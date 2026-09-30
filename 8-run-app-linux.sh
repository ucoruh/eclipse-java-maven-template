#!/bin/bash
# 8 - run the calculator from the jar that 6-build-and-test-linux.sh built.
#   ./8-run-app-linux.sh               demo: 6 * 7
#   ./8-run-app-linux.sh 12 + 30       your own expression: <number> <+|-|*|/> <number>
set -e
cd "$(dirname "$0")"
. scripts/load-env-linux.sh

JAR="build/linux-release/calculator-app-$VERSION.jar"
if [ ! -f "$JAR" ]; then
    echo "[ERROR] $JAR not found. Build it first: ./6-build-and-test-linux.sh" >&2
    exit 1
fi

if [ "$#" -eq 0 ]; then
    echo "No arguments given - running a demo expression (6 * 7)."
    echo "Usage: 8-run-app-linux.sh <number> <+|-|*|/> <number>"
    java -jar "$JAR" 6 "*" 7
else
    java -jar "$JAR" "$@"
fi

echo "Operation Completed!"
