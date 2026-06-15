from pathlib import Path
root = Path("minigames")
patterns = [
    ("res://minigame_", "res://minigames/minigame_"),
    ("res://ui_global/", "res://minigames/ui_global/"),
]
changed = []
for path in root.rglob("*"):
    if not path.is_file() or path.suffix in {".uid"}:
        continue
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        continue
    new_text = text
    for old, new in patterns:
        new_text = new_text.replace(old, new)
    if new_text != text:
        path.write_text(new_text, encoding="utf-8")
        changed.append(str(path))
print("CHANGED_FILES:", len(changed))
for p in changed[:200]:
    print(p)
