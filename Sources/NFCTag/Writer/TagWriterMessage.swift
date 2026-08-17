import Foundation

/// Messages to show in the system NFC tag scanner bottom sheet when writing tags.
public struct TagWriterMessage: Sendable {

    public static let defaultScanningMessage = "Hold your phone near the tag to write."
    public static let defaultDidWriteTagMessage = "Successfully wrote data to tag."

    public let scanningMessage: String
    public var didWriteTagMessage: @Sendable (Tag) -> String

    public init(
        scanningMessage: String = defaultScanningMessage,
        didWriteTagMessage: @escaping @Sendable (Tag) -> String = { _ in defaultDidWriteTagMessage }
    ) {
        self.scanningMessage = scanningMessage
        self.didWriteTagMessage = didWriteTagMessage
    }
}
