# Reports across the three course templates

The full "which report is which" breakdown for **this** template lives on the generated site itself, next to the
tools it describes: `calculator-app/target/site/tool-catalog.html` (source:
`calculator-app/src/site/markdown/tool-catalog.md`), linked as **"Which report is which?"** in the site's left
menu. Build the site first (`7-build-app.bat`/`.sh`) if that file does not exist yet.

## The same idea, three ecosystems

All three course template repositories follow the same "every report twice: native tool + ReportGenerator" idea,
so what you learn to read here transfers directly:

| Concern | Java (this repo) | C/C++ (`cpp-cmake-ctest-template`) | C# (`vs-net-core-template`) |
|---|---|---|---|
| Unit-test results | Maven Surefire Report | CTest JUnit XML -> `junit2html` | .NET TRX -> HTML |
| Code coverage, native | JaCoCo HTML | OpenCppCoverage HTML (Windows) / `gcovr` (Linux) | `dotnet-coverage` |
| Code coverage, other family | ReportGenerator (from the JaCoCo XML) | ReportGenerator (from the coverage XML) | ReportGenerator (from coverlet's cobertura XML) |
| Documentation coverage | coverxygen -> `genhtml` **and** coverxygen -> ReportGenerator | coverxygen -> `genhtml` **and** coverxygen -> ReportGenerator | coverxygen -> `genhtml` **and** coverxygen -> ReportGenerator |
| API docs, ecosystem-native | Javadoc | Doxygen (there is no separate "native" C++ doc tool - Doxygen is both) | DocFX |
| API docs, cross-language | Doxygen | Doxygen | Doxygen |
| Site | `mvn site` (Fluido skin) | Doxygen HTML as the site | DocFX site |

Everything else (badges, `-historydir` coverage trend, `site.zip` in the release) works the same way across all
three - see [releases-en.md](releases-en.md).
