@echo off

:: Enable necessary extensions
@setlocal enableextensions

echo ============================================================
echo  Build calculator-app: clean, test, package, docs, reports, site
echo ============================================================

echo Get the current directory
set "currentDir=%CD%"

echo Change the current working directory to the script directory
@cd /d "%~dp0"

echo -----------------------------------------------------------
echo 1. Clean previous generated reports (idempotent: skip folders
echo    that do not exist yet instead of erroring on them)
echo -----------------------------------------------------------
if exist "calculator-app\target\site\coverxygen" rd /S /Q "calculator-app\target\site\coverxygen"
if exist "calculator-app\target\site\coverxygen-reportgenerator" rd /S /Q "calculator-app\target\site\coverxygen-reportgenerator"
if exist "calculator-app\target\site\coveragereport" rd /S /Q "calculator-app\target\site\coveragereport"
if exist "calculator-app\target\site\doxygen" rd /S /Q "calculator-app\target\site\doxygen"
if exist "calculator-app\target\site\downloads" rd /S /Q "calculator-app\target\site\downloads"
if exist "release" rd /S /Q "release"
mkdir "release"

echo -----------------------------------------------------------
echo 2. Maven: clean, run tests (JUnit5 + JaCoCo instrumentation)
echo    and package the runnable jar
echo -----------------------------------------------------------
call mvn -f "calculator-app\pom.xml" clean test package
if errorlevel 1 (
    echo [ERROR] "mvn clean test package" failed - see the Maven output above.
    echo         Common causes: wrong JDK on PATH ^(see docs\guide\troubleshooting-en.md^),
    echo         a failing test, or no network access to Maven Central on first run.
    exit /b 1
)

echo -----------------------------------------------------------
echo 3. Create the report folders this script fills in
echo -----------------------------------------------------------
if not exist "calculator-app\target\site\coverxygen" mkdir "calculator-app\target\site\coverxygen"
if not exist "calculator-app\target\site\coverxygen-reportgenerator" mkdir "calculator-app\target\site\coverxygen-reportgenerator"
if not exist "calculator-app\target\site\coveragereport" mkdir "calculator-app\target\site\coveragereport"
if not exist "calculator-app\target\site\doxygen" mkdir "calculator-app\target\site\doxygen"
rem History folders live OUTSIDE target\ on purpose: `mvn clean` (step 2 above)
rem must not erase ReportGenerator's coverage trend between runs.
if not exist "report_coverage_hist" mkdir "report_coverage_hist"
if not exist "report_doc_coverage_hist" mkdir "report_doc_coverage_hist"

echo -----------------------------------------------------------
echo 4. Doxygen: HTML (API docs, "other" family) + XML (coverxygen's input)
echo -----------------------------------------------------------
where doxygen >nul 2>&1
if errorlevel 1 (
    echo [ERROR] doxygen not found on PATH. Fix: choco install doxygen.install -y
    exit /b 1
)
call doxygen Doxyfile
if errorlevel 1 (
    echo [ERROR] Doxygen failed - see the output above.
    exit /b 1
)

echo -----------------------------------------------------------
echo 5. ReportGenerator on the JaCoCo XML: HTML + badges + history
echo    (code coverage, ReportGenerator family; JaCoCo HTML itself
echo    was already produced by step 2, the native family)
echo -----------------------------------------------------------
where reportgenerator >nul 2>&1
if errorlevel 1 (
    echo [ERROR] reportgenerator not found on PATH.
    echo Fix: dotnet tool install -g dotnet-reportgenerator-globaltool
    exit /b 1
)
call reportgenerator "-reports:calculator-app\target\site\jacoco\jacoco.xml" "-sourcedirs:calculator-app\src\main\java" "-targetdir:calculator-app\target\site\coveragereport" "-historydir:report_coverage_hist" "-reporttypes:Html;Badges"
if errorlevel 1 (
    echo [ERROR] reportgenerator failed on the JaCoCo report - see the output above.
    exit /b 1
)

echo -----------------------------------------------------------
echo 6. coverxygen: turn the Doxygen XML into lcov.info (this is the
echo    shared input for both documentation-coverage reports below)
echo -----------------------------------------------------------
where py >nul 2>&1
if errorlevel 1 (
    echo [ERROR] The "py" launcher was not found. Install Python 3.12+ from python.org
    echo         with "py launcher" enabled, then re-open the terminal.
    exit /b 1
)
py -3.12 -c "import coverxygen" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] The "coverxygen" package is not installed for "py -3.12".
    echo         Note: plain "python" on this machine may resolve to an unrelated
    echo         install ^(e.g. a graphics tool's bundled Python^) that does not have
    echo         it - that is exactly why this script calls "py -3.12" explicitly
    echo         instead of "python". Run: py -3.12 -m pip install --user coverxygen
    exit /b 1
)
rem NOTE: the --prefix value uses a forward slash before the closing quote on
rem purpose. A trailing BACKSLASH immediately before a closing double-quote
rem (e.g. "...\calculator-app\") is parsed by Windows' argv rules as an
rem escaped quote character, not a closing quote - it silently swallows every
rem argument after it. Forward slashes avoid the whole problem and Doxygen /
rem coverxygen / lcov all accept them on Windows.
call py -3.12 -m coverxygen --xml-dir "calculator-app\target\site\doxygen\xml" --src-dir "." --format lcov --output "calculator-app\target\site\coverxygen\lcov.info" --prefix "%currentDir:\=/%/calculator-app/"
for %%L in ("calculator-app\target\site\coverxygen\lcov.info") do set "LCOV_SIZE=%%~zL"
if not defined LCOV_SIZE set "LCOV_SIZE=0"
if "%LCOV_SIZE%"=="0" (
    echo [ERROR] coverxygen did not produce a non-empty lcov.info. The Doxygen XML
    echo         input ^(calculator-app\target\site\doxygen\xml^) may be missing or
    echo         empty, or the --prefix path may not match the source tree -
    echo         re-run step 4 above and check its output.
    exit /b 1
)

echo -----------------------------------------------------------
echo 7. genhtml: render lcov.info (documentation coverage, native family)
echo -----------------------------------------------------------
set "GENHTML="
for /f "delims=" %%G in ('where genhtml 2^>nul') do if not defined GENHTML set "GENHTML=%%G"
if not defined GENHTML (
    if exist "C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml" (
        echo "genhtml" is not on PATH; falling back to the default Chocolatey
        echo lcov install location.
        set "GENHTML=C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml"
    ) else (
        echo [ERROR] genhtml not found on PATH or at the default Chocolatey lcov
        echo         location. Fix: choco install lcov -y
        exit /b 1
    )
)
where perl >nul 2>&1
if errorlevel 1 (
    echo [ERROR] perl not found on PATH ^(genhtml is a Perl script^).
    echo Fix: choco install strawberryperl -y
    exit /b 1
)
call perl "%GENHTML%" --legend --title "Documentation Coverage Report" "calculator-app\target\site\coverxygen\lcov.info" -o "calculator-app\target\site\coverxygen"
if errorlevel 1 (
    echo [ERROR] genhtml failed - see the output above.
    exit /b 1
)

echo -----------------------------------------------------------
echo 8. ReportGenerator on the same lcov.info (documentation coverage,
echo    ReportGenerator family - shows the exact same data as step 7,
echo    rendered differently) plus a doc-coverage badge for the landing page
echo -----------------------------------------------------------
call reportgenerator "-reports:calculator-app\target\site\coverxygen\lcov.info" "-targetdir:calculator-app\target\site\coverxygen-reportgenerator" "-historydir:report_doc_coverage_hist" "-reporttypes:Html;Badges"
if errorlevel 1 (
    echo [ERROR] reportgenerator failed on the coverxygen lcov.info - see the output above.
    exit /b 1
)

echo -----------------------------------------------------------
echo 9. Copy coverage badges and site resources
echo -----------------------------------------------------------
copy /Y "calculator-app\target\site\coveragereport\badge_combined.svg" "assets\badge_combined.svg" >nul
copy /Y "calculator-app\target\site\coveragereport\badge_branchcoverage.svg" "assets\badge_branchcoverage.svg" >nul
copy /Y "calculator-app\target\site\coveragereport\badge_linecoverage.svg" "assets\badge_linecoverage.svg" >nul
copy /Y "calculator-app\target\site\coveragereport\badge_methodcoverage.svg" "assets\badge_methodcoverage.svg" >nul
if exist "calculator-app\target\site\coverxygen-reportgenerator\badge_combined.svg" (
    copy /Y "calculator-app\target\site\coverxygen-reportgenerator\badge_combined.svg" "assets\badge_doccoverage.svg" >nul
)

copy /Y "assets\rteu_logo.jpg" "calculator-app\src\site\resources\images\rteu_logo.jpg" >nul
robocopy "assets" "calculator-app\src\site\resources\assets" /E >nul
if errorlevel 8 (
    echo [ERROR] robocopy failed to mirror assets\ into the Maven site resources.
    exit /b 1
)
copy /Y README.md "calculator-app\src\site\markdown\readme.md" >nul
rem README.md's docs/guide/*.md and LICENSE links are relative on purpose (best
rem for GitHub's own rendering); rewrite them to absolute GitHub blob URLs in
rem the SITE's copy only, since docs/guide/*.md and LICENSE are not part of the
rem generated site (the site's readme.html would otherwise link to 404s).
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='calculator-app\src\site\markdown\readme.md'; (Get-Content $p -Raw) -replace '\]\(docs/guide/', '](https://github.com/ucoruh/eclipse-java-maven-template/blob/main/docs/guide/' -replace '\]\(LICENSE\)', '](https://github.com/ucoruh/eclipse-java-maven-template/blob/main/LICENSE)' | Set-Content -NoNewline $p"
if errorlevel 1 (
    echo [ERROR] Failed to rewrite relative links in the site's copy of README.md.
    exit /b 1
)

echo -----------------------------------------------------------
echo 10. Maven site: project info, Surefire report, JaCoCo, Javadoc,
echo     JXR, Checkstyle, PMD/CPD, SpotBugs - and it keeps the extra
echo     reports from steps 4-8 that already live under target\site
echo -----------------------------------------------------------
call mvn -f "calculator-app\pom.xml" site
if errorlevel 1 (
    echo [ERROR] "mvn site" failed - see the Maven output above.
    exit /b 1
)

echo -----------------------------------------------------------
echo 11. Bundle each report into calculator-app\target\site\downloads\*.zip
echo     - this is what the "Download (zip)" button on every reports\*.html
echo     page links to (see docs\guide\workflow-en.md). Self-contained
echo     directory reports are zipped as-is; single-file reports (surefire,
echo     checkstyle, pmd, cpd, spotbugs) are bundled with the shared site
echo     css/images so they still look right when opened outside the site.
echo -----------------------------------------------------------
if exist "calculator-app\target\site\downloads" rd /S /Q "calculator-app\target\site\downloads"
mkdir "calculator-app\target\site\downloads"

call tar -a -cf "calculator-app\target\site\downloads\jacoco.zip" -C "calculator-app\target\site\jacoco" .
call tar -a -cf "calculator-app\target\site\downloads\coveragereport.zip" -C "calculator-app\target\site\coveragereport" .
call tar -a -cf "calculator-app\target\site\downloads\coverxygen.zip" -C "calculator-app\target\site\coverxygen" .
call tar -a -cf "calculator-app\target\site\downloads\coverxygen-reportgenerator.zip" -C "calculator-app\target\site\coverxygen-reportgenerator" .
call tar -a -cf "calculator-app\target\site\downloads\javadoc.zip" -C "calculator-app\target\site\apidocs" .
call tar -a -cf "calculator-app\target\site\downloads\doxygen.zip" -C "calculator-app\target\site\doxygen\html" .

set "BUNDLE_TMP=%TEMP%\eclipse-java-maven-template-report-bundle"
for %%F in (surefire checkstyle pmd cpd spotbugs) do (
    if exist "%BUNDLE_TMP%" rd /S /Q "%BUNDLE_TMP%"
    mkdir "%BUNDLE_TMP%"
    if exist "calculator-app\target\site\%%F.html" (
        copy /Y "calculator-app\target\site\%%F.html" "%BUNDLE_TMP%\index.html" >nul
        robocopy "calculator-app\target\site\css" "%BUNDLE_TMP%\css" /E >nul
        robocopy "calculator-app\target\site\images" "%BUNDLE_TMP%\images" /E >nul
        call tar -a -cf "calculator-app\target\site\downloads\%%F.zip" -C "%BUNDLE_TMP%" .
    ) else (
        echo [WARN] calculator-app\target\site\%%F.html not found - skipping its download bundle.
    )
)
if exist "%BUNDLE_TMP%" rd /S /Q "%BUNDLE_TMP%"

echo -----------------------------------------------------------
echo 12. Package the jar and every report family into release\
echo -----------------------------------------------------------
if not exist "calculator-app\target\calculator-app-1.0-SNAPSHOT.jar" (
    echo [ERROR] calculator-app-1.0-SNAPSHOT.jar was not produced by "mvn package".
    exit /b 1
)
rem tar does not glob on Windows (cmd.exe does not expand '*.jar' and passes the
rem literal quotes through), so the single known jar name is listed explicitly.
call tar -czvf "release\application-binary.tar.gz" -C "calculator-app\target" "calculator-app-1.0-SNAPSHOT.jar"
call tar -czvf "release\test-jacoco-report.tar.gz" -C "calculator-app\target\site\jacoco" .
call tar -czvf "release\test-coverage-report.tar.gz" -C "calculator-app\target\site\coveragereport" .
call tar -czvf "release\application-documentation.tar.gz" -C "calculator-app\target\site\doxygen" .
call tar -czvf "release\doc-coverage-report.tar.gz" -C "calculator-app\target\site\coverxygen" .
call tar -czvf "release\doc-coverage-reportgenerator-report.tar.gz" -C "calculator-app\target\site\coverxygen-reportgenerator" .
call tar -czvf "release\api-docs-javadoc.tar.gz" -C "calculator-app\target\site\apidocs" .
if not exist "release\test-results-surefire" mkdir "release\test-results-surefire"
robocopy "calculator-app\target\surefire-reports" "release\test-results-surefire\xml" /E >nul
copy /Y "calculator-app\target\site\downloads\surefire.zip" "release\test-results-surefire\surefire-report.zip" >nul 2>nul
call tar -czvf "release\test-results-surefire.tar.gz" -C "release\test-results-surefire" .
rd /S /Q "release\test-results-surefire"
call git archive --format=tar.gz --output="release\source-code.tar.gz" HEAD
call tar -czvf "release\application-site.tar.gz" -C "calculator-app\target\site" .

echo -----------------------------------------------------------
echo 13. Write release\README.md: what every archive is, and the site URL
echo     (10-release.bat / release.yml append a site.zip row to this same
echo     file once they create it - this script does not produce site.zip)
echo -----------------------------------------------------------
rem NOTE: the table is deliberately the LAST content in this file (no blank
rem line or trailing text after the last row) - 10-release.bat/.sh and
rem release.yml append one more `^| site.zip ^| ... ^|` line once they create
rem site.zip, and a Markdown table only stays one table if every row is on a
rem line directly adjacent to the last one, with nothing in between.
> "release\README.md" echo # Release contents
>> "release\README.md" echo.
>> "release\README.md" echo Built locally by `7-build-app.bat` / `7-build-app.sh`.
>> "release\README.md" echo.
>> "release\README.md" echo Live site: https://ucoruh.github.io/eclipse-java-maven-template/
>> "release\README.md" echo.
>> "release\README.md" echo See `docs/guide/releases-en.md` / `docs/guide/releases-tr.md` for how each of these is produced and how to open it.
>> "release\README.md" echo.
>> "release\README.md" echo ^| Archive ^| Contents ^|
>> "release\README.md" echo ^|---^|---^|
>> "release\README.md" echo ^| `application-binary.tar.gz` ^| The runnable jar - portable bytecode, runs unmodified on Windows, Linux and macOS with any JDK 17+ ^|
>> "release\README.md" echo ^| `source-code.tar.gz` ^| The source tree at this commit (`git archive`) ^|
>> "release\README.md" echo ^| `test-results-surefire.tar.gz` ^| Raw JUnit XML (`surefire-reports/`) plus the rendered Surefire report, standalone ^|
>> "release\README.md" echo ^| `test-jacoco-report.tar.gz` ^| Code coverage, native family: JaCoCo HTML ^|
>> "release\README.md" echo ^| `test-coverage-report.tar.gz` ^| Code coverage, ReportGenerator family: HTML + badges + history ^|
>> "release\README.md" echo ^| `doc-coverage-report.tar.gz` ^| Documentation coverage, native family: coverxygen + `genhtml` ^|
>> "release\README.md" echo ^| `doc-coverage-reportgenerator-report.tar.gz` ^| Documentation coverage, ReportGenerator family (same data, different rendering) ^|
>> "release\README.md" echo ^| `application-documentation.tar.gz` ^| API docs: Doxygen HTML ^|
>> "release\README.md" echo ^| `api-docs-javadoc.tar.gz` ^| API docs: Javadoc HTML ^|
>> "release\README.md" echo ^| `application-site.tar.gz` ^| The full Maven site (landing page + every report page), tar.gz form ^|

echo ....................
echo Operation Completed!
echo ....................
echo Jar:               calculator-app\target\calculator-app-1.0-SNAPSHOT.jar
echo Site:              calculator-app\target\site\index.html
echo Report downloads:  calculator-app\target\site\downloads\
echo Release packages:  release\

rem CI runners set CI=true; skip the interactive pause there so the script
rem never blocks an automated/non-interactive run.
if not defined CI pause
