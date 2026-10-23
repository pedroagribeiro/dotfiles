---
name: artifact-style
description: Pedro's house visual language for anything published as a page — Claude artifacts, standalone HTML, design docs, reports, dashboards, plans, one-pagers, mockups. A soft product-page look in Poppins with Menlo for code, an 880px reading column, a header with two diffuse glows, rounded cards and one indigo accent, light and dark themes both designed. Use whenever building a page for Pedro, including when he says "make me a page", "write this up", "put this somewhere I can share", or asks for an artifact, HTML file, doc or dashboard. It is brand-neutral; a brand layer (e.g. nutrium-brand-web) can sit on top by overriding its tokens.
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

**Poppins for everything read. Menlo for anything that is code** — paths,
field names, JSON, endpoints, status codes. Menlo ships only with macOS and iOS, so
`--font-mono` falls back to JetBrains Mono (still loaded from Google Fonts, and only
downloaded where Menlo is missing), then the system monospace. Menlo has no 500 or 600
weight; those render as its bold. Material Symbols Outlined for icons.
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

For API and data-model pages the template also carries:

- **Endpoint card** (`article.ep`): the endpoint line, a short description and
  `.block`s with a micro-type `h3` (Input, Output, Status codes).
- **Status codes** (`.codes` > `.code`): a `.pill` per HTTP status (`ok` for 2xx,
  `warn` for 4xx the app handles, `err` for 403/404/5xx), then what it means and its body.
- **ER diagram** (`.er-scroll` > `.er`): tables as white `.ent` cards (14px radius) on a
  `--soft` canvas with the 20px radius. The table name is mono 600 in `--heading`; an
  existing table's name drops to `--muted`. A new or changed table gets a 3px inset rule
  along its top in `--ok` or `--warn`, plus a status pill in the header. Fields are `.f`
  rows in mono 12px, with the type in small sans on the right; `add` / `chg` / `del`
  rows sit on their state's `-soft` fill with a `+` / `~` / `−` marker, and `del`
  strikes the name through. Unmarked rows are existing fields in `--muted`.
  Place the boxes with an inline `grid-template-areas` on `.er` and `grid-area` on each
  box. List the links in `data-edges` as `[from-id, to-id, "fk" | "id", label]`: the
  script draws curved links between box edges (horizontal when the boxes sit side by
  side, vertical otherwise), solid `--muted` for a foreign key and dashed `--ok` for a
  plain id, with the label in a white pill at the middle. Links leave through the side
  with the wider gap and stay level with the other box where the two overlap; labels are
  drawn on a layer above the boxes, so a short gap never hides one. The canvas breaks out
  of the 880px reading column, up to 1200px, because three columns of table names do not
  fit in it. The `.legend` uses `.sw`
  squares (`add`, `chg`, `del`, plain for existing) and `.sw.line` / `.sw.line.id` for the
  two kinds of link. Keep `.er`'s `min-width`, so a narrow screen scrolls the diagram
  instead of squeezing it, and lay the boxes out so no link crosses a box.
- `.plain-list` for a bulleted list, `.values` for a mono list of enum values.
- **View switch** (`nav.view-switch` in the hero, below `.meta`): a pill-shaped segmented
  control for a page with two or three parts that are read separately, such as an API
  contract and its data model. Each tab is a link to the id of a `[data-view]` wrapper in
  `main .wrap`; the script shows one wrapper at a time and marks its tab with
  `aria-current="true"`. A link to any element inside a hidden view opens that view and
  scrolls to it, and the last view chosen is remembered per page in `localStorage`. Each
  view stacks its sections with the same 72px gap as `main .wrap`. Use it only when the
  parts have different readers; a long page for one reader keeps one column.
- **Collapsible task** (`.task-list` > `details.task`): one row per item of a plan, a
  checklist or a reference list, closed by default. The `summary` holds a mono
  `.task-id` in the accent text colour, the `.task-title` and `.chip`s in `.task-meta`
  (difficulty, dependencies). The `.task-body` takes plain HTML: micro-type `h4` labels,
  lists, `blockquote` for a pointer to follow and `pre`. Put a `.task-tools` row with two
  `button[data-tasks="open"|"close"]` under the section head to open or close every task
  in that section. A `ul.checklist` draws empty boxes for a checkpoint; it is a list to
  read, not a form.

Use these instead of page-local CSS. A page that needs another component gets it
added to the template first.

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
