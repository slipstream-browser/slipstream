# Release smoke-test checklist

> **RULE 0 — the sandbox stays ON.** A run with `--no-sandbox` is NOT VALID FOR
> RELEASE and satisfies no gate below. The v0.1 blank-browser bug reproduced
> *only* with the sandbox on; `--no-sandbox` made everything look healthy.
>
> **RULE 1 — process liveness before features.** Gates A1-A3 run first. If any
> fails, STOP: the browser is not rendering and every downstream "PASS" is
> meaningless. Our first branded build failed A1 while appearing to merely have
> "a crashing extension".

## Tier A - liveness gates (hard stop on failure)

**A1. Renderers exist and execute.** After launch + navigating to a real page:
at least one `--type=renderer` process is alive, the page target's title is
non-empty, and CDP `Runtime.evaluate('1+1')` returns `2` within 10s.

**A2. Zero crash histograms.** Close via CDP `Browser.close` (NEVER kill -9 —
histograms are only dumped on clean shutdown), then assert `CrashExitCodes.Renderer`,
`CrashExitCodes.Extension` and `BrowserRenderProcessHost.ChildCrashes` have zero
samples, and `Renderer.BrowserLaunchToRunLoopStart` has at least one.
(Exit code 7 = `CHROME_RESULT_CODE_MISSING_DATA` = chrome.dll failed to load.)

**A3. No Windows Code Integrity blocks.** Snapshot the
`Microsoft-Windows-CodeIntegrity/Operational` log before the run; assert zero new
Event ID 3033 entries naming our exe afterwards. This is the ONLY place this class
of failure is recorded — Chromium's logs and Crashpad are empty by construction.

**A4. Default extension actually works.** A `background_page` target exists for
uBlock Origin (`cjpalhdlnbpafiamejdnhcphjbkeiagm`), `chrome://extensions` shows it
enabled with `disable_reasons=[]`, AND a known ad URL returns `ERR_BLOCKED_BY_CLIENT`
— verify it *functions*, not merely that it installed.

## Tier B - build-time gates (run before any browser starts)

**B1. Import-table check:** `py -3.11 scripts/check-imports.py <out>/chrome.dll`
must pass — no app-directory DLL may be a load-time import (renderer CIG blocks
them). Wired into `scripts/build.ps1`; validated against the known-bad build.

**B2. Effective-arg diff** vs the pinned baseline (`gn args --list --short` for
both out dirs) plus a diff of `gen/**/buildflags.h`. Review the deltas, not prose.

**B3. Rebrand leftover scan:** case-insensitive `thorium` sweep over allowlisted
dirs, shipped binary string tables, `out/<config>/` filenames, and a fresh
profile's files — diffed against a checked-in reviewed allowlist.

**B4. Cross-boundary constant check:** for every literal `rebrand.py` rewrites,
assert no identical sibling literal survives un-rewritten outside the allowlist.
One-sided renames are the rebrand's characteristic failure mode (they caused both
the `slipstream://` scheme split and the exe-name build break).

## Tier C - functional checklist

Run against every packaged build before publishing. Items 3–5 are the two
properties most likely to silently regress (CWS + zero-telemetry) — never skip.

1. `chrome://version` — Slipstream name, correct product + Chromium versions.
2. `chrome://gpu` — hardware acceleration active, no software fallback.
3. **CWS install**: open chromewebstore.google.com, install uBlock Origin
   Lite → succeeds without workarounds.
4. **CWS update**: `chrome://extensions` → Developer mode → Update →
   completes; `chrome://net-export` capture shows a 200 from
   `clients2.google.com/service/update2/crx`.
5. **Zero-telemetry egress**: 10-min idle run behind a local proxy
   (Fiddler/mitmproxy). Assert ZERO requests to:
   `*.google-analytics.com`, `clients4.google.com/chrome-variations`,
   `optimizationguide-pa.googleapis.com`, `*/uma`, RLZ endpoints.
   Expected/allowed: component updater (CRLSet/root store), CWS/crx checks,
   Widevine component fetch.
6. Installer: installs to its own registry root + `%LOCALAPPDATA%\Slipstream`,
   coexists with Chrome (and Thorium if present); uninstall leaves no
   orphaned keys under the Slipstream GUIDs.
7. DRM: a Widevine site (Spotify Web) works after the runtime component
   fetch completes (`chrome://components` shows Widevine).
8. `py -3.11 third_party\thorium\check_simd.py` — binary matches the
   intended SIMD profile (avx2_fma).
9. Portable zip: unzip to a new folder, launches, writes profile locally,
   no installer registry writes.
10. One MV3 service-worker extension functions (regression check for
    `enable_background_contents=false`).

## Pillar-design additions (docs/PILLARS.md)

11. **WebRTC ICE-candidate leak check** (C2 invariant gate): local-IP
    concealment holds — no private IPs in candidates (offline harness or
    browserleaks-equivalent page).
12. Extension auto-update + uBO filter-list fetch succeed **while Memory
    Saver has discarded tabs** (and nightly: while commit-limit discard is
    active).
13. Idle capture (item 5) additionally asserts zero requests to
    `clients2.google.com/time`.
14. Nightly, once network-service sandbox lands: proxy-auth, captive portal,
    uBO list fetch, CWS install, component update — all under the sandboxed
    network service.
15. Nightly, once content verification is at BOOTSTRAP/ENFORCE: corrupt-byte
    detect/repair test; delisted-MV2 uBO preinstall still passes verification.
16. Nightly, once elevation service lands: `sc qc` shows the service, ABE
    CLSID resolves, app-bound key blob present, v20 cookies decrypt;
    per-user install negative test (stays DPAPI v10).
