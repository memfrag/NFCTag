import Foundation

/// Error cases that may occur when ``TagScanner`` scans tags.
public enum TagScannerError: Swift.Error, CustomStringConvertible {
    case tagNotSupported
    case noNDEFRecordsFound
    case unexpectedError
    case scanningNotSupported
    case writingNotSupported

    public var description: String {
        switch self {
        case .tagNotSupported: "This type of tag is not supported."
        case .noNDEFRecordsFound: "No payload found in tag."
        case .unexpectedError: "Something went wrong, try again."
        case .scanningNotSupported: "Scanning is not supported by device."
        case .writingNotSupported: "Writing is not supported by device."
        }
    }
}
