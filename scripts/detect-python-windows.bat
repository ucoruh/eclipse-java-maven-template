@echo off
rem Helper: pick a working Python 3 and put the command in PY (e.g. "py -3.12").
rem Why not plain "python"/"py -3"? On some machines "python" is another program's bundled
rem interpreter and "py -3" can be a free-threaded 3.13t build that crashes on C extensions
rem (see docs\guide\troubleshooting-en.md). So we try explicit versions first.
rem Usage:  call scripts\detect-python-windows.bat   (sets PY, or exits 1 with a message)
set "PY="
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"
where py >nul 2>&1
if not errorlevel 1 (
    for %%V in (3.12 3.13 3.11 3.10) do (
        if not defined PY (
            py -%%V -c "import sys" >nul 2>&1
            if not errorlevel 1 set "PY=py -%%V"
        )
    )
)
if not defined PY (
    python -c "import sys; sys.exit(0 if sys.version_info[:2] >= (3, 10) else 1)" >nul 2>&1
    if not errorlevel 1 set "PY=python"
)
if not defined PY (
    echo [ERROR] No usable Python 3.10+ found. Install Python 3.12 from python.org with the
    echo         "py launcher" option ticked, then open a NEW terminal. See docs\guide\install-en.md.
    exit /b 1
)
exit /b 0
