# Configure and build.  .\scripts\build.ps1 [-OutDir out\slipstream] [-Jobs 22]
param(
    [string]$OutDir = 'out\slipstream',
    [int]$Jobs = 22,
    [string]$ArgsFile = ''
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
$env:PYTHONNOUSERSITE = '1'  # isolate build Python from --user site-packages (see docs/BUILDING-WINDOWS.md)
Set-Location $env:CR_DIR

if (-not $ArgsFile) { $ArgsFile = "$env:SLIP_DIR\config\win_x64_avx2.gn" }
New-Item -ItemType Directory -Force (Join-Path $env:CR_DIR $OutDir) | Out-Null
Copy-Item $ArgsFile (Join-Path $env:CR_DIR "$OutDir\args.gn") -Force

gn gen $OutDir
if ($LASTEXITCODE -ne 0) { throw "gn gen failed" }
gn args $OutDir --list > "$env:SLIP_DIR\docs\gn_all_args.txt"

# -j 22 not 32: clang-cl peaks 1-1.5 GB/TU; 32 jobs thrashes 32 GB RAM.
# concurrent_links stays at default (-1): Windows+ThinLTO budget (45 GB/link)
# auto-clamps to one link job on this machine — exactly what we want.
autoninja -C $OutDir thorium_all thorium_installer -j $Jobs
if ($LASTEXITCODE -ne 0) { throw "build failed" }
Write-Output "Build complete: $OutDir"
