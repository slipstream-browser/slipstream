# Package release artifacts: portable zip + renamed installer + checksums.
#   .\scripts\package.ps1 [-OutDir out\slipstream]
param([string]$OutDir = 'out\slipstream')
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

$v = Get-Content "$env:SLIP_DIR\VERSION.json" | ConvertFrom-Json
$stamp = "$($v.product)_M$($v.chromium)_win_$($v.cpu_target)"
$dist = "$env:SLIP_DIR\dist"
New-Item -ItemType Directory -Force $dist | Out-Null
$outAbs = Join-Path $env:CR_DIR $OutDir

# 1. Installer (mini_installer target output)
$installer = Get-ChildItem $outAbs -Filter '*installer*.exe' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($installer) {
    Copy-Item $installer.FullName "$dist\slipstream_${stamp}_installer.exe"
    Write-Output "Installer: slipstream_${stamp}_installer.exe"
} else { Write-Warning "No installer exe found in $outAbs" }

# 2. Portable zip: binary + resources, plus a portable marker
$portableDir = "$env:TEMP\slipstream_portable"
Remove-Item $portableDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $portableDir | Out-Null
$include = @('*.exe','*.dll','*.pak','*.bin','*.dat','icudtl.dat','*.json')
Get-ChildItem $outAbs -File | Where-Object {
    $n = $_.Name
    ($include | Where-Object { $n -like $_ }) -and $n -notmatch 'interactive_ui|unittest|browser_test|mini_installer'
} | Copy-Item -Destination $portableDir
foreach ($sub in 'locales','resources','MEIPreload','swiftshader') {
    if (Test-Path "$outAbs\$sub") { Copy-Item "$outAbs\$sub" $portableDir -Recurse }
}
Copy-Item "$env:SLIP_DIR\LICENSES" $portableDir -Recurse
Set-Content "$portableDir\portable.marker" "Slipstream portable mode marker"
Compress-Archive "$portableDir\*" "$dist\slipstream_${stamp}_portable.zip" -Force
Write-Output "Portable: slipstream_${stamp}_portable.zip"

# 3. build-info.json + SHA256SUMS
$buildInfo = @{
    product          = $v.product
    chromium         = $v.chromium
    thorium_tag      = $v.thorium_tag
    chromium_git_sha = (git -C $env:CR_DIR rev-parse HEAD)
    slipstream_sha   = (git -C $env:SLIP_DIR rev-parse HEAD)
    built_utc        = (Get-Date).ToUniversalTime().ToString('o')
    builder          = $env:COMPUTERNAME
} | ConvertTo-Json
Set-Content "$dist\build-info.json" $buildInfo

$sums = Get-ChildItem $dist -File | Where-Object Name -ne 'SHA256SUMS.txt' | ForEach-Object {
    "$((Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower())  $($_.Name)"
}
Set-Content "$dist\SHA256SUMS.txt" $sums
Write-Output "Packaged to $dist"
