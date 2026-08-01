#!/usr/bin/env python3
"""Synchronize the Sheepshead+ product paragraph in fastlane metadata.

The source locale is en-US. Other locales are updated with the same accurate
English product block until a reviewed translation is available. This avoids
shipping copy that describes a different game or product model.
"""
from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent / "fastlane" / "metadata"
PLUS_HEADING = "SHEEPSHEAD+ (optional upgrade)"
PLUS_BODY = (
    "Everything above stays free, forever. Sheepshead+ adds one extra practice "
    "set in every beginner room, plus The Master Tables for advanced picker, "
    "partner, bury, and trick decisions. New drills are added "
    "throughout the year."
)
SUBSCRIPTIONS_HEADING = "SUBSCRIPTIONS"


def replace_plus_section(text: str) -> str:
    pattern = re.compile(
        r"(?ims)^[^\n]*(?:SHEEPSHEAD\+|THE MASTER TABLES)[^\n]*\n.*?"
        r"(?=^\s*(?:SUBSCRIPTIONS|BUILT FOR NEW PLAYERS|WHY IT WORKS)\s*$)",
    )
    replacement = f"{PLUS_HEADING}\n{PLUS_BODY}\n\n"
    updated, count = pattern.subn(replacement, text, count=1)
    if count:
        return updated
    marker = re.search(r"(?im)^\s*SUBSCRIPTIONS\s*$", text)
    if marker:
        return text[: marker.start()] + replacement + text[marker.start() :]
    return text.rstrip() + "\n\n" + replacement


def main() -> None:
    en_us = ROOT / "en-US" / "description.txt"
    source = en_us.read_text(encoding="utf-8")
    for locale_dir in sorted(ROOT.iterdir()):
        description = locale_dir / "description.txt"
        if not description.is_file():
            continue
        original = source if locale_dir.name == "en-US" else description.read_text(encoding="utf-8")
        updated = replace_plus_section(original)
        description.write_text(updated, encoding="utf-8")
        print(f"updated {description}")


if __name__ == "__main__":
    main()
