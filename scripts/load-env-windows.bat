@echo off
rem Helper (not a numbered script): load project.env and set the platform tokens.
rem Use from a script that already did "cd /d %~dp0" (repo root):
rem     call scripts\load-env-windows.bat
rem Sets: PROJECT_NAME, VERSION, GITHUB_REPO (from project.env), PLATFORM=windows, ARCH=x64|arm64.
rem It must NOT use setlocal/endlocal - the caller needs the variables.
if not exist "project.env" (
    echo [ERROR] project.env not found in %CD% - run the scripts from the repository root.
    exit /b 1
)
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("project.env") do set "%%A=%%B"
set "PLATFORM=windows"
set "ARCH=x64"
if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"
if not defined PROJECT_NAME (
    echo [ERROR] PROJECT_NAME is missing in project.env.
    exit /b 1
)
if not defined VERSION (
    echo [ERROR] VERSION is missing in project.env.
    exit /b 1
)
exit /b 0
