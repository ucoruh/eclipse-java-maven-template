# Daily workflow and reports

## Branch, commit, push

```bash
git checkout -b feature/checkout-book
# ... edit, add tests ...
git add -A
git commit -m "Add LibraryCatalog.checkOut with overdue tracking"
git push -u origin feature/checkout-book
```

The `pre-commit` hook (installed by `1-configure-git-hooks-*`) runs Astyle on every staged `.java`/`.c`/`.cpp`/`.h`
file and refuses the commit if it cannot format cleanly, or if `.gitignore`/`README.md`/`Doxyfile` are missing.
Open a pull request into `main` when the branch is ready; merge it once CI is green.

## What runs where

| When | What runs | Where the output lands |
|---|---|---|
| every `git commit` | Astyle formatting check (`pre-commit` hook) | in place, on your files |
| you, many times a day | `6-build-and-test-windows.bat` / `./6-build-and-test-linux.sh` (about a minute): build + JUnit tests + jar + test report | `build/<platform>-release/`, `reports/<platform>/tests-junit2html/`, `publish/<platform>-<arch>/` |
| you, before a push or a demo | `7-build-all-windows.bat` / `./7-build-all-linux.sh`: everything - coverage (JaCoCo + ReportGenerator), Doxygen, Javadoc, documentation coverage (genhtml + ReportGenerator), Maven site, MkDocs site, `release/` | `reports/<platform>/`, `site/`, `site-native/`, `release/` (all gitignored) |
| every push / PR | `.github/workflows/ci.yml`: `windows`, `linux`, `macos` jobs, then `site` (merge + link check) | GitHub Actions run; the merged site is an artifact |
| push to `main` | the same, and the `site` job deploys GitHub Pages | `https://<owner>.github.io/<repo>/` (skipped on a private repo, see [Releases](releases.md)) |
| a `vX.Y.Z` tag | the same, and the `site` job publishes the GitHub Release with every asset | the repo's **Releases** page |
| `10-release-*` (you) | build everything locally and `gh release create` | the repo's **Releases** page, no Actions minutes |

## Reading the reports

Run `9-open-site-windows.bat` / `./9-open-site-linux.sh` (it serves the site on http://localhost:8000/) and start
from **Which report is which?** under **Reports**. Short version:

- **Unit tests** (`tests-junit2html`): did the tests pass, what did each assert.
- **Coverage**: JaCoCo and ReportGenerator show the same data two ways; ReportGenerator adds badges and a history.
- **Documentation coverage**: how much of your public API has a doc comment - genhtml and ReportGenerator, same data.
- **API docs**: Javadoc (Java-native) and Doxygen (the same tool the C/C++ and C# templates use).
- **Maven site** (opens in its own tab): Checkstyle, PMD, CPD, SpotBugs, JXR, Surefire - informational, they never
  fail the build.

Reports exist twice - **Windows** and **Linux** - because the results can differ. Read both when they disagree.

## Showing an HTML report inside your site

The site is MkDocs Material. The report pages under **Reports -> Windows / Linux** are **generated** by
`scripts/assemble.py site` (called by `7-build-all-*`); this section shows what such a page is, how to add your own
report, and how to test it.

**When to use an iframe, and when not.** Every report that is **not a Maven-site page** goes into an `<iframe>`, in
both sites: JaCoCo, ReportGenerator, genhtml, junit2html, Javadoc, Test Javadoc, Doxygen, JXR Source Xref / Test Source
Xref (and OpenCppCoverage in the C++ template). A page the Maven site renders itself with its own menu - Surefire,
Checkstyle, PMD, CPD, SpotBugs, project info, dependencies, plugins, SCM - is **never framed** (a site inside the site,
two menus, two banners): link it so it opens in a new tab (see the "right / wrong" example in
[Naming standard](standard.md#6-site-rules-what-is-framed-and-what-is-not)). In the Maven native site the frames are
tiny wrapper pages in `frames/`, generated from the same `REPORTS` list (`scripts/assemble.py prep`), so a new report
gets its MkDocs page **and** its Maven wrapper from one entry.

**1. The page.** Each report page is a small Markdown file with raw HTML, e.g.
`docs/reports/linux/coverage-jacoco/index.en.md` / `index.tr.md` (generated - do not edit it, edit the template in
`scripts/assemble.py`, function `report_page`):

```html
# Code coverage - JaCoCo - Linux

<div class="report-toolbar">
<a class="md-button md-button--primary" href="html/index.html" target="_blank" rel="noopener">Open in a new tab</a>
<a class="md-button" href="https://github.com/<owner>/<repo>/releases/download/v1.1.0/calculator-1.1.0-linux-report-coverage-jacoco.zip">Download (zip)</a>
</div>

<p class="report-explainer">One sentence: what the report shows.</p>

<div class="report-frame-wrap">
<iframe class="report-frame" src="html/index.html" title="JaCoCo coverage (linux)" loading="lazy"></iframe>
</div>

<p class="report-fallback">If the frame stays empty, <a href="html/index.html">open the report directly</a>.</p>
```

The raw report is copied next to the page as `html/`, so the frame's path `html/index.html` is **relative** and
works both on GitHub Pages (`/<repo>/reports/linux/coverage-jacoco/`) and on `http://localhost:8000/`.

**2. Add a new report.**

1. Make your tool write standalone HTML into `reports/<platform>/<kind>-<tool>/` (e.g. `reports/linux/mutation-pitest/`)
   in both `7-build-all-windows.bat` and `7-build-all-linux.sh`.
2. Add one entry to the `REPORTS` list at the top of `scripts/assemble.py` (folder key, title, one-line explanation,
   entry file, asset name) and its Turkish title/text in `TR_TITLE` / `TR_WHAT`. That gets you the frame page, the zip in `release/`, the row in `ASSETS.md` and the
   downloads table.
3. Add the page to the `nav:` of `mkdocs.yml` under Reports -> Windows and Linux.

**3. Test it locally.** `7-build-all-*` then `9-open-site-*`: the site is served over http on port 8000. Browsers
refuse to load an `<iframe>` from a `file://` page, so double-clicking `site/index.html` shows empty frames - always
go through `http://localhost:8000/`.

**Common problems.**

| Symptom | Cause / fix |
|---|---|
| Empty frame, "Open in a new tab" works | the site was opened via `file://`; use `9-open-site-*` |
| Empty frame over http | the report folder was not generated or copied: check `reports/<platform>/<kind>-<tool>/index.html` exists and re-run `7-build-all-*` |
| 404 for the report | an absolute path (`/html/...`); keep frame paths relative - GitHub Pages serves under `/<repo>/` |
| Blank frame with a "refused to connect" message | the report tool sends `X-Frame-Options`; standalone file reports do not, so this means you framed a **server** page - open it in a new tab instead |
| `mkdocs build --strict` warns about a missing file | a page listed in `nav:` was not generated; add the report to `REPORTS` in `assemble.py` |

## Keeping coverage up

Run `6-build-and-test-*` after every meaningful change and `7-build-all-*` before you push; glance at the coverage
badges (`assets/badge_linecoverage.svg` etc., also at the top of `README.md`) or the JaCoCo page. A new method with 0%
coverage has no test yet - write one before moving on (see [from-topic.md](from-topic.md#4-write-tests-first)).
