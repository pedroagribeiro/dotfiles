# Global instructions

These apply in every session, in every repository. A project's own `CLAUDE.md` and
anything I say directly both override them.

## Artifacts and standalone pages

**Load the `artifact-style` skill before writing any artifact, standalone HTML page,
design doc, report or dashboard**, and follow it unless my request pins a different
visual direction — in which case my request wins.

It carries the palette (VS Code Dark 2026, the same theme my editor and terminal run),
the lettering (Geist Mono), and a set of render gotchas that are easy to trip over and
expensive to notice late. Read it *before* writing the file, not after: retrofitting a
theme onto a finished page means hunting hard-coded colours, and one that gets missed
shows up as a single wrong-coloured element weeks later.

This applies to the bundled `artifact-design` skill too — that one decides how much
design investment a request warrants, `artifact-style` decides what it looks like. Load
both; they answer different questions.
