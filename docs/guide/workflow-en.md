# Daily workflow

## Branch, commit, push

```bash
git checkout -b feature/checkout-book
# ... edit, add tests ...
git add -A
git commit -m "Add LibraryCatalog.checkOut with overdue tracking"
git push -u origin feature/checkout-book
```

The `pre-commit` hook (installed by `1-configure-git-hooks`) runs Astyle on every staged `.java`/`.c`/`.cpp`/`.h`
file and refuses the commit if it cannot format cleanly, or if `.gitignore`/`README.md`/`Doxyfile` are missing.
Open a pull request into `main` when the branch is ready; merge it once CI is green.

## What runs where

| When | What runs | Where the output lands |
|---|---|---|
| every `git commit` | Astyle formatting check (`pre-commit` hook) | in place, on your files |
| every push / PR | `.github/workflows/ci.yml` job `build`: `mvn clean test package` | GitHub Actions "Checks" tab; Surefire reports uploaded as an artifact only if it fails |
| every push / PR | `.github/workflows/ci.yml` job `site`: the full report/site pipeline (see below) | a downloadable `maven-site-preview` artifact on the run, so a reviewer can preview the site from a PR |
| `7-build-app.bat` / `.sh` (run by you, whenever) | full build: tests, JaCoCo, ReportGenerator (coverage + badge), Doxygen, coverxygen, `genhtml`, ReportGenerator (doc-coverage + badge), `mvn site`, per-report `downloads/*.zip`, `release/*.tar.gz` | `calculator-app/target/site/`, `release/` (both are gitignored - not committed) |
| every push to `main`, or a manual dispatch, of `.github/workflows/pages.yml` | the same full pipeline, published to the `gh-pages` branch (skipped with an explanation on a private repo unless the `PAGES_ON_PRIVATE` repository variable is `true`) | `https://<owner>.github.io/<repo>/` |
| a `vX.Y.Z` tag push, or a manual dispatch (with a `version` input), of `.github/workflows/release.yml` | the same full pipeline, then a GitHub Release with every report attached as its own named asset | the repo's **Releases** page |
| `10-release.bat` / `.sh` (run by you) | the same full pipeline, zipped as `release/site.zip`, published with `gh release create` | the repo's **Releases** page, without spending any Actions minutes |

CI's `build` job is deliberately lean: it only compiles and runs tests on every push, so it stays fast and does not
burn your (limited, on a private repo) Actions minutes. CI's `site` job, `pages.yml` and `release.yml` all run the
same heavier pipeline (Doxygen, ReportGenerator, coverxygen/`genhtml`, `mvn site`) - `site` uploads it as a
preview artifact, `pages.yml` publishes it live, `release.yml` attaches it to a release. See
[releases-en.md](releases-en.md) for the private-repo/GitHub Free implications of each.

## Reading the reports

Run `9-run-webpage.bat`/`.sh` (it serves the site over a local HTTP server and opens it - see below for why) and
start from **Which report is which?** in the left menu - it explains every report on the site and which
folder/file backs it. Short version:
- **Unit Tests -> Surefire Report**: did the tests pass, and what did each one assert.
- **Code Coverage -> JaCoCo / ReportGenerator**: same underlying data, two renderings; ReportGenerator additionally
  gives you badges and a history trend.
- **Documentation Coverage -> Coverxygen (genhtml / ReportGenerator)**: how much of your public API has a Javadoc
  comment - again the same data, two renderings.
- **API Docs -> Javadoc / Doxygen**: the actual API reference, in the Java-native format and in the
  cross-language-consistent format the other two course templates also use.
- **Code Quality -> Checkstyle / PMD / CPD / SpotBugs**: style, design smells, copy-paste, bug patterns -
  informational, they do not fail the build.

Every one of these also has its own page **inside the site**, under the **Reports** menu, showing the report in a
framed, scrollable viewer with "Open in a new tab" and "Download (zip)" buttons - see the next section for how
that is built, in case you want to add a report of your own.

## Showing an HTML report inside your site

Every report page under the **Reports** menu (`calculator-app/src/site/markdown/reports/*.html` once built) is a
small hand-written page, not something Maven generates automatically. This is how one is built, using the
JaCoCo report page as a worked example, and how to add a new one.

**1. The markdown source** - `calculator-app/src/site/markdown/reports/jacoco.md`:

```markdown
# Code Coverage: JaCoCo (native)

<div class="report-toolbar">
<a class="btn" href="../jacoco/index.html" target="_blank" rel="noopener">Open in a new tab</a>
<a class="btn" href="../downloads/jacoco.zip">Download (zip)</a>
</div>

<p class="report-explainer">One sentence: what this report shows and why it matters.</p>

<div class="report-frame-wrap">
<iframe class="report-frame" src="../jacoco/index.html" title="JaCoCo coverage report" loading="lazy"></iframe>
</div>

<p class="report-fallback">If the report above does not load (some browsers block framed pages), <a
href="../jacoco/index.html">open it directly</a>.</p>
```

Doxia's Markdown parser passes standalone, blank-line-separated HTML blocks straight through, which is how the
`<div>`/`<iframe>` markup survives into the generated page unchanged. The paths are **relative to
`reports/<name>.html`**, i.e. one level below the site root, so a report that lives at
`calculator-app/target/site/jacoco/index.html` is `../jacoco/index.html` from here - the same relative path works
unchanged locally and on GitHub Pages (`/<repo>/reports/jacoco.html` and `/<repo>/jacoco/index.html` are still one
level apart). The `.report-toolbar`, `.report-frame-wrap`, `.report-frame` etc. classes are styled once, for every
report page, in `calculator-app/src/site/resources/css/site.css`.

**2. The menu entry** - add a line to the `Reports` `<menu>` in `calculator-app/src/site/site.xml`:

```xml
<item name="Coverage: JaCoCo (native)" href="reports/jacoco.html" />
```

**3. The download button's target** - `../downloads/jacoco.zip` is produced by `7-build-app.bat`/`.sh` (the step
titled "Bundle each report into ... downloads/*.zip"): a directory-shaped report (JaCoCo, ReportGenerator,
coverxygen, Javadoc, Doxygen) is zipped as-is; a single-file report generated straight at the site root
(Surefire, Checkstyle, PMD, CPD, SpotBugs) is bundled together with the site's shared `css/`/`images/` folders
first, so it still renders correctly when unzipped and opened on its own. If you add a genuinely new report, add
one more `tar -a -cf` (Windows) / `zip -rq` (Linux, via the `zip_dir` helper) line next to the existing ones.

**4. Testing it locally** - `9-run-webpage.bat`/`.sh` (no arguments) serves `calculator-app/target/site/` with
`python -m http.server` and prints the URL to open. This step is not optional: browsers block an `<iframe>` from
loading a `file://` page for security reasons, so double-clicking `index.html` will show a blank frame on every
report page - you must go through `http://localhost:8000/` (or whatever port you passed) for the frames to load.

**Common problems**:
- **Blank iframe, "Open in a new tab" works fine** - you opened the site via `file://` instead of
  `9-run-webpage`. Use the local HTTP server.
- **Blank iframe even over `http://`** - the report folder was not actually generated/copied. Check that
  `calculator-app/target/site/<folder>/index.html` exists; if not, re-run `7-build-app` and read its console
  output for the step that failed.
- **404 for the report** - a stale absolute or `/repo`-prefixed path. Keep paths relative (`../folder/...`), not
  absolute (`/folder/...`) - GitHub Pages serves the site from a `/<repo>/` sub-path, so an absolute path breaks
  there even though it works locally.
- **"Download (zip)" 404s** - the zip is produced by `7-build-app`'s bundling step, not by `mvn site` alone;
  re-run `7-build-app` (running `mvn site` on its own will not create `target/site/downloads/`).

## Keeping coverage up

Run `7-build-app` after every meaningful change and glance at the coverage badges
(`assets/badge_linecoverage.svg` etc., also shown at the top of `README.md`) or the JaCoCo report. If a new method
has 0% coverage, it has no test yet - write one before moving on (see
[from-topic-en.md](from-topic-en.md#4-write-tests-first)).
