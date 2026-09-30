# Reports across the three course templates

The "which report is which" breakdown for **this** template is the page [Which report is which?](which-report.md);
build the site first (`7-build-all-windows.bat` / `./7-build-all-linux.sh`) to see the report pages themselves.

## The same idea, three ecosystems

All three course templates follow the same standard ([Naming standard](standard-en.md)): every report **twice**
(native tool + a cross-ecosystem tool), on **Windows and Linux**, shown in a **MkDocs Material** main site, with the
ecosystem's own site tool published next to it (`native/`).

| Concern | Java (this repo) | C/C++ (`cpp-cmake-ctest-template`) | C# (`vs-net-core-template`) |
|---|---|---|---|
| Unit-test results | JUnit XML -> `junit2html` (Surefire page in the Maven site) | CTest JUnit XML -> `junit2html` | .NET TRX -> HTML |
| Code coverage, native | JaCoCo HTML | OpenCppCoverage HTML (Windows) / lcov, gcovr (Linux) | coverlet lcov -> `genhtml` |
| Code coverage, other family | ReportGenerator (from the JaCoCo XML) | ReportGenerator (from the coverage XML) | ReportGenerator (from coverlet's cobertura XML) |
| Documentation coverage | coverxygen -> `genhtml` **and** coverxygen -> ReportGenerator | the same | the same |
| API docs, ecosystem-native | Javadoc | Doxygen (there is no separate "native" C++ doc tool) | DocFX |
| API docs, cross-language | Doxygen | Doxygen | Doxygen |
| Ecosystem's own site (published under `native/`, never framed) | `mvn site` (Fluido skin) | - | DocFX site |
| Main site | MkDocs Material | MkDocs Material | MkDocs Material |

Everything else (badges, the `-historydir` coverage trend, `...-site.zip` in the release) works the same way in all
three - see [Releases and private repositories](releases-en.md).
