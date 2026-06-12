#!/usr/bin/env bash
# sync-status-from-epics.sh — seed execution-status.yaml keys from epic shards
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPECS="$REPO_ROOT/specs"
OUT="$SPECS/execution-status.yaml"
EPICS="$SPECS/epics"

python3 - "$EPICS" "$OUT" <<'PY'
import re
import sys
from pathlib import Path

epics_dir = Path(sys.argv[1])
out = Path(sys.argv[2])
keys: dict[str, str] = {}

existing_path = epics_dir.parent / "execution-status.yaml"
if existing_path.exists():
    existing = existing_path.read_text(encoding="utf-8")
    for m in re.finditer(r"^  ([a-z0-9._-]+):\s*(\S+)", existing, re.M):
        keys[m.group(1)] = m.group(2)

for folder in sorted(epics_dir.glob("e*/")):
    epic_yaml = folder / "epic.yaml"
    if epic_yaml.exists():
        text = epic_yaml.read_text(encoding="utf-8")
        em = re.search(r"^id:\s*(e\d+)", text, re.M)
        if em:
            eid = em.group(1)
            keys.setdefault(eid, "backlog")
        
        # Find all stories in epic.yaml
        for sm in re.finditer(r"^\s+- id:\s*(e\d+s\d+)", text, re.M):
            sid = sm.group(1)
            keys.setdefault(sid, "todo")
            
            # Find task files corresponding to this story in the same folder
            task_file = folder / f"{sid}-tasks.yaml"
            if task_file.exists():
                ttext = task_file.read_text(encoding="utf-8")
                # Extract task ids (e.g. - id: 1)
                for tm in re.finditer(r"^\s+- id:\s*(\d+)", ttext, re.M):
                    tid = f"{sid}-{tm.group(1)}"
                    keys.setdefault(tid, "todo")

lines = ["development_status:"]
for k in sorted(keys.keys()):
    lines.append(f"  {k}: {keys[k]}")
lines.append("")
out.write_text("\n".join(lines), encoding="utf-8")
print(f"sync-status-from-epics: wrote {out} ({len(keys)} keys)")
PY

