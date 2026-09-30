@echo off
rem 4 - install / check every tool the numbered scripts use. Safe to re-run (each step checks first).
rem   JDK 17 + Maven   -> 6-build-and-test, 7-build-all
rem   astyle           -> 5-format-code, the pre-commit hook
rem   doxygen, graphviz-> API docs (Doxygen) + coverxygen input
rem   lcov + Strawberry Perl -> genhtml (documentation-coverage HTML, native family)
rem   .NET SDK + reportgenerator (dotnet tool) -> coverage / doc-coverage HTML, badges, history
rem   Python 3.12 packages from requirements.txt (mkdocs-material, junit2html, coverxygen)
rem   gh (GitHub CLI)  -> 10-release
rem Needs Chocolatey (3-install-package-manager-windows.bat installs it). Run in an ADMINISTRATOR terminal.
@setlocal enableextensions
@cd /d "%~dp0"

where choco >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Chocolatey not found. Run 3-install-package-manager-windows.bat first ^(administrator terminal^).
    exit /b 1
)

echo == JDK 17 ==
where java >nul 2>&1
if errorlevel 1 (choco install temurin17 -y) else (echo Java is already installed.)
echo == Maven ==
where mvn >nul 2>&1
if errorlevel 1 (choco install maven -y) else (echo Maven is already installed.)
echo == Astyle ==
where astyle >nul 2>&1
if errorlevel 1 (choco install astyle -y) else (echo Astyle is already installed.)
echo == Doxygen ==
where doxygen >nul 2>&1
if errorlevel 1 (choco install doxygen.install -y) else (echo Doxygen is already installed.)
echo == Graphviz ^(optional: diagrams in the Doxygen output^) ==
where dot >nul 2>&1
if errorlevel 1 (choco install graphviz -y) else (echo Graphviz is already installed.)
echo == lcov ^(genhtml^) ==
where genhtml >nul 2>&1
if errorlevel 1 (choco install lcov -y) else (echo genhtml is already installed.)
echo == Strawberry Perl ^(a Windows-native perl for genhtml; Git's own perl cannot read Windows paths^) ==
set "NATIVEPERL="
for /f "delims=" %%P in ('where perl 2^>nul ^| findstr /V /I /L /C:"\usr\bin"') do if not defined NATIVEPERL set "NATIVEPERL=%%P"
if not defined NATIVEPERL if exist "C:\Strawberry\perl\bin\perl.exe" set "NATIVEPERL=C:\Strawberry\perl\bin\perl.exe"
if not defined NATIVEPERL (choco install strawberryperl -y) else (echo Native perl found: %NATIVEPERL%)
echo == curl ==
where curl >nul 2>&1
if errorlevel 1 (choco install curl -y) else (echo curl is already installed.)

echo == .NET SDK ^(needed for the ReportGenerator global tool^) ==
where dotnet >nul 2>&1
if errorlevel 1 (
    echo [ERROR] dotnet not found on PATH. Install the .NET SDK first, e.g.:  winget install Microsoft.DotNet.SDK.9
    echo         or: choco install dotnet-sdk -y      then open a NEW terminal and re-run this script.
    exit /b 1
)
echo == ReportGenerator ==
dotnet tool update --global dotnet-reportgenerator-globaltool
if errorlevel 1 (
    echo [ERROR] "dotnet tool update --global dotnet-reportgenerator-globaltool" failed.
    exit /b 1
)

echo == Python packages ^(requirements.txt^) ==
call scripts\detect-python-windows.bat
if errorlevel 1 exit /b 1
echo Using: %PY%
%PY% -m pip install --user -r requirements.txt
if errorlevel 1 (
    echo [ERROR] pip could not install requirements.txt for %PY%.
    exit /b 1
)

echo == GitHub CLI ==
where gh >nul 2>&1
if errorlevel 1 (
    choco install gh -y
) else (
    echo GitHub CLI is already installed. Run "gh auth login" once - see docs\guide\releases.en.md.
)

echo ....................
echo All required tools checked/installed. Open a NEW terminal so PATH changes apply.
echo ....................
if not defined CI if not defined NO_PAUSE pause
exit /b 0
