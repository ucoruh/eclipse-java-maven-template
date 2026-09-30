#!/bin/bash
# Helper: make sure genhtml (package "lcov") exists; exports GENHTML. Source it.
GENHTML="$(command -v genhtml || true)"
if [ -z "$GENHTML" ]; then
    echo "[ERROR] genhtml not found. Fix: sudo apt-get install -y lcov  (or run 4-install-tools-linux.sh)" >&2
    return 1 2>/dev/null || exit 1
fi
export GENHTML
