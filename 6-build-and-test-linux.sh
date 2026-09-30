#!/bin/bash
# 6 - FAST loop: build + unit tests + the runnable app (about a minute).
# Everything else (coverage, API docs, sites, release folder) is 7-build-all-linux.sh.
# Linux and WSL are the same platform ("linux"): same script, same output names.
# Output:  build/linux-release/   publish/linux-<arch>/   reports/linux/tests-junit2html/
set -e
cd "$(dirname "$0")"
. scripts/load-env-linux.sh
. scripts/detect-python-linux.sh

fail() { echo "[ERROR] $1" >&2; exit 1; }

echo "============================================================"
echo " $PROJECT_NAME $VERSION - build + unit tests ($PLATFORM-$ARCH)"
echo "============================================================"
command -v mvn >/dev/null 2>&1 || fail "mvn not found. Run ./4-install-tools-linux.sh (then open a NEW terminal)."

echo "[1/4] Maven: clean, compile, run the JUnit 5 tests (JaCoCo attached), package the jar"
mvn -B -f calculator-app/pom.xml -Drevision="$VERSION" clean verify \
    || fail "'mvn clean verify' failed - see the Maven output above (JAVA_HOME/PATH? see docs/guide/troubleshooting.en.md)."

echo "[2/4] Stage the build output in build/linux-release/"
rm -rf build/linux-release
mkdir -p build/linux-release
cp "calculator-app/target/calculator-app-$VERSION.jar" build/linux-release/ \
    || fail "calculator-app/target/calculator-app-$VERSION.jar was not produced (project.env VERSION is passed as -Drevision)."

echo "[3/4] Unit-test report (junit2html) in reports/linux/tests-junit2html/"
"$PY" -c "import junit2htmlreport" 2>/dev/null \
    || fail "junit2html is not installed for $PY. Fix: $PY -m pip install --user -r requirements.txt (or run ./4-install-tools-linux.sh)"
rm -rf reports/linux/tests-junit2html
mkdir -p reports/linux/tests-junit2html/xml
cp calculator-app/target/surefire-reports/TEST-*.xml reports/linux/tests-junit2html/xml/ \
    || fail "No Surefire XML found in calculator-app/target/surefire-reports."
"$PY" -m junit2htmlreport --merge reports/linux/tests-junit2html/xml/all-tests.xml \
    reports/linux/tests-junit2html/xml/TEST-*.xml || fail "junit2html could not merge the Surefire XML files."
"$PY" -m junit2htmlreport reports/linux/tests-junit2html/xml/all-tests.xml reports/linux/tests-junit2html/index.html \
    || fail "junit2html could not render the HTML report."

echo "[4/4] Package the application into publish/ and release/"
"$PY" scripts/assemble.py app --platform linux --arch "$ARCH"

echo "...................."
echo "Build and tests OK."
echo "  jar:    build/linux-release/"
echo "  app:    publish/linux-$ARCH/ (run.sh)  and  release/"
echo "  tests:  reports/linux/tests-junit2html/index.html"
echo "...................."
