# FAQ

**Why is there no Google account Sync?**
Google restricted the Sync API to official Chrome in March 2021. Every fork
lost it — no API key or patch brings it back. Use a password manager and
bookmark export/import, or a third-party sync extension.

**Windows SmartScreen warned me about the installer.**
Expected until our code-signing reputation accrues (see ROADMAP v0.3).
Verify the SHA-256 checksum and the build-provenance attestation from the
release page instead of trusting the banner.

**Is Safe Browsing on?**
The code is compiled in but inert: it needs a Google API key that is not
legally redistributable, and we ship no Google keys on principle. Windows
SmartScreen and the preinstalled uBlock Origin are the practical layer.

**Why did my Manifest V2 extension disappear from the Web Store?**
Google stopped serving MV2 store-wide. Slipstream keeps the MV2 *runtime*
alive, so sideloaded MV2 extensions still work — but the store only offers
MV3 versions. Our uBlock Origin preinstall still works.

**A website says my browser is Chrome. Why?**
The User-Agent keeps the `Chrome/<version>` token for site compatibility and
Web Store access. This is deliberate and load-bearing; don't file it.

**Tilt/motion web games don't work.**
Motion sensors are blocked by default (privacy). Re-enable per site at
`slipstream://settings/content/sensors`.

**Every HTTPS site shows certificate errors all of a sudden.**
Check your system clock. Slipstream doesn't query Google's network-time
service (privacy), so a badly skewed clock surfaces as cert errors.

**Memory Saver discarded a tab I cared about.**
Add the site to the exceptions at `slipstream://settings/performance`, or
turn Memory Saver off entirely. Discarded tabs reload with their state on
click.

**Can I squeeze more RAM savings out of it?**
Power-user opt-in: add `--process-per-site` to your shortcut to merge
same-site tabs into shared processes. Trade-offs documented in
[DEBLOAT.md](DEBLOAT.md) — bigger crash blast radius, coarser discarding.

**Is this related to "NAT Slipstreaming"?**
No. That's the name of a 2020 browser-delivered network attack technique by
Samy Kamkar (long since mitigated by browser port-blocking, including here).
We just both liked the aerodynamics metaphor. Also no relation to Windows
ISO "slipstreaming", the VPN, the racing game, or the pilot-logbook
extension.

**Why should I trust an unsigned browser from one person?**
You shouldn't, blindly. Read [SECURITY.md](SECURITY.md) — it says plainly
what this project can and cannot promise. Everything is built from public
source with pinned versions, published build scripts, checksums, and
provenance attestations you can verify.
