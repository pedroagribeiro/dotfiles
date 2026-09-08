---
name: artifact-style
description: Pedro's house visual language for anything published as a page — Claude artifacts, standalone HTML, design docs, reports, dashboards, plans, one-pagers, mockups. VS Code Dark 2026 palette, Geist Mono lettering, gradient surfaces, plus the render gotchas that come with them. Use whenever building a page for Pedro, including when he says "make me a page", "write this up", "put this somewhere I can share", or asks for an artifact, HTML file, doc or dashboard.
---

# Artifact style

The default look for anything I publish as an artifact or a standalone HTML page,
unless the request pins a different direction. **If it does, the request wins.**

The palette is **VS Code Dark 2026**, the same theme my editor and terminal run.
The lettering is **Geist Mono**, the font my terminal runs. Dark, rounded, quiet,
with gradients doing the work that borders usually do.

## Where the palette actually lives

Both files are in `~/.dotfiles`. **Read the Zed one** — the Ghostty theme is only the
16-colour ANSI palette plus a background, which is not enough to build a page from:

- `home/programs/zed/themes/vscode-2026.json` — surfaces, borders, text tiers, accent,
  semantic colours. This is the source of truth.
- `home/programs/ghostty/themes/vscode-dark-2026` — ANSI only. Useful for the bright
  variants of red/green/cyan when a semantic colour needs to be more legible.

## Palette

Paint every value explicitly — never inherit a host background.

```css
:root {
  --paper:    #121314;   /* page ground — editor.background */
  --surface:  #191A1B;   /* cards — surface.background */
  --sunk:     #161718;   /* quiet cards, between paper and surface */
  --raised:   #202122;   /* hover, panel headers — elevated_surface */
  --ink:      #BBBEBF;   /* body — editor.foreground */
  --bright:   #E5E5E5;   /* headings, bold */
  --dim:      #8C8C8C;   /* secondary — text.muted */
  --faint:    #868788;   /* labels — see the contrast note below */
  --rule:     rgba(255, 255, 255, 0.07);
  --rule-firm:rgba(255, 255, 255, 0.14);
  --accent:   #48A0C7;   /* text.accent */
  --accent-bg:rgba(72, 160, 199, 0.13);
  --warn:     #E5BA7D;
  --warn-bg:  rgba(229, 186, 125, 0.10);
  --stop:     #F14C4C;
  --lift:     inset 0 1px 0 rgba(255, 255, 255, 0.06);
  color-scheme: dark;
}
```

**Two semantic substitutions, both deliberate.** The theme declares `warning: #e5e510`
and `error: #cd3131`. Pure yellow screams next to running prose, and `#cd3131` is too
dark to read on `#121314`. Use `#E5BA7D` (the theme's `modified`) and `#F14C4C` (the
terminal's bright red) instead.

**Pick the accent to match the content.** Default is `#48A0C7`. Alternatives from the
same theme: green `#73C991`, amber `#E5BA7D`, cyan `#29B8DB`, magenta `#D670D6`. One
accent per page. If the page already has meaningful colour, choose the accent nearest
what is there so nothing has to be redrawn.

**Code blocks sit *below* the surface, not beside it** — this is the inversion that
catches people coming from a light design. On a ground this dark, that means going
nearly black:

```css
--slab: #0B0C0D;  --slab-2: #17181A;   /* header bar */
--slab-ink: #BBBEBF;  --slab-dim: #868788;
```

Status codes inside slabs: 4xx `#E5BA7D`, 5xx `#F14C4C`.

**Contrast: this ground is darker than it looks, so mid-greys fail.** `#121314` is much
deeper than a typical dark theme, and the greys that pass AA elsewhere do not pass here.
Anything below roughly `#7E7F80` on small text is under 4.5:1 — `--faint` is `#868788`
rather than something dimmer for exactly that reason. Check every label tier, not just
body text; the micro-labels are the ones that fail.

## Lettering

**Geist Mono for anything that names something, Geist for anything that is read.**
Headings, labels, code and diagram text are mono; running prose is not, because most of
what I write is prose and full mono is tiring to read. If a page is short or is mostly
data, all-mono is a fine call.

```html
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600&family=Geist+Mono:wght@400;500;600&display=swap">
```

```css
--ff-disp: 'GeistMono Nerd Font', 'Geist Mono', ui-monospace, SFMono-Regular, Menlo, monospace;
--ff-mono: 'GeistMono Nerd Font', 'Geist Mono', ui-monospace, SFMono-Regular, Menlo, monospace;
--ff-body: 'Geist', -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
```

**Put `'GeistMono Nerd Font'` first and `'Geist Mono'` second.** The Nerd Font is
installed locally, so my machine renders the patched face; everyone else falls through to
the Google Fonts copy. Both Geist and Geist Mono are on Google Fonts, which is the only
font host an artifact's CSP allows — a font from anywhere else fails silently.

Mono glyphs are wide, so the tracking is **looser** than a grotesk wants, and the display
sizes are **smaller** so the visual mass matches:

| | size | weight | tracking | colour |
|---|---|---|---|---|
| h1 | `clamp(1.6rem, 4.1vw, 2.2rem)` | 600 | `-0.02em` | gradient text |
| h2 | `clamp(1.32rem, 3.1vw, 1.72rem)` | 600 | `-0.018em` | `--bright` |
| h3 | `1.05rem` | 600 | `-0.01em` | `--bright` |
| body | `15.5px` / 1.68 | 400 | `-0.003em` | `--ink` |
| bold | — | 600 | — | `--bright` |

**Uppercase micro-labels get smaller and wider, never bolder** — `0.66rem`, weight 500,
`letter-spacing: 0.1em`, in `--faint`. (Wider than that reads as gappy in a monospace.)

Code sits at `0.9em` with `letter-spacing: 0`. It needs less shrinking than it would
beside a sans, because it is now the same family as the headings.

## Roundness and surfaces

Radii: `6px` chips and badges · `10px` cards and rows · `12px` panels · `14px` figures.

Every card gets the lit top edge, which is what makes a dark surface read as raised
without a visible border:

```css
box-shadow: var(--lift);
background: linear-gradient(180deg, rgba(255, 255, 255, 0.035), transparent 42%), var(--surface);
```

**Gradients carry hierarchy, they are not decoration.** Use them in exactly these places:

- a two-colour radial glow behind the masthead, low alpha, accent plus one neighbour
  (`#48A0C7` with `#29B8DB` works)
- the lit top edge on cards, above
- a wash on cards that mean something — amber for warnings, using `--warn` at 7–9%
- the active tab or selected control, filled with the accent at 10–22% plus a soft outer glow
- gradient text on the h1 only
- section rules that fade out rather than stopping dead:
  `border-image: linear-gradient(90deg, var(--rule-firm), transparent 78%) 1;`

Nowhere else. A gradient on every surface is the look this is trying to avoid.

**Text on an accent fill must be dark, not white.** `#48A0C7` with white is about 2.5:1.
Use `#0B0C0D` on it, which is near 6.7:1.

## Gotchas, each one learned the hard way

**`background` resets `background-clip`.** Gradient text set up with
`background-clip: text` disappears the moment a later rule re-declares the `background`
shorthand — it renders as a solid coloured bar. Use `background-image` in any rule that
touches a clipped element, and re-assert the clip.

**Light screenshots need a mat, and it goes on the `<img>`.** Embedded PNGs with white
backgrounds are pure glare on a dark ground:

```css
.shot img {
  padding: 0.7rem;
  border-radius: 14px;
  background: linear-gradient(168deg, #E8E9EA, #D3D5D6);
  box-shadow: 0 1px 2px rgba(0,0,0,0.4), 0 18px 36px -22px rgba(0,0,0,0.7);
}
```

A neutral light mat, not a tinted one — this palette has no warm light half to borrow.
On the `<img>`, **not** the `<figure>`: a mat on the figure swallows the caption and
leaves light text on a light ground.

**Draw inline SVG in `currentColor` and `var(--accent)`.** Diagrams built that way
retheme for free and survive every palette change — a whole retheme can land without
touching a single diagram. Literal hex inside an SVG is a future re-edit.

**Check the theme applies to grid and flex containers.** A `::before` added for a
gradient rule becomes a grid item and silently breaks the layout. Prefer `border-image`
or a `background-size: 100% 1px` hairline.

**Verify before publishing.** Grep the stylesheet for stray hex from whatever the page
looked like before, count `{` against `}`, and compute the contrast of every text tier
against every ground it sits on. A retheme that misses one hard-coded value shows up as
one wrong-coloured chip that nobody notices for weeks.

## What not to do

No cream-and-terracotta. No purple-to-blue hero gradient. No emoji as section markers.
No centring everything. No `rounded-lg` on every element regardless of role. If a
choice would look the same on any other page, it is the wrong choice.
