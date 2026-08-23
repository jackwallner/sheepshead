# Sheepshead audit823

Audit date: 2026-08-23

Scope: Sheepshead only, /Users/jackwallner/sheepshead.

Objective: identify concrete opportunities and risks affecting downloads, trial
starts, purchase conversion, ratings, retention, user experience, release
quality, storefront consistency, and the way Cursor, Claude, and Codex should
navigate this repository.

This is an evidence-based audit, not an implementation. The repository and
connected dashboards were inspected read-only. No app code, configuration,
metadata, website, or other file was changed. No commit or push was made.

## Evidence legend

- **Observed** means directly present in local source/config, or returned by a
  read-only ASC, RevenueCat, App Store, or website check on 2026-08-23.
- **Inference** means a likely product, conversion, or operational consequence
  of observed behavior. It needs validation before implementation.
- **Recommendation** means a concrete next step for the implementation agent.
- **Validation** means the smallest useful test or measurement after a change.

## Executive decision list

### P0: stop stale pricing automation from changing the catalog

**Observed:** the app and public site use monthly $6.99, yearly $29.99, and
lifetime $69.99 in Sheepshead/Sheepshead.storekit:6-79,
CLAUDE.md:38-45, and docs/index.html:47-71. The live ASC price schedules
read on 2026-08-23 show current USA prices of $6.99 monthly and $29.99
yearly, with older preserved prices of $1.99 and $9.99. However:

- scripts/asc-setup-release.py:18-33 still encodes monthly $1.99 and yearly
  $9.99.
- scripts/asc-set-prices.py:21-22 still encodes monthly $1.99 and yearly
  $9.99.
- scripts/asc-create-lifetime.py:4-5,103-132 still encodes lifetime $29.99.

**Inference:** rerunning a setup or price script can create a price rollback or
make the source of truth disagree with the product customers see. This is the
highest operational and revenue risk found in the repository.

**Recommendation:** make scripts read one reviewed price configuration, or
require an explicit price argument and print a destructive-change confirmation
before posting. Add a read-only check that compares every hardcoded or loaded
price with the live ASC schedule and with the local StoreKit fixture. Do not
run the existing mutating scripts until their values and intent are reviewed.

**Validation:** run a dry-run mode against ASC and assert:

~~~text
monthly  local=6.99  ASC=6.99  site=6.99
yearly   local=29.99 ASC=29.99 site=29.99
lifetime local=69.99 site=69.99 ASC=<explicitly verified>
~~~

The current audit did not independently confirm the live ASC lifetime price.
Do not assume the $69.99 local value is already the live ASC value until that
one read is performed.

### P1: instrument the complete trial funnel before choosing a paywall winner

**Observed:** SubscriptionService.trackPaywallImpression in
Shared/Services/SubscriptionService.swift:77-89 sends only a RevenueCat
custom paywall impression. There are no purchase-start, CTA-tap, cancellation,
purchase-error, entitlement-delay, restore, onboarding-completion, or
trial-start events. The custom SwiftUI paywall is not a RevenueCat dashboard
Paywall.

RevenueCat currently shows:

- no dashboard Paywalls,
- no Experiments,
- no Funnels,
- one default offering with three packages,
- no useful source-to-trial funnel in the dashboard.

**Inference:** the app can report that someone saw a paywall, and RevenueCat
can report transactions, but it cannot answer which surface caused a trial,
where a user abandoned, or whether a purchase was delayed, cancelled, or
failed. A/B tests would otherwise optimize against revenue noise or a tiny
transaction count.

**Recommendation:** add a small, centralized funnel event layer before running
paywall experiments. Keep RevenueCat customer attributes coarse and
non-identifying. Use a separate event destination or durable local export for
events if RevenueCat is not the chosen analytics sink. Do not scatter raw
Purchases calls throughout views.

**Validation:** every production purchase path must produce a consistent
sequence for the same anonymous customer:

~~~text
paywall_impression
paywall_cta_tap
purchase_started
purchase_cancelled OR purchase_error OR purchase_succeeded
entitlement_unlocked
~~~

Trial start and trial conversion should be reconciled against ASC or RevenueCat
transaction state, not inferred solely from a button tap.

### P1: fix public website structured data and version drift

**Observed:** docs/index.html:74-86 publishes JSON-LD with:

- softwareVersion: 1.2.0, while the public App Store lookup reports 1.2.1
  and the pending ASC version is 1.2.2;
- aggregateRating.ratingValue: 5 and ratingCount: 1, while the public
  iTunes lookup on 2026-08-23 reports averageUserRating: 0 and
  userRatingCount: 0;
- the old App Store slug sheepshead-practice in downloadUrl.

**Inference:** search engines and users can see unsupported social proof and an
old release version. This is a trust and data-consistency problem, not merely
cosmetic stale copy.

**Recommendation:** remove aggregateRating until it is generated from a
verified current review count, update softwareVersion from the release source
of truth, and use the canonical App Store URL directly rather than relying on a
redirect.

**Validation:** fetch the canonical page and App Store lookup in CI, parse the
JSON-LD, and fail if rating count, version, download URL, or product prices are
stale.

### P1: verify the real App Store purchase catalog in a production build

**Observed:** ASC reports all three products approved, current 1.2.2 waiting
for review, and build 28 valid. RevenueCat's current offering has three App
Store products, but each package also retains a Test Store product entry. The
repository history and CLAUDE.md:46-59 document a previous rejection where an
App Store build received an empty Test Store offering.

The read-only checker passes:

~~~text
python3 scripts/verify-store-config.py
OK: 3 packages, every product fetchable
~~~

**Inference:** the catalog is materially healthier than the rejected build, but
the prior failure mode is important enough that a package-present check is not
the same as a successful production purchase. A production build must prove
that the App Store product mapping is the one selected at runtime.

**Recommendation:** add a release-only smoke test that loads all three package
IDs from an App Store/TestFlight build, renders localized prices, completes a
sandbox purchase or restore, and confirms the intended entitlement. Add a
watchdog warning when the current offering includes a package with a missing,
unexpected, or non-App-Store store product.

**Validation:** test monthly, yearly, lifetime, restore, cancel, delayed
entitlement, and product-unavailable paths on TestFlight. Never configure the
production RevenueCat key on a simulator.

### P1: the onboarding trial starts monthly without showing the plan choice

**Observed:** OnboardingView documents the intent at
Sheepshead/Views/OnboardingView.swift:3-14. The final onboarding button calls
primaryAction() at :327-351, ensures offerings, selects
subscriptions.package(for: .monthly), and opens Apple's purchase sheet. The
full three-plan selector is only the fallback if the monthly package is
missing. By contrast, PaywallView initializes selectedPlan to .yearly at
Sheepshead/Views/PaywallView.swift:215-223.

**Inference:** a new user sees a monthly purchase decision without a visible
yearly or lifetime alternative, while a returning user sees yearly selected by
default. This is a meaningful conversion and revenue variable, and it also
creates different purchase experiences for equally qualified users.

**Recommendation:** make the difference deliberate and testable. Candidate
controls are:

1. direct monthly trial, current behavior;
2. direct yearly trial, if the economics and Apple offer eligibility support
   it;
3. one compact plan selector on the trial page;
4. free-first onboarding followed by a plan selector after the first completed
   practice session.

Do not combine plan order, copy, onboarding length, and price changes in one
test.

**Validation:** primary metrics are trial starts per install, trial starts per
trial-page view, trial-to-paid at 8 and 30 days, net revenue per install, and
refund/cancel rate. Guardrails are onboarding completion, first session
completion, product errors, and support complaints.

### P2: add the missing 1.2.2 What's New entry

**Observed:** project.yml:31-32 is marketing version 1.2.2 build 28.
Shared/Services/WhatsNew.swift:44-131 contains release entries for 1.2.0,
1.0, and 1.1, but not 1.2.1 or 1.2.2. currentRelease at :134-145 returns
nil for the current build, so the Home and Settings What's New paths do not
present a release entry for 1.2.2.

**Inference:** the app can ship new paid features without showing a returning
user what changed or why Sheepshead+ is more valuable. This removes a natural
reactivation and upsell surface immediately after an update.

**Recommendation:** add the current release entry as part of the release
checklist, or make release notes data-driven from one versioned source. Keep a
free and paid split, and test whether the update sheet should show the paywall
immediately or only after the user chooses a paid feature.

**Validation:** install the previous public build, update to the candidate, set
no whatsnew.lastSeenVersion, and verify the sheet appears once, dismisses
cleanly, and does not trap free users behind a purchase screen.

## Current state snapshot

### Local app identity

**Observed:**

| Field | Value | Source |
| --- | --- | --- |
| Product | Sheepshead Trainer: Trump Play | project.yml, fastlane/metadata/en-US |
| Display name | Sheepshead Trainer | project.yml:27, README.md:10 |
| Bundle ID | com.jackwallner.sheepshead | project.yml:26 |
| App Store ID | 6796913227 | README.md:13, Shared/Services/ReviewPromptTracker.swift:6 |
| Current local version | 1.2.2 | project.yml:31 |
| Current local build | 28 | project.yml:32 |
| Deployment target | iOS 17.0 | project.yml:7-14 |
| Device family | iPhone and iPad | project.yml:35, Info.plist |
| RevenueCat SDK | SPM from 5.72.0 | project.yml:2-5 |

### ASC and public storefront status

**Observed, read on 2026-08-23:**

| Surface | Result | Interpretation |
| --- | --- | --- |
| ASC version 1.2.2 | WAITING_FOR_REVIEW | Candidate is submitted, not public |
| ASC build 28 | VALID, not expired | Build is attachable and processed |
| Public App Store version | 1.2.1 | Current customer-facing binary is behind local candidate |
| ASC localizations | 50 on the pending version | Locale coverage is complete structurally |
| en-US screenshots | 6 iPhone, 6 iPad | Screenshot inventory exists for both device families |
| Age rating | 4+ | Matches the local release checklist |
| Monthly, yearly, lifetime | All APPROVED | Product states are not the current catalog blocker |
| Subscription trial offers | 175 one-week free-trial records per subscription | Availability is territory and eligibility dependent |
| Public rating lookup | 0 ratings, average 0 | Snapshot, not a claim that no review exists in every storefront UI |

The ASC status is healthy enough to continue release review, but the pricing
script drift, structured-data drift, and production purchase verification are
release blockers for confidence.

### RevenueCat status

**Observed, read-only RevenueCat dashboard snapshot for project 3fd00657, last
28 days shown as 2026-07-27 through 2026-08-23:**

- Active trials: 1.
- Active subscriptions: 0.
- MRR: $0.
- Revenue: $0.
- New customers: 12.
- Active customers: 24.
- Recent activity included one active monthly trial and one recently expired
  yearly trial.
- Product catalog has one current default offering, displayed as
  Sheepshead+, created 2026-08-01, with three packages.
- No RevenueCat Paywall is attached.
- No target rules are configured.
- No Experiments are configured.
- No Funnels are configured.

**Interpretation:** the customer base is early and the dashboard sample is too
small to select a price or paywall winner. The snapshot is useful as a
monitoring baseline, not as a statistically meaningful conversion rate.

**Important boundary:** this audit does not treat the app privacy or privacy
policy wording about RevenueCat data collection as an inconsistency finding.
The user explicitly excluded that category from this audit.

## Product promise and access model

### Free and paid inventory

**Observed:** Shared/Content/DrillLibrary.swift is the content source of truth.
It defines five rooms:

| Room | Free content | Paid content |
| --- | --- | --- |
| Card Room | Meet the Cards, Card Check | Plus Card Extras |
| Trump Room | Read the Cards, Read the Holding | Plus Hand Extras |
| Bury Room | Bury Playbook, Choose Your Bury | Plus Bury Extras |
| Trick Room | Trick Judgment, Trick Rules | Plus Trick Extras |
| Master Tables | None | Advanced Bury, Defense School, Expert Holdings, Master Rules |

Cross-cutting paid modes are Endless Practice, Sheepshead Minute, Game Night
Prep, Timed Challenge, Fix My Mistakes, extra room sets, and Master Tables.

**Observed:** Shared/Content/EndlessPractice.swift:6-107 generates only
handReading and trickPlay skills. It does not generate endless bury or picker
practice. Shared/Content/SessionBuilder.swift:164-223 deliberately excludes
discard items from the uniform Quick Session because they require a two-card
interaction.

**Inference:** the product claims broad repeatable practice, but the primary
generated mode does not cover the Bury Room's signature two-card choice. That
may be a deliberate quality boundary, but it is an expectation gap if the
paywall or marketing says practice never runs out across all skills.

**Recommendation:** either:

- state clearly that Endless Practice covers card reading and trick play, while
  Bury and picker practice live in authored sets and Minute/Game Night flows;
- or build a generated two-card bury mode with the same legal-content
  invariants as authored scenarios.

**Validation:** compare paid users' starts and completion rates by mode. If
Endless Practice is the main paid CTA but users repeatedly choose Bury Room,
prioritize a generated bury loop before adding more generic paywall copy.

### Entitlement and product mapping

**Observed:** SubscriptionService.package(for:) at
Shared/Services/SubscriptionService.swift:103-109 maps yearly to
offering.annual, monthly to offering.monthly, and lifetime to
offering.lifetime. apply(_:) at :178-187 unlocks the app when any active
RevenueCat entitlement exists. CLAUDE.md:46-53 documents both pro and
Sheepshead+ entitlements and the three $rc_* packages.

**Strength:** accepting both old and new entitlement names reduces the risk of
locking out existing purchasers during the RevenueCat migration.

**Risk:** accepting any active entitlement can hide a catalog mistake. A future
unrelated entitlement, test entitlement, or accidentally active product would
unlock the whole app.

**Recommendation:** preserve backward compatibility but require an explicit
allowlist, for example pro and Sheepshead+, and log an internal warning for
any unexpected active entitlement. Keep the product-to-package map tested.

## Download and ASO audit

### Metadata quality

**Observed:** python3 scripts/validate_metadata.py passes with 50 locales.
python3 scripts/validate_aso_brief.py with the Sheepshead brief and product
name also passes.

The en-US fields are close to the ASC limits without exceeding them:

| Field | Value | Length | Limit | Finding |
| --- | --- | ---: | ---: | --- |
| Name | Sheepshead Trainer: Trump Play | 30 | 30 | Uses the full name budget |
| Subtitle | Learn Trump, Bury, and Tricks | 29 | 30 | One character remains |
| Keywords | practice,picker,called ace,partner,blind,quiz,lesson,schafkopf,card game,offline,strategy,rules | 95 chars | 100 bytes | Valid, but should be reviewed for search value |
| Promotional text | Practice trump, picking, partner play, and trick decisions in short drills before your next Sheepshead deal. | 108 | 170 | Clear, skill-specific promise |

**Strengths:** the name says this is a trainer rather than a full game; the
subtitle names three key skills; the description distinguishes the product
from multiplayer competitors; all 50 supported storefront folders contain the
required fields and URLs; prohibited template terms and em dashes are checked.

**Inference:** the metadata is structurally release-ready, but the keyword
source is drifting. docs/research/aso-sheepshead.md:51-69 recommends a map
including trainer, trump, tricks, bury, learn, and called ace, while the actual
en-US keywords use practice, picker, called ace, partner, blind, quiz, lesson,
schafkopf, card game, offline, strategy, and rules. Some terms are already in
the name or subtitle, but the decision is not recorded clearly enough to know
whether the difference is intentional.

**Recommendation:** update the ASO brief with the exact uploaded keyword
string, its byte count, the terms intentionally covered by name/subtitle, and
the next research date. Do not change keywords only because they look
different from the brief. Recheck search demand and competitors before the next
metadata upload.

### Localization

**Observed:** the repository has 50 supported ASC locale directories and the
pending ASC version has 50 version localizations. Sampled metadata includes
localized German, French, Spanish, Japanese, and Simplified Chinese fields.

**Inference:** the storefront presents a broad localized acquisition surface,
while the SwiftUI binary is English literal copy with no visible localization
resource system. This is not automatically wrong, but it creates a promise gap
for users who discover the app through a translated listing and then see
English onboarding, paywall, drills, and settings.

**Recommendation:** choose one explicit strategy:

1. ship only storefront localizations supported by an English binary, with
   accurate expectations;
2. localize the highest-value onboarding, paywall, and first-room paths first;
3. document that the current localized metadata is search testing only and
   should not imply in-app translation.

**Validation:** test each localized storefront's install-to-first-session path
with the device language set to that locale. Measure onboarding completion,
trial-page view, and first session completion by storefront language.

### Screenshots and landing page

**Observed:** ASC readiness reports six iPhone and six iPad screenshots in
en-US. SheepsheadScreenshots/ScreenshotTests.swift:1-194 navigates Home,
Quick Session, Trump, Bury, Trick, and Card Room surfaces. It intentionally
does not open a paywall, trial page, Apple purchase sheet, Settings, or the
What's New sheet beyond dismissing it.

**Inference:** the screenshot set proves the free learning product, but not the
paid value proposition or point-of-purchase clarity. A free-first screenshot
set may be correct for acquisition, but the paid product is not visually
validated in the same automated capture loop.

**Recommendation:** add a separate non-uploaded purchase-flow UI smoke path or
manual capture checklist. Keep App Store screenshots focused on the download
promise, and use the paywall path to validate price, trial, legal links, and
loading states rather than necessarily adding a subscription screenshot to the
storefront.

## Trial and purchase flow

### Current flow map

~~~text
Fresh install
  -> three value pages
  -> required skill selection
  -> trial page
      -> Start 7-day free trial
          -> monthly RevenueCat package
          -> Apple purchase confirmation
              -> purchase success
                  -> How to Play for new users
                  -> Feature Tour
                  -> real Quick Session
                  -> Home
              -> cancel, stay on trial page
              -> error, show Purchase Issue
              -> monthly package missing, open full plan paywall
      -> Get Started
          -> How to Play for new users, otherwise Feature Tour
          -> real Quick Session
          -> Home
~~~

~~~text
Returning free user
  -> Home, Room, locked training tile, Settings, or update upsell
  -> shared custom PaywallView
  -> yearly selected by default
  -> monthly or lifetime selectable
  -> Apple purchase sheet or Restore
~~~

### Strong choices already present

- The app keeps the primary onboarding button in the same geometry across
  pages, reducing accidental movement at the trial decision.
- The free exit is visible on the trial page.
- The trial page has Terms, Privacy, and Restore links.
- The full paywall uses live localized RevenueCat StoreProduct prices rather
  than hardcoded customer-facing prices.
- ensureOfferings() retries the offering fetch when a paywall opens, which
  directly addresses the historical zero-package failure.
- Purchase cancellation is treated as a normal outcome, so it does not open a
  second paywall.
- confirmEntitlement() polls after purchase and tells the user to Restore if
  money moved but the entitlement is delayed.
- A new user is shown How to Play before the real practice session.
- The free rooms remain usable and the free path is not blocked by a trial.

### Conversion and UX risks

#### The first purchase surface is direct monthly

The direct monthly path is simple, but it hides lifetime and yearly choices from
the user most likely to be evaluating the product carefully. The fallback path
behaves differently from the normal path. This should be treated as a deliberate
pricing experiment, not an implementation accident.

#### Price fallback can omit the billed amount

OnboardingView.monthlyDisclosure at :238-243 returns
Includes 7 days free. Auto-renews until canceled. when the monthly product is
not available. PaywallPricing.terms at PaywallView.swift:197-210 does the same
for recurring plans. The full paywall then retries offerings, but the
onboarding CTA can still present a generic disclosure immediately before a
purchase attempt.

**Recommendation:** if the billed amount is unavailable, disable the purchase
CTA or show a clearly labeled loading/error state until the product is loaded.
Do not make a purchase decision with a generic no-price disclosure.

#### Trial eligibility is not surfaced before the Apple sheet

The copy says Start 7-day free trial, but the app does not show whether the
Apple Account is eligible. Terms mention that trial availability is for
eligible accounts, but the onboarding page does not. Returning users who used
the introductory offer may see a purchase sheet that does not behave as the
headline suggests.

**Recommendation:** use eligibility-safe copy such as Try Sheepshead+ until
the store response proves the offer, or render the actual offer state. Do not
promise a free trial for an ineligible account.

#### Restore on onboarding is silent on failure

OnboardingView.swift:293-295 calls try? await subscriptions.restore() and does
not display an error or a no-purchase result. Settings and PaywallView do
display restore outcomes.

**Recommendation:** use the same restore state and error message component in
all three surfaces. A user who reinstalls during onboarding should know whether
the restore succeeded, found nothing, or failed due to network/store state.

#### Entitlement confirmation window is short for a paid state transition

confirmEntitlement() defaults to three attempts with 1.2 seconds between
attempts, about 2.4 seconds of waiting after the initial check. The warning is
good, but a delayed App Store or RevenueCat response can still make a
successful customer think the purchase failed.

**Recommendation:** test the current timeout with delayed sandbox responses.
Consider a non-blocking pending state with an automatic refresh, plus a clear
Restore action, rather than extending the blocking spinner indefinitely.

#### The update upsell can be lost after a failed paywall

WhatsNewSheet calls WhatsNew.markSeen() before the optional paywall flow. If
the paywall fails or the user dismisses it, the update sheet will not recur.
This may be acceptable for low pressure UX, but it should be intentional.

**Recommendation:** mark the release seen after the user dismisses the update
content, but track whether the paid CTA was shown and whether it succeeded. Do
not repeat the whole sheet just because a purchase failed.

### Purchase edge-case matrix

| Scenario | Expected behavior | Current code surface | Priority |
| --- | --- | --- | --- |
| Cold launch, offerings loading | CTA waits or clearly says loading | SubscriptionService.start, ensureOfferings | P1 |
| Offering has zero packages | No dead CTA, useful error | ensureOfferings, PurchaseError | P1 |
| Monthly package missing on onboarding | Full plan fallback | OnboardingView.primaryAction | P1 |
| User cancels Apple sheet | Stay on current page, no error | PurchaseOutcome.cancelled | P2, validate |
| Purchase succeeds, RC delayed | Pending state and eventual unlock | confirmEntitlement | P1 |
| Trial already consumed | Accurate Apple/store copy | No app eligibility state | P1 |
| Lifetime purchase | One-time copy, no renewal language | PaywallPricing.terms | P2, validate |
| Restore finds entitlement | Unlock and explain success | Paywall/Settings, onboarding differs | P1 |
| Restore finds nothing | Explain no previous purchase | Paywall/Settings, onboarding silent | P1 |
| User opens locked drill repeatedly | Source-specific measurement, no loop | shared PaywallView | P2 |
| iPad landscape and large type | Footer, terms, and cards remain usable | custom paywall layout | P1, unverified |
| Store product price changes | All surfaces use live localized price | app mostly does, scripts do not | P0 |
| Unexpected active entitlement | Do not silently unlock wrong product | apply(_:) accepts any active entitlement | P1 |

## Paywall and A/B test opportunities

The current implementation is a custom SwiftUI paywall, not a RevenueCat native
Paywall. RevenueCat Experiments and Paywalls are therefore not active control
surfaces today. The Apple-native purchase sheet is the final confirmation layer
and should not be A/B copied or obscured.

### Suggested experiment backlog

| Test | Control | Variant | Primary metric | Guardrails | Code surface |
| --- | --- | --- | --- | --- | --- |
| Onboarding plan choice | Direct monthly trial | Compact monthly/yearly/lifetime selector | trial start per trial-page view, net revenue per install | onboarding completion, first session | OnboardingView |
| Default recurring plan | Yearly selected | Monthly selected | trial start, paid conversion | annual mix, refund/cancel rate | PaywallView.selectedPlan |
| Lifetime anchor | Current third card | Lifetime card with explicit one-time value comparison | lifetime starts, total revenue | recurring trial starts, revenue per install | PaywallContent, PaywallPricing |
| Paywall headline | Get Sheepshead+ | Practice every day before your next deal | CTA tap rate | completion of free content | PaywallContent |
| Benefit order | Endless, mistakes, timed | Start with the locked feature that caused entry | CTA rate by source | no increase in dismissals | PaywallContent plus source copy |
| Source-specific copy | Generic membership message | Bury-specific or timed-challenge-specific copy | CTA rate by locked feature | downstream paid conversion | RoomView, HomeView |
| First paywall timing | Show at first locked tap | Show after one completed free room | trial start per install, free activation | retention and paywall dismissals | HomeView, product gate |
| Free-first onboarding | Trial CTA on page 5 | Free five-minute session before trial CTA | first session completion, later trial start | day-1/day-7 retention | OnboardingView, FeatureTourView |
| Update upsell | Optional update sheet CTA | Neutral update sheet, upsell only from locked feature | post-update paid starts | update completion and support contacts | WhatsNewSheet, HomeView |
| CTA language | Start 7-day free trial | Try Sheepshead+ free or eligibility-safe Try Sheepshead+ | CTA tap and purchase success | trial disputes and cancellations | OnboardingView, PaywallView |

### Test discipline

- Run one primary variable per experiment.
- Persist a variant assignment so the same customer does not see different copy
  in the same session.
- Include paywall_source, paywall_variant, selected_plan, and app_version in
  the event record.
- Report both starts and downstream outcomes. CTA rate alone is not a win.
- Use a minimum cohort and a fixed observation window. The current RevenueCat
  volume is too small for rapid conclusions.
- Do not fabricate social proof. The current website rating markup should be
  removed until it is real.

### Paywall surfaces to exercise manually

The source IDs are:

- sheepshead_onboarding_trial
- sheepshead_onboarding_fallback
- sheepshead_home_sheet
- sheepshead_room_sheet
- sheepshead_settings_sheet

For each, test fresh install, returning free user, returning paid user, slow
network, no network, zero packages, localized pricing, Dynamic Type, VoiceOver,
dark mode, iPhone portrait, iPad portrait, and iPad landscape. Verify that a
sheet cannot be presented on top of another sheet, that close returns to the
same context, and that a successful purchase does not leave a stale lock on the
originating screen.

## RevenueCat attributes and usage signals

### What is observable now

**Observed:** usage is almost entirely local:

- ProgressStore stores streaks, completed drills, seen items, missed items, and
  daily Quick Session completion in UserDefaults.
- PracticeRecordStore stores per-item or per-skill attempts, accuracy, room,
  due date, and challenge high score locally.
- SheepsheadMinuteStore keeps a local 30-day result archive.
- AppSettings stores appearance, sound, haptics, and reminder preferences.
- RevenueCat receives purchase and entitlement state, plus the custom paywall
  impression already sent by SubscriptionService.
- No general analytics SDK, user identity system, server-side practice history,
  or customer attribute calls are present in the repository.

**Inference:** the app can personalize locally, but the owner cannot tell which
room, paywall surface, onboarding choice, or free-to-paid path is working across
customers. RevenueCat's current customer counts cannot explain product usage.

### Recommended coarse custom attributes

Use only low-cardinality, non-sensitive attributes. Set them through one
centralized service, and overwrite the current value rather than creating a new
attribute name for every experiment.

| Attribute | Values | Set or update at | Why |
| --- | --- | --- | --- |
| skill_level | new, basics, played | OnboardingView.skillCard, :161-166 | Segment first-session and trial behavior |
| onboarding_completed | true | OnboardingView.finish, :368-375 | Distinguish install from activated user |
| last_paywall_source | known source IDs only | PaywallView task, :281-284 | Compare locked-drill contexts |
| paywall_variant | short controlled ID | assignment point before render | Reconcile A/B exposure |
| last_selected_plan | monthly, yearly, lifetime | plan selection in PaywallView | Explain product mix |
| trial_plan | plan ID or none | after verified store transaction | Trial mix, not intent only |
| completed_free_room_count | bounded integer | after room completion | Activation depth |
| last_practice_room | room IDs | session start or completion | Usage segmentation |
| completed_session_count | bounded integer or coarse bucket | completion path | Retention depth without raw history |
| review_queue_bucket | 0, 1-3, 4-12, 13+ | before Game Night or Fix My Mistakes | Understand repeat-use value |
| app_version | semantic version | app start or purchase surface | Release regression comparison |

Do not send card holdings, answers, feedback text, email, name, exact location,
or raw practice history as a custom attribute. Do not use a high-cardinality
attribute for every drill ID or session timestamp.

### Recommended event taxonomy

These events can be implemented in the chosen analytics sink. RevenueCat's
existing paywall impression API is not a substitute for all of them.

~~~text
app_opened
onboarding_page_viewed
skill_selected
onboarding_completed
free_session_started
free_session_completed
free_session_abandoned
paywall_impression
paywall_cta_tap
purchase_started
purchase_cancelled
purchase_failed
purchase_succeeded
entitlement_unlocked
restore_started
restore_succeeded
restore_empty
trial_started
trial_converted
review_prompt_shown
review_feedback_started
review_store_open_requested
~~~

Suggested insertion points:

- SheepsheadApp.body.onAppear for app_opened and app version.
- OnboardingView.onChange(of: page) and finish() for onboarding events.
- OnboardingView.skillCard for skill selection.
- PaywallView.task for impressions, preserving the existing source IDs.
- PaywallView.purchase() before and after SubscriptionService.purchase for CTA,
  start, cancel, and error.
- SubscriptionService.apply(_:) for a single transition into an allowlisted
  entitlement.
- SettingsView and PaywallView.restore() for restore outcomes, including no
  entitlement.
- QuickSessionView start/finish and DrillCompleteView for session outcomes.
- ReviewPromptSheet and ReviewPromptTracker for review funnel outcomes.

## UX audit by journey

### First launch and onboarding

**Observed:** OnboardingView has three value pages, a required skill choice,
and a trial page. New users then receive How to Play, Feature Tour, and a real
Quick Session before Home. The free path and paid path eventually merge into the
same teaching flow.

**Strengths:** clear product boundary, no account requirement, a free exit,
skill-based routing, a primer before an unfamiliar first session, and a real
practice result instead of an empty lobby.

**Risks:** there are at least four decision pages before the first hands-on
question, the skill choice is required, and the user can encounter two more
onboarding layers after choosing the trial or free path. This may be excellent
for true beginners but slow for returning Sheepshead players.

**Recommendations:**

- Test a returning-player fast path using the played choice that skips or
  compresses How to Play and Feature Tour.
- Test a try-one-free-drill route before asking for a trial.
- Keep the current full primer available from How to Play and Settings.
- Track page-level abandonment, not just onboarding completion.
- Make the trial page disclose the actual plan and price before the button. If
  the price is unavailable, keep the CTA disabled until it is available.

### Home

**Observed:** HomeView provides Get Started, optional primer, training tiles,
four free rooms, a locked Master Tables room, and a bottom upgrade card. Locked
training tiles, locked rooms, upgrade card, Settings membership, and update
upsell all open the shared paywall.

**Strengths:** room-based information architecture, many free entry points,
progress rings, a strong first action, and a consistent membership surface.

**Risks and opportunities:**

- Multiple paywall surfaces currently collapse into the same source class or
  broad source ID. Distinguish the exact feature and visual context in events.
- The bottom upgrade card may be below the first screen on a small phone, while
  locked tiles appear earlier. Compare each source's conversion.
- Locked tile accessibility hint says Included with Sheepshead+, but does not
  state that tapping opens the purchase screen. Improve VoiceOver
  discoverability.
- If WhatsNew is missing the current version, a new paid feature can be
  present in code but absent from Home's update explanation.

### Rooms and content

**Observed:** free drills open directly; paid drills and Master Tables open the
paywall. RoomView.swift:103-115 limits drill subtitles to two lines.
HomeView.swift:521-575 uses progress rings and ProgressStore.roomProgress.

**Recommendation:** verify that progress denominator semantics match the paid
gate. The local product note says progress counts only drills a player can
currently open, while ProgressStore.roomProgress(_:) divides by all drills in
the room. If the home card filters paid drills elsewhere, a free player can see
different completion semantics than the underlying store. Add a test that
asserts free and paid denominators deliberately.

**Validation:** for a free account with one completed free drill, compare Home
ring, Room row state, Stats, and the underlying count for every room. Repeat as
paid and after a content addition.

### Practice and feedback

**Strengths:** QuickSessionView snapshots its item list, holds the answer until
Next, uses a consistent choice flow, records local progress, and avoids
replacing a live question during a state update. The code comments show that
this was a prior UX failure and the current design addresses it.

**Risks:** there is no external start, completion, or abandonment signal. The
owner cannot identify whether users stop on a particular question, explanation,
or interaction type. Generated practice IDs are UUID-based and rolled up by
skill, which is good for local storage but poor for content-level analysis.

**Recommendation:** add stable content and interaction IDs to aggregate events
without sending raw card data. Track answer type, room, question index, and
completion, not the user's full holding.

### Daily Minute and Game Night Prep

**Observed:** SheepsheadMinuteStore is local, keeps 30 days, and produces a
shared daily five-question challenge. Game Night Prep uses local reminders and
routes into a personalized local session. Both are Sheepshead+ gated.

**Opportunities:** these are the strongest retention loops in the product. Add
deep links and lifecycle metrics for notification delivered, opened, session
started, session completed, and paid gate encountered. Measure whether the
weekly reminder creates practice or only notification opt-outs.

**Risks:** local-only archives cannot support cross-device continuity or
owner-visible retention analysis. That may be an intentional privacy and
simplicity choice; do not add accounts solely for analytics without a product
decision.

### Accessibility and layout

**Observed:** there are useful accessibility labels and hints in Home, Flashcard,
How to Play, and screenshot helpers. The repository also supports iPad
portrait/landscape and readable content widths. The screenshot test does not
cover paywall, trial, Settings, or Dynamic Type.

Potential checks:

- Paywall plan cards should expose plan name, price, trial/renewal status, and
  selection state as one VoiceOver element.
- Locked Home tiles should announce that they open Sheepshead+ details.
- RoomView subtitle lineLimit(2) should be checked at the largest Dynamic Type
  size and in German or long translated content.
- Paywall safe-area footer should remain visible when content, legal copy, and
  Apple price strings expand.
- Bury selection should announce selected count and the selected card state.
- Confetti, sound, and haptics should not be the only feedback for a correct or
  incorrect answer.

**Validation:** run VoiceOver and Dynamic Type on iPhone and iPad for onboarding,
trial page, paywall, locked room, bury selection, completion, and Settings.

## Ratings and review funnel

### Current behavior

**Observed:** ReviewPromptTracker.swift:49-108 requires at least three positive
moments and two app launches. It uses a 120-day cooldown after a hard decision
and 30 days after Maybe later. DrillCompleteView.swift:77-100 records a
positive moment whenever a drill completion screen appears. The Daily Minute
result path does the same at SheepsheadMinuteView.swift:291-292.

ReviewPromptSheet.swift:74-132 asks whether the player is enjoying the app,
routes happy users to the App Store, and routes unhappy users to mail feedback.
Settings can open the review pitch directly at SettingsView.swift:175-179.

### Rating conversion risks

1. A positive moment is currently any completed drill, including a low score.
   The completion headline can say Good practice! for a score below 70%, but
   that completion still increments the review gate.
2. ReviewPromptSheet calls markOpenedWriteReview() before
   UIApplication.shared.open and does not inspect an open completion callback.
   If the URL fails to open, the prompt is permanently retired.
3. The native requestReview() path has no observable display or submission
   result because Apple controls its quota and presentation.
4. The Settings rate path deliberately bypasses the enjoyment gate. This is
   useful for an explicitly motivated user, but it should be measured separately
   from the earned prompt.
5. The public lookup currently reports zero ratings. The website's JSON-LD
   claims one five-star rating, which must be removed or verified.

**Recommendations:**

- Separate drill_completed from positive_moment_eligible.
- Require a high-confidence positive signal, such as a high score, a repeat
  session, an explicit yes, or a completed explanation interaction, before
  asking for a rating.
- Keep unhappy users in feedback, but add a lightweight internal feedback
  outcome event so the owner can see whether mail was available.
- Use the UIApplication.shared.open completion handler and only mark the
  external review outcome when the system reports the URL opened.
- Add a Rate test path that verifies the correct app ID, current storefront,
  and no stale redirect.

**Validation:** with a clean UserDefaults suite, test completion scores 0%, 60%,
70%, and 100%, the third completion, two launches, hard dismissal, soft defer,
Settings entry, missing Mail app, and failed App Store URL open. Verify prompt
frequency, feedback access, and no rating ask immediately after an error.

## Website, terms, privacy, and storefront consistency

### Positive consistency

- App Store metadata support and marketing URLs point to the GitHub Pages site.
- Paywall Terms link uses Apple's Standard Licensed Application EULA.
- Paywall Privacy link matches the metadata privacy URL.
- Local privacy and terms pages were last updated August 17, 2026.
- The live GitHub Pages home, privacy, terms, and support URLs returned HTTP
  200 in the read-only check.
- The site and StoreKit fixture agree on monthly $6.99, yearly $29.99, and
  lifetime $69.99 locally.
- The site says four practice rooms and no account, matching the app's local
  room structure and onboarding.

### Issues to resolve

#### Duplicate legal page sources

docs/privacy-policy.html and docs/privacy-policy/index.html contain the same
legal body but different relative navigation links. The same is true for Terms.
Support is duplicated exactly. This is a maintenance hazard because a future
legal update can reach one URL but not the other.

**Recommendation:** select one canonical source, generate both routing forms,
and add a link/content equality check. Keep the ASC URL, website URL, and
redirect behavior in a single release manifest.

#### Canonical host and App Store marketing URL differ

docs/index.html:13,25,75 declares
https://jackwallner.com/ios/sheepshead/ as canonical, while ASC metadata uses
https://jackwallner.github.io/sheepshead/. Both were reachable, but they are
two public hosts for one acquisition page.

**Recommendation:** make the portfolio URL the canonical public URL if that is
the intended brand destination, or make GitHub Pages canonical if it is the
operational source. Keep the other URL as a redirect or mirror with explicit
canonical tags and an automated freshness check.

#### Old App Store slug appears in every website CTA

docs/index.html:76,557,574,841 links to
apps.apple.com/us/app/sheepshead-practice/id6796913227. The URL redirects to
the canonical sheepshead-trainer-trump-play page.

**Recommendation:** update all download links to the final canonical URL. A
redirect is functional, but a direct link is faster, clearer in previews, and
less likely to become stale if Apple changes slug behavior.

#### Website says iPhone while the app supports iPad

docs/index.html:569-570 says iPhone, Four practice rooms, Works offline,
while project.yml:35, ASC screenshots, and the app guide support iPad.

**Recommendation:** say iPhone and iPad or intentionally position the site as
phone-first. Keep the App Store screenshot set and site promise aligned.

#### Landing page release and rating markup is stale

See the P1 finding above. The softwareVersion, aggregateRating, and old
download slug should be generated or checked rather than hand-maintained.

### Legal wording checks

The paywall uses price-specific copy when a StoreProduct is available and links
to Terms and Privacy. The metadata description states that monthly and yearly
subscriptions have a seven-day trial, auto-renew, charge the Apple ID, and can
be canceled at least 24 hours before renewal. The local Terms page states the
same purchase mechanics.

**Recommendation:** keep one reviewed legal phrase table and test the following
strings in all purchase surfaces:

- seven-day free trial only when the store presents an eligible offer;
- amount and billing period before confirmation;
- auto-renewal;
- cancellation timing;
- Apple Account charge timing;
- one-time lifetime distinction;
- restore path;
- Terms and Privacy links.

This audit intentionally does not reopen the RevenueCat data-disclosure
question that the user excluded.

## Crash, regression, and deprecation watchdog signals

### Evidence available now

**Observed:** there is no crash reporting SDK, MetricKit consumer, server event
pipeline, or crash export in the repository. ios27Sheepshead.md:3-26 records a
read-only compatibility pass on 2026-08-05 with build, tests, launch, and UI
snapshot passing, but with main-actor isolation warnings in
Sheepshead/Utilities/Theme.swift and test files. Current tests were not
rerun during this read-only audit.

The source search found no app production fatalError, preconditionFailure, TODO,
FIXME, or HACK. The test suite contains try! XCTUnwrap in
SheepsheadTests/PracticeRecordStoreTests.swift:140, which is test-only.

scripts/testflight.sh is not a read-only watchdog: it increments project.yml,
regenerates the project, cleans, archives, and uploads. Do not use it as an
audit command.

### Production signals to monitor after each release

| Signal | Baseline and alert | Source or implementation point |
| --- | --- | --- |
| Crash-free users/sessions | Compare candidate build 28 with public 1.2.1; alert on statistically meaningful regression | ASC/Xcode Organizer or crash provider |
| Hang rate and launch failure | Any new spike in first launch or first Home render | ASC diagnostics, TestFlight feedback |
| Memory termination | New rate by device family, especially iPad | ASC diagnostics |
| Onboarding completion | Drop from install to progress.hasOnboarded | funnel event at OnboardingView.finish |
| Trial-page reach | Drop before page 4/5 | OnboardingView.onChange(of: page) |
| Product-unavailable errors | Any production occurrence is urgent | PurchaseError.productsUnavailable |
| Purchase cancellations | Monitor by plan and source, not as an error | PurchaseOutcome.cancelled |
| Purchase success without unlock | Any occurrence is P1 | confirmEntitlement warning path |
| Restore failures/empty restores | Alert if rate changes after release | restore methods in Settings, Paywall, onboarding |
| Trial starts | Compare to trial-page views, not installs alone | ASC/RevenueCat transaction state |
| Trial-to-paid | Cohort at eight and 30 days | RevenueCat customer state |
| Rating velocity | Alert if a release changes review volume or sentiment | App Store reviews, not only native prompt count |
| Website links | Any non-200 or redirect chain over one hop | CI HTTP checker |
| Product price drift | Any local/ASC/site mismatch | read-only ASC checker plus JSON-LD parser |
| Metadata drift | Missing locale, over-limit field, stale version | metadata validator plus ASC comparison |
| Concurrency warnings | Warnings-as-errors before SDK/Xcode change | Xcode build/test output |

### Regression release matrix

For every production release, validate these paths on a TestFlight build and
one current iPhone plus one iPad:

1. Fresh install, onboarding, free exit, first free session.
2. Fresh install, monthly trial offer, cancel, retry.
3. Fresh install, monthly purchase success, delayed entitlement, app relaunch.
4. Returning free user, locked room, locked drill, each training tile, Home
   upgrade, Settings upgrade.
5. Yearly purchase and lifetime purchase from the full paywall.
6. Restore with a previously purchased Apple Account.
7. Restore with no purchase and with a temporary network failure.
8. Daily Minute, Game Night Prep, reminders, and notification deep link.
9. Review prompt after high, medium, and low score completions.
10. Dark mode, light mode, largest Dynamic Type, VoiceOver, portrait, and
    landscape.
11. App update from public 1.2.1 to candidate 1.2.2, including What's New.
12. Background/foreground during Apple purchase and during entitlement refresh.

### Deprecated UX checks

The next watchdog should flag stale or deprecated experiences without AI when
possible:

- local version does not match project.yml, pending ASC version, public site
  JSON-LD, README, or What's New release data;
- live download links use an old App Store slug or require multiple redirects;
- a paywall says trial when StoreKit presents no eligible trial;
- a recurring plan has a price missing from the CTA disclosure;
- a package is missing, mapped to the wrong product ID, or has a Test Store
  product in a production resolution path;
- a free/paid progress denominator differs between Home, Room, and Stats;
- a legal URL returns a non-200 response or duplicate legal files diverge;
- the landing page's rating markup is greater than the actual App Store count;
- no What's New data exists for the current marketing version;
- release scripts contain a price or version older than the reviewed manifest;
- the app build emits new compiler deprecation or actor-isolation warnings;
- UI smoke cannot find trial CTA, Terms, Privacy, Restore, or Close controls;
- a paid purchase succeeds but the app remains locked after the entitlement
  refresh window;
- notification settings show enabled while the pending request is absent;
- a notification routes to a stale or unavailable destination.

## Cursor, Claude, and Codex repository hygiene

### Current state

**Observed:**

- CLAUDE.md is the detailed root project guide.
- AGENTS.md is a symlink to CLAUDE.md, so Codex and Claude share one
  canonical instruction file.
- No .cursor rules, .mdc files, nested AGENTS.md, nested CLAUDE.md, or
  Codex-specific repository instruction directory was found in the first three
  levels.
- archive/README.md correctly says archived notes are historical and not
  current state.
- docs/tasks/ contains short active-looking content and Quick Session task
  notes, but there is no explicit owner/status/index for them.
- docs/asc-submission-checklist.md mixes historical 1.0/build 22 submission
  notes, rejection history, and current procedural guidance.
- README.md:14 still says marketing version 1.0.
- README.md:37-44 points agents to release scripts, but does not warn that
  scripts/testflight.sh mutates version/build state and uploads.
- ios27Sheepshead.md is a dated compatibility note with unresolved warnings.
- Shared/Services/WhatsNew.swift has no 1.2.2 release entry.
- docs/research/aso-sheepshead.md is marked final with a research date of
  2026-08-01, while docs/research/sheepshead-market.md explicitly says to
  recheck competitors and prices before a monetization decision.

### Risks for an implementation agent

An agent reading only README.md can believe the app is version 1.0. An agent
reading only docs/asc-submission-checklist.md can follow a version 1.0
submission path. An agent reading CLAUDE.md gets the current product prices,
but could still run stale price scripts. An agent reading docs/research can
use a keyword plan that does not match the uploaded metadata. This is exactly
the kind of cross-document contradiction that causes agents to make unsafe
release changes.

### Recommended documentation contract

Keep one short, current root index and separate historical material by status:

~~~text
CLAUDE.md                  canonical agent and project instructions
AGENTS.md                  symlink to CLAUDE.md
README.md                  human-facing project identity and safe commands
docs/current/              current product, funnel, pricing, and release facts
docs/release/              current release checklist and validation evidence
docs/research/             dated research with status and next-review date
docs/tasks/                active implementation tasks with owner/status
docs/audits/               dated audit artifacts
archive/                   immutable historical notes only
~~~

The implementation agent should not move or delete files automatically during
this audit. After a separate documentation cleanup decision:

1. Put the reviewed price/product manifest in docs/current/.
2. Add a status, last verified, and next review header to every active research
   or release document.
3. Mark the old ASC checklist sections as historical, or split current
   procedure from rejection history.
4. Update README version and safe command descriptions.
5. Keep the root agent guide limited to durable rules and links to current
   operational facts.
6. Keep audit823.md as the handoff artifact requested for this audit. Move it
   to docs/audits/ only in a later task that explicitly allows another write.

### Agent-safe commands to document

Clearly label commands as read-only, local test, or mutating:

| Command | Class | Note |
| --- | --- | --- |
| python3 scripts/validate_metadata.py | Read-only | Local field and limit check |
| python3 scripts/validate_aso_brief.py ... | Read-only | Research brief check |
| python3 scripts/verify-store-config.py | Read-only | ASC/RevenueCat catalog check |
| python3 scripts/asc-readiness.py | Read-only | ASC version/build/product check |
| xcodebuild ... test | Local validation | May use simulator/DerivedData, no production RC on simulator |
| xcodegen generate | Mutating | Rewrites generated Xcode project |
| scripts/testflight.sh | Mutating/external | Bumps build, archives, uploads |
| scripts/asc-set-prices.py | Mutating/external | Changes live price schedules |
| scripts/asc-submit-for-review.py | Mutating/external | Submits ASC review state |

## Prioritized implementation backlog

### P0, before another pricing or release automation run

1. Replace stale prices in scripts/asc-setup-release.py,
   scripts/asc-set-prices.py, and scripts/asc-create-lifetime.py with a
   reviewed source-of-truth design.
2. Independently read the live ASC lifetime USA price and record it with a
   timestamp.
3. Add a dry-run price drift check across StoreKit, ASC, site JSON-LD, and the
   reviewed manifest.
4. Remove or regenerate the landing page's unsupported aggregate rating.

### P1, before judging conversion or shipping a new monetization flow

1. Add complete funnel instrumentation and source/plan/variant dimensions.
2. Add production App Store catalog and entitlement smoke coverage.
3. Make trial eligibility and price-loading states accurate before the CTA.
4. Unify restore handling across onboarding, PaywallView, and Settings.
5. Add the current What's New entry for 1.2.2 and verify the update flow.
6. Validate the paywall on iPad, Dynamic Type, and VoiceOver.
7. Reconcile the website version, rating markup, canonical download URL, and
   device support copy.

### P2, after instrumentation is available

1. Run onboarding direct-monthly versus plan-choice test.
2. Run default yearly versus monthly test with revenue and cancellation
   guardrails.
3. Compare first locked-feature paywall against free-first timing.
4. Add source-specific value copy for Bury, Timed Challenge, and Master Tables.
5. Decide whether Endless Practice needs a generated bury/picker mode.
6. Improve review eligibility to use completed high-confidence positive moments.
7. Centralize duplicate legal pages and add link/content checks.
8. Refresh ASO research and record the exact uploaded keyword decision.

### P3, documentation and ongoing hygiene

1. Update README from 1.0 to a generated current-version reference.
2. Split current ASC procedure from historical rejection notes.
3. Add status and next-review dates to research and task documents.
4. Resolve main-actor warnings in Theme.swift and test targets before enabling
   warnings-as-errors.
5. Add a machine-readable release manifest consumed by website, metadata,
   scripts, What's New, and audit checks.

## Validation plan for the implementation agent

Run these read-only repository checks first:

~~~bash
python3 scripts/validate_metadata.py
python3 scripts/validate_aso_brief.py \
  --brief docs/research/aso-sheepshead.md \
  --product-name 'Sheepshead Trainer: Trump Play'
source ~/.baseball_credentials
python3 scripts/verify-store-config.py
python3 scripts/asc-readiness.py
~~~

Then add or run, in a controlled branch and with the user's approval for any
mutation:

~~~bash
# Local app validation, use the leased headless agent-sheepshead simulator.
xcodebuild -project Sheepshead.xcodeproj -scheme Sheepshead \
  -destination 'id=<agent-sheepshead-udid>' test CODE_SIGNING_ALLOWED=NO

# Screenshot/UI validation after the test harness is intentionally extended.
scripts/capture-screenshots.sh <udid> <output-dir>
~~~

For a candidate release, the validation report should include:

- source version/build, pending ASC version/build, and public App Store
  version;
- all three product IDs, product states, USA prices, and trial records;
- RevenueCat offering/package/entitlement resolution from an App Store build;
- onboarding page views, free exits, first session, trial CTA, trial start,
  paid conversion, and restore outcomes;
- crash-free users, crash-free sessions, hangs, memory terminations, and launch
  failures compared with the prior public build;
- public landing page JSON-LD version, rating count, price, canonical URL, and
  direct App Store URL;
- all legal and support URL status codes;
- metadata locale count, field limits, and exact source hash;
- current What's New coverage;
- iPhone/iPad, accessibility, Dynamic Type, dark mode, notification, and
  purchase edge-case results.

## Known gaps and confidence limits

- No live crash, hang, memory, or App Store diagnostic export was available in
  the repository context. The watchdog section is a concrete monitoring
  specification, not evidence of a current production spike.
- No fresh build/test run was performed during this audit. The cited iOS 27
  pass is historical and includes concurrency warnings.
- The ASC current lifetime price was not independently confirmed in the current
  read. Local StoreKit, site, and CLAUDE.md agree on $69.99; one mutating
  lifetime script says $29.99.
- RevenueCat dashboard counts are a small 28-day snapshot and should not be
  treated as conversion rates.
- The public App Store rating result is a read-only iTunes lookup snapshot.
- This audit does not assess the RevenueCat app privacy disclosure mismatch
  category that the user excluded.
- The audit recommends instrumentation and watchdog work but does not create
  or deploy a notification, crash reporter, or external analytics service.

## Read-only completion record

The only permitted output from this focused rerun is this file:
/Users/jackwallner/sheepshead/audit823.md

No other Sheepshead file was edited. No app code or configuration was edited.
No commit or push was performed.

## Activity and success context, 2026-08-23

Classification: **low-scale monetizing**. Confidence: **low**. Trend: **no ASC comparison displayed**.

ASC release state: `iOS 1.2.2 Waiting for Review`. ASC evidence: [Analytics Overview](https://appstoreconnect.apple.com/apps/6796913227/analytics/overview?dateSpec=d90), selected range `dateSpec=d90`.
RevenueCat evidence: [Project Overview](https://app.revenuecat.com/projects/3fd00657/overview), production mode, selected range `Last 28 days, 2026-07-27 through 2026-08-23`.

### Observed activity

| Source | Metric | Value | Window or comparison |
| --- | --- | ---: | --- |
| ASC | First-time downloads | 6 | 90-day Analytics Overview |
| ASC | Redownloads | 1 | 90-day Analytics Overview |
| ASC | Conversion rate | 0.7% | comparison not displayed |
| ASC | Proceeds | $2 | 90-day Analytics Overview |
| ASC | In-app purchases | 2 | 90-day Analytics Overview |
| RevenueCat | New customers | 12 | last 28 days |
| RevenueCat | Active customers | 24 | last 28 days |
| RevenueCat | Active trials | 1 | current total |
| RevenueCat | Active subscriptions | 0 | current total |
| RevenueCat | MRR | $0 | current total |
| RevenueCat | Revenue | $0 | last 28 days |

A missing value above means the source did not expose that metric in this read-only snapshot. It is not a zero.

### Interpretation and implementation focus

Sheepshead is a tiny but nonzero product: 6 ASC first-time downloads, 2 ASC in-app purchases, 12 RevenueCat new customers, and 1 active trial. No current active subscription or RevenueCat revenue is visible. Do not select a paywall winner from this sample. Confirm the release state and let a mature cohort establish whether the free game loop creates enough value to justify the offer.

The deterministic classifier recommends: Protect the current paid path, then use release and cohort baselines to decide whether acquisition or conversion is the next constraint.

- Join ASC first-time download, first launch, first value, paywall shown, offer loaded, trial started, trial canceled, trial converted, entitlement active, restore, and purchase failure events with the app version and build.
- Keep ASC's 90-day acquisition and proceeds window separate from RevenueCat's 28-day customer and revenue window. Do not calculate a conversion rate by dividing values from different windows.
- Use a mature trial cohort and a minimum sample before choosing a native paywall or onboarding A/B winner. Record the offering identifier, package, placement, experiment variant, and build.
- Put the app's classification and the next baseline date in the release handoff so Cursor, Claude, and Codex do not optimize from an old qualitative audit.

### Boundary on success or death

This snapshot supports the label **low-scale monetizing**, not a lifetime verdict. The app has current paid activity, but ASC does not expose a positive comparison for the selected window. A later decision should include a clean 28-day RevenueCat trend, ASC acquisition and conversion trend, ratings and review count, crash and hang evidence, and a release-specific cohort.
This dated section supersedes earlier statements in this file that per-app ASC or RevenueCat activity was unavailable as of 2026-08-23. Earlier statements remain historical evidence boundaries for their original audit pass.
