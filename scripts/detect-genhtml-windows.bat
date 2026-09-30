@echo off
rem Helper: find genhtml (lcov) and a Windows-native Perl to run it; sets GENHTML and PERL.
rem genhtml is a Perl script. The perl that ships with Git (Git\usr\bin\perl.exe, often first on
rem PATH) cannot read Windows paths ("genhtml: ERROR: cannot read C:/..."), so a Windows-native
rem perl (Strawberry Perl) is needed.
rem Usage:  call scripts\detect-genhtml-windows.bat   (sets GENHTML and PERL, or exits 1)
set "GENHTML="
set "PERL="
for /f "delims=" %%G in ('where genhtml 2^>nul') do if not defined GENHTML set "GENHTML=%%G"
if not defined GENHTML (
    if exist "C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml" set "GENHTML=C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml"
)
if not defined GENHTML (
    echo [ERROR] genhtml not found on PATH or in the default Chocolatey lcov folder.
    echo         Fix: choco install lcov -y   ^(or run 4-install-tools-windows.bat^)
    exit /b 1
)
for /f "delims=" %%P in ('where perl 2^>nul ^| findstr /V /I /L /C:"\usr\bin"') do if not defined PERL set "PERL=%%P"
if not defined PERL (
    if exist "C:\Strawberry\perl\bin\perl.exe" set "PERL=C:\Strawberry\perl\bin\perl.exe"
)
if not defined PERL (
    echo [ERROR] No Windows-native perl found - genhtml needs one ^(Git's own perl cannot read Windows paths^).
    echo         Fix: choco install strawberryperl -y
    exit /b 1
)
exit /b 0
