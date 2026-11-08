# Pre-submit review, 2026-11-07 (1.3.3 build 45)

Branch `review/2026-11-07-sheepshead` from `origin/main` at `c368861`.

## Scope

The App Store lookup reports 1.3.2 live (released 2026-11-05). Its binary is
build 44, last set in `e2868ec` ("chore: bump build 44 to 45" came later, with
1.3.3). The review covers `e2868ec..c368861`, app sources only (`Sheepshead/`,
`Shared/`, `project.yml`): 7 files, +134 / -7.

- Flashcard Undo takes back the answer it undoes (`FlashcardDrillView`,
  `PracticeRecordStore.snapshot/restore`, `ProgressStore.itemMark/restoreItem`).
- The game night reminder is dropped only on a confirmed lapse
  (`SubscriptionService.lapseConfirmed`, `confirmsNoMembership`,
  `AppSettings.dropGameNightReminderUnlessMember`, three HomeView call sites).
- Version 1.3.3, build 45. `Info.plist` reads both from build settings.

Also checked across the shipping app for App Review risk: paywall and
onboarding trial page carry Terms, Privacy and Restore; no hard-coded prices in
Swift; no Android or Google Play strings in iOS sources; the local Pro override
toggle is inside `#if DEBUG`.

## Findings

No P0 or P1 found. Nothing fixed.

| Severity | File:line | What happens | Status |
|---|---|---|---|
| P2 | `Sheepshead/Views/HomeView.swift:264` | A member whose RevenueCat cache is over 3 days old (renewed while the app was closed) taps the game night notification: the cache reads inactive, so the paywall opens until the network answers. `PaywallView` dismisses itself when `isPro` flips and `pendingAfterUpgrade` routes them to the prep, so it self-heals in a second or two online. Offline it stays a paywall. | Not fixed: present in 1.3.2 too, self-heals, and fixing it means waiting on `lapseConfirmed` here, a flow change for Jack. |
| P2 | `Shared/Services/SubscriptionService.swift:414` | `confirmsNoMembership` never confirms a lapse while offline with a stale cache, so a lapsed member's game night reminder keeps firing until the app next reaches RevenueCat. | Not fixed: by design (the verify pass rejected acting on the cache, which drops a renewed member's reminder). |
| P2 | `Shared/Services/AppSettings.swift:236` | Restore to a new phone (C1 in `state-machines-2026-11-06-fixes.md`): reminder flags come back on, the pending request and permission may not. | Not fixed: held for Jack's decision in that doc. |

## Checked and clean

- Undo ordering: a pick on the card now showing is restored before the swipe
  it follows, so a missed card that comes straight back, picked again and then
  undone, ends at the pre-answer row and marks. A `nil` snapshot removes the
  row (first answer ever). The re-appended copy of a missed card is removed
  before the card is reinserted. Undo is hidden once the deck finishes.
- `lapseConfirmed`: starts false; `launchCacheAnsweredAt` is set in `start()`
  before any delegate callback can run (the callback hops to the main actor
  after `start()` returns). With no cache every network record confirms; the
  cached record itself never does unless it is under 5 minutes old. The DEBUG
  override never confirms. All writes are on the main actor
  (`SubscriptionService` is `@MainActor`).
- No stored data changes shape: `PracticeRecord` rows and the seen/missed sets
  are read and written exactly as in 1.3.2, so nothing old fails to decode.
- No new notification scheduling: turning the toggle off goes through the
  existing `didSet`, which removes the pending request once.

## Tests

Not run. `gh-sim test --scheme Sheepshead` (queue id
`sheepshead@20261107-222755-0247-claude-imacd7ac-1107-223243-31840`) sat queued
for 90 minutes and never started: 0 of 5 GitHub Macs running, 25 runs queued,
and the GitHub API returned "rate limit exceeded" for the account during the
wait. The client was stopped at the 90-minute cap. No code changed on this
branch, so the last green suite on this code is run 42357782920 (179 passed,
0 failed, `state-machines-2026-11-06-fixes.md`), which covers both changes in
scope; the 1.3.3 commits after it change only `project.yml` version numbers,
fastlane notes and Android files. xcodegen is not installed on this machine
and was not needed (no `.swift` file added or removed).
