import Foundation

/// Error cases that may occur when ``TagWriter`` writes tags.
public enum TagWriterError: Swift.Error, CustomStringConvertible {
    case tagNotSupported
    case tagNotWritable
    case invalidPayload
    case unexpectedError

    public var description: String {
        switch self {
        case .tagNotWritable: "The tag is not writable."
        case .invalidPayload: "The URL is invalid or does not fit."
        case .tagNotSupported: "This type of tag is not supported."
        case .unexpectedError: "Something went wrong, try again."
        }
    }
}
