# Sheepshead rules audit, 2026-10-22

Baseline: `c7d9cf1c`. Scope: all registered lessons, generated patterns, bury recommendations and grading on both platforms. The original tree is preserved. This is a trainer, without a live multiplayer or cumulative payout engine.

Final integration base: `4296405` (current origin/main). Some corrections listed below were already present there and were retained. The table records findings in the original local checkout as well as the remaining fixes. Final verification covers the newer generated engines too.

## Authority and exact variant

[Sheepshead.org Basic Rules](https://www.sheepshead.org/rules/sheepshead-basic-rules/) describes the common five-player game and house variants. [Pagat's Sheepshead rules](https://www.pagat.com/schafkopf/shep.html), Identifying a Partner, explicitly describes both players' called-suit reservation obligations.

The bury drills use five-player called ace, with the option to go alone. They exclude under/unknown calls and calling a ten; owning all fail aces therefore leaves no call in the basic bury-drill agreement. Other table variants, including calling a ten, remain described in the teaching text. Jack-of-diamonds partnership, alternate player counts, leasters, doublers, cracks and bump/payout variants are not offered as playable modes or graded calculations. The primer asks players to agree the all-pass rule at their actual table. These house variations are not interchangeable with this drill's agreement.

| Authoritative rule for this variant | Test on both platforms |
| --- | --- |
| 32 cards, 7-A. Five players get six; blind has two. Picker takes blind and buries two, leaving six. | Existing deal invariants; `everyCardValueAndFullTrumpOrder` |
| Four queens C,S,H,D, four jacks C,S,H,D, then diamonds A,T,K,9,8,7: fourteen trumps. Fail cards exclude queens/jacks and rank A,T,K,9,8,7. | Full trump and fail order tables |
| Card points A/T/K/Q/J =11/10/4/3/2; 7/8/9=0; deck totals 120. | All ranks across four suits |
| Follow trump or led fail suit. When void, discard or trump, subject to the called-suit reservation. Highest trump wins, otherwise highest led suit. No obligation to overtrump. | Legal-play and trick tables |
| Call only a fail ace absent from hand and blind, keeping at least one fail card of that suit. Burying an ace does not make it callable. | `callingCannotUseAceFromHandBlindOrBury` |
| Picker reserves one hold card until the called suit is first led (last-trick exception). Partner reserves the ace and must play it on that first lead, even with another card of the suit. Either may lead the called suit. | Twelve legal-play rows, linked to two actual graded questions |
| Called-ten alternative (when agreed): all three fail aces held, call an absent fail ten and retain its ace. Picker must save/play that ace; partner must save/play the ten on the called-suit lead. | Called-ten eligibility and reservation rows on both platforms |
| Burying trump is legal. Bury points count for the picking side. The picking side needs 61; 60-60 loses. | `buryLegalityIsSeparateFromTheGradedStrategy`, `trickWinnersAndSixtySixtyLoss` |

## Corrections

| Before | After | Regression |
| --- | --- | --- |
| Bury advice says every queen, jack and diamond stays whenever fail cards exist, without declaring the grading objective. | Explicitly state trump buries are legal. Every bury exercise now says its objective: preserve trump, maximize emptied fail suits, then bank points while preserving the planned call. | Legal trump-bury rows plus every catalog scenario; existing unique-objective tests |
| Goal card omits the bury from the target; primer omits following trump. | Count tricks plus bury; follow the led suit group, including trump. | Target/bury and trump-follow tables, actual goal-card assertion |
| General permission to discard any card when void omits reserved ace/hold restrictions. | Explicit reservation and mandatory first-lead ace; new graded examples. | Called-ace and picker-hold rows |
| Holding all aces presented as universally forcing alone. | Identify no-under/no-ten agreement; acknowledge other tables' additional calls. | Variant primer and no-call cases |
| `master-hand-1` describes three high trumps plus diamond ace, but displays two queens, diamond A/T, club A. | Accurately describes four trumps and a fail ace. | Full card and pattern invariants; reviewed explanation |
| Low-trump bury rationales claim fail aces/points can never be protected. | Describe the stated void/points objective without predicting unseen opponents. | Every bury's explicit objective and existing objective optimizer |

The engine checker separates legality from the teaching preference. Existing bury tests still prove the coach's pair uniquely meets each stated objective. These are not claims that the pair maximizes win probability against every unknown deal. The current generated-trick winner engine is independently cross-checked as well. The app does not grade a regional cumulative scoring schedule; only card points and the 61-point winning target are claimed here.

## Verification

`RulesAuditTests.swift` and `RulesAuditTest.kt` use the same independently authored reference tables. Run `xcodegen generate`, the `Sheepshead` unit-test scheme and `fm-gradle testDebugUnitTest` from `android/`. See `verification.md` for final receipts.
