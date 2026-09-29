#!/bin/bash
set -e

cd "$(dirname "$0")"

open_url() {
    local url="$1"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 &
    elif command -v wslview >/dev/null 2>&1; then
        wslview "$url" >/dev/null 2>&1 &
    else
        echo "Open this in your browser: $url"
    fi
}

if [ "$1" = "--serve" ]; then
    echo "Running a live Maven site server (rebuilds from src/site on demand)..."
    echo "Open http://localhost:9000/ - Use CTRL+C to stop."
    open_url "http://localhost:9000/"
    mvn -f calculator-app/pom.xml site:run
else
    INDEX="calculator-app/target/site/index.html"
    if [ ! -f "$INDEX" ]; then
        echo "[ERROR] $INDEX not found. Build it first: ./7-build-app.sh" >&2
        exit 1
    fi
    echo "Opening the already-built static site in your default browser..."
    open_url "file://$(pwd)/$INDEX"
fi

echo "Operation Completed!"
