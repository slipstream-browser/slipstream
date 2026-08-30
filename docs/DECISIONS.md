# Slipstream — recorded decisions

Dated log of load-bearing decisions. Changing any of these requires a new
dated entry, not an edit.

## 2026-08-30 — founding decisions

| Decision | Choice | Rationale |
|---|---|---|
| Foundation | Thorium (`gz83/thorium`) as a **pinned submodule**, never a git fork | Thorium's ordered patch series + setup scripts are consumable as-is; a fork would force merging ~180 patch files every release. Submodule pin = auditable delta, cheap rebases, and dormancy insurance (the series can be replayed on vanilla Chromium). |
| Base version | `M152.0.7977.55` (Chromium 152.0.7977.55) | Latest Thorium release at project start (2026-08-23). |
| License | BSD-3-Clause for the Slipstream delta | Matches both Chromium and Thorium (verified: Thorium is BSD-3, **not** GPL — package trackers claiming GPL are stale). Bidirectional patch flow stays frictionless. |
| Product name | **Slipstream** | GitHub `slipstream-browser` org/user free (checked 2026-08-30); no existing browser uses it. Known adjacent risk: dormant SLIPSTREAM mark once held by Slipstream Data Inc. (network-optimization software, absorbed by BlackBerry) — re-check formally before v1.0. Rename is cheap by design (token map + overlay). |
| Google API keys | **None shipped**; Thorium's `thorium-default-api-keys.patch` excluded | The hardcoded key is Google's shared public dev key — ToS violation to redistribute, shared abused quota. CWS install + extension auto-update use unauthenticated endpoints and work keyless. |
| Chrome Web Store | Fully preserved — `webstorePrivate` API, `extension_urls.cc`, CRX3 verification, extension auto-updater, `Chrome/<major>.0.0.0` UA token all untouched | Core product requirement. The ungoogled-chromium patches that strip these are explicitly NOT imported. |
| Safe Browsing | Compiled in (`safe_browsing_mode=1`) but inert without a key; documented honestly | Stripping it (`=0`) forecloses the option; shipping Google's key is prohibited. Practical protection = Windows SmartScreen + preinstalled uBlock Origin (Thorium patch kept). Personal builds MAY inject a private key via git-ignored `local_keys.gn`. |
| Widevine | `bundle_widevine_cdm=false`; component updater fetches CDM at runtime | Redistributing the CDM requires a Widevine license agreement we don't have. Runtime fetch keeps Netflix/Spotify working with a clean legal posture. |
| FFmpeg | `is_component_ffmpeg=true` | FFmpeg is LGPL-2.1+; a separate replaceable ffmpeg.dll is the clean LGPL §6 posture (Thorium statically links it). |
| Security-negative Thorium patches | Excluded: `disable-download-quarantine` (kills MotW), `allow-insecure-downloads` | A security-positioned browser does not silently disable OS download quarantine. |
| `disable-encryption.patch` | **Kept** (inspected 2026-08-30) | Adds opt-in switches only (`--disable-encryption`, `--disable-machine-id`, `--revert-from-portable`); defaults unchanged, DPAPI stays on. Enables truly portable profiles. Documented: portable mode with these flags stores credentials unencrypted. |
| CPU target | AVX2 (`thorium_x86_profile = "avx2_fma"`) only, for distribution | Haswell/Zen1+ floor, matches Thorium's main channel. AVX-512 gets one benchmark experiment, not a maintained channel (PGO profile is generic; community-measured gains are low single digits; each channel doubles build time). |
| Sync | Not available, documented in FAQ | Google closed the Sync API to third-party Chromium builds in March 2021. No key brings it back. |
| MV2 | Keep Thorium's `allow_manifest_v2_extensions` runtime patch | Sideloaded/preinstalled MV2 (uBO classic) keeps working; CWS no longer serves MV2 — documented so it isn't filed as a Slipstream bug. |
| Repo visibility | Private until v0.1 ships, then public | Nothing public until a release exists and licensing files are complete. |
| Chromium checkout | Full history (not `--no-history`) | Deviation from the original plan: tag checkouts and 2-week rebase cadence need tag fetches, which fight shallow clones. Disk (1.27 TB free) is not the constraint. |

## 2026-08-30 — v0.0 gate results

| Finding | Consequence |
|---|---|
| Stock Thorium build green on first attempt (4.5 h, `-j 22`, peak RAM fine with 96 GB pagefile) | Toolchain proven; SDK 26100 passed M152's checks (28000 installed anyway for future milestones). |
| CWS serves the browser normally; uBO Lite installed by hand; **uBO classic auto-preinstalled from CWS on new profile** (verified in test profile) | Keep Thorium's `preinstall-ublock-origin.patch`. Google's CRX service still serves the delisted MV2 package (2026-08-30). Fallback if that ever stops: swap the ID to uBO Lite (`ddkjiahejlhfcafbddmgiahcphecmpfh`). Nothing is bundled in the installer → no GPL redistribution obligations. |
| **Chromium's own hard-coded preinstall list also installed an Adobe Acrobat extension** (`efaidnbmnnnibpcajpcglclefindmkaj`) in the test profile | Bloat. New stage-90 patch planned: `90-trim-preinstalled-extensions.patch` — clear Chromium's partner preinstalls, keep only uBO. |

## 2026-08-30 — pillar design (memory / privacy / security)

Product pillars set by Matt: **fast, memory-optimized, privacy-first, secure.**
Priority when irreconcilable: **SECURE > PRIVACY > FAST > MEMORY.**

Full machine-verified design: `docs/PILLARS.md` (implementation plan) +
`docs/pillar-proposals.json` (evidence record; every item carries file:line
proof from the pinned tree). Highlights:

| Decision | Choice |
|---|---|
| Memory strategy | Discard/freeze stack (Memory Saver default-ON, commit-limit discard, freeze+purge), NOT weakened protections. Site isolation, BackupRefPtr, spare renderer all kept — costs documented. |
| Three more Thorium patches excluded | `windows-thorium-flags-conf` (user-writable flag injection), `relax-bad-flags-warning`, `ftp-support-thorium`. |
| **Invariant (C2)** | `enable_mdns=false` is only valid while `webrtc.ip_handling_policy=default_public_interface_only` ships in the same build. Revert one ⇒ revert both, same commit. ICE-leak check is a release gate. |
| Network time (C3) | Google time-service queries off; skewed-clock users see generic cert errors (FAQ entry). Idle-capture bar now includes `clients2.google.com/time`. |
| HTTPS-First | Balanced auto-enable (user pref always wins). |
| App-Bound Encryption | Pursued via targeted revert of Thorium's elevation-service guards + our fresh GUIDs + system-level install default. Gated on investigating why Thorium disabled it. Per-user/portable installs stay DPAPI — documented. |
| Default search engine | **DuckDuckGo** (decided 2026-08-30), seeded via initial_preferences — cheap, reversible, consistent with privacy-first identity. Users switch in two clicks; choice screen re-evaluated at v1.0. |

## GUID registry (PERMANENT after first public release)

See `branding/brand.json`. Six fresh GUIDs generated 2026-08-30; reusing
Thorium's or Chromium's GUIDs would make installers fight over registry
ownership, default-browser registration, and COM activation on machines with
both installed.
