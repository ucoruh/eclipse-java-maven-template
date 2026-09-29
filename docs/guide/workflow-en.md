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
| every push / PR | `.github/workflows/ci.yml`: `mvn clean test package` | GitHub Actions "Checks" tab; Surefire reports uploaded as an artifact only if it fails |
| `7-build-app.bat` / `.sh` (run by you, whenever) | full build: tests, JaCoCo, ReportGenerator (coverage), Doxygen, coverxygen, `genhtml`, ReportGenerator (doc-coverage), `mvn site`, `release/*.tar.gz` | `calculator-app/target/site/`, `release/` (both are gitignored - not committed) |
| a `vX.Y.Z` tag push, or a manual dispatch, of `.github/workflows/release.yml` | the same full pipeline as `7-build-app.sh`, then a GitHub Release with every report attached | the repo's **Releases** page |
| `10-release.bat` / `.sh` (run by you) | the same full pipeline, zipped as `release/site.zip`, published with `gh release create` | the repo's **Releases** page, without spending any Actions minutes |

CI (`ci.yml`) is deliberately lean: it only compiles and runs tests on every push, so it stays fast and does not
burn your (limited, on a private repo) Actions minutes. The full report/site/release pipeline only runs when you
actually want a release - see [releases-en.md](releases-en.md).

## Reading the reports

Open `calculator-app/target/site/index.html` (via `9-run-webpage.bat`/`.sh`) and start from **Which report is
which?** in the left menu - it explains every report on the site and which folder/file backs it. Short version:
- **Unit Tests -> Surefire Report**: did the tests pass, and what did each one assert.
- **Code Coverage -> JaCoCo / ReportGenerator**: same underlying data, two renderings; ReportGenerator additionally
  gives you badges and a history trend.
- **Documentation Coverage -> Coverxygen (genhtml / ReportGenerator)**: how much of your public API has a Javadoc
  comment - again the same data, two renderings.
- **API Docs -> Javadoc / Doxygen**: the actual API reference, in the Java-native format and in the
  cross-language-consistent format the other two course templates also use.
- **Code Quality -> Checkstyle / PMD / CPD / SpotBugs**: style, design smells, copy-paste, bug patterns -
  informational, they do not fail the build.

## Keeping coverage up

Run `7-build-app` after every meaningful change and glance at the coverage badges
(`assets/badge_linecoverage.svg` etc., also shown at the top of `README.md`) or the JaCoCo report. If a new method
has 0% coverage, it has no test yet - write one before moving on (see
[from-topic-en.md](from-topic-en.md#4-write-tests-first)).
