---
paths:
  - "android/**"
  - "docs/android-*.html"
  - "scripts/android-export/**"
  - "scripts/sync-android-content.sh"
  - "scripts/play_screenshot_compositor.py"
  - "scripts/play-products.py"
  - "scripts/play-upload.sh"
  - "scripts/make_android_icon.py"
---

# Sheepshead Trainer Android rules

## Identity and products

- Native Android code is in `android/`, a screen-for-screen port of the iOS app
  (same copy, tokens, flows, product IDs). When iOS changes, port the change.
  It started from `~/cribbage/android` (the English sibling of the Skat port;
  both iOS apps share the cardport shell); every Cribbage screen string, rule
  and asset was replaced with the Sheepshead one.
- Package `com.jackwallner.sheepshead`, launcher label "Sheepshead Trainer",
  Play title "Sheepshead Trainer: Trump Play", paid tier "Sheepshead+".
  Feedback and Play contact email `jackwallner+m@gmail.com` (same as iOS).
- Products (same IDs as iOS): subscriptions `com.jackwallner.sheepshead.monthly`
  and `com.jackwallner.sheepshead.yearly` (base plans `monthly` / `yearly`,
  7-day `trial-7d` new-customer offer), lifetime one-time product
  `com.jackwallner.sheepshead.lifetime` (purchase option `lifetime`). Android
  US ladder $5.49 / $23.99 / $55.99, about 20% under iOS ($6.99 / $29.99 /
  $69.99); local prices are Play's conversion plus the fleet PPP curve. Never
  put prices in listing copy or app literals (`TrialCopyTest` pins the
  fallback strings).
- RevenueCat project `proj3fd00657`: Test Store app `appc8bf9296a5` (Debug key
  `apikey8f00896747`, the same `test_` key iOS uses), Play app `app8f0e9c3c59`
  (`goog_` key `apikeya8b2d6aa0e`, release only), App Store app
  `app1f5f141a60`. Entitlements `pro` (`entl01faed076c`) and `Sheepshead+`
  (`entl6b4d4a8f82`); either unlocks, and each holds the Play, App Store and
  Test Store products. The app reads offering `android` (`ofrng0884c699d8`,
  not current; iOS keeps `default`) with `$rc_monthly` (`pkge64f804e6af`),
  `$rc_annual` (`pkgef1feedeaf5`) and `$rc_lifetime` (`pkgea6efb64336`), each
  holding the Play product (`...monthly:monthly` `proda18de605b1`,
  `...yearly:yearly` `prodb9737dc777`, `...lifetime` `prodef65f0906e`) and the
  Test Store twin. Play service-account credentials are not set on the Play app
  yet (needs the Play Console app first).
- rc-clean knows the Play app: `~/.rc-clean/apps.json` on the Air and the MBP
  has the `android` block for `com.jackwallner.sheepshead` (added 2026-10-18).
- Play reviewers unlock Sheepshead+ with a code (long-press Settings > Version).
  Only its SHA-256 is in the build (`PLAY_REVIEW_CODE_SHA256` in
  `local.properties`); the code is `SHEEPSHEAD_PLAY_REVIEW_CODE` in
  `~/.sheepshead_credentials` and goes in Play Console App access. Never commit
  it.

## Content and parity

- Content and engine fixtures come from Swift, never hand-edited:
  `scripts/sync-android-content.sh` runs `scripts/android-export/` and writes
  `app/src/main/resources/sheepshead-content.json` and the test fixture
  `sheepshead-parity.json`. Rerun it after changing `Shared/Models`,
  `Shared/Content`, `WhatsNew.swift` or `ChoiceShuffle.swift`.
- `SeededRandom.kt` is the Swift RNG bit for bit (FNV-1a seed, xorshift64*,
  Lemire bounded draw, forward Fisher-Yates), so seeded holdings, choice order
  and the daily Sheepshead Minute match iOS. The parity fixture also pins every
  card's trump, fail, point and strength values and 300 seeded five-card
  classifications.
- `ContentTest` ports `ContentValidityTests` including the bury rules (never
  bury trump, unique best bury, called-ace legality, alone hands), and
  `GeneratorParityTest` ports `HandGeneratorTests` and the Minute tests.

## Deliberate differences from iOS

- Purchase copy names Google Play and has no "24 hours before the end of the
  period" clause (Play has no such rule).
- The review prompt keeps the iOS gates (second launch on, 30-day cooldown) and
  calls `launchReviewFlow` with no enjoyment question. Settings "Rate
  Sheepshead Trainer" opens the Play listing.

## Build

- JDK 17, checked-in Gradle wrapper, AGP 9.4.1, Kotlin 2.4.20, minSdk 26,
  target/compile 36.
- `android/local.properties` (ignored, mode 600) holds `REVENUECAT_TEST_KEY`,
  `REVENUECAT_PLAY_KEY`, `PLAY_REVIEW_CODE_SHA256` and `PLAY_UPLOAD_*` (upload
  keystore `~/.android/keystores/sheepshead-upload.p12`, backup in
  `~/.android/keystores/backups/`, alias `upload`, password
  `SHEEPSHEAD_PLAY_UPLOAD_PASSWORD` in `~/.sheepshead_credentials`). Release
  builds fail without them. Upload cert SHA-256
  `1C:B9:B6:86:64:97:22:7A:44:DE:47:98:07:BD:00:20:3B:9D:61:0F:AD:54:30:6A:2E:1F:42:3D:25:41:F4:F2`.
- `scripts/make_android_icon.py` derives the adaptive icon layers, legacy and
  round icons and `play-assets/icon-512.png` from the iOS AppIcon (already
  full bleed, so it is used as is).
- Increment `versionCode` on every Play upload. 1.2.4 is versionCode 1.
- `scripts/play-upload.sh [validate|internal|internal-draft|production-draft]`
  and `scripts/play-products.py [--dry-run]` need `PLAY_SERVICE_ACCOUNT_JSON`.
  Neither has been run yet.

## Emulator (remote MacBook Pro only)

Follow the `android-dev` skill's Remote MacBook Pro section. Host
`jackwallner@192.168.4.25` (strict host keys), SDK
`/Users/jackwallner/Library/Android/sdk`. Build the debug and androidTest APKs
on jmbp with `fm-gradle assembleDebug assembleDebugAndroidTest` from `android/`
(never `./gradlew` here) and copy them to a temp dir on the Pro
(`~/tmp/claude-sheepshead` for the 2026-10-18 run). Create a temporary AVD by
hand (`.ini` plus a `config.ini` cloned from `agent-emu-1`, `android-36`
`google_apis_playstore` x86_64, 1080x2400), boot it headless on a free port:

```sh
ssh jackwallner@192.168.4.25 'nohup ~/Library/Android/sdk/emulator/emulator -avd claude-sheepshead -port 5590 -no-window -no-audio -no-boot-anim -no-metrics -no-snapshot-save -gpu swiftshader_indirect > ~/tmp/claude-sheepshead/emulator.log 2>&1 &'
ssh jackwallner@192.168.4.25 '~/Library/Android/sdk/platform-tools/adb -s emulator-5590 shell getprop sys.boot_completed'
```

Disable Digital Wellbeing (`pm disable-user --user 0
com.google.android.apps.wellbeing`) and the three animation scales before
testing. Install both APKs with `adb -s emulator-5590 install -r -t`. Run
each `AppFlowTest` method on its own (`am instrument -w -e class
com.jackwallner.sheepshead.AppFlowTest#<method>
com.jackwallner.sheepshead.test/androidx.test.runner.AndroidJUnitRunner`)
after `pm clear com.jackwallner.sheepshead`, and check each `OK (1 test)`.
That stands in for Gradle's orchestrator `clearPackageData`: run as one plain
`am instrument`, `forcePro` from the member tests leaks into the free paywall
test, and the hand-run orchestrator could not reach its service on the API 36
image. If the Pro is loaded, a system ANR dialog can sit over captures: set
`settings put global hide_error_dialogs 1` and tap Wait before shooting. Afterwards `adb -s emulator-5590 emu kill`,
then delete only `~/.android/avd/claude-sheepshead.{avd,ini}` and the temp
dir. Never touch `small_phone`, `agent-emu-*`, `sol-*` or other agents' AVDs,
and never run an unqualified `adb emu kill` or `adb kill-server`. The Pro is a
2015 i7: a cold boot takes about 5 minutes.

Debug launch extras (`DebugLaunchOptions`, debug builds only): `resetAll`,
`onboarded`, `skillLevel`, `seedProgress`, `forcePro`, `appearance`, `uiTest`.
Test tags are exposed as resource ids.

## Store assets

`StoreScreenshotTest` (excluded from the connected suite; run it with
`am instrument -w -e class com.jackwallner.sheepshead.StoreScreenshotTest com.jackwallner.sheepshead.test/androidx.test.runner.AndroidJUnitRunner`)
writes the six raw 1080x2400 captures to
`/sdcard/Android/data/com.jackwallner.sheepshead/files/screens/`, the same six
screens as the App Store set (`scripts/screenshot_raw/`). Turn System UI demo
mode on first. Pull them into `android/play-assets/raw/` and run
`python3 scripts/play_screenshot_compositor.py` for the 1080x1920 frames (App
Store headlines) and the 1024x500 feature graphic. Listing text and the
changelog are in `android/play-assets/metadata/android/en-US/` (English, no
prices, no em dashes). Privacy and terms pages are `docs/android-privacy.html`
and `docs/android-terms.html` on GitHub Pages.

## Play state (2026-10-18)

Not in Play Console yet. Signed AAB versionCode 1 (1.2.4) builds and verifies
locally (package, targetSdk 36, upload cert, 16 KB ELF and zip alignment,
`goog_` key in release only); nothing uploaded. Verified 2026-10-18: 58 JVM
tests, 6 `AppFlowTest` device tests and the 6-shot `StoreScreenshotTest` pass
on the Pro (`claude-sheepshead`, API 36 Play image, since deleted); dark mode
Home and the Test Store paywall with live prices checked by screenshot. Left for the Console session: create the app
(E3 Apps), run `scripts/play-products.py`, set the RevenueCat Play
service-account credentials, App content forms (privacy policy, ads, App
access with the review code, target audience, data safety, IARC, category
Education), listing upload, internal then production release, Send for review
in this app's pacing slot.
