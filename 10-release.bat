@echo off

:: Enable necessary extensions
@setlocal enableextensions enabledelayedexpansion
@cd /d "%~dp0"

echo ============================================================
echo  Local release: build everything, package release\, publish
echo  with the GitHub CLI (works on a private repo + GitHub Free -
echo  see docs\guide\releases-en.md)
echo ============================================================

set "DRYRUN=0"
set "VERSION="

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--dry-run" (
    set "DRYRUN=1"
    shift
    goto parse_args
)
if not defined VERSION (
    set "VERSION=%~1"
    shift
    goto parse_args
)
shift
goto parse_args
:args_done

if not defined VERSION (
    if exist "VERSION" (
        set /p VERSION=<VERSION
    )
)
if not defined VERSION (
    echo [ERROR] No version given and no VERSION file found.
    echo Usage: 10-release.bat vX.Y.Z [--dry-run]
    echo    or: put "vX.Y.Z" in a VERSION file and run: 10-release.bat [--dry-run]
    exit /b 1
)
echo Release version: %VERSION%

echo -----------------------------------------------------------
echo 1. Refuse a dirty working tree (release must come from a
echo    committed, reviewable state)
echo -----------------------------------------------------------
where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] git not found on PATH.
    exit /b 1
)
set "DIRTY="
for /f "delims=" %%S in ('git status --porcelain 2^>nul') do set "DIRTY=1"
if defined DIRTY (
    echo [ERROR] Working tree is not clean. Commit or stash your changes first:
    git status --short
    exit /b 1
)

echo -----------------------------------------------------------
echo 2. Check the GitHub CLI is installed and logged in
echo -----------------------------------------------------------
where gh >nul 2>&1
if errorlevel 1 (
    echo [ERROR] GitHub CLI "gh" not found. Fix: choco install gh -y
    exit /b 1
)
gh auth status >nul 2>&1
if errorlevel 1 (
    echo [ERROR] gh is not logged in to GitHub.
    echo Fix: gh auth login
    echo ^(see docs\guide\releases-en.md for a step-by-step walkthrough,
    echo including the GitHub Student Developer Pack^)
    exit /b 1
)

echo -----------------------------------------------------------
echo 3. Build everything locally: jar, both coverage-report
echo    families, both doc-coverage families, API docs, site
echo -----------------------------------------------------------
call "%~dp07-build-app.bat"
if errorlevel 1 (
    echo [ERROR] Build failed - fix it before releasing.
    exit /b 1
)

echo -----------------------------------------------------------
echo 4. Zip the whole site as release\site.zip (download -^> unzip
echo    -^> open index.html; this is how graders see the site on a
echo    private repo without GitHub Pages - see docs\guide\releases-en.md)
echo -----------------------------------------------------------
if exist "release\site.zip" del /q "release\site.zip"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path 'calculator-app\target\site\*' -DestinationPath 'release\site.zip' -Force"
if errorlevel 1 (
    echo [ERROR] Could not create release\site.zip.
    exit /b 1
)
if not exist "release\site.zip" (
    echo [ERROR] release\site.zip was not created.
    exit /b 1
)

echo -----------------------------------------------------------
echo Release assets in release\:
echo -----------------------------------------------------------
dir /b "release"

set "NOTES_FILE=%TEMP%\release-notes-%VERSION%.md"
> "%NOTES_FILE%" echo # %VERSION%
>> "%NOTES_FILE%" echo.
>> "%NOTES_FILE%" echo Built locally with 7-build-app.bat / 7-build-app.sh.
>> "%NOTES_FILE%" echo.
>> "%NOTES_FILE%" echo - application-binary.tar.gz - the runnable jar
>> "%NOTES_FILE%" echo - test-jacoco-report.tar.gz / test-coverage-report.tar.gz - unit-test coverage, native ^(JaCoCo^) and ReportGenerator families
>> "%NOTES_FILE%" echo - doc-coverage-report.tar.gz - documentation coverage ^(coverxygen, both genhtml and ReportGenerator^)
>> "%NOTES_FILE%" echo - application-documentation.tar.gz - Doxygen API docs
>> "%NOTES_FILE%" echo - application-site.tar.gz / site.zip - the full Maven site ^(unzip site.zip and open index.html^)

if "%DRYRUN%"=="1" (
    echo -----------------------------------------------------------
    echo [DRY RUN] Would run:
    echo   gh release create %VERSION% release\* --title "%VERSION%" --notes-file "%NOTES_FILE%"
    echo [DRY RUN] No release was created and nothing was published.
    exit /b 0
)

echo -----------------------------------------------------------
echo 5. Publish with the GitHub CLI (no Actions minutes used)
echo -----------------------------------------------------------
gh release create "%VERSION%" release\* --title "%VERSION%" --notes-file "%NOTES_FILE%"
if errorlevel 1 (
    echo [ERROR] "gh release create" failed - see the output above.
    echo Common causes: the tag %VERSION% already exists, you lack push access,
    echo or an asset exceeds GitHub's 2 GiB-per-file limit.
    exit /b 1
)

echo ....................
echo Release %VERSION% published.
echo ....................
if not defined CI pause
