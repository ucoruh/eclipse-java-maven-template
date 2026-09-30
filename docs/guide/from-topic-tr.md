# Proje konusundan kendi projenize

Bu sayfa `Calculator` örneğini gerçek bir ders projesine dönüştürmeyi, somut bir örnek konuyla anlatır:
**"Kütüphane Kitap Takip Sistemi"** (küçük bir kütüphane kataloğu + ödünç takibi - ders proje kılavuzundan seçtiğiniz
konuyu buraya koyun, adımlar aynı).

## Kontrol listesi

- [ ] `project.env` içine adınızı yazın (`PROJECT_NAME`, `VERSION`, `GITHUB_REPO`) - proje kimliğinin TEK yeri
- [ ] Maven `groupId`'yi ve Java paketini yeniden adlandırın
- [ ] Kaynak klasörlerini yeni pakete uyacak şekilde yeniden adlandırın
- [ ] `Calculator` / `CalculatorApp`'i kendi alan (domain) sınıflarınızla değiştirin
- [ ] `pom.xml`'in `<name>`/`<description>`/`<url>`/shade `mainClass`'ını güncelleyin
- [ ] `Doxyfile`'ın `PROJECT_NAME`/`PROJECT_BRIEF`/`INPUT`'unu güncelleyin
- [ ] `calculator-app/src/site/site.xml`'in banner/bağlantılarını güncelleyin (ya da olduğu gibi bırakın - geneldir)
- [ ] Her yeni modül için **önce** test yazın (normal, sınır, geçersiz girdi - aşağıya bakın)
- [ ] Her değişiklikten sonra `6-build-and-test-*` (ve push'tan önce `7-build-all-*`) çalıştırın, kapsama rozetlerini/raporlarını kontrol edin
- [ ] `README.md`'nin başlığını ve açıklamasını güncelleyin
- [ ] Erken ve sık commit edin (bakınız [workflow-tr.md](workflow-tr.md))

## 1. Projeyi ve Maven koordinatlarını adlandırın

Önce depo kökündeki `project.env` - her betik, sürüm dosyası adları ve site onu okur:

```text
PROJECT_NAME=librarytracker
VERSION=0.1.0
GITHUB_REPO=<hesabiniz>/<depo-adiniz>
```

Dosyalar böylece `librarytracker-0.1.0-windows-x64-app.zip` vb. olur ([Adlandırma standardı](standard-tr.md)).

Sonra `calculator-app/pom.xml`:

`calculator-app/pom.xml` içinde:

```xml
<groupId>com.ucoruh.librarytracker</groupId>
<artifactId>library-tracker-app</artifactId>
<name>library-tracker-app</name>
<description>Kütüphane Kitap Takip Sistemi - dönem projesi</description>
```

Shade eklentisinin `mainClass`'ı yeni giriş noktası sınıfınızı göstermeli (adım 3):

```xml
<mainClass>com.ucoruh.librarytracker.LibraryTrackerApp</mainClass>
```

**En basit ve güvenli yol: modül klasörünü ve `artifactId`'yi `calculator-app` olarak bırakın** - betikler, `Doxyfile`,
`mkdocs.yml` ve CI o klasöre başvurur; kullanıcılarınızın gördüğü *adlar* (dosyalar, site, uygulama arşivindeki jar)
`artifactId`'den değil `PROJECT_NAME`'den gelir. Yalnızca `groupId`, `<name>`, `<description>` ve yukarıdaki
`<mainClass>`'ı değiştirin. (Klasörü de yeniden adlandırmakta ısrar ederseniz, depoda `calculator-app` arayın ve
betiklerdeki, `Doxyfile`, `mkdocs.yml`, `.github/workflows/ci.yml` ve `.gitignore` içindeki her eşleşmeyi değiştirin.)

## 2. Paketi ve klasörleri yeniden adlandırın

```bash
# depo kökünden
git mv calculator-app/src/main/java/com/ucoruh/calculator calculator-app/src/main/java/com/ucoruh/librarytracker
git mv calculator-app/src/test/java/com/ucoruh/calculator calculator-app/src/test/java/com/ucoruh/librarytracker
```

Ardından taşıdığınız her `.java` dosyasının başındaki `package com.ucoruh.calculator;` satırını
`package com.ucoruh.librarytracker;` yapın ve başka yerlerdeki her `import com.ucoruh.calculator....`'u güncelleyin.

## 3. Örnek sınıfları kendi alanınızla değiştirin

Şablonun ayrımı kasıtlıdır ve yapmanız gerekeni yansıtır:
- **kütüphane sınıfları** (`Calculator`) gerçek mantığı taşır, düzdür, yazdırmak yerine değer döndürür ve iyice
  birim test edilmiştir.
- **uygulama sınıfı** (`CalculatorApp`) ince bir giriş noktasıdır: `args`'ı ayrıştırır, kütüphaneyi çağırır,
  sonucu yazdırır - başka hiçbir şey yapmaz - ve ayrıştırma mantığı `main`'in İÇİNDE değil, küçük, test edilebilir
  bir metotta yaşar (`run(String[] args)`) ve asla `System.in`'den okumaz (öyle yapsaydı bir betik veya CI işi
  sonsuza dek asılı kalırdı).

"Kütüphane Kitap Takip Sistemi" için bu şöyle olabilir:
- `Book.java`, `Loan.java`, `LibraryCatalog.java` (kütüphane: kitap ekle/çıkar, kitap ödünç ver, geri al, gecikmiş
  ödünçleri listele - konunuzun ders kılavuzunun istediği her ne ise) - her biri eşleşen bir `*Test.java` ile.
- `LibraryTrackerApp.java`, küçük bir alt-komut kümesini (örn. `add-book`, `checkout`, `return`, `list-overdue`)
  `LibraryCatalog`'a yönlendiren bir `static String run(String[] args)` ve yalnızca `run(args)`'ın sonucunu
  yazdıran bir `main` içerir - tıpkı bugün `CalculatorApp`'in yaptığı gibi.

## 4. Önce testleri yazın

Kütüphane sınıflarınızın **her** genel (public) metodu için en az şunları yazın:
- bir **normal** durum (tipik, beklenen girdi)
- bir **sınır** (boundary) durumu (boş koleksiyon, sıfır/bir/çok, ilk/son eleman, `Integer.MAX_VALUE` tarzı sınırlar)
- bir **geçersiz girdi** durumu (`null`, var olmayan bir kitap kimliği, zaten ödünçte olan bir kitabı ödünç verme) -
  seçtiğiniz istisnayı fırlattığını ya da seçtiğiniz hata değerini döndürdüğünü doğrulayın; kazayla belgelenmemiş bir
  `NullPointerException` fırlatmasına izin vermeyin.

`CalculatorTest.java` ve `CalculatorAppTest.java` tam olarak bu örüntünün işlenmiş örnekleridir (JUnit 5,
normal/sınır/geçersiz durumları gruplayan `@Nested` sınıflar, `assertThrows`, sınır tabloları için
`@ParameterizedTest` + `@CsvSource`) - içeriği değil örüntüyü kopyalayın.

## 5. Doxygen'i ve siteyi güncelleyin

`Doxyfile` (çıktı klasörü ve `PROJECT_NUMBER` betiklerden gelir - o iki satıra dokunmayın):
```
PROJECT_NAME    = "Kütüphane Kitap Takip Sistemi"
PROJECT_BRIEF   = "Küçük bir kütüphane kataloğu ve ödünç takip sistemi"
INPUT           = calculator-app/src/main/java
```
Site: `mkdocs.yml` (`site_name`, `site_description`, `repo_url`) ve açılış sayfası `docs/index.md`; Maven sitesi
banner'ı (`calculator-app/src/site/site.xml`) geneldir, olduğu gibi kalabilir.

## 6. Yeniden derleyin ve kontrol edin

```batch
7-build-all-windows.bat
9-open-site-windows.bat
```
(Linux/WSL'de `./7-build-all-linux.sh` ve `./9-open-site-linux.sh`.)
Siteyi açın, **Which report is which?** sayfasını kontrol edin ve şunları doğrulayın:
- birim test raporu tüm yeni testlerinizi, hepsi yeşil olarak gösteriyor
- JaCoCo ve ReportGenerator ikisi de yeni sınıflarınız için gerçek kapsama sayıları gösteriyor (0% değil, ve eski
  `Calculator` sınıfı değil - o kaybolmuş olmalı)
- Javadoc ve Doxygen ikisi de yeni sınıflarınızı yeni Javadoc yorumlarınızla gösteriyor

## 7. Devam edin

- [workflow-tr.md](workflow-tr.md) - günlük branch/commit/push döngüsü ve CI'nin ne yaptığı
- [releases-tr.md](releases-tr.md) - notlandırılacak bir anlık görüntüyü (snapshot) nasıl yayımlarsınız
- [troubleshooting-tr.md](troubleshooting-tr.md) - yukarıdakileri yaparken karşılaşmanız en olası hataların
  düzeltmeleri
