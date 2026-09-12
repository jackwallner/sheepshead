---
paths:
  - "Shared/Content/SheepsheadMinuteContent.swift"
  - "Shared/Services/SheepsheadMinuteStore.swift"
  - "Sheepshead/Views/SheepsheadMinuteView.swift"
  - "Sheepshead/Views/GameNightPrepView.swift"
  - "Shared/Content/SessionBuilder.swift"
  - "Shared/Content/HandGenerator.swift"
  - "Shared/Services/AppSettings.swift"
  - "SheepsheadTests/SheepsheadMinuteTests.swift"
  - "SheepsheadTests/HandGeneratorTests.swift"
  - "Sheepshead/Views/Drills/QuickSessionView.swift"
  - "Sheepshead/Views/SettingsView.swift"
---

# Sheepshead: game-night rhythm

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

## Game-night rhythm (1.2)

Sheepshead+ owns two recurring rituals. `SheepsheadMinuteContent` deterministically builds the
same five questions for every member on a local calendar day: two generated
hand reads, one bury decision, and two trick questions. Results and a 30-day
archive stay on device in `SheepsheadMinuteStore`; sharing uses the system share sheet and
needs no account or leaderboard.

The bury question is built straight from the authored scenarios, NOT through
`SessionBuilder.choiceItems`. The quick-session pool deliberately excludes
those drills, so drawing the daily from it silently produced a four-question
challenge with that skill missing entirely.

`HandGenerator` deals the daily hands from a caller-supplied generator all the
way down: `deal`, `fill`, and `randomHand` are all generic over
`RandomNumberGenerator`. One `.shuffled()` or `.randomElement()` left calling
the system source is enough to make the same day deal different hands on
different devices, and the stability test is what catches it.

`GameNightPrepView` stores a weekly game night in `AppSettings`, schedules a
local notification, and opens directly into `SessionBuilder.gameNightPrep`,
which prioritizes due mistakes, misses, the weakest room, and unseen member
content in that order. Both features are entirely Sheepshead+ gated.
