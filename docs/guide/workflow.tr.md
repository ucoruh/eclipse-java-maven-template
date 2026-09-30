# Günlük çalışma ve raporlar

## Dal aç, commit et, push et

```bash
git checkout -b feature/checkout-book
# ... düzenle, test ekle ...
git add -A
git commit -m "Add LibraryCatalog.checkOut with overdue tracking"
git push -u origin feature/checkout-book
```

`pre-commit` kancası (`1-configure-git-hooks-*` kurar) hazırlanan her `.java`/`.c`/`.cpp`/`.h` dosyasında Astyle
çalıştırır; düzgün biçimlendiremezse ya da `.gitignore`/`README.md`/`Doxyfile` yoksa commit'i reddeder. Dal hazır
olunca `main`'e pull request açın; CI yeşil olunca birleştirin.

## Ne nerede çalışır

| Ne zaman | Ne çalışır | Çıktı nereye düşer |
|---|---|---|
| her `git commit` | Astyle biçim denetimi (`pre-commit` kancası) | yerinde, dosyalarınızda |
| siz, günde çok kez | `6-build-and-test-windows.bat` / `./6-build-and-test-linux.sh` (yaklaşık bir dakika): derle + JUnit testleri + jar + test raporu | `build/<platform>-release/`, `reports/<platform>/tests-junit2html/`, `publish/<platform>-<arch>/` |
| siz, push veya gösterimden önce | `7-build-all-windows.bat` / `./7-build-all-linux.sh`: her şey - kapsama (JaCoCo + ReportGenerator), Doxygen, Javadoc, dokümantasyon kapsaması (genhtml + ReportGenerator), Maven sitesi, MkDocs sitesi, `release/` | `reports/<platform>/`, `site/`, `site-native/`, `release/` (hepsi gitignore'da) |
| her push / PR | `.github/workflows/ci.yml`: `windows`, `linux`, `macos` işleri, sonra `site` (birleştirme + bağlantı denetimi) | GitHub Actions çalıştırması; birleşik site artefakttır |
| `main`'e push | aynısı, ayrıca `site` işi GitHub Pages'i yayınlar | `https://<sahip>.github.io/<depo>/` (özel depoda atlanır, bkz. [Sürümler](releases.md)) |
| `vX.Y.Z` etiketi | aynısı, ayrıca `site` işi her dosyayla GitHub Release'i yayınlar | deponun **Releases** sayfası |
| `10-release-*` (siz) | her şeyi yerelde derler ve `gh release create` çalıştırır | deponun **Releases** sayfası, Actions dakikası harcamadan |

## Raporları okumak

`9-open-site-windows.bat` / `./9-open-site-linux.sh` çalıştırın (siteyi http://localhost:8000/ adresinde sunar) ve
**Reports** altındaki **Which report is which?** sayfasından başlayın. Kısaca:

- **Birim testleri** (`tests-junit2html`): testler geçti mi, her biri neyi doğruladı.
- **Kapsama**: JaCoCo ve ReportGenerator aynı veriyi iki biçimde gösterir; ReportGenerator rozet ve geçmiş ekler.
- **Dokümantasyon kapsaması**: genel API'nizin ne kadarında dokümantasyon yorumu var - genhtml ve ReportGenerator, aynı veri.
- **API belgeleri**: Javadoc (Java'nın kendi aracı) ve Doxygen (C/C++ ve C# şablonlarının da kullandığı araç).
- **Maven sitesi** (kendi sekmesinde açılır): Checkstyle, PMD, CPD, SpotBugs, JXR, Surefire - bilgilendiricidir,
  derlemeyi asla durdurmaz.

Raporlar iki kez vardır - **Windows** ve **Linux** - çünkü sonuçlar farklı olabilir. Farklıysa ikisini de okuyun.

## HTML raporunu sitenizin içinde göstermek

Site MkDocs Material'dır. **Reports -> Windows / Linux** altındaki rapor sayfaları `scripts/assemble.py site` ile
(`7-build-all-*` çağırır) **üretilir**; bu bölüm böyle bir sayfanın ne olduğunu, kendi raporunuzu nasıl ekleyeceğinizi
ve nasıl deneyeceğinizi gösterir.

**Ne zaman iframe, ne zaman değil.** **Maven sitesi sayfası olmayan** her rapor, iki sitede de `<iframe>` içine konur:
JaCoCo, ReportGenerator, genhtml, junit2html, Javadoc, Test Javadoc, Doxygen, JXR Source Xref / Test Source Xref (C++
şablonunda OpenCppCoverage). Maven sitesinin kendi menüsüyle kendisinin ürettiği sayfa - Surefire, Checkstyle, PMD, CPD,
SpotBugs, proje bilgisi, bağımlılıklar, eklentiler, SCM - **asla çerçevelenmez** (site içinde site, iki menü, iki
başlık): yeni sekmede açılan bağlantı verin ([Adlandırma standardı](standard.md#6-site-kurallar-neyin-cercevesi-olur-neyin-olmaz)
sayfasındaki "doğru / yanlış" örneğine bakın). Maven native sitesinde çerçeveler `frames/` içindeki küçük sarmalayıcı
sayfalardır ve aynı `REPORTS` listesinden üretilir (`scripts/assemble.py prep`); yeni bir rapor tek kayıtla hem MkDocs
sayfasını **hem** Maven sarmalayıcısını alır.

**1. Sayfa.** Her rapor sayfası, ham HTML içeren küçük bir Markdown dosyasıdır; örn.
`docs/reports/linux/coverage-jacoco/index.en.md` / `index.tr.md` (üretilir - düzenlemeyin; `scripts/assemble.py` içindeki `report_page`
şablonunu düzenleyin):

```html
# Code coverage - JaCoCo - Linux

<div class="report-toolbar">
<a class="md-button md-button--primary" href="html/index.html" target="_blank" rel="noopener">Open in a new tab</a>
<a class="md-button" href="https://github.com/<sahip>/<depo>/releases/download/v1.1.0/calculator-1.1.0-linux-report-coverage-jacoco.zip">Download (zip)</a>
</div>

<p class="report-explainer">Tek cümle: rapor ne gösterir.</p>

<div class="report-frame-wrap">
<iframe class="report-frame" src="html/index.html" title="JaCoCo coverage (linux)" loading="lazy"></iframe>
</div>

<p class="report-fallback">Çerçeve boş kalırsa <a href="html/index.html">raporu doğrudan açın</a>.</p>
```

Ham rapor sayfanın yanına `html/` olarak kopyalanır; bu yüzden çerçevenin `html/index.html` yolu **göreli**dir ve hem
GitHub Pages'te (`/<depo>/reports/linux/coverage-jacoco/`) hem `http://localhost:8000/` adresinde çalışır.

**2. Yeni rapor eklemek.**

1. Aracınıza bağımsız HTML'i `reports/<platform>/<tür>-<araç>/` içine (örn. `reports/linux/mutation-pitest/`) yazdırın:
   hem `7-build-all-windows.bat` hem `7-build-all-linux.sh` içinde.
2. `scripts/assemble.py` başındaki `REPORTS` listesine bir kayıt ekleyin (klasör anahtarı, başlık, tek satırlık
   açıklama, giriş dosyası, dosya adı) ve Türkçe başlığını/metnini `TR_TITLE` / `TR_WHAT` içine. Böylece çerçeve sayfasını, `release/` içindeki zip'i, `ASSETS.md` satırını ve
   indirme tablosunu alırsınız.
3. Sayfayı `mkdocs.yml` `nav:` içinde Reports -> Windows ve Linux altına ekleyin.

**3. Yerelde deneyin.** `7-build-all-*` sonra `9-open-site-*`: site http ile 8000 portunda sunulur. Tarayıcılar
`file://` sayfasından `<iframe>` yüklemeyi reddeder; bu yüzden `site/index.html`'e çift tıklamak boş çerçeve gösterir -
her zaman `http://localhost:8000/` üzerinden gidin.

**Sık sorunlar.**

| Belirti | Neden / çözüm |
|---|---|
| Çerçeve boş, "Open in a new tab" çalışıyor | site `file://` ile açıldı; `9-open-site-*` kullanın |
| http üzerinden de boş | rapor klasörü üretilmedi ya da kopyalanmadı: `reports/<platform>/<tür>-<araç>/index.html` var mı bakın, `7-build-all-*` tekrar çalıştırın |
| Rapor için 404 | mutlak yol (`/html/...`); çerçeve yollarını göreli tutun - GitHub Pages `/<depo>/` altında sunar |
| "refused to connect" iletili boş çerçeve | araç `X-Frame-Options` gönderiyor; bağımsız dosya raporları göndermez, yani bir **sunucu** sayfasını çerçevelediniz - yeni sekmede açın |
| `mkdocs build --strict` eksik dosya uyarısı veriyor | `nav:` içinde yazılı bir sayfa üretilmedi; raporu `assemble.py` `REPORTS` listesine ekleyin |

## Kapsamayı yüksek tutmak

Anlamlı her değişiklikten sonra `6-build-and-test-*`, push'tan önce `7-build-all-*` çalıştırın; kapsama rozetlerine
(`assets/badge_linecoverage.svg` vb., `README.md`'nin başında da görünür) veya JaCoCo sayfasına bakın. %0 kapsamalı yeni bir
metodun testi yoktur - devam etmeden yazın (bkz. [from-topic.md](from-topic.md#4-once-testleri-yazin)).
