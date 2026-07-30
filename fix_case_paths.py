"""
fix_case_paths.py
Fixes case-sensitive resource path mismatches in the project.
Specifically:
  - res://Minigames/ -> res://minigames/   (in all .tscn, .tres, .gd files)
  - Cleans stale res://Data/ entries from .godot editor cache files
"""
import os, re

root = r'c:/Users/d2tod/Documents/Proyectos de Godot/riegolandia'
EXTS = {'.tscn', '.tres', '.gd', '.cfg'}
SKIP_DIRS = {'.git', 'export'}

REPLACEMENTS = [
    ('res://Minigames/', 'res://minigames/'),
]

changed_files = []
errors = []

for dirpath, dirs, files in os.walk(root):
    dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
    for fname in files:
        if not any(fname.endswith(ext) for ext in EXTS):
            continue
        fpath = os.path.join(dirpath, fname)
        try:
            text = open(fpath, encoding='utf-8', errors='ignore').read()
        except Exception as e:
            errors.append(f"READ ERROR {fpath}: {e}")
            continue
        new_text = text
        for old, new in REPLACEMENTS:
            new_text = new_text.replace(old, new)
        if new_text != text:
            try:
                open(fpath, 'w', encoding='utf-8').write(new_text)
                rel = os.path.relpath(fpath, root)
                changed_files.append(rel)
            except Exception as e:
                errors.append(f"WRITE ERROR {fpath}: {e}")

# Also fix the .godot editor cache files that contain the stale res://Data/ path
GODOT_CACHE_EXTS = {'.cfg', '', 'filesystem_update4', 'filesystem_cache10'}
godot_dir = os.path.join(root, '.godot')
cache_replacements = [
    ('res://Data/Tornado_base.tres', 'res://data/Tornado_base.tres'),
]
for dirpath, dirs, files in os.walk(godot_dir):
    for fname in files:
        fpath = os.path.join(dirpath, fname)
        try:
            text = open(fpath, encoding='utf-8', errors='ignore').read()
        except Exception:
            continue
        new_text = text
        for old, new in cache_replacements:
            new_text = new_text.replace(old, new)
        if new_text != text:
            try:
                open(fpath, 'w', encoding='utf-8').write(new_text)
                rel = os.path.relpath(fpath, root)
                changed_files.append(f"[CACHE] {rel}")
            except Exception as e:
                errors.append(f"WRITE ERROR {fpath}: {e}")

print(f"\n=== FIXED {len(changed_files)} files ===")
for f in changed_files:
    print(f"  {f}")
if errors:
    print(f"\n=== {len(errors)} ERRORS ===")
    for e in errors:
        print(f"  {e}")
else:
    print("\nNo errors.")
