# Bu şablonu kullanın

## 1. Kendi deponuzu oluşturun

GitHub'da şablon deposunu açın ve **Use this template -> Create a new repository**'ye tıklayın. Bir ad seçin
(örn. `cen429-adiniz-proje`), **Private** bırakın (bu derste öğrenci depoları özeldir - bunun rapor/Pages için ne
anlama geldiği için bakınız [releases-tr.md](releases-tr.md)) ve oluşturun.

Fork **etmeyin** - "Use this template" size orijinaliyle paylaşılan geçmişi olmayan bir depo verir, kendi projeniz
için istediğiniz de tam olarak budur.

## 2. Clone edin

```bash
git clone https://github.com/<hesabiniz>/<depo-adiniz>.git
cd <depo-adiniz>
```

## 3. Git kancalarını yapılandırın (bir kez)

Windows:
```batch
1-configure-git-hooks.bat
```
Linux/WSL:
```bash
./1-configure-git-hooks.sh
```

Bu, `pre-commit`'i (staged Java/C/C++/C# dosyalarını Astyle ile otomatik biçimlendirir, `.gitignore`, `README.md`
veya `Doxyfile` eksikse commit'i reddeder) ve `pre-push`'u `.git/hooks/` içine kurar.

## 4. Araç zincirini kurun

Daha önce yapmadıysanız [install-tr.md](install-tr.md)'yi izleyin.

## 5. İlk derleme

Windows:
```batch
7-build-app.bat
```
Linux/WSL:
```bash
./7-build-app.sh
```

Her şeyi yapan tek betik budur: `mvn clean test package`, Doxygen, her iki kapsama-raporu ailesi (native JaCoCo +
ReportGenerator), her iki dokümantasyon-kapsama ailesi (native `genhtml` + ReportGenerator), Javadoc/JXR/
Checkstyle/PMD/SpotBugs raporları, tam `mvn site` ve her şeyi `release/` altında paketler. İlk çalıştırmada bir-iki
dakika sürer (Maven ve rapor araçları kendi önbelleklerini indirir), sonraki çalıştırmalarda hızlıdır. Konsol
çıktısını baştan sona okuyun - her adım yapmadan önce ne yapacağını yazdırır ve bir şey ters gittiği an bir
`[ERROR]` ve önerilen bir düzeltmeyle durur (düzeltme açık değilse bakınız
[troubleshooting-tr.md](troubleshooting-tr.md)).

Bir `[ERROR]` satırı olmadan biterse şunlara sahipsinizdir:
- çalıştırılabilir bir jar: `calculator-app/target/calculator-app-1.0-SNAPSHOT.jar`
- tam bir rapor sitesi: `calculator-app/target/site/index.html`
- bir release için paketlenmiş her şey: `release/*.tar.gz`

## 6. Çalıştırın ve siteyi açın

Windows:
```batch
8-run-app.bat 6 "*" 7
9-run-webpage.bat
```
Linux/WSL:
```bash
./8-run-app.sh 6 "*" 7
./9-run-webpage.sh
```

`9-run-webpage`, zaten derlenmiş statik siteyi (tüm raporlarıyla) yerel bir HTTP sunucusu üzerinden yayınlar ve
<http://localhost:8000/> adresini açar - çoğu sayfa için düz bir `file://` bağlantısı da işe yarardı, ama rapor
sayfaları bir `<iframe>` kullanır ve çoğu tarayıcı `file://`'dan çerçevelenmiş bir sayfayı yüklemeyi reddeder.
`--serve` geçirirseniz bunun yerine <http://localhost:9000/>'da, `src/site/*`'i anlık olarak yeniden derleyen canlı
bir Maven site sunucusu çalışır (`site.xml`'i veya `src/site/markdown/` altındaki markdown sayfalarını
düzenlerken kullanışlıdır, ama `7-build-app`'in kopyaladığı ekstra rapor klasörlerini içermez - sitenin tamamını
görmek için varsayılan modu kullanın).

## 7. Şimdi kendi projeniz yapın

Örnek `Calculator`'ı kendi proje konunuza çevirmek için [from-topic-tr.md](from-topic-tr.md) ile devam edin.
