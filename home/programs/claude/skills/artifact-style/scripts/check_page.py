#!/usr/bin/env python3
"""Pre-publish check for a page built on the artifact-style template.

Usage: python3 -I check_page.py page.html

Reports brace balance, hex colours outside the token blocks, and WCAG contrast
for the token pairs the components actually put on top of each other, in both
themes. Later token blocks win, so a brand layer's overrides are honoured.
"""
import re
import sys

PAIRS = [
    ("fg", "bg"), ("fg", "surface"), ("heading", "surface"),
    ("muted", "bg"), ("muted", "surface"), ("muted", "soft"), ("muted", "warn-soft"),
    ("accent-text", "accent-soft"), ("accent-text", "bg"), ("accent-2", "accent-2-soft"),
    ("on-accent", "accent"),
    ("ok", "ok-soft"), ("warn", "warn-soft"), ("err", "err-soft"),
    ("code-fg", "code-bg"), ("code-key", "code-bg"), ("code-str", "code-bg"),
    ("code-num", "code-bg"), ("code-dim", "code-bg"),
]
LARGE_TEXT = {("on-accent", "accent")}

BLOCK = re.compile(r'(:root(?:\[data-theme="dark"\]|:not\(\[data-theme="light"\]\))?)\s*\{([^{}]*)\}')
TOKEN = re.compile(r'--([\w-]+)\s*:\s*(#[0-9a-fA-F]{6})\b')


def luminance(hex_colour):
    channels = [int(hex_colour[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def main(path):
    html = open(path, encoding="utf-8").read()
    styles = "\n".join(re.findall(r"<style>(.*?)</style>", html, re.S))
    problems = 0

    if styles.count("{") != styles.count("}"):
        print(f"BRACES  {{ {styles.count('{')}  vs  }} {styles.count('}')}")
        problems += 1

    # The dark selectors outrank bare :root, so every dark block wins over every bare block.
    light, dark_only = {}, {}
    for selector, body in BLOCK.findall(styles):
        (light if selector == ":root" else dark_only).update(TOKEN.findall(body))
    dark = {**light, **dark_only}

    stripped = BLOCK.sub("", styles)
    stripped = re.sub(r"/\*.*?\*/", "", stripped, flags=re.S)
    stripped = re.sub(r"@font-face\s*\{[^}]*\}", "", stripped)
    stray = sorted(set(re.findall(r"#[0-9a-fA-F]{3,8}\b", stripped)))
    body = re.sub(r"<style>.*?</style>", "", html, flags=re.S)
    stray += sorted(set(re.findall(r'(?:fill|stroke|color)\s*[:=]\s*"?(#[0-9a-fA-F]{3,8})\b', body)))
    if stray:
        print("STRAY HEX outside token blocks:", ", ".join(stray))
        problems += 1

    for theme, tokens in (("light", light), ("dark", dark)):
        for fg, bg in PAIRS:
            if fg not in tokens or bg not in tokens:
                continue
            ratio = contrast(tokens[fg], tokens[bg])
            floor = 3.0 if (fg, bg) in LARGE_TEXT else 4.5
            if ratio < floor:
                print(f"CONTRAST {theme:5}  --{fg} on --{bg}  {ratio:.2f} < {floor}")
                problems += 1

    print("OK" if problems == 0 else f"{problems} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
