package com.jackwallner.sheepshead

import com.jackwallner.sheepshead.content.DrillLibrary
import com.jackwallner.sheepshead.content.HowToPlayContent
import com.jackwallner.sheepshead.model.DrillKind
import com.jackwallner.sheepshead.model.PlayingCard
import com.jackwallner.sheepshead.model.SheepsheadRules
import com.jackwallner.sheepshead.model.Suit
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RulesAuditTest {
    private fun card(code: String): PlayingCard = PlayingCard.Standard(code.drop(1).toInt(),
        mapOf('C' to Suit.CLUBS, 'D' to Suit.DIAMONDS, 'H' to Suit.HEARTS, 'S' to Suit.SPADES).getValue(code.first()))
    private fun reference() = JSONObject(javaClass.getResourceAsStream("/rules-reference.json")!!.bufferedReader().readText())
    @Test fun everyCardValueAndFullTrumpOrder() {
        val deck = PlayingCard.sheepsheadDeck
        assertEquals(32, deck.toSet().size)
        assertEquals(14, deck.count { it.isTrump })
        assertEquals(18, deck.count { it.isFail })
        assertEquals(120, deck.sumOf { it.pointValue })
        for ((rank, points) in listOf(7 to 0, 8 to 0, 9 to 0, 10 to 10, 11 to 2, 12 to 3, 13 to 4, 14 to 11))
            for (suit in Suit.entries) assertEquals(points, PlayingCard.Standard(rank, suit).pointValue)
        assertEquals(reference().getJSONArray("order").strings().map(::card), deck.filter { it.isTrump }.sortedByDescending { it.trumpStrength })
        for (suit in listOf(Suit.CLUBS, Suit.HEARTS, Suit.SPADES)) {
            val fail = listOf(14, 10, 13, 9, 8, 7).map { PlayingCard.Standard(it, suit) }
            assertEquals(fail, fail.sortedByDescending { it.failStrength })
        }
    }
    @Test fun followingAndCalledAceReservation() {
        val quizzes = DrillLibrary.rooms.flatMap { it.drills }.flatMap { (it.kind as? DrillKind.Quiz)?.questions.orEmpty() }.associateBy { it.id }
        for (r in reference().getJSONArray("legal").objects()) {
            val hand = r.getJSONArray("hand").strings().map(::card)
            val led = if (r.isNull("led")) null else card(r.getString("led"))
            val call = if (r.isNull("calledSuit")) null else Suit.fromRaw(r.getString("calledSuit"))
            assertEquals(r.getString("id"), r.getJSONArray("expected").strings().map(::card),
                SheepsheadRules.legal(hand, led, call, r.getBoolean("isPicker"), r.getBoolean("opened"), r.optInt("calledRank", 14)))
            quizzes[r.getString("id")]?.let { assertEquals(hand, it.tiles); assertEquals(0, it.answerIndex) }
        }
    }
    @Test fun callingCannotUseAceFromHandBlindOrBury() {
        for (r in reference().getJSONArray("calls").objects()) assertEquals(r.getJSONArray("expected").strings().map(Suit::fromRaw),
            SheepsheadRules.callableSuits(r.getJSONArray("deal").strings().map(::card), r.getJSONArray("bury").strings().map(::card)))
        for (r in reference().getJSONArray("tenCalls").objects()) assertEquals(r.getJSONArray("expected").strings().map(Suit::fromRaw),
            SheepsheadRules.callableTenSuits(r.getJSONArray("deal").strings().map(::card), r.getJSONArray("bury").strings().map(::card)))
    }
    @Test fun trickWinnersAndSixtySixtyLoss() {
        for (r in reference().getJSONArray("tricks").objects()) assertEquals(r.getInt("winner"), SheepsheadRules.winner(r.getJSONArray("cards").strings().map(::card)))
        for ((points, bury, won) in listOf(Triple(49, listOf(card("C14"), card("H7")), false), Triple(50, listOf(card("C14"), card("H7")), true),
            Triple(60, listOf(card("C7"), card("H8")), false), Triple(61, listOf(card("C7"), card("H8")), true)))
            assertEquals(won, SheepsheadRules.pickerWins(points, bury))
    }
    @Test fun buryLegalityIsSeparateFromTheGradedStrategy() {
        val deal = listOf("C12", "S12", "D7", "D8", "H14", "H7", "S10", "S9").map(::card)
        for (bury in listOf(listOf("C12", "D7"), listOf("H14", "H7"), listOf("D7", "D8"))) assertTrue(SheepsheadRules.canBury(bury.map(::card), deal))
        for (bury in listOf(listOf("C12"), listOf("H14", "H14"), listOf("H14", "C7"))) assertFalse(SheepsheadRules.canBury(bury.map(::card), deal))
        val drills = DrillLibrary.rooms.flatMap { it.drills }
        val basics = drills.flatMap { (it.kind as? DrillKind.Flashcards)?.cards.orEmpty() }
        assertTrue(basics.first { it.id == "cards-goal" }.backBody.contains("plus the two buried cards"))
        for (s in drills.flatMap { (it.kind as? DrillKind.Discard)?.scenarios.orEmpty() }) {
            assertTrue(s.situation.contains("For this drill"))
            assertTrue(SheepsheadRules.canBury(s.recommendedDiscard, s.deal))
            s.calledSuit?.let { assertTrue(it in SheepsheadRules.callableSuits(s.deal, s.recommendedDiscard)) }
        }
        assertTrue(HowToPlayContent.pages[0].body.contains("no under calls or called tens"))
        assertTrue(HowToPlayContent.pages.first { it.id == "sheep-tricks" }.body.contains("including trump"))
        val cards = drills.flatMap { (it.kind as? DrillKind.Flashcards)?.cards.orEmpty() }
        assertTrue(cards.first { it.id == "bury-no-trump" }.backBody.contains("Burying trump is legal"))
    }
}
