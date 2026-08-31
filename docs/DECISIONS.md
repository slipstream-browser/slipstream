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
| FFmpeg | ~~`is_component_ffmpeg=true`~~ **SUPERSEDED 2026-08-31 → `false`** (see postmortem below) | Original rationale: LGPL §6 separate-DLL posture. Reversed: in a static build it makes ffmpeg.dll a load-time import that renderer Code Integrity Guard blocks, killing every renderer. LGPL is satisfied by published pinned sources + build instructions instead. |
| Security-negative Thorium patches | Excluded: `disable-download-quarantine` (kills MotW), `allow-insecure-downloads` | A security-positioned browser does not silently disable OS download quarantine. |
| `disable-encryption.patch` | **Kept** (inspected 2026-08-30) | Adds opt-in switches only (`--disable-encryption`, `--disable-machine-id`, `--revert-from-portable`); defaults unchanged, DPAPI stays on. Enables truly portable profiles. Documented: portable mode with these flags stores credentials unencrypted. |
| CPU target | AVX2 (`thorium_x86_profile = "avx2_fma"`) only, for distribution | Haswell/Zen1+ floor, matches Thorium's main channel. AVX-512 gets one benchmark experiment, not a maintained channel (PGO profile is generic; community-measured gains are low single digits; each channel doubles build time). |
| Sync | Not available, documented in FAQ | Google closed the Sync API to third-party Chromium builds in March 2021. No key brings it back. |
| MV2 | Keep Thorium's `allow_manifest_v2_extensions` runtime patch | Sideloaded/preinstalled MV2 (uBO classic) keeps working; CWS no longer serves MV2 — documented so it isn't filed as a Slipstream bug. |
| Repo visibility | **Public from day one** (Matt, 2026-08-30) — live at github.com/mcatsim/slipstream-browser | Transfer to the slipstream-browser org once Matt creates it (org creation has no API). Domains slipstreambrowser.com + slipstream-browser.com purchased by Matt 2026-08-30. |
| Chromium checkout | Full history (not `--no-history`) | Deviation from the original plan: tag checkouts and 2-week rebase cadence need tag fetches, which fight shallow clones. Disk (1.27 TB free) is not the constraint. |

## 2026-08-30 — v0.0 gate results

| Finding | Consequence |
|---|---|
| Stock Thorium build green on first attempt (4.5 h, `-j 22`, peak RAM fine with 96 GB pagefile) | Toolchain proven; SDK 26100 passed M152's checks (28000 installed anyway for future milestones). |
| CWS serves the browser normally; uBO Lite installed by hand; **uBO classic auto-preinstalled from CWS on new profile** (verified in test profile) | Keep Thorium's `preinstall-ublock-origin.patch`. Google's CRX service still serves the delisted MV2 package (2026-08-30). Fallback if that ever stops: swap the ID to uBO Lite (`ddkjiahejlhfcafbddmgiahcphecmpfh`). Nothing is bundled in the installer → no GPL redistribution obligations. |
| **Chromium's own hard-coded preinstall list also installed an Adobe Acrobat extension** (`efaidnbmnnnibpcajpcglclefindmkaj`) in the test profile | Bloat. New stage-90 patch planned: `90-trim-preinstalled-extensions.patch` — clear Chromium's partner preinstalls, keep only uBO. |

## 2026-08-30 — first branded build (v0.1.0-dev)

`slipstream.exe` built, launches, loads the Chrome Web Store, preinstalls
uBlock Origin. PE resource reads Slipstream / The Slipstream Browser Authors.
Artifacts: 186 MB installer + 552 MB portable zip.

Config couplings discovered by building (each cost a partial build; all now
documented so they never recur):

| Coupling | Resolution |
|---|---|
| `enable_background_mode=false` + extensions | Impossible: `chrome/browser/background/extensions/BUILD.gn` asserts it and is built whenever extensions are on. Flag dropped (caught at `gn gen`). |
| `enable_cdm_storage_id=true` + `enable_rlz=false` | `cdm_storage_id.cc` hard-errors "RLZ must be enabled on Windows/Mac". Disabled CDM storage ID; privacy wins, Widevine L3 unaffected. |
| Windows exe output name | Thorium writes `initialexe/thorium` and mini_installer consumes `$root_out_dir/thorium.exe` — both path-glued, so the rebrand pass correctly skips them. Fixed by `patches/90-windows-exe-output-name.patch` (6 refs, 2 files). |
| `--user` site-packages + 22 parallel build actions | `WinError 1450`; build now sets `PYTHONNOUSERSITE=1`. |

Rebrand-pass rule learned the hard way: replace a token **only as a standalone
word**. Renaming anything glued to an identifier char, a path separator, or a
file suffix breaks the build, because those symbols/dirs are defined outside
the allowlist (`base/`, `content/`, `components/vector_icons/thorium/`) and
referenced inside it.

## 2026-08-31 — POSTMORTEM: the blank-browser bug (v0.1.0-dev)

**Symptom reported:** "uBlock Origin has crashed."
**Actual fault:** every renderer process in the branded build died ~21ms after
launch with exit code 7. The browser rendered *nothing* — uBO's crash balloon
was simply the loudest symptom. Found by a 5-angle parallel investigation with a
stock-vs-branded A/B; root cause proven from PE import tables + Windows
CodeIntegrity event 3033 + source, not inference.

**Root cause — ours, not upstream.** `is_component_ffmpeg = true` (added by us
for a "clean LGPL posture") in a static `is_component_build = false` build makes
`ffmpeg.dll` a **load-time import of chrome.dll** in the application directory.
Renderers enforce Code Integrity Guard at process creation
(`chrome_content_browser_client.cc` `PreSpawnChild`: `enforce_code_integrity =
true` for `kRenderer`, unconditional in non-component builds). Only DLLs on that
function's `AllowExtraDll` list are exempt — `chrome.dll` and `chrome_elf.dll`
are; `ffmpeg.dll` was not. So `LoadLibraryExW(chrome.dll)` returned NULL in every
renderer → `main_dll_loader_win.cc:257` → exit 7 (`MISSING_DATA`).

| Fact | Evidence |
|---|---|
| 0 renderers branded vs 5-6 stock | process lists, `Target.getTargets` |
| all renderers exit 7 | `CrashExitCodes.Renderer` histogram, bucket 7 = 100% |
| ffmpeg.dll is the only import delta | PE import table: branded has it, stock doesn't |
| the kernel blocked it | CodeIntegrity/Operational event 3033 x208 naming ffmpeg.dll |
| sandbox is the gate | `--no-sandbox` on the same binary restores everything |

**Fix:** `is_component_ffmpeg = false`. Zero cost to fast/memory/secure pillars;
the only loss is the separate-DLL packaging posture — which was never a
Windows-appropriate knob (`ffmpeg_options.gni` documents it as a convenience for
Linux distro packagers). LGPL is satisfied instead by publishing pinned sources
and complete build instructions, which this repo does by construction.

**Lessons, now encoded as gates (docs/SMOKE.md):**
1. *Feature tests are not liveness tests.* The old checklist would have "passed"
   a browser that rendered nothing. Tier A liveness gates now run first and hard-stop.
2. *`--no-sandbox` invalidates a test run.* It made the broken build look healthy.
3. *This class of bug is invisible to Chromium's own diagnostics* — no Crashpad
   dump, no error log. Only Windows CodeIntegrity 3033 and the shutdown
   histograms record it. Both are now asserted.
4. *Build-time invariants beat runtime discovery:* `scripts/check-imports.py`
   turns this exact failure into a link-time error. Validated against both the
   known-bad and known-good builds; wired into `scripts/build.ps1`.

**Second real bug found and fixed in the same pass:** the internal URL scheme was
renamed one-sidedly. `content/public/common/url_constants.h` (outside the rebrand
allowlist) still said `"thorium"` while `chrome/` and `components/` emitted
`slipstream://`, so Copy-URL produced links that could not be pasted back and
`slipstream://version` never resolved. Unified on `slipstream` via
`patches/90-internal-url-scheme.patch`. One-sided renames are the rebrand pass's
characteristic failure mode — SMOKE.md gate B4 now scans for them.

**Exonerated (do not re-investigate):** the MV2 restore patch, the uBO preinstall,
the CWS pipeline, the rebrand pass itself, `use_on_device_model_service=false`
(the pre-flagged suspect — a red herring), and the three pillar pins
(`enable_backup_ref_ptr_support`, `v8_enable_sandbox`,
`v8_enable_pointer_compression`), all verified no-ops via byte-identical
buildflag headers and V8 snapshot blobs.

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
