---
title: Ana sayfa
hide:
  - toc
---

<div class="hero" markdown>

# Calculator - Java + Maven ders şablonu

Dönem projesi için eksiksiz, test edilmiş bir başlangıç noktası: **Java 17**, **Maven**, **JUnit 5**, **JaCoCo** ve
**ReportGenerator** ile kapsama, **Javadoc** ve **Doxygen** ile API belgeleri ve bu site - her rapor **Windows ve Linux**'ta
üretilir, her sürüm dosyası yerelde ve GitHub'da aynı biçimde adlandırılır.

<p class="badge-row">
<a href="https://github.com/ucoruh/eclipse-java-maven-template/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/ucoruh/eclipse-java-maven-template/ci.yml?branch=main&amp;label=build" alt="Build status"></a>
<a href="../reports/linux/coverage-reportgenerator/"><img src="../assets/badge_combined.svg" alt="Kod kapsaması"></a>
<a href="../reports/linux/doccoverage-reportgenerator/"><img src="../assets/badge_doccoverage.svg" alt="Dokümantasyon kapsaması"></a>
<a href="https://github.com/ucoruh/eclipse-java-maven-template/releases/latest"><img src="https://img.shields.io/github/v/release/ucoruh/eclipse-java-maven-template?label=release" alt="Son sürüm"></a>
<a href="https://github.com/ucoruh/eclipse-java-maven-template/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-AGPL--3.0-blue" alt="Lisans: AGPL-3.0"></a>
</p>

[Son sürümü indir](https://github.com/ucoruh/eclipse-java-maven-template/releases/latest){ .md-button .md-button--primary }
[Buradan başlayın: araçları kurun](guide/install.md){ .md-button }
[English](../){ .md-button }

</div>

## Başlangıç

<div class="grid cards" markdown>

- :material-book-open-variant: **Kılavuz**

    Kurulum, şablonu kullanma, proje konusunu kendi projenize çevirme, günlük çalışma, sorun giderme.

    [:octicons-arrow-right-24: Kılavuzu aç](guide/install.md)

- :material-translate: **English / Türkçe**

    Tüm site - kılavuzlar, rapor sayfaları, indirmeler - iki dilde de var. Başlıktaki dil seçiciyi kullanın.

    [:octicons-arrow-right-24: English](../)

- :material-presentation: **GitHub Pages olmadan projenizi gösterin**

    GitHub Free'de özel depo mu? Tam siteyi yerelde derleyip açın, gösterim kontrol listesiyle.

    [:octicons-arrow-right-24: Kontrol listesi](guide/showcase.md)

- :material-tag-text: **Adlandırma standardı ve site kuralları**

    Betik adları, klasörler, sürüm dosyaları ve bir raporun ne zaman çerçevelenip ne zaman kendi başına açıldığı.

    [:octicons-arrow-right-24: Standardı oku](guide/standard.md)

</div>

## Raporlar - Windows ve Linux yan yana

<div class="grid cards" markdown>

- :fontawesome-brands-windows: **Windows**

    Birim testleri, kapsama (JaCoCo ve ReportGenerator), dokümantasyon kapsaması, Doxygen, Javadoc.

    [:octicons-arrow-right-24: Windows raporları](reports/windows/index.md)

- :fontawesome-brands-linux: **Linux (WSL dahil)**

    Aynı takım Linux'ta üretildi - sayılar ve görünüm hafifçe farklı olabilir.

    [:octicons-arrow-right-24: Linux raporları](reports/linux/index.md)

- :material-help-circle: **Hangi rapor hangisi?**

    Native araç ve ReportGenerator; her raporun neden iki kez var olduğu.

    [:octicons-arrow-right-24: Açıklama](guide/which-report.md)

- :material-api: **API belgeleri**

    Doxygen, Javadoc ve JXR çapraz başvuruları, platform başına.

    [:octicons-arrow-right-24: API belgeleri](api.md)

- :material-download: **İndirmeler**

    Her sürüm dosyası: uygulamalar, rapor arşivleri, kaynak, site, sağlama toplamları.

    [:octicons-arrow-right-24: İndirmeler](downloads.md)

- :material-language-java: **Maven sitesi (native)**

    Checkstyle, PMD, CPD, SpotBugs, Surefire - yalnızca Maven'in üretebildiği sayfalar, kendi sekmesinde.

    [:octicons-arrow-right-24: Maven sitesi](maven-site.md)

</div>

## Betikler tek tabloda

Aynı numara = her ders şablonunda aynı iş; platform sonektir (`-windows.bat`, `-linux.sh`; WSL de Linux'tur).

| # | İş | Windows | Linux / WSL |
|---|---|---|---|
| 1 | Git kancalarını kur | `1-configure-git-hooks-windows.bat` | `./1-configure-git-hooks-linux.sh` |
| 3 | Paket yöneticisini kur | `3-install-package-manager-windows.bat` | - |
| 4 | Araçları kur | `4-install-tools-windows.bat` | `./4-install-tools-linux.sh` |
| 5 | Kodu biçimlendir | `5-format-code-windows.bat` | `./5-format-code-linux.sh` |
| 6 | Derle + birim testleri (hızlı) | `6-build-and-test-windows.bat` | `./6-build-and-test-linux.sh` |
| 7 | Her şey: raporlar, API belgeleri, siteler, `release/` | `7-build-all-windows.bat` | `./7-build-all-linux.sh` |
| 8 | Uygulamayı çalıştır | `8-run-app-windows.bat` | `./8-run-app-linux.sh` |
| 9 | Siteyi http://localhost üzerinde aç | `9-open-site-windows.bat` | `./9-open-site-linux.sh` |
| 10 | GitHub CLI ile sürüm yayınla | `10-release-windows.bat` | `./10-release-linux.sh` |
| 11 | Temizle | `11-clean-windows.bat` | `./11-clean-linux.sh` |
