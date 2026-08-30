# Sync the Chromium checkout to the version pinned by the Thorium submodule.
# The pin lives in third_party/thorium/version.py (THORIUM_VERSION) — single
# source of truth; never hardcode a version here.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$verLine = Select-String -Path "$env:THOR_DIR\version.py" -Pattern 'THORIUM_VERSION\s*=\s*"([^"]+)"'
if (-not $verLine) { throw "Could not read THORIUM_VERSION from $env:THOR_DIR\version.py" }
$ver = $verLine.Matches[0].Groups[1].Value
Write-Output "Pinned Chromium version: $ver"

# Ensure PGO profiles are enabled in .gclient (required for chrome_pgo_phase=2)
$gclientFile = 'D:\src\chromium\.gclient'
$gc = Get-Content $gclientFile -Raw
if ($gc -notmatch 'checkout_pgo_profiles') {
    $gc = $gc -replace '("custom_vars"\s*:\s*\{)', "`$1`n      `"checkout_pgo_profiles`": True,"
    if ($gc -notmatch 'checkout_pgo_profiles') {
        # no custom_vars block existed — add one to the src solution
        $gc = $gc -replace '(\{\s*"name"\s*:\s*"src",)', "`$1`n    `"custom_vars`": { `"checkout_pgo_profiles`": True },"
    }
    Set-Content $gclientFile $gc
    Write-Output "Added checkout_pgo_profiles to .gclient"
}

Set-Location $env:CR_DIR
git fetch origin "+refs/tags/${ver}:refs/tags/${ver}"
git checkout -f "tags/$ver"
gclient sync -D --force --reset --with_branch_heads --with_tags
gclient runhooks
Write-Output "Sync complete at $ver"
