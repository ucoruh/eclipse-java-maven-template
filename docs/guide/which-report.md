# Which report is which?

*(Türkçe bölüm sayfanın altında / Turkish section below.)*

Every report is produced **on Windows and on Linux** and kept separately (**Reports → Windows / Linux** in the
menu): the numbers usually match, but line endings, paths and tool versions can make them differ, so both sets
are shown. Most reports are produced **twice**, once with the Java ecosystem's own ("native") tool and once with
a cross-ecosystem tool (ReportGenerator, Doxygen) so you can compare them.

| What it shows | Native tool (folder) | Alternative tool (folder) |
|---|---|---|
| Did the tests pass? Which test asserted what? | **junit2html** on the Surefire XML (`tests-junit2html`) — plus the Maven *Surefire* page in the [Maven site](../maven-site.md) | — |
| Which lines / branches / methods did the tests execute? | **JaCoCo** HTML (`coverage-jacoco`) | **ReportGenerator** HTML with badges and a history trend (`coverage-reportgenerator`) |
| How much of the public API carries a doc comment? | **coverxygen → lcov → genhtml** (`doccoverage-lcov`) | the same lcov file rendered by **ReportGenerator** (`doccoverage-reportgenerator`) |
| API reference (classes, methods, parameters) | **Javadoc** (`api-javadoc`) | **Doxygen** (`api-doxygen`) — the tool the C/C++ and C# templates use too |
| Code style, design smells, copy-paste, bug patterns, cross-referenced source | — | **Maven site**: Checkstyle, PMD, CPD, SpotBugs, JXR (Java only) — open in their own tab |

The folder names follow `reports/<platform>/<kind>-<tool>/`, e.g. `reports/linux/coverage-jacoco/`.

## Why two tools for one page?

- The **native** tool needs nothing beyond the JDK and the Maven plugins already declared in `pom.xml`.
- **ReportGenerator** is one tool for every language (the C++ and C# templates use it too). It adds **badges** for the
  README and a **history** of coverage over many builds. Same data, different presentation — comparing both is a
  good exercise in reading a coverage report critically.

## Shown in a frame, or opened as its own site?

Two kinds of HTML exist, and the site treats them differently:

| Kind | Examples | How this site shows it |
|---|---|---|
| **Standalone HTML** made outside the site generator | JaCoCo, ReportGenerator, genhtml, junit2html, Javadoc, Doxygen | a page inside this site with the report in an `<iframe>` (title, explanation, *Open in a new tab*, *Download*) |
| **A page that carries its own site navigation** | every Maven-site page (Surefire, Checkstyle, PMD, CPD, SpotBugs, JXR, project info) | **never framed** — a link that opens the Maven site in a new tab |

A framed Maven page would show *a site inside a site* (two menus, two banners, a scrollbar in a scrollbar). See
*Naming standard and site rules* for the right/wrong example.

## Where the raw data comes from

```text
calculator-app/target/surefire-reports/*.xml   <- Surefire: raw JUnit XML (junit2html renders it)
calculator-app/target/site/jacoco/jacoco.xml    <- JaCoCo: raw coverage XML (ReportGenerator reads it)
reports/<platform>/api-doxygen/xml/             <- Doxygen: inventory of doc comments (coverxygen reads it)
reports/<platform>/doccoverage-lcov/lcov.info   <- coverxygen: lcov file (genhtml AND ReportGenerator read it)
```

If a page is empty or missing, re-run `7-build-all-windows.bat` (Windows) or `./7-build-all-linux.sh` (Linux/WSL) and
read its console output from the top — every step announces itself as `[n/9]`.

---

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
| Kod stili, tasarım kokuları, kopya-yapıştır, hata kalıpları, çapraz başvurulu kaynak | — | **Maven sitesi**: Checkstyle, PMD, CPD, SpotBugs, JXR (yalnız Java) — kendi sekmesinde açılır |

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
| Site üretecinin **dışında üretilmiş bağımsız HTML** | JaCoCo, ReportGenerator, genhtml, junit2html, Javadoc, Doxygen | sitenin içinde, raporu `<iframe>` ile gösteren sayfa (başlık, açıklama, *Yeni sekmede aç*, *İndir*) |
| **Kendi site gezinmesini taşıyan sayfa** | Maven sitesinin her sayfası (Surefire, Checkstyle, PMD, CPD, SpotBugs, JXR, proje bilgisi) | **asla çerçevelenmez** — Maven sitesini yeni sekmede açan bağlantı |

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
