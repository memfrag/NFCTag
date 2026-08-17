# Getting Started with Scanning Tags

Scan NFC NDEF tags with text and/or URL payloads.

## Examples

### Scanning a Tag

To scan one tag at a time, use ``TagScanner/scanTag(message:)``.

```swift
let tagScanner = TagScanner()

let tag = try await tagScanner.scanTag()

for payload in tag.payloads {
    switch payload {
    case .url(let url): print(url)
    case .text(let text, _): print(text)
    }
}    
```

### Scanning Multiple Tags

To scan multiple tags at a time, use ``TagScanner/scanTags(multiple:message:)``.

```swift
let tagScanner = TagScanner()

for try await tag in tagScanner.scanTags() {
    for payload in tag.payloads {
        switch payload {
        case .url(let url): print(url)
        case .text(let text, _): print(text)
        }
    }    
}
```

### Scanning a Tag in the Background

Assuming the scanned tag contains a URL that is registered as an "applink" in the app, tags can be scanned in the background. Process the scanned tags by extracting them from the resulting `NSUserActivity`.

```swift
SomeSwiftUIView()
    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
        if let tag = activity.scannedTag {
            for payload in tag.payloads {
                switch payload {
                case .url(let url): print(url)
                case .text(let text, _): print(text)
                }
            }
        }
    }
```
