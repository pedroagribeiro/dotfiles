---
name: nutrium-brand-web
description: Nutrium brand layer for web pages built with the artifact-style skill — Claude artifacts, standalone HTML, design docs, reports and dashboards made in the Nutrium repository. Swaps the base tokens for Nutrium's (mint #62CDC0, ink neutrals, coral only for the worse side of a comparison), adds the Geomanist eyebrow face and the Nutrium logo. Load it right after artifact-style whenever a page is built from the Nutrium repo. Not for Google Slides/Docs/Sheets — that is nutrium-branding.
---

# Nutrium brand layer (web)

A layer on top of `artifact-style`. Load that skill first: it owns the layout, the
type scale and every component. This one only changes token values and adds the
logo and the Geomanist face. **Never restyle a component here.** If a page needs a
new component, add it to the `artifact-style` template so both looks get it.

Source of the values: the Nutrium Design System ramps (Figma "WEBSITE NUTRIUM 2025"),
as used in the "Food quantities in ounces" page
(https://claude.ai/artifact/DtRnUPAg23mBUDzu7Fox7y).

## Applying it

After copying and filling `artifact-style/template.html`:

```bash
python3 -I ~/.claude/skills/nutrium-brand-web/scripts/apply_brand.py <page.html>
python3 -I ~/.claude/skills/artifact-style/scripts/check_page.py <page.html>
```

The script fills the template's `<!-- brand:head -->`, `<!-- brand:logo -->` and
`<!-- brand:logo-footer -->` markers. It adds the brand tokens, the Geomanist
`@font-face` as a base64 data URI (artifacts can't load fonts from anywhere but Google
Fonts or the page's own files), the logo sprite and the two logo instances. The page
grows by about 55 KB. Keep the markers in place until the script has run.

## What the layer sets

- **Accent = brand mint.** `--accent` `#62CDC0` for fills, `--accent-text` `#23756B`
  (dark: `#7FDACF`) for text, `--accent-soft` teal-100 `#E3F4F4`.
- **Text on mint is ink, not white.** `--on-accent` is `#1F232C`. White on `#62CDC0` is
  about 2:1 and fails contrast; the original page had that bug.
- **Second accent = Nutrium blue** (`#3569AD` on blue-100 `#EBF4FF`, darkened from
  `#4381CB` so the 12px tag text passes).
- **State:** ok uses the mint text tones (mint means the favourable option); warn uses
  the yellow ramp; err uses coral `#AD3E26` on coral-100. **Coral marks only the worse side of a
  comparison or a real error**, never decoration.
- **Neutrals:** ink-900 headings, ink-800 body, ink-600 muted, ink-300 borders, page
  `#FAFCFF`.
- **Atmosphere:** mint and sky glows in the hero; the h1 gradient word runs
  `#1AB394 → #62CDC0 → #83BCFF`.
- **Eyebrows in Geomanist Medium** (`--font-display`). Everything else stays Poppins.
- **Logo:** 136px at the top of the hero, 96px in the footer, coloured by `--logo`
  (logo green `#1AB394`, white in dark). Never recolour or redraw it.

## Copy

Nutrium pages follow the brand voice: US English unless the audience is Portuguese,
"dietitian" and "appointment" in English, "nutricionista" and "consulta" in
Portuguese. No em dashes in the page's copy.
