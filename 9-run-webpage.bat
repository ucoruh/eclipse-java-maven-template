@echo off
@setlocal enableextensions
@cd /d "%~dp0"

if /I "%~1"=="--serve" goto :serve

echo Serving the already-built static site with a local HTTP server.
echo (Report pages use an ^<iframe^>; most browsers block iframes on a
echo file:// page, so this must be served over http://, not opened directly.)
if not exist "calculator-app\target\site\index.html" (
    echo [ERROR] calculator-app\target\site\index.html not found.
    echo Build it first: 7-build-app.bat
    exit /b 1
)
where py >nul 2>&1
if errorlevel 1 (
    echo [ERROR] The "py" launcher was not found. Install Python 3.12+ from python.org
    echo         with "py launcher" enabled, or use "9-run-webpage.bat --serve" instead.
    exit /b 1
)
set "PORT=8000"
if not "%~2"=="" set "PORT=%~2"
echo Open http://localhost:%PORT%/ in your browser. Use CTRL+C to stop.
if not defined CI start "" "http://localhost:%PORT%/"
py -3.12 -m http.server %PORT% --directory "calculator-app\target\site"
goto :end

:serve
echo Running a live Maven site dev server ^(rebuilds pages from src\site on
echo demand^). Only useful while editing site.xml/markdown - the report pages
echo need a full "7-build-app.bat" run first so their iframes have something
echo to point at.
echo Open http://localhost:9000/ - Use CTRL+C to stop.
if not defined CI start http://localhost:9000/
call mvn -f "calculator-app\pom.xml" site:run

:end
echo Operation Completed!
if not defined CI pause
