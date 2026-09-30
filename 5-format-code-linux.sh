#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Formatting Java Code with Astyle..."

if ! command -v astyle >/dev/null 2>&1; then
    echo "[ERROR] astyle not found. Install it: sudo apt-get install -y astyle" >&2
    exit 1
fi

# --mode=java tells Astyle to use Java brace/indent conventions instead of the
# C/C++ defaults.
find calculator-app/src/main/java calculator-app/src/test/java -name '*.java' -print0 \
    | xargs -0 astyle --mode=java --options=astyle-options.txt
