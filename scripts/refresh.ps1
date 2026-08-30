# Re-export Slipstream's patches from the (hand-fixed) Chromium tree.
# Use after a rebase where apply.ps1 hit rejects and you fixed them in-tree:
# this regenerates patches/*.patch with clean context via Thorium's
# refresh_series.py (same semantics as their own series maintenance).
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$slipSeries = Get-Content "$env:SLIP_DIR\patches\series" |
    Where-Object { $_ -and $_ -notmatch '^\s*#' }
if (-not $slipSeries) { Write-Output "Slipstream series is empty — nothing to refresh."; exit 0 }

$slipFile = "$env:TEMP\slipstream_own_series"
Set-Content $slipFile $slipSeries

py -3.11 "$env:THOR_DIR\patch_scripts\series\refresh_series.py" `
    --thorium-root $env:SLIP_DIR --source-tree $env:CR_DIR --series $slipFile
if ($LASTEXITCODE -ne 0) { throw "refresh_series.py failed: $LASTEXITCODE" }

git -C $env:SLIP_DIR status --short patches/
Write-Output "Refresh complete — review the diff above, then commit."
