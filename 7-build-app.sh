#!/bin/bash
set -e

echo "============================================================"
echo " Build calculator-app: clean, test, package, docs, reports, site"
echo "============================================================"

currentDir="$(pwd)"
cd "$(dirname "$0")"

fail() {
    echo "[ERROR] $1" >&2
    exit 1
}

echo "-----------------------------------------------------------"
echo "1. Clean previous generated reports (idempotent: rm -rf on a"
echo "   missing folder is a silent no-op, unlike Windows 'rd')"
echo "-----------------------------------------------------------"
rm -rf calculator-app/target/site/coverxygen
rm -rf calculator-app/target/site/coverxygen-reportgenerator
rm -rf calculator-app/target/site/coveragereport
rm -rf calculator-app/target/site/doxygen
rm -rf release
mkdir -p release

echo "-----------------------------------------------------------"
echo "2. Maven: clean, run tests (JUnit5 + JaCoCo instrumentation)"
echo "   and package the runnable jar"
echo "-----------------------------------------------------------"
mvn -f calculator-app/pom.xml clean test package \
    || fail "'mvn clean test package' failed - see the Maven output above (JAVA_HOME/PATH? see docs/guide/troubleshooting-en.md)."

echo "-----------------------------------------------------------"
echo "3. Create the report folders this script fills in"
echo "-----------------------------------------------------------"
mkdir -p calculator-app/target/site/coverxygen
mkdir -p calculator-app/target/site/coverxygen-reportgenerator
mkdir -p calculator-app/target/site/coveragereport
mkdir -p calculator-app/target/site/doxygen
# History folders live OUTSIDE target/ on purpose: `mvn clean` (step 2 above)
# must not erase ReportGenerator's coverage trend between runs.
mkdir -p report_coverage_hist
mkdir -p report_doc_coverage_hist

echo "-----------------------------------------------------------"
echo "4. Doxygen: HTML (API docs, 'other' family) + XML (coverxygen's input)"
echo "-----------------------------------------------------------"
command -v doxygen >/dev/null 2>&1 || fail "doxygen not found. Install it: sudo apt-get install -y doxygen"
doxygen Doxyfile || fail "Doxygen failed - see the output above."

echo "-----------------------------------------------------------"
echo "5. ReportGenerator on the JaCoCo XML: HTML + badges + history"
echo "   (code coverage, ReportGenerator family; JaCoCo HTML itself"
echo "   was already produced by step 2, the native family)"
echo "-----------------------------------------------------------"
command -v reportgenerator >/dev/null 2>&1 \
    || fail "reportgenerator not found on PATH. Fix: dotnet tool install -g dotnet-reportgenerator-globaltool (and add \$HOME/.dotnet/tools to PATH)."
reportgenerator "-reports:calculator-app/target/site/jacoco/jacoco.xml" \
    "-sourcedirs:calculator-app/src/main/java" \
    "-targetdir:calculator-app/target/site/coveragereport" \
    "-historydir:report_coverage_hist" \
    "-reporttypes:Html;Badges" \
    || fail "reportgenerator failed on the JaCoCo report - see the output above."

echo "-----------------------------------------------------------"
echo "6. coverxygen: turn the Doxygen XML into lcov.info (this is the"
echo "   shared input for both documentation-coverage reports below)"
echo "-----------------------------------------------------------"
command -v python3 >/dev/null 2>&1 || fail "python3 not found. Install it: sudo apt-get install -y python3"
python3 -c "import coverxygen" >/dev/null 2>&1 \
    || fail "The 'coverxygen' package is not installed for python3. Fix: python3 -m pip install --user coverxygen"
python3 -m coverxygen --xml-dir "calculator-app/target/site/doxygen/xml" --src-dir "." \
    --format lcov --output "calculator-app/target/site/coverxygen/lcov.info" \
    --prefix "$currentDir/calculator-app/"
if [ ! -s "calculator-app/target/site/coverxygen/lcov.info" ]; then
    fail "coverxygen did not produce a non-empty lcov.info. The Doxygen XML input (calculator-app/target/site/doxygen/xml) may be missing or empty - re-check step 4."
fi

echo "-----------------------------------------------------------"
echo "7. genhtml: render lcov.info (documentation coverage, native family)"
echo "-----------------------------------------------------------"
command -v genhtml >/dev/null 2>&1 || fail "genhtml not found. Install it: sudo apt-get install -y lcov"
genhtml --legend --title "Documentation Coverage Report" \
    "calculator-app/target/site/coverxygen/lcov.info" \
    -o "calculator-app/target/site/coverxygen" \
    || fail "genhtml failed - see the output above."

echo "-----------------------------------------------------------"
echo "8. ReportGenerator on the same lcov.info (documentation coverage,"
echo "   ReportGenerator family - shows the exact same data as step 7,"
echo "   rendered differently)"
echo "-----------------------------------------------------------"
reportgenerator "-reports:calculator-app/target/site/coverxygen/lcov.info" \
    "-targetdir:calculator-app/target/site/coverxygen-reportgenerator" \
    "-historydir:report_doc_coverage_hist" \
    -reporttypes:Html \
    || fail "reportgenerator failed on the coverxygen lcov.info - see the output above."

echo "-----------------------------------------------------------"
echo "9. Copy coverage badges and site resources"
echo "-----------------------------------------------------------"
cp "calculator-app/target/site/coveragereport/badge_combined.svg" "assets/badge_combined.svg"
cp "calculator-app/target/site/coveragereport/badge_branchcoverage.svg" "assets/badge_branchcoverage.svg"
cp "calculator-app/target/site/coveragereport/badge_linecoverage.svg" "assets/badge_linecoverage.svg"
cp "calculator-app/target/site/coveragereport/badge_methodcoverage.svg" "assets/badge_methodcoverage.svg"

cp "assets/rteu_logo.jpg" "calculator-app/src/site/resources/images/rteu_logo.jpg"
mkdir -p "calculator-app/src/site/resources/assets"
cp -r assets/. "calculator-app/src/site/resources/assets/"
cp README.md "calculator-app/src/site/markdown/readme.md"

echo "-----------------------------------------------------------"
echo "10. Maven site: project info, Surefire report, JaCoCo, Javadoc,"
echo "    JXR, Checkstyle, PMD/CPD, SpotBugs - and it keeps the extra"
echo "    reports from steps 4-8 that already live under target/site"
echo "-----------------------------------------------------------"
mvn -f calculator-app/pom.xml site \
    || fail "'mvn site' failed - see the Maven output above."

echo "-----------------------------------------------------------"
echo "11. Package the jar and every report family into release/"
echo "-----------------------------------------------------------"
[ -f "calculator-app/target/calculator-app-1.0-SNAPSHOT.jar" ] \
    || fail "calculator-app-1.0-SNAPSHOT.jar was not produced by 'mvn package'."
tar -czvf release/application-binary.tar.gz -C calculator-app/target calculator-app-1.0-SNAPSHOT.jar
tar -czvf release/test-jacoco-report.tar.gz -C calculator-app/target/site/jacoco .
tar -czvf release/test-coverage-report.tar.gz -C calculator-app/target/site/coveragereport .
tar -czvf release/application-documentation.tar.gz -C calculator-app/target/site/doxygen .
tar -czvf release/doc-coverage-report.tar.gz -C calculator-app/target/site/coverxygen .
tar -czvf release/application-site.tar.gz -C calculator-app/target/site .

echo "...................."
echo "Operation Completed!"
echo "...................."
echo "Jar:               calculator-app/target/calculator-app-1.0-SNAPSHOT.jar"
echo "Site:              calculator-app/target/site/index.html"
echo "Release packages:  release/"
