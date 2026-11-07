VERDICT: PASS

# Verification of the state machine fixes, 2026-11-06 (second pass, after the C2 rework)

Independent check of `state-machines-2026-11-06-fixes.md` against `state-machines-2026-11-06-review.md` and the whole change `git diff e06572ed0bd4d9002c67343378ebb335a1f1403b..HEAD` (`fa0f9f7`, `f8a2480`, `58c42a8`, `1c2c395`, `958cfa8`, `7510e56`, `d7a68a6`, snapshot `c48a2ef`). This replaces the first verify doc, which failed C2 for acting on RevenueCat's launch cache. Every claim was re-read in the code, and RevenueCat's behaviour was read in purchases-ios 5.80.3 source, not assumed. Nothing in the app or its tests was changed.

Summary: both fixes work on the review's routes and break nothing found. The C2 rework now tears the reminder down only on a record newer than the launch cache (a network or live StoreKit answer) or one under 5 minutes old, which meets the "fresh network not a member" rule. The three top regression tests fail with the app fixes reverted and pass on HEAD. Full unit suite 179/179.

## Fixes

| id | Works on the review's route | Regression check | Evidence |
|---|---|---|---|
| C2 | Yes. A lapsed member's first launch: the cached record (more than 3 days old, read inactive by RevenueCat) is applied with `lapseConfirmed` false, so nothing is torn down. RevenueCat's background fetch of the stale cache delivers the network record through the delegate; its `requestDate` is the server's request time, later than the cache's, so `lapseConfirmed` turns true, `onChange(of: lapseConfirmed)` drops the flag, and `didSet` removes the pending request. A renewed member: the cache reads inactive (not confirmed, nothing dropped), the network record is active, `lapseConfirmed` stays false, the reminder stays. | Pass. Only `HomeView` reads `lapseConfirmed`; `isPro`, `membershipResolved`, `observe`, paywall and trial gating are untouched. No stored key added or changed. | `SubscriptionService.swift:102-104` (launch cache date captured before `apply`), `:391-395` and `:414-423` (`confirmsNoMembership`), `:97` and `:168-172` (no store: simulator), `:45` (not persisted). `HomeView.swift:56` (onAppear), `:118` (onChange of `lapseConfirmed`), `:129` (isPro to false), `:265` (non-member notification tap). `AppSettings.swift:236-239` then `:103-111` (`cancelGameNightReminder`). RevenueCat 5.80.3: `HTTPClient.swift:1015,1039-1045` (304 responses get the new request date), `Purchases.swift:111,2792-2799` (delegate gets the cache at set, recorded as last sent), `CustomerInfoManager.swift:157-198` (`cachedOrFetched` returns the cache and fetches a stale one in the background). Unit `GameNightReminderTests` (5 tests) and UI `testLaunchAsLapsedMemberDropsGameNightReminder` pass on HEAD; the UI test fails with the app fix reverted (run 42370133202, tile "Game Night Prep, Thursday"). |
| B1 | Yes. Undo restores the `PracticeRecordStore` row and the `ProgressStore` seen/missed marks taken just before the grade, for plain cards (at commit) and choice cards (at pick), and also takes back a pick already made on the card now showing. Restore order is newest first, so a missed last card re-queued behind itself ends at its pre-grade state. | Pass. Rows are written in the same `Codable` shape; a restored `nil` removes a row created by the undone answer. Undo is not offered after the deck finishes (toolbar lives in `drillBody`), unchanged. No other store is written by a flashcard grade, so nothing is left behind. | `FlashcardDrillView.swift:249` (snapshot before the pick is graded), `:361-372` (plain card snapshot, pick carried into `lastSwipe`), `:384-400` (restore pending then swipe), `:402-413`. `PracticeRecordStore.swift:99-114`, `ProgressStore.swift:122-138`. UI `testUndoThenReanswerDoesNotCountTwice` and `testUndoneMistapLeavesNoMissInStats` pass on HEAD (run 42367337902) and fail with the fix reverted (run 42370133202: `("1") is not equal to ("0")`; "the undone mistap still counts against accuracy"). Unit `testRestoreTakesBackAnUndoneMiss`, `testRestoreKeepsAnUndoneHitFromDoublingTheStreak`, `testRestoreItemPutsSeenAndMissedBack` pass (run 42363743269). |
| `fa0f9f7` (test infra) | Not a claim. One `NSPredicate` per query so `SheepsheadUITests` compiles on Xcode 27.1. | Pass. Test only. | `FlashcardDeckUITests.swift:74-80`; the deck test passes in run 42367337902. |

### What the tests leave open (device checks)

- C2, the RevenueCat wiring: no test drives `start()` or `apply` with a real cached record (no `CustomerInfo` fixture, `apply` is private, the simulator never configures RevenueCat). The unit tests check `confirmsNoMembership` and `AppSettings` in isolation; the UI test covers only the no-store simulator branch (`SubscriptionService.swift:97`). Device check, sandbox: (1) game night on, cancel, kill, move the clock 4 days past expiry, launch online: the reminder goes off within seconds and `getPendingNotificationRequests` no longer lists `sheepshead.gameNightReminder`; (2) same, but let the subscription renew: the reminder stays; (3) same as (1) in airplane mode: the reminder stays until the network answers.
- C2 depends on the network record differing from the cache. RevenueCat compares records without `requestDate` (`CustomerInfoResponse.swift:15-23`, `@IgnoreHashable`) and sends the delegate only a changed record (`CustomerInfoManager.swift:334-345`), and `cachedOrFetched` at launch hands back the cache, not the network answer. A lapse does change the record (`management_url` is null without an active subscription; a refund sets `refunded_at`), so the route works, but check (1) above is what proves it.
- B1 is covered end to end by the UI tests on the shipping deck.

## Must change

Nothing.

## Disputed, skipped and held

The fixes doc lists "Disputed: None." Rulings on what it skipped or held:

- C4, UNVERIFIED in the review, marked "Skipped, settled NOT A BUG": accepted. It was not skipped unproven: the review's own settling test was run on the base commit. I downloaded the artifact of run 42332894569 (`sheepshead-nofix-tmp`): `testLockedTileOpensPaywallAfterNotificationOverSettings` found Close, Retry loading prices and Start 7-Day Free Trial on screen and no Done, so routing the destination over Settings dismisses Settings and presents the paywall. The feared refused sheet with `showPaywall` stuck true does not happen on iOS 27.2, so no route reaches the fault there. The parked-destination alternative was reverted with its DEBUG hook; nothing of C4 remains in the diff. The route also now needs a C2 state (a non-member holding a game night request), which the C2 fix removes once the network answers.
- C1, restore half, held for Jack: accepted. UNVERIFIED, not runnable headless, nothing changed for it, and the question is a product call.
- C1 revoke half, B2, C3: NOT A BUG in the review and left alone. B2's repro was not kept, correctly.

## Scope

- No change to trial or onboarding flows, prices, offers, how membership is judged (`isPro` is set exactly as before, `SubscriptionService.swift:389`), or when a paywall appears (`HomeView.swift:262-268` shows it under the same condition; the added call only drops a reminder).
- No backend, App Store Connect or RevenueCat change.
- The C2 teardown acts only on a record newer than the launch cache or under 5 minutes old, never on the launch cache alone, a missing request or a failed call (a failed fetch never calls `apply`, `SubscriptionService.swift:263-265`). Simulator builds count as confirmed because there is no store at all, as before.
- No stored data format change; nothing migrated or reset.
- Every in-scope review claim (C2, B1) is fixed; C4 and C1 restore are ruled above. No held item was changed.

## Regression sweep (diff only)

- Existing users after upgrade: a member with the reminder on keeps it; a launch reads no new key. B1 reads old rows unchanged.
- The `isPro` true to false branch (`HomeView.swift:120-131`) now needs `lapseConfirmed`. In Release, `isPro` only falls on a record from `apply`, and every in-session record that differs from the launch cache comes from the network (or RevenueCat's offline StoreKit computation, `requestDate = Date()`, which reads renewals from StoreKit), so a real lapse while Home is open still drops the reminder (M5 row "membership lapses while Home is observing").
- Neighbouring transitions from the audit tables: M2 rows unchanged (`membershipResolved`, `isPro` and the snapshot logic untouched); M3 churn ask untouched; M6 non-member tap still parks and opens the paywall, now also drops the reminder only when confirmed, and the 4s offline fallback tears nothing down; M8/M9 Undo rows fixed, "last card commit" unchanged.
- Notifications: off goes through the existing `didSet`, which removes only `sheepshead.gameNightReminder`. The daily reminder and the permission-denied path are untouched.
- Entitlements and trials: a purchase or restore applies an active record and resets `lapseConfirmed` to false. Nothing re-enables the reminder after a rejoin, which was already true.
- Undo and edit paths: covered under B1.
- Day and time zone: `confirmsNoMembership` compares server dates with each other first, and its 5 minute window uses `abs`, so a device clock ahead or behind cannot make an old cache count.
- Widgets and watch: none in this project. Localized text and iPhone Duo layouts: no strings or layout changed.

## Test results

All on GitHub's Macs via `gh-sim`, Xcode 27.1, iPhone 17 on iOS 27.2.

- Full unit suite on HEAD, `gh-sim test --scheme Sheepshead`: run 42363743269, Passed, 179 passed, 0 failed. Matches the fixes doc (run 42357782920, 179 passed). All 8 added unit tests pass.
- UI regression and deck tests on HEAD with launch screenshots, `gh-sim all --scheme SheepsheadUITests --only .../StateMachineRegressionUITests --only .../FlashcardDeckUITests`: run 42367337902, Passed, 5 passed, 0 failed. Every added or edited UI test passes.
- Revert proof on a throwaway branch (`Shared/` and `Sheepshead/` reset to `e06572e`, all tests kept), the top three in one `--only` run: run 42370133202, 0 passed, 3 failed: `testLaunchAsLapsedMemberDropsGameNightReminder` ("Game Night Prep, Thursday"), `testUndoThenReanswerDoesNotCountTwice` (`("1") is not equal to ("0")`), `testUndoneMistapLeavesNoMissInStats` (accuracy not 100%). The scratch branch was deleted. The C2 rework's own unit test (`testStaleInactiveCacheThenActiveKeepsARenewedMembersReminder`) calls `dropGameNightReminderUnlessMember(lapseConfirmed:)`, which neither the base nor the first fix has, so without the rework it does not compile.
- Not run: `PaywallFunnelUITests` (buys through RevenueCat's Test Store over the network; untouched by this change).
- No test newly fails.

## Notes

- Screens: `HomeView` and `FlashcardDrillView` changed logic only. Run 42367337902 screenshots: as a non-member with the reminder stored on, Home's Game Night Prep tile reads "Weekly" (dropped); as a member with the same stored flag it reads "Thursday" (kept). `gh-sim launch` cannot reach the deck (no deep link); its Undo is exercised by the passing UI tests.
- DEBUG only: on a device build with RevenueCat configured, the Settings developer switch turning Pro off (`setLocalOverride(isPro: false)`, `SubscriptionService.swift:163-173`) no longer drops the reminder, since that is not a confirmed lapse. Release builds have no such switch.
- C4 was settled on iOS 27.2 only. The deployment target is iOS 17; how earlier SwiftUI handles the sibling sheet was not tested. Low stakes now that the C2 state it needs is cleared.
- The `lapseConfirmed` property comment says the launch-cache date is `distantPast` "when there was none"; it starts at `distantFuture` until `start()` runs (`SubscriptionService.swift:66-68`), which is the safe direction. Wording only.
- Style only: B1's `GradeSnapshot` stores the card id beside the card already held in `SwipeRecord`; harmless.
