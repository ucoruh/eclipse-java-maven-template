# Install everything (Windows and Linux/WSL)

This page gets a brand new machine ready to build `eclipse-java-maven-template`. Every command below is one you
can copy-paste; the "expected output" line tells you what a working install looks like so you know when to stop.

## What you need and why

| Tool | Why | Used by |
|---|---|---|
| JDK 17 (or 21) | compile and run Java, JUnit 5 needs 17+ | everything |
| Maven 3.8+ | build, test, package, site | everything |
| Git | clone, hooks, releases | everything |
| Doxygen | API docs (2nd family) + input for documentation coverage | `7-build-all-*` |
| lcov (`genhtml`) + a Windows-native Perl | renders the documentation-coverage report (native family) | `7-build-all-*` |
| Python 3.12 + the packages in `requirements.txt` (`coverxygen`, `junit2html`, `mkdocs-material`) | documentation-coverage source, the unit-test HTML report, the main site | `6-build-and-test-*`, `7-build-all-*` |
| .NET SDK + ReportGenerator global tool | coverage/doc-coverage HTML, badges, history (2nd family) | `7-build-all-*` |
| Astyle | code formatting | `5-format-code`, the pre-commit hook |
| GitHub CLI (`gh`) | publish a release from your machine | `10-release-*` |

## Windows

### 1. Package managers

```batch
3-install-package-manager-windows.bat
```

Installs [Chocolatey](https://chocolatey.org/) and [Scoop](https://scoop.sh/) if you do not already have them.

### 2. Everything else

```batch
4-install-tools-windows.bat
```

(Run it in an **administrator** terminal; it installs JDK 17, Maven, Astyle, Doxygen, Graphviz, lcov, Strawberry Perl, the
ReportGenerator tool, the Python packages and the GitHub CLI - each only if missing.)

This script checks each tool first and only installs what is missing, so it is safe to re-run. Verify each tool
afterwards:

```batch
java -version
```
Expected output (version may differ, but it must be **17 or higher**):
```
openjdk version "17.0.9" 2023-10-17
OpenJDK Runtime Environment Temurin-17.0.9+9 (build 17.0.9+9)
```

```batch
mvn -version
```
Expected output includes a `Java version:` line matching the JDK above.

```batch
doxygen --version
```
Expected: a version number, e.g. `1.9.7`.

```batch
where genhtml
```
Expected: a path such as `C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml`. This file has **no `.exe`
extension** - it is a Perl script, so `7-build-all-windows.bat` always runs it as `perl "<path>\genhtml" ...`, never as
`genhtml` directly. If `perl` itself is missing: `choco install strawberryperl -y`.

```batch
py -3.12 -c "import coverxygen; print('coverxygen OK')"
```
Expected: `coverxygen OK`. **Do not use plain `python`** for this - see
[troubleshooting-en.md](troubleshooting-en.md#a-different-python-runs-first) for why.

```batch
dotnet --version
reportgenerator --help
```
Expected: a .NET SDK version (8.x or newer) and ReportGenerator's help text.

```batch
gh --version
```
Expected: `gh version X.Y.Z (...)`. Needed only for `10-release-windows.bat` - see
[releases-en.md](releases-en.md).

## Linux / WSL (Ubuntu)

If you use WSL, open an **Ubuntu terminal** (not PowerShell) for all of the commands below. WSL cannot see your
Google Drive `G:` path - see [troubleshooting-en.md](troubleshooting-en.md#wsl-cannot-see-g) for how to work
around that.

### 1. Everything (one script)

```bash
./4-install-tools-linux.sh
```

There is no separate package-manager script on Linux (`apt` is already there). The script refreshes `apt`, installs the
native tools, and - only where `apt`'s version is too old - a per-user JDK 17, Maven 3.9 and .NET SDK (into `$HOME/tools`
and `$HOME/.dotnet`, no `sudo` for that part), then ReportGenerator and the Python packages of `requirements.txt`.

Verify:

```bash
java -version        # 17 or newer
mvn -version
doxygen --version
genhtml --version     # a normal, directly-executable command on Linux - no perl wrapper needed
python3 -c "import coverxygen; print('coverxygen OK')"
dotnet --version
reportgenerator --help
gh --version
```

If `reportgenerator` is "not found" right after installing it, your shell does not have `$HOME/.dotnet/tools` on
`PATH` yet. If it *is* found but fails with a "You must install .NET to run this application" / missing-framework
error, `DOTNET_ROOT` is not set (see
[troubleshooting-en.md](troubleshooting-en.md#dotnet-root)). Add both to `~/.bashrc` and open a new terminal:

```bash
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$HOME/.dotnet:$HOME/.dotnet/tools:$PATH"
```

### 3. Make the scripts executable

The `.sh` scripts are committed with the executable bit set (`git update-index --chmod=+x`), so a fresh `git
clone` should already let you run `./7-build-all-linux.sh` directly. If you get "Permission denied":

```bash
chmod +x *.sh
```

## Next

Once every command above prints what this page says it should, continue with
[use-template-en.md](use-template-en.md).
