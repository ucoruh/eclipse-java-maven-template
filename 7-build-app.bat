@echo off

:: Enable necessary extensions
@setlocal enableextensions

echo Get the current directory
set "currentDir=%CD%"

echo Change the current working directory to the script directory
@cd /d "%~dp0"

echo Change directory to calculator-app
cd calculator-app

echo Perform Maven clean, test, site generation, and packaging
call mvn clean test site package

echo Return to the previous directory
cd ..

echo Generate Doxygen HTML and XML Documentation
call doxygen Doxyfile

echo Change directory to calculator-app
cd calculator-app

echo Generate ReportGenerator HTML Report
call reportgenerator "-reports:target/site/jacoco/jacoco.xml" "-sourcedirs:src/main/java" "-targetdir:target/site/coveragereport" -reporttypes:Html

echo Display information about the binary file
echo Our Binary is a Single Jar With Dependencies. You Do Not Need to Compress It.

echo Return to the previous directory
cd ..


echo Generate Doxygen Coverage Report

echo Create coverxygen directory
cd calculator-app
cd target
cd site
mkdir coverxygen
cd ..
cd ..
cd ..

echo Run Coverxygen
call python -m coverxygen --xml-dir ./calculator-app/target/site/doxygen/xml --src-dir ./ --format lcov --output ./calculator-app/target/site/coverxygen/lcov.info --prefix %currentDir%\calculator-app\

echo Run lcov genhtml
call perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml ./calculator-app\target\site\coverxygen\lcov.info -o calculator-app/target/site/coverxygen

echo Package Coverage Report-1
call tar -czvf test-jacoco-report.tar.gz -C calculator-app/target/site/jacoco .

echo Package Coverage Report-2
call tar -czvf test-coverage-report.tar.gz -C calculator-app/target/site/coveragereport .

echo Package Code Documentation
call tar -czvf application-documentation.tar.gz -C calculator-app/target/site/doxygen .

echo Package Product Site
call tar -czvf application-site.tar.gz -C target/site .

echo Return to the previous directory
cd ..

echo Operation Completed!
pause
