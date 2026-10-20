---
paths:
  - "Shared/Services/SubscriptionService.swift"
  - "Shared/Services/ProgressStore.swift"
  - "Shared/Services/WhatsNew.swift"
  - "Sheepshead/Views/OnboardingView.swift"
  - "Sheepshead/Views/PaywallView.swift"
  - "Sheepshead/Views/HowToPlayView.swift"
  - "Sheepshead/Views/FeatureTourView.swift"
  - "SheepsheadTests/TrialCopyTests.swift"
  - "SheepsheadTests/PaywallFunnelTests.swift"
---

# Sheepshead Trainer: membership, the trial flow and fit

Sheepshead+ (entitlements `Sheepshead+` and `pro`, any active one unlocks). Prices
are read live from StoreKit through RevenueCat (`PaywallPricing`); never
hardcode one anywhere. An unresolved product shows "Loading price…" and the
disclosure drops the amount.

**Trial flow, structurally Mahj 1.3.2.** Onboarding trial page: soft "Get
Started" exit above the primary, primary CTA in the exact Continue slot, one
tap buys the MONTHLY trial, Apple confirms. The page title stays "Try Sheepshead+
free" (as shipped). The billed amount is the most prominent price (22pt
display, 3.1.2(c)) with the small disclosure under it; the paywall footer keeps
the same 22pt line. `trialDisclosure` uses `PaywallPricing.terms` ("7 days
free, then $X/month. Auto-renews until canceled.") and must always name the
plan the CTA buys (`onboardingPlan`). Backing out of Apple's sheet is
`PurchaseOutcome.cancelled`, never an error and never another paywall. A member
reaching the trial page (reinstall, second device) sees Continue and goes
straight to the tour; Restore sits in the trial page's legal row. The trial end
date is not shown anywhere; Settings shows Manage Subscription only when there
is an expiration date (not for lifetime). Only the button wording varies, via
`TrialCTA` offering metadata; any other change to this flow needs Jack's
go-ahead. The paywall CTA stays disabled until StoreKit returns a price, which
includes every simulator run (RevenueCat is never configured there).

**Membership state.** `membershipResolved` is false until a customer record
was read (cache or network); nothing may treat "not a member" as a lapse or
sell a trial before it. A reinstall is a new anonymous RevenueCat user:
`recoverReinstalledMembershipIfNeeded` syncs once per install when StoreKit
owns an entitlement, and `ensureOfferings` (so every purchase) waits for it (3s
cap). `startedTrial` comes from the purchased entitlement's `periodType`, not
the product. `confirmEntitlement` fetches a fresh record. Simulators keep the
early return in `configureIfNeeded`: never configure the production `appl_`
key there.

**Fit.** Every fix is conditional on fit or text size, never on device. At
accessibility sizes the onboarding pages, the primer and the tour put the page
in a ScrollView with the buttons pinned below; the trial page scrolls and
carries its price, Get Started and legal row inside the page; Home and the room
grid drop to one column, the Sheepshead+ badge stacks under the title and the
room icon tile hides; the training tiles become a full-width column. Below
accessibility sizes the trial page keeps the designed layout. The primer's hand
row takes the largest of 46/40/36/32pt that fits. Home's header stacks the
chips under the title on compact widths (no gear collision), and the toolbar
keeps its system background. Dark mode uses `Theme.onFill` on filled buttons
and `Theme.goldText` for small gold text. `Theme.display` scales with Dynamic
Type, capped at 1.6x. Home shows `currentStreak()`, which drops to 0 after a
missed day instead of holding the last count.

**What's New mechanics.** `WhatsNew.currentRelease` is the newest entry at or
below the running version, so a build with no entry of its own still carries
the last notes once to a player who skipped a version. It is marked seen when
shown, and `shownThisLaunch` delays ATT to the next launch. One entry per
version: add lines to the existing entry rather than a second one. The 1.3.0
entry repeats the 1.2.4 lines under the weekly-gain line, so a player
updating from 1.2.3 or earlier still hears about them.
