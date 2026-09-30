# Calculator App - Maven site

<div class="site-hero">
<h1>Maven site (native)</h1>
<p class="tagline">The Java-native reports of this project, built by <code>mvn site</code> with the Fluido skin:
project information, Surefire, JaCoCo, Javadoc, JXR, Checkstyle, PMD, CPD and SpotBugs.</p>
<p class="hero-actions">
<a class="btn btn-large btn-download" href="../index.html">Main site (MkDocs) with every report, Windows and Linux</a>
<a class="btn btn-large" href="https://github.com/ucoruh/eclipse-java-maven-template/releases/latest">Download the latest release</a>
</p>
</div>

This is the **native** Maven site. The main site of the project is the MkDocs site one level up
(`../index.html` when this site is published under `native/`); it shows the standalone reports (JaCoCo,
ReportGenerator, Doxygen, Javadoc, junit2html, documentation coverage) for Windows **and** Linux.

## Reports on this site

<div class="card-grid">

<div class="report-card">
<span class="card-eyebrow">Unit tests</span>
<h3><a href="surefire.html">Surefire Report</a></h3>
<p>Every JUnit&nbsp;5 test that ran, pass/fail and duration.</p>
</div>

<div class="report-card">
<span class="card-eyebrow">Code coverage</span>
<h3><a href="frames/jacoco.html">JaCoCo</a></h3>
<p>Line, branch and method coverage on the source.</p>
</div>

<div class="report-card">
<span class="card-eyebrow">API docs</span>
<h3><a href="frames/javadoc.html">Javadoc</a></h3>
<p>The Java API reference.</p>
</div>

<div class="report-card">
<span class="card-eyebrow">Source</span>
<h3><a href="frames/xref.html">Source cross-reference (JXR)</a></h3>
<p>Browsable source with links from every symbol.</p>
</div>

<div class="report-card">
<span class="card-eyebrow">Code quality</span>
<h3><a href="checkstyle.html">Checkstyle</a></h3>
<p>Coding-style conformance (Google style).</p>
</div>

<div class="report-card">
<span class="card-eyebrow">Code quality</span>
<h3><a href="pmd.html">PMD</a> &middot; <a href="cpd.html">CPD</a></h3>
<p>Design smells and copy-pasted code.</p>
</div>

<div class="report-card">
<span class="card-eyebrow">Code quality</span>
<h3><a href="spotbugs.html">SpotBugs</a></h3>
<p>Bug patterns found in the compiled bytecode.</p>
</div>

<div class="report-card">
<span class="card-eyebrow">Project</span>
<h3><a href="project-info.html">Project information</a></h3>
<p>Dependencies, plugins, team, source control, CI.</p>
</div>

</div>
