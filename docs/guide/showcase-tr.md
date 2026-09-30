# GitHub Pages olmadan projenizi gösterin

Ders deponuz **özeldir (private)** ve **GitHub Free**'de özel bir depo GitHub Pages yayınlayamaz. Bu ders için sorun
değil: Pages'in göstereceği her şeyi **yerelde** gösterebilirsiniz ve bir sürümden indireceğiniz her şey zaten
`release/` klasörünüzde durur. Bu sayfa tam tarif ve proje sunumu için gösterim kontrol listesidir.

## Depo neden özel ve nasıl oluşturulur (fork DEĞİL)

Deponuzu **Fork** ile değil **Use this template** ile oluşturun: herkese açık bir deponun fork'u özel yapılamaz,
şablondan oluşturulan depo yapılabilir.

1. GitHub'da şablonu açın: <https://github.com/ucoruh/eclipse-java-maven-template>.
2. Yeşil **Use this template** düğmesine (sağ üstte, **Code**'un yanında) tıklayın -> **Create a new repository**.
3. Owner: kendi hesabınız. Repository name: örn. `cen207-adiniz-project`. **Private** seçin. **Create repository**.
4. Yeni deponuzda: **Settings -> Collaborators -> Add people**; eğitmen `ucoruh`'u (ve takım arkadaşlarınızı) ekleyin.
   Davetiyeyi kabul etmeden depoyu göremezler.
5. Klonlayın ve ilk derlemeyi yapın ([Şablonu kullanın](use-template-tr.md)).

## Tam siteyi yerelde derleyin ve açın

Windows:
```batch
7-build-all-windows.bat
9-open-site-windows.bat
```
Linux / WSL:
```bash
./7-build-all-linux.sh
./9-open-site-linux.sh
```

`7-build-all-*` uygulamayı derler, testleri çalıştırır, her raporu ve API belgesini üretir, MkDocs sitesini (`site/`)
ve Maven sitesini (`site-native/`) kurar ve `release/` klasörünü doldurur. `9-open-site-*` siteyi
**http://localhost:8000/** adresinde sunar ve tarayıcıda açar (açılmazsa adresi elle açın). Sunum boyunca pencereyi
açık tutun; **CTRL+C** sunucuyu durdurur.

Neden `index.html`'e çift tıklamak yerine sunucu? Rapor sayfaları raporları çerçevede gösterir ve tarayıcılar
`file://` sayfalarının çerçevelerini engeller: boş çerçeve görürsünüz.

`7-build-all-*` sonunda beklenen çıktı:
```text
Operation completed.
  Site:        site/index.html
  Maven site:  site-native/index.html
  Reports:     reports/<platformunuz>/
  Release:     release/          (ASSETS.md lists every file)
```

## Gösterim kontrol listesi

Başlamadan **önce** `7-build-all-*` bitmiş ve `9-open-site-*` çalışıyor olsun (sınıfın önünde derleme yapmayın).

1. **Site ana sayfası** (`http://localhost:8000/`): rozetler, üst bölüm, menü (Home, Guide, Kılavuz, Reports, API
   docs, Downloads, Maven site).
2. **Her rapor sayfası** (**Reports -> Windows** veya **Linux**, hangisinde derlediyseniz): birim testleri (hepsi
   yeşil mi?), JaCoCo ve ReportGenerator ile kapsama (sayılar aynı mı?), genhtml ve ReportGenerator ile
   dokümantasyon kapsaması. Her birinin ne gösterdiğini ve hangi satırların kırmızı olduğunu bir cümleyle söyleyin.
3. **API belgeleri**: **API docs** -> Doxygen ve Javadoc; *kendi* sınıflarınızdan birini bulup yorumunu gösterin.
4. **Maven sitesi**: **Maven site (native)** -> *Open the Maven site* (yeni sekme) -> Checkstyle / PMD / SpotBugs; bir
   bulguyu ve ne yaptığınızı açıklayın.
5. Dosya gezgininde veya terminalde **`release/` klasörü** (`dir release` / `ls -l release`): her dosyayı gösterin,
   `ASSETS.md`'yi açın; `SHA256SUMS.txt`'yi anın.
6. **Uygulamayı kaynak ağacından değil, sürüm arşivinden çalıştırın**: `release/<proje>-<sürüm>-windows-x64-app.zip`
   dosyasını açın (veya `linux` olanı), `run.bat 6 "*" 7` (ya da `./run.sh 6 "*" 7`) çalıştırıp sonucu gösterin.
7. **Sağlama toplamı doğrulama** (isteğe bağlı, 30 sn): Windows `Get-FileHash release\<dosya> -Algorithm SHA256`,
   Linux `sha256sum -c SHA256SUMS.txt`.

Diğer platformun raporları yerelde yoktur (bir makine = bir platform); `ASSETS.md` bunu söyler. CI yeşilken GitHub
sürümünde ikisi de vardır: son madde olarak sürüm sayfasını açın.

## Aynı dosyalar bir GitHub Release'te (özel depolarda çalışır)

Sürüm (release), bir etiket artı eklenmiş dosyalardır; GitHub Free'de özel depolarda çalışır ve ortak çalışanlarınız
(eğitmen) tarafından görülür.

```batch
10-release-windows.bat --dry-run
10-release-windows.bat
```
(Linux/WSL'de `./10-release-linux.sh`.) `--dry-run` her şeyi derler ve yayınlamadan tam `gh release create` komutunu
ve dosya listesini yazdırır. Gerçek çalıştırma `v<project.env'deki VERSION>` sürümünü **`release/`'deki her dosyayla**
yayınlar. GitHub CLI'da bir kez oturum açmalısınız: `gh auth login` - bkz. [Sürümler ve özel depolar](releases-tr.md).

## GitHub Pro'nuz varsa (Student Developer Pack)

O zaman canlı site de mümkündür: [Sürümler ve özel depolar](releases-tr.md), *Yine de GitHub Pages almak* bölümü. O
zamana kadar bu yerel gösterim tamamen yeterlidir.

## Sorunlar

| Belirti | Çözüm |
|---|---|
| `9-open-site-*` `site/index.html not found` diyor | önce `7-build-all-*` çalıştırın |
| Rapor sayfasında boş çerçeveler | `site/index.html`'e çift tıkladınız; `9-open-site-*` kullanın (http://localhost) |
| `Address already in use` | 8000 portunu başka sunucu kullanıyor: `9-open-site-windows.bat 8080` (boş herhangi bir port) |
| Bir platformun rapor sayfaları *Not available in this build* diyor | beklenen: o platform bu makinede derlenmedi; CI ikisini de derler |
