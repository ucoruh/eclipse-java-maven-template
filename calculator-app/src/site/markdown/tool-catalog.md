# Which tool produced which page?

This project produces every coverage/documentation page **twice**: once with the ecosystem's own ("native") tool,
and once with [ReportGenerator](https://reportgenerator.io/), so you can see both side by side and understand what
each tool adds. All of them are produced by `7-build-app.bat` / `7-build-app.sh`, and every one of them also gets
its own page **inside this site**, in a styled frame with an "Open in a new tab" and a "Download (zip)" button -
see the **Reports** menu on the left, or click a link in the "Folder" column below.

| # | What it shows | Native tool | Folder | Alternate tool | Folder |
|---|---|---|---|---|---|
| 1 | Did the tests pass? What did each one assert? | Maven **Surefire Report** (HTML rendering of the JUnit XML under `target/surefire-reports`) | [`surefire.html`](reports/surefire.html) | — (single family for this template; see `docs/guide/toolchain-comparison-en.md` for the C/C++ and C# equivalents) | — |
| 2 | Which lines/branches/methods did the tests execute? | **JaCoCo** HTML | [`jacoco/index.html`](reports/jacoco.html) | **ReportGenerator** HTML, with coverage **badges** (`assets/badge_*.svg`) and a **history** trend (`report_coverage_hist/`, kept outside `target/` so `mvn clean` does not erase it) | [`coveragereport/index.html`](reports/coveragereport.html) |
| 3 | How much of the public API has a Javadoc comment? | **coverxygen** (reads the Doxygen XML) → **lcov** `genhtml` | [`coverxygen/index.html`](reports/coverxygen.html) | same `lcov.info`, rendered by **ReportGenerator** instead of `genhtml`, plus a documentation-coverage **badge** (`assets/badge_doccoverage.svg`) | [`coverxygen-reportgenerator/index.html`](reports/coverxygen-reportgenerator.html) |
| 4 | API reference (classes, methods, parameters) | **Javadoc** (the Java-ecosystem-native tool) | [`apidocs/index.html`](reports/javadoc.html) | **Doxygen** HTML (the same tool the C/C++ and mixed-language templates use, so the three course templates look alike) | [`doxygen/html/index.html`](reports/doxygen.html) |

## Why two tools per page?

- The **native** tool (JaCoCo, Javadoc, `genhtml`) is what a Java developer reaches for by default; it needs no extra
  installation beyond the JDK/Maven plugins already declared in `pom.xml`.
- **ReportGenerator** is a separate cross-ecosystem tool (it also drives the coverage pages in the C++ and C#
  course templates). It adds two things the native tools do not: **badges** you can embed in `README.md`, and a
  **history** view that plots coverage over several builds. Comparing both outputs on the same data is a good
  exercise in reading a coverage page critically — the numbers should match; the presentation differs.

## Code quality pages (Java-only, no ReportGenerator equivalent)

`mvn site` also runs three static-analysis pages that have no ReportGenerator/native pairing — they are Java
specific and only make sense as a single page:

- **Checkstyle** (`checkstyle.html`) — coding-style conformance (Google style, informational only, does not fail the
  build).
- **PMD** (`pmd.html`) and **CPD** (`cpd.html`) — design smells and copy-pasted code.
- **SpotBugs** (`spotbugs.html`) — static bug-pattern detector (bytecode-based, so it runs after `mvn package`).

## Where the raw data comes from

```text
target/surefire-reports/*.xml        <- Surefire (raw JUnit XML; surefire.html is its HTML rendering)
target/site/jacoco/jacoco.xml        <- JaCoCo (raw coverage XML; also fed to ReportGenerator)
target/site/doxygen/xml/*.xml        <- Doxygen (raw Javadoc-comment inventory; fed to coverxygen)
target/site/coverxygen/lcov.info     <- coverxygen's lcov file (fed to both genhtml and ReportGenerator)
```

If a page is empty or missing, re-run `7-build-app.bat` (Windows) or `7-build-app.sh` (Linux/WSL) and read its
console output top to bottom — every step prints what it is about to do before doing it.

---

# Hangi sayfayı hangi araç üretti?

Bu proje her kapsama/dokümantasyon sayfasını **iki kez** üretir: bir kez ekosistemin kendi ("native") aracıyla, bir
kez de [ReportGenerator](https://reportgenerator.io/) ile — böylece ikisini yan yana görüp her aracın ne kattığını
anlayabilirsiniz. Hepsi `7-build-app.bat` / `7-build-app.sh` tarafından üretilir; her biri ayrıca bu sitenin
içinde, çerçeveli kendi sayfasında da gösterilir — soldaki **Reports** menüsüne veya aşağıdaki "Klasör" sütunundaki
bağlantıya bakın.

| # | Ne gösterir? | Native araç | Klasör | Alternatif araç | Klasör |
|---|---|---|---|---|---|
| 1 | Testler geçti mi? Her biri neyi doğruladı? | Maven **Surefire Report** (`target/surefire-reports` altındaki JUnit XML'in HTML hali) | [`surefire.html`](reports/surefire.html) | — | — |
| 2 | Testler hangi satır/dal/metotları çalıştırdı? | **JaCoCo** HTML | [`jacoco/index.html`](reports/jacoco.html) | **ReportGenerator** HTML, kapsama **rozetleri** (`assets/badge_*.svg`) ve **geçmiş** (history) trendiyle (`report_coverage_hist/`, `target/` dışında tutulur ki `mvn clean` silmesin) | [`coveragereport/index.html`](reports/coveragereport.html) |
| 3 | Genel API'nin ne kadarında Javadoc yorumu var? | **coverxygen** (Doxygen XML'ini okur) → **lcov** `genhtml` | [`coverxygen/index.html`](reports/coverxygen.html) | aynı `lcov.info`, `genhtml` yerine **ReportGenerator** ile, artı bir doküman-kapsama **rozeti** (`assets/badge_doccoverage.svg`) | [`coverxygen-reportgenerator/index.html`](reports/coverxygen-reportgenerator.html) |
| 4 | API referansı (sınıflar, metotlar, parametreler) | **Javadoc** (Java ekosisteminin kendi aracı) | [`apidocs/index.html`](reports/javadoc.html) | **Doxygen** HTML (C/C++ ve karma dil şablonlarının da kullandığı araç; üç ders şablonu böylece birbirine benzer) | [`doxygen/html/index.html`](reports/doxygen.html) |

## Neden her sayfa için iki araç?

- **Native** araç (JaCoCo, Javadoc, `genhtml`) bir Java geliştiricisinin varsayılan tercihidir; `pom.xml`'de zaten
  tanımlı JDK/Maven eklentileri dışında ekstra kurulum gerektirmez.
- **ReportGenerator** ayrı, ekosistemler-arası bir araçtır (C++ ve C# ders şablonlarındaki kapsama sayfalarını da o
  üretir). Native araçların vermediği iki şeyi ekler: `README.md`'ye gömebileceğiniz **rozetler** (badges) ve birkaç
  derleme boyunca kapsamayı grafikleyen **geçmiş** (history) görünümü. Aynı veri üzerinde iki çıktıyı karşılaştırmak,
  bir kapsama sayfasını eleştirel okumak için iyi bir alıştırmadır — sayılar örtüşmeli, sunum farklıdır.

## Kod kalitesi sayfaları (yalnız Java, ReportGenerator karşılığı yok)

`mvn site` ayrıca ReportGenerator/native eşleşmesi olmayan üç statik analiz sayfası çalıştırır — bunlar Java'ya
özgüdür ve tek sayfa olarak anlamlıdır:

- **Checkstyle** (`checkstyle.html`) — kodlama stiline uygunluk (Google stili, yalnız bilgilendirme, derlemeyi
  durdurmaz).
- **PMD** (`pmd.html`) ve **CPD** (`cpd.html`) — tasarım kokuları ve kopya-yapıştır kod.
- **SpotBugs** (`spotbugs.html`) — bytecode tabanlı statik hata deseni bulucu (bu yüzden `mvn package`'dan sonra
  çalışır).

## Ham veri nereden geliyor?

```text
target/surefire-reports/*.xml        <- Surefire (ham JUnit XML; surefire.html onun HTML hali)
target/site/jacoco/jacoco.xml        <- JaCoCo (ham kapsama XML'i; ReportGenerator'a da verilir)
target/site/doxygen/xml/*.xml        <- Doxygen (ham Javadoc-yorum envanteri; coverxygen'e verilir)
target/site/coverxygen/lcov.info     <- coverxygen'in lcov dosyası (hem genhtml'e hem ReportGenerator'a verilir)
```

Bir sayfa boş ya da eksikse `7-build-app.bat` (Windows) veya `7-build-app.sh` (Linux/WSL) betiğini yeniden çalıştırın
ve konsol çıktısını baştan sona okuyun — her adım ne yapacağını, yapmadan önce yazdırır.
