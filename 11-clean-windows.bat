@echo off
rem 11 - delete everything the scripts generated (all of it is gitignored, nothing you wrote is touched).
rem   11-clean-windows.bat          removes build\ publish\ release\ site\ site-native\ and the Windows/Linux
rem                                 report folders and calculator-app\target\  (report HISTORY is kept)
rem   11-clean-windows.bat --all    also removes the report history (coverage trend starts again)
@setlocal enableextensions
@cd /d "%~dp0"
set "ALL=0"
for %%A in (%*) do if /I "%%~A"=="--all" set "ALL=1"

for %%D in (build publish release site site-native calculator-app\target docs\reports docs\native docs\downloads docs\assets) do (
    if exist "%%D" (
        echo removing %%D
        rd /S /Q "%%D"
    )
)
del /Q docs\downloads.*.md docs\maven-site.*.md >nul 2>nul
if exist "reports" (
    for /d %%P in (reports\*) do (
        for /d %%K in ("%%P\*") do (
            if /I not "%%~nxK"=="_history" (
                echo removing %%K
                rd /S /Q "%%K"
            )
        )
    )
)
if "%ALL%"=="1" if exist "reports" (
    echo removing reports ^(including history^)
    rd /S /Q "reports"
)
echo Clean done.
if not defined CI if not defined NO_PAUSE pause
exit /b 0
