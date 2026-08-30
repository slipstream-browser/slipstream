# Dot-source this to set up a Slipstream build shell:  . .\scripts\env.ps1
$env:DEPOT_TOOLS_DIR = 'D:\src\depot_tools'
if ($env:PATH -notlike "$env:DEPOT_TOOLS_DIR*") {
    $env:PATH = "$env:DEPOT_TOOLS_DIR;" + $env:PATH
}
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = '0'
$env:vs2026_install = 'C:\Program Files\Microsoft Visual Studio\2026\Community'
$env:CR_DIR   = 'D:\src\chromium\src'
$env:THOR_DIR = 'D:\src\slipstream\third_party\thorium'
$env:SLIP_DIR = 'D:\src\slipstream'
