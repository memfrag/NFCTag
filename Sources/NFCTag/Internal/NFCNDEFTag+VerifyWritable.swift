import Foundation
import CoreNFC
import OSLog

extension NFCNDEFTag {

    func verifyWritable() async throws {
        let (status, capacity) = try await queryNDEFStatus()
        Logger.writer.trace("NDEF Capacity: \(capacity)")
        guard status != .readOnly else {
            throw TagWriterError.tagNotWritable
        }
        guard status == .readWrite else {
            throw TagWriterError.tagNotSupported
        }
    }
}
