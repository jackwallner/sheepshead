package com.jackwallner.sheepshead.data

import java.time.Duration
import java.time.Instant

/**
 * Whether a customer record is a fresh "not a member", the only thing that may
 * tear down a member feature (the game night reminder).
 *
 * The record read from RevenueCat's on-device cache at launch can be days old
 * and cannot tell an expiry from a renewal since: a member whose plan renewed
 * or whose trial converted while the app was closed reads inactive until the
 * network answers. A record counts only when it was answered after that launch
 * cache (so by the network, whatever the device clock says) or within
 * `FRESH_BASELINE_AGE` of now.
 */
object MembershipFreshness {
    val FRESH_BASELINE_AGE: Duration = Duration.ofMinutes(5)

    fun confirmsNoMembership(
        isActive: Boolean,
        answeredAt: Instant,
        launchCacheAnsweredAt: Instant,
        now: Instant = Instant.now(),
    ): Boolean {
        if (isActive) return false
        return answeredAt.isAfter(launchCacheAnsweredAt) ||
            Duration.between(answeredAt, now).abs() <= FRESH_BASELINE_AGE
    }
}
