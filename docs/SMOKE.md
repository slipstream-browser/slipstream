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
