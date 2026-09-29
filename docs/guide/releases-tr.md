# Özel depo: release'ler ve site

Ders deponuz **özel (private)** ve çoğu öğrencide düz bir **GitHub Free** hesabı var. Bu sayfa bunun tam olarak ne
yapıp ne yapmadığını ve bu şablonun boşlukları nasıl aştığını açıklar.

## Free ile Pro'da ne çalışır (GitHub'ın kendi belgelerinden gerçekler)

| Özellik | GitHub Free (özel depo) | GitHub Pro / Team (ya da Pro veren Free'nin Student Developer Pack'i) |
|---|---|---|
| **Release'ler** (bir etiket + ekli dosyalar, dosya başına 2 GiB'e, 1000 varlığa kadar) | **Çalışır.** Yalnızca siz ve eklediğiniz katkıcılara (collaborator) görünür. | Aynı, fark yok. |
| **GitHub Pages** (canlı bir `https://<kullanici>.github.io/<depo>/` sitesi) | **Özel bir depoda çalışmaz.** | Depo için Pages etkinleştirildiğinde **çalışır**. |
| **GitHub Actions dakikaları** | 2.000 dakika/ay, 500 MB artifact depolama | 3.000 dakika/ay, 1 GB artifact depolama |

Pratik sonuç: **Free'de özel bir depoda göz atılabilir bir siteyi teslim etme yolu Release'lerdir** - Pages değil.
`10-release.bat`/`.sh` (ve `release.yml` Actions iş akışı) tam olarak bunu üretir: her rapor paketlenip bir GitHub
Release'e eklenir, artı tüm site `site.zip` olarak sıkıştırılır, böylece indirilip hiç sunucu gerekmeden yerelde
açılabilir (aç → `index.html`'i aç).

## Yine de GitHub Pages almak: Student Developer Pack

Bir `site.zip` yerine (veya ona ek olarak) canlı bir Pages URL'si istiyorsanız:

1. <https://education.github.com/pack> adresine gidin ve **üniversite e-posta adresinizle** başvurun
   (`...@erdogan.edu.tr` ya da eşdeğeri) - GitHub'ın önce kontrol ettiği ve en hızlı onay yolu budur.
2. Kanıt istenirse, genellikle bir öğrenci kimliği fotoğrafı ya da kayıt belgesi yeterlidir.
3. Onay birkaç dakikadan birkaç güne kadar sürebilir - ilk release'inizden önce beklemeyin; bu arada
   `site.zip`'i kullanın.
4. Onaylandıktan sonra hesabınızda GitHub Pro olur. Deponuzda: **Settings -> Pages -> Source**, etkinleştirin
   (branch ya da Actions tabanlı, seçiminize göre).
5. Ancak o zaman `release.yml`'in elle tetiklemesini **"Also deploy target/site to GitHub Pages"** işaretli
   çalıştırın (bakınız [workflow-tr.md](workflow-tr.md)) - Pages henüz etkinleştirilmemişse zararsızca başarısız
   olur.

## Eğitmeni katkıcı olarak ekleyin

Notlandırma özel release'lerinizi görebilmelidir. Deponuzda: **Settings -> Collaborators -> Add people**,
`ucoruh`'u (ya da eğitmeninizin verdiği GitHub kullanıcı adını) ekleyin ve daveti kabul etmesini bekleyin. Bu
yapılmazsa Releases sayfanız - ve depodaki her şey - eğitmen için görünmezdir.

## GitHub CLI'yi (`gh`) kurmak ve giriş yapmak

Windows:
```batch
where gh
```
Eksikse: `choco install gh -y` (`4-install-required-apps.bat` tarafından da yapılır).

Linux/WSL:
```bash
gh --version
```
Eksikse, `4-install-required-apps.sh` `apt` ile kurar.

Ardından, release aldığınız her makinede **bir kez**:
```bash
gh auth login
```
İstemlere yanıt verin: **GitHub.com** -> **HTTPS** -> **Login with a web browser** (en kolayı) -> gösterdiği
tek-seferlik kodu açtığı tarayıcı sekmesine girin. Doğrulayın:
```bash
gh auth status
```
Beklenen çıktı `Logged in to github.com account <kullanici-adiniz>` gibi bir satır içerir.

## Bir release yayımlamak

```batch
10-release.bat v1.0.0
```
ya da, depoda zaten bulunan `VERSION` dosyasını kullanarak (önce sürümü artırın):
```batch
10-release.bat
```
Her iki betik de:
1. **kirli bir çalışma ağacında çalışmayı reddeder** - önce commit edin ya da stash'leyin, böylece bir release
   her zaman gerçek bir commit'e karşılık gelir;
2. `gh auth status`'u kontrol eder ve giriş yapmamışsanız tam olarak nasıl yapacağınızı söyler;
3. tam derlemeyi çalıştırır (`7-build-app`) - jar, her iki kapsama-raporu ailesi, her iki dokümantasyon-kapsama
   ailesi, Javadoc + Doxygen, Maven site;
4. siteyi `release/site.zip` olarak sıkıştırır;
5. `gh release create <sürüm> release/* --title <sürüm> --notes-file <üretilen notlar>`'ı çalıştırır.

Gerçek bir projede ilk kullanımınızda **her zaman önce `--dry-run`'ı deneyin** - 1-4. adımları çalıştırır ve tam
`gh release create` komutunu ve varlık listesini yazdırır, ama hiçbir şey yayımlamaz:
```batch
10-release.bat v1.0.0 --dry-run
```

Bu **sıfır GitHub Actions dakikası** kullanır - her şey makinenizde çalışır, yalnızca son `gh release create`
çağrısı GitHub ile konuşur.

## CI alternatifi: `release.yml`

`.github/workflows/release.yml` aynı tam boru hattını, ama GitHub'ın çalıştırıcılarında, bir `v*` etiketinin
push'lanmasıyla ya da **Actions** sekmesinden elle tetiklenmesiyle yapar. Tam araç zincirini yerel kurmak
istemiyorsanız makul bir alternatiftir, ama Actions dakikası harcar (çalıştırma başına kabaca 4-6 dakika - iş
akışı dosyasının üstündeki yoruma bakın) - Free'nin 2.000 dakika/ay'ında birkaç release için bu gerçek bir sorun
değildir, ama her push'ta çalışacak şekilde bağlamayın.

## Sorun giderme {#sorun-giderme}

| Belirti | Düzeltme |
|---|---|
| `10-release` "gh is not logged in to GitHub" ile duruyor | `gh auth login`, ardından doğrulamak için `gh auth status`. |
| `gh release create` `HTTP 404` ile başarısız oluyor | Genellikle `gh`'nin yanlış hesaba giriş yapmış olduğu, ya da depo yolu/remote'un yanlış olduğu anlamına gelir. `gh repo view`'ın deponuzu yazdırdığını kontrol edin. |
| `gh release create` `HTTP 403` ile başarısız oluyor | Siz (ya da `gh`'nin giriş yaptığı hesap) bu depoya yazma erişimine sahip değilsiniz - sahibi olduğunuzu ya da yazma erişimiyle (sadece okuma değil) katkıcı olarak eklendiğinizi doğrulayın. |
| Eğitmen release'inizi göremediğini söylüyor | Onu katkıcı olarak eklemeyi unuttunuz (yukarıya bakın), ya da depo özel ve hiç davet edilmediler. |
| `gh release create` bir varlığın çok büyük olduğundan bahsederek başarısız oluyor | GitHub'ın sınırı **dosya başına** 2 GiB'dir. `release/*.tar.gz` ve `site.zip` bu şablon için normalde birkaç MB'dir - biri şişerse, `target/`'ı kazayla kendi içine özyinelemeli paketlemediğinizi, ya da gitignore'lanması gereken üretilmiş içeriği kontrol edin. |
| Release başarılı ama `site.zip` boş/bozuk bir sayfa açıyor | Önce tamamen çıkarın (zip görüntüleyiciden doğrudan `index.html`'i açmayın) - `css/`/`js/`/rapor alt klasörlerine göreli bağlantıların, onun yanında çıkarılmış kardeş dosyalara ihtiyacı vardır. |
