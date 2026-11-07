VERDICT: FAIL

# Verification of the state machine fixes, 2026-11-06

Independent check of `state-machines-2026-11-06-fixes.md` against `state-machines-2026-11-06-review.md` and the whole change `git diff e06572ed0bd4d9002c67343378ebb335a1f1403b..HEAD` (commits `fa0f9f7`, `f8a2480`, `58c42a8`, `1c2c395`; the fixes doc cites them by their pre-rebase hashes `69c7206`, `707e711`, `493dee4`). Every claim was re-read in the code. Nothing in the app or its tests was changed.

Why it fails: the C2 fix tears the game night reminder down on RevenueCat's on-device cache, not on a fresh network answer. That cache also reads "not a member" for a paying member whose subscription renewed while the app was closed, so the fix switches off a current member's reminder (check 4, and a real regression). B1 works and is clean.

## Fixes

| id | Works on the review's route | Regression check | Evidence |
|---|---|---|---|
| C2 | Yes for the lapsed member the review describes. A cold launch with an inactive record now turns the flag off and removes the pending request. | FAIL. Clears a stored setting on an inferred state (cached entitlement), and drops a renewing member's reminder. | See "Must change". Route through the fix: `HomeView.swift:56` (onAppear) and `:114-115` (onChange of `membershipResolved`) call `AppSettings.dropGameNightReminderUnlessMember` (`AppSettings.swift:235-238`), which only checks `membershipResolved && !isPro`. Off goes through `gameNightReminderEnabled.didSet`, which calls `cancelGameNightReminder` (`AppSettings.swift:103-111`). Test `testLaunchAsLapsedMemberDropsGameNightReminder` passes on HEAD (run 42351580361) and fails with the app fix reverted (run 42349003055, tile read "Game Night Prep, Thursday"). Screenshots of run 42351580361: non-member with the flag stored on shows "Weekly"; member shows "Thursday". |
| B1 | Yes. Undo restores the `PracticeRecordStore` row and the `ProgressStore` seen/missed marks taken before the grade, and also takes back a choice already picked on the card showing when Undo is tapped. | Pass. No stored format change; a restored row is the exact pre-grade value, so attempts, correct, streak, ease, interval, due date and roomID all return. Newest-first restore order is right even when the same card is both the pending pick and the undone swipe (a missed last card re-queued behind itself): the older snapshot is applied last. | `FlashcardDrillView.swift:245-251` (snapshot before the pick is graded), `:355-372` (snapshot for plain cards, pick's snapshot carried into `lastSwipe`), `:384-400` (restore pending then swipe), `:402-413`. Stores: `PracticeRecordStore.swift:99-114`, `ProgressStore.swift` `itemMark`/`restoreItem`. Tests `testUndoThenReanswerDoesNotCountTwice` and `testUndoneMistapLeavesNoMissInStats` pass on HEAD (run 42351580361) and fail with the app fix reverted (run 42349003055: `("1") is not equal to ("0")`, and "the undone mistap still counts against accuracy"). Unit tests `testRestoreTakesBackAnUndoneMiss`, `testRestoreKeepsAnUndoneHitFromDoublingTheStreak`, `testRestoreItemPutsSeenAndMissedBack` pass (run 42344956984); they call the new API, so they cannot compile without the fix. |
| `fa0f9f7` (test infra) | Not a claim. One `NSPredicate` per query so `SheepsheadUITests` compiles on Xcode 27.1. | Pass. Test-only, no behaviour change. | `FlashcardDeckUITests.swift:74-80`. |

## Must change

C2: only a fresh network "not a member" may switch the reminder off.

- `SubscriptionService.start()` applies `Purchases.shared.cachedCustomerInfo` before any network call (`SubscriptionService.swift:93`), and `apply` sets `membershipResolved = true` for any record (`:374`). So the drop at `HomeView.swift:56` / `:114-115` runs on the cached record, before `refreshCustomerInfo` (`:244-250`) answers.
- RevenueCat judges a cached record against its `requestDate` only within 3 days; after that it judges against the current date (`CustomerInfo+ActiveDates.swift`, `requestDateGracePeriod = .days(3)` and `referenceDate(for:)`, purchases-ios 5.80.3; the review relied on the same lines for C2). The cache holds the expiry from the last time the app read it, so it cannot tell "expired" from "renewed since".
- Route that now breaks: a monthly (or yearly, or trial-converting) member sets the game night reminder. Their subscription renews while the app is closed. They next cold-launch more than 3 days after their previous launch (a weekly game night habit does exactly this). The cached record reads inactive, `membershipResolved` is true, `isPro` is false, so the reminder is switched off and its request removed. Moments later the network says active and `isPro` flips true, but nothing turns the reminder back on. A paying member silently loses the feature they set up, at roughly every renewal. Before the fix this sequence cleared nothing: `isPro` went false to false (no `onChange`) then false to true.
- It also breaks the audit's own transition table: M3 invariant 1 and the M5 row "member, refunded or expired while app closed" assume a stale cache is never treated as a lapse.
- The simulator cannot show this (simulator builds never configure RevenueCat, `SubscriptionService.swift:85-89`, so `membershipResolved` is set without a cache), which is why the new tests and screenshots pass.
- Direction: drop only when the inactive answer is fresh, for example gate on a record whose `requestDate` is within `freshBaselineAge` (the rule `observe` already uses, `SubscriptionService.swift:412-413`), or on a flag set only by a network `customerInfo` result. Add a unit test that a stale inactive record followed by an active one leaves the reminder on.

## Disputed, skipped and held

The fixes doc has no "Disputed" section. Rulings on what it skipped or held:

- C4, skipped as NOT A BUG: accepted. The base-commit UI test run 42332894569 (artifact checked) shows that opening the route over Settings dismisses Settings and presents the paywall (Close, Retry loading prices, Start 7-Day Free Trial on screen, no Done), so the tap is not lost and `showPaywall` does not stick. The fix was reverted with its DEBUG hook; nothing of it remains in the diff. C4 was UNVERIFIED, and no fix for it shipped.
- C1, restore half, held for Jack: accepted. UNVERIFIED in the review, not runnable headless, no failing test possible on `e06572e`, and nothing was changed for it. The held question is a product call.
- C1 revoke half, B2, C3: NOT A BUG in the review and left alone. Correct.
- B2's repro test was not kept: correct, the review showed it encodes a preference against a documented rule.

## Scope

- No change to trial, onboarding, paywall, prices, offers or how membership is judged. `SubscriptionService.swift` is untouched.
- No backend, App Store Connect or RevenueCat change needed.
- No stored data format change: `practice.records`, `progress.seenItems` and `progress.missedItems` are written in the same shape (`PracticeRecordStore.swift:139-141`, `ProgressStore.swift`).
- Failure under check 4: C2 clears a stored setting on an inferred state (a cached entitlement). See "Must change".
- Every in-scope review claim is in the fixes table or the summary line.

## Regression sweep (diff only)

- Existing users after upgrade: no migration; B1 reads stored rows as before. C2 can switch off a stored reminder for a renewing member (above).
- Widgets and watch: none in this project (`project.yml` has one app target and test bundles).
- Notifications: C2 removes `sheepshead.gameNightReminder` through the existing `didSet`. The permission-denied path (`AppSettings.swift:197-207`) and the daily reminder are untouched. `consumePendingDestination` waits for membership before its non-member branch, and the drop itself refuses an unresolved state, so the 4s offline fallback (`HomeView.swift:255-265`) tears nothing down.
- Entitlements and trials: membership logic untouched; the DEBUG local override path behaves as before.
- Undo and edit paths: covered above; Undo after the deck finishes is not offered (toolbar lives in `drillBody`), unchanged.
- Day and time zone: nothing touched.
- Localized text and iPhone Duo layouts: no strings or layout changed.

## Test results

All on GitHub's Macs via `gh-sim`, Xcode 27.1, iPhone 17 on iOS 27.2.

- Full unit suite on HEAD, `gh-sim test --scheme Sheepshead`: run 42344956984, Passed, 177 passed, 0 failed. Matches the fixes doc (run 42336704795, 177 passed).
- Revert proof on a throwaway branch (`Shared/` and `Sheepshead/` reset to `e06572e`, all tests kept), the three regression tests in one `--only` run: run 42349003055, 0 passed, 3 failed: `testLaunchAsLapsedMemberDropsGameNightReminder` ("Game Night Prep, Thursday"), `testUndoThenReanswerDoesNotCountTwice` (`("1") is not equal to ("0")`), `testUndoneMistapLeavesNoMissInStats` (accuracy not 100%). The scratch branch was deleted. A first dispatch of this run failed on a GitHub API rate limit (infrastructure, no run created) and was redispatched.
- UI regression tests plus the deck test on HEAD, with launch screenshots: run 42351580361, Passed, 5 passed, 0 failed.
- No test newly fails.

## Notes

- Screens: `HomeView` and `FlashcardDrillView` changed logic only. `gh-sim launch` can reach Home but not the deck (no deep links); Home was screenshotted as a non-member and as a member with the reminder stored on, and showed "Weekly" and "Thursday" on the Game Night Prep tile as expected. The deck's Undo was exercised by the passing UI tests instead.
- The project rule `membership-and-trial.md` says `membershipResolved` means "cache or network", which is what the C2 fix followed. That is true as a definition, but a resolved cache is not a fresh "not a member", and the new note in `.claude/rules/game-night.md` should say so once C2 is reworked.
- Style only: B1's `GradeSnapshot` carries the card ID separately from the card already held in `SwipeRecord`; harmless.
