@echo off
@setlocal enableextensions
@cd /d "%~dp0"

if not exist "calculator-app\target\calculator-app-1.0-SNAPSHOT.jar" (
    echo [ERROR] calculator-app\target\calculator-app-1.0-SNAPSHOT.jar not found.
    echo Build it first: 7-build-app.bat
    exit /b 1
)

if "%~1"=="" (
    echo No arguments given - running a demo expression ^(6 * 7^).
    echo Usage: 8-run-app.bat ^<number^> ^<+^|-^|*^|/^> ^<number^>
    java -jar "calculator-app\target\calculator-app-1.0-SNAPSHOT.jar" 6 "*" 7
) else (
    java -jar "calculator-app\target\calculator-app-1.0-SNAPSHOT.jar" %*
)

echo Operation Completed!
if not defined CI pause
