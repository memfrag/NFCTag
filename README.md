# NFCTag

[![Documentation](https://img.shields.io/badge/documentation-DocC-blue)](https://memfrag.github.io/NFCTag/documentation/nfctag/)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/license-0BSD-green)](LICENSE)

A convenience package for iOS for scanning and writing NDEF NFC tags.

## Documentation

Full API documentation is published at
**[memfrag.github.io/NFCTag](https://memfrag.github.io/NFCTag/documentation/nfctag/)**.

Jump straight to a topic:

- [Scanning Tags](https://memfrag.github.io/NFCTag/documentation/nfctag/scanningtags/)
- [Writing Tags](https://memfrag.github.io/NFCTag/documentation/nfctag/writingtags/)
- [`TagScanner`](https://memfrag.github.io/NFCTag/documentation/nfctag/tagscanner/)
- [`TagWriter`](https://memfrag.github.io/NFCTag/documentation/nfctag/tagwriter/)

## Installation

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/memfrag/NFCTag.git", from: "1.0.0")
```

## Requirements

Swift 6 and iOS 17 or later. CoreNFC is unavailable on native macOS, so this
package targets iOS only.

## License

NFCTag is released under the BSD Zero Clause license. See LICENSE file for details.

## Usage

### Scanning a Tag

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

### Writing a Tag

```swift
let tag = Tag(.url(URL(string: "https://example.com")!))
let tagWriter = TagWriter()
try await tagWriter.writeTag(tag)
```

### Scanning a Tag in the Background

Assuming the scanned tag contains a URL that is registered as an "applink" in the app.

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
