# Which report is which?

Every report is produced **on Windows and on Linux** and kept separately (**Reports → Windows / Linux** in the
menu): the numbers usually match, but line endings, paths and tool versions can make them differ, so both sets
are shown. Most reports are produced **twice**, once with the Java ecosystem's own ("native") tool and once with
a cross-ecosystem tool (ReportGenerator, Doxygen) so you can compare them.

| What it shows | Native tool (folder) | Alternative tool (folder) |
|---|---|---|
| Did the tests pass? Which test asserted what? | **junit2html** on the Surefire XML (`tests-junit2html`) — plus the Maven *Surefire* page in the [Maven site](../maven-site.md) | — |
| Which lines / branches / methods did the tests execute? | **JaCoCo** HTML (`coverage-jacoco`) | **ReportGenerator** HTML with badges and a history trend (`coverage-reportgenerator`) |
| How much of the public API carries a doc comment? | **coverxygen → lcov → genhtml** (`doccoverage-lcov`) | the same lcov file rendered by **ReportGenerator** (`doccoverage-reportgenerator`) |
| API reference (classes, methods, parameters) | **Javadoc** (`api-javadoc`) | **Doxygen** (`api-doxygen`) — the tool the C/C++ and C# templates use too |
| Code style, design smells, copy-paste, bug patterns | — | **Maven site**: Checkstyle, PMD, CPD, SpotBugs (Java only) — open in their own tab |
| Cross-referenced source (main and test), Test Javadoc | **JXR** `api-xref-jxr`, `api-xreftest-jxr`; **Javadoc** `api-testjavadoc` | — |

The folder names follow `reports/<platform>/<kind>-<tool>/`, e.g. `reports/linux/coverage-jacoco/`.

## Why two tools for one page?

- The **native** tool needs nothing beyond the JDK and the Maven plugins already declared in `pom.xml`.
- **ReportGenerator** is one tool for every language (the C++ and C# templates use it too). It adds **badges** for the
  README and a **history** of coverage over many builds. Same data, different presentation — comparing both is a
  good exercise in reading a coverage report critically.

## Shown in a frame, or opened as its own site?

Two kinds of HTML exist, and the site treats them differently:

| Kind | Examples | How this site shows it |
|---|---|---|
| **Every report that is not a Maven-site page** (standalone HTML without a site menu) | JaCoCo, ReportGenerator, genhtml, junit2html, Javadoc, Test Javadoc, Doxygen, JXR Source Xref / Test Source Xref | a page in the `<iframe>` of **both** sites: this one (title, explanation, *Open in a new tab*, *Download*) and, through a small wrapper page, the Maven native site |
| **A page the Maven site renders itself, with its own menu** | Surefire, Checkstyle, PMD, CPD, SpotBugs, project info, dependencies, plugins, SCM | **never framed** — a link that opens the Maven site in a new tab |

A framed Maven page would show *a site inside a site* (two menus, two banners, a scrollbar in a scrollbar). See
*Naming standard and site rules* for the right/wrong example.

## Where the raw data comes from

```text
calculator-app/target/surefire-reports/*.xml   <- Surefire: raw JUnit XML (junit2html renders it)
calculator-app/target/site/jacoco/jacoco.xml    <- JaCoCo: raw coverage XML (ReportGenerator reads it)
reports/<platform>/api-doxygen/xml/             <- Doxygen: inventory of doc comments (coverxygen reads it)
reports/<platform>/doccoverage-lcov/lcov.info   <- coverxygen: lcov file (genhtml AND ReportGenerator read it)
```

If a page is empty or missing, re-run `7-build-all-windows.bat` (Windows) or `./7-build-all-linux.sh` (Linux/WSL) and
read its console output from the top — every step announces itself as `[n/9]`.
