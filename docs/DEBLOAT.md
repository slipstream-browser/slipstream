# Debloat design (what Slipstream strips, and what it deliberately keeps)

Order of preference: **GN arg → default pref → small patch** (every patch is
rebase debt).

## GN args added on top of Thorium's win_AVX2_args.gn

| Arg | Value | Why |
|---|---|---|
| `enable_rlz` | `false` | Google install-attribution library; Thorium leaves it on. Highest-value single flag. |
| `enable_background_mode` | `false` | Compile out the tray background host (Thorium only flips the pref). |
| `enable_background_contents` | `false` | Legacy hosted-app background pages. Test one MV3 service-worker extension before shipping. |
| `enable_service_discovery` / `enable_mdns` | `false` | Kills mDNS/DIAL background chatter (Cast already hidden by Thorium). |
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

## Verification per release

10-minute idle capture must show **zero** requests to UMA/variations/
optimization-guide/RLZ endpoints; CWS install + update must succeed.
