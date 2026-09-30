# Use this template

## 1. Create your own PRIVATE repository from it (not a fork)

On GitHub open the template repository, click the green **Use this template** button (top right, next to **Code**) ->
**Create a new repository**. Pick your account as **Owner**, a **Repository name** (e.g. `cen207-yourname-project`),
choose **Private**, and click **Create repository**.

Do **not** fork it: a fork of a public repository **cannot be made private**, while a repository created with "Use
this template" can - and student repositories on this course are private (see
[Releases and private repositories](releases-en.md) for what that means for reports and Pages, and
[Showing your project without GitHub Pages](showcase-en.md) for the local demo).

Then add the people who must see it: **Settings -> Collaborators -> Add people** -> the instructor `ucoruh` and your
team mates (they must accept the invitation).

## 2. Clone it

```bash
git clone https://github.com/<your-account>/<your-repo>.git
cd <your-repo>
```
This template has no submodules (script `0-init-submodules` exists only in the templates that do).

## 3. Configure the git hooks (once)

Windows: `1-configure-git-hooks-windows.bat`  -  Linux/WSL: `./1-configure-git-hooks-linux.sh`

This installs `pre-commit` (auto-formats staged Java/C/C++/C# files with Astyle and refuses to commit if
`.gitignore`, `README.md` or `Doxyfile` are missing) and `pre-push` into `.git/hooks/`.

## 4. Install the toolchain

Follow [install-en.md](install-en.md) if you have not already (`4-install-tools-windows.bat` /
`./4-install-tools-linux.sh`).

## 5. Name your project in `project.env`

```text
PROJECT_NAME=calculator
VERSION=1.1.0
GITHUB_REPO=<your-account>/<your-repo>
```
Every script and the CI workflow read this file: the asset names (`<PROJECT_NAME>-<VERSION>-...`), the release tag
(`v<VERSION>`) and the site links come from it. See [Naming standard](standard-en.md).

## 6. First build

Fast check (about a minute): build + unit tests + the runnable app.

Windows: `6-build-and-test-windows.bat`  -  Linux/WSL: `./6-build-and-test-linux.sh`

Expected end of the output:
```text
Build and tests OK.
  jar:      build\windows-release\
  app:      publish\windows-x64\  (run.bat)  and  release\
  tests:    reports\windows\tests-junit2html\index.html
```

Everything (tests, coverage with both tool families, API docs, documentation coverage, both sites, the `release/`
folder):

Windows: `7-build-all-windows.bat`  -  Linux/WSL: `./7-build-all-linux.sh`

It takes a few minutes on the first run (Maven and the report tools download their caches). Read the console output
from the top: every step is numbered `[n/9]` and stops with an `[ERROR]` line and a suggested fix the moment something
goes wrong (see [troubleshooting-en.md](troubleshooting-en.md)). When it ends without `[ERROR]` you have:

- a runnable jar: `build/<platform>-release/calculator-app-<VERSION>.jar` and the app folder `publish/<platform>-<arch>/`
- every report: `reports/<platform>/<kind>-<tool>/`
- the MkDocs site: `site/index.html`, the Maven site: `site-native/index.html`
- every release asset: `release/` (with `ASSETS.md` and `SHA256SUMS.txt`)

## 7. Run it and open the site

Windows:
```batch
8-run-app-windows.bat 6 "*" 7
9-open-site-windows.bat
```
Linux/WSL:
```bash
./8-run-app-linux.sh 6 "*" 7
./9-open-site-linux.sh
```
Expected: `6 * 7 = 42` (or similar), then the browser opens <http://localhost:8000/>. The site is served over http
because the report pages use frames and browsers block frames of `file://` pages. Options: `9-open-site-* --maven`
serves the Maven site alone, `--edit` starts the live-reloading MkDocs server while you write documentation, and a
number picks another port (`9-open-site-windows.bat 8080`).

## 8. Now make it your project

Continue with [from-topic-en.md](from-topic-en.md) to turn the `Calculator` sample into your own project topic.
When you are ready to show it: [Showing your project without GitHub Pages](showcase-en.md).
