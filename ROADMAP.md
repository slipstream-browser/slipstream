# Roadmap

Solo maintainer with a day job — dates are honest estimates, not promises.
The [SECURITY.md](docs/SECURITY.md) patch-lag SLO always outranks feature work.

| Milestone | Contents | Status |
|---|---|---|
| **v0.0** — prove the build | Stock Thorium M152 built from source on the reference machine; CWS verified | ✅ Done (2026-08-30) |
| **v0.1** — first release | Slipstream branding + install identity; debloat/privacy/memory/security patch set ([PILLARS.md](docs/PILLARS.md)); DuckDuckGo default; theme v1; portable zip + installer, unsigned, SHA-256 + provenance attestation; SignPath signing application filed | 🔨 In progress |
| **v0.2** — cadence + updates | First upstream rebase proving the pipeline; in-app update checker (GitHub Releases poll, no silent installs); Scoop bucket; nightly-lane features promoted per gates | Planned |
| **v0.3** — signed + discoverable | Code-signed installers (SignPath); winget manifest; SBOM; patch-lag table publishing | Planned |
| **v0.4** — cadence proof | Four consecutive on-time rebases; upstream-release tracking automation | Planned |
| **v1.0** — stable | 12 months of published patch-lag data; SmartScreen reputation; attorney trademark check; succession/EOL policy | Aspirational |

Stretch (v1.0+): rebranded Omaha 4 auto-updater, reproducible builds,
additional CPU variants (SSE4) on demand.
