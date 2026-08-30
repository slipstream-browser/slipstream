# Apply Thorium (+ Slipstream delta) onto the pristine Chromium tree.
#   .\scripts\apply.ps1 -Stock     -> unmodified Thorium only (v0.0 gate)
#   .\scripts\apply.ps1            -> Thorium (minus exclusions) + Slipstream
# Must ALWAYS start from a clean tree; this script resets it first.
param([switch]$Stock)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

Write-Output "=== [1/5] Reset Chromium tree to pristine (keeps out/ and gclient deps) ==="
git -C $env:CR_DIR checkout -f
git -C $env:CR_DIR clean -fd -e out    # no -x: gclient-managed ignored deps must survive

Write-Output "=== [2/5] Thorium version pin + overlay + patch series ==="
py -3.11 "$env:THOR_DIR\version.py"
if ($Stock) {
    py -3.11 "$env:THOR_DIR\setup.py" --avx2 --chromium-src $env:CR_DIR
    if ($LASTEXITCODE -ne 0) { throw "thorium setup.py failed: $LASTEXITCODE" }
    Write-Output "=== Stock Thorium applied. Done (skipping Slipstream delta). ==="
    exit 0
}

# Full pipeline: overlay Thorium src/, then its series MINUS our exclusions.
robocopy "$env:THOR_DIR\src" $env:CR_DIR /E /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) { throw "robocopy thorium overlay failed: $LASTEXITCODE" }

$exclusions = Get-Content "$env:SLIP_DIR\patches\thorium_exclusions.txt" |
    Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object { $_.Trim() }
$effective = Get-Content "$env:THOR_DIR\patch_scripts\series\series" |
    Where-Object { $line = $_.Trim(); -not ($exclusions | Where-Object { $line -like "*$_*" }) }
$effectiveFile = "$env:TEMP\slipstream_effective_series"
Set-Content $effectiveFile $effective
Write-Output "Effective series: $($effective.Count) lines ($($exclusions.Count) exclusion rules)"

py -3.11 "$env:THOR_DIR\patch_scripts\series\apply_series.py" `
    --thorium-root $env:THOR_DIR --source-tree $env:CR_DIR --series $effectiveFile --apply
if ($LASTEXITCODE -ne 0) { throw "apply_series.py failed: $LASTEXITCODE" }

# Thorium's post-patch string sync steps (mirror setup.py)
foreach ($s in 'sync_grd_strings.py', 'merge_thorium_xtb.py') {
    $p = Get-ChildItem $env:THOR_DIR -Recurse -Filter $s -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p) { py -3.11 $p.FullName; if ($LASTEXITCODE -ne 0) { throw "$s failed" } }
}

Write-Output "=== [3/5] Slipstream whole-file overlay ==="
robocopy "$env:SLIP_DIR\overlay\src" $env:CR_DIR /E /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) { throw "robocopy slipstream overlay failed: $LASTEXITCODE" }

Write-Output "=== [4/5] Slipstream patch series ==="
$slipSeries = Get-Content "$env:SLIP_DIR\patches\series" |
    Where-Object { $_ -and $_ -notmatch '^\s*#' }
if ($slipSeries) {
    $slipFile = "$env:TEMP\slipstream_own_series"
    Set-Content $slipFile $slipSeries
    # --thorium-root points at OUR repo: series patch paths resolve against it
    py -3.11 "$env:THOR_DIR\patch_scripts\series\apply_series.py" `
        --thorium-root $env:SLIP_DIR --source-tree $env:CR_DIR --series $slipFile --apply
    if ($LASTEXITCODE -ne 0) { throw "slipstream series failed: $LASTEXITCODE" }
} else { Write-Output "(empty — nothing to apply yet)" }

Write-Output "=== [5/5] Rebrand token pass ==="
py -3.11 "$env:SLIP_DIR\scripts\rebrand.py" --chromium-src $env:CR_DIR --brand "$env:SLIP_DIR\branding\brand.json"
if ($LASTEXITCODE -ne 0) { throw "rebrand.py failed: $LASTEXITCODE" }

Write-Output "=== Apply complete. ==="
# NOTE: apply_series.py / setup.py argument names were taken from the gz83
# tree as of M152 — re-verify against the submodule after every tag bump.
