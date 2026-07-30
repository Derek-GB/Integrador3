import os, re

root = r'c:/Users/d2tod/Documents/Proyectos de Godot/riegolandia'
pattern = re.compile(r'res://([A-Z][^\s"\']+)')
results = []
EXTS = {'.tscn', '.tres', '.gd', '.cfg', '.import'}
SKIP_DIRS = {'.git', '.godot', 'export'}

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
        for m in pattern.finditer(text):
            rel = os.path.relpath(fpath, root)
            results.append((rel, m.group(0)))

seen = set()
for f, p in results:
    if p not in seen:
        seen.add(p)
        print(p, ' --> ', f)
