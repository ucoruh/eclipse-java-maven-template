# Her şeyi kurun (Windows ve Linux/WSL)

Bu sayfa `eclipse-java-maven-template`'i derlemek için sıfır bir makineyi hazırlar. Aşağıdaki her komut kopyala-
yapıştır yapabileceğiniz bir komuttur; "beklenen çıktı" satırı çalışan bir kurulumun neye benzediğini gösterir, böylece
ne zaman duracağınızı bilirsiniz.

## Neye ihtiyacınız var ve neden

| Araç | Neden | Kim kullanıyor |
|---|---|---|
| JDK 17 (veya 21) | Java'yı derlemek/çalıştırmak için; JUnit 5, 17+ ister | her şey |
| Maven 3.8+ | build, test, package, site | her şey |
| Git | clone, hook'lar, release'ler | her şey |
| Doxygen | API dokümantasyonu (2. aile) + dokümantasyon kapsamasının girdisi | `7-build-all-*` |
| lcov (`genhtml`) + Windows'a özgü bir Perl | dokümantasyon kapsama raporunu (native aile) render eder | `7-build-all-*` |
| Python 3.12 + `requirements.txt` paketleri (`coverxygen`, `junit2html`, `mkdocs-material`) | dokümantasyon-kapsama kaynağı, birim test HTML raporu, ana site | `6-build-and-test-*`, `7-build-all-*` |
| .NET SDK + ReportGenerator global tool | kapsama/dokümantasyon-kapsama HTML'i, rozetler, geçmiş (2. aile) | `7-build-all-*` |
| Astyle | kod biçimlendirme | `5-format-code`, pre-commit kancası |
| GitHub CLI (`gh`) | makinenizden bir release yayımlamak | `10-release-*` |

## Windows

### 1. Paket yöneticileri

```batch
3-install-package-manager-windows.bat
```

[Chocolatey](https://chocolatey.org/) ve [Scoop](https://scoop.sh/)'u, zaten yoksa kurar.

### 2. Geri kalan her şey

```batch
4-install-tools-windows.bat
```

(**Yönetici** terminalinde çalıştırın; JDK 17, Maven, Astyle, Doxygen, Graphviz, lcov, Strawberry Perl, ReportGenerator
aracı, Python paketleri ve GitHub CLI'ı - her biri yalnızca eksikse - kurar.)

Bu betik her aracı önce kontrol eder ve yalnızca eksik olanı kurar, bu yüzden tekrar tekrar çalıştırmak güvenlidir.
Ardından her aracı doğrulayın:

```batch
java -version
```
Beklenen çıktı (sürüm farklı olabilir ama **17 veya üzeri** olmalı):
```
openjdk version "17.0.9" 2023-10-17
OpenJDK Runtime Environment Temurin-17.0.9+9 (build 17.0.9+9)
```

```batch
mvn -version
```
Beklenen çıktıda yukarıdaki JDK ile eşleşen bir `Java version:` satırı olmalı.

```batch
doxygen --version
```
Beklenen: bir sürüm numarası, örn. `1.9.7`.

```batch
where genhtml
```
Beklenen: `C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml` gibi bir yol. Bu dosyanın **`.exe` uzantısı yoktur** -
bir Perl betiğidir, bu yüzden `7-build-all-windows.bat` onu her zaman `genhtml` olarak değil, `perl "<yol>\genhtml" ...`
olarak çalıştırır. `perl`'in kendisi eksikse: `choco install strawberryperl -y`.

```batch
py -3.12 -c "import coverxygen; print('coverxygen OK')"
```
Beklenen: `coverxygen OK`. Bunun için **düz `python`'ı kullanmayın** - nedeni için bakınız
[troubleshooting-tr.md](troubleshooting-tr.md#farkli-bir-python-once-calisiyor).

```batch
dotnet --version
reportgenerator --help
```
Beklenen: bir .NET SDK sürümü (8.x veya üzeri) ve ReportGenerator'ın yardım metni.

```batch
gh --version
```
Beklenen: `gh version X.Y.Z (...)`. Yalnızca `10-release-windows.bat` için gerekli - bakınız
[releases-tr.md](releases-tr.md).

## Linux / WSL (Ubuntu)

WSL kullanıyorsanız aşağıdaki tüm komutlar için bir **Ubuntu terminali** açın (PowerShell değil). WSL, Google
Drive'ınızdaki `G:` yolunu göremez - bunu nasıl aşacağınız için bakınız
[troubleshooting-tr.md](troubleshooting-tr.md#wsl-g-yi-goremiyor).

### 1. Her şey (tek betik)

```bash
./4-install-tools-linux.sh
```

Linux'ta ayrı bir paket yöneticisi betiği yoktur (`apt` zaten vardır). Betik `apt`'ı günceller, yerel araçları kurar ve -
yalnızca `apt` sürümü çok eskiyse - kullanıcı bazında JDK 17, Maven 3.9 ve .NET SDK'yı (`$HOME/tools` ve `$HOME/.dotnet`
içine, bu kısım için `sudo` gerekmez), ardından ReportGenerator'ı ve `requirements.txt` Python paketlerini kurar.

Doğrulayın:

```bash
java -version        # 17 veya üzeri
mvn -version
doxygen --version
genhtml --version     # Linux'ta doğrudan çalıştırılabilen normal bir komut - perl sarmalayıcı gerekmez
python3 -c "import coverxygen; print('coverxygen OK')"
dotnet --version
reportgenerator --help
gh --version
```

`reportgenerator` kurulumdan hemen sonra "bulunamadı" derse, kabuğunuzda `$HOME/.dotnet/tools` henüz `PATH`'te
değildir. *Bulunuyor* ama "You must install .NET to run this application" / eksik-framework hatasıyla
başarısız oluyorsa (bir eski .NET SDK'sının önceden kurulu geldiği WSL imajlarında yaygındır), `DOTNET_ROOT`
ayarlı değildir - bakınız [troubleshooting-tr.md](troubleshooting-tr.md#dotnet-root). İkisini de `~/.bashrc`'ye
ekleyip yeni bir terminal açın:

```bash
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$HOME/.dotnet:$HOME/.dotnet/tools:$PATH"
```

### 3. Betikleri çalıştırılabilir yapın

`.sh` betikleri çalıştırılabilir bit'i işaretli olarak commit edilir (`git update-index --chmod=+x`), bu yüzden
taze bir `git clone` `./7-build-all-linux.sh`'i doğrudan çalıştırmanıza izin vermelidir. "Permission denied" alırsanız:

```bash
chmod +x *.sh
```

## Sırada

Yukarıdaki her komut bu sayfanın söylediğini yazdırdığında, [use-template-tr.md](use-template-tr.md) ile devam
edin.
