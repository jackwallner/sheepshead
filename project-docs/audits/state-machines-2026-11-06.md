# State machine audit, 2026-11-06

Scope: iOS app and `Shared/` at commit f68765f (clean tree, `git stash -u` had nothing to stash). There are no widget, watch or backend targets in this repo (`project.yml` has the app, a unit target and two UI targets; no server code), so the entitlement path audited is `SubscriptionService` and RevenueCat only. Android is out of scope. Nothing was fixed.

Summary: 2 bugs proved by test (B1, B2), 4 code path only (C1 to C4), 6 product calls. No bug was found in the churn-ask machine, the Minute store, the feedback queue, the streak arithmetic across time zones, or the purchase and restore flags.

## Bugs, ranked by impact

Impact is users reached times cost. There is no analytics in the repo, so populations are stated from the UI, not measured.

| id | Bug | What the user sees | Promise | User route | Impact | Evidence | file:line |
|---|---|---|---|---|---|---|---|
| B1 | Flashcard Undo puts the card back but leaves the recorded answer in `PracticeRecordStore` and `ProgressStore`; answering again records a second answer on top | After one real correct answer on a card (Undo, then answer again) the room chip says "1 of N locked in". A mastery item that needs two correct answers in a row is counted known after one. The same double count feeds the weekly "+N questions locked in" chip, the 3 day review interval, and accuracy. An undone wrong answer also stays in Fix My Mistakes | `Mastery.swift:4-6` "an item counts only after two correct answers in a row"; the control is labelled "Undo last answer" (`FlashcardDrillView.swift:88`) | Home > The Card Room > Meet the Cards > tap "32 cards" > Next > tap the arrow toolbar button (Undo last answer) > tap "32 cards" > Next > back to the room: chip reads "Learning, 1 of N locked in". The arrow only shows after a card has been committed (`:82`). Free, no device or zone needed | Every player who uses the free first deck and mistaps once (the Card Room is the first room, and its first drill is this deck); also the other flashcard decks. Cost: inflated progress (a number the app uses to say practice is working), earlier review dates. No money, nothing lost | Proved: UI test, see below | `FlashcardDrillView.swift:231-237,340-363` grade, `:365-376` undo has no store call |
| B2 | Closing a Fix My Mistakes run after answering some of it scores the answers out of the whole queue and records a finished drill | "1/3 right, Good practice!" after answering one of three, and the streak and "drills done" go up | `PracticeRunView.swift:319-320` "A run the player quit before answering anything is not an achievement; sending it to the completion screen would fake one"; the button is labelled "Close" (`:156`), the other modes say "Finish" | Needs a member and at least two due mistakes: Home > Fix My Mistakes (badge "N due") > answer one > toolbar "Close" | Members with 2 or more due mistakes who bail early. Cost: wrong score, wrong streak credit, and for 2 of 3 right a review prompt gate computed on the wrong fraction (`DrillCompleteView.swift:86`) | Proved: UI test, see below | `PracticeRunView.swift:93,156,315-326` |
| C1 | Reminder flags never reconcile with iOS permission or the pending request | The Game Night card says "Prep is scheduled" and the toggle stays on after notifications are turned off in iOS Settings, or if pending requests were lost; nothing reschedules at launch | `GameNightPrepView.swift:78` "Prep is scheduled"; `AppSettings.swift:89-92` comment about not silently failing | Settings > Daily Reminder on (grant) > leave app > iOS Settings > Notifications > off > reopen: toggle still on, no alert | Everyone who ever revoked notification permission with a reminder on. Cost: the reminder never fires and the app says it will | Code path | `AppSettings.swift:175-188,210-228`; the only schedule triggers are didSet and the authorization callback (call sites listed under State machines) |
| C2 | Game night reminder survives a lapse that Home did not observe, and Settings hides its only off switch | A lapsed member keeps getting "Your game night prep is ready" weekly; tapping opens the paywall; the toggle is in a screen Settings no longer links to | `game-night.md` "Both features are entirely Sheepshead+ gated"; `HomeView.swift:126-128` exists to prevent exactly this | Member sets a game night reminder; subscription ends while the app is closed; the next cold launch reads a cached record that is already inactive (no isPro change, so `onChange` at `HomeView.swift:118` never fires); Settings > Practice no longer shows Game Night Prep (`SettingsView.swift:105`) | Lapsed members with game night on. If RevenueCat returns the cached record as active first, the later change does fire and the gap is closed, so reach depends on RevenueCat's cache behaviour | Code path | `HomeView.swift:118-129`, `SettingsView.swift:105-111`, `SubscriptionService.swift:93,365-385` |
| C3 | Purchase paths do not wait for `membershipResolved` | An offline cold start (no cache, no customer record) lets the trial CTA open Apple's sheet for a member whose entitlement StoreKit cannot see | `membership-and-trial.md` "nothing may ... sell a trial before it"; `membershipResolved` is read only in `HomeView.swift:113,205,246` | Fresh install on a second device with a promotional or non-StoreKit entitlement, bad network, tap through onboarding to the trial page and tap the CTA | Rare: reinstalls with a StoreKit entitlement are handled by `recoverReinstalledMembership` (`SubscriptionService.swift:137-149`) | Code path | `OnboardingView.swift:572-633`, `PaywallView.swift:443-480` |
| C4 | A notification route consumed while another Home sheet is up is dropped | Tapping the game night notification while What's New or Settings is open does nothing for a non-member; the parked destination later jumps in when they buy | `HomeView.swift:270-272` doc: What's New "never over a screen the player opened from a notification" | Update launch with What's New pending, tap the notification from a cold start as a non-member | Narrow: update launch plus lapsed reminder plus tap | Code path | `HomeView.swift:243-264` sets `showPaywall` without checking `homeIsBare` |

### Evidence

UI repro: `state-machines-2026-11-06-repro.swift` (class `StateMachineAuditRepro`, the UI half lives in `SheepsheadUITests`). Run with `gh-sim test --scheme SheepsheadUITests --only SheepsheadUITests/StateMachineAuditRepro`, GitHub run 42296273806 (all numbers below are from it; the first two attempts did not compile or failed on test setup and are not used), Xcode 27.1, iPhone 17 on iOS 27.2. Launch arguments blank the stored practice data so each test starts empty.

B1:
- Control `testControlOneAnswerLocksInNothing`: PASSED. One correct answer on card one, Next, back to the room: chip "0 of N locked in".
- `testUndoThenReanswerDoesNotCountTwice`: FAILED with `XCTAssertEqual failed: ("1") is not equal to ("0") - undo then re-answer is one answer, but the room says 1 locked in`. Its own preconditions passed first: Undo last answer was offered after the first Next, and after tapping it the deck header read "0 of N down".

B2:
- `testClosingFixMyMistakesEarlyScoresOutOfWhatWasAnswered`: FAILED with `XCTAssertTrue failed - one question answered, the score screen says 1/3`. Preconditions passed first: the Fix My Mistakes tile read "3 due" after three wrong answers, the run showed "1 of 3", Close was offered, and the score screen appeared. Expected a score out of the one question answered (`1/1` or `0/1`).

Test infrastructure finding (not a state machine bug): `SheepsheadUITests/FlashcardDeckUITests.swift:76` does not compile under Xcode 27.1 (`error: sending 'predicate' risks causing data races`), which stops every test in the `SheepsheadUITests` target. The repro run needed that helper rewritten (the NSPredicate built per call instead of reused); the rewrite was not committed.

### What would settle the code path claims

- C1: on a device, enable Daily Reminder, switch notifications off in iOS Settings, relaunch, and read `UNUserNotificationCenter.getNotificationSettings`; also restore a backup to a new device with the flag set and list pending requests. Both are one-line checks once `AppSettings` takes an injected center.
- C2: sandbox subscription with a short expiry, set game night, kill the app past expiry, cold launch offline-first, and list pending requests and `isPro` transitions. The deciding fact is whether RevenueCat's `cachedCustomerInfo` reports an expired entitlement as active.
- C3: inject a `CustomerInfo` source into `SubscriptionService.apply` (private today) to test the unresolved window.
- C4: a UI test with `-sheepshead.suppressWhatsNew` removed, a stored `whatsnew.lastSeenVersion` older than 1.3.0 and a routed destination.

## Product calls

Not counted: no stated promise to cite.

- P1. The daily reminder and the game night reminder are static repeating notifications, so they fire after the player already practised that day or that week (`AppSettings.swift:175-188`, copy at `:155-157`).
- P2. The Minute week starts Sunday in every region because `Calendar.gregorianLocal` builds a locale-less calendar (`Calendar+Gregorian.swift`), where the system calendar would start on Monday in much of Europe.
- P3. The Timed Challenge clock counts one second per `Task.sleep`, so it stops while the app is backgrounded (`PracticeRunView.swift:233-243`); a player can leave to look something up.
- P4. Opening the write-review page ends the passive rating asks even if no review is posted (`ReviewPromptTracker.swift:94-98`, documented as intended).
- P5. Endless and Fix My Mistakes runs end with a finished-drill credit after a single answer (`PracticeRunView.swift:321-325`), which counts toward the streak.
- P6. A notification tap replaces the Home stack (`HomeView.swift:263`), abandoning an unfinished Sheepshead Minute run (its answers stay recorded, its result does not).

## Related fixes, in order

1. B1: make Undo reverse the grade it undoes (decrement or restore the record and the seen/missed sets), or grade only on commit, and add a store-level inverse test.
2. B2: score a closed review run out of `attempted`, and do not record a drill for it, matching Endless.
3. C2 and C1 together: reconcile reminders in one place at launch and on foreground (read `getNotificationSettings` and pending requests, clear a game night flag for non-members, show the permission alert), which also fixes the Settings dead end.
4. C3, C4: gate purchase CTAs on `membershipResolved`; route paywalls through `homeIsBare`.
5. Test infra: fix `FlashcardDeckUITests.swift:76`.

## State machines

Legend for the "breaks" column: a bug id (B1..) means the transition violates the machine's invariant and is documented in the bug table. "ok" means the transition holds the invariant. "gap" means a reachable state the code does not reconcile but that has no counted bug.

Test seams available in this app (checked before marking anything Code path):
`ProgressStore(defaults:)`, `PracticeRecordStore(defaults:)`, `MasteryLedger(defaults:)`, `SheepsheadMinuteStore(defaults:)`, `AppSettings(defaults:)`, `FeedbackService(endpoint:defaults:session:)`, `WhatsNew.shouldPresent(defaults:)`, `ConversionDiagnostics.defaultsOverride`, `SubscriptionService.shared.observe(_:answeredAt:now:defaults:)` and the pure `MembershipTransitions`. Not injectable: `UNUserNotificationCenter.current()` (hard-wired in `AppSettings.swift:162,176,191,198,211,231`), `CustomerInfo` (no fixture type in the target; `SubscriptionService.apply` is private), `ReviewPromptTracker` (static, `.standard`), and every SwiftUI `@State`. Time zone: `Calendar.current` (ProgressStore) and `Calendar.gregorianLocal` (Minute store, ledger, Minute content) both follow `NSTimeZone.default`, so a test can move the zone; no counted bug needed it. UI seams: launch arguments override any stored default (`-progress.hasOnboarded YES`, `-subscription.localProOverride YES` in Debug), which is how the UI repro starts clean and as a member without RevenueCat.

Every scheduler call site (notification claims): `AppSettings.swift:187` (`add` daily), `:227` (`add` game night), `:177,:192,:212,:232` (`removePendingNotificationRequests`). Callers: `reminderEnabled.didSet` (:80-86), `reminderTime.didSet` (:99), `gameNightReminderEnabled.didSet` (:105-110), `gameNightDay.didSet` (:117), `gameNightReminderTime.didSet` (:126), the authorization callbacks (:166, :201) and `HomeView.swift:127`, which sets `gameNightReminderEnabled = false`. Nothing else in `Sheepshead/` or `Shared/` touches notifications except `AppRouter.swift` (delegate and routing).

### M1. Onboarding (`OnboardingView`, `FeatureTourView`, `HowToPlayView`)

State: `stage` (pages, howToPlay, tour) and `page` 0...4 (view `@State`), `skillLevel` (AppStorage), `purchasing`, `restoring`, `trialEligible`, `showPaywallFallback`, `purchaseError`; persisted exit flag `progress.hasOnboarded`.

Invariants:
1. `hasOnboarded` flips only in `finish()`, so Home never shows before the tour ends.
2. A swipe cannot pass the skill page without a choice (`OnboardingView.swift:94-100`).
3. A member is never sold a trial (`:579`, `:589`).
4. `purchasing` and `restoring` are exclusive (`:487`, `:636`).

| From | Event | To | Breaks |
|---|---|---|---|
| pages(4) | CTA, not member, package present | purchase sheet, `purchasing` | ok |
| purchase | cancelled | pages(4) | ok (`:626`) |
| purchase | purchased, entitlement confirmed | tour or howToPlay | ok |
| purchase | purchased, entitlement late | pages(4) with alert | ok, Restore recovers |
| pages(4) | CTA before offerings load | `showPaywallFallback` | ok |
| any stage | app killed | pages(0), `skillLevel` kept, member sees Continue | ok (restart, no data lost) |
| pages(4) | tap before first customer record | Apple sheet may open for a member whose entitlement StoreKit cannot see | gap, C3 |
| tour | Skip or cover dismissed | `finish()` | ok |

### M2. Membership (`SubscriptionService`)

State: `isPro`, `membershipResolved`, `isTrialing`, `expirationDate`, `offerings`, `membershipRecovery`, UserDefaults `membership.lastSnapshot`, `membership.churnAskSpent`, `membership.pendingChurnMoment`, `membership.reinstallSyncDone`.

Invariants:
1. `membershipResolved` is false only until the first record is applied, and nothing treats "not a member" as a lapse before it (rule file `membership-and-trial.md`).
2. `isPro == (any active entitlement)` after every `apply`.
3. At most one churn moment per departure; a returning member clears a queued one.
4. A first record becomes the baseline only if fresh (5 min).

| From | Event | To | Breaks |
|---|---|---|---|
| unresolved | cached record applied in `start()` | resolved, isPro from cache | ok |
| unresolved | no cache, network fails | stays unresolved all session, no retry | gap (offline cold start); purchase buttons still reachable, C3 |
| resolved member | delegate update with no entitlement | isPro false, snapshot lapsed, churn moment queued | ok |
| resolved member | cache older than 5 min, no previous snapshot | no baseline saved | ok (`:412`) |
| free | `purchase` returns | `apply(result.customerInfo)` then `confirmEntitlement` | ok |
| free | reinstall, StoreKit owns entitlement | one `syncPurchases`, key set on success | ok |
| free | reinstall, StoreKit owns nothing | check repeats on every `ensureOfferings` | ok (cheap) |
| member | refunded or expired while app closed | stale cache may read active, then lapsed | ok if stale-active (see M5 for the reminder side) |

### M3. Churn ask

State: `snapshot`, `churnAskSpent`, `pendingChurnMoment`, Home `churnPrompt`, `homeIsBare`.

| From | Event | To | Breaks |
|---|---|---|---|
| none | active to inactive | pending, spent=true | ok |
| pending | Home bare 0.9s later | `consumeChurnMoment`, sheet | ok |
| pending | Home covered | waits, retried by `homeIsBareAgain` | ok |
| pending | member returns before shown | cleared by `resetsAsk` | ok |
| spent | renewal off then lapse | no second ask | ok (one per departure, documented) |

### M4. Purchase and restore flags (`PaywallView`, `SettingsView`)

`purchasing`, `restoring`, `loadingPrices`, `priceLoadAttempted`, `trialEligible`, `message`. Purchase button disabled while either flag is set or no price. `isPro` flipping true dismisses the sheet. Paywall opened for an unresolved member is dismissed by the same `onChange` once the record lands. No counted bug.

### M5. Reminders (`AppSettings`, `SettingsView`, `GameNightPrepView`, `HomeView`)

State per reminder: stored flag (`settings.reminderEnabled`, `settings.gameNightReminderEnabled`), iOS authorization (not stored), one pending request (`sheepshead.dailyReminder`, `sheepshead.gameNightReminder`), plus the shared `reminderPermissionDenied`.

Invariants:
1. flag on implies a pending request exists and iOS allows alerts.
2. flag off implies no pending request.
3. Game night flag on implies the player is a member (`game-night.md`: "Both features are entirely Sheepshead+ gated").

| From | Event | To | Breaks |
|---|---|---|---|
| off | toggle on, permission granted | flag on, request added | ok |
| off | toggle on, denied | flag reset to off, alert | ok |
| on | time or day changed | request replaced | ok |
| on | toggle off | request removed | ok |
| on | user turns notifications off in iOS Settings | flag stays on, label still says "Prep is scheduled" (`GameNightPrepView.swift:78`), alert never shown | gap, C1 |
| on | restore or migration brings defaults but not pending requests | flag on, nothing pending, no launch reconcile | gap, C1 |
| on (game night) | membership lapses while Home is observing | flag reset by `HomeView.swift:127`, request removed | ok |
| on (game night) | membership already inactive at launch, no isPro change observed | flag stays on, request keeps firing, Settings link hidden (`SettingsView.swift:105`) so it cannot be turned off in app | C2 |
| on | toggle on then off before the authorization callback | callback schedules after the off | gap (needs sub-100ms double tap on an already authorized device) |

### M6. Notification routing and Home presentation (`AppRouter`, `HomeView`)

State: `pendingDestination`, `path`, `pendingAfterUpgrade`, `membershipWaitOver`, `showPaywall`, `showSettings`, `showWhatsNew`, `churnPrompt`, `homeOnScreen`.

Invariant: a destination is consumed once and is either shown, parked behind the paywall (`pendingAfterUpgrade`), or dropped by an explicit dismissal.

| From | Event | To | Breaks |
|---|---|---|---|
| idle | tap notification, member | `path=[prep]` | ok |
| idle | tap, free | paywall, parked | ok |
| idle | tap, unresolved | waits up to 4s | ok |
| any sheet up | destination consumed, free | `showPaywall = true` while another sheet is presented, SwiftUI drops it, destination consumed | gap, C4 |
| path non-empty | tap notification | stack replaced, an unfinished drill is abandoned | gap (answers are already stored, only the Minute result is lost) |
| What's New up | resolve membership | prep pushed behind the sheet | ok, visible after dismiss |

### M7. Streak and daily Get Started (`ProgressStore`)

State: `streakCount`, `lastActiveDay` (a start-of-day instant), `lastQuickSessionDay`, `totalSessions`, `completions`, `sessionsAtOnboarding`.

Invariants: streak counts consecutive local calendar days with a finished drill; `currentStreak()` is 0 after a missed day; Get Started rests until the next local day.

| From | Event | To | Breaks |
|---|---|---|---|
| streak n, last = yesterday | finish a drill | n+1 | ok |
| streak n, last = today | finish another | n | ok |
| streak n, gap above 1 | finish | 1 | ok |
| last in the future (clock moved back) | finish | unchanged, session still counted | ok (documented `ProgressStore.swift:98-101`) |
| any | zone change | day compared in the new zone | ok (checked with start-of-day arithmetic, no inconsistent pair found) |
| any | quit a Fix My Mistakes run with Close after one answer | counted as a finished drill, scored out of the whole queue | B2 |
| any | Reset Progress | counters cleared, onboarding kept | ok |

### M8. Practice record, mastery, ledger (`PracticeRecordStore`, `Mastery`, `MasteryLedger`)

State: per item `attempts`, `correct`, `streak`, `dueDate`, `intervalDays`, `ease`; `ProgressStore.seenItems/missedItems`; ledger days.

Invariants: one graded answer produces exactly one record; known means two correct in a row inside the interval; missed set and record agree about the last answer.

| From | Event | To | Breaks |
|---|---|---|---|
| any | graded answer in quiz, hand match, bury, session, run | one record plus one recordItem | ok |
| flashcard, answered | Undo | queue restored, record and recordItem not reverted | B1 |
| flashcard, answered | Undo then answer again | second record on top of the first | B1 |
| any | two corrects, interval 3d | known until due plus 3d | ok |
| item known | free after lapse | excluded from totals, `weeklyGain` can drop to nil | ok (documented: negative is nil) |

### M9. Flashcard deck (`FlashcardDrillView`)

State: `queue`, `isFlipped`, `choicePick`, `isFlinging`, `lastSwipe`, `finished`.

Invariants: a choice card is graded once at pick time (`:233-237`); a plain card is graded once at swipe (`:348-352`); the Next button commits once per card (fixed in 81be3aa).

| From | Event | To | Breaks |
|---|---|---|---|
| front | pick choice | graded, flipped | ok |
| flipped | Next (single or double tap) | one commit | ok |
| committed | Undo | card back at the front, `choicePick` nil, `lastSwipe` nil | B1 (grade kept) |
| front again | pick choice | graded a second time | B1 |
| last card | commit | finished, session recorded | ok |

### M10. Choice runs (`QuickSessionView`, `PracticeRunView`)

Quick session: `index`, `selection`, `finished`; one grade per question (`guard selection == nil`). Run: `mode`, `attempted`, `secondsRemaining`.

| From | Event | To | Breaks |
|---|---|---|---|
| answering | pick | graded once | ok |
| review run, 0 answered | Close | dismiss, no record | ok |
| review run, k of n answered | Close | score screen k/n, session recorded | B2 |
| endless run | Finish after k | score k/attempted | ok |
| timed | background the app | clock stops, resumes on return | gap (product call P3) |
| timed | 0s | finish, best score kept | ok |

### M11. Sheepshead Minute (`SheepsheadMinuteStore`, `SheepsheadMinuteView`)

State: results keyed by local day, `completedAt`. Invariants: one result per day key; `record` is idempotent; a day key never changes for a saved result.

| From | Event | To | Breaks |
|---|---|---|---|
| no result | finish today | stored, session recorded | ok |
| result | `record` again | existing returned | ok |
| archive day, no result | finish | stored under that day, counts toward the week by `completedAt` | ok (documented) |
| any | Reset Progress | cleared, day replayable | ok |

### M12. Feedback queue (`FeedbackService`)

State: pending rows (cap 20), `isFlushing`. Network error, 408, 429, 5xx queue; other 4xx drop. Each row leaves the queue only after the server answers. Gap: a row the server accepted but whose response was lost is re-sent (duplicate row). No counted bug.

### M13. Rating prompt (`ReviewPromptTracker`, `ReviewRequest`)

State: `launchCount`, `lastShown`, `outcome`. `markShown` is written when the call is made. Opening the write-review page ends the asks even if no review is posted (product call P4).

### M14. What's New (`WhatsNew`)

State: `whatsnew.lastSeenVersion`. Fresh install is stamped by `finish()`; `markSeen` runs when the sheet shows. A swipe-down dismiss does not re-show it. ok.
