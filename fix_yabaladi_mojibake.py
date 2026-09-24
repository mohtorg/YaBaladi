from pathlib import Path
from datetime import datetime
import shutil

ROOT = Path(r"C:\ya_baladi\lib")
BACKUP_ROOT = Path(r"C:\ya_baladi_mojibake_backup_" + datetime.now().strftime("%Y%m%d_%H%M%S"))
MARKERS = tuple(chr(int(x, 16)) for x in ["0637","0638","00a7","201e","2026","00a9","00b5","00b3","00b4","0639","062a","0644","0645","0646","0648","0641","064a","0642","0647","0623","0625","062d","062e","062f","0630","0632","0637","0638","061b"])

if not ROOT.exists():
    raise SystemExit(f"PROJECT_NOT_FOUND: {ROOT}")

changed = []
for path in ROOT.rglob("*.dart"):
    text = path.read_text(encoding="utf-8")
    out = []
    count = 0
    for line in text.splitlines(keepends=True):
        score = sum(line.count(m) for m in MARKERS)
        if score:
            try:
                candidate = line.encode("cp1256", "ignore").decode("utf-8")
            except UnicodeError:
                candidate = line
            candidate_score = sum(candidate.count(m) for m in MARKERS)
            if candidate_score < score:
                line = candidate
                count += 1
        out.append(line)
    new_text = "".join(out)
    if new_text != text:
        rel = path.relative_to(ROOT.parent)
        backup = BACKUP_ROOT / rel
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, backup)
        path.write_text(new_text, encoding="utf-8", newline="")
        changed.append((str(rel), count))

print("MOJIBAKE_FIX_COMPLETE")
print("BACKUP:", BACKUP_ROOT)
print("CHANGED_FILES:", len(changed))
for name, count in changed:
    print(f"  {name} | changed lines: {count}")
