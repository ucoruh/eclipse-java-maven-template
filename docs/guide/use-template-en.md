# Use this template

## 1. Create your own repository from it

On GitHub, open the template repository and click **Use this template -> Create a new repository**. Pick a name
(e.g. `cen429-yourname-project`), keep it **Private** (student repos on this course are private - see
[releases-en.md](releases-en.md) for what that means for reports/Pages), and create it.

Do **not** fork it - "Use this template" gives you a repository with no shared history with the original, which is
what you want for your own project.

## 2. Clone it

```bash
git clone https://github.com/<your-account>/<your-repo>.git
cd <your-repo>
```

## 3. Configure the git hooks (once)

Windows:
```batch
1-configure-git-hooks.bat
```
Linux/WSL:
```bash
./1-configure-git-hooks.sh
```

This installs `pre-commit` (auto-formats staged Java/C/C++/C# files with Astyle and refuses to commit if
`.gitignore`, `README.md` or `Doxyfile` are missing) and `pre-push` into `.git/hooks/`.

## 4. Install the toolchain

Follow [install-en.md](install-en.md) if you have not already.

## 5. First build

Windows:
```batch
7-build-app.bat
```
Linux/WSL:
```bash
./7-build-app.sh
```

This is the one script that does everything: `mvn clean test package`, Doxygen, both coverage-report families
(JaCoCo native + ReportGenerator), both documentation-coverage families (`genhtml` native + ReportGenerator), the
Javadoc/JXR/Checkstyle/PMD/SpotBugs reports, the full `mvn site`, and packages everything under `release/`. It
takes a minute or two on first run (Maven and the report tools download their own caches) and is fast on later
runs. Read its console output top to bottom - every step prints what it is about to do before doing it, and it
stops with a `[ERROR]` and a suggested fix the moment something goes wrong (see
[troubleshooting-en.md](troubleshooting-en.md) if the fix is not obvious).

If it finishes without an `[ERROR]` line, you have:
- a runnable jar: `calculator-app/target/calculator-app-1.0-SNAPSHOT.jar`
- a full report site: `calculator-app/target/site/index.html`
- everything packaged for a release: `release/*.tar.gz`

## 6. Run it and open the site

Windows:
```batch
8-run-app.bat 6 "*" 7
9-run-webpage.bat
```
Linux/WSL:
```bash
./8-run-app.sh 6 "*" 7
./9-run-webpage.sh
```

`9-run-webpage` opens the already-built static site. Pass `--serve` to instead run a live Maven site server at
<http://localhost:9000/> that rebuilds `src/site/*` on the fly while you edit it (useful when you are editing
`site.xml` or the markdown pages under `src/site/markdown/`).

## 7. Now make it your project

Continue with [from-topic-en.md](from-topic-en.md) to turn the `Calculator` sample into your own project topic.
