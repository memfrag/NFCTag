import Foundation

/// Messages to show in the system NFC tag scanner bottom sheet when scanning tags.
public struct TagScannerMessage: Sendable {

    public static let defaultScanningMessage = "Hold your phone near the tag."
    public static let defaultDidScanTagMessage = "Scan was successful."

    public let scanningMessage: String
    public var didScanTagMessage: @Sendable (Tag) -> String

    public init(
        scanningMessage: String = defaultScanningMessage,
        didScanTagMessage: @escaping @Sendable (Tag) -> String = { _ in defaultDidScanTagMessage }
    ) {
        self.scanningMessage = scanningMessage
        self.didScanTagMessage = didScanTagMessage
    }
}
