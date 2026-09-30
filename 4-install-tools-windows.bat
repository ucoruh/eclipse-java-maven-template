@echo off
@setlocal enableextensions
@cd /d "%~dp0"

rem This installs exactly what this repo's own scripts use:
rem   astyle      -> 5-format-code.bat, pre-commit hook
rem   doxygen     -> 7-build-app.bat (API docs + coverxygen's XML input)
rem   graphviz    -> optional, only used if Doxyfile's HAVE_DOT is turned on
rem   lcov        -> 7-build-app.bat (genhtml renders the doc-coverage lcov.info;
rem                  bundles the Perl runtime genhtml needs on Windows)
rem   reportgenerator (dotnet tool) -> 7-build-app.bat (coverage + doc-coverage HTML/badges/history)
rem   coverxygen (py -3.12 pip package) -> 7-build-app.bat
rem   curl        -> 2-create-git-ignore.bat
rem   gh (GitHub CLI) -> 10-release.bat (see docs/guide/releases-en.md)
rem Re-running this script is safe: every step checks first and skips work
rem that is already done ("dotnet tool update" instead of "install" so a
rem second run does not fail with "already installed").

echo Installing Astyle...
where astyle >nul 2>&1
if errorlevel 1 (choco install astyle -y) else (echo Astyle is already installed.)

echo Installing Doxygen...
where doxygen >nul 2>&1
if errorlevel 1 (choco install doxygen.install -y) else (echo Doxygen is already installed.)

echo Installing Graphviz ^(optional - only needed if Doxyfile's HAVE_DOT=YES^)...
where dot >nul 2>&1
if errorlevel 1 (choco install graphviz -y) else (echo Graphviz is already installed.)

echo Installing lcov ^(provides genhtml^)...
where genhtml >nul 2>&1
if errorlevel 1 (
    choco install lcov -y
    echo genhtml is a Perl script; it lives under
    echo C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml and is invoked via "perl".
) else (
    echo genhtml is already installed.
)

echo Installing curl...
where curl >nul 2>&1
if errorlevel 1 (choco install curl -y) else (echo curl is already installed.)

echo Checking for the .NET SDK ^(needed for the ReportGenerator global tool^)...
where dotnet >nul 2>&1
if errorlevel 1 (
    echo [ERROR] dotnet not found on PATH. Install the .NET SDK first, e.g.:
    echo   winget install Microsoft.DotNet.SDK.8
    echo   or: choco install dotnetcore -y
    exit /b 1
)

echo Installing / updating the ReportGenerator global tool...
dotnet tool update --global dotnet-reportgenerator-globaltool
if errorlevel 1 (
    echo [ERROR] "dotnet tool update --global dotnet-reportgenerator-globaltool" failed.
    exit /b 1
)

echo Checking for the "py" launcher ^(needed for coverxygen^)...
where py >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python launcher "py" not found. Install Python 3.12+ from python.org
    echo         with "py launcher" enabled.
    exit /b 1
)

echo Installing coverxygen for py -3.12 ^(NOT plain "pip"/"python": on some machines
echo those resolve to an unrelated Python install, e.g. a graphics tool's bundled one^)...
py -3.12 -m pip install --user coverxygen
if errorlevel 1 (
    echo [ERROR] "py -3.12 -m pip install --user coverxygen" failed.
    exit /b 1
)

echo Checking for the GitHub CLI ^(needed by 10-release.bat^)...
where gh >nul 2>&1
if errorlevel 1 (
    echo GitHub CLI not found. Installing...
    choco install gh -y
) else (
    echo GitHub CLI is already installed. Run "gh auth login" once - see
    echo docs\guide\releases-en.md.
)

echo ....................
echo All required tools checked/installed.
echo ....................

if not defined CI pause
