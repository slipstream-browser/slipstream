# Per-release rebase workflow

Target: ~30 min human attention + ~4 h machine time; release published
24–72 h after Thorium's tag.

```powershell
cd D:\src\slipstream
git checkout -b rebase/M<next>

# 1. Bump the pin
git -C third_party\thorium fetch --tags
git -C third_party\thorium checkout M<next-tag>

# 2. Review what changed upstream in the things we depend on
git -C third_party\thorium diff <old>..<new> -- patch_scripts/series/series
git -C third_party\thorium diff <old>..<new> -- src/chrome/app/theme
#    + diff Chromium's BRANDING and chromium_install_modes.h vs our overlay copies

# 3. Re-sync, re-apply (fix rejects — only our ≤12 patches can reject;
#    overlay files never can), rebuild, smoke, refresh patches
.\scripts\sync.ps1
.\scripts\apply.ps1
.\scripts\build.ps1
# smoke test per docs/SMOKE.md, then refresh.ps1, commit, tag, release

# 4. Diff docs/gn_all_args.txt vs previous milestone — catches renamed/removed
#    GN args before they bite.
```

Update `VERSION.json` and the patch-lag table every release.

## If Thorium goes dormant (trigger: 60 days inactive on both repos)

1. Vendor the submodule at the last good tag (nothing else changes).
2. Point the version pin at a newer Chromium stable tag; replay the same
   series; expect 10–30 rejects/milestone (~4–12 h).
3. If self-maintaining long-term: triage the ~180-patch series down to the
   ~40 that matter (build/SIMD, codecs, debloat, MV2, branding).
