# Code Quality: SpotBugs

<div class="report-toolbar">
<a class="btn" href="../spotbugs.html" target="_blank" rel="noopener">Open in a new tab</a>
<a class="btn" href="../downloads/spotbugs.zip">Download (zip)</a>
</div>

<p class="report-explainer">A static, bytecode-based bug-pattern detector (it runs after <code>mvn package</code>,
since it needs the compiled <code>.class</code> files, not the source). It catches classes of bugs pattern-matching
alone cannot, such as null-pointer risks and resource leaks. Report-only, does not fail the build.</p>

<div class="report-frame-wrap">
<iframe class="report-frame" src="../spotbugs.html" title="SpotBugs report" loading="lazy"></iframe>
</div>

<p class="report-fallback">If the report above does not load (some browsers block framed pages), <a
href="../spotbugs.html">open it directly</a>.</p>
