@echo off
rem 6 - FAST loop: build + unit tests + the runnable app (about a minute).
rem Everything else (coverage, API docs, sites, release folder) is 7-build-all-windows.bat.
rem Output:  build\windows-release\   publish\windows-<arch>\   reports\windows\tests-junit2html\
@setlocal enableextensions enabledelayedexpansion
@cd /d "%~dp0"

call scripts\load-env-windows.bat
if errorlevel 1 exit /b 1
call scripts\detect-python-windows.bat
if errorlevel 1 exit /b 1

echo ============================================================
echo  %PROJECT_NAME% %VERSION% - build + unit tests (%PLATFORM%-%ARCH%)
echo ============================================================

echo [1/4] Maven: clean, compile, run the JUnit 5 tests (JaCoCo attached), package the jar
call mvn -B -f "calculator-app\pom.xml" -Drevision=%VERSION% clean verify
if errorlevel 1 (
    echo [ERROR] "mvn clean verify" failed - see the Maven output above.
    echo         Common causes: wrong JDK on PATH ^(docs\guide\troubleshooting-en.md^), a failing test,
    echo         or no network access to Maven Central on the first run.
    exit /b 1
)

echo [2/4] Stage the build output in build\windows-release\
if exist "build\windows-release" rd /S /Q "build\windows-release"
mkdir "build\windows-release"
copy /Y "calculator-app\target\calculator-app-%VERSION%.jar" "build\windows-release\" >nul
if errorlevel 1 (
    echo [ERROR] calculator-app\target\calculator-app-%VERSION%.jar was not produced.
    echo         ^(project.env VERSION and the pom's revision are passed with -Drevision.^)
    exit /b 1
)

echo [3/4] Unit-test report (junit2html) in reports\windows\tests-junit2html\
%PY% -c "import junit2htmlreport" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] junit2html is not installed for this Python. Fix: %PY% -m pip install --user -r requirements.txt
    echo         ^(or run 4-install-tools-windows.bat^)
    exit /b 1
)
if exist "reports\windows\tests-junit2html" rd /S /Q "reports\windows\tests-junit2html"
mkdir "reports\windows\tests-junit2html\xml"
set "XMLS="
for %%F in ("calculator-app\target\surefire-reports\TEST-*.xml") do (
    copy /Y "%%~F" "reports\windows\tests-junit2html\xml\" >nul
    set "XMLS=!XMLS! "reports\windows\tests-junit2html\xml\%%~nxF""
)
if not defined XMLS (
    echo [ERROR] No Surefire XML found in calculator-app\target\surefire-reports.
    exit /b 1
)
%PY% -m junit2htmlreport --merge "reports\windows\tests-junit2html\xml\all-tests.xml" !XMLS!
if errorlevel 1 (
    echo [ERROR] junit2html could not merge the Surefire XML files.
    exit /b 1
)
%PY% -m junit2htmlreport "reports\windows\tests-junit2html\xml\all-tests.xml" "reports\windows\tests-junit2html\index.html"
if errorlevel 1 (
    echo [ERROR] junit2html could not render the HTML report.
    exit /b 1
)

echo [4/4] Package the application into publish\ and release\
%PY% scripts\assemble.py app --platform windows --arch %ARCH%
if errorlevel 1 exit /b 1

echo ....................
echo Build and tests OK.
echo   jar:      build\windows-release\
echo   app:      publish\windows-%ARCH%\  (run.bat)  and  release\
echo   tests:    reports\windows\tests-junit2html\index.html
echo ....................
if not defined CI if not defined NO_PAUSE pause
exit /b 0
