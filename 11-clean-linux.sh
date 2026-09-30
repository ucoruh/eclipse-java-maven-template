#!/bin/bash
# 11 - delete everything the scripts generated (all of it is gitignored, nothing you wrote is touched).
#   ./11-clean-linux.sh          removes build/ publish/ release/ site/ site-native/ and the Windows/Linux
#                                report folders and calculator-app/target/  (report HISTORY is kept)
#   ./11-clean-linux.sh --all    also removes the report history (coverage trend starts again)
set -e
cd "$(dirname "$0")"
ALL=0
for a in "$@"; do [ "$a" = "--all" ] && ALL=1; done

for d in build publish release site site-native calculator-app/target docs/reports docs/native docs/downloads docs/assets; do
    if [ -e "$d" ]; then echo "removing $d"; rm -rf "$d"; fi
done
rm -f docs/downloads.md docs/maven-site.md
if [ -d reports ]; then
    for p in reports/*/; do
        for k in "$p"*/; do
            [ -d "$k" ] || continue
            [ "$(basename "$k")" = "_history" ] && continue
            echo "removing $k"; rm -rf "$k"
        done
    done
    if [ "$ALL" = "1" ]; then echo "removing reports (including history)"; rm -rf reports; fi
fi
echo "Clean done."
