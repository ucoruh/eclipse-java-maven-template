@echo off
@setlocal enableextensions
@cd /d "%~dp0"

if /I "%~1"=="--serve" goto :serve

echo Opening the already-built static site in your default browser...
if not exist "calculator-app\target\site\index.html" (
    echo [ERROR] calculator-app\target\site\index.html not found.
    echo Build it first: 7-build-app.bat
    exit /b 1
)
start "" "calculator-app\target\site\index.html"
goto :end

:serve
echo Running a live Maven site server ^(rebuilds from src\site on demand^)...
echo Open http://localhost:9000/ - Use CTRL+C to stop.
start http://localhost:9000/
call mvn -f "calculator-app\pom.xml" site:run

:end
echo Operation Completed!
if not defined CI pause
