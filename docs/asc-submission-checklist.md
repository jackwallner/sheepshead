# App Store Connect submission checklist, Sheepshead Trainer: Trump Play

This is the release reference for App Store Connect. Metadata, screenshots,
products, pricing, categories, age rating, review details, and build attachment
are scripted. App Privacy is represented locally by
`fastlane/app_privacy_details.json`; the fastlane privacy action still requires
an App Store Connect web session because Apple's public API does not expose this
questionnaire.

## App Privacy ("App Privacy" tab -> Get Started / Edit)

Data collected: **Purchase History** only, via the RevenueCat SDK. No other data
types are collected (no Contact Info, no Location, no Contacts, no User Content,
no Browsing/Search History, no Usage Data, no Diagnostics, and no
Health/Fitness data).

### Purchases
- Data type: **Purchase History**
- Collected: **Yes**
- Linked to the user's identity: **No** (RevenueCat generates an anonymous
  app-user ID and the app has no account or custom identity system)
- Used for tracking (across apps/websites owned by other companies): **No**
- Purpose: **App Functionality** and **Analytics**. App Functionality enables
  Sheepshead+ entitlements. Analytics covers RevenueCat's subscription and
  purchase reporting.

### Everything else: answer "No" / not collected
- Contact Info: No (no account system, no email/name collected in-app)
- Location: No
- Health & Fitness: No
- Financial Info: No (Apple handles payment; the app never sees card data)
- User Content: No
- Search/Browsing History: No
- Usage Data: No (no analytics SDK)
- Diagnostics: No (beyond Apple's own automatic, opt-in crash reporting,
  which Apple already accounts for separately and does not require declaring)

### "Data Not Linked to You" vs "Data Used to Track You"
Select **Data Not Linked to You** for Purchase History. Do **not** select
"Used to Track You". RevenueCat's anonymous identifier is app-scoped and is not
used by this app to correlate activity across other companies' apps or sites.
This matches `docs/privacy-policy.html`, which states that RevenueCat receives
an anonymous app identifier and purchase or entitlement information, not a name
or email.

Source: `Shared/Services/SubscriptionService.swift` and
`fastlane/app_privacy_details.json` (RevenueCat is the only SDK that leaves the
device; there are no ads or tracking pixels).

## Age Rating questionnaire

Target: **4+**.

Answer **No** / **None** to every content category:
- Cartoon or Fantasy Violence: None
- Realistic Violence: None
- Sexual Content or Nudity: None
- Profanity or Crude Humor: None
- Alcohol, Tobacco, or Drug Use: None
- Mature/Suggestive Themes: None
- Horror/Fear Themes: None
- Medical/Treatment Information: None
- **Simulated Gambling: NO.** Sheepshead is a solitaire-style *training*
  app , flashcards, quizzes, and hand-matching drills. There are no
  opponents, no betting, no chips, no stakes, and no wagering mechanic of any
  kind, simulated or otherwise. It never presents sheepshead as a game to win
  money or prizes.
- Contests: None
- Unrestricted Web Access: No (no in-app browser/web view to arbitrary URLs;
  the few outbound links , Terms/EULA, Privacy Policy, Rate on the App
  Store , open in the system browser via `Link`, not an in-app web view)
- User-Generated Content / Communication: None (no chat, no accounts, no
  social features)

Expected result: **4+**, no advisory content descriptors.

## Cross-check against `plan712.md` section 8

- B (subscription legal in metadata): done , see
  `fastlane/metadata/en-US/description.txt` SUBSCRIPTIONS section, mirrored
  into every supported ASC locale with localized storefront copy.
- C (privacy policy live + support/terms resolve): confirmed ,
  `https://jackwallner.github.io/sheepshead/privacy-policy`,
  `https://jackwallner.github.io/sheepshead/terms`,
  `https://jackwallner.github.io/sheepshead/support` all returned HTTP 200 on
  2026-07-12.
- D (age rating = 4+, simulated gambling = No): captured above.
- E (review notes: original hands, non-affiliation, Pro sandbox testing,
  trial terms): written to `fastlane/metadata/review_information/notes.txt`.

## Not covered here (owned elsewhere / by Jack)

- F (OT710 trial page pricing/terms near CTA, paywall fallback): app-code
  verification, not an ASC metadata task.
- G (app icon + launch screen light/dark): verified in the AppIcon asset catalog,
  simulator home screen, and release archive.
- H (StoreKit products exist in ASC with correct prices/trial): created and
  configured by `asc-setup-release.py`, `asc-create-lifetime.py`, and
  `asc-finish-products.py`; verify the final states in `asc-readiness.py`.
- I (TestFlight build): attach the newest `VALID` build to editable version 1.0
  with `asc-attach-build.py` after TestFlight processing completes.
- Submitting for review: **done 2026-08-03**. Version 1.0 with build 22 is
  `WAITING_FOR_REVIEW`, together with the Sheepshead+ subscription group, both
  auto-renewable subscriptions, and the lifetime in-app purchase.

## First-submission gotcha: subscriptions cannot be submitted via the API

`scripts/asc-submit-for-review.py` cannot complete a first submission for an
app whose subscription group has never been reviewed. Apple requires the first
auto-renewable subscription to be submitted **on the app version**, but
`reviewSubmissionItems` has no `subscription` relationship, and
`POST /subscriptionSubmissions` refuses with
`STATE_ERROR.FIRST_SUBSCRIPTION_MUST_BE_SUBMITTED_ON_VERSION`. The app-version
PATCH then fails with `SUBSCRIPTION_GROUP_SUBMISSION_NOT_ALLOWED`.

Do the last step in the App Store Connect web UI:

1. Run the scripts as usual through `asc-attach-build.py`. Adding the version
   as a review submission item moves it to `READY_FOR_REVIEW`, which is why
   `asc-readiness.py` then reports "NO editable version found". That is
   expected, not a failure.
2. Open each subscription under Monetization, click **Add for Review**, and
   pick the existing **Draft iOS Submission** rather than Create New
   Submission. Add every subscription the paywall sells, not just one.
3. Open **Draft Submissions** and click **Submit for Review**.

Subsequent versions do not need this once one subscription has been approved.
