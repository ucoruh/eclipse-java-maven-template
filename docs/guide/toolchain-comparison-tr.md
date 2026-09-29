# Üç ders şablonunda raporlar

**Bu** şablon için tam "hangi rapor hangisi" dökümü, betikleri anlattığı raporların hemen yanında, üretilen
sitenin kendisinde yaşar: `calculator-app/target/site/tool-catalog.html` (kaynağı:
`calculator-app/src/site/markdown/tool-catalog.md`), sitenin sol menüsünde **"Which report is which?"** olarak
bağlantılıdır. Bu dosya henüz yoksa önce siteyi derleyin (`7-build-app.bat`/`.sh`).

## Aynı fikir, üç ekosistem

Üç ders şablonu deposu da aynı "her rapor iki kez: native araç + ReportGenerator" fikrini izler, bu yüzden burada
okumayı öğrendiğiniz şey doğrudan aktarılır:

| Konu | Java (bu depo) | C/C++ (`cpp-cmake-ctest-template`) | C# (`vs-net-core-template`) |
|---|---|---|---|
| Birim test sonuçları | Maven Surefire Report | CTest JUnit XML -> `junit2html` | .NET TRX -> HTML |
| Kod kapsama, native | JaCoCo HTML | OpenCppCoverage HTML (Windows) / `gcovr` (Linux) | `dotnet-coverage` |
| Kod kapsama, diğer aile | ReportGenerator (JaCoCo XML'inden) | ReportGenerator (kapsama XML'inden) | ReportGenerator (coverlet'in cobertura XML'inden) |
| Dokümantasyon kapsama | coverxygen -> `genhtml` **ve** coverxygen -> ReportGenerator | coverxygen -> `genhtml` **ve** coverxygen -> ReportGenerator | coverxygen -> `genhtml` **ve** coverxygen -> ReportGenerator |
| API dokümantasyonu, ekosistem-native | Javadoc | Doxygen (ayrı bir "native" C++ doküman aracı yok - Doxygen ikisi de) | DocFX |
| API dokümantasyonu, diller-arası | Doxygen | Doxygen | Doxygen |
| Site | `mvn site` (Fluido skin) | Site olarak Doxygen HTML | DocFX sitesi |

Geri kalan her şey (rozetler, `-historydir` kapsama trendi, release'deki `site.zip`) üçünde de aynı şekilde çalışır
- bakınız [releases-tr.md](releases-tr.md).
