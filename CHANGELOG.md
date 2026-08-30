# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions pair the product version with the Chromium base
(e.g. `0.1.0 — Chromium 152.0.7977.55`).

## [Unreleased]

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
