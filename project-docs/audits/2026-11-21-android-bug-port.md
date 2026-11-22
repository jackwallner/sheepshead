# Android port of the 2026-11-20 bug fixes

Checked 2026-11-22 on `main`. Each row of
[2026-11-20-bug-fixes.md](2026-11-20-bug-fixes.md) was checked against the
`android/` port by reading the code. Bugs that exist there were fixed with the
smallest change that matches the iOS behavior.

The fix commits came from a fleet run (`sheepshead-port1122`) that ported the
same iOS commits; they were fast-forwarded onto `main` in place of a second,
overlapping set of edits. That run also ported fixes from outside the catalog,
listed under the table.

Unit run (`fm-gradle testDebugUnitTest`, GitHub Linux) at HEAD `a6863f1`:
`sheepshead-mbairfcc1-1122-103345-17045`, **86 passed, 0 failed.**

No run before the fixes. No emulator run; the Compose wiring was checked by
reading the code.

| iOS bug | Android verdict | Commit | Test | Notes |
|---|---|---|---|---|
| B1 Streak resets or counts twice after a westward zone change | already fine | | `StreakTimeTest.storedDaysSurviveAWestwardZoneChange` (pins it) | `ProgressStore` has always stored days as `yyyy-MM-dd` keys, which is the iOS fix |
| B2 Paying member with an old RevenueCat cache asked why they left | not applicable | ae82c2c (related) | `ReminderStateTest` (5 lapse tests) | Android has no "why did you leave" question. The same stale cache did drop a renewed member's game night reminder; that is fixed: the reminder is dropped only on a lapse confirmed after the launch cache (`lapseConfirmed`) |
| B3 Home keeps yesterday's "Today's session is done" after midnight | ported | 895cedb | `StreakTimeTest.getStartedRestsForOneCalendarDayInTheDeviceZone`, `currentStreakDropsAfterAMissedDay` | Home draws for a day from `rememberToday()`, which refreshes on return to the app and on date, time and zone changes, and reads `currentStreak(today)` |
| B4 Daily Reminder stays on after notifications are turned off | ported | b6820cd | `ReminderStateTest.deniedNotificationsTurnTheRemindersOffAndSayWhy`, `allowedNotificationsLeaveTheRemindersAlone`, `deniedWithNoReminderSetStaysQuiet` | Settings and Game Night Prep check when they appear and when the app returns. Blocked with a reminder on: the reminders turn off and the "Notifications are off" alert says why |
| B5 Get Started available again the same day after a westward zone change | already fine | | `StreakTimeTest.getStartedRestsForOneCalendarDayInTheDeviceZone` | Same day-key storage as B1 for the Get Started day |
| B6 Minute "Your week" always starts on Sunday | already fine | | `StreakTimeTest.minuteWeekStartsOnTheLocalesFirstWeekday` (pins it) | `GameStores` uses `WeekFields.of(locale)` |
| B7 Timed Challenge clock stops in the background | already fine | | | `SessionScreens.kt` counts down to a `SystemClock.elapsedRealtime` deadline, so time away counts |

Counts: 2 ported, 4 already fine, 1 not applicable.

## Also ported, from outside the catalog

| Commit | What | Test |
|---|---|---|
| 895cedb | A clock set back no longer counts a day twice, and an unreadable stored day no longer crashes a finished drill (iOS 38b8785, cf65fac) | `StreakTimeTest.aClockSetBackDoesNotCountADayTwice`, `anUnreadableStoredDayDoesNotCrash` |
| 2de3fee | Flashcard Undo takes back the answer it undoes in the practice and progress stores (iOS f8a2480) | `UndoGradeTest` (4 tests) |

## Needs Jack

Nothing blocking. Not uploaded to Play; the fixes ship with the next Android
build when you ask for one.
