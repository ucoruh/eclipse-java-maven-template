# Private repository: releases and the site

Your course repository is **private**, and most students have a plain **GitHub Free** account. This page explains
exactly what that does and does not let you do, and how this template works around the gaps.

## What works on Free vs Pro (facts, from GitHub's own docs)

| Feature | GitHub Free (private repo) | GitHub Pro / Team (or Free's Student Developer Pack, which grants Pro) |
|---|---|---|
| **Releases** (a tag + attached files, up to 2 GiB per file, up to 1000 assets) | **Works.** Visible to you and anyone you add as a collaborator. | Same, no difference. |
| **GitHub Pages** (a live `https://<user>.github.io/<repo>/` site) | **Does not work on a private repo.** | **Works**, once Pages is enabled for the repo. |
| **GitHub Actions minutes** | 2,000 minutes/month, 500 MB artifact storage | 3,000 minutes/month, 1 GB artifact storage |

The practical consequence: **Releases are how you hand in a browsable site on a private Free repo** - not Pages.
That is exactly what `10-release.bat`/`.sh` (and the `release.yml` Actions workflow) produce: every report,
packaged, attached to a GitHub Release, plus the whole site zipped as `site.zip` so it can be downloaded and
opened locally with no server needed (unzip -> open `index.html`).

## Getting GitHub Pages anyway: the Student Developer Pack

If you want a live Pages URL instead of (or in addition to) `site.zip`:

1. Go to <https://education.github.com/pack> and apply with your **university e-mail address**
   (`...@erdogan.edu.tr` or equivalent) - this is what GitHub checks first, fastest path to approval.
2. If asked for proof, a student ID photo or an enrollment document is usually enough.
3. Approval can take anywhere from a few minutes to a few days - do not wait on it before your first release;
   use `site.zip` in the meantime.
4. Once approved, your account has GitHub Pro. On your repo: **Settings -> Pages -> Source**, enable it (branch
   or Actions-based, your choice - `.github/workflows/pages.yml` publishes to the `gh-pages` branch, so "Deploy
   from a branch" -> `gh-pages` works out of the box).
5. Tell `pages.yml` it is allowed to run on your now-Pro-enabled private repo: **Settings -> Secrets and
   variables -> Actions -> Variables tab -> New repository variable**, name `PAGES_ON_PRIVATE`, value `true`.
   Without this, `pages.yml` skips the deploy on every push and explains why in the run's summary (see
   [workflow-en.md](workflow-en.md)) - this is on purpose, so a plain Free-tier private clone never wastes Actions
   minutes attempting a Pages deploy that would just fail.
6. Push to `main` (or re-run `pages.yml` manually from the **Actions** tab) - the site is live at
   `https://<your-username>.github.io/<your-repo>/` a minute or two later.

## Add the instructor as a collaborator

Grading needs to see your private releases. On your repo: **Settings -> Collaborators -> Add people**, add
`ucoruh` (or whichever GitHub username your instructor gives you), and wait for them to accept the invite. Without
this, your Releases page - and everything else in the repo - is invisible to the instructor.

## Installing and logging into the GitHub CLI (`gh`)

Windows:
```batch
where gh
```
If missing: `choco install gh -y` (also done by `4-install-required-apps.bat`).

Linux/WSL:
```bash
gh --version
```
If missing, `4-install-required-apps.sh` installs it via `apt`.

Then, **once**, on each machine you release from:
```bash
gh auth login
```
Answer the prompts: **GitHub.com** -> **HTTPS** -> **Login with a web browser** (easiest) -> follow the one-time
code it shows you into the browser tab it opens. Verify:
```bash
gh auth status
```
Expected output includes a line like `Logged in to github.com account <your-username>`.

## Publishing a release

```batch
10-release.bat v1.0.0
```
or, using the `VERSION` file already in the repo (bump it first):
```batch
10-release.bat
```
Both scripts:
1. **refuse to run on a dirty working tree** - commit or stash first, so a release always matches a real commit;
2. check `gh auth status` and tell you exactly how to log in if you are not;
3. run the full build (`7-build-app`) - jar, both coverage-report families, both documentation-coverage families,
   Javadoc + Doxygen, the Maven site;
4. zip the site as `release/site.zip`;
5. run `gh release create <version> release/* --title <version> --notes-file <generated notes>`.

**Always try `--dry-run` first** the first time you use it on a real project - it runs steps 1-4 and prints the
exact `gh release create` command and the asset list, but does not publish anything:
```batch
10-release.bat v1.0.0 --dry-run
```

This uses **zero GitHub Actions minutes** - everything runs on your machine, only the final `gh release create`
call talks to GitHub.

## The CI alternative: `release.yml`

`.github/workflows/release.yml` does the same full pipeline, but on GitHub's runners, triggered by pushing a
`v*` tag or by a manual dispatch from the **Actions** tab. It is a reasonable alternative if you prefer not to
install the full toolchain locally, but it does spend Actions minutes (roughly 4-6 per run - see the comment at
the top of the workflow file) - on Free's 2,000 min/month that is not a real concern for a handful of releases,
but do not wire it to run on every push.

## Troubleshooting {#troubleshooting}

| Symptom | Fix |
|---|---|
| `10-release` stops at "gh is not logged in to GitHub" | `gh auth login`, then `gh auth status` to confirm. |
| `gh release create` fails with `HTTP 404` | Usually means `gh` is authenticated against the wrong account, or the repo path/remote is wrong. Check `gh repo view` prints your repo. |
| `gh release create` fails with `HTTP 403` | You (or the account `gh` is logged in as) do not have write access to this repo - confirm you own it or were added as a collaborator with write access, not just read. |
| The instructor says they cannot see your release | You forgot to add them as a collaborator (see above), or the repo is private and they were never invited. |
| `gh release create` fails mentioning an asset is too large | GitHub's limit is 2 GiB **per file**. `release/*.tar.gz` and `site.zip` are normally a few MB for this template - if one balloons, check you are not accidentally packaging `target/` recursively into itself, or generated content that should have been gitignored. |
| Release succeeds but `site.zip` opens to a blank/broken page | Unzip it fully first (do not open `index.html` straight out of the zip viewer) - relative links to `css/`/`js/`/report subfolders need the sibling files to be extracted alongside it. |
