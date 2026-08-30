# Building Slipstream on Windows

## Hardware floor

- 16+ cores strongly recommended (reference machine: Ryzen 9 9950X3D, 16C/32T)
- 32 GB RAM minimum **with a 96 GB fixed pagefile on the build NVMe**
  (the single ThinLTO link of chrome.dll transiently exceeds 32 GB;
  without the pagefile the build dies with LNK1102/LLVM OOM at ~95%).
  64 GB RAM is the highest-ROI upgrade for this workload.
- ~200 GB free NVMe (checkout ~110 GB with history + out dir 60–90 GB)
- First full build: **≈ 3.5–5 h**. Incremental: 15–45 min (LTO link dominates).

## Machine prep (elevated, one-time)

Run `D:\src\setup-elevated.ps1` as admin. It does:
1. Defender exclusions for `D:\src` + compiler processes (worth 25–40% wall
   time; scoped deliberately — do not exclude broader paths).
2. `fsutil 8dot3name set D: 1`
3. Pagefile: fixed 96 GB on D:, 4–16 GB on C: (**reboot required**).
4. Visual Studio 2026 Community: workload `NativeDesktop` +
   `VC.ATLMFC` + recommended components.
5. Windows 11 SDK 10.0.28000 (all features, includes Debugging Tools —
   Chromium needs ≥ 10.0.26100.3323 for large-page PDBs).

Also required once: `HKLM\...\FileSystem\LongPathsEnabled = 1` (already set
on the reference machine) and **disable VS auto-update** (Installer →
Settings) — Chromium pins toolchain expectations per milestone.

Git: identity + a conditional include keeps Chromium-specific settings
(`autocrlf=false`, `longpaths`, `fscache`) scoped to `D:\src` only — see
`D:\src\.gitconfig-chromium`.

## Toolchain (non-elevated)

- depot_tools from the **zip bundle** (not git clone) → `D:\src\depot_tools`,
  first on PATH. `DEPOT_TOOLS_WIN_TOOLCHAIN=0`, `vs2026_install` set.
  First `gclient` run bootstraps the rest.
- CPython 3.11 with the `py` launcher (Thorium's scripts invoke `py -3.11`).
- Ensure `where python3` resolves to `D:\src\depot_tools\python3.bat` first;
  disable Store app-execution aliases for python if they shadow it.

## Build sequence

```powershell
cd D:\src\slipstream
. .\scripts\env.ps1
# one-time: fetch --nohooks chromium  into D:\src\chromium (full history)
.\scripts\sync.ps1              # pin to Thorium's version, gclient sync + hooks
.\scripts\apply.ps1 -Stock      # v0.0: stock Thorium   (later: apply.ps1 for full)
.\scripts\build.ps1             # gn gen + autoninja -j 22
```

Gate for v0.0: `out\slipstream\thorium.exe` launches and installs an
extension from the Chrome Web Store.

## Timing/RAM notes for this config

- `-j 22`, not 32: clang-cl peaks 1–1.5 GB per TU; 32 jobs thrash 32 GB.
- `concurrent_links` stays default: Windows+ThinLTO auto-clamps to 1 link.
- Siso is the default build engine (`autoninja` dispatches); set
  `use_siso=false` + `gn clean` if you need classic ninja determinism.
- Never run VMs/containers/games during the final link.
- Record exact `cl.exe`/SDK versions here per release.
