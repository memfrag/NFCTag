# ``NFCTag``

A convenience package for iOS for scanning and writing NFC NDEF tags.

## Overview

The `NFCTag` package wraps `CoreNFC` for the specific purpose of scanning and writing NFC NDEF tags containing text and/or URL payloads.

> Note: Only text and URL payloads are supported.

## Topics

### Scanning Tags

- <doc:ScanningTags>
- ``TagScanner``
- ``TagStream``
- ``TagScannerMessage``
- ``TagScannerError``

### Writing Tags

- <doc:WritingTags>
- ``TagWriter``
- ``TagWriterMessage``
- ``TagWriterError``

### Tag and Payloads

- ``Tag``
- ``TagPayload``
