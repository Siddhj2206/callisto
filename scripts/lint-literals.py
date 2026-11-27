#!/usr/bin/env python3
"""Fail on raw sizes, colors, fonts and durations in component code.

Everything visual comes from the tokens (scripts/generate-theme.py). Only
tokens/ and foundations/ may hold numbers. 0, 1, 2 and 0.5 are allowed (centring, halving); anything else needs a token.

Also fails when two component folders define the same type name: a file that
imports both silently gets one of them.
"""

import re
import sys
from pathlib import Path

SHELL = Path(__file__).resolve().parent.parent / "shell" / "triton"
CHECKED = ["primitives", "patterns", "surfaces"]
# Properties whose values are looks. Logic such as thresholds is not flagged.
PROPERTY = re.compile(
    r"\b(?:width|height|implicitWidth|implicitHeight|radius|spacing|x|y|size|"
    r"margins|\w+Margin|padding|\w+Padding|pixelSize|duration|border\.width|"
    r"strokeWidth|opacity|scale|fromScale|fromY)\s*:\s*(.*)"
)
NUMBER = re.compile(r"(?<![\w.])-?\d+(?:\.\d+)?(?![\w.])")
COLOR = re.compile(r'"#[0-9A-Fa-f]{3,8}"|Qt\.rgba\(|Qt\.hsla\(')
ALLOWED = {"0", "1", "-1", "2", "0.5"}


def main() -> int:
    problems = []
    for folder in CHECKED:
        for path in sorted((SHELL / folder).rglob("*.qml")):
            for number, line in enumerate(path.read_text().splitlines(), 1):
                code = line.split("//")[0]
                found = bool(COLOR.search(code))
                match = PROPERTY.search(code)
                if match:
                    value = re.sub(r'"[^"]*"', "", match.group(1))
                    found = found or any(n not in ALLOWED for n in NUMBER.findall(value))
                if found:
                    problems.append(f"{path.relative_to(SHELL.parent.parent)}:{number}: {line.strip()}")
    seen = {}
    for folder in CHECKED + ["foundations", "tokens"]:
        for path in sorted((SHELL / folder).rglob("*.qml")):
            other = seen.setdefault(path.stem, path)
            if other != path:
                problems.append(f"type name {path.stem} is defined twice: "
                                f"{other.relative_to(SHELL)} and {path.relative_to(SHELL)}")
    print("\n".join(problems) or "lint-literals: clean")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
