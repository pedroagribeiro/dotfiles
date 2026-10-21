# Global instructions

These apply in every session, in every repository. A project's own `CLAUDE.md` and
anything I say directly both override them.

## Artifacts and standalone pages

**Load the `artifact-style` skill before writing any artifact, standalone HTML page,
design doc, report or dashboard**, and follow it unless my request pins a different
visual direction — in which case my request wins.

It carries a page template (a soft product-page look in light and dark with one indigo
accent), the lettering (Poppins and JetBrains Mono), a pre-publish check script and a set
of render gotchas that are easy to trip over and expensive to notice late. It is
brand-neutral; a project may name a brand layer to load on top of it. Read it *before*
writing the file, not after: retrofitting a
theme onto a finished page means hunting hard-coded colours, and one that gets missed
shows up as a single wrong-coloured element weeks later.

This applies to the bundled `artifact-design` skill too — that one decides how much
design investment a request warrants, `artifact-style` decides what it looks like. Load
both; they answer different questions.
