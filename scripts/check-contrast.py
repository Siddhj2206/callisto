#!/usr/bin/env python3
"""WCAG contrast of the color pairs the shell draws, in both modes.

Translucent materials are composited over the worst thing that could be behind
them (black under the light scheme, white under the dark one). Thick sees the
windows below, so it has to pass as it is. Mica and Glass see the wallpaper only
and the shell raises their alpha until secondary text passes (Scheme.legible),
so for those this shows how far it has to go over the worst wallpaper.

    scripts/check-contrast.py [tokens.json ...]    # default design/tokens.json
    scripts/check-contrast.py --all                # every ratio, not just misses

A tokens.json compiled by the engine (~/.config/callisto/tokens.json) works too,
to check a particular wallpaper's colors.
"""

import json
import sys
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

TEXT = 4.5  # WCAG AA, normal text
SHAPE = 3.0  # AA for controls and their states


def rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) / 255 for i in (0, 2, 4))


def over(color, alpha, under):
    return tuple(c * alpha + u * (1 - alpha) for c, u in zip(color, under))


def luminance(color):
    r, g, b = (c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in color)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(a, b):
    high, low = sorted((luminance(a), luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def legible(role, fill, material, behind):
    """The alpha the shell would use: Scheme.legible in the generated theme."""
    ink = rgb(material["ink"])
    alpha = material["designed"]
    while alpha < 1:
        under = over(ink, material["veil"], over(role[fill], alpha, behind))
        if ratio(role["on_surface_variant"], under) >= TEXT:
            return alpha
        alpha += 0.01
    return 1


def pairs(tokens, mode):
    """(foreground name, background name, ratio, wanted)"""
    role = {k: rgb(v) for k, v in tokens["color"][mode].items() if isinstance(v, str) and v.startswith("#")}
    material = tokens["material"] if "alpha" in tokens.get("material", {}) else tokens["ui"]["material"]
    material = material[mode]
    ink = rgb(material["ink"])
    behind = (0, 0, 0) if mode == "light" else (1, 1, 1)

    surfaces = {"surface": role["surface"]}
    for name, fill in (("mica", "surface_container_low"), ("glass", "surface_container_high")):
        alpha = legible(role, fill, {**material, "designed": material[name]}, behind)
        surfaces[name] = over(role[fill], alpha, behind)
    surfaces["thick"] = over(role["surface_container_high"], material["thick"], behind)
    # Rows, chips and fields sit on a veil over each of those.
    backgrounds = dict(surfaces)
    for name, base in surfaces.items():
        backgrounds["veil on " + name] = over(ink, material["veil"], base)

    for background, color in backgrounds.items():
        for foreground in ("on_surface", "on_surface_variant"):
            yield foreground, background, ratio(role[foreground], color), TEXT
    # Section headings and text buttons.
    yield "primary", "surface", ratio(role["primary"], role["surface"]), TEXT
    for fill in ("primary", "secondary_container", "primary_container", "tertiary_container", "error_container"):
        text = "on_" + fill
        if text in role and fill in role:
            yield text, fill, ratio(role[text], role[fill]), TEXT
    # A switch's outline and a filled control against the page.
    for shape in ("outline", "primary"):
        yield shape, "veil on surface", ratio(role[shape], backgrounds["veil on surface"]), SHAPE


def terminal(tokens, mode):
    """The terminal theme the engine would write for this scheme."""
    loader = SourceFileLoader("engine", str(REPO / "bin/callisto-apply"))
    engine = module_from_spec(spec_from_loader(loader.name, loader))
    sys.dont_write_bytecode = True
    loader.exec_module(engine)
    theme = dict(line.split("=", 1) for line in engine.emit_foot_theme({"color": {"dark": tokens["color"][mode]}}).splitlines() if "=" in line)
    background = rgb(theme["background"])
    # "Black" on dark and bright black are for backgrounds and comments.
    names = [f"{kind}{i}" for kind in ("regular", "bright") for i in range(1, 8)]
    for name in names:
        yield "terminal " + name, "terminal", ratio(rgb(theme[name]), background), TEXT


def main(argv):
    every = "--all" in argv
    paths = [Path(a) for a in argv if not a.startswith("--")] or [REPO / "design/tokens.json"]
    misses = 0
    for path in paths:
        tokens = json.loads(path.read_text())
        for mode in ("dark", "light"):
            for foreground, background, got, wanted in [*pairs(tokens, mode), *terminal(tokens, mode)]:
                failed = got < wanted
                misses += failed
                if failed or every:
                    print(f"{'MISS' if failed else 'ok  '} {mode:5} {foreground:24} on {background:20} {got:5.2f} (want {wanted})")
    print(f"check-contrast: {misses} below WCAG AA" if misses else "check-contrast: all pairs pass")
    return 1 if misses else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
