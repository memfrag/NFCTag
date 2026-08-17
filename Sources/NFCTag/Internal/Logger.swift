import Foundation
import OSLog

extension Logger {
    static let scanner = Logger(subsystem: "io.apparata.NFCTag", category: "Scanner")
    static let writer = Logger(subsystem: "io.apparata.NFCTag", category: "Writer")
}
