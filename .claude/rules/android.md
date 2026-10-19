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
  Test Store twin. Existing Play service-account credentials are saved and
  confirmed; no new service-account grant is needed.
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

- Build directly on jmbp using installed JDK21, checked-in Gradle wrapper,
  AGP 9.4.1, Kotlin 2.4.20, minSdk26, target/compile36, Java17 bytecode.
  Never build or run Android on the Air. Do not dispatch from this fleet host.
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
  Monthly/yearly and their trials are active. Lifetime creation must follow
  the first accepted billing-enabled artifact upload.

## Pro runtime and verification

Run one memory-limited Gradle job and one owned emulator at a time. JDK21 is at
`~/.jdk/jdk-21.0.12.1+1/Contents/Home`; SDK is `~/Library/Android/sdk`.
Use `--no-daemon --max-workers=1`, Gradle heap3GB, ActiveProcessorCount4.
Full checks: testDebugUnitTest, assembleDebug, assembleDebugAndroidTest,
assembleRelease, bundleRelease, assembleQa and lintRelease.

Only debug uses the Test Store SDK key. QA uses release source/R8, debug signing
and an empty SDK key. Never install a production-key release on an emulator.
Debug launch extras are resetAll, onboarded, skillLevel, seedProgress, forcePro,
appearance and uiTest. QA/release ignore them. Test tags are resource IDs.
The reviewer field is masked with Password keyboard and autocorrect disabled.

Create an owned sol-sheepshead Google Play AVD, headless, one serial at a time.
Never touch another AVD or use adb kill-server/unqualified emu kill. Cold boot on
this2015 dual-core Pro can leave a System UI ANR over an otherwise healthy app.
Inspect the fresh hierarchy/capture and select Wait only on the identified
System UI dialog. Keep real app failures visible. Let Android finish boot work,
and use sys.user.0.ce_available for credential-unlock readiness. Keep the owned
emulator alive while diagnosing a failed manual check instead of repeatedly
cold-booting it. Stop/delete the owned AVD after acceptance, retain proof.

Run AppFlowTest methods separately after pm clear, or use the AndroidX test
orchestrator with clearPackageData. A single plain instrumentation suite can
leak forcePro from member tests into the free paid-boundary case. Pass the
private reviewCode only through a local redacting harness, never in a committed
script or capture. No private-code screenshot is needed.

Current verification: full signed/QA/release-lint build18m31s,58JVM cases pass.
Prior accepted6base device cases plus current first-run60.657s, masked reviewer
74.42s and free locked-boundary43.467s cases pass. This is not a fresh full7-case
run. Signed vc1/1.2.4, target36 APK/AAB signatures, ZIP and all4ELF16KB alignments
pass. Release has the correct SDK key/digest and no Test Store key/private code;
QA has no SDK key. Optimized QA passes: debug extras ignored, free onboarding,
locked paid content, masked reviewer input and wrong-code rejection. All four
final captures inspected. Cold-boot System UI ANR recovered with its Wait action.
Source is accepted. Signed main rebuild passes58s, including compilation of
the import-sorted device test. Main APK/AAB signatures, target36 and all4ELF/ZIP
16KB alignments pass. Play upload is next.
AAB: android/app/build/outputs/bundle/release/app-release.aab.

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

E3 Apps app4973390987996289663. Listing,512RGB icon,1024x500RGB feature and
six inspected real free1080x1920 store captures are saved. Contact/privacy,
no ads/government/ad-ID/financial/health, Education category, adult18+ audience,
reviewer Sign in details/hash, Data safety,178countries and existing internal
tester list are saved. Managed publishing is off. Only Content ratings needs
attention; IARC terms approval is pending, do not accept a new agreement.

Data safety discloses collected purchase history, app interactions and anonymous
IDs, encrypted transit, no accounts, support deletion. Practice records stay
local. Two private RC transaction webhooks disable paywall-event forwarding;
no advertising integration. No new credentials, grants or integrations were
created. The privacy retention heading has a delete-data anchor, which must be
checked on the public page after accepted main publication.

Accepted main vc1 is uploaded, internal1 completed and production1 draft.
Console confirms internal availability, unreviewed. Actual tester opt-in:
https://play.google.com/apps/internaltest/4701148071273382598.
All3products are active at5.49/23.99/55.99, with eligible7day subscription trials.
Lifetime creation required an active BILLING artifact, not upload alone.
RC final readback confirms saved service-account credentials, all3Play products
on both entitlements,3mapped android-offering packages and preserved iOS default.
Public privacy HTTP200 and delete-data anchor verified after accepted main push.

Pre-launch overview had no report before upload; recheck its generation/results.
Licensed Play purchase/restore requires a signed-in licensed tester. IARC terms
approval remains pending. Quit Zyn production1(1.2.7) is in review, so no next
production submission until it clears and fleet pacing permits. No production
review sent or public availability claimed. Owned sol-sheepshead stopped/deleted.

Final Console readback confirms managed publishing off, only Content ratings
needs attention, and pre-launch still has no report after active internal1.
Trial offers now target users who have never held any subscription in this app,
matching the other fleet ports. Product readback verifies active5.49/23.99/55.99
and free P1W phases in every trial region, with app-wide acquisition eligibility.
Google conversion initially picked54.99 for the55.99 lifetime input; the script
now preserves configured US prices and reconciles existing lifetime US price.
Other localized prices keep Play conversion and the fleet PPP curve.
Offer targeting reference:
https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.subscriptions.basePlans.offers#AcquisitionTargetingRule.
