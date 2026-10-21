#!/usr/bin/env python3
"""Apply the Nutrium brand layer to a page built from the artifact-style template.

Usage: python3 -I apply_brand.py page.html

Fills the template's markers in place:
  <!-- brand:head -->         brand tokens, the Geomanist @font-face and the logo sprite
  <!-- brand:logo -->         the logo at the top of the hero
  <!-- brand:logo-footer -->  the small logo in the footer

Geomanist is embedded as a base64 data URI because artifacts only load fonts from
Google Fonts or from files published with the page.
"""
import base64
import pathlib
import sys

ASSETS = pathlib.Path(__file__).resolve().parent.parent / "assets"
LOGO = '<svg class="logo" viewBox="0 0 1830 430" role="img" aria-label="Nutrium"><use href="#nutrium-logo" fill="currentColor"/></svg>'


def main(path):
    page_path = pathlib.Path(path)
    page = page_path.read_text(encoding="utf-8")

    missing = [m for m in ("<!-- brand:head -->", "<!-- brand:logo -->") if m not in page]
    if missing:
        print("Missing marker(s):", ", ".join(missing))
        return 1

    font_path = ASSETS / "Geomanist-Medium.otf"
    if not font_path.exists():
        # The font is licensed and git-ignored in the public dotfiles repo, so a fresh clone lacks it.
        print(f"Missing {font_path}. Copy it from fonts/Geomanist-Medium.otf in "
              "https://claude.ai/artifact/DtRnUPAg23mBUDzu7Fox7y")
        return 1
    font = base64.b64encode(font_path.read_bytes()).decode()
    css = (ASSETS / "brand.css").read_text(encoding="utf-8")
    css = css.replace("__GEOMANIST__", f"data:font/otf;base64,{font}")
    sprite = (ASSETS / "nutrium-logo-sprite.svg").read_text(encoding="utf-8").strip()

    page = page.replace("<!-- brand:head -->", f"<style>\n{css}</style>\n{sprite}", 1)
    page = page.replace("<!-- brand:logo-footer -->", LOGO, 1)
    page = page.replace("<!-- brand:logo -->", LOGO, 1)
    page_path.write_text(page, encoding="utf-8")
    print(f"Branded {page_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
