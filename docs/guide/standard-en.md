# Naming standard and site rules

The same standard is used by all three course templates (Java, C/C++, C#), so what you learn here works in every
project of the course. Nothing below is a suggestion - the scripts, the CI workflow and the site depend on it.

## 1. One file names the project: `project.env`

```text
PROJECT_NAME=calculator
VERSION=1.1.0
GITHUB_REPO=ucoruh/eclipse-java-maven-template
```

Every script (`scripts/load-env-windows.bat`, `scripts/load-env-linux.sh`, `scripts/assemble.py`) and the CI
workflow reads this file. To rename your project you edit **this one file** (plus the Java package - see
[From a project topic to your project](from-topic-en.md)). `VERSION` is written without a leading `v`; the Git tag
is `v` + `VERSION`. The Maven `pom.xml` takes its version from the scripts (`-Drevision=<VERSION>`), so the jar is
`calculator-app-1.1.0.jar`.

## 2. Platform tokens

| Token | Means | Where you see it |
|---|---|---|
| `windows` | native Windows | `-windows.bat`, `reports/windows/`, `...-windows-x64-app.zip` |
| `linux` | native Linux **and WSL** (WSL *is* Linux: same `.sh` scripts, Linux binaries) | `-linux.sh`, `reports/linux/`, `...-linux-x64-app.tar.gz` |
| `macos` | CI only, application binary only | `...-macos-arm64-app.tar.gz` |

Architecture (`x64`, `arm64`) appears only in application binary names. The tokens `wsl` and `win` never appear in
a file name.

## 3. The scripts: same number = same job, platform = suffix

Every script exists as `NN-name-windows.bat` and `NN-name-linux.sh` (WSL runs the `.sh`).

| # | Job | Windows | Linux / WSL |
|---|---|---|---|
| 0 | Initialise submodules (only in templates that have submodules; this Java template has none) | - | - |
| 1 | Install the Git hooks | `1-configure-git-hooks-windows.bat` | `1-configure-git-hooks-linux.sh` |
| 2 | Create `.gitignore` (one-time bootstrap for a brand new repo) | `2-create-gitignore-windows.bat` | `2-create-gitignore-linux.sh` |
| 3 | Install the package manager | `3-install-package-manager-windows.bat` | - (apt is already there) |
| 4 | Install every tool | `4-install-tools-windows.bat` | `4-install-tools-linux.sh` |
| 5 | Format the code | `5-format-code-windows.bat` | `5-format-code-linux.sh` |
| 6 | **Fast**: build + unit tests | `6-build-and-test-windows.bat` | `6-build-and-test-linux.sh` |
| 7 | **Everything**: + every report, API docs, both sites, the `release/` folder | `7-build-all-windows.bat` | `7-build-all-linux.sh` |
| 8 | Run the app | `8-run-app-windows.bat` | `8-run-app-linux.sh` |
| 9 | Open the site on `http://localhost` | `9-open-site-windows.bat` | `9-open-site-linux.sh` |
| 10 | Release with the GitHub CLI (`--dry-run` first) | `10-release-windows.bat` | `10-release-linux.sh` |
| 11 | Clean everything generated | `11-clean-windows.bat` | `11-clean-linux.sh` |

Helper scripts (not meant to be run by hand) live in `scripts/` and follow the same suffix rule:
`load-env-*`, `detect-python-*`, `detect-genhtml-*`, `delete-desktop-ini-*`, `install-toolchain-linux.sh`. The two
platform-neutral helpers are Python: `scripts/assemble.py` (staging, zipping, site pages, `ASSETS.md`,
`SHA256SUMS.txt`) and `scripts/check-links.py` (link checker).

### Old name -> new name

| Old | New |
|---|---|
| `1-configure-git-hooks.bat` / `.sh` | `1-configure-git-hooks-windows.bat` / `1-configure-git-hooks-linux.sh` |
| `2-create-git-ignore.bat` / `.sh` | `2-create-gitignore-windows.bat` / `2-create-gitignore-linux.sh` |
| `3-install-package-manager.bat` | `3-install-package-manager-windows.bat` |
| `3-install-package-manager.sh` | merged into `4-install-tools-linux.sh` (runs `scripts/install-toolchain-linux.sh`) |
| `4-install-required-apps.bat` / `.sh` | `4-install-tools-windows.bat` / `4-install-tools-linux.sh` |
| `5-format-code.bat` / `.sh` | `5-format-code-windows.bat` / `5-format-code-linux.sh` |
| `7-build-app.bat` / `.sh` | `7-build-all-windows.bat` / `7-build-all-linux.sh` (the quick part is the new `6-build-and-test-*`) |
| `8-run-app.bat` / `.sh` | `8-run-app-windows.bat` / `8-run-app-linux.sh` |
| `9-run-webpage.bat` / `.sh` | `9-open-site-windows.bat` / `9-open-site-linux.sh` |
| `10-release.bat` / `.sh` | `10-release-windows.bat` / `10-release-linux.sh` |
| `delete_desktop_ini.bat` / `.sh` | `scripts/delete-desktop-ini-windows.bat` / `scripts/delete-desktop-ini-linux.sh` |
| `init-submodules.bat`, `update-submodules.bat` | `docs/archive/legacy-scripts/` (this template has no submodules) |
| `VERSION` file | `project.env` |

## 4. Local folders (all gitignored)

| Folder | Holds |
|---|---|
| `build/<platform>-<config>/` | the built jar, e.g. `build/windows-release/` |
| `publish/<platform>-<arch>/` | the runnable application folder, e.g. `publish/linux-x64/` (`run.bat` / `run.sh`) |
| `reports/<platform>/<kind>-<tool>/` | one folder per report, e.g. `reports/linux/coverage-jacoco/`, `reports/windows/tests-junit2html/` |
| `site/` | the MkDocs site (the main site) |
| `site-native/` | the Maven site (Fluido) |
| `release/` | every release asset - exactly what the GitHub release gets |

Maven itself still works in `calculator-app/target/` (Eclipse and every IDE expect that); the scripts copy what
matters into the folders above.

The report folders (`<kind>-<tool>`): `tests-junit2html`, `coverage-jacoco`, `coverage-reportgenerator`,
`doccoverage-lcov`, `doccoverage-reportgenerator`, `api-doxygen`, `api-javadoc`. Windows and Linux each get their
own set, because results can differ between the two (line endings, paths, tool versions).

## 5. Release assets

Pattern: `<project>-<version>[-<platform>[-<arch>]]-<content>[-<tool>].<ext>` (version without `v`).

| Asset | Example |
|---|---|
| application | `calculator-1.1.0-windows-x64-app.zip`, `calculator-1.1.0-linux-x64-app.tar.gz`, `calculator-1.1.0-macos-arm64-app.tar.gz` (CI) |
| tests | `calculator-1.1.0-windows-report-tests.zip`, `...-linux-report-tests.zip` |
| coverage | `...-<platform>-report-coverage-reportgenerator.zip`, `...-<platform>-report-coverage-jacoco.zip` |
| documentation coverage | `...-<platform>-report-doccoverage-reportgenerator.zip`, `...-<platform>-report-doccoverage-lcov.zip` |
| API docs | `...-<platform>-api-doxygen.zip`, `...-<platform>-api-javadoc.zip` |
| Maven site | `calculator-1.1.0-site-maven.zip` (with Checkstyle, PMD, CPD, SpotBugs, Surefire, JXR) |
| neutral | `calculator-1.1.0-source.zip`, `calculator-1.1.0-site.zip` (MkDocs site with **both** platforms), `ASSETS.md`, `SHA256SUMS.txt` |

`.zip` for Windows binaries and everything HTML; `.tar.gz` for Linux/macOS binaries (it keeps the executable bit).
The local `release/` folder and the GitHub release contain **the same names**. A local build holds your platform's
assets plus the neutral ones; `ASSETS.md` says which platform's assets are missing (CI builds all of them).

## 6. Site rules: what is framed and what is not

The main site is **MkDocs Material**: Home, Guide (EN), Kılavuz (TR), Reports (Windows / Linux), API docs, Downloads,
Maven site. The Java ecosystem's own site (Maven + Fluido) is still built and is published under `native/` on Pages
(`site-native/` locally).

**The rule:** only **standalone HTML made outside the site generator** goes into an `<iframe>` (ReportGenerator,
genhtml, junit2html, JaCoCo, Javadoc, Doxygen). A page that **carries its own site navigation** - every Maven-site
page (project info, Surefire, Checkstyle, PMD, CPD, SpotBugs, JXR) - is **never framed**; it is linked so it opens as
its own site in a new tab.

Right - a standalone report in a frame (`docs/reports/linux/coverage-jacoco/index.md`):

```html
<iframe class="report-frame" src="html/index.html" title="JaCoCo coverage (linux)" loading="lazy"></iframe>
```

Wrong - a Maven-site page in a frame (you would see a site inside the site: two menus, two banners, a scrollbar
inside a scrollbar):

```html
<iframe src="../native/checkstyle.html"></iframe>   <!-- do NOT do this -->
```

Right - the Maven-site page as a link that opens in a new tab:

```html
<a href="../native/checkstyle.html" target="_blank" rel="noopener">Checkstyle (Maven site)</a>
```

## 7. CI in one picture

| Job | Runs on | Does |
|---|---|---|
| `windows` | `windows-latest` | `7-build-all-windows.bat --no-site`, uploads `reports/windows` + its `release/` files |
| `linux` | `ubuntu-latest` | `7-build-all-linux.sh --no-site`, uploads `reports/linux`, `site-native` + its `release/` files |
| `macos` | `macos-latest` | builds and packs the application only (`...-macos-arm64-app.tar.gz`) |
| `site` | `ubuntu-latest` | merges every artifact, builds the MkDocs site (both platforms) + copies the Maven site to `native/`, checks links (fails only on broken links in **our own** pages), deploys Pages on a push to `main` (private-repo rule: [releases](releases-en.md)), and on a `v*` tag publishes every asset with `ASSETS.md`, `SHA256SUMS.txt` and notes that link the site |
