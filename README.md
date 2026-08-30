# Slipstream

**An optimization-first Chromium browser for Windows. Fast, quiet, and honest.**

> ⚠️ **Pre-release. Nothing to download yet.** This repo is the build system
> and patch set; the first release (v0.1) will be a portable zip + installer.

Slipstream is a Chromium-based browser built on the
[Thorium](https://github.com/gz83/thorium) patch set (compiler optimizations:
AVX2, ThinLTO, PGO) with additional debloating on top — and with the things
that make Chromium practical left fully intact.

## What it is

- **Fast**: `is_official_build` + PGO + ThinLTO + AVX2/FMA targeting, via
  Thorium's proven optimization patches.
- **Quiet**: no metrics/UMA upload, no crash-report upload, no field
  trials/variations, no RLZ, no promo surfaces, no background mode, no
  mDNS chatter. Verified per release with an idle network capture.
- **Chrome Web Store works natively**: install and auto-update extensions
  exactly like Chrome. No helper extension, no manual .crx juggling.
- **No Google API keys shipped**: the Web Store needs none; we refuse to
  bundle Google's shared dev key like some forks do.
- **Honest about security**: we inherit Chromium's CVEs and publish our
  patch lag. See [SECURITY.md](docs/SECURITY.md). Security-relevant OS
  integrations (download quarantine / Mark-of-the-Web) are NOT disabled —
  even where upstream Thorium disables them.

## What it is not

- **No Google account Sync** — Google closed Sync to all third-party
  Chromium builds in 2021. Not fixable with keys.
- **Not a vendor browser** — one maintainer, measured patch delay. If your
  threat model includes targeted attackers, use Chrome or Edge.
- **Safe Browsing is inert** in distributed builds (needs a
  non-redistributable Google key). Windows SmartScreen + the preinstalled
  uBlock Origin are the practical protection layer.

## Building

See [docs/BUILDING-WINDOWS.md](docs/BUILDING-WINDOWS.md). Short version:
VS 2026 + Windows 11 SDK 28000 + depot_tools + ~200 GB disk + a few hours.

## License

BSD-3-Clause for the Slipstream delta; Chromium and Thorium are BSD-3-Clause.
See [LICENSE](LICENSE), [TRADEMARK.md](TRADEMARK.md), and `LICENSES/`.
