# Debloat design (what Slipstream strips, and what it deliberately keeps)

Order of preference: **GN arg → default pref → small patch** (every patch is
rebase debt).

## GN args added on top of Thorium's win_AVX2_args.gn

| Arg | Value | Why |
|---|---|---|
| `enable_rlz` | `false` | Google install-attribution library; Thorium leaves it on. Highest-value single flag. |
| `enable_mdns` | `false` | Kills mDNS/DIAL chatter AND is the PRIV-03 local-IP concealment lever (paired with the WebRTC pref, C2 invariant). `enable_service_discovery` is derived from this (features.gni) — never set it directly. |

**Dropped at the gn-gen gate (M152), do NOT re-add:**
- `enable_background_mode=false` / `enable_background_contents=false` — `chrome/browser/background/extensions/BUILD.gn` asserts `enable_background_mode`, and that target is pulled in whenever extensions are enabled. Extensions (CWS) are a hard requirement, so background mode cannot be compiled out at M152. Re-check each milestone; if upstream decouples them, revisit.
| `is_component_ffmpeg` | `true` | LGPL hygiene (separate ffmpeg.dll). |
| `bundle_widevine_cdm` | `false` | Runtime component fetch instead — clean redistribution posture. |
| `safe_browsing_mode` | `1` (keep) | See DECISIONS.md. |

Verify each against `docs/gn_all_args.txt` for the pinned milestone before
shipping — the arg surface churns.

## Stage-90 patches (see patches/series)

metrics off · crash-upload off (local minidumps kept) · variations fully
neutered · component-updater trimmed **surgically** · optimization-guide
fetches off · promo surfaces removed · default-prefs hardening (no prefetch,
no search suggest, DoH secure, no UKM).

## Deliberately KEPT (do not "debloat" these)

- Component updater's security components: **CRLSet, Chrome Root Store,
  Origin Trials, cert components** — the out-of-band security channel.
- Certificate transparency log list updates.
- The entire extension update pipeline and `webstorePrivate` API.
- The `Chrome/<major>.0.0.0` User-Agent token (CWS gates on it).
- Windows download quarantine / MotW.
- `chrome://net-internals`, `chrome://policy` (support tooling).

## Pillar design (2026-08-30)

The memory/privacy/security feature set is specified in `docs/PILLARS.md`
(verified implementation plan) and `docs/pillar-proposals.json` (evidence).

**Known FAST costs, accepted deliberately** (PILLARS.md C6/C7):
- Purge-on-freeze also purges bfcache pages → back-navigations rebuild caches.
- Default-search renderer no longer pinned alive → tens of ms on first search
  after process death (masked by network; search-suggest is off anyway).

**Deliberately KEPT despite memory cost** (security wins):
- Strict site isolation, BackupRefPtr/MiraclePtr
  (build_overrides/partition_alloc.gni), the warm spare renderer,
  Blink's strong memory cache (pressure-purged instead).

**Power-user memory opt-in** (documented, never default): add
`--process-per-site` to a shortcut to merge same-site tabs into one process.
Caveats: bigger crash blast radius, coarser tab discarding. The shipped
default already includes upstream's bounded same-site reuse
(kProcessPerSiteUpToMainFrameThreshold: 2 frames / 2 GB cap).

## Verification per release

10-minute idle capture must show **zero** requests to UMA/variations/
optimization-guide/RLZ endpoints; CWS install + update must succeed.
