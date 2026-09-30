# Üç ders şablonunda raporlar

**Bu** şablon için "hangi rapor hangisi" dökümü [Hangi rapor hangisi?](which-report.md) sayfasındadır; rapor
sayfalarının kendisini görmek için önce siteyi derleyin (`7-build-all-windows.bat` / `./7-build-all-linux.sh`).

## Aynı fikir, üç ekosistem

Üç ders şablonu da aynı standardı izler ([Adlandırma standardı](standard-tr.md)): her rapor **iki kez** (native araç +
ekosistemler arası araç), **Windows ve Linux'ta**, ana site olarak **MkDocs Material** içinde gösterilir; ekosistemin
kendi site aracı yanında (`native/`) yayınlanır.

| Konu | Java (bu depo) | C/C++ (`cpp-cmake-ctest-template`) | C# (`vs-net-core-template`) |
|---|---|---|---|
| Birim test sonuçları | JUnit XML -> `junit2html` (Maven sitesinde Surefire sayfası) | CTest JUnit XML -> `junit2html` | .NET TRX -> HTML |
| Kod kapsaması, native | JaCoCo HTML | OpenCppCoverage HTML (Windows) / lcov, gcovr (Linux) | coverlet lcov -> `genhtml` |
| Kod kapsaması, diğer aile | ReportGenerator (JaCoCo XML'inden) | ReportGenerator (kapsama XML'inden) | ReportGenerator (coverlet'in cobertura XML'inden) |
| Dokümantasyon kapsaması | coverxygen -> `genhtml` **ve** coverxygen -> ReportGenerator | aynısı | aynısı |
| API belgeleri, ekosistemin kendi aracı | Javadoc | Doxygen (ayrı bir "native" C++ belge aracı yoktur) | DocFX |
| API belgeleri, diller arası | Doxygen | Doxygen | Doxygen |
| Ekosistemin kendi sitesi (`native/` altında yayınlanır, asla çerçevelenmez) | `mvn site` (Fluido teması) | - | DocFX sitesi |
| Ana site | MkDocs Material | MkDocs Material | MkDocs Material |

Geri kalan her şey (rozetler, `-historydir` kapsama eğilimi, sürümdeki `...-site.zip`) üçünde de aynı çalışır -
bkz. [Sürümler ve özel depolar](releases-tr.md).
