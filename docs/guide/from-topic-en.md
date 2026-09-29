# From a project topic to your own project

This walks through turning the `Calculator` sample into a real course project, using one concrete example topic:
**"Library Book Tracker"** (a small library catalog + loan tracker - swap in whatever topic you picked from the
course project guide, the steps are the same).

## Checklist

- [ ] Rename the Maven coordinates (`groupId`/`artifactId`) and the Java package
- [ ] Rename the source folders to match the new package
- [ ] Rename `Calculator` / `CalculatorApp` to your own domain classes
- [ ] Update `pom.xml`'s `<name>`/`<description>`/`<url>`/shade `mainClass`
- [ ] Update `Doxyfile`'s `PROJECT_NAME`/`PROJECT_BRIEF`/`INPUT`
- [ ] Update `calculator-app/src/site/site.xml`'s banner/links (or leave as-is - it is generic)
- [ ] Write tests **first** for each new module (normal, boundary, invalid input - see below)
- [ ] Keep running `7-build-app` after every change and check the coverage badges/reports
- [ ] Update `README.md`'s title and description
- [ ] Commit early, commit often (see [workflow-en.md](workflow-en.md))

## 1. Rename the Maven coordinates

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

If you rename the `artifactId`, also update every script that hard-codes `calculator-app-1.0-SNAPSHOT.jar`
(`8-run-app.bat`/`.sh`, `9-run-webpage.bat`/`.sh`, `7-build-app.bat`/`.sh`'s jar-check) and the `<mainClass>` above.

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

`Doxyfile`:
```
PROJECT_NAME    = "Library Book Tracker"
PROJECT_BRIEF   = "A small library catalog and loan tracker"
INPUT           = calculator-app/src/main/java
```
(`INPUT` can stay as-is if you keep the `calculator-app` folder name; rename it too - `git mv calculator-app
library-tracker-app` - if you want the folder to match, and then update every script/`pom.xml`/`Doxyfile`
reference to `calculator-app/`.)

## 6. Rebuild and check

```batch
7-build-app.bat
9-run-webpage.bat
```
Open the site, check the **Which report is which?** page, and confirm:
- Surefire report shows all your new tests, all green
- JaCoCo and ReportGenerator both show real coverage numbers for your new classes (not 0%, and not the old
  `Calculator` class - it should be gone)
- Javadoc and Doxygen both show your new classes with your new Javadoc comments

## 7. Keep going

- [workflow-en.md](workflow-en.md) - daily branch/commit/push loop and what CI does
- [releases-en.md](releases-en.md) - how to publish a graded snapshot
- [troubleshooting-en.md](troubleshooting-en.md) - fixes for the errors you are most likely to hit while doing
  all of the above
