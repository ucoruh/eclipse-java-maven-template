# Sürümler ve özel depolar

Ders deponuz **özeldir (private)** ve çoğu öğrencinin düz bir **GitHub Free** hesabı vardır. Bu sayfa bunun neye izin
verip neye vermediğini ve bu şablonun boşlukları nasıl kapattığını anlatır. Proje sunumu için adım adım tarif
[GitHub Pages olmadan projenizi gösterin](showcase.md) sayfasındadır.

## Free ve Pro'da ne çalışır (GitHub belgelerinden olgular)

| Özellik | GitHub Free (özel depo) | GitHub Pro / Team (veya Pro veren ücretsiz Student Developer Pack) |
|---|---|---|
| **Sürümler** (etiket + eklenmiş dosyalar, dosya başına en çok 2 GiB, en çok 1000 dosya) | **Çalışır.** Sizin ve eklediğiniz ortak çalışanların görebildiği. | Aynı. |
| **GitHub Pages** (canlı `https://<kullanıcı>.github.io/<depo>/` sitesi) | **Özel depoda çalışmaz.** | **Çalışır**, depoda Pages açıldıktan sonra. |
| **GitHub Actions dakikaları** | ayda 2.000 dk, 500 MB artefakt alanı | ayda 3.000 dk, 1 GB artefakt alanı |

Pratik sonuç: özel bir Free depoda site **yerelde** gösterilir (`7-build-all-*` + `9-open-site-*`) ve **Release**
içinde `...-site.zip` olarak teslim edilir. Şablon deposunun kendisi herkese açıktır; sitesi
<https://ucoruh.github.io/eclipse-java-maven-template/> adresinde canlıdır.

## Sürüm dosyaları (yerel klasör = GitHub sürümü, birebir)

`7-build-all-<platform>` `release/` klasörünü doldurur; `10-release-<platform>` ve CI iş akışı **tam olarak bu
dosyaları** ekler. Adlar `<proje>-<sürüm>[-<platform>[-<mimari>]]-<içerik>[-<araç>].<uzantı>` kalıbındadır
([Adlandırma standardı](standard.md)); `calculator` 1.1.0 için:

| Dosya | Nedir |
|---|---|
| `calculator-1.1.0-windows-x64-app.zip` | Windows için çalıştırılabilir uygulama (jar + `run.bat`) |
| `calculator-1.1.0-linux-x64-app.tar.gz` | Linux ve WSL için aynısı (jar + `run.sh`, çalıştırma bitini korur) |
| `calculator-1.1.0-macos-arm64-app.tar.gz` | macOS için aynısı (yalnız CI üretir) |
| `calculator-1.1.0-<platform>-report-tests.zip` | birim test raporu (junit2html) + ham JUnit XML |
| `calculator-1.1.0-<platform>-report-coverage-reportgenerator.zip` / `-report-coverage-jacoco.zip` | kod kapsaması, iki araç ailesi |
| `calculator-1.1.0-<platform>-report-doccoverage-reportgenerator.zip` / `-report-doccoverage-lcov.zip` | dokümantasyon kapsaması, iki aile |
| `calculator-1.1.0-<platform>-api-doxygen.zip` / `-api-javadoc.zip` | API belgeleri |
| `calculator-1.1.0-site-maven.zip` | Maven sitesi (Checkstyle, PMD, CPD, SpotBugs, Surefire, JXR) |
| `calculator-1.1.0-site.zip` | iki platformun raporlarıyla MkDocs sitesi |
| `calculator-1.1.0-source.zip` | bu kayıttaki kaynak |
| `ASSETS.md`, `SHA256SUMS.txt` | yukarıdakilerin site bağlantılı tablosu; sağlama toplamları |

`<platform>` `windows` veya `linux`'tur. Yerel derleme **bir** platformun dosyalarını ve bağımsız olanları içerir -
`ASSETS.md` eksikleri listeler; CI her platformu derler.

## Yine de GitHub Pages almak: Student Developer Pack

1. <https://education.github.com/pack> adresine gidip **üniversite e-posta adresinizle** başvurun.
2. Kanıt istenirse öğrenci kimliği fotoğrafı veya öğrenci belgesi genelde yeterlidir.
3. Onay dakikalar ile günler arası sürer - beklemeyin; yerel gösterim ve sürüm yeterlidir.
4. Onaylanınca hesabınız GitHub Pro olur. Deponuzda: **Settings -> Pages -> Source: Deploy from a branch ->
   `gh-pages`**. CI iş akışı ilk yayınında bu dalı oluşturur.
5. Özel depoda yayına izin verin: **Settings -> Secrets and variables -> Actions -> Variables -> New repository
   variable**, ad `PAGES_ON_PRIVATE`, değer `true`. Bu olmadan iş akışı özel depoda Pages yayınını **atlar** ve nedenini
   bir bildirimde ve çalıştırma özetinde söyler (bu mesaj [GitHub Pages olmadan projenizi gösterin](showcase.md)
   sayfasına bağlanır) - bilerek: Free özel depo çalışamayacak bir yayın için dakika harcamasın.
6. `main`'e push edin; site bir iki dakika sonra `https://<kullanıcı-adınız>.github.io/<depo-adınız>/` adresinde canlıdır.

## Eğitmeni ortak çalışan olarak ekleyin

**Settings -> Collaborators -> Add people**, `ucoruh`'u ekleyin, davetin kabul edilmesini bekleyin. Bu olmadan
Sürümleriniz (ve özel depodaki her şey) eğitmene görünmez.

## GitHub CLI (`gh`) kurulumu ve oturum açma

Windows: `where gh` - yoksa `choco install gh -y` (`4-install-tools-windows.bat` de yapar).
Linux/WSL: `gh --version` - yoksa `4-install-tools-linux.sh` kurar.

Makine başına bir kez:
```bash
gh auth login
```
**GitHub.com -> HTTPS -> Login with a web browser** seçin, tek kullanımlık kodu tarayıcı sekmesine yazın. Doğrulayın:
```bash
gh auth status
```
Beklenen: `Logged in to github.com account <kullanıcı-adınız>`.

## Kendi makinenizden sürüm yayınlamak

1. `project.env` içinde `VERSION=1.2.0` yapın, commit edin.
2. Önce deneme - her şeyi derler ve yayınlayacağını yalnızca *yazdırır*:
   ```batch
   10-release-windows.bat --dry-run
   ```
3. Yayınlayın:
   ```batch
   10-release-windows.bat
   ```
   (Linux/WSL'de `./10-release-linux.sh`.) Betik kirli çalışma ağacını reddeder, `gh auth status` denetler,
   `7-build-all-*` çalıştırır, sürüm notlarını yazar ve
   `gh release create v<VERSION> release/* --title ... --notes-file build/release-notes.md` çalıştırır. Actions dakikası
   harcanmaz.

## CI iş akışı (`.github/workflows/ci.yml`)

Tek iş akışı, dört iş ([Adlandırma standardı](standard.md#7-ci-tek-bakista)):

| Tetikleyici | Ne olur |
|---|---|
| herhangi bir dala push / pull request | `windows`, `linux`, `macos` işleri derler, test eder, rapor üretir; `site` bunları birleştirip siteyi kurar (artefakt olarak yüklenir) |
| `main`'e push | aynısı, ayrıca `site` işi **GitHub Pages'i yayınlar** (`gh-pages` dalı) |
| `v*` etiketi push'u (örn. `v1.1.0`; `project.env` ile aynı olmalı) | aynısı, ayrıca `site` işi yukarıdaki her dosyayla **GitHub Release'i yayınlar** |
| elle çalıştırma (**Actions -> CI -> Run workflow**) | `main`'e push ile aynı; *release* kutusunu işaretlerseniz `v<VERSION>` de yayınlanır |

**Maliyet:** tam bir çalıştırma dört işte toplam kabaca 12-20 Actions dakikasıdır (özel depolarda Windows dakikası
iki, macOS on kat sayılır); herkese açık şablonda küçük, ama özel Free depoda (ayda 2.000 dk) bilmeye değer: özellik
dallarına özgürce push edin, yalnızca sürüm çıkarırken etiketleyin. Artefaktlar 7 gün saklanır.

**Özel depo kuralı:** iş akışı `github.event.repository.private` değerini algılar. Özel depoda `PAGES_ON_PRIVATE`
deposu değişkeni `true` değilse Pages yayını atlanır; atlama bir `::notice` ek açıklamasında ve `$GITHUB_STEP_SUMMARY`
içinde açıklanır ve [GitHub Pages olmadan projenizi gösterin](showcase.md) sayfasına bağlanır. Sürümler her zaman
çalışır.

## Sorun giderme {#troubleshooting}

| Belirti | Çözüm |
|---|---|
| `10-release-*` "gh is not logged in" ile duruyor | `gh auth login`, sonra `gh auth status`. |
| `gh release create` `HTTP 404` veriyor | `gh` yanlış hesapta oturum açmış ya da uzak depo yanlış. `gh repo view` deponuzu yazdırmalı. |
| `gh release create` `HTTP 403` veriyor | `gh`'nin kullandığı hesabın bu depoya yazma erişimi yok (sahip veya yazma yetkili ortak çalışan). |
| `gh release create` etiket zaten var diyor | `project.env` içinde `VERSION`'ı yükseltin (etiket asla yeniden kullanılmaz), commit edin, tekrar çalıştırın. |
| Eğitmen sürümünüzü göremiyor | `ucoruh`'u ortak çalışan ekleyin (yukarıda) ve davetin kabul edildiğinden emin olun. |
| Bir dosya çok büyük | GitHub sınırı dosya başına 2 GiB; `target/` veya üretilmiş klasörleri arşive katmadığınızdan emin olun. |
| CI: *tag v1.2.0 does not match project.env* | `project.env`'i `VERSION=1.2.0` yapın ve o commit'i etiketleyin. |
| Sürüm başarılı ama `...-site.zip` boş rapor çerçeveleri gösteriyor | tamamen açın ve **sunun** (`python -m http.server --directory site`); çerçeveler `file://`'dan yüklenmez. |
