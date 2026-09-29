#!/bin/bash
set -e

# NOTE: this is a ONE-TIME bootstrap script for starting a brand new repo from
# nothing (see README.md "Repository Setup"). Running it again on this
# template overwrites .gitignore's project-specific additions (target/,
# release/, report_*_hist/, README badge exceptions) with the generic
# toptal.com template - do not run it here; it is documented for reference
# only.

API_URL="https://www.toptal.com/developers/gitignore/api/c,csharp,vs,visualstudio,visualstudiocode,java,maven,c++,cmake,eclipse,netbeans"
OUTPUT_FILE=".gitignore"

cd "$(dirname "$0")"

if ! command -v curl >/dev/null 2>&1; then
    echo "[ERROR] curl not found. Install it: sudo apt-get install -y curl" >&2
    exit 1
fi

curl -sf -o "$OUTPUT_FILE" "$API_URL"
echo "Downloaded .gitignore file from $API_URL and saved as $OUTPUT_FILE"

echo "**/desktop.ini" >> "$OUTPUT_FILE"
echo "Appended '**/desktop.ini' to $OUTPUT_FILE"
echo "Remember to re-add this template's project-specific .gitignore entries"
echo "(see docs/guide/use-template-en.md) after regenerating from the API."
