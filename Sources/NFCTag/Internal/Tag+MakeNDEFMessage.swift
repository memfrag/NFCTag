import Foundation
import CoreNFC

extension Tag {

    func makeNDEFMessage() throws -> NFCNDEFMessage {
        let records: [NFCNDEFPayload] = payloads.compactMap { payload in
            switch payload {
            case .url(let url):
                NFCNDEFPayload.wellKnownTypeURIPayload(url: url)
            case .text(let string, let locale):
                NFCNDEFPayload.wellKnownTypeTextPayload(string: string, locale: locale)
            }
        }
        guard !records.isEmpty else {
            throw TagWriterError.invalidPayload
        }
        return NFCNDEFMessage(records: records)
    }
}
