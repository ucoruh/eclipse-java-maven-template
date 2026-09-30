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
    echo "Running a live Maven site dev server (rebuilds pages from src/site on"
    echo "demand). Only useful while editing site.xml/markdown - the report"
    echo "pages need a full '7-build-app.sh' run first so their iframes have"
    echo "something to point at."
    echo "Open http://localhost:9000/ - Use CTRL+C to stop."
    open_url "http://localhost:9000/"
    mvn -f calculator-app/pom.xml site:run
else
    INDEX="calculator-app/target/site/index.html"
    if [ ! -f "$INDEX" ]; then
        echo "[ERROR] $INDEX not found. Build it first: ./7-build-app.sh" >&2
        exit 1
    fi
    PORT="${2:-8000}"
    PYTHON=""
    if command -v python3 >/dev/null 2>&1; then
        PYTHON=python3
    elif command -v python >/dev/null 2>&1; then
        PYTHON=python
    else
        echo "[ERROR] Neither python3 nor python was found on PATH." >&2
        echo "        Install Python 3, or use './9-run-webpage.sh --serve' instead." >&2
        exit 1
    fi
    echo "Serving the already-built static site with a local HTTP server."
    echo "(Report pages use an <iframe> - most browsers block iframes on a"
    echo "file:// page, so this must be served over http://, not opened directly.)"
    echo "Open http://localhost:$PORT/ - Use CTRL+C to stop."
    open_url "http://localhost:$PORT/"
    "$PYTHON" -m http.server "$PORT" --directory "calculator-app/target/site"
fi

echo "Operation Completed!"
