# Getting Started with Writing Tags

Write text and/or URL payloads to NFC NDEF tags.

## Examples

### Writing a Tag

To write a tag, use ``TagWriter/writeTag(_:message:)``.

```swift
let tag = Tag(.url(URL(string: "https://example.com")!))
let tagWriter = TagWriter()
try await tagWriter.writeTag(tag)
```
