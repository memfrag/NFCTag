# NFCTag

A convenience package for iOS for scanning and writing NDEF NFC tags.

## Documentation

API documentation is available at [memfrag.github.io/NFCTag](https://memfrag.github.io/NFCTag/documentation/nfctag/).

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
