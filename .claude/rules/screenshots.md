---
paths:
  - "scripts/capture-screenshots.sh"
  - "scripts/with-ipad-sim.sh"
  - "SheepsheadScreenshots/*"
---

# Sheepshead: screenshots

Moved verbatim from AGENTS.md. Loads when a matching file is read; update it here.

## Screenshots

`scripts/capture-screenshots.sh <udid> <out-dir> [prefix]` drives the real app
through the App Store screens via the `Screenshots` scheme.
`scripts/with-ipad-sim.sh` creates a throwaway 13-inch iPad (App Store iPad
shots must be 2064x2752 and the agent-sim pool has no iPad Pro), boots it
headless, and deletes it on exit:

```bash
./scripts/with-ipad-sim.sh sh -c './scripts/capture-screenshots.sh "$IPAD_UDID" out ipad_'
```

Gotchas baked into the test: the What's New sheet covers Home on the first
launch after a version bump and returns every time Home reappears, so the
script passes the marketing version in through
`TEST_RUNNER_SCREENSHOT_APP_VERSION` and the test marks it seen; returning to
the root only taps navigation-bar button 0 while a back button is there,
because on Home that button is the Settings gear; and the test never calls
XCTFail, because a failing UI test spends ten minutes collecting simulator
diagnostics first.

## iPhone Duo capture

DEBUG only (`Sheepshead/Utilities/DuoScreenshotMode.swift`). `-DuoSeed`
fills the real stores with a week of practice (streak, mastery rings, a weekly
gain baseline, endless topics, three Sheepshead Minutes, Sheepshead+ override; no
RevenueCat, no network), once per install (`duo.seeded`), so gh-sim's relaunch
for the inner display shows the same week. `-DuoTour -DuoRoutes a,b,c` walks
Home through routes on a timer, because the capture job cannot tap and `simctl
openurl` raises a confirmation sheet. Routes: home, quick, room-<id>,
drill-<id>, stats, endless, minute, prep, timed, howto, settings, paywall.
Dwell is `-DuoTourStep` (outer) and `-DuoTourStepRegular` (inner). The tour
restarts when the panes split or join, so each display gets a full walk, and it
lives outside the NavigationStack, not on Home's root (a pushed route would
cancel a task there).

```bash
gh-sim launch --device 'iPhone Duo' --wait 6 \
  --args "-DuoSeed -DuoTour -sheepshead.suppressWhatsNew -DuoTourFirst 1 -DuoTourStep 8 -DuoTourStepRegular 13 -DuoRoutes home,room-bury-room,drill-bury-two" \
  --url noop://1 ... --url noop://8
```

The launch step has a 10 minute cap that includes boot and every screenshot, so
keep to about 7 routes and 8 urls per launch. Screenshot cadence varies by runner (one
inner walk outran all eight inner shots), so for a must-have inner screen use
2 routes with `-DuoTourStepRegular 45`; the last route holds to the end. `--record-seconds` eats the same
budget. Never kill a watching `gh-sim`; reattach with `gh-sim get <id>`. Sizes:
outer 1398x2034, inner 2853x2007, both in `APP_IPHONE_DUO`.

Native video: `gh-sim all --record-seconds` records the test step and that
recorder holds the simulator, so the launch videos come back empty ("A
recording is already in progress"). Record in a separate `gh-sim launch` with
`-DuoTourFirst 6 -DuoTourStep 4 -DuoTourStepRegular 4` and about 3 urls, so the
pushes land after the inner recorder attaches; a long dwell records a still
screen. Score with `fleet-record60.py verify`.
