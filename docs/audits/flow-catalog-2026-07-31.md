# Runtime flow catalog

The port preserves the source app's runtime structure:

| Flow | Primary interaction | Completion |
| --- | --- | --- |
| Onboarding | skill choice, primer, feature tour | real Quick Session or Home escape hatch |
| Card Room | swipe cards and quizzes | graded drill completion |
| Trump Room | hand recognition and trump-rule explanations | graded drill completion |
| Bury Room | select two cards from an eight-card holding | scenario score and explanation |
| Trick Room | choices about legal plays and trick winners | graded drill completion |
| Master Tables | advanced locked content | membership-gated drill completion |
| Practice | generated, review, or timed items | score, best score, or review history |

The dedicated simulator and the test command are recorded in the handoff notes
after the final runtime pass.

## Final parity pass, 2026-08-01

- Device: `agent-sheepshead`, UDID `383900AB-C151-4745-99B7-30962082B835`.
- Build: `xcodegen generate`, then the `Sheepshead` scheme on the
  dedicated simulator.
- Tests: 52 tests, 0 failures.
- Headless UI checks: Home, Get Started, Trump Room, Bury Room, a live
  eight-card bury screen, Settings, and the Sheepshead+ paywall. The paywall
  showed yearly, lifetime, and monthly pricing, trial and renewal language,
  Restore, Terms of Use, and Privacy Policy.
- Release captures: six real screens in `scripts/screenshot_raw/`,
  `fastlane/screenshots/en-US/`, `docs/screenshots/`, and the six public
  `docs/appstore-screenshot-*.png` assets.
- Simulator safety: the final runtime log contained no production RevenueCat
  configure call or RevenueCat API endpoint.
- Structural gate: Cardport parity passed against the reference card app.
