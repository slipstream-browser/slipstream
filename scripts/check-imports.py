#!/usr/bin/env python3
"""Fail the build if chrome.dll statically imports an app-directory DLL.

WHY THIS EXISTS (v0.1, 2026-08-31): we shipped a build in which
`is_component_ffmpeg=true` (in a static `is_component_build=false` build) added
`ffmpeg.dll` as a load-time import of chrome.dll. Renderer processes enforce
Code Integrity Guard (chrome/browser/chrome_content_browser_client.cc,
PreSpawnChild: MITIGATION_FORCE_MS_SIGNED_BINS, applied at process creation),
and only the DLLs on that function's AllowExtraDll list are exempt. ffmpeg.dll
was not, so LoadLibraryExW(chrome.dll) returned NULL in every renderer and each
one exited with code 7 (CHROME_RESULT_CODE_MISSING_DATA) after ~21ms. The
browser rendered nothing at all. Nothing in Chromium's own logs or Crashpad
records this -- the only trace is Windows CodeIntegrity event 3033.

This check turns that entire class of failure into a build-time error.
Keep ALLOWED in sync with the AllowExtraDll loop in PreSpawnChild.

Usage: py -3.11 scripts/check-imports.py <path-to-chrome.dll>
"""
import struct
import sys
from pathlib import Path

# DLLs a renderer may load from the application directory: those Chromium
# explicitly exempts from Code Integrity Guard, plus OS-signed system DLLs.
ALLOWED_APP_DLLS = {"chrome_elf.dll"}
SYSTEM_HINTS = (
    "kernel32", "ntdll", "user32", "gdi32", "advapi32", "ws2_32", "crypt32",
    "version", "winmm", "dwrite", "ole32", "oleaut32", "shell32", "shlwapi",
    "psapi", "dbghelp", "userenv", "winspool", "comdlg32", "imm32", "uxtheme",
    "dwmapi", "propsys", "setupapi", "cfgmgr32", "powrprof", "dhcpcsvc",
    "iphlpapi", "secur32", "wintrust", "msvcrt", "api-ms-win", "rpcrt4",
    "bcrypt", "ncrypt", "wtsapi32", "credui", "d3d11", "dxgi", "d2d1",
)


def rva_to_off(rva, sections):
    for va, vsz, raw, rsz in sections:
        if va <= rva < va + max(vsz, rsz):
            return raw + (rva - va)
    return None


def imports(path: Path):
    d = path.read_bytes()
    pe = struct.unpack_from("<I", d, 0x3C)[0]
    if d[pe:pe + 4] != b"PE\0\0":
        raise SystemExit(f"{path}: not a PE file")
    nsec, = struct.unpack_from("<H", d, pe + 6)
    opt_sz, = struct.unpack_from("<H", d, pe + 20)
    opt = pe + 24
    magic, = struct.unpack_from("<H", d, opt)
    dd = opt + (112 if magic == 0x20B else 96)          # data directories
    imp_rva, = struct.unpack_from("<I", d, dd + 8)      # entry 1 = imports
    sec = opt + opt_sz
    sections = []
    for i in range(nsec):
        o = sec + i * 40
        vsz, va, rsz, raw = struct.unpack_from("<IIII", d, o + 8)
        sections.append((va, vsz, raw, rsz))
    off = rva_to_off(imp_rva, sections)
    out = []
    while off:
        desc = d[off:off + 20]
        if len(desc) < 20 or desc == b"\0" * 20:
            break
        name_rva, = struct.unpack_from("<I", desc, 12)
        if not name_rva:
            break
        no = rva_to_off(name_rva, sections)
        end = d.index(b"\0", no)
        out.append(d[no:end].decode("ascii", "replace"))
        off += 20
    return out


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    dll = Path(sys.argv[1])
    if not dll.exists():
        raise SystemExit(f"not found: {dll}")
    bad = []
    for name in imports(dll):
        low = name.lower()
        if low in ALLOWED_APP_DLLS or any(h in low for h in SYSTEM_HINTS):
            continue
        # Anything left that ships next to the exe is a renderer-fatal import.
        if (dll.parent / name).exists():
            bad.append(name)
    if bad:
        print(f"FAIL: {dll.name} statically imports app-directory DLL(s): "
              f"{', '.join(bad)}")
        print("Renderer Code Integrity Guard will block these and every "
              "renderer will die with exit code 7 (blank browser).")
        print("Fix: link the code statically, or add the DLL to the "
              "AllowExtraDll loop in PreSpawnChild (a real CIG concession).")
        return 1
    print(f"OK: {dll.name} imports no app-directory DLLs "
          f"(renderer CIG safe).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
