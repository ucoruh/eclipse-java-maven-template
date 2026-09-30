@echo off
rem 10 - LOCAL release: build everything (script 7), then publish release\ with the GitHub CLI.
rem Works on a private repository on GitHub Free and uses no Actions minutes.
rem   10-release-windows.bat --dry-run   build + show the exact gh command and the asset list; publish nothing
rem   10-release-windows.bat             really publish tag v<VERSION from project.env> with every file in release\
rem The version comes from project.env (VERSION=1.1.0 -> tag v1.1.0); edit it there, commit, then release.
rem NOTE: a local build only holds THIS platform's assets. CI (the "v*" tag workflow) builds Windows +
rem Linux + macOS; use this script when you want to release without CI (see docs\guide\releases.en.md).
@setlocal enableextensions enabledelayedexpansion
@cd /d "%~dp0"

set "DRYRUN=0"
for %%A in (%*) do if /I "%%~A"=="--dry-run" set "DRYRUN=1"

call scripts\load-env-windows.bat
if errorlevel 1 exit /b 1
call scripts\detect-python-windows.bat
if errorlevel 1 exit /b 1
set "TAG=v%VERSION%"

echo ============================================================
echo  Local release %TAG% of %PROJECT_NAME%  (platform %PLATFORM%-%ARCH%)
echo ============================================================

echo [1/5] Refuse a dirty working tree (a release must come from a committed state)
where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] git not found on PATH.
    exit /b 1
)
set "DIRTY="
for /f "delims=" %%S in ('git status --porcelain 2^>nul') do set "DIRTY=1"
if defined DIRTY (
    echo [ERROR] The working tree is not clean. Commit or stash your changes first:
    git status --short
    exit /b 1
)

echo [2/5] Check the GitHub CLI is installed and logged in
where gh >nul 2>&1
if errorlevel 1 (
    echo [WARN] GitHub CLI "gh" not found. Fix: choco install gh -y
    if "%DRYRUN%"=="0" exit /b 1
    echo [DRY RUN] Continuing without gh - a real release needs it.
) else (
    gh auth status >nul 2>&1
    if errorlevel 1 (
        echo [WARN] gh is not logged in. Fix: gh auth login   ^(see docs\guide\releases.en.md^)
        if "%DRYRUN%"=="0" exit /b 1
        echo [DRY RUN] Continuing without a login - a real release needs it.
    )
)

echo [3/5] Build everything (7-build-all-windows.bat: reports, API docs, both sites, release\)
set "NO_PAUSE=1"
call .\7-build-all-windows.bat
if errorlevel 1 (
    echo [ERROR] The build failed - fix it before releasing.
    exit /b 1
)

echo [4/5] Release notes
%PY% scripts\assemble.py notes
if errorlevel 1 exit /b 1
echo Files in release\ ^(these become the release assets^):
dir /b "release"

if "%DRYRUN%"=="1" (
    echo [DRY RUN] Would run:
    echo   gh release create %TAG% release\* --title "%PROJECT_NAME% %VERSION%" --notes-file build\release-notes.md
    echo [DRY RUN] No release was created and nothing was published.
    exit /b 0
)

echo [5/5] Publish with the GitHub CLI
gh release create "%TAG%" release\* --title "%PROJECT_NAME% %VERSION%" --notes-file "build\release-notes.md"
if errorlevel 1 (
    echo [ERROR] "gh release create" failed - see the output above.
    echo Common causes: the tag %TAG% already exists ^(raise VERSION in project.env^), you have no write
    echo access to the repository, or an asset is larger than 2 GiB.
    exit /b 1
)
echo ....................
echo Release %TAG% published.
echo ....................
if not defined CI pause
exit /b 0
