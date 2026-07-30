import os, re

root = r'c:/Users/d2tod/Documents/Proyectos de Godot/riegolandia'
# Look specifically for paths that start with a capital first directory segment
# We care about: res://Data/, res://Scenes/, res://Scripts/, res://Images/, etc.
CRITICAL_CAPS = re.compile(r'res://([A-Z][a-zA-Z0-9_]*)/') 
EXTS = {'.tscn', '.tres', '.gd', '.cfg', '.import'}
SKIP_DIRS = {'.git', '.godot', 'export'}

# Also collect all lowercase actual directory names at root
actual_dirs = {d.lower(): d for d in os.listdir(root) if os.path.isdir(os.path.join(root, d)) and d not in SKIP_DIRS}

results = []
for dirpath, dirs, files in os.walk(root):
    dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
    for fname in files:
        if not any(fname.endswith(ext) for ext in EXTS):
            continue
        fpath = os.path.join(dirpath, fname)
        try:
            text = open(fpath, encoding='utf-8', errors='ignore').read()
        except Exception:
            continue
        for m in CRITICAL_CAPS.finditer(text):
            seg = m.group(1)  # First path segment after res://
            # Check if this segment CASE-MISMATCHES a real directory
            if seg.lower() in actual_dirs and actual_dirs[seg.lower()] != seg:
                rel = os.path.relpath(fpath, root)
                results.append((rel, m.group(0), seg, actual_dirs[seg.lower()]))

print(f"Found {len(results)} case mismatches:")
for f, path, wrong, correct in results:
    print(f"  WRONG: {path}  CORRECT: res://{correct}/  in: {f}")
