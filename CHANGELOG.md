# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions pair the product version with the Chromium base
(e.g. `0.1.0 — Chromium 152.0.7977.55`).

## [Unreleased]

### Fixed (2026-08-31) — blank-browser blocker
- **`is_component_ffmpeg=true` bricked every renderer.** In a static build it made
  ffmpeg.dll a load-time import of chrome.dll, which renderer Code Integrity Guard
  blocks; all renderers exited with code 7 ~21ms after launch and the browser
  rendered nothing. Reverted to `false`.
- **Internal URL scheme unified on `slipstream`** — was renamed one-sidedly, so
  Copy-URL produced links that could not be pasted back.
- Added `scripts/check-imports.py` build gate (fails on app-directory DLL imports)
  and Tier A runtime liveness gates in docs/SMOKE.md.
- Verified post-fix with the sandbox ON: 4 renderers alive, JS executes, uBO
  background page live and blocking 3/3 ad hosts, 0 crash-histogram samples,
  0 CodeIntegrity blocks.

### Milestone: first branded build (0.1.0-dev, 2026-08-30)
- `slipstream.exe` builds, launches, and loads the Chrome Web Store;
  uBlock Origin preinstalls on new profiles
- PE version resource: Slipstream / The Slipstream Browser Authors
- Verified in artifacts: Widevine unbundled (runtime fetch), FFmpeg statically
  linked (see the 2026-08-31 fix above), on-device model service out, RLZ out
- Packaged: 186 MB installer + 552 MB portable zip, SHA-256 + build-info
- Not yet in this build: stage-90 privacy/memory/security patch set,
  DuckDuckGo default, in-browser theme

### Added
- Build system: pinned Thorium submodule (M152.0.7977.55), overlay + stage-90
  patch-series architecture, full Windows build scripts
- Verified pillar design for memory/privacy/security defaults
  (docs/PILLARS.md, docs/pillar-proposals.json)
- Name clearance record (docs/NAME-CLEARANCE.md)

### Changed (vs stock Thorium)
- Excluded: hardcoded Google API keys, download-quarantine disable,
  insecure-downloads allow, %APPDATA% flag injection, relaxed bad-flag
  warnings, FTP client, What's New/Chrome Labs default-on
- DuckDuckGo default search (pending implementation)

### Security
- SECURITY.md with numeric patch-lag SLO drafted
