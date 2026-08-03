# Sheepshead content accuracy pass, 2026-08-03

Pre-release rules audit of every authored drill. The earlier port audit
confirmed the deck, trump, and point model. This pass checked the teaching
claims themselves and found genuine rules errors, all of which are fixed and
now locked in by `ContentValidityTests`.

## Rules errors found and fixed

1. **The picker cannot call an ace they were dealt.** Nine items implied the
   opposite, either by showing the called ace inside the picker's own holding or
   by describing a call the deal made illegal: `bury-scenario-2`,
   `bury-scenario-5`, `more-bury-2`, `plus-bury-2`, `master-bury-1`,
   `more-hand-5`, `plus-hand-5`, `master-hand-7`, `read-match-5`, and the tiles
   on `master-defense-1`. Every bury scenario now declares its `calledSuit` and
   the tests reject a deal that contains that ace.
2. **Wrong card counts in `bury-what`.** It read "the picker has six cards after
   taking the blind" and "keep four, bury two". The picker holds eight after the
   blind and keeps six.
3. **Buries that gave away trump.** `bury-scenario-1`, `bury-scenario-4`,
   `bury-scenario-6`, and `master-bury-4` recommended burying a diamond, a
   queen-suit trump, or the diamond 10 while keeping a zero-point fail card.
   Trump is control and now never appears in a recommended bury.
4. **Ambiguous graded answers.** `more-bury-4` offered four interchangeable
   zero-point fail cards, so the graded pair was arbitrary. `master-bury-2`,
   `master-hand-1`, and `master-hand-2` each had two equally correct answers.
5. **Holdings that did not match their category.** `plus-hand-1` and
   `more-hand-1` were marked Trump Stack while containing fail cards.
   `more-hand-6` was described as "four strong trumps and a point diamond" when
   all five cards were trump.
6. **Fail-suit facts.** `read-point-cards` called the king fourth in its fail
   suit; it is third, behind the ace and the 10. `more-hand-2`, `plus-hand-2`,
   and `master-hand-4` each called a five-card holding a "full" or "complete"
   fail suit, but a fail suit holds six cards.
7. **Garbled copy.** The `trick-fail-winner` explanation ended mid-thought.
8. **Unsubstituted placeholder.** `HandGenerator.explain` returned the literal
   text "All five cards are (suit) fail cards" because the interpolation was
   missing, so generated practice showed the placeholder to players.

## Bury model the drills now teach

Every recommended bury is the strict best play under three stated principles,
ranked in this order:

1. Never bury trump. Queens, jacks, and diamonds are control.
2. Empty a short fail suit when you can, so that suit can be trumped later.
3. Bank the most points possible. Buried points count for the picking side and
   cannot be captured.

A picker may only name a fail ace they were not dealt, and must keep at least
one card of that suit. A hand that leaves no legal call is marked `isAlone`.

## Enforcement

`ContentValidityTests` now fails the build on any regression:

- `testBuryRecommendationsNeverContainTrump`
- `testBuryRecommendationIsTheUniqueBestBury` enumerates every legal two-card
  bury and requires the authored answer to be the unique maximum
- `testCalledSuitScenariosObeyTheCallAnAceRules`
- `testBuryScenariosAreEitherPartnershipHandsOrMarkedAlone`
- `testHandMatchDistractorsDoNotAlsoFitTheHolding`
- `testGeneratedFailSuitExplanationNamesTheSuit`

59 tests, 0 failures, on `agent-sheepshead`.
