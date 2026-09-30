@echo off
rem 7 - EVERYTHING on Windows: build + tests (script 6), code coverage (JaCoCo + ReportGenerator),
rem API docs (Doxygen + Javadoc), documentation coverage (coverxygen -> genhtml + ReportGenerator),
rem the Maven site, the MkDocs site, and the release\ folder (same names as the GitHub release).
rem   7-build-all-windows.bat            full local run
rem   7-build-all-windows.bat --no-site  reports + release parts only (what the CI platform job runs)
@setlocal enableextensions enabledelayedexpansion
@cd /d "%~dp0"

set "NO_SITE="
set "NO_MKDOCS_2_WARNING=true"
for %%A in (%*) do if /I "%%~A"=="--no-site" set "NO_SITE=1"

call scripts\load-env-windows.bat
if errorlevel 1 exit /b 1
call scripts\detect-python-windows.bat
if errorlevel 1 exit /b 1

echo ============================================================
echo  %PROJECT_NAME% %VERSION% - build EVERYTHING (%PLATFORM%-%ARCH%)
echo ============================================================
for %%T in (mvn doxygen reportgenerator) do (
    where %%T >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] %%T not found on PATH. Run 4-install-tools-windows.bat ^(then open a NEW terminal^).
        exit /b 1
    )
)
call scripts\detect-genhtml-windows.bat
if errorlevel 1 exit /b 1
%PY% -c "import coverxygen, junit2htmlreport" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] coverxygen / junit2html missing for this Python. Fix: %PY% -m pip install --user -r requirements.txt
    exit /b 1
)

echo [1/9] Clean the generated Windows output (the reports history is kept)
for %%D in (tests-junit2html coverage-jacoco coverage-reportgenerator doccoverage-lcov doccoverage-reportgenerator api-doxygen api-javadoc api-xref-jxr api-xreftest-jxr api-testjavadoc) do (
    if exist "reports\windows\%%D" rd /S /Q "reports\windows\%%D"
)
if exist "release" rd /S /Q "release"
mkdir "release"
if exist "site-native" rd /S /Q "site-native"
if exist "site" rd /S /Q "site"

echo [2/9] Build + unit tests + app (script 6)
set "NO_PAUSE=1"
call .\6-build-and-test-windows.bat
if errorlevel 1 exit /b 1

echo [3/9] Doxygen: API docs (HTML) + XML for coverxygen  -^> reports\windows\api-doxygen\
set "DOXYGEN_OUTPUT_DIR=reports/windows/api-doxygen"
call doxygen Doxyfile
if errorlevel 1 (
    echo [ERROR] Doxygen failed - see the output above.
    exit /b 1
)

echo [4/9] ReportGenerator on the JaCoCo XML  -^> reports\windows\coverage-reportgenerator\
if not exist "reports\windows\_history\coverage" mkdir "reports\windows\_history\coverage"
call reportgenerator "-reports:calculator-app\target\site\jacoco\jacoco.xml" "-sourcedirs:calculator-app\src\main\java" "-targetdir:reports\windows\coverage-reportgenerator" "-historydir:reports\windows\_history\coverage" "-reporttypes:Html;Badges" "-title:%PROJECT_NAME% %VERSION% - code coverage (windows)"
if errorlevel 1 (
    echo [ERROR] reportgenerator failed on the JaCoCo report.
    exit /b 1
)
copy /Y "reports\windows\coverage-reportgenerator\badge_combined.svg" "assets\badge_combined.svg" >nul
copy /Y "reports\windows\coverage-reportgenerator\badge_branchcoverage.svg" "assets\badge_branchcoverage.svg" >nul
copy /Y "reports\windows\coverage-reportgenerator\badge_linecoverage.svg" "assets\badge_linecoverage.svg" >nul
copy /Y "reports\windows\coverage-reportgenerator\badge_methodcoverage.svg" "assets\badge_methodcoverage.svg" >nul

echo [5/9] coverxygen: Doxygen XML -^> lcov.info, then genhtml  -^> reports\windows\doccoverage-lcov\
mkdir "reports\windows\doccoverage-lcov"
rem The --prefix uses forward slashes on purpose: a trailing backslash before the closing quote is
rem parsed by Windows as an escaped quote and swallows every argument after it.
set "PREFIX=%CD:\=/%/calculator-app/"
call %PY% -m coverxygen --xml-dir "reports\windows\api-doxygen\xml" --src-dir "." --format lcov --output "reports\windows\doccoverage-lcov\lcov.info" --prefix "!PREFIX!"
set "LCOV_SIZE=0"
for %%L in ("reports\windows\doccoverage-lcov\lcov.info") do set "LCOV_SIZE=%%~zL"
if "!LCOV_SIZE!"=="0" (
    echo [ERROR] coverxygen produced an empty lcov.info - check the Doxygen XML in reports\windows\api-doxygen\xml.
    exit /b 1
)
call "%PERL%" "%GENHTML%" --legend --title "Documentation coverage (windows)" "reports\windows\doccoverage-lcov\lcov.info" -o "reports\windows\doccoverage-lcov"
if errorlevel 1 (
    echo [ERROR] genhtml failed - see the output above.
    exit /b 1
)

echo [6/9] ReportGenerator on the same lcov.info  -^> reports\windows\doccoverage-reportgenerator\
if not exist "reports\windows\_history\doccoverage" mkdir "reports\windows\_history\doccoverage"
call reportgenerator "-reports:reports\windows\doccoverage-lcov\lcov.info" "-targetdir:reports\windows\doccoverage-reportgenerator" "-historydir:reports\windows\_history\doccoverage" "-reporttypes:Html;Badges" "-title:%PROJECT_NAME% %VERSION% - documentation coverage (windows)"
if errorlevel 1 (
    echo [ERROR] reportgenerator failed on the coverxygen lcov.info.
    exit /b 1
)
copy /Y "reports\windows\doccoverage-reportgenerator\badge_combined.svg" "assets\badge_doccoverage.svg" >nul

echo [7/9] Maven site (Surefire, JaCoCo, Javadoc, JXR, Checkstyle, PMD, CPD, SpotBugs)  -^> site-native\
%PY% scripts\assemble.py prep
call mvn -B -f "calculator-app\pom.xml" -Drevision=%VERSION% site
if errorlevel 1 (
    echo [ERROR] "mvn site" failed - see the Maven output above.
    exit /b 1
)
robocopy "calculator-app\target\site" "site-native" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (
    echo [ERROR] robocopy could not copy the Maven site to site-native\.
    exit /b 1
)
robocopy "calculator-app\target\site\jacoco" "reports\windows\coverage-jacoco" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 exit /b 1
robocopy "calculator-app\target\site\apidocs" "reports\windows\api-javadoc" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 exit /b 1
robocopy "calculator-app\target\site\testapidocs" "reports\windows\api-testjavadoc" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 exit /b 1
robocopy "calculator-app\target\site\xref" "reports\windows\api-xref-jxr" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 exit /b 1
robocopy "calculator-app\target\site\xref-test" "reports\windows\api-xreftest-jxr" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 exit /b 1
rem the Maven site frames every standalone report: give it its own copy of them
%PY% scripts\assemble.py native
if errorlevel 1 exit /b 1

echo [8/9] Package every Windows report into release\
%PY% scripts\assemble.py reports --platform windows
if errorlevel 1 exit /b 1

if defined NO_SITE (
    echo [9/9] --no-site: MkDocs site skipped ^(CI builds it once, from both platforms^)
    goto :done
)
echo [9/9] MkDocs Material site  -^> site\   and the rest of release\
%PY% -c "import material" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] mkdocs-material is not installed. Fix: %PY% -m pip install --user -r requirements.txt
    exit /b 1
)
%PY% scripts\assemble.py site
if errorlevel 1 exit /b 1
%PY% -m mkdocs build --strict -q -d site
if errorlevel 1 (
    echo [ERROR] "mkdocs build" failed - see the warnings above.
    exit /b 1
)
%PY% scripts\assemble.py finalize
if errorlevel 1 exit /b 1

:done
echo ....................
echo Operation completed.
echo   Site:        site\index.html   (9-open-site-windows.bat serves it on http://localhost:8000/)
echo   Maven site:  site-native\index.html
echo   Reports:     reports\windows\
echo   Release:     release\          (ASSETS.md lists every file)
echo ....................
if not defined CI pause
exit /b 0
