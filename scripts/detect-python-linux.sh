#!/bin/bash
# Helper: pick a working Python 3 and export its command as PY. Source it:
#     . scripts/detect-python-linux.sh
export PYTHONUTF8=1
PY=""
for c in python3 python3.12 python; do
    if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(0 if sys.version_info[:2] >= (3, 8) else 1)' 2>/dev/null; then
        PY="$c"; break
    fi
done
if [ -z "$PY" ]; then
    echo "[ERROR] python3 not found. Install it: sudo apt-get install -y python3 python3-pip python3-venv" >&2
    return 1 2>/dev/null || exit 1
fi
export PY
