@echo off

:: Enable necessary extensions
@setlocal enableextensions

rem This template currently has no git submodules (unlike the C/C++ course
rem template, which vendors googletest this way); "git submodule update" below
rem is a harmless no-op here. This script is kept so the numbered-script set
rem stays consistent across the three course templates, and in case you add a
rem submodule of your own later.
echo ::: INIT SUBMODULES BEGIN ::::

echo Get the current directory
set "currentDir=%CD%"

echo Change the current working directory to the script directory
@cd /d "%~dp0"

del desktop.ini /A:H /S

for /r %%i in (desktop.ini) do (
    git rm --cached --force "%%i"
)

git submodule update --init --recursive

echo ::: INIT SUBMODULES COMPLETED ::::
if not defined CI pause