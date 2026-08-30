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
| Security-negative Thorium patches | Excluded: `disable-download-quarantine` (kills MotW), `allow-insecure-downloads` | A security-positioned browser does not silently disable OS download quarantine. `disable-encryption.patch` pending inspection before v0.1. |
| CPU target | AVX2 (`thorium_x86_profile = "avx2_fma"`) only, for distribution | Haswell/Zen1+ floor, matches Thorium's main channel. AVX-512 gets one benchmark experiment, not a maintained channel (PGO profile is generic; community-measured gains are low single digits; each channel doubles build time). |
| Sync | Not available, documented in FAQ | Google closed the Sync API to third-party Chromium builds in March 2021. No key brings it back. |
| MV2 | Keep Thorium's `allow_manifest_v2_extensions` runtime patch | Sideloaded/preinstalled MV2 (uBO classic) keeps working; CWS no longer serves MV2 — documented so it isn't filed as a Slipstream bug. |
| Repo visibility | Private until v0.1 ships, then public | Nothing public until a release exists and licensing files are complete. |
| Chromium checkout | Full history (not `--no-history`) | Deviation from the original plan: tag checkouts and 2-week rebase cadence need tag fetches, which fight shallow clones. Disk (1.27 TB free) is not the constraint. |

## GUID registry (PERMANENT after first public release)

See `branding/brand.json`. Six fresh GUIDs generated 2026-08-30; reusing
Thorium's or Chromium's GUIDs would make installers fight over registry
ownership, default-browser registration, and COM activation on machines with
both installed.
