# Sheepshead project guide

Sheepshead is a practice app for the common five-player Sheepshead variant.
It teaches the 32-card deck, trump, picking, partner play, burying, and trick
decisions. It is not a full multiplayer game. The XcodeGen project and scheme
are `Sheepshead`, the headless simulator is `agent-sheepshead`, and the bundle
ID is `com.jackwallner.sheepshead`.

## Product rules

The swipe deck is the signature interaction, but each room uses the interaction
that fits its skill: flashcards, choice questions, holding recognition, and
picker scenarios.

The teaching model uses the common five-player rules: a 32-card deck made from
7 through ace, queens and jacks plus diamonds as trump, six cards per player,
and a two-card blind. The picker takes the blind, buries two cards, and the
basic picking-team target is 61 of 120 points. House-rule differences are
called out in copy instead of hidden.

All authored examples are original teaching holdings. `ContentValidityTests`
covers every drill in `DrillLibrary`: valid 7 through ace cards, no repeated
physical card in a holding, eight-card picker holdings, two-card buries, unique
IDs, no em dashes, and the free versus Sheepshead+ split.

Bury scenarios are also checked against the rules, not just the shape. A
recommended bury never contains trump, and it must be the unique best pair
under: empty a short fail suit first, then bank the most points. A scenario
that plans a call sets `calledSuit`, which requires that the ace was not dealt
to the picker and that a hold card survives the bury; a scenario with no legal
call sets `isAlone`. Hand-match holdings may not fit any offered distractor.
See `docs/audits/sheepshead-accuracy-2026-08-03.md`.

The review funnel asks after the third positive drill: enjoying it, yes opens
the App Store review page for `6796913227`, no opens a feedback mail draft to
`jackwallner+m@gmail.com`. Unhappy players never see a rating ask.

## Sheepshead+ products

The local StoreKit configuration contains:

- `com.jackwallner.sheepshead.monthly`, $1.99 per month, one-week trial
- `com.jackwallner.sheepshead.yearly`, $9.99 per year, one-week trial
- `com.jackwallner.sheepshead.lifetime`, $29.99 one time

This project has two entitlements, `pro` and `Sheepshead+`, and every product
is attached to both. The scaffold keyed the entitlement to the player-facing
name and RevenueCat will not let a lookup_key be edited, so `pro` was added
alongside it: shipped binaries that check `entitlements["pro"]` and current
ones that accept any active entitlement both unlock on a purchase. Keep both
fed, which `scripts/rc-wire-appstore-products.py` does idempotently along with
creating the App Store products and attaching them to the `$rc_monthly` /
`$rc_annual` / `$rc_lifetime` packages of the current offering. The project
shipped with Test Store products only, which serves an offering with zero
packages and a dead purchase button, so run
`scripts/verify-store-config.py` before any submission. The player
facing membership name is `Sheepshead+`. The public RevenueCat key lives in
`Shared/Services/SubscriptionService.swift`. Simulator builds return before
`Purchases.configure`, so the production key is never used by simulator runs.

## Architecture

- `Shared/Models` contains `PlayingCard`, `Suit`, `HandCategory`, drill models,
  and room locking.
- `Shared/Content` contains the authored deck, trump, picker, bury, trick,
  primer, plus, and Master Tables content. `DrillLibrary.rooms` is the source
  of truth for the five rooms.
- `Shared/Services` contains progress, settings, spaced review, subscriptions,
  notifications, and the review funnel.
- `Sheepshead/Views` contains onboarding, the home lobby, room screens, the
  swipe deck, quick sessions, generated practice, settings, and the paywall.
- `Sheepshead/Utilities/Theme.swift` contains the warm card-table visual
  system, haptics, sounds, and reusable view styles.

Generated practice uses `HandGenerator` for mutually exclusive five-card rule
shapes and `PracticeRecordStore` for spaced review. `PracticeRunView` hosts
Endless Practice, Fix My Mistakes, and Timed Challenge.

## Content workflow

When adding a room or card set:

1. Add original content under `Shared/Content`.
2. Register the drill in `DrillLibrary` and assign its free or Sheepshead+ state.
3. Add or update invariants in `ContentValidityTests`.
4. Run `xcodegen generate`.
5. Run the unit tests and inspect the room in `agent-sheepshead`.

## Build and simulator rules

Use `xcodegen generate` after adding or removing Swift files or changing
`project.yml`. Use only `agent-sheepshead` for runtime checks. Never open
Simulator.app. Simulator builds must not configure the production RevenueCat
key.

Cardport's reusable porting workflow is in `/Users/jackwallner/cardport`.
Preserve the reference app's runtime, release, website, legal, and screenshot
surfaces when changing the domain.

## Game-night rhythm (1.2)

Sheepshead+ owns two recurring rituals. `SheepsheadMinuteContent` deterministically builds the
same five questions for every member on a local calendar day: two generated
hand reads, one bury decision, and two trick questions. Results and a 30-day
archive stay on device in `SheepsheadMinuteStore`; sharing uses the system share sheet and
needs no account or leaderboard.

The bury question is built straight from the authored scenarios, NOT through
`SessionBuilder.choiceItems`. The quick-session pool deliberately excludes
those drills, so drawing the daily from it silently produced a four-question
challenge with that skill missing entirely.

`HandGenerator` deals the daily hands from a caller-supplied generator all the
way down: `deal`, `fill`, and `randomHand` are all generic over
`RandomNumberGenerator`. One `.shuffled()` or `.randomElement()` left calling
the system source is enough to make the same day deal different hands on
different devices, and the stability test is what catches it.

`GameNightPrepView` stores a weekly game night in `AppSettings`, schedules a
local notification, and opens directly into `SessionBuilder.gameNightPrep`,
which prioritizes due mistakes, misses, the weakest room, and unseen member
content in that order. Both features are entirely Sheepshead+ gated.

## iPad (1.2)

iPad support is free: `TARGETED_DEVICE_FAMILY "1,2"`, portrait and landscape,
adaptive Home columns, drill grids, and readable content widths.

Every drill body is a scroll view, so a question that underfills the viewport
was pinned to the top and left the bottom half of a 13-inch iPad empty.
`CenteringScrollView` centres short content and leaves taller content scrolling
untouched (minHeight, not height). Keep its `maxWidth: .infinity`: a plain
ScrollView centres narrow content for you, an explicitly framed one does not.
The room eyebrow lives INSIDE `QuestionPager` so it centres with the question,
and the flashcard deck is capped at 520pt wide so a card still looks like a
card.

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
