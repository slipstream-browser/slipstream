# Apply Thorium (+ Slipstream delta) onto the pristine Chromium tree.
#   .\scripts\apply.ps1 -Stock     -> unmodified Thorium only (v0.0 gate)
#   .\scripts\apply.ps1            -> Thorium (minus exclusions) + Slipstream
# Always starts from a clean tree; this script resets it first.
#
# Design: we do NOT re-implement Thorium's setup.py (its copy plan + GRD/XTB
# rebase + profile handling are subtle). Instead we let setup.py do the whole
# Thorium layer, having first commented out our excluded patches in the
# submodule's series file, then restore that file via git. Our own overlay,
# series, and rebrand run afterward.
param([switch]$Stock)
$ErrorActionPreference = 'Stop'
# Native tools (git, py) write progress to stderr; in PS this can surface as a
# terminating error under Stop even on success. Disable that coupling (PS7) and
# rely on explicit $LASTEXITCODE checks after each native call.
$PSNativeCommandUseErrorActionPreference = $false
. "$PSScriptRoot\env.ps1"

function Invoke-Native([string]$what, [scriptblock]$block) {
    & $block 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "$what failed: exit $LASTEXITCODE" }
}

Write-Output "=== [1/6] Reset Chromium tree to pristine (keeps out/ and gclient deps) ==="
Invoke-Native 'git checkout' { git -C $env:CR_DIR checkout -f }
Invoke-Native 'git clean' { git -C $env:CR_DIR clean -fd -e out }  # -fd only: gclient deps survive

Write-Output "=== [2/6] Thorium version pin ==="
Invoke-Native 'version.py' { py -3.11 "$env:THOR_DIR\version.py" }

$seriesFile = "$env:THOR_DIR\patch_scripts\series\series"
$restoreSeries = $false
try {
    if (-not $Stock) {
        Write-Output "=== [3/6] Neutralize excluded Thorium patches in the series ==="
        $exclusions = Get-Content "$env:SLIP_DIR\patches\thorium_exclusions.txt" |
            Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object { $_.Trim() }
        $lines = Get-Content $seriesFile
        $hits = 0
        $out = foreach ($line in $lines) {
            $stripped = ($line -split '#', 2)[0].Trim()
            $match = $exclusions | Where-Object { $stripped -and $stripped -like "*$_*" }
            if ($match) { $hits++; "# [slipstream-excluded] $line" } else { $line }
        }
        if ($hits -ne $exclusions.Count) {
            throw "Exclusion mismatch: $($exclusions.Count) rules but $hits lines commented. A patch name changed upstream -- reconcile patches/thorium_exclusions.txt."
        }
        Set-Content $seriesFile $out
        $restoreSeries = $true
        Write-Output "Commented $hits excluded patch lines."
    } else {
        Write-Output "=== [3/6] (stock) no exclusions ==="
    }

    Write-Output "=== [4/6] Thorium setup.py (overlay + series + GRD rebase + profile) ==="
    Invoke-Native 'thorium setup.py' { py -3.11 "$env:THOR_DIR\setup.py" --avx2 --chromium-src $env:CR_DIR }
}
finally {
    if ($restoreSeries) {
        git -C $env:THOR_DIR checkout -- patch_scripts/series/series 2>&1 | Out-Null
        Write-Output "Restored Thorium series file."
    }
}

if ($Stock) {
    Write-Output "=== Stock Thorium applied. Done (skipping Slipstream delta). ==="
    exit 0
}

Write-Output "=== [5/6] Slipstream whole-file overlay + own patch series ==="
robocopy "$env:SLIP_DIR\overlay\src" $env:CR_DIR /E /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) { throw "robocopy slipstream overlay failed: $LASTEXITCODE" }

$slipSeries = Get-Content "$env:SLIP_DIR\patches\series" | Where-Object { $_ -and $_ -notmatch '^\s*#' }
if ($slipSeries) {
    $slipFile = "$env:TEMP\slipstream_own_series"
    Set-Content $slipFile $slipSeries
    # --thorium-root points at OUR repo so series patch paths resolve against it
    Invoke-Native 'slipstream series' {
        py -3.11 "$env:THOR_DIR\patch_scripts\series\apply_series.py" `
            --thorium-root $env:SLIP_DIR --source-tree $env:CR_DIR --series $slipFile --apply
    }
} else {
    Write-Output "(Slipstream series empty -- nothing to apply yet)"
}

Write-Output "=== [6/6] Rebrand token pass ==="
Invoke-Native 'rebrand.py' {
    py -3.11 "$env:SLIP_DIR\scripts\rebrand.py" --chromium-src $env:CR_DIR --brand "$env:SLIP_DIR\branding\brand.json"
}

Write-Output "=== Apply complete. ==="
