# Security policy (draft — finalize before the repo goes public at v0.1)

## The core disclosure

Slipstream is a fork of Thorium, which is a fork of Chromium. **It inherits
every Chromium vulnerability until a rebased release ships.** Chromium ships
stable security updates roughly every two weeks (weekly security refreshes on
top), and n-day exploitation begins within days of disclosure. Any Slipstream
release older than current Chromium stable should be assumed vulnerable.

## Patch-lag SLO (falsifiable, published)

- Target: security release within **7 days** of the corresponding upstream
  Chromium stable; within **3 days** when upstream flags in-the-wild
  exploitation.
- Every release note states: `Chromium <ver>, upstream release <date>,
  lag <N> days`. Historical table: `docs/patch-lag.md`.
- If a release will miss the SLO: a pinned issue titled `[LAG] Chromium <ver>`
  within 24 h of the upstream release, recommending users switch to Chrome or
  Edge until it lands. The *notification* is the hard commitment.

## Honest limitations

This is not a replacement for a vendor-supported browser. Chrome, Edge, and
Firefox have full-time security teams, fuzzing fleets, and incident response.
This project is one person rebasing upstream fixes. No continuous fuzzing, no
0-day response capability. If your threat model includes targeted attackers,
use Chrome or Edge.

Additional posture notes:
- **Safe Browsing is inert** in distributed builds (no Google API key, by
  policy). Practical layer: Windows SmartScreen + preinstalled uBlock Origin.
- Windows download quarantine / Mark-of-the-Web is **kept** (we exclude the
  upstream Thorium patch that disables it).
- No telemetry means no crash-report pipeline: report crashes manually.

## Reporting

GitHub Private Vulnerability Reporting (enable at repo publish) is the only
channel. Acknowledgement target: 72 h. No bug bounty — this project has no
revenue; reporters are credited in release notes.

In scope: Slipstream's own patches, build config, installer, release
infrastructure. Out of scope: upstream Chromium bugs (→ crbug.com), Thorium
bugs (→ Thorium's tracker), SmartScreen warnings on unsigned builds, missing
Sync.

## Abandonment clause

If this project is abandoned, the final release note and README will say so
within 30 days.
