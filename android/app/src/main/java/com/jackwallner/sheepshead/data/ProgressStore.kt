package com.jackwallner.sheepshead.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.jackwallner.sheepshead.model.Room
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import org.json.JSONObject

/** Streaks, drill completions, and the flat seen/missed sets behind the daily mix. */
class ProgressStore(private val defaults: KeyValueStore, private val clock: AppClock) {
    var streakCount by mutableStateOf(defaults.getInt(Keys.STREAK_COUNT))
        private set
    var totalSessions by mutableStateOf(defaults.getInt(Keys.TOTAL_SESSIONS))
        private set
    var completions by mutableStateOf(loadCompletions())
        private set
    var seenItems by mutableStateOf(defaults.getStringSet(Keys.SEEN_ITEMS))
        private set
    var missedItems by mutableStateOf(defaults.getStringSet(Keys.MISSED_ITEMS))
        private set

    /** The last day a drill was finished, as a `yyyy-MM-dd` key. State, so a streak shown on screen follows it. */
    var lastActiveDay by mutableStateOf(defaults.getString(Keys.LAST_ACTIVE_DAY))
        private set

    /** Root branches onboarding vs Home on this, so it is observable. */
    var hasOnboarded by mutableStateOf(defaults.getBoolean(Keys.HAS_ONBOARDED))
        private set

    /** Bumps whenever the day-based state may have moved, so Home recomposes. */
    var quickSessionDay by mutableStateOf(defaults.getString(Keys.LAST_QUICK_SESSION_DAY))
        private set

    fun setOnboarded(value: Boolean) {
        hasOnboarded = value
        defaults.putBoolean(Keys.HAS_ONBOARDED, value)
    }

    fun completions(drillID: String): Int = completions[drillID] ?: 0

    fun roomProgress(room: Room): Double {
        if (room.drills.isEmpty()) return 0.0
        return room.drills.count { completions(it.id) > 0 }.toDouble() / room.drills.size
    }

    fun recordSession(drillID: String) {
        completions = completions + (drillID to completions(drillID) + 1)
        totalSessions += 1
        bumpStreak()
        defaults.putString(Keys.COMPLETIONS, JSONObject(completions as Map<*, *>).toString())
        defaults.putInt(Keys.TOTAL_SESSIONS, totalSessions)
    }

    /**
     * The streak as it stands on `today`. `streakCount` only changes when a
     * drill is finished, so after a missed day it still holds the old number
     * and Home would show a streak the player has already lost.
     */
    fun currentStreak(today: LocalDate = clock.today()): Int {
        val last = lastActiveDay ?: return streakCount
        val gap = days(last, today.toString()) ?: 0
        return if (gap > 1) 0 else streakCount
    }

    /**
     * Consecutive calendar days with at least one finished drill. Days are
     * stored as `yyyy-MM-dd` keys, the date the phone showed then, so a
     * time-zone change never moves them.
     */
    private fun bumpStreak() {
        val today = clock.today().toString()
        val last = lastActiveDay
        if (last != null) {
            val gap = days(last, today) ?: 0
            when {
                gap == 1L -> streakCount += 1
                gap > 1L -> streakCount = 1
                // The clock went backwards (travel, a manual change). Keep the
                // later day so the streak is not counted twice on the way back.
                gap < 0L -> return
            }
        } else {
            streakCount = 1
        }
        lastActiveDay = today
        defaults.putString(Keys.LAST_ACTIVE_DAY, today)
        defaults.putInt(Keys.STREAK_COUNT, streakCount)
    }

    /** Anything answered wrong comes back first; unseen items come next. */
    fun recordItem(id: String, correct: Boolean) {
        seenItems = seenItems + id
        missedItems = if (correct) missedItems - id else missedItems + id
        persistItems()
    }

    data class ItemSnapshot(val id: String, val seen: Boolean, val missed: Boolean)

    fun snapshotItem(id: String) = ItemSnapshot(id, id in seenItems, id in missedItems)

    fun restoreItem(snapshot: ItemSnapshot) {
        seenItems = if (snapshot.seen) seenItems + snapshot.id else seenItems - snapshot.id
        missedItems = if (snapshot.missed) missedItems + snapshot.id else missedItems - snapshot.id
        persistItems()
    }

    private fun persistItems() {
        defaults.putStringSet(Keys.SEEN_ITEMS, seenItems)
        defaults.putStringSet(Keys.MISSED_ITEMS, missedItems)
    }

    /** Get Started is once a day: a fresh mix each day, resting once today's is done. */
    fun quickSessionCompletedToday(today: LocalDate = clock.today()): Boolean = quickSessionDay == today.toString()

    fun markQuickSessionCompleted() {
        quickSessionDay = clock.today().toString()
        defaults.putString(Keys.LAST_QUICK_SESSION_DAY, quickSessionDay!!)
    }

    /** Clears every practice stat. Leaves onboarding and purchases alone. */
    fun resetAll() {
        streakCount = 0
        lastActiveDay = null
        totalSessions = 0
        completions = emptyMap()
        seenItems = emptySet()
        missedItems = emptySet()
        quickSessionDay = null
        listOf(
            Keys.STREAK_COUNT, Keys.LAST_ACTIVE_DAY, Keys.TOTAL_SESSIONS, Keys.COMPLETIONS,
            Keys.SEEN_ITEMS, Keys.MISSED_ITEMS, Keys.REVIEW_GATE_SHOWN, Keys.LAST_QUICK_SESSION_DAY,
        ).forEach(defaults::remove)
    }

    private fun loadCompletions(): Map<String, Int> {
        val raw = defaults.getString(Keys.COMPLETIONS) ?: return emptyMap()
        val json = runCatching { JSONObject(raw) }.getOrNull() ?: return emptyMap()
        return json.keys().asSequence().associateWith { json.getInt(it) }
    }

    companion object {
        /** Whole days from one stored day key to another, whatever the zone; null if either is unreadable. */
        fun days(start: String, end: String): Long? {
            val from = runCatching { LocalDate.parse(start) }.getOrNull() ?: return null
            val to = runCatching { LocalDate.parse(end) }.getOrNull() ?: return null
            return ChronoUnit.DAYS.between(from, to)
        }
    }

    private object Keys {
        const val STREAK_COUNT = "progress.streakCount"
        const val LAST_ACTIVE_DAY = "progress.lastActiveDay"
        const val TOTAL_SESSIONS = "progress.totalSessions"
        const val COMPLETIONS = "progress.completions"
        const val HAS_ONBOARDED = "progress.hasOnboarded"
        const val REVIEW_GATE_SHOWN = "progress.reviewGateShown"
        const val SEEN_ITEMS = "progress.seenItems"
        const val MISSED_ITEMS = "progress.missedItems"
        const val LAST_QUICK_SESSION_DAY = "progress.lastQuickSessionDay"
    }
}
