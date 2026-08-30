# Slipstream Browser

**An optimization-first Chromium browser for Windows. Fast, memory-smart, private, and honest.**

> ⚠️ **Pre-release.** v0.0 (a from-source proving build) is complete; v0.1 — the
> first downloadable release — is in progress. Watch Releases. Nothing to
> download yet.

Slipstream Browser is an open-source Chromium fork built on the
[Thorium](https://github.com/gz83/thorium) optimization patch set (AVX2,
ThinLTO, PGO official builds), with additional debloating, privacy hardening,
and memory tuning on top — and with the things that make Chromium practical
left fully intact, starting with the Chrome Web Store.

## Core feature set

**Fast** — compiler-level speed, not marketing:
- `is_official_build` + profile-guided optimization + ThinLTO + AVX2/FMA targeting
- V8 pointer compression and sandbox pinned in the build config
- No telemetry subsystems competing for cycles

**Memory-smart** — reclaim RAM without weakening protections:
- Memory Saver **on by default**: background tabs discard after hours of disuse
- Windows commit-limit discarding: tabs discard before out-of-memory crashes
- Tab freezing with renderer memory purge under pressure
- Site isolation, MiraclePtr, and the spare renderer deliberately **kept** —
  memory wins come from the discard/freeze stack, never from weakened security

**Private by default**:
- Zero telemetry: no UMA metrics, no crash uploads, no field trials/variations,
  no RLZ (compiled out), no promo services — verified each release with an
  idle network capture
- Third-party cookies blocked by default; WebRTC never exposes local IPs
- No hyperlink auditing, no autofill crowdsourcing, no Google time queries;
  battery API returns constants; sensors and idle detection blocked by default
- **DuckDuckGo** as default search (switch to anything in two clicks)
- **No Google API keys shipped** — we refuse to bundle Google's shared dev key

**Secure and honest about it**:
- HTTPS-First mode (balanced) on by default
- Tracks Chromium stable security releases with a **published patch-lag SLO**
  ([SECURITY.md](docs/SECURITY.md))
- Windows download quarantine (Mark-of-the-Web) **kept** — we exclude upstream
  patches that disable it, along with silent-flag-injection and FTP patches
- Staged hardening lane: network-service sandbox, renderer AppContainer,
  extension content verification, App-Bound Encryption

**Practical**:
- **Chrome Web Store works natively** — install and auto-update extensions
  exactly like Chrome; uBlock Origin preinstalled on new profiles (from the
  store, not bundled; uninstall sticks)
- Manifest V2 runtime kept alive (sideloaded MV2 extensions keep working)
- Portable zip + installer; portable profiles supported

## What it is not

- **No Google account Sync** — Google closed Sync to all third-party Chromium
  builds in 2021. No fork can fix this.
- **Not a vendor browser** — one maintainer, measured patch delay, no fuzzing
  fleet. If your threat model includes targeted attackers, use Chrome or Edge.
  Read [SECURITY.md](docs/SECURITY.md) before trusting this browser.
- **Safe Browsing is inert** in distributed builds (requires a
  non-redistributable Google key). Windows SmartScreen + uBlock Origin are the
  practical protection layer.
- No relation to "NAT Slipstreaming," the 2020 browser attack technique — or
  to slipstreaming Windows ISOs, the VPN, the racing game, or the airline
  logbook extension. Crowded word, empty niche.

## How it's built

A thin, auditable delta — no vendored Chromium, no fork of Thorium:

```
pinned Chromium tag  ->  Thorium patch series (minus our exclusions)
                     ->  Slipstream overlay (branding, install identity)
                     ->  Slipstream stage-90 patches (debloat/privacy/memory/security)
```

Every excluded upstream patch and every added patch is documented with
rationale: [DECISIONS.md](docs/DECISIONS.md) ·
[PILLARS.md](docs/PILLARS.md) · [DEBLOAT.md](docs/DEBLOAT.md).
Build it yourself: [BUILDING-WINDOWS.md](docs/BUILDING-WINDOWS.md).

## Comparison, honestly

| | Slipstream | Chrome | Thorium | ungoogled-chromium |
|---|---|---|---|---|
| Compiler optimizations (AVX2/PGO/LTO) | ✅ | ❌ | ✅ | ❌ |
| Zero telemetry, verified per release | ✅ | ❌ | partial | ✅ |
| Chrome Web Store + extension auto-update | ✅ | ✅ | ✅ | ❌ (workarounds) |
| Memory Saver + commit-limit discard defaults | ✅ | opt-in | ❌ | ❌ |
| Google Sync | ❌ | ✅ | ❌ | ❌ |
| Sub-24h security response | ❌ (7-day SLO) | ✅ | irregular | irregular |
| Download quarantine (MotW) kept | ✅ | ✅ | ❌ | ✅ |
| Ships Google API keys | ❌ | n/a | ⚠️ | ❌ |

## License

BSD-3-Clause for the Slipstream delta; Chromium and Thorium are BSD-3-Clause.
See [LICENSE](LICENSE), [TRADEMARK.md](TRADEMARK.md), `LICENSES/`.
Built on Chromium (The Chromium Authors) and the Thorium patch set
(Alexander Frick and contributors). Neither endorses this project.
