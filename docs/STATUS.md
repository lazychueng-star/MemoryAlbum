# Status

T0.1 — Windows host has no `xcodegen`, `xcodebuild`, `xcrun`, or `swift`; `scripts/verify.sh fast` cannot start because WSL is unavailable. Exact Xcode/Swift versions and Debug/Release results remain pending on macOS (Gate G0 pending).
T0.2 — `project.yml` now integrates `Domain/` and `Data/Persistence/` into the app target and `Tests/Domain/` plus `Tests/Fixtures/` into `MemoryAlbumTests`; Windows static checks pass, but the 8 contract tests require execution on macOS via `scripts/verify.sh fast`.
