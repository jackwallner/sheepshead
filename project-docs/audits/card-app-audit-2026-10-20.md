# Sheepshead card-app audit (Mahj reference), 2026-10-20

Reference: `jackwallner/mahj` (read only, cloned to /tmp/mahjref). Mahj terms
and mechanics (Charleston, jokers, NMJL card sections, hand-play engine,
monthly challenge, Supabase feedback) are unsuitable here and were not ported.

Legend: PRESENT, MISSING (built this shift), UNSUITABLE, GAP (known, not built).

## Feature audit

| Area | Status | Source | Notes |
|---|---|---|---|
| Endless original practice | PRESENT, widened | `Shared/Content/EndlessPractice.swift`, `HandGenerator.swift` | Had 2 skills (Read the Holding, Read the Trump). Added Who Takes the Trick? and Count the Points, both from `TrickGenerator`. Members only (paid boundary unchanged). |
| Fix My Mistakes / spaced review | PRESENT | `PracticeRecordStore.swift`, `PracticeRunView.swift` (.review) | SM-2 trimmed, queue worst first, tile hidden when nothing is due. Generated items correctly stay out of the queue. |
| Timed challenge | PRESENT | `PracticeRunView.swift` (.timed) | 90 s, best score kept. Now draws from the four skills. |
| Room-level stats | PRESENT | `StatsView.swift` | Accuracy per room, weakest room. |
| Mastery (known vs opened) | MISSING, built | `Shared/Services/Mastery.swift`, `StatsView`, `RoomView` | Two correct in a row and not lapsed counts as known. Free players are measured only against rooms and drills they can open. |
| Coaching for misses | MISSING, built | `PracticeRecordStore.skillToCoach`, `StatsView.coachCard` | Per-skill accuracy was recorded but never shown. Coach card appears for members when a skill has 8+ answers and under 80%, and opens that skill. Every answer already shows its explanation. |
| Daily short practice | PRESENT | `SheepsheadMinuteView`, `SheepsheadMinuteStore`, `GameNightPrepView` | Deterministic daily five. Not changed. |
| Reference / glossary | GAP | `HowToPlayView` | Mahj has a searchable at-the-table reference. Sheepshead has a six-page primer and rank/point flashcards but no search. Not built: the corpus (trump ladder, points, called-ace rules) is small and already in the primer. Recommended next. |
| Practice-hand flow (play a hand) | UNSUITABLE | n/a | Mahj `HandPlayEngine` is a full game loop. A trick-play simulator would need a bot opponent engine; not built, would be invented gameplay at this size. |
| Progression | PARTIAL | `ProgressStore`, `StatsView` | Streak and drill count present. Mastery levels (Not started, Learning, Solid, Sharp) now give a goal per room. |
| Reminders | PRESENT | `AppSettings.swift`, `SettingsView.swift` | Daily reminder and weekly game-night reminder. |
| Feedback and ratings | PRESENT | `FeedbackSheet.swift`, `ReviewRequest.swift` | No-gate policy kept. Backend feedback is UNSUITABLE (no backend, mail sheet). |
| What's New | INCORRECT, fixed | `Shared/Services/WhatsNew.swift` | Marketing version is 1.2.4 but the newest entry was 1.2.2, so no sheet showed after updating. Added 1.2.4. 1.2.3 shipped with no entry. |
| Reduce Motion | MISSING, built | `ConfettiBurst.swift`, `PracticeRunView.swift` | No view honoured `accessibilityReduceMotion`. Confetti, screen flash and the slide transition now fall back to a fade. Other drill views keep their transitions (GAP). |
| Larger text | GAP, verify | all views | Audit capture at AX XXXL in `SheepsheadScreenshots/AuditTests.swift`; see run findings in the checkpoint. |

## Correctness notes

- Trick winner and point answers are produced by `TrickGenerator` and checked in
  `TrickGeneratorTests` against an independent oracle (explicit trump ladder, not
  `trumpStrength`). The deck totals 120 points, asserted.
- "Read the Trump" (existing) offers "Not in the deck" as a third choice that can
  never be right. It is a throwaway distractor, harmless but weak (GAP).
- `HandGenerator.pointCards` hands are fail-only by dealing; the category check
  also admits trump point cards if a future caller passes them. Unchanged.

## Personas

- Beginner: free rooms, primer and Meet the Cards unchanged. New skills are
  members-only, so a free beginner sees Room Mastery on Your Progress but not
  Endless.
- Improving player: skill breakdown and coach card give the missing "what is
  weak" answer.
- Returning player: Fix My Mistakes and mastery lapse (known items stop counting
  one interval past due) bring them back to the right material.
- Larger text and Reduce Motion: see above.
