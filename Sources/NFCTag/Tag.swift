import Foundation

/// Represents an NFC NDEF tag and contains the tag payloads.
///
/// > Note: Only URL and text payloads are supported.
///
public struct Tag: Sendable {

    /// The payloads contained in the NFC NDEF tag.
    ///
    /// > Note: Only URL and text payloads are supported.
    ///
    public let payloads: [TagPayload]

    /// Initialize with the payloads contained in the NFC NDEF tag.
    ///
    /// > Note: Only URL and text payloads are supported.
    ///
    public init(_ payloads: [TagPayload]) {
        self.payloads = payloads
    }

    /// Initialize with the payloads contained in the NFC NDEF tag.
    ///
    /// > Note: Only URL and text payloads are supported.
    ///
    public init(_ payloads: TagPayload...) {
        self.payloads = payloads
    }
}
