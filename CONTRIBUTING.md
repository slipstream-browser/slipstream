# Contributing to Slipstream Browser

Thanks for your interest! This is a solo-maintained Chromium fork with a
deliberately thin delta — the contribution rules exist to keep the 2-week
Chromium rebase cadence survivable.

## Ground rules

1. **Don't send Chromium bugs here.** Rendering glitches, web-platform
   behavior, crashes deep in Blink/V8 → [crbug.com](https://crbug.com).
   Thorium-patch behavior → [Thorium's tracker](https://github.com/Alex313031/thorium/issues).
   If unsure, file here and we'll route it.
2. **Every patch is rebase debt.** PRs that add patches must justify why a
   GN arg or default pref can't do the job (that's also the order we prefer:
   GN arg → pref → feature flip → patch). Large invasive patches will be
   declined regardless of quality — see the non-goals in
   [docs/PILLARS.md](docs/PILLARS.md).
3. **One patch per PR**, applying cleanly through `scripts/apply.ps1`, with
   a green build and the smoke checks in [docs/SMOKE.md](docs/SMOKE.md)
   relevant to your change.
4. **DCO sign-off required** (`git commit -s`). By signing off you certify
   the [Developer Certificate of Origin](https://developercertificate.org/).
   License is BSD-3-Clause.
5. **CWS compatibility is sacred.** Anything touching `extensions/`,
   `webstore_private`, CRX verification, or the User-Agent Chrome token is
   rejected by default.

## Getting started

- Build setup: [docs/BUILDING-WINDOWS.md](docs/BUILDING-WINDOWS.md)
- Architecture (submodule + overlay + stage-90 series): [README](README.md#how-its-built)
- Per-release rebase flow: [docs/REBASE.md](docs/REBASE.md)

## Good first contributions

- Smoke-test reports on hardware we don't have (SSE4-only CPUs, 8GB RAM boxes)
- Documentation fixes and FAQ additions
- Patch-lag table verification
- Icon/theme assets (see branding/THEME.md for the palette)

## Security issues

Never in public issues — use GitHub Private Vulnerability Reporting.
See [docs/SECURITY.md](docs/SECURITY.md).
