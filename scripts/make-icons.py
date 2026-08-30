#!/usr/bin/env python3
"""Generate the Slipstream icon set from branding/assets/logo*.svg.

Renders the SVGs with the project's own headless Chromium build (pixel-perfect
gradients/filters), then downscales and assembles PNGs + multi-size ICOs with
Pillow. Output lands in the overlay tree (icon filenames must keep Chromium's
names — resources reference them):

  overlay/src/chrome/app/theme/chromium/product_logo_{16,24,48,64,128,256}.png
  overlay/src/chrome/app/theme/chromium/win/{chromium,chromium_doc,chromium_pdf,app_list}.ico

Usage: py -3.11 scripts/make-icons.py [--browser <path to thorium/slipstream exe>]
"""
import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parent.parent
ASSETS = REPO / "branding" / "assets"
THEME_DIR = REPO / "overlay" / "src" / "chrome" / "app" / "theme" / "chromium"
WIN_DIR = THEME_DIR / "win"

# small variant (no trails/glow) below this size
SMALL_CUTOFF = 33
PNG_SIZES = [16, 24, 48, 64, 128, 256]
ICO_SIZES = [16, 24, 32, 48, 64, 128, 256]


def render(browser: Path, svg: Path, px: int, out_png: Path) -> None:
    """Render svg at px×px via headless Chromium screenshot."""
    with tempfile.TemporaryDirectory(prefix="slipicons-") as td:
        tmp = Path(td)
        wrapper = tmp / "w.html"
        wrapper.write_text(
            f'<!doctype html><html><body style="margin:0;background:transparent">'
            f'<img src="{svg.resolve().as_uri()}" width="{px}" height="{px}" '
            f'style="display:block"></body></html>',
            encoding="utf-8",
        )
        cmd = [
            str(browser), "--headless=new", f"--screenshot={out_png}",
            f"--window-size={px},{px}", "--default-background-color=00000000",
            "--disable-gpu", "--no-first-run",
            f"--user-data-dir={tmp / 'profile'}", wrapper.resolve().as_uri(),
        ]
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        if not out_png.exists():
            print("CMD:", " ".join(cmd), file=sys.stderr)
            print("EXIT:", r.returncode, file=sys.stderr)
            print("STDOUT:", r.stdout[-2000:], file=sys.stderr)
            print("STDERR:", r.stderr[-2000:], file=sys.stderr)
            raise RuntimeError(f"headless render failed for {px}px")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--browser", type=Path,
                    default=Path("D:/src/chromium/src/out/thorium/thorium.exe"))
    ap.add_argument("--full", type=Path, help="pre-rendered 1024px master PNG")
    ap.add_argument("--small", type=Path, help="pre-rendered 512px small-variant PNG")
    args = ap.parse_args()

    WIN_DIR.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="slipicons-master-") as td:
        tmp = Path(td)
        full_png = args.full or (tmp / "full.png")
        small_png = args.small or (tmp / "small.png")
        if not args.full:
            render(args.browser, ASSETS / "logo.svg", 1024, full_png)
        if not args.small:
            render(args.browser, ASSETS / "logo-small.svg", 512, small_png)
        full = Image.open(full_png).convert("RGBA")
        small = Image.open(small_png).convert("RGBA")

        def at(px: int) -> Image.Image:
            src = small if px < SMALL_CUTOFF else full
            return src.resize((px, px), Image.LANCZOS)

        for px in PNG_SIZES:
            at(px).save(THEME_DIR / f"product_logo_{px}.png")
            print(f"product_logo_{px}.png")

        frames = [at(px) for px in ICO_SIZES]
        for name in ("chromium.ico", "chromium_doc.ico", "chromium_pdf.ico",
                     "app_list.ico"):
            frames[-1].save(WIN_DIR / name, format="ICO",
                            append_images=frames[:-1],
                            sizes=[(s, s) for s in ICO_SIZES])
            print(name)

    print("icon set complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
