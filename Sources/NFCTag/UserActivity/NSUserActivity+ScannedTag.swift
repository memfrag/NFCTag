import Foundation

/// Convenience extension for retrieving an NFC NDEF tag that was scanned in the background.
///
/// **Example:**
///
/// Assuming the scanned tag contains a URL that is registered as an "applink" in the app.
///
/// ```swift
/// SomeSwiftUIView()
///     .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
///         if let tag = activity.scannedTag {
///             for payload in tag.payloads {
///                 switch payload {
///                 case .url(let url): print(url)
///                 case .text(let text, _): print(text)
///                 }
///             }
///         }
///     }
/// ```
///
extension NSUserActivity {
    
    /// Contains an NFC NDEF tag if it was scanned in the background and has a URL payload.
    ///
    /// **Example:**
    ///
    /// Assuming the scanned tag contains a URL that is registered as an "applink" in the app.
    ///
    /// ```swift
    /// SomeSwiftUIView()
    ///     .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
    ///         if let tag = activity.scannedTag {
    ///             for payload in tag.payloads {
    ///                 switch payload {
    ///                 case .url(let url): print(url)
    ///                 case .text(let text, _): print(text)
    ///                 }
    ///             }
    ///         }
    ///     }
    /// ```
    ///
    public var scannedTag: Tag? {
        let payloads = ndefMessagePayload.records.compactMap { record in
            TagPayload(from: record)
        }
        if payloads.isEmpty {
            return nil
        } else {
            let tag = Tag(payloads)
            return tag
        }
    }
}
