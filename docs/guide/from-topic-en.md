# From a project topic to your own project

This walks through turning the `Calculator` sample into a real course project, using one concrete example topic:
**"Library Book Tracker"** (a small library catalog + loan tracker - swap in whatever topic you picked from the
course project guide, the steps are the same).

## Checklist

- [ ] Set your name in `project.env` (`PROJECT_NAME`, `VERSION`, `GITHUB_REPO`) - the ONE place for the project identity
- [ ] Rename the Maven `groupId` and the Java package
- [ ] Rename the source folders to match the new package
- [ ] Rename `Calculator` / `CalculatorApp` to your own domain classes
- [ ] Update `pom.xml`'s `<name>`/`<description>`/`<url>`/shade `mainClass`
- [ ] Update `Doxyfile`'s `PROJECT_NAME`/`PROJECT_BRIEF`/`INPUT`
- [ ] Update `calculator-app/src/site/site.xml`'s banner/links (or leave as-is - it is generic)
- [ ] Write tests **first** for each new module (normal, boundary, invalid input - see below)
- [ ] Keep running `6-build-and-test-*` after every change (and `7-build-all-*` before a push) and check the coverage badges/reports
- [ ] Update `README.md`'s title and description
- [ ] Commit early, commit often (see [workflow-en.md](workflow-en.md))

## 1. Name the project and the Maven coordinates

First `project.env` at the repository root - every script, the release asset names and the site read it:

```text
PROJECT_NAME=librarytracker
VERSION=0.1.0
GITHUB_REPO=<your-account>/<your-repo>
```

The assets then become `librarytracker-0.1.0-windows-x64-app.zip` and so on (see [Naming standard](standard-en.md)).

Then `calculator-app/pom.xml`:

In `calculator-app/pom.xml`:

```xml
<groupId>com.ucoruh.librarytracker</groupId>
<artifactId>library-tracker-app</artifactId>
<name>library-tracker-app</name>
<description>Library Book Tracker - term project</description>
```

The shade plugin's `mainClass` must point at your new entry-point class (step 3):

```xml
<mainClass>com.ucoruh.librarytracker.LibraryTrackerApp</mainClass>
```

**Simplest and safest: keep the module folder and `artifactId` as `calculator-app`** - the scripts, `Doxyfile`,
`mkdocs.yml` and CI refer to that folder, and the *names your users see* (assets, site, jar inside the app archive) come
from `PROJECT_NAME`, not from the `artifactId`. Change only `groupId`, `<name>`, `<description>` and the `<mainClass>`
above. (If you insist on renaming the folder too, search the repository for `calculator-app` and replace every hit in
the scripts, `Doxyfile`, `mkdocs.yml`, `.github/workflows/ci.yml` and `.gitignore`.)

## 2. Rename the package and folders

```bash
# from the repo root
git mv calculator-app/src/main/java/com/ucoruh/calculator calculator-app/src/main/java/com/ucoruh/librarytracker
git mv calculator-app/src/test/java/com/ucoruh/calculator calculator-app/src/test/java/com/ucoruh/librarytracker
```

Then update the `package com.ucoruh.calculator;` line at the top of every `.java` file you just moved to
`package com.ucoruh.librarytracker;`, and every `import com.ucoruh.calculator....` elsewhere.

## 3. Replace the sample classes with your domain

The template's split is intentional and mirrors what you should do:
- **library classes** (`Calculator`) hold the actual logic, are plain, return values instead of printing, and are
  thoroughly unit tested.
- the **app class** (`CalculatorApp`) is a thin entry point: it parses `args`, calls the library, prints the
  result - nothing else - and its parsing logic lives in a small testable method (`run(String[] args)`), **not**
  inside `main`, and it never reads from `System.in` (a script or CI job would hang forever if it did).

For "Library Book Tracker" that might become:
- `Book.java`, `Loan.java`, `LibraryCatalog.java` (the library: add/remove a book, check a book out, check it back
  in, list overdue loans - whatever your topic's course guide asks for) - each with a matching `*Test.java`.
- `LibraryTrackerApp.java` with a `static String run(String[] args)` that dispatches a small set of subcommands
  (e.g. `add-book`, `checkout`, `return`, `list-overdue`) to `LibraryCatalog`, and a `main` that just prints
  `run(args)`'s result - exactly like `CalculatorApp` does today.

## 4. Write tests first

For **every** public method of your library classes, write at minimum:
- a **normal** case (typical, expected input)
- a **boundary** case (empty collection, zero/one/many, first/last element, `Integer.MAX_VALUE`-style edges)
- an **invalid input** case (`null`, a book ID that does not exist, checking out an already-checked-out book) -
  assert it throws the exception you chose, or returns the error value you chose; do not let it throw an
  undocumented `NullPointerException` by accident.

`CalculatorTest.java` and `CalculatorAppTest.java` are worked examples of exactly this pattern (JUnit 5, `@Nested`
classes grouping normal/boundary/invalid cases, `assertThrows`, `@ParameterizedTest` with `@CsvSource` for
boundary tables) - copy the pattern, not the content.

## 5. Update Doxygen and the site

`Doxyfile` (the output folder and `PROJECT_NUMBER` come from the scripts - do not change those two lines):
```
PROJECT_NAME    = "Library Book Tracker"
PROJECT_BRIEF   = "A small library catalog and loan tracker"
INPUT           = calculator-app/src/main/java
```
The site: `mkdocs.yml` (`site_name`, `site_description`, `repo_url`) and the landing page `docs/index.md`; the Maven
site banner in `calculator-app/src/site/site.xml` is generic and can stay.

## 6. Rebuild and check

```batch
7-build-all-windows.bat
9-open-site-windows.bat
```
(`./7-build-all-linux.sh` and `./9-open-site-linux.sh` on Linux/WSL.)
Open the site, check the **Which report is which?** page, and confirm:
- the unit-test report shows all your new tests, all green
- JaCoCo and ReportGenerator both show real coverage numbers for your new classes (not 0%, and not the old
  `Calculator` class - it should be gone)
- Javadoc and Doxygen both show your new classes with your new Javadoc comments

## 7. Keep going

- [workflow-en.md](workflow-en.md) - daily branch/commit/push loop and what CI does
- [releases-en.md](releases-en.md) - how to publish a graded snapshot
- [troubleshooting-en.md](troubleshooting-en.md) - fixes for the errors you are most likely to hit while doing
  all of the above
