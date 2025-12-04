#!/usr/bin/env python3
"""
Quick static checker for a Godot project folder.
Checks:
 - Each .gd script contains at least one 'func' line.
 - Scans for obvious undeclared identifiers mentioned in error logs pattern:
   (simple heuristic) X referenced but no `class_name` or var declaration found in any file
 - Scans .tscn ext_resource paths and reports missing files.
Usage:
    python3 scripts/check_gd_quickscan.py /path/to/project_root
"""
import sys, os, re, json
from pathlib import Path

ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
print(f"[quickscan] project root: {ROOT}")

# 1) gather scripts and scene files
gd_files = list(ROOT.rglob("*.gd"))
tscn_files = list(ROOT.rglob("*.tscn"))

print(f"[quickscan] Found {len(gd_files)} .gd files and {len(tscn_files)} .tscn files")

# 2) Check .gd files have 'func' and collect class_name / exported names / identifiers (simple)
all_identifiers = set()
class_names = set()
func_counts = {}
for p in gd_files:
    txt = p.read_text(encoding='utf8', errors='ignore')
    func_counts[p] = len(re.findall(r'(^|\n)\s*func\s+', txt))
    # collect 'class_name' declarations
    for m in re.finditer(r'class_name\s+([A-Za-z0-9_]+)', txt):
        class_names.add(m.group(1))
    # collect exported variable names and simple var names (heuristic)
    for m in re.finditer(r'\bvar\s+([A-Za-z0-9_]+)', txt):
        all_identifiers.add(m.group(1))
    for m in re.finditer(r'\b([A-Za-z0-9_]+)\s*\(', txt):
        # function call names, may be identifiers, keep
        all_identifiers.add(m.group(1))

# detect gd files missing func
missing_funcs = [str(p) for p,c in func_counts.items() if c == 0]

# 3) parse tscn ext_resource entries and check files exist
missing_resources = []
for t in tscn_files:
    txt = t.read_text(encoding='utf8', errors='ignore')
    for m in re.finditer(r'ext_resource path=\"([^\"]+)\"', txt):
        path = m.group(1)
        # res:// mapping to real file path: convert res:// to root if present
        real = path
        if path.startswith("res://"):
            real = str(ROOT / path[7:])
        if not os.path.exists(real):
            missing_resources.append((str(t), path, real))

# 4) simple "undeclared" heuristic: search for tokens used that don't appear as class_name/var
# This is very noisy; restrict to likely suspects by scanning grep for 'Identifier "X" not declared' patterns in any log files
undeclared_candidates = set()
# Look for explicit error / TODO tokens in code or comments, else skip
error_patterns = re.compile(r'Identifier\s+"?([A-Za-z0-9_]+)"?\s+not declared', re.IGNORECASE)
# scan recent .log files if exist
for lf in ROOT.rglob("*.log"):
    text = lf.read_text(errors='ignore')
    for mm in error_patterns.finditer(text):
        undeclared_candidates.add(mm.group(1))
# Also look inside scripts for suspicious capitalized names that are not class_name
for idname in list(all_identifiers)[:]:
    if idname[0].isupper() and idname not in class_names:
        undeclared_candidates.add(idname)

# Print report
ok = True
print("---- quickscan report ----")
if missing_funcs:
    ok = False
    print(f"[ERROR] {len(missing_funcs)} .gd files appear to have zero 'func' definitions (possible syntax/truncated file):")
    for p in missing_funcs[:20]:
        print("  -", p)
else:
    print("[OK] All .gd files contain at least one 'func' (quick heuristic).")

if missing_resources:
    ok = False
    print(f"[ERROR] {len(missing_resources)} missing ext_resource files referenced in .tscn:")
    for t,path,real in missing_resources[:50]:
        print(f"  - scene: {t} references -> {path}  (resolved:{real})  [MISSING]")
else:
    print("[OK] All ext_resource paths found on disk (quick check).")

if undeclared_candidates:
    ok = False
    print(f"[WARN] Possible undeclared identifiers found (heuristic):")
    for c in sorted(undeclared_candidates):
        print("  -", c)
else:
    print("[OK] No obvious undeclared identifier candidates found by heuristic.")

print("--------------------------")
sys.exit(0 if ok else 3)
