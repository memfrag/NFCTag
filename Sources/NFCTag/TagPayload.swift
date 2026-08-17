import Foundation
import CoreNFC

/// The payload contained in an NFC NDEF ``Tag``.
///
/// > Note: Only URL and text payloads are supported.
///
public enum TagPayload {
    case url(URL)
    case text(String, locale: Locale)
}

extension TagPayload {

    init?(from record: NFCNDEFPayload) {
        if let url = record.wellKnownTypeURIPayload() {
            self = .url(url)
        } else if let tuple = textPayloadToTuple(record.wellKnownTypeTextPayload()) {
            self = .text(tuple.string, locale: tuple.locale)
        } else {
            return nil
        }
    }
}

private func textPayloadToTuple(_ payload: (String?, Locale?)) -> (string: String, locale: Locale)? {
    if let string = payload.0 {
        return (string, payload.1 ?? Locale(identifier: "en-US"))
    } else {
        return nil
    }
}
