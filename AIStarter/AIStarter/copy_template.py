#!/usr/bin/env python3
"""Safe scaffold copy: whitelist page id, reject traversal/missing target/overwrite."""
import re, shutil, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "ai/skill-provider/templates/task-list.swift"
WORKSPACE = ROOT / "AIStarter"
PAGE_IDS = {"task-list": TEMPLATE}
def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: copy_template.py <page-id> <workspace-relative-destination>")
    page, rel = sys.argv[1], sys.argv[2]
    if page not in PAGE_IDS:
        raise SystemExit("unsupported page id: " + page)
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9]*", Path(rel).stem):
        raise SystemExit("invalid destination filename")
    dest = (WORKSPACE / rel).resolve()
    if WORKSPACE not in dest.parents:
        raise SystemExit("destination escapes workspace")
    if not dest.parent.is_dir():
        raise SystemExit("destination directory does not exist")
    if dest.exists():
        raise SystemExit("refusing to overwrite existing file")
    shutil.copyfile(PAGE_IDS[page], dest)
    print("copied template to " + str(dest.relative_to(WORKSPACE)))
if __name__ == "__main__":
    main()
