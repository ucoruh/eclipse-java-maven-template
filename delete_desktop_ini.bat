@echo off
setlocal enabledelayedexpansion

echo Deleting all desktop.ini files recursively from the current folder...
for /r %%i in (desktop.ini) do (
    echo Deleting: %%i
    del "%%i"
)

echo Process completed.
