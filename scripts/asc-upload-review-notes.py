#!/usr/bin/env python3
"""Push fastlane/metadata/review_information/notes.txt to App Store Connect.

    source ~/.baseball_credentials
    python3 scripts/asc-upload-review-notes.py [--dry-run]

asc-upload-metadata.py deliberately skips review_information (asc_lib.py:257,
it is not a locale directory), and asc-finish-submission.py only syncs the
contact email. Nothing else carried the reviewer notes, so the field silently
kept whatever the last manual paste left in it. This closes that gap and is
idempotent: it patches only when the stored notes differ.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from asc_lib import (
    ASCClient, bearer_token, bundle_id_from_appfile, find_app,
    find_editable_version, load_credentials,
)

# App Store Connect rejects a longer value outright.
MAX_NOTES = 4000


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    path = Path(__file__).resolve().parent.parent / "fastlane/metadata/review_information/notes.txt"
    notes = path.read_text().strip()
    if not notes:
        print(f"error: {path} is empty")
        return 1
    if len(notes) > MAX_NOTES:
        print(f"error: notes are {len(notes)} chars, ASC allows {MAX_NOTES}")
        return 1

    key_id, issuer_id, key_path = load_credentials()
    client = ASCClient(bearer_token(key_id, issuer_id, key_path))
    app = find_app(client, bundle_id_from_appfile())
    version = find_editable_version(client, app["id"])
    if not version:
        print("error: no editable version")
        return 1
    vid = version["id"]
    version_string = version["attributes"].get("versionString")

    detail = client.get(f"/appStoreVersions/{vid}/appStoreReviewDetail").get("data")
    if not detail:
        print("error: version has no appStoreReviewDetail")
        return 1

    if detail["attributes"].get("notes", "").strip() == notes:
        print(f"review notes already current on {version_string}")
        return 0

    if args.dry_run:
        print(f"would patch review notes on {version_string} ({len(notes)} chars)")
        return 0

    client.patch(
        f"/appStoreReviewDetails/{detail['id']}",
        {
            "data": {
                "type": "appStoreReviewDetails",
                "id": detail["id"],
                "attributes": {"notes": notes},
            }
        },
    )
    print(f"review notes -> {version_string} ({len(notes)} chars)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
