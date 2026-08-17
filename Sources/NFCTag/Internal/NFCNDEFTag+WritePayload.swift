import Foundation
import CoreNFC
import OSLog

extension NFCNDEFTag {

    func writeTag(_ tag: Tag) async throws {
        let message = try tag.makeNDEFMessage()
        try await writeNDEF(message)
    }
}
