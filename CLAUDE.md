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

The RevenueCat entitlement in this project is keyed `Sheepshead+`, not the
fleet's usual `pro`: RevenueCat will not let a lookup_key be edited and refuses
to create `pro` here. `SubscriptionService.apply(_:)` therefore treats any
active entitlement as membership instead of matching one key. Products live on
the App Store app record and are attached to the entitlement and to the
`$rc_monthly` / `$rc_annual` / `$rc_lifetime` packages of the current offering;
`scripts/rc-wire-appstore-products.py` is the idempotent script that does it.
The project shipped with Test Store products only, which serves an offering
with zero packages and a dead purchase button, so verify the SDK-facing
offering after any store change. The player
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
