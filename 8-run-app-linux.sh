#!/bin/bash
set -e

cd "$(dirname "$0")"

JAR="calculator-app/target/calculator-app-1.0-SNAPSHOT.jar"

if [ ! -f "$JAR" ]; then
    echo "[ERROR] $JAR not found. Build it first: ./7-build-app.sh" >&2
    exit 1
fi

if [ "$#" -eq 0 ]; then
    echo "No arguments given - running a demo expression (6 * 7)."
    echo "Usage: 8-run-app.sh <number> <+|-|*|/> <number>"
    java -jar "$JAR" 6 "*" 7
else
    java -jar "$JAR" "$@"
fi

echo "Operation Completed!"
