# Decisions

## 2026-10-29 — T0.3 Nuke local image gate

**Status:** Accepted. Keep Nuke `13.2.0`; do not add Kingfisher.

**Measured environment:** GitHub Actions `macos-15`, Xcode `26.3`, Apple Swift `6.2.4`, iPhone 16 Pro simulator on iOS `18.5`.

**Nuke test results:**

| Gate | Result |
|---|---|
| 48MP HEIC from a local file URL | Gallery `1,000 × 750`; thumbnail `320 × 240` |
| 48MP HEIC from `Data` | Gallery `1,000 × 750` |
| Ten 12MP JPEGs from local file URLs | Each thumbnail `320 × 240` |
| JPEG with EXIF orientation `6` | Gallery image transformed to `750 × 1,000` |
| 50 rapid updates with distinct file URLs | 49 superseded requests cancelled; final image `1,000 × 750` |
| Memory-only cache and release | Cache populated after loads; `removeAll()` returned count `0`, cost `0` bytes, and the weak image reference became `nil` |

The complete macOS CI test suite passed `10/10` with `0` failures and `0` skips; suite runtime was `193.9s`, including on-runner generation and encoding of all image fixtures.

**Decision:** Use `ImageRequest.ThumbnailOptions(maxPixelSize:)` for local file and `Data` requests. Nuke's ImageIO-backed thumbnail path produces the requested display sizes without materializing a full-size `UIImage`, and its cancellable `ImageTask` plus `ImageCache` satisfy the gallery request lifecycle. Keep `dataCache = nil` for the app's owned local files and bound decoded memory with `ImageCache`.

**Boundary:** This gate validates behavior on the iOS Simulator in CI, not Instruments measurements or real-device performance. Those remain product acceptance work after the gallery integration exists.
