@echo off
@setlocal enableextensions
@cd /d "%~dp0"

echo Formatting Java Code with Astyle...

where astyle >nul 2>&1
if errorlevel 1 (
    echo [ERROR] astyle not found on PATH. Fix: choco install astyle -y
    exit /b 1
)

rem --mode=java tells Astyle to use Java brace/indent conventions instead of
rem the C/C++ defaults (this project's source is Java, not C#).
astyle --mode=java --options="astyle-options.txt" --recursive "calculator-app/src/main/java/*.java" "calculator-app/src/test/java/*.java"

if not defined CI pause
