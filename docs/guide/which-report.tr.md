# Hangi rapor hangisi?

Her rapor **hem Windows'ta hem Linux'ta** üretilir ve ayrı tutulur (menüde **Reports → Windows / Linux**): sayılar
genelde aynıdır ama satır sonları, yollar ve araç sürümleri farklılık yaratabilir; bu yüzden iki takım da gösterilir.
Raporların çoğu **iki kez** üretilir: bir kez Java ekosisteminin kendi ("native") aracıyla, bir kez de ekosistemler
arası bir araçla (ReportGenerator, Doxygen); böylece karşılaştırabilirsiniz.

| Ne gösterir? | Native araç (klasör) | Alternatif araç (klasör) |
|---|---|---|
| Testler geçti mi? Hangi test neyi doğruladı? | Surefire XML üzerinde **junit2html** (`tests-junit2html`) — ayrıca [Maven sitesinde](../maven-site.md) Maven *Surefire* sayfası | — |
| Testler hangi satır / dal / metotları çalıştırdı? | **JaCoCo** HTML (`coverage-jacoco`) | rozet ve geçmiş grafiği olan **ReportGenerator** HTML (`coverage-reportgenerator`) |
| Genel API'nin ne kadarında dokümantasyon yorumu var? | **coverxygen → lcov → genhtml** (`doccoverage-lcov`) | aynı lcov dosyasının **ReportGenerator** ile sunumu (`doccoverage-reportgenerator`) |
| API başvurusu (sınıflar, metotlar, parametreler) | **Javadoc** (`api-javadoc`) | **Doxygen** (`api-doxygen`) — C/C++ ve C# şablonlarının da kullandığı araç |
| Kod stili, tasarım kokuları, kopya-yapıştır, hata kalıpları | — | **Maven sitesi**: Checkstyle, PMD, CPD, SpotBugs (yalnız Java) — kendi sekmesinde açılır |
| Çapraz başvurulu kaynak (ana ve test), Test Javadoc | **JXR** `api-xref-jxr`, `api-xreftest-jxr`; **Javadoc** `api-testjavadoc` | — |

Klasör adları `reports/<platform>/<tür>-<araç>/` biçimindedir; örneğin `reports/linux/coverage-jacoco/`.

## Neden bir sayfa için iki araç?

- **Native** araç, `pom.xml`'de zaten tanımlı JDK ve Maven eklentileri dışında hiçbir şey gerektirmez.
- **ReportGenerator** her dil için tek araçtır (C++ ve C# şablonları da kullanır). README için **rozetler** (badges)
  ve birçok derleme boyunca kapsama **geçmişi** ekler. Veri aynı, sunum farklıdır; ikisini karşılaştırmak bir kapsama
  raporunu eleştirel okumak için iyi bir alıştırmadır.

## Çerçeve içinde mi, kendi sitesi olarak mı?

İki tür HTML vardır ve site bunlara farklı davranır:

| Tür | Örnekler | Bu sitede nasıl gösterilir |
|---|---|---|
| **Maven sitesi sayfası olmayan her rapor** (site menüsü olmayan bağımsız HTML) | JaCoCo, ReportGenerator, genhtml, junit2html, Javadoc, Test Javadoc, Doxygen, JXR Source Xref / Test Source Xref | **iki** sitenin `<iframe>`inde: bu sitede sayfa (başlık, açıklama, *Yeni sekmede aç*, *İndir*), Maven native sitesinde küçük sarmalayıcı sayfa |
| **Maven'in kendi menüsüyle kendisinin ürettiği sayfa** | Surefire, Checkstyle, PMD, CPD, SpotBugs, proje bilgisi, bağımlılıklar, eklentiler, SCM | **asla çerçevelenmez** — Maven sitesini yeni sekmede açan bağlantı |

Çerçevelenmiş bir Maven sayfası *site içinde site* gösterir (iki menü, iki başlık, kaydırma çubuğu içinde kaydırma
çubuğu). Doğru/yanlış örneği için *Adlandırma standardı ve site kuralları* sayfasına bakın.

## Ham veri nereden gelir?

```text
calculator-app/target/surefire-reports/*.xml   <- Surefire: ham JUnit XML (junit2html bunu işler)
calculator-app/target/site/jacoco/jacoco.xml    <- JaCoCo: ham kapsama XML (ReportGenerator bunu okur)
reports/<platform>/api-doxygen/xml/             <- Doxygen: dokümantasyon yorumu envanteri (coverxygen okur)
reports/<platform>/doccoverage-lcov/lcov.info   <- coverxygen: lcov dosyası (genhtml VE ReportGenerator okur)
```

Bir sayfa boşsa ya da yoksa `7-build-all-windows.bat` (Windows) veya `./7-build-all-linux.sh` (Linux/WSL) dosyasını
yeniden çalıştırın ve konsol çıktısını baştan okuyun — her adım `[n/9]` diye kendini duyurur.
