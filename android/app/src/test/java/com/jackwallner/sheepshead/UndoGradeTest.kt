package com.jackwallner.sheepshead

import com.jackwallner.sheepshead.data.AnswerSnapshot
import com.jackwallner.sheepshead.data.AppClock
import com.jackwallner.sheepshead.data.InMemoryStore
import com.jackwallner.sheepshead.data.PracticeRecordStore
import com.jackwallner.sheepshead.data.ProgressStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Ports of the iOS flashcard Undo tests (`PracticeRecordStoreTests`, `ProgressStoreTests`). */
class UndoGradeTest {
    private val defaults = InMemoryStore()
    private val clock = AppClock()

    private val records get() = PracticeRecordStore(defaults, clock)

    /** Undo put the card back but left its grade: an undone mistap stayed a miss due for review. */
    @Test
    fun undoingAMissLeavesNoMissBehind() {
        val progress = ProgressStore(defaults, clock)
        val records = records
        val snapshot = AnswerSnapshot.take(progress, records, "card-1")
        progress.recordItem("card-1", correct = false)
        records.record("card-1", "card-room", correct = false)
        assertTrue("card-1" in progress.missedItems)

        snapshot.restore(progress, records)

        assertFalse("card-1" in progress.missedItems)
        assertFalse("card-1" in progress.seenItems)
        assertNull(records.records["card-1"])
        assertEquals(0, records.totalAttempts)
        val reloaded = PracticeRecordStore(defaults, clock)
        assertNull("the undo is stored", reloaded.records["card-1"])
        assertFalse("card-1" in ProgressStore(defaults, clock).missedItems)
    }

    /** An undone correct answer counted twice toward "locked in" once it was answered again. */
    @Test
    fun anUndoneCorrectAnswerCountsOnce() {
        val progress = ProgressStore(defaults, clock)
        val records = records
        val snapshot = AnswerSnapshot.take(progress, records, "card-1")
        progress.recordItem("card-1", correct = true)
        records.record("card-1", "card-room", correct = true)
        snapshot.restore(progress, records)
        progress.recordItem("card-1", correct = true)
        records.record("card-1", "card-room", correct = true)
        assertEquals(1, records.records["card-1"]!!.attempts)
        assertEquals(1, records.records["card-1"]!!.streak)
    }

    /** A card that was already graded once keeps that earlier row when the second grade is undone. */
    @Test
    fun undoRestoresThePreviousRowNotAnEmptyOne() {
        val progress = ProgressStore(defaults, clock)
        val records = records
        progress.recordItem("card-1", correct = false)
        records.record("card-1", "card-room", correct = false)
        val before = records.records["card-1"]

        val snapshot = AnswerSnapshot.take(progress, records, "card-1")
        progress.recordItem("card-1", correct = true)
        records.record("card-1", "card-room", correct = true)
        snapshot.restore(progress, records)

        assertEquals(before, records.records["card-1"])
        assertTrue("the earlier miss is still a miss", "card-1" in progress.missedItems)
    }

    /** Generated items collapse onto one row per skill; the snapshot reads and restores that row. */
    @Test
    fun undoUsesTheRowAnItemIdMapsTo() {
        val progress = ProgressStore(defaults, clock)
        val records = records
        val id = "gen-handReading-ABC"
        val snapshot = AnswerSnapshot.take(progress, records, id)
        records.record(id, "trump-room", correct = true)
        assertEquals(1, records.records["handReading"]!!.attempts)
        snapshot.restore(progress, records)
        assertNull(records.records["handReading"])
    }
}
