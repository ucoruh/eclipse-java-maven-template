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
echo    rendered differently)
echo -----------------------------------------------------------
call reportgenerator "-reports:calculator-app\target\site\coverxygen\lcov.info" "-targetdir:calculator-app\target\site\coverxygen-reportgenerator" "-historydir:report_doc_coverage_hist" -reporttypes:Html
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

copy /Y "assets\rteu_logo.jpg" "calculator-app\src\site\resources\images\rteu_logo.jpg" >nul
robocopy "assets" "calculator-app\src\site\resources\assets" /E >nul
if errorlevel 8 (
    echo [ERROR] robocopy failed to mirror assets\ into the Maven site resources.
    exit /b 1
)
copy /Y README.md "calculator-app\src\site\markdown\readme.md" >nul

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
echo 11. Package the jar and every report family into release\
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
call tar -czvf "release\application-site.tar.gz" -C "calculator-app\target\site" .

echo ....................
echo Operation Completed!
echo ....................
echo Jar:               calculator-app\target\calculator-app-1.0-SNAPSHOT.jar
echo Site:              calculator-app\target\site\index.html
echo Release packages:  release\

rem CI runners set CI=true; skip the interactive pause there so the script
rem never blocks an automated/non-interactive run.
if not defined CI pause
