package com.jackwallner.sheepshead

import com.jackwallner.sheepshead.content.SheepsheadMinuteContent
import com.jackwallner.sheepshead.data.AppClock
import com.jackwallner.sheepshead.data.InMemoryStore
import com.jackwallner.sheepshead.data.ProgressStore
import com.jackwallner.sheepshead.data.SheepsheadMinuteStore
import java.time.Clock
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Ports of the iOS `TimeStateTests`: the streak, Get Started and the Minute week across zones and clock changes. */
class StreakTimeTest {
    private val defaults = InMemoryStore()
    private val clock = AppClock()
    private val la = ZoneId.of("America/Los_Angeles")

    /** The device clock showing `hour`:00 on `month`/`day` 2026 in `zone`. */
    private fun setNow(zone: ZoneId, month: Int, day: Int, hour: Int = 12, minute: Int = 0) {
        val instant = LocalDateTime.of(2026, month, day, hour, minute).atZone(zone).toInstant()
        clock.clock = Clock.fixed(instant, zone)
    }

    // MARK: - Streak and Get Started across time zones

    /** Days are stored as day keys, so a trip west does not move them, even a long one. */
    @Test
    fun storedDaysSurviveAWestwardZoneChange() {
        for (east in listOf("Asia/Tokyo", "Pacific/Auckland")) {
            val store = ProgressStore(InMemoryStore(), clock)
            setNow(ZoneId.of(east), 3, 10, hour = 20)
            store.recordSession("a")
            store.markQuickSessionCompleted()

            setNow(la, 3, 10, hour = 18)
            assertTrue("$east: still today's Get Started", store.quickSessionCompletedToday())
            store.recordSession("a")
            assertEquals("$east: March 10 counted twice", 1, store.streakCount)

            setNow(la, 3, 11, hour = 10)
            assertFalse(store.quickSessionCompletedToday())
            assertEquals(east, 1, store.currentStreak())
            store.recordSession("a")
            assertEquals(east, 2, store.streakCount)
            setNow(la, 3, 13, hour = 10)
            assertEquals("two missed days end the streak", 0, store.currentStreak())
        }
    }

    /** Spring forward (March 8) and fall back (November 1) in Los Angeles. */
    @Test
    fun streakCountsCalendarDaysAcrossDaylightSavingChanges() {
        val spring = ProgressStore(InMemoryStore(), clock)
        setNow(la, 3, 7, hour = 23, minute = 30)
        spring.recordSession("a")
        setNow(la, 3, 8, hour = 0, minute = 30)
        spring.recordSession("a")
        setNow(la, 3, 9, hour = 23, minute = 59)
        spring.recordSession("a")
        assertEquals(3, spring.streakCount)

        val fall = ProgressStore(InMemoryStore(), clock)
        setNow(la, 10, 31, hour = 23, minute = 30)
        fall.recordSession("a")
        setNow(la, 11, 1, hour = 1, minute = 30)
        fall.recordSession("a")
        setNow(la, 11, 1, hour = 23, minute = 30)
        fall.recordSession("a")
        assertEquals("the 25-hour day is still one day", 2, fall.streakCount)
        setNow(la, 11, 2, hour = 0, minute = 15)
        fall.recordSession("a")
        assertEquals(3, fall.streakCount)
    }

    /** Travel or a manual change sets the clock back: the later day stays, nothing counts twice. */
    @Test
    fun aClockSetBackDoesNotCountADayTwice() {
        val store = ProgressStore(defaults, clock)
        setNow(la, 3, 10)
        store.recordSession("a")
        setNow(la, 3, 11)
        store.recordSession("a")
        assertEquals(2, store.streakCount)

        setNow(la, 3, 10)
        store.recordSession("a")
        assertEquals("a day behind the last one changes nothing", 2, store.streakCount)
        setNow(la, 3, 11)
        store.recordSession("a")
        assertEquals("the way back is not a new day", 2, store.streakCount)
        setNow(la, 3, 12)
        store.recordSession("a")
        assertEquals(3, store.streakCount)
    }

    /** `streakCount` only moves when a drill ends, so Home reads the live number. */
    @Test
    fun currentStreakDropsAfterAMissedDay() {
        val store = ProgressStore(defaults, clock)
        assertEquals(0, store.currentStreak())
        setNow(la, 3, 10)
        store.recordSession("a")
        store.recordSession("a")
        setNow(la, 3, 11)
        store.recordSession("a")
        assertEquals(2, store.currentStreak())
        setNow(la, 3, 12)
        assertEquals("yesterday still holds the streak", 2, store.currentStreak())
        setNow(la, 3, 13)
        assertEquals("a missed day loses it", 0, store.currentStreak())
        assertEquals("the stored count is untouched until the next drill", 2, store.streakCount)
    }

    @Test
    fun getStartedRestsForOneCalendarDayInTheDeviceZone() {
        val store = ProgressStore(defaults, clock)
        setNow(la, 3, 10, hour = 23, minute = 59)
        store.markQuickSessionCompleted()
        assertTrue(store.quickSessionCompletedToday())
        assertTrue(store.quickSessionCompletedToday(LocalDate.of(2026, 3, 10)))
        // Home draws for a stored day, so a morning-after redraw sees the new one.
        assertFalse(store.quickSessionCompletedToday(LocalDate.of(2026, 3, 11)))
        setNow(la, 3, 11, hour = 0, minute = 1)
        assertFalse(store.quickSessionCompletedToday())
    }

    @Test
    fun dayGapsCrossMonthsAndYears() {
        assertEquals(1L, ProgressStore.days("2026-02-28", "2026-03-01"))
        assertEquals(1L, ProgressStore.days("2026-12-31", "2027-01-01"))
        assertEquals(-1L, ProgressStore.days("2026-03-11", "2026-03-10"))
        assertNull(ProgressStore.days("garbage", "2026-03-10"))
    }

    /** A damaged stored day must not crash a finished drill. */
    @Test
    fun anUnreadableStoredDayDoesNotCrash() {
        defaults.putString("progress.lastActiveDay", "garbage")
        defaults.putInt("progress.streakCount", 4)
        val store = ProgressStore(defaults, clock)
        setNow(la, 3, 10)
        assertEquals(4, store.currentStreak())
        store.recordSession("a")
        assertEquals(4, store.streakCount)
        setNow(la, 3, 11)
        store.recordSession("a")
        assertEquals(5, store.streakCount)
    }

    // MARK: - Sheepshead Minute week

    /** The week starts on the device locale's first day: Sunday in the US, Monday in France. */
    @Test
    fun minuteWeekStartsOnTheLocalesFirstWeekday() {
        val store = SheepsheadMinuteStore(defaults, clock)
        val sunday = LocalDate.of(2026, 3, 8)
        setNow(la, 3, 8)
        store.record(SheepsheadMinuteContent.challenge(sunday), List(5) { true })
        setNow(la, 3, 11)
        assertEquals("Sunday opens the week in the US", 1, store.completedThisWeek(Locale.US))
        assertEquals("Sunday closes the week in France", 0, store.completedThisWeek(Locale.FRANCE))
        assertEquals(DayOfWeek.SUNDAY, sunday.dayOfWeek)
    }
}
