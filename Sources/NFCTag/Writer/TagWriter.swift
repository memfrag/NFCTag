import Foundation
import CoreNFC
import OSLog

// MARK: - TagWriter

/// Writes NFC NDEF tags.
public final class TagWriter {

    private var session: NFCNDEFReaderSession?

    private var sessionHandler: SessionHandler?

    public init() {
        //
    }

    deinit {
        cleanUp()
    }

    // MARK: Write Tag

    /// Write an NFC NDEF tag.
    ///
    /// > Note: Only text and URL payloads supported.
    ///
    /// **Example:**
    ///
    /// ```swift
    /// let tag = Tag(.url(URL(string: "https://example.com")!))
    /// let tagWriter = TagWriter()
    /// try await tagWriter.writeTag(tag)
    /// ```
    ///
    public func writeTag(
        _ tag: Tag,
        message: TagWriterMessage = .init()
    ) async throws {

        guard NFCNDEFReaderSession.readingAvailable else {
            throw TagScannerError.writingNotSupported
        }

        cleanUp()

        defer { cleanUp() }

        let sessionHandler = SessionHandler(tag: tag, statusMessage: message)
        self.sessionHandler = sessionHandler

        let session = NFCNDEFReaderSession(
            delegate: sessionHandler,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        self.session = session
        session.alertMessage = message.scanningMessage

        return try await withCheckedThrowingContinuation { continuation in
            sessionHandler.setContinuation(continuation)
            session.begin()
        }
    }

    // MARK: Clean Up

    private func cleanUp() {
        // Resuming here keeps a caller from awaiting forever if the writer is
        // torn down before the session reports a result.
        sessionHandler?.finish(throwing: TagWriterError.unexpectedError)
        sessionHandler = nil
        session?.invalidate()
        session = nil
    }
}

extension TagWriter {

    // MARK: - SessionHandler

    /// Receives reader session callbacks on the session's private queue.
    ///
    /// `@unchecked Sendable` is warranted because every stored property is
    /// either an immutable Sendable value or a lock guarded ``LockedBox``.
    final class SessionHandler: NSObject, NFCNDEFReaderSessionDelegate, @unchecked Sendable {

        private let tag: Tag

        private let statusMessage: TagWriterMessage

        private let continuation = LockedBox<CheckedContinuation<Void, Error>>()

        init(tag: Tag, statusMessage: TagWriterMessage) {
            self.tag = tag
            self.statusMessage = statusMessage
            super.init()
        }

        deinit {
            finish(throwing: TagWriterError.unexpectedError)
        }

        func setContinuation(_ continuation: CheckedContinuation<Void, Error>) {
            self.continuation.set(continuation)
        }

        // MARK: Finish

        /// Resumes the continuation, at most once.
        func finish(throwing error: Swift.Error?) {
            guard let continuation = continuation.take() else {
                return
            }
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
        }

        // MARK: - Session Did Detect Tags

        func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {

            guard let detectedTag = tags.first else {
                return
            }

            // CoreNFC types carry no concurrency annotations, so the compiler
            // cannot tell that these objects are handed over to this callback
            // and never touched anywhere else. The session delivers callbacks
            // on a single serial queue and the work below is the only consumer,
            // so the region is broken explicitly here.
            nonisolated(unsafe) let tagToWrite = detectedTag
            nonisolated(unsafe) let session = session

            Task {
                do {
                    try await session.connect(to: tagToWrite)
                } catch {
                    dump(error)
                    session.restartPolling()
                    return
                }

                do {
                    try await tagToWrite.verifyWritable()
                    try await tagToWrite.writeTag(tag)

                    session.alertMessage = statusMessage.didWriteTagMessage(tag)
                    finish(throwing: nil)
                } catch let error as TagWriterError {
                    dump(error)
                    session.invalidate(errorMessage: error.description)
                    finish(throwing: error)
                } catch {
                    dump(error)
                    session.invalidate(errorMessage: "Write failed, try again.")
                    finish(throwing: error)
                }
            }
        }

        // MARK: - Session Did Detect NDEFs

        func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
            // Not called.
        }

        // MARK: - Session Did Invalidate

        func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
            Logger.writer.trace("Reader session did invalidate with error: \(error.localizedDescription)")
            finish(throwing: error)
        }

        // MARK: - Session Did Become Active

        func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
            Logger.writer.trace("Reader session did become active.")
        }
    }
}
