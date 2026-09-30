# Şablonu kullanın

## 1. Şablondan kendi ÖZEL deponuzu oluşturun (fork değil)

GitHub'da şablon deposunu açın, yeşil **Use this template** düğmesine (sağ üstte, **Code**'un yanında) -> **Create a
new repository**'ye tıklayın. **Owner** olarak hesabınızı, **Repository name** olarak bir ad (örn.
`cen207-adiniz-project`) seçin, **Private**'ı işaretleyin ve **Create repository**'ye tıklayın.

Fork **etmeyin**: herkese açık bir deponun fork'u **özel yapılamaz**, "Use this template" ile oluşturulan depo
yapılabilir - ve bu derste öğrenci depoları özeldir (raporlar ve Pages için anlamı
[Sürümler ve özel depolar](releases.md), yerel gösterim için
[GitHub Pages olmadan projenizi gösterin](showcase.md) sayfasındadır).

Sonra görmesi gerekenleri ekleyin: **Settings -> Collaborators -> Add people** -> eğitmen `ucoruh` ve takım
arkadaşlarınız (daveti kabul etmeleri gerekir).

## 2. Klonlayın

```bash
git clone https://github.com/<hesabiniz>/<depo-adiniz>.git
cd <depo-adiniz>
```
Bu şablonda alt modül yoktur (`0-init-submodules` betiği yalnız alt modülü olan şablonlarda bulunur).

## 3. Git kancalarını yapılandırın (bir kez)

Windows: `1-configure-git-hooks-windows.bat`  -  Linux/WSL: `./1-configure-git-hooks-linux.sh`

Bu, `pre-commit` (hazırlanan Java/C/C++/C# dosyalarını Astyle ile biçimlendirir; `.gitignore`, `README.md` veya
`Doxyfile` yoksa commit'i reddeder) ve `pre-push` kancalarını `.git/hooks/` içine kurar.

## 4. Araç zincirini kurun

Henüz yapmadıysanız [install.md](install.md) sayfasını izleyin (`4-install-tools-windows.bat` /
`./4-install-tools-linux.sh`).

## 5. Projenizi `project.env` içinde adlandırın

```text
PROJECT_NAME=calculator
VERSION=1.1.0
GITHUB_REPO=<hesabiniz>/<depo-adiniz>
```
Her betik ve CI iş akışı bu dosyayı okur: dosya adları (`<PROJECT_NAME>-<VERSION>-...`), sürüm etiketi (`v<VERSION>`) ve
site bağlantıları buradan gelir. Bkz. [Adlandırma standardı](standard.md).

## 6. İlk derleme

Hızlı deneme (yaklaşık bir dakika): derle + birim testleri + çalıştırılabilir uygulama.

Windows: `6-build-and-test-windows.bat`  -  Linux/WSL: `./6-build-and-test-linux.sh`

Çıktının beklenen sonu:
```text
Build and tests OK.
  jar:      build\windows-release\
  app:      publish\windows-x64\  (run.bat)  and  release\
  tests:    reports\windows\tests-junit2html\index.html
```

Her şey (testler, iki araç ailesiyle kapsama, API belgeleri, dokümantasyon kapsaması, iki site, `release/` klasörü):

Windows: `7-build-all-windows.bat`  -  Linux/WSL: `./7-build-all-linux.sh`

İlk çalıştırmada birkaç dakika sürer (Maven ve rapor araçları önbelleklerini indirir). Konsol çıktısını baştan okuyun:
her adım `[n/9]` diye numaralıdır ve bir şey ters gidince `[ERROR]` satırı ve önerilen çözümle durur
([troubleshooting.md](troubleshooting.md)). `[ERROR]` olmadan biterse şunlara sahipsiniz:

- çalıştırılabilir jar: `build/<platform>-release/calculator-app-<VERSION>.jar` ve uygulama klasörü `publish/<platform>-<arch>/`
- her rapor: `reports/<platform>/<tür>-<araç>/`
- MkDocs sitesi: `site/index.html`, Maven sitesi: `site-native/index.html`
- her sürüm dosyası: `release/` (`ASSETS.md` ve `SHA256SUMS.txt` ile)

## 7. Çalıştırın ve siteyi açın

Windows:
```batch
8-run-app-windows.bat 6 "*" 7
9-open-site-windows.bat
```
Linux/WSL:
```bash
./8-run-app-linux.sh 6 "*" 7
./9-open-site-linux.sh
```
Beklenen: `6 * 7 = 42` (veya benzeri), sonra tarayıcı <http://localhost:8000/> adresini açar. Site http ile sunulur çünkü
rapor sayfaları çerçeve kullanır ve tarayıcılar `file://` sayfalarının çerçevelerini engeller. Seçenekler:
`9-open-site-* --maven` Maven sitesini tek başına sunar, `--edit` belge yazarken canlı yenilenen MkDocs sunucusunu
başlatır, bir sayı başka port seçer (`9-open-site-windows.bat 8080`).

## 8. Şimdi kendi projeniz yapın

`Calculator` örneğini kendi proje konunuza çevirmek için [from-topic.md](from-topic.md) ile devam edin.
Göstermeye hazır olunca: [GitHub Pages olmadan projenizi gösterin](showcase.md).
