---
title: Home
hide:
  - toc
---

<div class="hero" markdown>

# Calculator - Java + Maven course template

A complete, tested starting point for a term project: **Java 17**, **Maven**, **JUnit 5**, coverage with **JaCoCo**
and **ReportGenerator**, API docs with **Javadoc** and **Doxygen**, and this site - every report produced on
**Windows and Linux**, every release asset named the same way locally and on GitHub.

<p class="badge-row">
<a href="https://github.com/ucoruh/eclipse-java-maven-template/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/ucoruh/eclipse-java-maven-template/ci.yml?branch=main&amp;label=build" alt="Build status"></a>
<a href="reports/linux/coverage-reportgenerator/"><img src="assets/badge_combined.svg" alt="Code coverage"></a>
<a href="reports/linux/doccoverage-reportgenerator/"><img src="assets/badge_doccoverage.svg" alt="Documentation coverage"></a>
<a href="https://github.com/ucoruh/eclipse-java-maven-template/releases/latest"><img src="https://img.shields.io/github/v/release/ucoruh/eclipse-java-maven-template?label=release" alt="Latest release"></a>
<a href="https://github.com/ucoruh/eclipse-java-maven-template/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-AGPL--3.0-blue" alt="License: AGPL-3.0"></a>
</p>

[Download the latest release](https://github.com/ucoruh/eclipse-java-maven-template/releases/latest){ .md-button .md-button--primary }
[Start here: install the tools](guide/install.md){ .md-button }

</div>

## Start

<div class="grid cards" markdown>

- :material-book-open-variant: **Guide**

    Install, use the template, turn a project topic into your own project, daily workflow, troubleshooting.

    [:octicons-arrow-right-24: Open the guide](guide/install.md)

- :material-translate: **English / Türkçe**

    The whole site - guides, report pages, downloads - is available in both languages. Use the language switcher in the header.

    [:octicons-arrow-right-24: Türkçe](tr/)

- :material-presentation: **Show your project without GitHub Pages**

    Private repository on GitHub Free? Build and open the full site locally, with the demo checklist.

    [:octicons-arrow-right-24: Demo checklist](guide/showcase.md)

- :material-tag-text: **Naming standard and site rules**

    Script names, folders, release assets, and when a report is framed and when it opens on its own.

    [:octicons-arrow-right-24: Read the standard](guide/standard.md)

</div>

## Reports - Windows and Linux, side by side

<div class="grid cards" markdown>

- :fontawesome-brands-windows: **Windows**

    Unit tests, coverage (JaCoCo and ReportGenerator), documentation coverage, Doxygen, Javadoc.

    [:octicons-arrow-right-24: Windows reports](reports/windows/index.md)

- :fontawesome-brands-linux: **Linux (also WSL)**

    The same set built on Linux - numbers and rendering can differ slightly.

    [:octicons-arrow-right-24: Linux reports](reports/linux/index.md)

- :material-help-circle: **Which report is which?**

    Native tool versus ReportGenerator, and why every report exists twice.

    [:octicons-arrow-right-24: Explained](guide/which-report.md)

- :material-api: **API docs**

    Doxygen and Javadoc, per platform.

    [:octicons-arrow-right-24: API docs](api.md)

- :material-download: **Downloads**

    Every release asset: apps, report archives, source, site, checksums.

    [:octicons-arrow-right-24: Downloads](downloads.md)

- :material-language-java: **Maven site (native)**

    Checkstyle, PMD, CPD, SpotBugs, Surefire, JXR - the Maven-only pages, in their own tab.

    [:octicons-arrow-right-24: Maven site](maven-site.md)

</div>

## The scripts in one table

Same number = same job in every course template; the platform is the suffix (`-windows.bat`, `-linux.sh`;
WSL is Linux).

| # | Job | Windows | Linux / WSL |
|---|---|---|---|
| 1 | Install the Git hooks | `1-configure-git-hooks-windows.bat` | `./1-configure-git-hooks-linux.sh` |
| 3 | Install the package manager | `3-install-package-manager-windows.bat` | - |
| 4 | Install the tools | `4-install-tools-windows.bat` | `./4-install-tools-linux.sh` |
| 5 | Format the code | `5-format-code-windows.bat` | `./5-format-code-linux.sh` |
| 6 | Build + unit tests (fast) | `6-build-and-test-windows.bat` | `./6-build-and-test-linux.sh` |
| 7 | Everything: reports, API docs, sites, `release/` | `7-build-all-windows.bat` | `./7-build-all-linux.sh` |
| 8 | Run the app | `8-run-app-windows.bat` | `./8-run-app-linux.sh` |
| 9 | Open the site on http://localhost | `9-open-site-windows.bat` | `./9-open-site-linux.sh` |
| 10 | Release with the GitHub CLI | `10-release-windows.bat` | `./10-release-linux.sh` |
| 11 | Clean | `11-clean-windows.bat` | `./11-clean-linux.sh` |
