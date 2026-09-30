@echo off
rem 8 - run the calculator from the jar that 6-build-and-test-windows.bat built.
rem   8-run-app-windows.bat                 demo: 6 * 7
rem   8-run-app-windows.bat 12 + 30         your own expression: <number> <+|-|*|/> <number>
@setlocal enableextensions
@cd /d "%~dp0"
call scripts\load-env-windows.bat
if errorlevel 1 exit /b 1

set "JAR=build\windows-release\calculator-app-%VERSION%.jar"
if not exist "%JAR%" (
    echo [ERROR] %JAR% not found.
    echo Build it first: 6-build-and-test-windows.bat
    exit /b 1
)

if "%~1"=="" (
    echo No arguments given - running a demo expression ^(6 * 7^).
    echo Usage: 8-run-app-windows.bat ^<number^> ^<+^|-^|*^|/^> ^<number^>
    java -jar "%JAR%" 6 "*" 7
) else (
    java -jar "%JAR%" %*
)
if errorlevel 1 exit /b 1

echo Operation Completed!
if not defined CI if not defined NO_PAUSE pause
exit /b 0
