---
paths:
  - "Shared/Services/FeedbackService.swift"
  - "Shared/Services/MembershipTransitions.swift"
  - "Shared/Services/MasteryLedger.swift"
  - "Shared/Services/Mastery.swift"
  - "Shared/Services/ReviewPromptTracker.swift"
  - "Sheepshead/Views/ReviewPromptSheet.swift"
  - "Sheepshead/Views/Components/ReviewRequest.swift"
  - "Sheepshead/Views/StatsView.swift"
  - "SheepsheadTests/FeedbackServiceTests.swift"
  - "SheepsheadTests/MasteryLedgerTests.swift"
  - "SheepsheadTests/MembershipTransitionsTests.swift"
---

# Sheepshead Trainer: feedback, the churn question, and the weekly gain

Ported from Mahj (2026-10-20), by way of the sibling card trainers. Mahj's
`.claude/rules/feedback-and-retention.md` has the reasoning; this file is what
differs here.

## Ratings (App Review 5.6.1)

No question stands in front of Apple's prompt, ever. A finished drill or
Sheepshead Minute scoring half or better bumps a counter; `requestsReview(after:)`
waits 3s, re-checks the screen (view on screen, no alert or share sheet up) and
calls `requestReview()`. Gates live only in
`ReviewPromptTracker.shouldRequestReview`: second cold launch, 30-day cooldown,
and opening the write-review page ends the asks. Also required: onboarded, and
RevenueCat `rating_prompt` not `off`. Settings has two separate rows: "Rate
Sheepshead Trainer" (write-review page, ends the asks) and "Send Feedback" (never
stops them). The old pending-positive-moment tracker and the mail draft
`FeedbackSheet` are gone. No per-question report link (Jack's call in Mahj: a
flag under every answer casts doubt on the right one).

## The feedback sink

`FeedbackService` posts to the shared Supabase `app_feedback` table (project
`ucoveqbyfuxqvpysmixu`) with `appID = "sheepshead"`. The publishable key can only
INSERT rows where `app` is one of the card trainers (migration
`20261019120000_card_apps_feedback.sql` in the Mahj repo) and `kind` is
`general`, `not_enjoying`, `question` (unused here) or `churn`. 2xx is sent;
network error, 408, 429 and 5xx queue the row (cap 20, retried on launch and
every return to the app); any other 4xx is dropped. Nothing personal is sent.
The public privacy page (`docs/privacy-policy*.html`, "Feedback") describes the
fields (updated 2026-10-20); keep it in step.

## One sheet, two jobs

`ReviewPromptSheet` has `.feedback` and `.churn(ChurnMoment)`. Neither touches
`ReviewPromptTracker`. `SubscriptionService.observe` compares each RevenueCat
record with the last one (`MembershipTransitions.churnMoment`) and stores at
most one `ChurnMoment` per departure. Every product carries both the
`Sheepshead+` and `pro` entitlements, so the snapshot reads
`activeEntitlement(in:)` (`Sheepshead+` first, then `pro`, then any active one)
rather than a single key. A first record only becomes the baseline if
RevenueCat answered within 5 minutes (`freshBaselineAge`): launch applies the
cached record first, which can be months old. Home shows the question once 0.9s
after it is bare (`HomeView.homeIsBare`) and spends it only when shown.

## Weekly gain

`Mastery.swift` predates the port (1.2.4: room mastery, the skill coach) and
is the only mastery model; the ledger is built on it, never a second copy.
An item is known after two right answers in a row and until a full interval
past due. Trackable items are quiz, hand-match and bury questions plus every
flashcard (self-tested or self-graded, both are recorded); generated Endless
items never count, and a free player is measured only against the sets they
can open. The room rings on Home still count drills done; mastery shows in the
room header chip, the Your Progress mastery card and the ledger.
`MasteryLedger` stores known-question counts per room
once a day. `weeklyGain()` drives the plum "+N" chip on Home and the "Up N
questions this week" card on Your Progress. Home records only once
`membershipResolved` is true, or a member's first entry of the day would drop
every Sheepshead+ item and fake a gain the next day. Nothing is baked into the
repeating reminders (`AppSettings.dailyReminderBody` is static and
number-free; `ReminderCopyTests` guards it).

## Not ported, on purpose

Trial-end reminder screen (Mahj removed it from the frozen trial flow), the
per-question report link, mastery rings on Home rooms, and Mahj's free daily
and monthly challenge. The nearest thing here is Sheepshead Minute (a daily
five-question set, members only, no monthly one); the `challenge` remote switch
exists but nothing reads it and Minute is not behind it.
