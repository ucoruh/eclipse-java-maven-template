# Adlandırma standardı ve site kuralları

Aynı standart üç ders şablonunun (Java, C/C++, C#) hepsinde kullanılır; burada öğrendiğiniz her ders projesinde
geçerlidir. Aşağıdakiler öneri değildir: betikler, CI iş akışı ve site bunlara dayanır.

## 1. Projeyi tek dosya adlandırır: `project.env`

```text
PROJECT_NAME=calculator
VERSION=1.1.0
GITHUB_REPO=ucoruh/eclipse-java-maven-template
```

Her betik (`scripts/load-env-windows.bat`, `scripts/load-env-linux.sh`, `scripts/assemble.py`) ve CI iş akışı bu
dosyayı okur. Projeyi yeniden adlandırmak için **yalnızca bu dosyayı** düzenlersiniz (artı Java paketini - bkz.
[Proje konusundan projenize](from-topic-tr.md)). `VERSION` başında `v` olmadan yazılır; Git etiketi `v` + `VERSION`
olur. Maven `pom.xml` sürümünü betiklerden alır (`-Drevision=<VERSION>`), yani jar `calculator-app-1.1.0.jar` olur.

## 2. Platform simgeleri

| Simge | Anlamı | Nerede görürsünüz |
|---|---|---|
| `windows` | yerel Windows | `-windows.bat`, `reports/windows/`, `...-windows-x64-app.zip` |
| `linux` | yerel Linux **ve WSL** (WSL de Linux'tur: aynı `.sh` betikleri, Linux ikilileri) | `-linux.sh`, `reports/linux/`, `...-linux-x64-app.tar.gz` |
| `macos` | yalnız CI, yalnız uygulama ikilisi | `...-macos-arm64-app.tar.gz` |

Mimari (`x64`, `arm64`) yalnızca uygulama ikili adlarında geçer. `wsl` ve `win` simgeleri hiçbir dosya adında yer
almaz.

## 3. Betikler: aynı numara = aynı iş, platform = sonek

Her betik `NN-ad-windows.bat` ve `NN-ad-linux.sh` olarak vardır (WSL `.sh` çalıştırır).

| # | İş | Windows | Linux / WSL |
|---|---|---|---|
| 0 | Alt modülleri başlat (yalnız alt modülü olan şablonlarda; bu Java şablonunda yok) | - | - |
| 1 | Git kancalarını kur | `1-configure-git-hooks-windows.bat` | `1-configure-git-hooks-linux.sh` |
| 2 | `.gitignore` oluştur (yepyeni depo için tek seferlik) | `2-create-gitignore-windows.bat` | `2-create-gitignore-linux.sh` |
| 3 | Paket yöneticisini kur | `3-install-package-manager-windows.bat` | - (apt zaten var) |
| 4 | Tüm araçları kur | `4-install-tools-windows.bat` | `4-install-tools-linux.sh` |
| 5 | Kodu biçimlendir | `5-format-code-windows.bat` | `5-format-code-linux.sh` |
| 6 | **Hızlı**: derle + birim testleri | `6-build-and-test-windows.bat` | `6-build-and-test-linux.sh` |
| 7 | **Her şey**: + tüm raporlar, API belgeleri, iki site, `release/` klasörü | `7-build-all-windows.bat` | `7-build-all-linux.sh` |
| 8 | Uygulamayı çalıştır | `8-run-app-windows.bat` | `8-run-app-linux.sh` |
| 9 | Siteyi `http://localhost` üzerinde aç | `9-open-site-windows.bat` | `9-open-site-linux.sh` |
| 10 | GitHub CLI ile sürüm yayınla (önce `--dry-run`) | `10-release-windows.bat` | `10-release-linux.sh` |
| 11 | Üretilen her şeyi temizle | `11-clean-windows.bat` | `11-clean-linux.sh` |

Yardımcı betikler (elle çalıştırılmaz) `scripts/` klasöründedir ve aynı sonek kuralına uyar: `load-env-*`,
`detect-python-*`, `detect-genhtml-*`, `delete-desktop-ini-*`, `install-toolchain-linux.sh`. Platformdan bağımsız iki
yardımcı Python'dur: `scripts/assemble.py` (hazırlama, sıkıştırma, site sayfaları, `ASSETS.md`, `SHA256SUMS.txt`) ve
`scripts/check-links.py` (bağlantı denetleyicisi).

### Eski ad -> yeni ad

| Eski | Yeni |
|---|---|
| `1-configure-git-hooks.bat` / `.sh` | `1-configure-git-hooks-windows.bat` / `1-configure-git-hooks-linux.sh` |
| `2-create-git-ignore.bat` / `.sh` | `2-create-gitignore-windows.bat` / `2-create-gitignore-linux.sh` |
| `3-install-package-manager.bat` | `3-install-package-manager-windows.bat` |
| `3-install-package-manager.sh` | `4-install-tools-linux.sh` içine katıldı (`scripts/install-toolchain-linux.sh` çalışır) |
| `4-install-required-apps.bat` / `.sh` | `4-install-tools-windows.bat` / `4-install-tools-linux.sh` |
| `5-format-code.bat` / `.sh` | `5-format-code-windows.bat` / `5-format-code-linux.sh` |
| `7-build-app.bat` / `.sh` | `7-build-all-windows.bat` / `7-build-all-linux.sh` (hızlı kısım yeni `6-build-and-test-*`) |
| `8-run-app.bat` / `.sh` | `8-run-app-windows.bat` / `8-run-app-linux.sh` |
| `9-run-webpage.bat` / `.sh` | `9-open-site-windows.bat` / `9-open-site-linux.sh` |
| `10-release.bat` / `.sh` | `10-release-windows.bat` / `10-release-linux.sh` |
| `delete_desktop_ini.bat` / `.sh` | `scripts/delete-desktop-ini-windows.bat` / `scripts/delete-desktop-ini-linux.sh` |
| `init-submodules.bat`, `update-submodules.bat` | `docs/archive/legacy-scripts/` (bu şablonda alt modül yok) |
| `VERSION` dosyası | `project.env` |

## 4. Yerel klasörler (hepsi gitignore'da)

| Klasör | İçerik |
|---|---|
| `build/<platform>-<config>/` | derlenmiş jar, örn. `build/windows-release/` |
| `publish/<platform>-<arch>/` | çalıştırılabilir uygulama klasörü, örn. `publish/linux-x64/` (`run.bat` / `run.sh`) |
| `reports/<platform>/<tür>-<araç>/` | rapor başına bir klasör, örn. `reports/linux/coverage-jacoco/`, `reports/windows/tests-junit2html/` |
| `site/` | MkDocs sitesi (ana site) |
| `site-native/` | Maven sitesi (Fluido) |
| `release/` | her sürüm dosyası - GitHub sürümünün aldığı şeyin aynısı |

Maven kendi işini hâlâ `calculator-app/target/` içinde yapar (Eclipse ve tüm IDE'ler bunu bekler); betikler önemli
olanı yukarıdaki klasörlere kopyalar.

Rapor klasörleri (`<tür>-<araç>`): `tests-junit2html`, `coverage-jacoco`, `coverage-reportgenerator`,
`doccoverage-lcov`, `doccoverage-reportgenerator`, `api-doxygen`, `api-javadoc`. Windows ve Linux'un her biri kendi
takımını alır, çünkü sonuçlar ikisi arasında farklı olabilir (satır sonları, yollar, araç sürümleri).

## 5. Sürüm dosyaları (assets)

Kalıp: `<proje>-<sürüm>[-<platform>[-<mimari>]]-<içerik>[-<araç>].<uzantı>` (sürümde `v` yok).

| Dosya | Örnek |
|---|---|
| uygulama | `calculator-1.1.0-windows-x64-app.zip`, `calculator-1.1.0-linux-x64-app.tar.gz`, `calculator-1.1.0-macos-arm64-app.tar.gz` (CI) |
| testler | `calculator-1.1.0-windows-report-tests.zip`, `...-linux-report-tests.zip` |
| kapsama | `...-<platform>-report-coverage-reportgenerator.zip`, `...-<platform>-report-coverage-jacoco.zip` |
| dokümantasyon kapsaması | `...-<platform>-report-doccoverage-reportgenerator.zip`, `...-<platform>-report-doccoverage-lcov.zip` |
| API belgeleri | `...-<platform>-api-doxygen.zip`, `...-<platform>-api-javadoc.zip` |
| Maven sitesi | `calculator-1.1.0-site-maven.zip` (Checkstyle, PMD, CPD, SpotBugs, Surefire, JXR ile) |
| bağımsız | `calculator-1.1.0-source.zip`, `calculator-1.1.0-site.zip` (**iki** platformu içeren MkDocs sitesi), `ASSETS.md`, `SHA256SUMS.txt` |

Windows ikilileri ve tüm HTML için `.zip`; Linux/macOS ikilileri için `.tar.gz` (çalıştırma bitini korur). Yerel
`release/` klasörü ile GitHub sürümü **aynı adları** taşır. Yerel derleme kendi platformunuzun dosyalarını ve
bağımsız olanları içerir; `ASSETS.md` hangi platformun dosyalarının eksik olduğunu söyler (CI hepsini derler).

## 6. Site kuralları: neyin çerçevesi olur, neyin olmaz

Ana site **MkDocs Material**'dır: Ana sayfa, Guide (EN), Kılavuz (TR), Reports (Windows / Linux), API docs,
Downloads, Maven sitesi. Java ekosisteminin kendi sitesi (Maven + Fluido) de üretilir ve Pages'te `native/`
altında yayınlanır (yerelde `site-native/`).

**Kural:** yalnızca **site üretecinin dışında üretilmiş bağımsız HTML** `<iframe>` içine konur (ReportGenerator,
genhtml, junit2html, JaCoCo, Javadoc, Doxygen). **Kendi site gezinmesini taşıyan sayfa** - Maven sitesinin her
sayfası (proje bilgisi, Surefire, Checkstyle, PMD, CPD, SpotBugs, JXR) - **asla çerçevelenmez**; yeni sekmede kendi
sitesi olarak açılan bir bağlantıyla verilir.

Doğru - bağımsız rapor çerçevede (`docs/reports/linux/coverage-jacoco/index.md`):

```html
<iframe class="report-frame" src="html/index.html" title="JaCoCo coverage (linux)" loading="lazy"></iframe>
```

Yanlış - Maven sitesi sayfası çerçevede (site içinde site görürsünüz: iki menü, iki başlık, kaydırma çubuğu
içinde kaydırma çubuğu):

```html
<iframe src="../native/checkstyle.html"></iframe>   <!-- BUNU YAPMAYIN -->
```

Doğru - Maven sitesi sayfası, yeni sekmede açılan bağlantı olarak:

```html
<a href="../native/checkstyle.html" target="_blank" rel="noopener">Checkstyle (Maven sitesi)</a>
```

## 7. CI tek bakışta

| İş | Çalıştığı yer | Yaptığı |
|---|---|---|
| `windows` | `windows-latest` | `7-build-all-windows.bat --no-site`, `reports/windows` + kendi `release/` dosyalarını yükler |
| `linux` | `ubuntu-latest` | `7-build-all-linux.sh --no-site`, `reports/linux`, `site-native` + kendi `release/` dosyalarını yükler |
| `macos` | `macos-latest` | yalnız uygulamayı derler ve paketler (`...-macos-arm64-app.tar.gz`) |
| `site` | `ubuntu-latest` | tüm çıktıları birleştirir, MkDocs sitesini (iki platform) kurar + Maven sitesini `native/` altına koyar, bağlantıları denetler (yalnız **kendi** sayfalarımızdaki kırık bağlantılarda hata verir), `main`'e push'ta Pages'e yayınlar (özel depo kuralı: [sürümler](releases-tr.md)), `v*` etiketinde `ASSETS.md`, `SHA256SUMS.txt` ve siteye bağlantı veren notlarla her dosyayı yayınlar |
