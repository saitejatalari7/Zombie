"""Builds every layout in layouts/ (or the ones named on the command line).

    python3 tools/level_design/build_layouts.py            # all
    python3 tools/level_design/build_layouts.py s1_market  # one

Writes scripts/layout/plans/<ID>.gd and exits non-zero if any layout has a problem
(unreachable or misplaced markers, holes in the boundary, cells hidden from the camera).
"""
import importlib.util
import os
import sys

import layoutlib

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "..", "..", "scripts", "layout", "plans")


def load(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, "layouts", name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    names = sys.argv[1:] or sorted(f[:-3] for f in os.listdir(os.path.join(HERE, "layouts"))
                                   if f.endswith(".py") and not f.startswith("_"))
    failed = False
    for name in names:
        mod = load(name)
        plan, problems, text = layoutlib.build(layoutlib.Layout(mod))
        print(text)
        if problems:
            failed = True
            print("  PROBLEMS:")
            for p in problems:
                print("   - " + p)
            continue
        layoutlib.export_gdscript(plan, os.path.join(OUT_DIR, mod.ID + ".gd"), name)
        print(f"  -> scripts/layout/plans/{mod.ID}.gd")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
