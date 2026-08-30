# Release smoke-test checklist

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
