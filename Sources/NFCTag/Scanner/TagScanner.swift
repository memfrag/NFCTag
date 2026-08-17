import Foundation
import CoreNFC
import OSLog

/// An `AsyncThrowingStream` that produces a ``Tag`` whenever an NFC NDEF tag is scanned.
public typealias TagStream = AsyncThrowingStream<Tag, Error>

// MARK: - TagScanner

/// Scans NFC NDEF tags.
public final class TagScanner {

    private var session: NFCNDEFReaderSession?

    private var sessionHandler: SessionHandler?

    /// Initialize the tag scanner.
    public init() {
        //
    }

    deinit {
        cleanUp()
    }

    // MARK: Scan Tag

    /// Scan an NFC NDEF tag.
    ///
    /// > Note: Only text and URL payloads are supported.
    ///
    /// **Example:**
    ///
    /// ```swift
    /// let tagScanner = TagScanner()
    ///
    /// let tag = try await tagScanner.scanTag()
    ///
    /// for payload in tag.payloads {
    ///     switch payload {
    ///     case .url(let url): print(url)
    ///     case .text(let text, _): print(text)
    ///     }
    /// }
    /// ```
    ///
    public func scanTag(
        message: TagScannerMessage = .init()
    ) async throws -> Tag {

        guard NFCNDEFReaderSession.readingAvailable else {
            throw TagScannerError.scanningNotSupported
        }

        defer { cleanUp() }

        let tagStream = scanTags(multiple: true, message: message)

        for try await tag in tagStream {
            return tag
        }

        throw TagScannerError.noNDEFRecordsFound
    }

    // MARK: Scan Tags

    /// Scan multiple NFC NDEF tags using an `AsyncStream`.
    ///
    /// > Note: Only text and URL payloads are supported.
    ///
    /// **Example:**
    ///
    /// ```swift
    /// let tagScanner = TagScanner()
    ///
    /// for try await tag in tagScanner.scanTags() {
    ///     for payload in tag.payloads {
    ///         switch payload {
    ///         case .url(let url): print(url)
    ///         case .text(let text, _): print(text)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    public func scanTags(
        multiple: Bool = true,
        message: TagScannerMessage = .init()
    ) -> TagStream {

        cleanUp()

        let sessionHandler = SessionHandler(statusMessage: message)
        self.sessionHandler = sessionHandler

        let tagPayloadStream = AsyncThrowingStream { continuation in
            sessionHandler.setContinuation(continuation)
        }

        guard NFCNDEFReaderSession.readingAvailable else {
            cleanUp(error: TagScannerError.scanningNotSupported)
            return tagPayloadStream
        }

        let session = NFCNDEFReaderSession(
            delegate: sessionHandler,
            queue: nil,
            invalidateAfterFirstRead: multiple ? false : true
        )
        self.session = session

        session.alertMessage = message.scanningMessage
        session.begin()

        return tagPayloadStream
    }

    // MARK: Clean Up

    private func cleanUp(error: Swift.Error? = nil) {
        sessionHandler?.finish(throwing: error)
        sessionHandler = nil
        session?.invalidate()
        session = nil
    }
}

extension TagScanner {

    // MARK: - SessionHandler

    /// Receives reader session callbacks on the session's private queue.
    ///
    /// `@unchecked Sendable` is warranted because every stored property is
    /// either an immutable Sendable value or a lock guarded ``LockedBox``.
    final class SessionHandler: NSObject, NFCNDEFReaderSessionDelegate, @unchecked Sendable {

        private let statusMessage: TagScannerMessage

        private let continuation = LockedBox<TagStream.Continuation>()

        init(statusMessage: TagScannerMessage) {
            self.statusMessage = statusMessage
            super.init()
        }

        deinit {
            finish(throwing: nil)
        }

        func setContinuation(_ continuation: TagStream.Continuation) {
            self.continuation.set(continuation)
        }

        // MARK: Finish

        /// Finishes the stream, at most once.
        func finish(throwing error: Swift.Error?) {
            guard let continuation = continuation.take() else {
                return
            }
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }

        // MARK: - Read Tags

        private func readTags(_ tags: [NFCNDEFTag], in session: NFCNDEFReaderSession) async throws {
            for tag in tags {
                try await readTag(tag, in: session)
            }
        }

        // MARK: - Read Tag

        private func readTag(_ tag: NFCNDEFTag, in session: NFCNDEFReaderSession) async throws {
            try await session.connect(to: tag)

            do {
                let (status, _) = try await tag.queryNDEFStatus()
                guard status == .readWrite || status == .readOnly else {
                    throw TagScannerError.tagNotSupported
                }

                let message = try await tag.readNDEF()

                let payloads = message.records.compactMap { record in
                    TagPayload(from: record)
                }

                guard !payloads.isEmpty else {
                    throw TagScannerError.noNDEFRecordsFound
                }

                let tag = Tag(payloads)
                session.alertMessage = statusMessage.didScanTagMessage(tag)
                continuation.current?.yield(tag)

            } catch let error as TagScannerError {
                dump(error)
                session.invalidate(errorMessage: error.description)
                finish(throwing: error)
            } catch {
                dump(error)
                session.invalidate(errorMessage: "Scan failed, try again.")
                finish(throwing: error)
            }
        }

        // MARK: - Session Did Detect Tags

        func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
            // CoreNFC types carry no concurrency annotations, so the compiler
            // cannot tell that these objects are handed over to this callback
            // and never touched anywhere else. The session delivers callbacks
            // on a single serial queue and the work below is the only consumer,
            // so the region is broken explicitly here.
            nonisolated(unsafe) let tags = tags
            nonisolated(unsafe) let session = session

            Task {
                do {
                    try await readTags(tags, in: session)
                } catch {
                    dump(error)
                    session.restartPolling()
                }
            }
        }

        // MARK: - Session Did Detect NDEFs

        func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
            // Not called.
        }

        // MARK: - Session Did Invalidate

        func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
            Logger.scanner.trace("NFC reader session did invalidate with error: \(error.localizedDescription)")
            finish(throwing: error)
        }

        // MARK: - Session Did Become Active

        func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
            Logger.scanner.trace("NFC reader session did become active.")
        }
    }
}
