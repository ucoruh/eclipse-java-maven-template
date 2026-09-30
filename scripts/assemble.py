#!/usr/bin/env python3
"""Platform-neutral packaging helper for the numbered build scripts and the CI workflow.

The .bat / .sh scripts run the real tools (Maven, Doxygen, ReportGenerator, coverxygen, genhtml, junit2html).
This file does the parts that must be *identical* on Windows, Linux and CI: staging, zipping, the MkDocs report
pages, the asset table and the checksums. It uses only the Python standard library.

Commands (run from the repository root, e.g.  py -3.12 scripts/assemble.py app --platform windows):
  prep                          copy logos/badges into docs/assets and the Maven site resources
  app       --platform P [--arch A]   stage publish/P-A/ and pack release/<name>-<ver>-P-A-app.(zip|tar.gz)
  reports   --platform P              zip every reports/P/<kind>-<tool>/ into release/
  site                                stage docs/ for MkDocs: report pages (both platforms), Maven site, downloads
  finalize                            link check, source zip, site.zip, site-maven.zip, ASSETS.md, SHA256SUMS.txt
  notes                               write build/release-notes.md (used by the CI release step)
  info                                print the values read from project.env

Naming (see docs/guide/standard-en.md):  <project>-<version>[-<platform>[-<arch>]]-<content>[-<tool>].<ext>
"""
import argparse
import hashlib
import html
import io
import os
import platform as _platform
import shutil
import subprocess
import sys
import tarfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLATFORMS = ["windows", "linux"]  # platforms that produce reports
PLATFORM_TITLE = {"windows": "Windows", "linux": "Linux", "macos": "macOS"}

# key = <kind>-<tool> folder under reports/<platform>/
#   root  : sub-folder of that folder that holds the standalone HTML ('' = the folder itself)
#   entry : the HTML file that opens the report
#   asset : the content/tool part of the release asset name (-> <project>-<ver>-<platform>-<asset>.zip)
REPORTS = [
    dict(key="tests-junit2html", group="Unit tests", tool="junit2html", root="", entry="index.html",
         asset="report-tests",
         title="Unit test results",
         what="Every JUnit 5 test that ran (passed, failed, skipped), how long each took, and the failure text when "
              "something broke. Rendered by <code>junit2html</code> from the Surefire XML files; the raw XML is "
              "in the download too."),
    dict(key="coverage-jacoco", group="Code coverage", tool="JaCoCo (native)", root="", entry="index.html",
         asset="report-coverage-jacoco",
         title="Code coverage - JaCoCo",
         what="Which lines, branches and methods the unit tests actually executed, colour-coded straight onto the "
              "source (green = covered, red = missed). JaCoCo is the Java-native coverage tool."),
    dict(key="coverage-reportgenerator", group="Code coverage", tool="ReportGenerator", root="", entry="index.html",
         asset="report-coverage-reportgenerator",
         title="Code coverage - ReportGenerator",
         what="The same JaCoCo coverage data rendered by ReportGenerator: summary cards, risk hot spots, a history "
              "trend across builds and the README badges."),
    dict(key="doccoverage-lcov", group="Documentation coverage", tool="coverxygen + genhtml", root="",
         entry="index.html", asset="report-doccoverage-lcov",
         title="Documentation coverage - coverxygen + genhtml",
         what="How much of the public API carries a documentation comment. coverxygen reads the Doxygen XML and writes "
              "an lcov file; <code>genhtml</code> (the lcov tool) renders it like a code-coverage report."),
    dict(key="doccoverage-reportgenerator", group="Documentation coverage", tool="coverxygen + ReportGenerator",
         root="", entry="index.html", asset="report-doccoverage-reportgenerator",
         title="Documentation coverage - ReportGenerator",
         what="The same documentation-coverage data (same lcov file) rendered by ReportGenerator instead of genhtml."),
    dict(key="api-doxygen", group="API documentation", tool="Doxygen", root="html", entry="index.html",
         asset="api-doxygen",
         title="API documentation - Doxygen",
         what="The public API of the library as Doxygen renders it: classes, methods, parameters, call/collaboration "
              "graphs when Graphviz is installed. The same tool the C/C++ and C# templates use."),
    dict(key="api-javadoc", group="API documentation", tool="Javadoc (native)", root="", entry="index.html",
         asset="api-javadoc",
         title="API documentation - Javadoc",
         what="The Java-native API reference generated from the <code>/** ... */</code> comments by the JDK's "
              "<code>javadoc</code> tool."),
]
NEUTRAL_ASSETS = [
    ("source.zip", "-", "Source code at this commit (git archive)", "git archive", ""),
    ("site.zip", "-", "The whole MkDocs site with BOTH platforms' reports - unzip and serve it (see the guide "
                      "'Showing your project without GitHub Pages')", "MkDocs Material", ""),
    ("site-maven.zip", "-", "The native Maven site: project info, Surefire, JaCoCo, Javadoc, JXR, Checkstyle, PMD, "
                            "CPD, SpotBugs", "mvn site (Fluido)", "maven-site/"),
    ("ASSETS.md", "-", "This table", "-", "downloads/"),
    ("SHA256SUMS.txt", "-", "SHA-256 checksums of every other asset", "sha256", ""),
]


# ----------------------------------------------------------------------------- basics
def read_env():
    env = {}
    p = ROOT / "project.env"
    if not p.exists():
        sys.exit("[ERROR] project.env not found in " + str(ROOT))
    for line in p.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip()
    for need in ("PROJECT_NAME", "VERSION"):
        if not env.get(need):
            sys.exit("[ERROR] %s is missing in project.env" % need)
    env.setdefault("GITHUB_REPO", "")
    return env


ENV = read_env()
NAME = ENV["PROJECT_NAME"]
VER = ENV["VERSION"].lstrip("v")
REPO = ENV["GITHUB_REPO"]
OWNER, _, REPO_NAME = REPO.partition("/")
PAGES_URL = "https://%s.github.io/%s/" % (OWNER, REPO_NAME) if REPO else ""
RELEASE_URL = "https://github.com/%s/releases/download/v%s/" % (REPO, VER) if REPO else ""
RELEASE_PAGE = "https://github.com/%s/releases/tag/v%s" % (REPO, VER) if REPO else ""
REL = ROOT / "release"
DOCS = ROOT / "docs"


def arch_auto():
    m = _platform.machine().lower()
    return "arm64" if m in ("arm64", "aarch64") else "x64"


def asset(platform=None, arch=None, content="", ext="zip"):
    """calculator-1.1.0[-platform[-arch]]-content.ext"""
    parts = [NAME, VER]
    if platform:
        parts.append(platform)
    if arch:
        parts.append(arch)
    parts.append(content)
    return "-".join(parts) + "." + ext


def log(msg):
    print(msg, flush=True)


def rmtree(p):
    if Path(p).exists():
        shutil.rmtree(p, ignore_errors=True)


def make_zip(src_dir, out_file, exec_names=()):
    src_dir, out_file = Path(src_dir), Path(out_file)
    out_file.parent.mkdir(parents=True, exist_ok=True)
    if out_file.exists():
        out_file.unlink()
    with zipfile.ZipFile(out_file, "w", zipfile.ZIP_DEFLATED) as z:
        for f in sorted(src_dir.rglob("*")):
            if f.is_file():
                z.write(f, f.relative_to(src_dir).as_posix())
    log("  packed %s (%s)" % (out_file.name, human(out_file.stat().st_size)))


def make_targz(src_dir, out_file):
    """tar.gz that keeps the exec bit on *.sh / launchers."""
    src_dir, out_file = Path(src_dir), Path(out_file)
    out_file.parent.mkdir(parents=True, exist_ok=True)
    if out_file.exists():
        out_file.unlink()
    with tarfile.open(out_file, "w:gz") as t:
        for f in sorted(src_dir.rglob("*")):
            ti = t.gettarinfo(str(f), arcname=f.relative_to(src_dir).as_posix())
            ti.uid = ti.gid = 0
            ti.uname = ti.gname = ""
            if f.is_file():
                ti.mode = 0o755 if f.suffix in (".sh",) else 0o644
                with open(f, "rb") as fh:
                    t.addfile(ti, fh)
            else:
                ti.mode = 0o755
                t.addfile(ti)
    log("  packed %s (%s)" % (out_file.name, human(out_file.stat().st_size)))


def human(n):
    for u in ("B", "KB", "MB", "GB"):
        if n < 1024 or u == "GB":
            return "%.0f %s" % (n, u) if u == "B" else "%.1f %s" % (n, u)
        n /= 1024.0


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


# ----------------------------------------------------------------------------- prep
def cmd_prep(_a):
    (DOCS / "assets").mkdir(parents=True, exist_ok=True)
    for f in ("rteu_logo.jpg", "favicon.png"):
        if (ROOT / "assets" / f).exists():
            shutil.copy2(ROOT / "assets" / f, DOCS / "assets" / f)
    for f in (ROOT / "assets").glob("badge*.svg"):
        shutil.copy2(f, DOCS / "assets" / f.name)
    img = ROOT / "calculator-app" / "src" / "site" / "resources" / "images"
    img.mkdir(parents=True, exist_ok=True)
    if (ROOT / "assets" / "rteu_logo.jpg").exists():
        shutil.copy2(ROOT / "assets" / "rteu_logo.jpg", img / "rteu_logo.jpg")
    log("prep: logos and badges copied")


# ----------------------------------------------------------------------------- app
def find_jar():
    cands = [p for p in (ROOT / "calculator-app" / "target").glob("*.jar")
             if not p.name.startswith("original-") and "-sources" not in p.name and "-javadoc" not in p.name]
    if not cands:
        sys.exit("[ERROR] no jar in calculator-app/target - run 6-build-and-test-<platform> first")
    return sorted(cands)[0]


def cmd_app(a):
    plat, arch = a.platform, a.arch or arch_auto()
    jar = find_jar()
    stage = ROOT / "publish" / ("%s-%s" % (plat, arch))
    rmtree(stage)
    stage.mkdir(parents=True)
    jar_name = "%s-%s.jar" % (NAME, VER)
    shutil.copy2(jar, stage / jar_name)
    if plat == "windows":
        launcher = stage / "run.bat"
        launcher.write_bytes(("@echo off\r\nrem Runs the app (needs a JDK/JRE 17 or newer on PATH).\r\n"
                              'java -jar "%%~dp0%s" %%*\r\n' % jar_name).encode())
    else:
        launcher = stage / "run.sh"
        launcher.write_bytes(('#!/bin/sh\n# Runs the app (needs a JDK/JRE 17 or newer on PATH).\n'
                              'exec java -jar "$(dirname "$0")/%s" "$@"\n' % jar_name).encode())
        launcher.chmod(0o755)
    (stage / "README.txt").write_text(
        "%s %s (%s %s)\n\nUsage:  %s <number> <+|-|*|/> <number>\nExample: %s 6 \"*\" 7  ->  42\n"
        "Needs Java 17 or newer (java -version).\n" % (
            NAME, VER, PLATFORM_TITLE.get(plat, plat), arch, launcher.name,
            ("run.bat" if plat == "windows" else "./run.sh")), encoding="utf-8")
    REL.mkdir(exist_ok=True)
    if plat == "windows":
        make_zip(stage, REL / asset(plat, arch, "app", "zip"))
    else:
        make_targz(stage, REL / asset(plat, arch, "app", "tar.gz"))


# ----------------------------------------------------------------------------- reports
def report_root(plat, r):
    return ROOT / "reports" / plat / r["key"] / r["root"] if r["root"] else ROOT / "reports" / plat / r["key"]


def report_ready(plat, r):
    return (report_root(plat, r) / r["entry"]).exists()


def cmd_reports(a):
    plat = a.platform
    REL.mkdir(exist_ok=True)
    made = 0
    for r in REPORTS:
        if report_ready(plat, r):
            make_zip(report_root(plat, r), REL / asset(plat, None, r["asset"], "zip"))
            made += 1
        else:
            log("  [WARN] reports/%s/%s has no %s - skipped" % (plat, r["key"], r["entry"]))
    log("reports: %d archive(s) for %s" % (made, plat))


# ----------------------------------------------------------------------------- site (docs staging)
def asset_url(name):
    return RELEASE_URL + name


def platform_present(plat):
    return any(report_ready(plat, r) for r in REPORTS)


def report_page(plat, r, ready):
    ptitle = PLATFORM_TITLE[plat]
    zipname = asset(plat, None, r["asset"], "zip")
    head = "---\nhide:\n  - toc\n---\n\n# %s - %s\n\n" % (r["title"], ptitle)
    if not ready:
        return (head + "!!! warning \"Not available in this build\"\n"
                "    This report was not produced for **%s** in this build. Build it with "
                "`7-build-all-%s` on a %s machine, or use the CI run (it builds Windows and Linux)."
                "\n" % (ptitle, plat, ptitle))
    return (
        head +
        '<div class="report-toolbar">\n'
        '<a class="md-button md-button--primary" href="html/%(entry)s" target="_blank" rel="noopener">Open in a new tab</a>\n'
        '<a class="md-button" href="%(dl)s">Download (zip)</a>\n'
        '</div>\n\n'
        '<p class="report-explainer">%(what)s <em>Tool: %(tool)s. Platform: %(plat)s.</em> '
        'See <a href="../../../guide/which-report/">Which report is which?</a></p>\n\n'
        '<div class="report-frame-wrap">\n'
        '<iframe class="report-frame" src="html/%(entry)s" title="%(title)s (%(plat)s)" loading="lazy"></iframe>\n'
        '</div>\n\n'
        '<p class="report-fallback">If the frame above stays empty, '
        '<a href="html/%(entry)s">open the report directly</a>.</p>\n'
    ) % dict(entry=r["entry"], dl=asset_url(zipname), what=r["what"], tool=r["tool"], plat=ptitle,
             title=html.escape(r["title"]))


def cmd_site(_a):
    cmd_prep(_a)
    # clean generated parts of docs/
    for d in ("reports", "native", "downloads"):
        rmtree(DOCS / d)
    for f in ("downloads.md", "maven-site.md"):
        if (DOCS / f).exists():
            (DOCS / f).unlink()

    present = {}
    for plat in PLATFORMS:
        present[plat] = platform_present(plat)
        base = DOCS / "reports" / plat
        base.mkdir(parents=True, exist_ok=True)
        rows = []
        for r in REPORTS:
            ready = report_ready(plat, r)
            d = base / r["key"]
            d.mkdir(parents=True, exist_ok=True)
            if ready:
                shutil.copytree(report_root(plat, r), d / "html")
            (d / "index.md").write_text(report_page(plat, r, ready), encoding="utf-8")
            rows.append("| %s | %s | [%s](%s/index.md) | %s |" % (
                r["group"], r["tool"], r["title"], r["key"], "yes" if ready else "not built"))
        (base / "index.md").write_text(
            "# Reports - %s\n\nEvery report below was produced **on %s** (%s). Reports can differ between "
            "Windows and Linux (line endings, paths, tool versions), so both sets are kept separately.\n\n"
            "| Family | Tool | Report page | Built |\n|---|---|---|---|\n%s\n\n"
            "Not sure which report to open first? Read [Which report is which?](../../guide/which-report.md).\n"
            % (PLATFORM_TITLE[plat], PLATFORM_TITLE[plat],
               "native Windows" if plat == "windows" else "native Linux or WSL - WSL is Linux", "\n".join(rows)),
            encoding="utf-8")
    (DOCS / "reports" / "index.md").write_text(
        "# Reports\n\nThe same set of reports is produced on **Windows** and on **Linux** and kept separately - "
        "results can differ between the two.\n\n"
        "<div class=\"grid cards\" markdown>\n\n"
        "- [:fontawesome-brands-windows: **Windows reports**](windows/index.md)\n\n"
        "    Tests, coverage (two tool families), documentation coverage, API docs - built on Windows.\n\n"
        "- [:fontawesome-brands-linux: **Linux reports**](linux/index.md)\n\n"
        "    The same set built on Linux (WSL counts as Linux).\n\n"
        "- [:material-help-circle: **Which report is which?**](../guide/which-report.md)\n\n"
        "    What every report shows and how the two tool families differ.\n\n"
        "</div>\n", encoding="utf-8")

    # native Maven site is copied as static files -> site/native/ (never framed)
    nat = ROOT / "site-native"
    if (nat / "index.html").exists():
        shutil.copytree(nat, DOCS / "native")
        maven_note = ""
    else:
        maven_note = ('!!! warning "Not available in this build"\n    The Maven site was not built here '
                      '(run `7-build-all-<platform>`; CI builds it on Linux).\n\n')
    open_btn = ('<p><a class="md-button md-button--primary" href="../native/index.html" target="_blank" '
                'rel="noopener">Open the Maven site</a></p>\n\n')
    links = [("Project information", "project-info.html"), ("Surefire test report", "surefire.html"),
             ("JaCoCo coverage (Maven page)", "jacoco/index.html"), ("Javadoc", "apidocs/index.html"),
             ("Source cross-reference (JXR)", "xref/index.html"), ("Checkstyle", "checkstyle.html"),
             ("PMD", "pmd.html"), ("CPD (copy/paste detector)", "cpd.html"), ("SpotBugs", "spotbugs.html")]
    lis = "".join('<li><a href="../native/%s" target="_blank" rel="noopener">%s</a></li>\n' % (h, t)
                  for t, h in links)
    (DOCS / "maven-site.md").write_text(
        "# Maven site (native)\n\n" + maven_note +
        "The Java-native site built by `mvn site` with the Fluido skin. Its pages carry **their own navigation "
        "(menu, banner, footer)**, so they open as their own site in a new tab and are **never shown inside a "
        "frame** here (a site inside a site is confusing - see the guide *Naming standard and site rules*).\n\n"
        + open_btn + "<ul>\n" + lis + "</ul>\n\n"
        "These are the reports only Maven can produce: Checkstyle, PMD, CPD, SpotBugs, JXR and the Surefire "
        "page. Standalone HTML reports (JaCoCo, ReportGenerator, Doxygen, Javadoc, ...) live under "
        "**Reports** per platform.\n", encoding="utf-8")

    # downloads page
    rows = []
    for plat in PLATFORMS + ["macos"]:
        arch = "arm64" if plat == "macos" else "x64"
        ext = "zip" if plat == "windows" else "tar.gz"
        rows.append(("app", plat, asset(plat, arch, "app", ext), "Runnable application (jar + launcher)",
                     "javac/Maven + shade"))
    for plat in PLATFORMS:
        for r in REPORTS:
            rows.append((r["group"], plat, asset(plat, None, r["asset"], "zip"), r["title"], r["tool"]))
    for f, _p, what, tool, _l in NEUTRAL_ASSETS:
        rows.append(("neutral", "-", "%s-%s-%s" % (NAME, VER, f) if f.endswith(".zip") else f, what, tool))
    body = ["# Downloads\n",
            "Every file below is attached to the GitHub Release "
            "[v%s](%s)%s. The local `release/` folder produced by `7-build-all-<platform>` holds the same names "
            "for the platform you built on (plus the platform-neutral files); CI builds both platforms.\n" % (
                VER, RELEASE_PAGE, ""),
            "| Content | Platform | File | What is inside | Tool |", "|---|---|---|---|---|"]
    for grp, plat, fn, what, tool in rows:
        link = "[`%s`](%s%s)" % (fn, RELEASE_URL, fn) if RELEASE_URL else "`%s`" % fn
        body.append("| %s | %s | %s | %s | %s |" % (grp, PLATFORM_TITLE.get(plat, plat), link, what, tool))
    body.append("\nChecksums: `SHA256SUMS.txt` (verify with `sha256sum -c SHA256SUMS.txt` on Linux or "
                "`Get-FileHash` on Windows).\n")
    (DOCS / "downloads.md").write_text("\n".join(body), encoding="utf-8")
    log("site: docs/ staged (windows=%s, linux=%s, native=%s)" % (
        present["windows"], present["linux"], (nat / "index.html").exists()))


# ----------------------------------------------------------------------------- finalize
def cmd_finalize(a):
    REL.mkdir(exist_ok=True)
    site = ROOT / "site"
    if not (site / "index.html").exists():
        sys.exit("[ERROR] site/index.html not found - run 'mkdocs build' first (7-build-all does it)")
    # 1. link check (hard fail only for our own pages)
    chk = [sys.executable, str(ROOT / "scripts" / "check-links.py"), str(site)]
    if subprocess.call(chk) != 0:
        sys.exit("[ERROR] broken links inside the site's own pages - see above")
    # 2. source zip (tracked files at HEAD)
    src = REL / ("%s-%s-source.zip" % (NAME, VER))
    if src.exists():
        src.unlink()
    r = subprocess.run(["git", "archive", "--format=zip", "-o", str(src), "HEAD"], cwd=ROOT)
    if r.returncode != 0:
        log("  [WARN] git archive failed - no source zip")
    else:
        log("  packed %s (%s)" % (src.name, human(src.stat().st_size)))
    # 3. site zips
    make_zip(site, REL / ("%s-%s-site.zip" % (NAME, VER)))
    nat = ROOT / "site-native"
    if (nat / "index.html").exists():
        make_zip(nat, REL / ("%s-%s-site-maven.zip" % (NAME, VER)))
    else:
        log("  [WARN] site-native/ missing - no site-maven.zip")
    write_assets_md()
    write_sums()


def classify(fn):
    """-> (platform, content, tool, site link)"""
    stem = fn[len("%s-%s-" % (NAME, VER)):] if fn.startswith("%s-%s-" % (NAME, VER)) else fn
    for plat in PLATFORMS + ["macos"]:
        if stem.startswith(plat + "-"):
            rest = stem[len(plat) + 1:]
            if rest.startswith(("x64-", "arm64-")):
                arch, _, rest = rest.partition("-")
                return plat, "app (%s)" % arch, "Maven shade + launcher", "downloads/"
            for r in REPORTS:
                if rest.startswith(r["asset"] + "."):
                    return plat, r["title"], r["tool"], "reports/%s/%s/" % (plat, r["key"])
    for f, _p, what, tool, link in NEUTRAL_ASSETS:
        if fn.endswith(f) or fn == f:
            return "-", what, tool, link
    return "-", "", "", ""


def sort_key(fn):
    plat, _what, _tool, _link = classify(fn)
    order = ["windows", "linux", "macos", "-"].index(plat) if plat in ("windows", "linux", "macos", "-") else 9
    idx = 0
    for i, r in enumerate(REPORTS):
        if ("-" + r["asset"] + ".") in fn:
            idx = i + 1
    return (order, idx, fn)


def write_assets_md():
    files = sorted((p.name for p in REL.iterdir() if p.is_file() and p.name not in ("ASSETS.md", "SHA256SUMS.txt")),
                   key=sort_key)
    lines = ["# Release assets - %s %s\n" % (NAME, VER),
             "Live site: %s\n" % (PAGES_URL or "(set GITHUB_REPO in project.env)"),
             "| File | Platform | Content | Tool | Site link |", "|---|---|---|---|---|"]
    have = set(files)
    for fn in files + ["ASSETS.md", "SHA256SUMS.txt"]:
        plat, what, tool, link = classify(fn)
        lines.append("| `%s` | %s | %s | %s | %s |" % (
            fn, PLATFORM_TITLE.get(plat, plat), what, tool,
            ("[%s](%s%s)" % (link, PAGES_URL, link)) if link and PAGES_URL else ""))
    missing = []
    for plat in PLATFORMS:
        for r in REPORTS:
            fn = asset(plat, None, r["asset"], "zip")
            if fn not in have:
                missing.append((plat, fn))
    for plat, arch, ext in (("windows", "x64", "zip"), ("linux", "x64", "tar.gz"), ("macos", "arm64", "tar.gz")):
        fn = asset(plat, arch, "app", ext)
        if fn not in have and not any(h.startswith("%s-%s-%s-" % (NAME, VER, plat)) and h.endswith("-app." + ext)
                                      for h in have):
            missing.append((plat, fn))
    if missing:
        plats = sorted({PLATFORM_TITLE[p] for p, _ in missing})
        lines.append("\n## Not in this folder\n")
        lines.append("This `release/` folder was built on one machine, so the assets of the other platform(s) "
                     "(%s) are missing. **CI builds every platform** - the GitHub Release has them all.\n" %
                     ", ".join(plats))
        for plat, fn in missing:
            lines.append("- `%s` (%s)" % (fn, PLATFORM_TITLE[plat]))
    (REL / "ASSETS.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    log("  wrote release/ASSETS.md")


def write_sums():
    out = []
    for p in sorted(REL.iterdir()):
        if p.is_file() and p.name != "SHA256SUMS.txt":
            out.append("%s  %s" % (sha256(p), p.name))
    (REL / "SHA256SUMS.txt").write_text("\n".join(out) + "\n", encoding="utf-8")
    log("  wrote release/SHA256SUMS.txt (%d files)" % len(out))


def cmd_notes(_a):
    (ROOT / "build").mkdir(exist_ok=True)
    s = PAGES_URL
    L = ["# %s %s" % (NAME, VER), "",
         "Live site: %s" % s, "",
         "Every asset is attached below; `ASSETS.md` lists them with the site page of each report and "
         "`SHA256SUMS.txt` holds the checksums.", "",
         "| Platform | Reports on the live site |", "|---|---|"]
    for plat in PLATFORMS:
        links = " - ".join("[%s](%sreports/%s/%s/)" % (r["title"], s, plat, r["key"]) for r in REPORTS)
        L.append("| %s | %s |" % (PLATFORM_TITLE[plat], links))
    L += ["", "Also: [Maven site (Checkstyle, PMD, CPD, SpotBugs, Surefire, JXR)](%snative/index.html), "
          "[Downloads](%sdownloads/), [Which report is which?](%sguide/which-report/)." % (s, s, s), "",
          "Run the app: unzip `%s`, then `run.bat` (or `./run.sh` from the tar.gz) - needs Java 17+." %
          asset("windows", "x64", "app", "zip")]
    (ROOT / "build" / "release-notes.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    log("notes: build/release-notes.md")


def cmd_info(_a):
    for k, v in (("PROJECT_NAME", NAME), ("VERSION", VER), ("GITHUB_REPO", REPO), ("PAGES_URL", PAGES_URL),
                 ("ARCH(auto)", arch_auto())):
        print("%s=%s" % (k, v))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sp = ap.add_subparsers(dest="cmd", required=True)
    for name, fn in (("prep", cmd_prep), ("site", cmd_site), ("finalize", cmd_finalize), ("notes", cmd_notes),
                     ("info", cmd_info)):
        sp.add_parser(name).set_defaults(fn=fn)
    for name, fn in (("app", cmd_app), ("reports", cmd_reports)):
        p = sp.add_parser(name)
        p.add_argument("--platform", required=True, choices=["windows", "linux", "macos"])
        p.add_argument("--arch", choices=["x64", "arm64"])
        p.set_defaults(fn=fn)
    a = ap.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
