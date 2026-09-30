# Showing your project without GitHub Pages

Your course repository is **private**, and on **GitHub Free** a private repository cannot publish GitHub Pages.
That does not matter for the course: everything Pages would show, you can show **locally**, and everything you
would download from a release is already in your `release/` folder. This page is the exact recipe, and the demo
checklist for the project presentation.

## Why the repository is private, and how you create it (not a fork)

Create your repository with **Use this template**, not with **Fork**: a fork of a public repository cannot be made
private, while a repository created from a template can.

1. Open the template on GitHub: <https://github.com/ucoruh/eclipse-java-maven-template>.
2. Click the green **Use this template** button (top right, next to **Code**) -> **Create a new repository**.
3. Owner: your account. Repository name: e.g. `cen207-yourname-project`. Choose **Private**. Click **Create
   repository**.
4. In your new repository: **Settings -> Collaborators -> Add people**, add the instructor `ucoruh` (and your team
   mates). They must accept the invitation before they can see the repository.
5. Clone it and do the first build (see [Use the template](use-template-en.md)).

## Build and open the full site locally

Windows:
```batch
7-build-all-windows.bat
9-open-site-windows.bat
```
Linux / WSL:
```bash
./7-build-all-linux.sh
./9-open-site-linux.sh
```

`7-build-all-*` builds the application, runs the tests, produces every report and API doc, builds the MkDocs site
(`site/`) and the Maven site (`site-native/`) and fills the `release/` folder. `9-open-site-*` serves the site on
**http://localhost:8000/** and opens it in your browser (open the address by hand if it does not open). Keep the
window open while you present; **CTRL+C** stops the server.

Why a server and not a double-click on `index.html`? The report pages show the reports in frames, and browsers block
frames of `file://` pages: you would see empty frames.

Expected output at the end of `7-build-all-*`:
```text
Operation completed.
  Site:        site/index.html
  Maven site:  site-native/index.html
  Reports:     reports/<your platform>/
  Release:     release/          (ASSETS.md lists every file)
```

## The demo checklist

Have `7-build-all-*` finished and `9-open-site-*` running **before** you start (do not build in front of the class).

1. **Site home** (`http://localhost:8000/`): badges, hero, the menu (Home, Guide, Kılavuz, Reports, API docs,
   Downloads, Maven site).
2. **Each report page** under **Reports -> Windows** or **Linux** (whichever you built on): unit tests (all green?),
   coverage with JaCoCo and with ReportGenerator (same numbers?), documentation coverage with genhtml and with
   ReportGenerator. Say in one sentence what each shows and which lines are red.
3. **API docs**: open **API docs** -> Doxygen and Javadoc; find one of *your* classes and show its comment.
4. **Maven site**: **Maven site (native)** -> *Open the Maven site* (a new tab) -> Checkstyle / PMD / SpotBugs; explain
   one finding and what you did about it.
5. **The `release/` folder** in your file explorer or terminal (`dir release` / `ls -l release`): show every file
   and open `ASSETS.md`; mention `SHA256SUMS.txt`.
6. **Run the application from the release archive**, not from the source tree: unzip
   `release/<project>-<version>-windows-x64-app.zip` (or untar the `linux` one), run `run.bat 6 "*" 7` (or
   `./run.sh 6 "*" 7`) and show the result.
7. **Verify a checksum** (optional, 30 seconds): Windows `Get-FileHash release\<file> -Algorithm SHA256`, Linux
   `sha256sum -c SHA256SUMS.txt`.

The other platform's reports are missing locally (one machine = one platform); `ASSETS.md` says so. When CI is green
the GitHub release has both - open the release page as the last item.

## The same files in a GitHub Release (works on private repositories)

A release is a tag plus attached files; it works on private repositories on GitHub Free and is visible to your
collaborators (the instructor).

```batch
10-release-windows.bat --dry-run
10-release-windows.bat
```
(`./10-release-linux.sh` on Linux/WSL.) `--dry-run` builds everything and prints the exact `gh release create`
command and the file list without publishing. The real run publishes `v<VERSION from project.env>` with **every file
of `release/`**. You need the GitHub CLI logged in once: `gh auth login` - see [Releases and private
repositories](releases-en.md).

## If you have GitHub Pro (Student Developer Pack)

Then the live site is possible too: see [Releases and private repositories](releases-en.md), section *Getting
GitHub Pages anyway*. Until then, this local showcase is fully sufficient.

## Problems

| Symptom | Fix |
|---|---|
| `9-open-site-*` says `site/index.html not found` | run `7-build-all-*` first |
| Empty frames on a report page | you opened `site/index.html` by double-click; use `9-open-site-*` (http://localhost) |
| `Address already in use` | another server uses port 8000: `9-open-site-windows.bat 8080` (any free port) |
| One platform's report pages say *Not available in this build* | expected: that platform was not built on this machine; CI builds both |
