#!/bin/bash
# 7 - EVERYTHING on Linux/WSL: build + tests (script 6), code coverage (JaCoCo + ReportGenerator),
# API docs (Doxygen + Javadoc), documentation coverage (coverxygen -> genhtml + ReportGenerator),
# the Maven site, the MkDocs site, and the release/ folder (same names as the GitHub release).
#   ./7-build-all-linux.sh            full local run
#   ./7-build-all-linux.sh --no-site  reports + release parts only (what the CI platform job runs)
set -e
cd "$(dirname "$0")"

NO_SITE=""
export NO_MKDOCS_2_WARNING=true
for a in "$@"; do [ "$a" = "--no-site" ] && NO_SITE=1; done

. scripts/load-env-linux.sh
. scripts/detect-python-linux.sh
fail() { echo "[ERROR] $1" >&2; exit 1; }

echo "============================================================"
echo " $PROJECT_NAME $VERSION - build EVERYTHING ($PLATFORM-$ARCH)"
echo "============================================================"
for t in mvn doxygen reportgenerator; do
    command -v "$t" >/dev/null 2>&1 || fail "$t not found on PATH. Run ./4-install-tools-linux.sh (then open a NEW terminal)."
done
. scripts/detect-genhtml-linux.sh
"$PY" -c "import coverxygen, junit2htmlreport" 2>/dev/null \
    || fail "coverxygen / junit2html missing for $PY. Fix: $PY -m pip install --user -r requirements.txt"

echo "[1/9] Clean the generated Linux output (the reports history is kept)"
for d in tests-junit2html coverage-jacoco coverage-reportgenerator doccoverage-lcov doccoverage-reportgenerator api-doxygen api-javadoc api-xref-jxr api-xreftest-jxr api-testjavadoc; do
    rm -rf "reports/linux/$d"
done
rm -rf release site-native site
mkdir -p release

echo "[2/9] Build + unit tests + app (script 6)"
./6-build-and-test-linux.sh

echo "[3/9] Doxygen: API docs (HTML) + XML for coverxygen  -> reports/linux/api-doxygen/"
DOXYGEN_OUTPUT_DIR="reports/linux/api-doxygen" doxygen Doxyfile || fail "Doxygen failed - see the output above."

echo "[4/9] ReportGenerator on the JaCoCo XML  -> reports/linux/coverage-reportgenerator/"
mkdir -p reports/linux/_history/coverage
reportgenerator "-reports:calculator-app/target/site/jacoco/jacoco.xml" \
    "-sourcedirs:calculator-app/src/main/java" \
    "-targetdir:reports/linux/coverage-reportgenerator" \
    "-historydir:reports/linux/_history/coverage" \
    "-reporttypes:Html;Badges" \
    "-title:$PROJECT_NAME $VERSION - code coverage (linux)" \
    || fail "reportgenerator failed on the JaCoCo report."
# the README/landing badges are shared; the Windows run writes the same files - last build wins
cp reports/linux/coverage-reportgenerator/badge_{combined,branchcoverage,linecoverage,methodcoverage}.svg assets/

echo "[5/9] coverxygen: Doxygen XML -> lcov.info, then genhtml  -> reports/linux/doccoverage-lcov/"
mkdir -p reports/linux/doccoverage-lcov
"$PY" -m coverxygen --xml-dir reports/linux/api-doxygen/xml --src-dir . --format lcov \
    --output reports/linux/doccoverage-lcov/lcov.info --prefix "$(pwd)/calculator-app/"
[ -s reports/linux/doccoverage-lcov/lcov.info ] \
    || fail "coverxygen produced an empty lcov.info - check the Doxygen XML in reports/linux/api-doxygen/xml."
genhtml --legend --title "Documentation coverage (linux)" reports/linux/doccoverage-lcov/lcov.info \
    -o reports/linux/doccoverage-lcov || fail "genhtml failed - see the output above."

echo "[6/9] ReportGenerator on the same lcov.info  -> reports/linux/doccoverage-reportgenerator/"
mkdir -p reports/linux/_history/doccoverage
reportgenerator "-reports:reports/linux/doccoverage-lcov/lcov.info" \
    "-targetdir:reports/linux/doccoverage-reportgenerator" \
    "-historydir:reports/linux/_history/doccoverage" \
    "-reporttypes:Html;Badges" \
    "-title:$PROJECT_NAME $VERSION - documentation coverage (linux)" \
    || fail "reportgenerator failed on the coverxygen lcov.info."
cp reports/linux/doccoverage-reportgenerator/badge_combined.svg assets/badge_doccoverage.svg

echo "[7/9] Maven site (Surefire, JaCoCo, Javadoc, JXR, Checkstyle, PMD, CPD, SpotBugs)  -> site-native/"
"$PY" scripts/assemble.py prep
mvn -B -f calculator-app/pom.xml -Drevision="$VERSION" site || fail "'mvn site' failed - see the Maven output above."
cp -r calculator-app/target/site site-native
mkdir -p reports/linux/coverage-jacoco reports/linux/api-javadoc
cp -r calculator-app/target/site/jacoco/. reports/linux/coverage-jacoco/
cp -r calculator-app/target/site/apidocs/. reports/linux/api-javadoc/
mkdir -p reports/linux/api-testjavadoc reports/linux/api-xref-jxr reports/linux/api-xreftest-jxr
cp -r calculator-app/target/site/testapidocs/. reports/linux/api-testjavadoc/
cp -r calculator-app/target/site/xref/. reports/linux/api-xref-jxr/
cp -r calculator-app/target/site/xref-test/. reports/linux/api-xreftest-jxr/
# the Maven site frames every standalone report: give it its own copy of them
"$PY" scripts/assemble.py native

echo "[8/9] Package every Linux report into release/"
"$PY" scripts/assemble.py reports --platform linux

if [ -n "$NO_SITE" ]; then
    echo "[9/9] --no-site: MkDocs site skipped (CI builds it once, from both platforms)"
else
    echo "[9/9] MkDocs Material site  -> site/   and the rest of release/"
    "$PY" -c "import material" 2>/dev/null \
        || fail "mkdocs-material is not installed. Fix: $PY -m pip install --user -r requirements.txt"
    "$PY" scripts/assemble.py site
    "$PY" -m mkdocs build --strict -q -d site || fail "'mkdocs build' failed - see the warnings above."
    "$PY" scripts/assemble.py finalize
fi

echo "...................."
echo "Operation completed."
echo "  Site:        site/index.html   (./9-open-site-linux.sh serves it on http://localhost:8000/)"
echo "  Maven site:  site-native/index.html"
echo "  Reports:     reports/linux/"
echo "  Release:     release/          (ASSETS.md lists every file)"
echo "...................."
