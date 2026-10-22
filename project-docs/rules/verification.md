# Verification, 2026-10-22

- Swift engine/content XCTest: **48 passed, 0 failures**, using `python3 scripts/test-rules.py` (Swift 6, macOS XCTest, same Foundation sources and rule tables as the iOS target). Includes current generated trick and point-count oracles, called ace, and called-ten variation.
- Android: **63 passed, 0 failures, 0 skipped**, via `fm-gradle --local testDebugUnitTest` from `android/`, on the remote Mac (the wrapper's `--local` selects SSH to jmbp). Gradle did not run on the Air.
- XcodeGen and `git diff --check` passed.
- Native/JUnit table SHA-256: `f9a3fc32b0bbf03818acfeadfecee4b7bf460c813771344503dcd534a4bed09e`; copies are byte-identical.
- Branch `fix/rules-audit-20261022`, integrated on current origin/main, preserves original working-tree edits.
- TestFlight: **1.3.0 (41), VALID**, confirmed through App Store Connect (`21b21718-3e2f-481e-ab7f-cfe225ae6a6d`). `./scripts/testflight.sh --no-bump` exited 0 after signed archive and upload; application code is from `db8a32d`.

The Swift runner selects engine/content suites, excluding UI/persistence/mastery cases in mixed files. It is not a simulator UI run. Release archiving separately verifies application compilation. One stale Android release-note assertion now uses a version with no catalog entry, rather than assuming a particular maintenance release has no notes.
