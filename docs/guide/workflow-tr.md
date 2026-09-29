# Günlük iş akışı

## Branch, commit, push

```bash
git checkout -b feature/checkout-book
# ... düzenle, test ekle ...
git add -A
git commit -m "Add LibraryCatalog.checkOut with overdue tracking"
git push -u origin feature/checkout-book
```

`pre-commit` kancası (`1-configure-git-hooks` ile kurulur) her staged `.java`/`.c`/`.cpp`/`.h` dosyasında Astyle
çalıştırır ve temiz biçimlendiremezse ya da `.gitignore`/`README.md`/`Doxyfile` eksikse commit'i reddeder. Branch
hazır olduğunda `main`'e bir pull request açın; CI yeşil olunca merge edin.

## Ne nerede çalışır

| Ne zaman | Ne çalışır | Çıktı nereye gider |
|---|---|---|
| her `git commit` | Astyle biçimlendirme kontrolü (`pre-commit` kancası) | yerinde, dosyalarınız üzerinde |
| her push / PR | `.github/workflows/ci.yml`: `mvn clean test package` | GitHub Actions "Checks" sekmesi; Surefire raporu yalnızca başarısız olursa artifact olarak yüklenir |
| `7-build-app.bat` / `.sh` (siz çalıştırdığınızda, istediğiniz zaman) | tam derleme: testler, JaCoCo, ReportGenerator (kapsama), Doxygen, coverxygen, `genhtml`, ReportGenerator (doküman kapsama), `mvn site`, `release/*.tar.gz` | `calculator-app/target/site/`, `release/` (ikisi de gitignore'da - commit edilmez) |
| `.github/workflows/release.yml`'ın bir `vX.Y.Z` etiket push'u veya elle tetiklenmesi | `7-build-app.sh` ile aynı tam boru hattı, ardından her rapor ekli bir GitHub Release | deponun **Releases** sayfası |
| `10-release.bat` / `.sh` (siz çalıştırdığınızda) | aynı tam boru hattı, `release/site.zip` olarak sıkıştırılmış, `gh release create` ile yayımlanmış | deponun **Releases** sayfası, hiç Actions dakikası harcamadan |

CI (`ci.yml`) kasıtlı olarak yalındır: her push'ta yalnızca derler ve testleri çalıştırır, böylece hızlı kalır ve
(özel bir depoda sınırlı olan) Actions dakikalarınızı tüketmez. Tam rapor/site/release boru hattı yalnızca
gerçekten bir release istediğinizde çalışır - bakınız [releases-tr.md](releases-tr.md).

## Raporları okumak

`calculator-app/target/site/index.html`'i açın (`9-run-webpage.bat`/`.sh` ile) ve sol menüdeki **Which report is
which?**'ten başlayın - sitedeki her raporu ve hangi klasör/dosyanın onu ürettiğini açıklar. Kısaca:
- **Unit Tests -> Surefire Report**: testler geçti mi ve her biri neyi doğruladı.
- **Code Coverage -> JaCoCo / ReportGenerator**: aynı temel veri, iki farklı görünüm; ReportGenerator ayrıca size
  rozetler ve bir geçmiş (history) trendi verir.
- **Documentation Coverage -> Coverxygen (genhtml / ReportGenerator)**: genel API'nizin ne kadarında Javadoc yorumu
  var - yine aynı veri, iki görünüm.
- **API Docs -> Javadoc / Doxygen**: gerçek API referansı, Java-native biçimde ve diğer iki ders şablonunun da
  kullandığı diller-arası tutarlı biçimde.
- **Code Quality -> Checkstyle / PMD / CPD / SpotBugs**: stil, tasarım kokuları, kopya-yapıştır, hata desenleri -
  bilgilendirme amaçlıdır, derlemeyi durdurmazlar.

## Kapsamayı yüksek tutmak

Her anlamlı değişiklikten sonra `7-build-app`'i çalıştırın ve kapsama rozetlerine (`assets/badge_linecoverage.svg`
vb., `README.md`'nin üstünde de gösterilir) ya da JaCoCo raporuna göz atın. Yeni bir metodun kapsaması %0 ise henüz
testi yok demektir - devam etmeden önce bir tane yazın (bakınız
[from-topic-tr.md](from-topic-tr.md#4-once-testleri-yazin)).
