package com.jackwallner.sheepshead

import com.jackwallner.sheepshead.data.AppSettings
import com.jackwallner.sheepshead.data.InMemoryStore
import com.jackwallner.sheepshead.data.MembershipFreshness
import com.jackwallner.sheepshead.data.ReminderScheduler
import java.time.DayOfWeek
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Ports of the iOS `GameNightReminderTests` and `ReminderPermissionTests`. */
class ReminderStateTest {
    private val defaults = InMemoryStore()

    // MARK: - Game night reminder only on a fresh lapse

    private val now: Instant = Instant.ofEpochSecond(1_800_000_000)
    private val day = 86_400L

    private fun confirms(active: Boolean, answeredAt: Instant, cache: Instant) =
        MembershipFreshness.confirmsNoMembership(active, answeredAt, cache, now)

    private class FakeScheduler : ReminderScheduler {
        val log = mutableListOf<String>()
        override fun scheduleDaily(hour: Int, minute: Int) { log += "daily" }
        override fun cancelDaily() { log += "cancelDaily" }
        override fun scheduleGameNight(day: DayOfWeek, hour: Int, minute: Int) { log += "gameNight" }
        override fun cancelGameNight() { log += "cancelGameNight" }
    }

    private fun settingsWithReminders(scheduler: ReminderScheduler? = null): AppSettings {
        defaults.putBoolean("settings.reminderEnabled", true)
        defaults.putBoolean("settings.gameNightReminderEnabled", true)
        return AppSettings(defaults, scheduler)
    }

    @Test
    fun aConfirmedLapseDropsTheGameNightReminder() {
        val scheduler = FakeScheduler()
        val settings = settingsWithReminders(scheduler)
        assertTrue("an existing reminder loads", settings.gameNightReminderEnabled)
        settings.dropGameNightReminderUnlessMember(lapseConfirmed = true)
        assertFalse(settings.gameNightReminderEnabled)
        assertFalse("the off is stored", AppSettings(defaults, null).gameNightReminderEnabled)
        assertEquals("the pending alarm is cancelled", listOf("cancelGameNight"), scheduler.log)
        assertTrue("the daily reminder is not member-only", settings.reminderEnabled)
    }

    @Test
    fun anUnconfirmedLapseKeepsTheReminder() {
        val settings = settingsWithReminders()
        settings.dropGameNightReminderUnlessMember(lapseConfirmed = false)
        assertTrue(settings.gameNightReminderEnabled)
    }

    /** A monthly member renews while closed and launches four days later: cache reads inactive, network active. */
    @Test
    fun aStaleInactiveCacheThenActiveKeepsARenewedMembersReminder() {
        val settings = settingsWithReminders()
        val cacheDate = now.minusSeconds(4 * day)
        val cached = confirms(active = false, answeredAt = cacheDate, cache = cacheDate)
        assertFalse("a four-day-old cached record is not a fresh answer", cached)
        settings.dropGameNightReminderUnlessMember(cached)
        settings.dropGameNightReminderUnlessMember(confirms(active = true, answeredAt = now, cache = cacheDate))
        assertTrue(settings.gameNightReminderEnabled)
        assertTrue(AppSettings(defaults, null).gameNightReminderEnabled)
    }

    /** The membership really ran out while closed: the network answer after the stale cache drops it. */
    @Test
    fun aStaleInactiveCacheThenNetworkInactiveDropsTheReminder() {
        val settings = settingsWithReminders()
        val cacheDate = now.minusSeconds(4 * day)
        settings.dropGameNightReminderUnlessMember(confirms(active = false, answeredAt = cacheDate, cache = cacheDate))
        assertTrue(settings.gameNightReminderEnabled)
        settings.dropGameNightReminderUnlessMember(confirms(active = false, answeredAt = now.minusSeconds(1), cache = cacheDate))
        assertFalse(settings.gameNightReminderEnabled)
    }

    @Test
    fun freshnessRules() {
        val cacheDate = now.minusSeconds(4 * day)
        assertFalse("a member is never a lapse", confirms(active = true, answeredAt = now, cache = Instant.MIN))
        assertTrue("no cache at launch: any record is a network answer", confirms(false, cacheDate, Instant.MIN))
        assertTrue(
            "newer than the launch cache is a network answer, even on a wrong clock",
            confirms(false, cacheDate.plusSeconds(60), cacheDate),
        )
        assertTrue("a cache answered a minute ago is still fresh", confirms(false, now.minusSeconds(60), now.minusSeconds(60)))
        assertFalse(
            "a clock running behind does not make an old cache fresh",
            confirms(false, now.plusSeconds(4 * day), now.plusSeconds(4 * day)),
        )
    }
}
