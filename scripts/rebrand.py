#!/usr/bin/env python3
"""Deterministic Thorium -> Slipstream token pass over the Chromium tree.

Runs AFTER Thorium's patches and the Slipstream overlay, so patch context is
never disturbed and no reject is possible. Conservative by design:

- "Thorium"/"THORIUM" (user-visible casings) are replaced everywhere in the
  allowlist except protected identifiers.
- lowercase "thorium" is replaced ONLY when it is not part of a code
  identifier or a source-file path (i.e. not glued to [A-Za-z0-9_] via '_',
  and not followed by a source-file suffix). Renaming identifiers/filenames
  without renaming the files themselves breaks the build; internal names are
  invisible to users and get renamed (with file moves) in a later phase.
- Everything under extensions/ is outside the allowlist: the CWS install
  pipeline and the Chrome/<major> UA token must never be touched.

Emits out/rebrand_manifest.json (every file+count changed) as the evidence
artifact. Idempotent: a second run changes nothing.

Usage:
  py -3.11 rebrand.py --chromium-src D:/src/chromium/src \
      --brand D:/src/slipstream/branding/brand.json [--dry-run]
"""
import argparse
import json
import re
import sys
from pathlib import Path

SRC_FILE_SUFFIX = re.compile(r"^(?:\.(?:h|cc|mm|gni?|py|grdp?|xtb|rc|ico|png|svg))")


def load_brand(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def want_file(rel: str, cfg: dict) -> bool:
    rel_l = rel.replace("\\", "/").lower()
    if not any(rel_l.startswith(p.lower()) for p in cfg["allowlist_paths"]):
        return False
    if any(d.lower() in rel_l for d in cfg["denylist_paths"]):
        return False
    return any(rel_l.endswith(e) for e in cfg["extensions"])


def protect(text: str, identifiers: list[str]):
    """Swap protected identifiers for placeholders; return text + restore map."""
    restore = {}
    for i, ident in enumerate(identifiers):
        ph = f"\x00P{i}\x00"
        if ident in text:
            text = text.replace(ident, ph)
            restore[ph] = ident
    return text, restore


def replace_lower(text: str, old: str, new: str) -> str:
    """Replace lowercase token only where it isn't a code identifier/filename."""
    out = []
    idx = 0
    n = len(text)
    while True:
        j = text.find(old, idx)
        if j < 0:
            out.append(text[idx:])
            break
        out.append(text[idx:j])
        end = j + len(old)
        before = text[j - 1] if j > 0 else ""
        after = text[end] if end < n else ""
        # Keep lowercase "thorium" when it is part of a code identifier
        # (glued to _), a path segment (adjacent to a / or \ separator), or a
        # file reference (followed by a known source/asset suffix). Renaming
        # any of those without also renaming the real file/dir/symbol breaks
        # the build — e.g. the `components/vector_icons/thorium/` icon dir,
        # which is referenced by path in BUILD.gn but never actually renamed.
        glued_ident = before == "_" or after == "_"
        path_seg = before in "/\\" or after in "/\\"
        is_src_ref = bool(SRC_FILE_SUFFIX.match(text[end : end + 5]))
        if glued_ident or path_seg or is_src_ref:
            out.append(old)  # identifier, path segment, or file reference — keep
        else:
            out.append(new)
        idx = end
    return "".join(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--chromium-src", required=True, type=Path)
    ap.add_argument("--brand", required=True, type=Path)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    brand = load_brand(args.brand)
    cfg = brand["rebrand_pass"]
    tokens = cfg["tokens"]
    preserve = cfg["preserve_identifiers"]
    src = args.chromium_src.resolve()

    manifest = {}
    scanned = 0
    for root in cfg["allowlist_paths"]:
        base = src / root.rstrip("/")
        if not base.exists():
            continue
        for f in base.rglob("*"):
            if not f.is_file():
                continue
            rel = str(f.relative_to(src))
            if not want_file(rel, cfg):
                continue
            scanned += 1
            try:
                text = f.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            if "thorium" not in text.lower():
                continue
            orig = text
            text, restore = protect(text, preserve)
            for old, new in tokens:
                if old.islower():
                    text = replace_lower(text, old, new)
                else:
                    text = text.replace(old, new)
            for ph, ident in restore.items():
                text = text.replace(ph, ident)
            if text != orig:
                count = sum(
                    orig.count(o) for o, _ in tokens
                )
                manifest[rel.replace("\\", "/")] = count
                if not args.dry_run:
                    f.write_text(text, encoding="utf-8", newline="")

    out = src / "out"
    out.mkdir(exist_ok=True)
    (out / "rebrand_manifest.json").write_text(
        json.dumps(
            {"dry_run": args.dry_run, "files_scanned": scanned,
             "files_changed": len(manifest), "changes": manifest},
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"rebrand: scanned {scanned}, changed {len(manifest)} files"
          f"{' (dry run)' if args.dry_run else ''}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
