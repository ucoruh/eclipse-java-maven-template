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
    # The next three come from the Maven build (JXR / Javadoc). They are standalone HTML without any site menu,
    # so they are framed like the others. asset=None: no extra release archive (they are inside site-maven.zip).
    dict(key="api-xref-jxr", group="API documentation", tool="JXR (Maven)", root="", entry="index.html",
         asset=None, title="Source cross-reference - JXR",
         what="The main source code as browsable HTML: every class, method and variable links to its definition "
              "and usages. Generated by the Maven JXR plugin."),
    dict(key="api-xreftest-jxr", group="API documentation", tool="JXR (Maven)", root="", entry="index.html",
         asset=None, title="Test source cross-reference - JXR",
         what="The same cross-referenced view for the test sources (the JUnit tests)."),
    dict(key="api-testjavadoc", group="API documentation", tool="Javadoc (native)", root="", entry="index.html",
         asset=None, title="Test Javadoc",
         what="Javadoc of the test classes (the JUnit tests), generated by the JDK's <code>javadoc</code> tool."),
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

# Reports that the Maven build itself writes into target/site: (folder in the Maven site, wrapper page name).
# The native Maven site frames them from that folder. Every other report is copied into
# site-native/reports/<platform>/<key>/html/ (command "native") and framed from there, once per platform.
MAVEN_LOCAL = {
    "coverage-jacoco": ("jacoco", "jacoco"),
    "api-javadoc": ("apidocs", "javadoc"),
    "api-xref-jxr": ("xref", "xref"),
    "api-xreftest-jxr": ("xref-test", "xref-test"),
    "api-testjavadoc": ("testapidocs", "testjavadoc"),
}
FRAMES_DIR = ROOT / "calculator-app" / "src" / "site" / "markdown" / "frames"


def maven_frame_md(title, what, src, note=""):
    return (
        "# %s\n\n"
        '<div class="report-toolbar">\n'
        '<a class="btn" href="%s" target="_blank" rel="noopener">Open in a new tab</a>\n'
        "</div>\n\n"
        '<p class="report-explainer">%s%s</p>\n\n'
        '<div class="report-frame-wrap">\n'
        '<iframe class="report-frame" src="%s" title="%s" loading="lazy"></iframe>\n'
        "</div>\n\n"
        '<p class="report-fallback">If the frame stays empty, <a href="%s">open the report directly</a>.</p>\n'
    ) % (title, src, what, note, src, html.escape(title), src)


def gen_maven_frames():
    """Iframe wrapper pages of the Maven native site (calculator-app/src/site/markdown/frames/*.md)."""
    rmtree(FRAMES_DIR)
    FRAMES_DIR.mkdir(parents=True, exist_ok=True)
    n = 0
    for r in REPORTS:
        if r["key"] in MAVEN_LOCAL:
            folder, name = MAVEN_LOCAL[r["key"]]
            (FRAMES_DIR / (name + ".md")).write_text(
                maven_frame_md(r["title"], r["what"], "../%s/%s" % (folder, r["entry"])), encoding="utf-8")
            n += 1
        else:
            for plat in PLATFORMS:
                src = "../reports/%s/%s/html/%s" % (plat, r["key"], r["entry"])
                (FRAMES_DIR / ("%s-%s.md" % (r["key"], plat))).write_text(
                    maven_frame_md("%s - %s" % (r["title"], PLATFORM_TITLE[plat]), r["what"], src,
                                   " <em>Built on %s.</em>" % PLATFORM_TITLE[plat]), encoding="utf-8")
                n += 1
    log("prep: %d Maven-site frame pages generated" % n)


def cmd_native(_a):
    """Copy the standalone reports of every platform present into site-native/reports/ (for the frames)."""
    nat = ROOT / "site-native"
    if not (nat / "index.html").exists():
        log("native: site-native/ missing - nothing to do")
        return
    copy_native_reports(nat)


def copy_native_reports(nat):
    n = 0
    for plat in PLATFORMS:
        for r in REPORTS:
            if r["key"] in MAVEN_LOCAL or not report_ready(plat, r):
                continue
            dst = Path(nat) / "reports" / plat / r["key"] / "html"
            rmtree(dst)
            shutil.copytree(report_root(plat, r), dst)
            n += 1
    log("native: %d standalone report folder(s) copied into %s/reports" % (n, Path(nat).name))


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
    gen_maven_frames()


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
        if not r["asset"]:
            continue
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


LANGS = ("en", "tr")

# Turkish texts for the generated pages (English texts live in REPORTS above).
TR_TITLE = {
    "tests-junit2html": "Birim test sonuçları",
    "coverage-jacoco": "Kod kapsaması - JaCoCo",
    "coverage-reportgenerator": "Kod kapsaması - ReportGenerator",
    "doccoverage-lcov": "Dokümantasyon kapsaması - coverxygen + genhtml",
    "doccoverage-reportgenerator": "Dokümantasyon kapsaması - ReportGenerator",
    "api-doxygen": "API belgeleri - Doxygen",
    "api-javadoc": "API belgeleri - Javadoc",
    "api-xref-jxr": "Kaynak çapraz başvurusu - JXR",
    "api-xreftest-jxr": "Test kaynağı çapraz başvurusu - JXR",
    "api-testjavadoc": "Test Javadoc",
}
TR_WHAT = {
    "tests-junit2html": "Çalışan her JUnit 5 testi (geçti, kaldı, atlandı), her birinin süresi ve bir şey bozulduğunda hata metni. "
                        "Surefire XML dosyalarından <code>junit2html</code> ile üretilir; ham XML indirmede de vardır.",
    "coverage-jacoco": "Birim testlerinin hangi satır, dal ve metotları gerçekten çalıştırdığı, doğrudan kaynak üzerinde renklendirilmiş "
                       "(yeşil = kapsandı, kırmızı = kaçırıldı). JaCoCo, Java'nın kendi kapsama aracıdır.",
    "coverage-reportgenerator": "Aynı JaCoCo kapsama verisinin ReportGenerator ile sunumu: özet kartlar, risk noktaları, derlemeler "
                                "boyunca geçmiş grafiği ve README rozetleri.",
    "doccoverage-lcov": "Genel API'nin ne kadarında dokümantasyon yorumu var. coverxygen Doxygen XML'ini okuyup lcov dosyası yazar; "
                        "<code>genhtml</code> (lcov aracı) onu kod kapsama raporu gibi gösterir.",
    "doccoverage-reportgenerator": "Aynı dokümantasyon kapsaması verisinin (aynı lcov dosyası) genhtml yerine ReportGenerator ile sunumu.",
    "api-doxygen": "Kütüphanenin genel API'sinin Doxygen çıktısı: sınıflar, metotlar, parametreler; Graphviz kuruluysa çağrı/işbirliği "
                   "grafikleri. C/C++ ve C# şablonlarının da kullandığı araç.",
    "api-javadoc": "<code>/** ... */</code> yorumlarından JDK'nın <code>javadoc</code> aracıyla üretilen Java'ya özgü API başvurusu.",
    "api-xref-jxr": "Ana kaynak kodu gezilebilir HTML olarak: her sınıf, metot ve değişken tanımına ve kullanımlarına bağlanır. "
                    "Maven JXR eklentisi üretir.",
    "api-xreftest-jxr": "Test kaynakları (JUnit testleri) için aynı çapraz başvurulu görünüm.",
    "api-testjavadoc": "Test sınıflarının (JUnit testleri) Javadoc çıktısı; JDK'nın <code>javadoc</code> aracı üretir.",
}
TR_GROUP = {"Unit tests": "Birim testleri", "Code coverage": "Kod kapsaması",
            "Documentation coverage": "Dokümantasyon kapsaması", "API documentation": "API belgeleri"}
TR_PLAT = {"windows": "Windows", "linux": "Linux", "macos": "macOS"}


def report_page(plat, r, ready, lang="en"):
    ptitle = PLATFORM_TITLE[plat]
    tr = lang == "tr"
    title = TR_TITLE[r["key"]] if tr else r["title"]
    what = TR_WHAT[r["key"]] if tr else r["what"]
    # Static files (the raw report) are copied once, next to the English page. The Turkish page lives one folder
    # deeper (tr/...), so it climbs back to the site root: the same report files serve both languages.
    src = ("../../../../reports/%s/%s/html/" % (plat, r["key"])) if tr else "html/"
    zipname = asset(plat, None, r["asset"], "zip") if r["asset"] else None
    if zipname:
        dlbtn = '<a class="md-button" href="%s">%s</a>' % (asset_url(zipname), "İndir (zip)" if tr else "Download (zip)")
    else:
        dlbtn = '<a class="md-button" href="../../../downloads/">%s</a>' % (
            "Site zip dosyalarında var" if tr else "Included in the site zips")
    head = "---\nhide:\n  - toc\n---\n\n# %s - %s\n\n" % (title, ptitle)
    if not ready:
        if tr:
            return (head + '!!! warning "Bu derlemede yok"\n'
                    "    Bu rapor bu derlemede **%s** için üretilmedi. Bir %s makinesinde `7-build-all-%s` ile üretin "
                    "veya CI çalışmasını kullanın (Windows ve Linux'u derler).\n" % (ptitle, ptitle, plat))
        return (head + "!!! warning \"Not available in this build\"\n"
                "    This report was not produced for **%s** in this build. Build it with "
                "`7-build-all-%s` on a %s machine, or use the CI run (it builds Windows and Linux)."
                "\n" % (ptitle, plat, ptitle))
    if tr:
        L = dict(open="Yeni sekmede aç", meta="Araç: %s. Platform: %s." % (r["tool"], ptitle),
                 see="Bkz. <a href=\"../../../guide/which-report/\">Hangi rapor hangisi?</a>",
                 fb="Çerçeve boş kalırsa <a href=\"%s%s\">raporu doğrudan açın</a>." % (src, r["entry"]))
    else:
        L = dict(open="Open in a new tab", meta="Tool: %s. Platform: %s." % (r["tool"], ptitle),
                 see="See <a href=\"../../../guide/which-report/\">Which report is which?</a>",
                 fb="If the frame above stays empty, <a href=\"%s%s\">open the report directly</a>." % (src, r["entry"]))
    return (
        head +
        '<div class="report-toolbar">\n'
        '<a class="md-button md-button--primary" href="%(src)s%(entry)s" target="_blank" rel="noopener">%(open)s</a>\n'
        '%(dlbtn)s\n'
        '</div>\n\n'
        '<p class="report-explainer">%(what)s <em>%(meta)s</em> %(see)s</p>\n\n'
        '<div class="report-frame-wrap">\n'
        '<iframe class="report-frame" src="%(src)s%(entry)s" title="%(title)s (%(plat)s)" loading="lazy"></iframe>\n'
        '</div>\n\n'
        '<p class="report-fallback">%(fb)s</p>\n'
    ) % dict(src=src, entry=r["entry"], open=L["open"], dlbtn=dlbtn, what=what, meta=L["meta"], see=L["see"],
             title=html.escape(title), plat=ptitle, fb=L["fb"])


def write_lang(path_no_ext, texts):
    """Write <path>.en.md and <path>.tr.md (mkdocs-static-i18n suffix mode). texts = {'en': ..., 'tr': ...}"""
    for lang in LANGS:
        Path(str(path_no_ext) + "." + lang + ".md").write_text(texts[lang], encoding="utf-8")


def cmd_site(_a):
    cmd_prep(_a)
    # clean generated parts of docs/
    for d in ("reports", "native", "downloads"):
        rmtree(DOCS / d)
    for pat in ("downloads.*.md", "maven-site.*.md"):
        for f in DOCS.glob(pat):
            f.unlink()

    present = {}
    for plat in PLATFORMS:
        present[plat] = platform_present(plat)
        base = DOCS / "reports" / plat
        base.mkdir(parents=True, exist_ok=True)
        rows = {"en": [], "tr": []}
        for r in REPORTS:
            ready = report_ready(plat, r)
            d = base / r["key"]
            d.mkdir(parents=True, exist_ok=True)
            if ready:
                shutil.copytree(report_root(plat, r), d / "html")
            write_lang(d / "index", {lang: report_page(plat, r, ready, lang) for lang in LANGS})
            rows["en"].append("| %s | %s | [%s](%s/index.md) | %s |" % (
                r["group"], r["tool"], r["title"], r["key"], "yes" if ready else "not built"))
            rows["tr"].append("| %s | %s | [%s](%s/index.md) | %s |" % (
                TR_GROUP.get(r["group"], r["group"]), r["tool"], TR_TITLE[r["key"]], r["key"],
                "evet" if ready else "derlenmedi"))
        origin_en = "native Windows" if plat == "windows" else "native Linux or WSL - WSL is Linux"
        origin_tr = "yerel Windows" if plat == "windows" else "yerel Linux veya WSL - WSL de Linux'tur"
        write_lang(base / "index", {
            "en": "# Reports - %s\n\nEvery report below was produced **on %s** (%s). Reports can differ between "
                  "Windows and Linux (line endings, paths, tool versions), so both sets are kept separately.\n\n"
                  "| Family | Tool | Report page | Built |\n|---|---|---|---|\n%s\n\n"
                  "Not sure which report to open first? Read [Which report is which?](../../guide/which-report.md).\n"
                  % (PLATFORM_TITLE[plat], PLATFORM_TITLE[plat], origin_en, "\n".join(rows["en"])),
            "tr": "# Raporlar - %s\n\nAşağıdaki her rapor **%s üzerinde** üretildi (%s). Raporlar Windows ile Linux arasında "
                  "farklılaşabilir (satır sonları, yollar, araç sürümleri); bu yüzden iki takım ayrı tutulur.\n\n"
                  "| Aile | Araç | Rapor sayfası | Derlendi |\n|---|---|---|---|\n%s\n\n"
                  "Hangisini önce açacağınızı bilmiyor musunuz? [Hangi rapor hangisi?](../../guide/which-report.md) sayfasını okuyun.\n"
                  % (PLATFORM_TITLE[plat], PLATFORM_TITLE[plat], origin_tr, "\n".join(rows["tr"]))})
    write_lang(DOCS / "reports" / "index", {
        "en": "# Reports\n\nThe same set of reports is produced on **Windows** and on **Linux** and kept separately - "
              "results can differ between the two.\n\n"
              "<div class=\"grid cards\" markdown>\n\n"
              "- [:fontawesome-brands-windows: **Windows reports**](windows/index.md)\n\n"
              "    Tests, coverage (two tool families), documentation coverage, API docs - built on Windows.\n\n"
              "- [:fontawesome-brands-linux: **Linux reports**](linux/index.md)\n\n"
              "    The same set built on Linux (WSL counts as Linux).\n\n"
              "- [:material-help-circle: **Which report is which?**](../guide/which-report.md)\n\n"
              "    What every report shows and how the two tool families differ.\n\n"
              "</div>\n",
        "tr": "# Raporlar\n\nAynı rapor takımı **Windows'ta** ve **Linux'ta** üretilir ve ayrı tutulur - "
              "sonuçlar ikisi arasında farklı olabilir.\n\n"
              "<div class=\"grid cards\" markdown>\n\n"
              "- [:fontawesome-brands-windows: **Windows raporları**](windows/index.md)\n\n"
              "    Testler, kapsama (iki araç ailesi), dokümantasyon kapsaması, API belgeleri - Windows'ta üretildi.\n\n"
              "- [:fontawesome-brands-linux: **Linux raporları**](linux/index.md)\n\n"
              "    Aynı takım Linux'ta üretildi (WSL de Linux sayılır).\n\n"
              "- [:material-help-circle: **Hangi rapor hangisi?**](../guide/which-report.md)\n\n"
              "    Her raporun ne gösterdiği ve iki araç ailesinin farkı.\n\n"
              "</div>\n"})

    # native Maven site is copied as static files -> site/native/ (framed-page wrappers inside it, never framed here)
    nat = ROOT / "site-native"
    if (nat / "index.html").exists():
        shutil.copytree(nat, DOCS / "native")
        copy_native_reports(DOCS / "native")
        warn = {"en": "", "tr": ""}
    else:
        warn = {"en": '!!! warning "Not available in this build"\n    The Maven site was not built here '
                      '(run `7-build-all-<platform>`; CI builds it on Linux).\n\n',
                "tr": '!!! warning "Bu derlemede yok"\n    Maven sitesi burada derlenmedi '
                      "(`7-build-all-<platform>` çalıştırın; CI Linux'ta derler).\n\n"}
    links = [("Project information", "Proje bilgisi", "project-info.html"),
             ("Surefire test report", "Surefire test raporu", "surefire.html"),
             ("Checkstyle", "Checkstyle", "checkstyle.html"), ("PMD", "PMD", "pmd.html"),
             ("CPD (copy/paste detector)", "CPD (kopya-yapıştır dedektörü)", "cpd.html"),
             ("SpotBugs", "SpotBugs", "spotbugs.html"),
             ("Dependencies", "Bağımlılıklar", "dependencies.html"), ("Plugins", "Eklentiler", "plugins.html")]
    texts = {}
    for lang in LANGS:
        up = "../" if lang == "en" else "../../"   # the Turkish page is one folder deeper (tr/...)
        idx = 0 if lang == "en" else 1
        lis = "".join('<li><a href="%snative/%s" target="_blank" rel="noopener">%s</a></li>\n' % (up, l[2], l[idx])
                      for l in links)
        btn = ('<p><a class="md-button md-button--primary" href="%snative/index.html" target="_blank" '
               'rel="noopener">%s</a></p>\n\n' % (up, "Open the Maven site" if lang == "en" else "Maven sitesini aç"))
        if lang == "en":
            texts[lang] = (
                "# Maven site (native)\n\n" + warn[lang] +
                "The Java-native site built by `mvn site` with the Fluido skin. The pages Maven renders itself carry "
                "**their own navigation (menu, banner, footer)**, so they open as their own site in a new tab and are "
                "**never shown inside a frame** here (a site inside a site is confusing - see the guide *Naming "
                "standard and site rules*).\n\n" + btn + "<ul>\n" + lis + "</ul>\n\n"
                "Every **standalone** report (JaCoCo, ReportGenerator, genhtml, Doxygen, Javadoc, Test Javadoc, JXR "
                "source cross-references, junit2html) is the opposite: it is shown in a frame - in this site under "
                "**Reports** and **API docs**, and inside the Maven site through small wrapper pages.\n")
        else:
            texts[lang] = (
                "# Maven sitesi (native)\n\n" + warn[lang] +
                "`mvn site` ile Fluido temasıyla üretilen Java'ya özgü site. Maven'in kendisinin ürettiği sayfalar "
                "**kendi gezinmesini (menü, başlık, altbilgi)** taşır; bu yüzden yeni sekmede kendi sitesi olarak açılır ve "
                "burada **asla çerçeve içinde gösterilmez** (site içinde site kafa karıştırır - *Adlandırma standardı ve "
                "site kuralları* kılavuzuna bakın).\n\n" + btn + "<ul>\n" + lis + "</ul>\n\n"
                "Her **bağımsız** rapor (JaCoCo, ReportGenerator, genhtml, Doxygen, Javadoc, Test Javadoc, JXR kaynak "
                "çapraz başvuruları, junit2html) ise tam tersidir: çerçevede gösterilir - bu sitede **Reports** ve "
                "**API docs** altında, Maven sitesinde küçük sarmalayıcı sayfalarla.\n")
    write_lang(DOCS / "maven-site", texts)

    # downloads page
    rows = []
    for plat in PLATFORMS + ["macos"]:
        arch = "arm64" if plat == "macos" else "x64"
        ext = "zip" if plat == "windows" else "tar.gz"
        rows.append(("app", "uygulama", plat, asset(plat, arch, "app", ext),
                     "Runnable application (jar + launcher)", "Çalıştırılabilir uygulama (jar + başlatıcı)",
                     "javac/Maven + shade"))
    for plat in PLATFORMS:
        for r in [x for x in REPORTS if x["asset"]]:
            rows.append((r["group"], TR_GROUP.get(r["group"], r["group"]), plat, asset(plat, None, r["asset"], "zip"),
                         r["title"], TR_TITLE[r["key"]], r["tool"]))
    for f, _p, what, tool, _l in NEUTRAL_ASSETS:
        rows.append(("neutral", "bağımsız", "-", "%s-%s-%s" % (NAME, VER, f) if f.endswith(".zip") else f,
                     what, what, tool))
    texts = {}
    for lang, idx in (("en", 0), ("tr", 1)):
        if lang == "en":
            body = ["# Downloads\n",
                    "Every file below is attached to the GitHub Release [v%s](%s). The local `release/` folder produced "
                    "by `7-build-all-<platform>` holds the same names for the platform you built on (plus the "
                    "platform-neutral files); CI builds both platforms.\n" % (VER, RELEASE_PAGE),
                    "| Content | Platform | File | What is inside | Tool |", "|---|---|---|---|---|"]
        else:
            body = ["# İndirmeler\n",
                    "Aşağıdaki her dosya GitHub Release [v%s](%s) sürümüne eklidir. `7-build-all-<platform>` betiğinin "
                    "ürettiği yerel `release/` klasörü, derleme yaptığınız platform için (artı platformdan bağımsız "
                    "dosyalar) aynı adları taşır; CI iki platformu da derler.\n" % (VER, RELEASE_PAGE),
                    "| İçerik | Platform | Dosya | İçinde ne var | Araç |", "|---|---|---|---|---|"]
        for row in rows:
            grp, plat, fn, what, tool = row[idx], row[2], row[3], row[4 + idx], row[6]
            link = "[`%s`](%s%s)" % (fn, RELEASE_URL, fn) if RELEASE_URL else "`%s`" % fn
            body.append("| %s | %s | %s | %s | %s |" % (grp, PLATFORM_TITLE.get(plat, plat), link, what, tool))
        body.append("\nChecksums: `SHA256SUMS.txt` (verify with `sha256sum -c SHA256SUMS.txt` on Linux or "
                    "`Get-FileHash` on Windows).\n" if lang == "en" else
                    "\nSağlama toplamları: `SHA256SUMS.txt` (Linux'ta `sha256sum -c SHA256SUMS.txt`, Windows'ta "
                    "`Get-FileHash` ile doğrulayın).\n")
        texts[lang] = "\n".join(body)
    write_lang(DOCS / "downloads", texts)
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
    nat = DOCS / "native" if (DOCS / "native" / "index.html").exists() else ROOT / "site-native"
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
            for r in [x for x in REPORTS if x["asset"]]:
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
        if r["asset"] and ("-" + r["asset"] + ".") in fn:
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
        for r in [x for x in REPORTS if x["asset"]]:
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
    for name, fn in (("prep", cmd_prep), ("native", cmd_native), ("site", cmd_site), ("finalize", cmd_finalize), ("notes", cmd_notes),
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
