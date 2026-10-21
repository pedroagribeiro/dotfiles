---
name: artifact-style
description: Pedro's house visual language for anything published as a page — Claude artifacts, standalone HTML, design docs, reports, dashboards, plans, one-pagers, mockups. A soft product-page look in Poppins with JetBrains Mono for code, an 880px reading column, a header with two diffuse glows, rounded cards and one indigo accent, light and dark themes both designed. Use whenever building a page for Pedro, including when he says "make me a page", "write this up", "put this somewhere I can share", or asks for an artifact, HTML file, doc or dashboard. It is brand-neutral; a brand layer (e.g. nutrium-brand-web) can sit on top by overriding its tokens.
---

# Artifact style

The default look for anything I publish as an artifact or a standalone HTML page,
unless the request pins a different direction. **If it does, the request wins.**

It reads like a calm product explainer: an almost-white page, one reading column, a
header with two soft glows behind the title, and sections that always open with an
eyebrow, a heading and a short intro. Rounded white cards with thin borders carry the
content. Many of these pages are read by other teams, so legibility beats mood.

This look is **brand-neutral**. A brand layer may sit on top of it: it overrides the
tokens and adds a logo and a display face, but never redefines a component. If the
project's instructions name a brand layer, load it right after this skill.

Origin: the "Food quantities in ounces" page
(https://claude.ai/artifact/DtRnUPAg23mBUDzu7Fox7y), with the Nutrium branding taken out.
The previous look (teal API-reference, Source Sans 3) is archived in
`~/.claude/skills/.trash/artifact-style-2026-10-21/`.

## How to build a page

1. **Start from `template.html`** in this folder. Copy it to the scratchpad, rename the
   `<title>`, delete the components you don't need and fill in real content. The
   template has every token and component; don't rebuild them from memory.
2. If a brand layer applies, run its apply script on the copy (it fills the
   `<!-- brand:* -->` markers). Without a brand, delete the markers.
3. Run `python3 -I scripts/check_page.py <page>` and fix what it reports.
4. Publish.

## Tokens

All colours live in the three token blocks at the top of the template (bare `:root`,
the guarded `prefers-color-scheme: dark` block and `:root[data-theme="dark"]`). Component
rules only ever use `var(--…)`.

- **Neutrals:** `--bg` (almost white), `--surface` (cards), `--soft` (table headers,
  inline code, quiet fills), `--fg`, `--heading`, `--muted`, `--border`.
- **Accent (indigo by default):** `--accent` for fills (step numbers, callout rule,
  focus ring), `--accent-text` for text that must read as accent (eyebrows, labels,
  links, arrows), `--accent-soft` for tinted tiles, `--on-accent` for text sitting on
  `--accent`. Never put literal white on the accent.
- **Second accent:** `--accent-2` / `--accent-2-soft`, only to tell two options or
  categories apart (`.tag.alt`).
- **State:** `--ok`, `--warn`, `--err`, each as text on its own `-soft` fill. State is
  separate from the accent.
- **Code:** `--code-bg`, `--code-fg` and `--code-key/str/num/dim` for the `.tok-*`
  spans in `pre`.
- **Atmosphere:** `--glow-a` / `--glow-b` (the two header glows), `--shadow`,
  `--grad-accent` (the one gradient word in the h1).

## Lettering

**Poppins for everything read. JetBrains Mono for anything that is code** — paths,
field names, JSON, endpoints, status codes. Material Symbols Outlined for icons.
`--font-display` is the eyebrow face; in the base it is Poppins too, and a brand layer
may swap it.

- **h1:** `clamp(30px, 5.4vw, 44px)`, 700, tracking `-0.02em`, max `18ch`.
- **h2:** `clamp(24px, 3.6vw, 30px)`, 700, tracking `-0.02em`.
- **h3:** 17px, 600.
- **Body:** 16px / 1.6. The lede is 18px in `--muted`.
- **Eyebrow:** 14px, 500, uppercase, tracking `0.08em`, in `--accent-text`.
- **Table and label micro-type:** 11.5–12px, 600, uppercase, tracking `0.06em`, in
  `--muted`.
- **Inline code:** 0.82em on `--soft`. **Code block:** 13px / 1.6 on `--code-bg`.

Running text stays near 64–72 characters wide.

## Surfaces

- Page on `--bg`. Cards on `--surface` with a `1px solid var(--border)`.
- Radii: 8px for small controls and mock inputs, 14px for cards, tables and callouts,
  20px for the one feature panel, pills at 1000px.
- **One shadow per page:** only the `.panel` (the answer or before/after block) gets
  `--shadow`. Every other card is flat.
- **Gradients are allowed in exactly two places:** the two radial glows in the hero,
  and one `.grad` word in the h1. Nowhere else.
- A `.callout` carries the one thing to remember in a section; a `.callout.warn` marks
  a risk or an open question. Use them once or twice per page.

## Components in the template

The hero (eyebrow, h1, lede, chips), section head, table in `.table-scroll`, callout,
status pills, feature panel with a highlight, icon cards, flow with arrows, numbered
steps, stat tiles, option cards with a `dl`, icon list, code block, endpoint line and
footer. Use numbered steps only when the order is real.

## Gotchas

- **Every inline `<code>` inherits the `--soft` chip.** The template already resets
  it inside `pre` and `.path`; do the same for any other monospaced container.
- **Material Symbols are ligatures.** If the font is slow, the raw word
  ("arrow_forward") shows. The template's `.icon` has `width: 1em; overflow: hidden`
  so that never breaks the layout. Keep it.
- **Draw inline SVG in `currentColor` and `var(--…)`.** Literal hex inside an SVG breaks
  in one of the two themes. (A brand logo uses `currentColor` through a token.)
- **`::before` on a grid or flex container becomes an item.** The numbered steps use
  this on purpose (a 30px column); anywhere else, use borders or `background-image`.
- **Two-column grids collapse to one column below 760px**, `dl` rows below 560px.
  Give any new grid the same treatment.
- **`--muted` is the tier that fails contrast first**, especially on `--soft` and
  `--warn-soft`. The check script covers it in both themes.

## What not to do

No gradients outside the hero glows and the one h1 word. No shadow on every card. No
emoji as section markers. No centring everything. No colour that exists in only one
theme. No accent used as decoration: it marks labels, links, numbering and focus.
