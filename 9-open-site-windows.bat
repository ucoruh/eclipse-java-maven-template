@echo off
rem 9 - open the built site in your browser, served over http://localhost (the report pages use
rem <iframe>, and most browsers block iframes on a file:// page, so opening index.html by
rem double-click shows empty frames).
rem   9-open-site-windows.bat              serve site\            (the MkDocs site, all reports)
rem   9-open-site-windows.bat 9000         same, on port 9000
rem   9-open-site-windows.bat --maven      serve site-native\     (the Maven site on its own)
rem   9-open-site-windows.bat --edit       live-reloading MkDocs dev server (while writing docs)
@setlocal enableextensions
@cd /d "%~dp0"
call scripts\load-env-windows.bat
if errorlevel 1 exit /b 1
call scripts\detect-python-windows.bat
if errorlevel 1 exit /b 1

set "NO_MKDOCS_2_WARNING=true"
set "DIR=site"
set "PORT=8000"
set "MODE=serve"
for %%A in (%*) do (
    if /I "%%~A"=="--maven" set "DIR=site-native"
    if /I "%%~A"=="--edit" set "MODE=edit"
    echo %%~A| findstr /R "^[0-9][0-9]*$" >nul && set "PORT=%%~A"
)

if "%MODE%"=="edit" (
    echo Live MkDocs server - the report pages need a full 7-build-all-windows.bat run first.
    %PY% scripts\assemble.py site
    echo Open http://localhost:%PORT%/ - CTRL+C stops it.
    if not defined CI start "" "http://localhost:%PORT%/"
    %PY% -m mkdocs serve -a localhost:%PORT%
    goto :end
)

if not exist "%DIR%\index.html" (
    echo [ERROR] %DIR%\index.html not found.
    echo Build it first: 7-build-all-windows.bat
    exit /b 1
)
echo Serving %DIR%\ at http://localhost:%PORT%/   ^(CTRL+C stops the server^)
if not defined CI start "" "http://localhost:%PORT%/"
%PY% -m http.server %PORT% --directory "%DIR%"

:end
echo Operation Completed!
if not defined CI if not defined NO_PAUSE pause
exit /b 0
