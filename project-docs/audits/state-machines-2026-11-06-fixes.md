# State machine fixes, 2026-11-06

Fixes for the claims `state-machines-2026-11-06-review.md` kept, in the review's ranked order, on branch `fleet/20261106-174800-2be4-claude` from `e06572e`.

Summary: 4 claims looked at (2 in scope, 2 unverified). 2 fixed (C2, B1), 0 held as a fix, 1 unverified claim settled as not a bug and skipped (C4), 1 unverified claim held for Jack (C1, restore half). Product calls P1 to P6 and the NOT A BUG claims (B2, C1 revoke, C3) were left alone. The regression check (`state-machines-2026-11-06-verify.md`) rejected the first C2 fix; it was reworked on 2026-11-07 (see "Verify rework"). 0 disputed.

## Claims

| id | Review verdict | Outcome | Commit | Regression test | What changed |
|---|---|---|---|---|---|
| C2 | CONFIRMED | Fixed | "fix: drop a lapsed member's game night reminder at launch", reworked by "fix: drop the game night reminder only on a fresh lapse" | `GameNightReminderTests` (unit: `testStaleInactiveCacheThenActiveKeepsARenewedMembersReminder`, the verify route; `testStaleInactiveCacheThenNetworkInactiveDropsTheReminder`, the audit route; `testFreshnessRules`; a confirmed lapse drops and stores the off, an unconfirmed one keeps it); `StateMachineRegressionUITests/testLaunchAsLapsedMemberDropsGameNightReminder` (UI: launch as a non-member with the reminder stored on, Home's Game Night tile must read "Weekly", not the day) | `AppSettings.dropGameNightReminderUnlessMember(lapseConfirmed:)` turns the reminder off (and removes the pending request) only on `SubscriptionService.lapseConfirmed`: a record that says no membership and was answered after the cached record launch applies, or within `freshBaselineAge` (5 minutes, either clock direction), or no store at all (simulator). Home calls it on appear, when `lapseConfirmed` changes, on a lapse and in the non-member branch of `consumePendingDestination`, so a lapse that happened while the app was closed is caught as soon as the network answers. `isPro` and `membershipResolved` are unchanged. |
| B1 | CONFIRMED-MINOR | Fixed | "fix: flashcard Undo takes back the answer it undoes" | `PracticeRecordStoreTests/testRestoreTakesBackAnUndoneMiss`, `testRestoreKeepsAnUndoneHitFromDoublingTheStreak`, `ProgressStoreTests/testRestoreItemPutsSeenAndMissedBack` (unit); `StateMachineRegressionUITests/testUndoThenReanswerDoesNotCountTwice` (the audit's repro, which the review called sound), `testUndoneMistapLeavesNoMissInStats` (the review's realistic mistap route), `testControlOneAnswerLocksInNothing` (control) | Each flashcard grade snapshots the `PracticeRecordStore` row and the `ProgressStore` seen/missed marks first; "Undo last answer" restores them (`snapshot`/`restore`, `itemMark`/`restoreItem`). A choice already picked on the card showing when Undo is tapped is taken back too, since that card returns unanswered. Stored data is read exactly as before; nothing is migrated or dropped. |
| C4 | UNVERIFIED | Skipped, settled NOT A BUG | none | none kept | See Skipped. |
| C1 (restore half) | UNVERIFIED | Held for Jack | none | none | See Held for Jack. |

Also committed: "test: build each NSPredicate per query so the UI test target compiles on Xcode 27.1" (test infra, not a claim). `FlashcardDeckUITests.open` built one `NSPredicate` and sent it twice, which Xcode 27.1 rejects, so the whole `SheepsheadUITests` target did not compile. Each query now builds its own predicate.

The audit's B2 repro (`testClosingFixMyMistakesEarlyScoresOutOfWhatWasAnswered`) was not kept: the review showed it encodes the auditor's preference against a documented scoring rule.

## Verify rework (2026-11-07)

The verify doc failed C2: the first fix acted on `membershipResolved`, which RevenueCat's on-device cache sets at launch (`SubscriptionService.start`, cached record applied before any network call). RevenueCat judges a cache more than 3 days old against today with the expiry it last read, so a member whose subscription renewed while the app was closed read as lapsed and lost the reminder at about every renewal. Accepted as stated; nothing disputed.

The rework adds `SubscriptionService.lapseConfirmed` and `confirmsNoMembership(isActive:answeredAt:launchCacheAnsweredAt:now:)`. A "not a member" counts only when the record was answered after the launch cache (so it came from the network, whatever the device clock says; with no cache at launch every record is a network answer), or within `freshBaselineAge`, the rule `observe` already uses. The launch cache itself never counts unless it is under 5 minutes old, and a clock running behind does not make an old cache fresh. The new unit test `testStaleInactiveCacheThenActiveKeepsARenewedMembersReminder` is the verify doc's route (a 4-day-old inactive cache, then an active network record: the reminder stays on and stays stored). On the first fix the same route called `dropGameNightReminderUnlessMember(isMember: false, membershipResolved: true)` on the cached record, which turns the reminder off; that API is gone, so the test cannot compile against it. The simulator cannot show the cache case (no RevenueCat there), so the UI test still covers only the launch-as-non-member route.

## Disputed

None.

## Held for Jack

- C1, restore to a new device: a player with the Daily Reminder (or game night reminder) on restores a backup to a new phone. The flag comes back with the defaults; whether iOS brings the pending request and the notification permission with it is not documented, and it cannot be checked headless (the review says the same; a web search found only anecdotes that notifications stop after a restore). If they do not come back, the toggle says on and nothing fires. Decision: on a launch with a reminder on and notification permission never asked on this device, should the app ask for permission again at launch to honour the old choice, or turn the toggle off so the player sees it is off and can switch it back on? (Rescheduling when permission is already granted is safe either way and can ride along with the answer.)

## Skipped

- C4: not a bug. Settled with a UI test on the base commit (GitHub run 42332894569) that, as a non-member, opens Settings and has a DEBUG hook route the game night destination while Settings is up. On iOS 27.2 SwiftUI closes Settings and presents the paywall immediately: the test's "Settings is still open" precondition failed with the paywall's Close, Retry loading prices and Start 7-Day Free Trial buttons on screen and no Done. So the notification tap is not lost, and since the paywall is really presented, `showPaywall` resets when it closes instead of sticking true (the review's feared dead-tile state needs a refused sheet, which does not happen). A change that parks the destination until Settings closes was tried and reverted: it would make the tap wait for the player to close Settings, which is worse than the current direct paywall. The DEBUG hook and the C4 tests were removed with it.

## Test results

Rework, 2026-11-07, all on GitHub's Macs via `gh-sim`, Xcode 27.1, iPhone 17 on iOS 27.2:

- Full unit suite with the C2 rework: `gh-sim test --scheme Sheepshead`, run 42357782920: Passed, 179 passed, 0 failed (177 before, 3 old C2 unit tests replaced by 5).
- UI regression tests plus the deck test with the C2 rework: `gh-sim test --scheme SheepsheadUITests --only SheepsheadUITests/StateMachineRegressionUITests --only SheepsheadUITests/FlashcardDeckUITests`, run 42361131495: Passed, 5 passed, 0 failed (including `testLaunchAsLapsedMemberDropsGameNightReminder`, which failed on `e06572e` in run 42332894569).
- No test newly fails. No test failed, so none is named as already failing on `e06572e`.

First pass, 2026-11-06, all on GitHub's Macs via `gh-sim`, Xcode 27.1, iPhone 17 on iOS 27.2.

- Full unit suite, fixed tree: `gh-sim test --scheme Sheepshead`, run 42336704795: Passed, 177 passed, 0 failed.
- New UI regression tests plus the deck test, fixed tree: `gh-sim test --scheme SheepsheadUITests --only SheepsheadUITests/StateMachineRegressionUITests --only SheepsheadUITests/FlashcardDeckUITests`, run 42340781158: Passed, 5 passed, 0 failed (4 regression tests and the double-tap deck test).
- Same UI tests without the fixes (base commit plus only the test files and the C4 DEBUG hook), run 42332894569: control passed; `testUndoThenReanswerDoesNotCountTwice` failed (`("1") is not equal to ("0")`), `testUndoneMistapLeavesNoMissInStats` failed (accuracy not 100%), `testLaunchAsLapsedMemberDropsGameNightReminder` failed (tile read "Game Night Prep, Thursday"). The new unit tests call the new store and settings methods, so they do not compile without the fix.
- Earlier fixed-tree run 42327472936 (5 passed, 2 failed): both failures were test navigation (the Settings link scrolled out of view, a tile off the side of its row); the tests were changed to read the Home tile instead, and the C4 pair was later removed.
- Not run: `PaywallFunnelUITests`, which buys through RevenueCat's Test Store over the network and is untouched here.
- No test newly fails. No test in the run above failed on `e06572e`, so none is named as already failing.
