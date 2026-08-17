import Foundation
import Combine
import CoreNFC
import OSLog

/// An `AsyncThrowingStream` that produces a ``Tag`` whenever an NFC NDEF tag is scanned.
public typealias TagStream = AsyncThrowingStream<Tag, Error>

// MARK: - TagScanner

/// Scans NFC NDEF tags.
public class TagScanner {

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
            sessionHandler.continuation = continuation
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
        sessionHandler?.cleanUp(error: error)
        sessionHandler = nil
        session?.invalidate()
        session = nil
    }
}

extension TagScanner {

    // MARK: - SessionHandler

    class SessionHandler: NSObject, NFCNDEFReaderSessionDelegate {

        private let statusMessage: TagScannerMessage

        fileprivate var continuation: TagStream.Continuation?

        init(statusMessage: TagScannerMessage) {
            self.statusMessage = statusMessage
            super.init()
        }

        @available(*, unavailable)
        private override init() {
            fatalError("Not implemented")
        }

        deinit {
            cleanUp()
        }

        // MARK: Clean Up

        fileprivate func cleanUp(error: Swift.Error? = nil) {
            if let continuation {
                self.continuation = nil
                if let error {
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish()
                }
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
                continuation?.yield(tag)

            } catch let error as TagScannerError {
                dump(error)
                session.invalidate(errorMessage: error.description)
                if let continuation {
                    self.continuation = nil
                    continuation.finish(throwing: error)
                }
            } catch {
                dump(error)
                session.invalidate(errorMessage: "Scan failed, try again.")
                if let continuation {
                    self.continuation = nil
                    continuation.finish(throwing: error)
                }
            }
        }

        // MARK: - Session Did Detect Tags

        public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
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

        public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
            // Not called.
        }

        // MARK: - Session Did Invalidate

        public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
            Logger.scanner.trace("NFC reader session did invalidate with error: \(error.localizedDescription)")
            if let continuation {
                self.continuation = nil
                continuation.finish(throwing: error)
            }
        }

        // MARK: - Session Did Become Active

        public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
            Logger.scanner.trace("NFC reader session did become active.")
        }
    }
}
