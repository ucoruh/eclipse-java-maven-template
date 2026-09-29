# Proje konusundan kendi projenize

Bu sayfa `Calculator` örneğini gerçek bir ders projesine dönüştürmeyi, somut bir örnek konuyla anlatır:
**"Kütüphane Kitap Takip Sistemi"** (küçük bir kütüphane kataloğu + ödünç takibi - ders proje kılavuzundan seçtiğiniz
konuyu buraya koyun, adımlar aynı).

## Kontrol listesi

- [ ] Maven koordinatlarını (`groupId`/`artifactId`) ve Java paketini yeniden adlandırın
- [ ] Kaynak klasörlerini yeni pakete uyacak şekilde yeniden adlandırın
- [ ] `Calculator` / `CalculatorApp`'i kendi alan (domain) sınıflarınızla değiştirin
- [ ] `pom.xml`'in `<name>`/`<description>`/`<url>`/shade `mainClass`'ını güncelleyin
- [ ] `Doxyfile`'ın `PROJECT_NAME`/`PROJECT_BRIEF`/`INPUT`'unu güncelleyin
- [ ] `calculator-app/src/site/site.xml`'in banner/bağlantılarını güncelleyin (ya da olduğu gibi bırakın - geneldir)
- [ ] Her yeni modül için **önce** test yazın (normal, sınır, geçersiz girdi - aşağıya bakın)
- [ ] Her değişiklikten sonra `7-build-app`'i çalıştırmaya devam edin ve kapsama rozetlerini/raporlarını kontrol edin
- [ ] `README.md`'nin başlığını ve açıklamasını güncelleyin
- [ ] Erken ve sık commit edin (bakınız [workflow-tr.md](workflow-tr.md))

## 1. Maven koordinatlarını yeniden adlandırın

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

`artifactId`'yi yeniden adlandırırsanız, `calculator-app-1.0-SNAPSHOT.jar`'ı sabit kodlayan her betiği de
güncelleyin (`8-run-app.bat`/`.sh`, `9-run-webpage.bat`/`.sh`, `7-build-app.bat`/`.sh`'nin jar kontrolü) ve
yukarıdaki `<mainClass>`'ı.

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

`Doxyfile`:
```
PROJECT_NAME    = "Kütüphane Kitap Takip Sistemi"
PROJECT_BRIEF   = "Küçük bir kütüphane kataloğu ve ödünç takip sistemi"
INPUT           = calculator-app/src/main/java
```
(`calculator-app` klasör adını koruyorsanız `INPUT` olduğu gibi kalabilir; klasörün de eşleşmesini istiyorsanız
onu da yeniden adlandırın - `git mv calculator-app library-tracker-app` - ve ardından her betik/`pom.xml`/
`Doxyfile` referansını `calculator-app/`'e güncelleyin.)

## 6. Yeniden derleyin ve kontrol edin

```batch
7-build-app.bat
9-run-webpage.bat
```
Siteyi açın, **Which report is which?** sayfasını kontrol edin ve şunları doğrulayın:
- Surefire raporu tüm yeni testlerinizi, hepsi yeşil olarak gösteriyor
- JaCoCo ve ReportGenerator ikisi de yeni sınıflarınız için gerçek kapsama sayıları gösteriyor (0% değil, ve eski
  `Calculator` sınıfı değil - o kaybolmuş olmalı)
- Javadoc ve Doxygen ikisi de yeni sınıflarınızı yeni Javadoc yorumlarınızla gösteriyor

## 7. Devam edin

- [workflow-tr.md](workflow-tr.md) - günlük branch/commit/push döngüsü ve CI'nin ne yaptığı
- [releases-tr.md](releases-tr.md) - notlandırılacak bir anlık görüntüyü (snapshot) nasıl yayımlarsınız
- [troubleshooting-tr.md](troubleshooting-tr.md) - yukarıdakileri yaparken karşılaşmanız en olası hataların
  düzeltmeleri
