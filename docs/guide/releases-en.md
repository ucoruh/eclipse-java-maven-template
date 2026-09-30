# Releases and private repositories

Your course repository is **private**, and most students have a plain **GitHub Free** account. This page explains
exactly what that does and does not let you do, and how this template works around the gaps. The step-by-step
recipe for the project presentation is in [Showing your project without GitHub Pages](showcase-en.md).

## What works on Free vs Pro (facts, from GitHub's own docs)

| Feature | GitHub Free (private repo) | GitHub Pro / Team (or Free's Student Developer Pack, which grants Pro) |
|---|---|---|
| **Releases** (a tag + attached files, up to 2 GiB per file, up to 1000 assets) | **Works.** Visible to you and anyone you add as a collaborator. | Same. |
| **GitHub Pages** (a live `https://<user>.github.io/<repo>/` site) | **Does not work on a private repo.** | **Works**, once Pages is enabled for the repo. |
| **GitHub Actions minutes** | 2,000 minutes/month, 500 MB artifact storage | 3,000 minutes/month, 1 GB artifact storage |

Practical consequence: on a private Free repo the site is shown **locally** (`7-build-all-*` + `9-open-site-*`) and
handed in as `...-site.zip` inside the **Release**. The template repository itself is public, so its site is live at
<https://ucoruh.github.io/eclipse-java-maven-template/>.

## The release assets (local folder = GitHub release, one to one)

`7-build-all-<platform>` fills `release/`; `10-release-<platform>` and the CI workflow attach **exactly those files**.
Names follow `<project>-<version>[-<platform>[-<arch>]]-<content>[-<tool>].<ext>` (see
[Naming standard](standard-en.md)); for `calculator` 1.1.0:

| File | What it is |
|---|---|
| `calculator-1.1.0-windows-x64-app.zip` | the runnable application for Windows (jar + `run.bat`) |
| `calculator-1.1.0-linux-x64-app.tar.gz` | the same for Linux and WSL (jar + `run.sh`, keeps the exec bit) |
| `calculator-1.1.0-macos-arm64-app.tar.gz` | the same for macOS (built by CI only) |
| `calculator-1.1.0-<platform>-report-tests.zip` | unit-test report (junit2html) + raw JUnit XML |
| `calculator-1.1.0-<platform>-report-coverage-reportgenerator.zip` / `-report-coverage-jacoco.zip` | code coverage, both tool families |
| `calculator-1.1.0-<platform>-report-doccoverage-reportgenerator.zip` / `-report-doccoverage-lcov.zip` | documentation coverage, both families |
| `calculator-1.1.0-<platform>-api-doxygen.zip` / `-api-javadoc.zip` | API documentation |
| `calculator-1.1.0-site-maven.zip` | the Maven site (Checkstyle, PMD, CPD, SpotBugs, Surefire, JXR) |
| `calculator-1.1.0-site.zip` | the MkDocs site with both platforms' reports |
| `calculator-1.1.0-source.zip` | the source at this commit |
| `ASSETS.md`, `SHA256SUMS.txt` | the table of all of the above with site links; checksums |

`<platform>` is `windows` or `linux`. A local build has **one** platform's files plus the neutral ones - `ASSETS.md`
lists what is missing; CI builds every platform.

## Getting GitHub Pages anyway: the Student Developer Pack

1. Go to <https://education.github.com/pack> and apply with your **university e-mail address**.
2. If asked for proof, a student ID photo or an enrollment document is usually enough.
3. Approval takes minutes to days - do not wait for it; the local showcase and the release are enough.
4. Once approved your account has GitHub Pro. On your repo: **Settings -> Pages -> Source: Deploy from a branch ->
   `gh-pages`**. The CI workflow creates that branch on its first deploy.
5. Allow the deploy on a private repo: **Settings -> Secrets and variables -> Actions -> Variables -> New repository
   variable**, name `PAGES_ON_PRIVATE`, value `true`. Without it the workflow **skips** the Pages deploy on a private
   repo and says why in a notice and in the run summary (that message links to
   [Showing your project without GitHub Pages](showcase-en.md)) - on purpose, so a Free private repo never wastes
   minutes on a deploy that cannot work.
6. Push to `main`; the site is live a minute or two later at `https://<your-username>.github.io/<your-repo>/`.

## Add the instructor as a collaborator

**Settings -> Collaborators -> Add people**, add `ucoruh`, wait for the invitation to be accepted. Without it your
Releases (and everything else in the private repo) are invisible to the instructor.

## Installing and logging into the GitHub CLI (`gh`)

Windows: `where gh` - if missing, `choco install gh -y` (also done by `4-install-tools-windows.bat`).
Linux/WSL: `gh --version` - if missing, `4-install-tools-linux.sh` installs it.

Once per machine:
```bash
gh auth login
```
Choose **GitHub.com -> HTTPS -> Login with a web browser**, type the one-time code in the browser tab. Verify:
```bash
gh auth status
```
Expected: `Logged in to github.com account <your-username>`.

## Publishing a release from your machine

1. Edit `project.env` (`VERSION=1.2.0`), commit.
2. Dry run first - builds everything and only *prints* what it would publish:
   ```batch
   10-release-windows.bat --dry-run
   ```
3. Publish:
   ```batch
   10-release-windows.bat
   ```
   (`./10-release-linux.sh` on Linux/WSL.) The script refuses a dirty working tree, checks `gh auth status`, runs
   `7-build-all-*`, writes the release notes, and runs
   `gh release create v<VERSION> release/* --title ... --notes-file build/release-notes.md`. No Actions minutes are used.

## The CI workflow (`.github/workflows/ci.yml`)

One workflow, four jobs (see [Naming standard](standard-en.md#7-ci-in-one-picture)):

| Trigger | What happens |
|---|---|
| push to any branch / pull request | `windows`, `linux`, `macos` jobs build, test and produce reports; `site` merges them and builds the site (uploaded as an artifact) |
| push to `main` | the same, and the `site` job **deploys GitHub Pages** (`gh-pages` branch) |
| push of a `v*` tag (e.g. `v1.1.0`; must equal `project.env`) | the same, and the `site` job **publishes the GitHub Release** with every asset above |
| manual run (**Actions -> CI -> Run workflow**) | same as a push to `main`; tick *release* to also publish `v<VERSION>` |

**Cost:** a full run is roughly 12-20 Actions minutes counted across the four jobs (Windows minutes count double,
macOS ten times on private repos), which is small on the public template but worth knowing on a private Free repo
(2,000 min/month): push to a feature branch freely, tag only when you release. Artifacts are kept for 7 days.

**Private repository rule:** the workflow detects `github.event.repository.private`. On a private repo the Pages
deploy is skipped unless the repository variable `PAGES_ON_PRIVATE` is `true`; the skip is explained in a `::notice`
annotation and in `$GITHUB_STEP_SUMMARY` and points to [Showing your project without
GitHub Pages](showcase-en.md). Releases always run.

## Troubleshooting {#troubleshooting}

| Symptom | Fix |
|---|---|
| `10-release-*` stops at "gh is not logged in" | `gh auth login`, then `gh auth status`. |
| `gh release create` fails with `HTTP 404` | `gh` is logged into the wrong account, or the remote is wrong. `gh repo view` must print your repo. |
| `gh release create` fails with `HTTP 403` | the account `gh` uses has no write access to this repo (owner or collaborator with write). |
| `gh release create` says the tag already exists | raise `VERSION` in `project.env` (a tag is never re-used), commit, run again. |
| The instructor cannot see your release | add `ucoruh` as a collaborator (above) and make sure the invitation was accepted. |
| An asset is too large | GitHub's limit is 2 GiB per file; check that you are not packing `target/` or other generated folders into an archive. |
| CI: *tag v1.2.0 does not match project.env* | edit `project.env` to `VERSION=1.2.0` and tag that commit. |
| Release succeeds but `...-site.zip` shows empty report frames | unzip it fully and **serve** it (`python -m http.server --directory site`); frames do not load from `file://`. |
