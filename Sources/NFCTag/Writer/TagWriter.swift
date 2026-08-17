import Foundation
import Combine
import CoreNFC
import OSLog

// MARK: - TagWriter

/// Writes NFC NDEF tags.
public class TagWriter {

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

        session = NFCNDEFReaderSession(
            delegate: sessionHandler,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        session?.alertMessage = message.scanningMessage

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self,
                  let session = self.session,
                  let sessionHandler = self.sessionHandler else {
                continuation.resume(throwing: TagWriterError.unexpectedError)
                return
            }

            sessionHandler.continuation = continuation

            session.begin()
        }
    }

    // MARK: Clean Up

    private func cleanUp() {
        session?.invalidate()
        session = nil
        sessionHandler = nil
    }
}

extension TagWriter {

    // MARK: - SessionHandler

    class SessionHandler: NSObject, NFCNDEFReaderSessionDelegate {

        private let tag: Tag

        private let statusMessage: TagWriterMessage

        var continuation: CheckedContinuation<Void, Error>?

        init(tag: Tag, statusMessage: TagWriterMessage) {
            self.tag = tag
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
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        // MARK: Succeed

        private func succeed() {
            cleanUp()
        }

        // MARK: Fail

        private func fail(_ error: Swift.Error) {
            cleanUp(error: error)
        }

        // MARK: - Session Did Detect Tags

        public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {

            guard let detectedTag = tags.first else {
                return
            }

            Task {
                do {
                    try await session.connect(to: detectedTag)
                } catch {
                    dump(error)
                    session.restartPolling()
                }

                do {
                    try await detectedTag.verifyWritable()
                    try await detectedTag.writeTag(tag)

                    session.alertMessage = statusMessage.didWriteTagMessage(tag)
                    succeed()
                } catch let error as TagWriterError {
                    dump(error)
                    session.invalidate(errorMessage: error.description)
                    fail(error)
                } catch {
                    dump(error)
                    session.invalidate(errorMessage: "Write failed, try again.")
                    fail(error)
                }
            }
        }

        // MARK: - Session Did Detect NDEFs

        public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
            // Not called.
        }

        // MARK: - Session Did Invalidate

        public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
            Logger.writer.trace("Reader session did invalidate with error: \(error.localizedDescription)")
            fail(error)
        }

        // MARK: - Session Did Become Active

        public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
            Logger.writer.trace("Reader session did become active.")
        }
    }
}
