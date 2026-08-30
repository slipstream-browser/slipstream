# Pillar design — verified proposals (2026-08-30)

Machine-verified against Chromium 152.0.7977.55 + Thorium M152 series by a 7-agent
adversarial workflow (3 designers, 3 tree-grepping verifiers, 1 conflict judge).
Every proposal carries file:line evidence from the pinned tree. The judge's
implementation plan is in PILLARS.md; this file is the full evidence record.

# Cross-Pillar Conflict Adjudication — Slipstream v0.1/v0.2

Verified against D:\src\slipstream (patches/series, patches/thorium_exclusions.txt, docs/DECISIONS.md, docs/DEBLOAT.md) at 2026-08-30. Pillar priority applied: **SECURE > PRIVACY > FAST > MEMORY** when irreconcilable.

---

## Part 1 — Conflicts and rulings

### C1. SEC-CONF-02 (exclude flags-conf patch) vs MEM-10 (ship commented `--process-per-site` example in the flags conf) — **REAL CONFLICT, security wins**

MEM-10's delivery mechanism is exactly the file SEC-CONF-02 removes: it proposes shipping a commented example in the conf consumed by `windows-thorium-flags-conf.patch`, and SEC-CONF-02 excludes that patch as a no-admin persistence/desandbox vector (verified: `chrome_main_delegate.cc:546-624` appends every switch from user-writable `%APPDATA%`, filtering only `--process-type`/`--user-data-dir`).

**Ruling:** SEC-CONF-02 lands unchanged. MEM-10 is re-homed to **documentation only**: a DEBLOAT.md/FAQ section showing how to add `--process-per-site` to a shortcut, with the crash-blast-radius and poor-discard-granularity caveats, plus a pointer to the already-default `kProcessPerSiteUpToMainFrameThreshold` (2 frames / 2 GB cap) as the shipped middle ground. If flags-from-file is ever wanted, implement SEC-CONF-02's exe-dir-only variant — that variant would then be MEM-10's home. Both proposals' substance survives.

### C2. PRIV-02 ↔ PRIV-03 — **hard coupling, not a conflict; enforce atomicity**

`enable_mdns=false` (already in config/win_x64_avx2.gn:79) compiles out the mDNS responder that conceals local IPs in ICE candidates; PRIV-02's `default_public_interface_only` is what makes that safe. Verified load-bearing by the privacy verdicts.

**Ruling:** PRIV-02 must be in the same release as any build with `enable_mdns=false` — which means **v0.1 cannot ship without PRIV-02**. Record an invariant in DECISIONS.md: "revert PRIV-02 ⇒ revert `enable_mdns` to true in the same commit." Add a WebRTC ICE-candidate leak check (browserleaks.com/webrtc equivalent, offline harness) to docs/SMOKE.md as a per-release gate.

### C3. PRIV-10 (network time off) vs SECURE (bad-clock SSL interstitial) — **privacy wins, cost accepted**

Interacts mildly with SEC-HFM-01: HTTPS-First raises overall interstitial exposure, and a skewed-clock user now gets a generic cert error instead of "fix your clock." Windows NTP keeps this rare on the target platform.

**Ruling:** Keep PRIV-10. Document the trade in DECISIONS.md and add a FAQ line ("cert errors everywhere? check your system clock"). Also fix DEBLOAT.md's verification-bar wording per the verdict: the flip *widens* the zero-idle-traffic bar (add `clients2.google.com/time` to the idle-capture blocklist) rather than being required by the existing one.

### C4. BackupRefPtr memory overhead vs SECURE (MEM-08) — **security wins, pre-resolved**

Docs-only. Cite `build_overrides/partition_alloc.gni:74-106` (not partition_alloc.gni:265-269 alone) per the verdict's citation correction.

### C5. `--process-per-site` default vs strict site isolation — **already dissolved**

Both the memory audit (MEM-10) and the security non-goals audit independently concluded: opt-in only, site isolation untouched (`kSitePerProcess` on, no Thorium patch touches it). Nothing to arbitrate beyond C1's re-homing.

### C6. MEM-04 (purge-on-freeze) vs FAST (bfcache/back-nav) — **memory wins, cost noted**

The purge also fires on bfcache freezes, so back-navigations pay a cache-rebuild. This is the same trade Android ships by default; upstream provides no bfcache carve-out. Accept; one line in DEBLOAT.md's "known FAST costs."

### C7. MEM-06 (DSE renderer keep-alive off) vs FAST — **memory wins**

Tens of ms on the first search after process death, masked by network + the warm spare renderer (kept per memory non-goals). Synergy: search-suggest is already off in the prefs-hardening plan, making a hot DSE renderer even less valuable. Accept; DEBLOAT.md entry.

### C8. Tab discard/freeze stack (MEM-01/02/03/05) vs extension background behavior / CWS updater — **non-conflict, verified**

Extension background pages and MV3 service workers are not tab PageNodes; the freeze eligibility set and discard pipeline never touch them, and the extension auto-updater runs in the browser process. Confirmed across three independent verdicts. **Action:** add one belt-and-suspenders case to SMOKE.md — trigger an extension update and a uBO filter-list fetch while Memory Saver has discarded tabs and (nightly) while the commit-limit path is active.

### C9. SEC-NETSBX-05 + SEC-RAC-06 sandbox flips vs FAST/MEMORY — **negligible, staged**

One AppContainer token and sub-ms process-launch overhead. Non-conflicts, but both carry compat risk from third-party injectors (AV/VPN/IME), so they take the burn-in lanes below. SEC-RAC-06's rollout notes must mention the existing `RendererAppContainerEnabled` enterprise-policy off-switch (found during verification).

### C10. SEC-EPD-07 — **keep the flip, replace the story (verdict: modify)**

The mechanism is inverted from the proposal text: sandboxed children already get `MITIGATION_EXTENSION_POINT_DISABLE` unconditionally (`sandbox_win.cc:479-485`); the feature flip actually arms the **browser-process** lockdown via the chrome_elf beacon, with a legacy-IME auto-opt-out and the `kBlockBrowserLegacyExtensionPoints` policy override, taking effect on second launch. Land the same one-line flip with the corrected rationale in the patch header and SECURITY.md. The IME risk the proposal feared is already auto-mitigated in code.

### C11. SEC-ABE-04 vs Thorium's `mini_installer.patch` — **mechanism conflict inside the series, resolved by targeted revert**

The GOOGLE_CHROME_BRANDING guards around `AddElevationServiceWorkItems` are *added by Thorium*, not upstream (verdict: modify). Excluding all of `mini_installer.patch` would lose unrelated installer branding work, so instead ship a stage-90 patch that reverts only the two guard hunks. **Precondition:** determine why Thorium disabled elevation-service registration (likely unsigned-installer COM-service concerns) before promoting past nightly; Slipstream's signing posture must support a registered SYSTEM COM service. Pieces 2 (fresh GUIDs from brand.json into `chromium_install_modes.h` — mandatory, stock GUIDs collide with vanilla Chromium side-by-side) and 3 (system-level installer as recommended default) stand as written.

### C12. MEM-05 (infinite-tabs freezing) vs FAST/web-compat — **staged, as proposed**

Ships disabled in v0.1, on in nightly, default at v0.2 after soak. When promoted, it subsumes most of MEM-03's pressure path (same kInfiniteTabs freezing type, same 5-MRU protection) — note in the patch header so nobody "cleans up" MEM-03 as redundant beforehand.

### C13. PRIV-06 (sensors BLOCK) vs gamer audience — **resolved via FAQ**

Tilt-based web games get a per-site re-enable path at chrome://settings/content/sensors; sites see "no sensor," not an exception. Ship with the FAQ entry.

### C14. SEC-BADFLAG-03 vs power-user UX — **security wins, cosmetic cost**

Dismissible infobar per session for users deliberately running the four restored-warning flags. Complements SEC-CONF-02 and SEC-LOADEXT-08 as the anti-tamper trio; land all three together in v0.1.

No other pairwise conflicts found. HTTPS-First-vs-compatibility was pre-resolved by choosing balanced auto-enable (user pref always wins, `HasPrefPath` check verified); process-per-site-vs-isolation by C1/C5; discard-vs-CWS by C8.

---

## Part 2 — Final ordered implementation list

### A. `config/win_x64_avx2.gn` (GN args — land first, all v0.1)

| # | Arg | Source | Note |
|---|---|---|---|
| 1 | `v8_enable_pointer_compression = true` | MEM-07 | Assert-pin. Comment cites v8/BUILD.gn:632-634 and :730-735 (corrected lines). |
| 2 | `v8_enable_sandbox = true` | SEC-V8SBX-11 | Assert-pin; gen-time failure on drift. |
| 3 | `enable_backup_ref_ptr_support = true` | MEM-08 | Optional pin; decision recorded in DEBLOAT.md either way. |
| 4 | `use_on_device_model_service = false` (+ `build_with_model_execution = false` if link requires) | MEM-09 | **Gated:** trial build + CWS smoke test green, else defer to v0.2. Least-traveled config. |
| 5 | `enable_mdns = false` — *stays*, now with C2 invariant comment | PRIV-03 | Pairing rule: valid only while PRIV-02 ships. |

### B. `patches/thorium_exclusions.txt` (pure exclusions — v0.1, rebase burden decreases)

| # | Exclusion | Source |
|---|---|---|
| 6 | `other/windows-thorium-flags-conf.patch` | SEC-CONF-02 (winner of C1) |
| 7 | `other/relax-bad-flags-warning.patch` | SEC-BADFLAG-03 |
| 8 | `other/ftp-support-thorium.patch` | SEC-FTP-10 — run the apply-order dry run for hunk-context drift first (symbol deps already cleared) |

### C. `patches/90-default-prefs-hardening.patch` (extend the already-planned patch — v0.1)

Order within the patch is irrelevant; listed by file:

| # | Change | Source |
|---|---|---|
| 9 | `kMemorySaverModeState` default → `kEnabled` (2) — components/performance_manager/user_tuning/prefs.cc | MEM-01 |
| 10 | `kCookieControlsMode` default → `kBlockThirdParty` (1) — cookie_settings.cc | PRIV-01 |
| 11 | `webrtc.ip_handling_policy` default → `default_public_interface_only` — browser_ui_prefs.cc (post-Thorium context) | PRIV-02 (**required for v0.1**, per C2) |
| 12 | `kEnableHyperlinkAuditing` default → false — chrome_content_browser_client.cc | PRIV-04 |
| 13 | `kPasswordLeakDetectionEnabled` default → false — password_manager.cc | PRIV-08 |
| 14 | IDLE_DETECTION default ASK → BLOCK — content_settings_registry.cc | PRIV-05 |
| 15 | SENSORS default ALLOW → BLOCK — content_settings_registry.cc | PRIV-06 (+ FAQ entry, C13) |

### D. New stage-90 patches (suggested file names, append to patches/series in this order)

**v0.1, default-on:**

| # | Patch file | Contents |
|---|---|---|
| 16 | `patches/90-memory-feature-defaults.patch` | MEM-02 `kDiscardOnCommitLimit` → enabled; MEM-03 `kInfiniteTabsFreezingOnMemoryPressure` → enabled; MEM-04 `kMemoryPurgeOnFreeze` → enabled on desktop; MEM-06 `kKeepDefaultSearchEngineRendererAlive` → disabled. Header notes C6/C7 accepted FAST costs and the MEM-05 subsumption note (C12). |
| 17 | `patches/90-privacy-feature-defaults.patch` | PRIV-09 `kAutofillServerCommunication` → disabled (header: debug-namespace rebase caveat + kAutofillServerURL fallback); PRIV-10 `kNetworkTimeServiceQuerying` → disabled (header: C3 trade). |
| 18 | `patches/90-security-feature-defaults.patch` | SEC-HFM-01 `kHttpsFirstBalancedModeAutoEnable` → enabled (prefs untouched — user choice wins); SEC-EPD-07 `kWinSboxDisableExtensionPoints` → enabled with **corrected rationale** (C10: browser-process lockdown, IME auto-opt-out, policy override, effective second launch). |
| 19 | `patches/90-restore-blink-secure-defaults.patch` | SEC-BLINK-09: `kBlockMidiByDefault` → re-enabled, `kFileSystemUrlNavigation` → re-disabled. Applies after Thorium's thorium-blink-feature-defaults.patch; keeps its BrowsingTopics disables. |
| 20 | `patches/90-battery-status-desktop-constant.patch` | PRIV-07: constant plugged-in tuple in BatteryDispatcher::OnDidChange (~10 lines). |
| 21 | `patches/90-gate-load-extension-devmode.patch` | SEC-LOADEXT-08: `--load-extension` requires `kExtensionsUIDeveloperMode`; anchor on switch-name constants; document Selenium workaround. |

**v0.1 nightly burn-in (land the patch, feature promoted only after the gate):**

| # | Patch file | Contents / gate |
|---|---|---|
| 22 | `patches/90-network-service-sandbox.patch` | SEC-NETSBX-05: `kNetworkServiceSandbox` + `kWinSboxNetworkServiceSandboxIsLPAC` → enabled. Gate: SMOKE.md proxy-auth/captive-portal/uBO-fetch/CWS-install/component-update pass. `kNetworkServiceCodeIntegrity` staged separately after one cycle. |
| 23 | `patches/90-extension-content-verification.patch` | SEC-CV-12: non-branded default NONE → **BOOTSTRAP** for one pre-release cycle → ENFORCE. Gate: corrupt-byte detect/repair test + delisted MV2 uBO preinstall passes verification (else allowlist preinstall path or hold at BOOTSTRAP). |
| 24 | `patches/90-enable-elevation-service.patch` | SEC-ABE-04 piece 1 as corrected in C11: revert Thorium's two mini_installer.patch guard hunks. Plus: GUID wiring in the branding overlay (piece 2), system-level installer default (piece 3). Gates: full SEC-ABE-04 smoke list (sc qc / CLSID / APPB blob / v20 cookies / per-user v10 negative test) + install/upgrade/uninstall cycles + answer to "why did Thorium guard it." |
| 25 | `patches/90-renderer-appcontainer.patch` | SEC-RAC-06: `kRendererAppContainer` → enabled, **canary/nightly tag only** for one full cycle; promote on clean crash/white-screen reports. Rollout notes name the `RendererAppContainerEnabled` policy off-switch (C9). |

**v0.2 candidate:**

| # | Patch file | Contents |
|---|---|---|
| 26 | `patches/90-infinite-tabs-freezing.patch` | MEM-05: `kInfiniteTabsFreezing` → enabled. Lands commented-out/disabled in v0.1 series, nightly-enabled, promoted at v0.2 per soak gate (C12). |

### E. Documented-only (no code)

| # | Item | Where |
|---|---|---|
| 27 | `--process-per-site` power-user opt-in via shortcut flags (re-homed per C1), with blast-radius caveats and the bounded upstream default as the recommended middle ground | DEBLOAT.md + FAQ |
| 28 | BRP/MiraclePtr kept — cost class, corrected citation | DEBLOAT.md "deliberately KEPT" (MEM-08) |
| 29 | PRIV-02↔enable_mdns pairing invariant + ICE-leak release gate | DECISIONS.md + SMOKE.md (C2) |
| 30 | Network-time trade + clock-skew FAQ + idle-capture bar widened to include `clients2.google.com/time` | DECISIONS.md + DEBLOAT.md + FAQ (C3) |
| 31 | PRIV-11 default-search decision — **user decision required before v0.1**: option B (initial_preferences DDG seed, cheap) vs C (choice screen, brand-defensible, real rebase cost). Recommend B for v0.1 with C re-evaluated at v1.0 | DECISIONS.md |
| 32 | ABE scope: per-user/portable installs silently stay DPAPI (v10); interaction with kept `disable-encryption.patch` portable switches | SECURITY.md (SEC-ABE-04) |
| 33 | All three pillars' non-goals lists (farbling out of scope, V8 untouched, keyless Safe Browsing posture, MV2 risk, FTP removal as product-identity call, etc.) | SECURITY.md / DEBLOAT.md non-goals sections |

### SMOKE.md additions rolled up
Per-release: CWS install + auto-update (existing) · ICE-candidate leak check (C2) · extension update under active discard/commit-limit pressure (C8) · proxy-auth/captive-portal under sandboxed network service (#22) · content-verification corrupt/repair + uBO preinstall (#23) · full ABE checklist + per-user negative test (#24) · idle capture now also asserts zero `clients2.google.com/time` requests (C3).

### Dependency/order summary
1. Section A + B first (build-config and exclusions change what stage-90 patches apply against).
2. #11 (PRIV-02) must be in every shipped build while A#5 stands — hard invariant.
3. #16-21 land one at a time with green rebuilds, matching the existing series discipline.
4. #22-25 are patch-landed but gate-promoted; #24 blocked on the Thorium-guard-rationale investigation.
5. #26 is the only v0.2 default; everything else targets v0.1.
