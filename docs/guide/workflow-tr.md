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
| her push / PR | `.github/workflows/ci.yml`'in `build` işi: `mvn clean test package` | GitHub Actions "Checks" sekmesi; Surefire raporu yalnızca başarısız olursa artifact olarak yüklenir |
| her push / PR | `.github/workflows/ci.yml`'in `site` işi: tam rapor/site boru hattı (aşağıya bakın) | çalıştırmadaki indirilebilir `maven-site-preview` artifact'ı, böylece bir PR incelemesi siteyi önizleyebilir |
| `7-build-app.bat` / `.sh` (siz çalıştırdığınızda, istediğiniz zaman) | tam derleme: testler, JaCoCo, ReportGenerator (kapsama + rozet), Doxygen, coverxygen, `genhtml`, ReportGenerator (doküman kapsama + rozet), `mvn site`, rapor başına `downloads/*.zip`, `release/*.tar.gz` | `calculator-app/target/site/`, `release/` (ikisi de gitignore'da - commit edilmez) |
| `main`'e her push, veya `.github/workflows/pages.yml`'in elle tetiklenmesi | aynı tam boru hattı, `gh-pages` dalına yayımlanır (özel bir depoda `PAGES_ON_PRIVATE` depo değişkeni `true` olmadıkça bir açıklamayla atlanır) | `https://<hesap>.github.io/<depo>/` |
| bir `vX.Y.Z` etiket push'u, veya `.github/workflows/release.yml`'ın bir `version` girdisiyle elle tetiklenmesi | aynı tam boru hattı, ardından her rapor kendi adıyla ekli bir GitHub Release | deponun **Releases** sayfası |
| `10-release.bat` / `.sh` (siz çalıştırdığınızda) | aynı tam boru hattı, `release/site.zip` olarak sıkıştırılmış, `gh release create` ile yayımlanmış | deponun **Releases** sayfası, hiç Actions dakikası harcamadan |

CI'nin `build` işi kasıtlı olarak yalındır: her push'ta yalnızca derler ve testleri çalıştırır, böylece hızlı kalır
ve (özel bir depoda sınırlı olan) Actions dakikalarınızı tüketmez. CI'nin `site` işi, `pages.yml` ve `release.yml`
hepsi aynı daha ağır boru hattını çalıştırır (Doxygen, ReportGenerator, coverxygen/`genhtml`, `mvn site`) - `site`
onu bir önizleme artifact'ı olarak yükler, `pages.yml` canlı yayımlar, `release.yml` bir release'e ekler. Her
birinin özel depo/GitHub Free etkileri için bakınız [releases-tr.md](releases-tr.md).

## Raporları okumak

`9-run-webpage.bat`/`.sh`'yi çalıştırın (siteyi yerel bir HTTP sunucusu üzerinden yayınlar ve açar - nedeni için
aşağıya bakın) ve sol menüdeki **Which report is which?**'ten başlayın - sitedeki her raporu ve hangi
klasör/dosyanın onu ürettiğini açıklar. Kısaca:
- **Unit Tests -> Surefire Report**: testler geçti mi ve her biri neyi doğruladı.
- **Code Coverage -> JaCoCo / ReportGenerator**: aynı temel veri, iki farklı görünüm; ReportGenerator ayrıca size
  rozetler ve bir geçmiş (history) trendi verir.
- **Documentation Coverage -> Coverxygen (genhtml / ReportGenerator)**: genel API'nizin ne kadarında Javadoc yorumu
  var - yine aynı veri, iki görünüm.
- **API Docs -> Javadoc / Doxygen**: gerçek API referansı, Java-native biçimde ve diğer iki ders şablonunun da
  kullandığı diller-arası tutarlı biçimde.
- **Code Quality -> Checkstyle / PMD / CPD / SpotBugs**: stil, tasarım kokuları, kopya-yapıştır, hata desenleri -
  bilgilendirme amaçlıdır, derlemeyi durdurmazlar.

Bunların her birinin sitenin **içinde**, **Reports** menüsü altında kendi sayfası da vardır - raporu çerçeveli,
kaydırılabilir bir görüntüleyicide, "Open in a new tab" ve "Download (zip)" düğmeleriyle gösterir; bunun nasıl
kurulduğu (kendi raporunuzu eklemek isterseniz) için sıradaki bölüme bakın.

## Bir HTML raporunu sitenizin içinde göstermek

**Reports** menüsündeki her rapor sayfası (derlendikten sonra `calculator-app/src/site/markdown/reports/*.html`)
Maven'in otomatik ürettiği bir şey değil, elle yazılmış küçük bir sayfadır. İşte bunun nasıl kurulduğu - örnek
olarak JaCoCo rapor sayfası - ve yeni bir tane nasıl eklenir.

**Ne zaman iframe, ne zaman değil.** Bir raporu yalnızca site üreticisinin dışındaki bir aracın ürettiği *bağımsız*
bir HTML raporuysa iframe içine koyun: JaCoCo, ReportGenerator, genhtml (coverxygen), Javadoc, Doxygen. Maven
site'ın kendi ürettiği raporlar - Surefire raporu, Checkstyle, PMD, CPD, SpotBugs, JXR, proje bilgisi sayfaları - zaten
bu sitenin sayfalarıdır ve aynı menüye sahiptir. Onları iframe'e koymak sitenin içinde siteyi gösterir (iki menü, iki
başlık). Bunları `site.xml` içinden doğrudan bağlayın, örneğin
`<item name="Code Quality: Checkstyle" href="checkstyle.html" />`.

**1. Markdown kaynağı** - `calculator-app/src/site/markdown/reports/jacoco.md`:

```markdown
# Code Coverage: JaCoCo (native)

<div class="report-toolbar">
<a class="btn" href="../jacoco/index.html" target="_blank" rel="noopener">Open in a new tab</a>
<a class="btn" href="../downloads/jacoco.zip">Download (zip)</a>
</div>

<p class="report-explainer">Tek cümle: bu rapor ne gösteriyor ve neden önemli.</p>

<div class="report-frame-wrap">
<iframe class="report-frame" src="../jacoco/index.html" title="JaCoCo coverage report" loading="lazy"></iframe>
</div>

<p class="report-fallback">Yukarıdaki rapor yüklenmezse (bazı tarayıcılar çerçeveli sayfaları engeller), <a
href="../jacoco/index.html">doğrudan açın</a>.</p>
```

Doxia'nın Markdown ayrıştırıcısı, boş satırla ayrılmış bağımsız HTML bloklarını olduğu gibi geçirir - bu yüzden
`<div>`/`<iframe>` işaretlemesi üretilen sayfaya değişmeden geçer. Yollar **`reports/<ad>.html`'e göre görelidir**,
yani site kökünün bir alt seviyesinde; `calculator-app/target/site/jacoco/index.html`'de yaşayan bir rapor buradan
`../jacoco/index.html` olur - aynı göreli yol hem yerelde hem GitHub Pages'te değişmeden çalışır
(`/<depo>/reports/jacoco.html` ve `/<depo>/jacoco/index.html` yine bir seviye arayla dururlar).
`.report-toolbar`, `.report-frame-wrap`, `.report-frame` vb. sınıflar her rapor sayfası için tek seferde,
`calculator-app/src/site/resources/css/site.css`'te biçimlendirilir.

**2. Menü girdisi** - `calculator-app/src/site/site.xml`'deki `Reports` `<menu>`'süne bir satır ekleyin:

```xml
<item name="Coverage: JaCoCo (native)" href="reports/jacoco.html" />
```

**3. İndirme düğmesinin hedefi** - `../downloads/jacoco.zip`, `7-build-app.bat`/`.sh` tarafından üretilir (başlığı
"Bundle each report into ... downloads/*.zip" olan adım): klasör biçimli bir rapor (JaCoCo, ReportGenerator,
coverxygen, Javadoc, Doxygen) olduğu gibi zip'lenir; site kökünde tek dosya olarak üretilen bir rapor (Surefire,
Checkstyle, PMD, CPD, SpotBugs) önce sitenin ortak `css/`/`images/` klasörleriyle birlikte paketlenir, böylece
zip'ten çıkarılıp tek başına açıldığında da doğru görünür. Gerçekten yeni bir rapor eklerseniz, mevcutların yanına
bir `tar -a -cf` (Windows) / `zip -rq` (Linux, `zip_dir` yardımcı fonksiyonuyla) satırı daha ekleyin.

**4. Yerelde test etmek** - `9-run-webpage.bat`/`.sh` (argümansız) `calculator-app/target/site/`'i
`python -m http.server` ile yayınlar ve açılacak URL'yi yazdırır. Bu adım isteğe bağlı değildir: tarayıcılar
güvenlik nedeniyle bir `<iframe>`'in `file://` sayfasından yüklenmesini engeller, o yüzden `index.html`'e çift
tıklamak her rapor sayfasında boş bir çerçeve gösterir - çerçevelerin yüklenmesi için `http://localhost:8000/`
(ya da verdiğiniz port) üzerinden gitmelisiniz.

**Sık karşılaşılan sorunlar**:
- **Çerçeve boş, "Open in a new tab" çalışıyor** - siteyi `9-run-webpage` yerine `file://` ile açtınız. Yerel HTTP
  sunucusunu kullanın.
- **`http://` üzerinden bile çerçeve boş** - rapor klasörü gerçekte üretilmemiş/kopyalanmamış. 
  `calculator-app/target/site/<klasör>/index.html`'in var olup olmadığını kontrol edin; yoksa `7-build-app`'i
  yeniden çalıştırın ve hangi adımın başarısız olduğunu konsol çıktısından okuyun.
- **Rapor için 404** - eski, mutlak ya da `/depo`-önekli bir yol. Yolları göreli tutun (`../klasör/...`), mutlak
  değil (`/klasör/...`) - GitHub Pages siteyi bir `/<depo>/` alt yolundan sunar, bu yüzden yerelde çalışan mutlak
  bir yol orada bozulur.
- **"Download (zip)" 404 veriyor** - zip, yalnız `mvn site` tarafından değil `7-build-app`'in paketleme adımı
  tarafından üretilir; `7-build-app`'i yeniden çalıştırın (yalnız `mvn site` çalıştırmak `target/site/downloads/`'ı
  oluşturmaz).

## Kapsamayı yüksek tutmak

Her anlamlı değişiklikten sonra `7-build-app`'i çalıştırın ve kapsama rozetlerine (`assets/badge_linecoverage.svg`
vb., `README.md`'nin üstünde de gösterilir) ya da JaCoCo raporuna göz atın. Yeni bir metodun kapsaması %0 ise henüz
testi yok demektir - devam etmeden önce bir tane yazın (bakınız
[from-topic-tr.md](from-topic-tr.md#4-once-testleri-yazin)).
