package com.jackwallner.sheepshead

import com.jackwallner.sheepshead.content.SheepsheadMinuteCategory
import com.jackwallner.sheepshead.content.SheepsheadMinuteContent
import com.jackwallner.sheepshead.content.DrillLibrary
import com.jackwallner.sheepshead.content.EndlessPractice
import com.jackwallner.sheepshead.content.HandGenerator
import com.jackwallner.sheepshead.content.PracticeSkill
import com.jackwallner.sheepshead.content.QuickItem
import com.jackwallner.sheepshead.content.SessionBuilder
import com.jackwallner.sheepshead.model.ChoiceShuffle
import com.jackwallner.sheepshead.model.DrillKind
import com.jackwallner.sheepshead.model.HandCategory.FAIL_SUIT
import com.jackwallner.sheepshead.model.HandCategory.LOW_CARDS
import com.jackwallner.sheepshead.model.HandCategory.POINT_CARDS
import com.jackwallner.sheepshead.model.HandCategory.TRUMP_STACK
import com.jackwallner.sheepshead.model.racked
import com.jackwallner.sheepshead.model.PlayingCard
import com.jackwallner.sheepshead.model.PlayingCard.Companion.c
import com.jackwallner.sheepshead.model.PlayingCard.Companion.d
import com.jackwallner.sheepshead.model.PlayingCard.Companion.h
import com.jackwallner.sheepshead.model.PlayingCard.Companion.s
import com.jackwallner.sheepshead.model.StableSeededGenerator
import java.time.LocalDate
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Holds the Kotlin generators to the iOS output, plus ports of iOS
 * `HandGeneratorTests` and `SheepsheadMinuteContentTests`. The shared daily
 * challenge has to deal the same cards on both platforms.
 */
class GeneratorParityTest {
    private val parity = ParityFixtures.json

    private fun assertItem(label: String, expected: JSONObject, actual: QuickItem) {
        assertEquals(label, expected.getString("id"), actual.id)
        assertEquals(label, expected.getString("prompt"), actual.prompt)
        assertEquals(label, expected.getJSONArray("tiles").strings(), codes(actual.tiles))
        assertEquals(label, expected.getJSONArray("choices").strings(), actual.choices)
        assertEquals(label, expected.getInt("answerIndex"), actual.answerIndex)
        assertEquals(label, expected.getString("explanation"), actual.explanation)
        assertEquals(label, expected.getString("sourceLabel"), actual.sourceLabel)
        assertEquals(label, expected.getString("roomID"), actual.roomID)
        assertEquals(label, expected.getString("trackingID"), actual.trackingID)
        assertEquals(label, expected.getBoolean("isReviewable"), actual.isReviewable)
    }

    @Test
    fun seededStreamMatchesSwift() {
        val streams = parity.getJSONObject("streams")
        for (seed in streams.keys()) {
            val generator = StableSeededGenerator(seed)
            assertEquals("seed '$seed'", streams.getJSONArray(seed).strings(), (0 until 8).map { generator.next().toString() })
        }
    }

    @Test
    fun permutationsMatchSwift() {
        val permutations = parity.getJSONObject("permutations")
        for (key in permutations.keys()) {
            val (seed, count) = key.split("|")
            assertEquals(key, permutations.getJSONArray(key).ints(), ChoiceShuffle.permutation(count.toInt(), seed))
        }
    }

    @Test
    fun handBatchesMatchSwift() {
        val hands = parity.getJSONObject("hands")
        for (seed in hands.keys()) {
            val expected = hands.getJSONArray(seed).objects()
            val actual = HandGenerator.batch(7, seed)
            assertEquals(seed, expected.size, actual.size)
            expected.zip(actual).forEachIndexed { index, (json, hand) ->
                val label = "$seed #$index"
                assertEquals(label, json.getJSONArray("tiles").strings(), codes(hand.tiles))
                assertEquals(label, json.getString("answer"), hand.answer.raw)
                assertEquals(label, json.getJSONArray("choices").strings(), hand.choices.map { it.raw })
                assertEquals(label, json.getString("explanation"), hand.explanation)
            }
        }
    }

    @Test
    fun sheepsheadMinuteMatchesSwift() {
        val minutes = parity.getJSONObject("minutes")
        for (day in minutes.keys()) {
            val expected = minutes.getJSONObject(day)
            val challenge = SheepsheadMinuteContent.challenge(LocalDate.parse(day))
            assertEquals(day, expected.getString("shortDate"), challenge.shortDate)
            val questions = expected.getJSONArray("questions").objects()
            assertEquals(day, questions.size, challenge.questions.size)
            questions.zip(challenge.questions).forEachIndexed { index, (json, question) ->
                assertEquals("$day #$index", json.getString("category"), question.category.raw)
                assertItem("$day #$index", json.getJSONObject("item"), question.item)
            }
        }
    }

    @Test
    fun preparedChoicePoolMatchesSwift() {
        val expected = parity.getJSONArray("memberPool").objects()
        val actual = DrillLibrary.rooms.flatMap { SessionBuilder.choiceItems(it.id, includePro = true) }.map(SessionBuilder::prepared)
        assertEquals(expected.size, actual.size)
        expected.zip(actual).forEach { (json, item) -> assertItem(item.id, json, item) }
    }

    @Test
    fun cardFactsMatchSwift() {
        val cards = parity.getJSONArray("cards").objects()
        assertEquals(32, cards.size)
        assertEquals(cards.map { it.getString("code") }, codes(PlayingCard.sheepsheadDeck))
        for ((json, card) in cards.zip(PlayingCard.sheepsheadDeck)) {
            val label = card.code
            assertEquals(label, json.getBoolean("isTrump"), card.isTrump)
            assertEquals(label, json.getBoolean("isFail"), card.isFail)
            assertEquals(label, json.getBoolean("isFailAce"), card.isFailAce)
            assertEquals(label, json.getInt("pointValue"), card.pointValue)
            assertEquals(label, json.getInt("trumpStrength"), card.trumpStrength)
            assertEquals(label, json.getInt("failStrength"), card.failStrength)
            assertEquals(label, json.getInt("sortKey"), card.sortKey)
            assertEquals(label, json.getString("shortLabel"), card.shortLabel)
            assertEquals(label, json.getString("spokenName"), card.spokenName)
        }
        assertEquals(120, PlayingCard.sheepsheadDeck.sumOf { it.pointValue })
        assertEquals(14, PlayingCard.sheepsheadDeck.count { it.isTrump })
    }

    @Test
    fun holdingReadsMatchSwift() {
        val reads = parity.getJSONArray("reads").objects()
        assertEquals(300, reads.size)
        for (json in reads) {
            val cards = json.getJSONArray("cards").cards()
            val label = codes(cards).toString()
            assertEquals(label, if (json.isNull("category")) null else json.getString("category"), HandGenerator.category(cards)?.raw)
            assertEquals(label, json.getJSONArray("fits").strings(), HandGenerator.generatableCategories.filter { HandGenerator.fits(cards, it) }.map { it.raw })
            assertEquals(label, json.getJSONArray("racked").strings(), codes(cards.racked))
        }
    }

    // MARK: - iOS HandGeneratorTests

    @Test
    fun readsATrumpStack() {
        assertEquals(TRUMP_STACK, HandGenerator.category(listOf(c(12), s(11), d(14), d(9), h(12))))
    }

    @Test
    fun readsAFailSuit() {
        val cards = listOf(c(14), c(10), c(13), c(9), c(7))
        assertEquals(FAIL_SUIT, HandGenerator.category(cards))
        assertFalse(HandGenerator.fits(cards, TRUMP_STACK))
    }

    @Test
    fun readsPointCards() {
        assertEquals(POINT_CARDS, HandGenerator.category(listOf(c(14), d(10), h(13), s(14), c(10))))
    }

    @Test
    fun readsLowCards() {
        assertEquals(LOW_CARDS, HandGenerator.category(listOf(c(7), h(8), s(9), c(8), h(7))))
    }

    @Test
    fun generatedHandsAreLegalAndUnambiguous() {
        val deck = PlayingCard.sheepsheadDeck.toSet()
        for (target in HandGenerator.generatableCategories) {
            repeat(20) {
                val hand = HandGenerator.hand(target)
                assertNotNull("Could not deal ${target.raw}", hand)
                hand!!
                val shown = codes(hand.tiles).toString()
                assertEquals(shown, 5, hand.tiles.size)
                assertEquals(shown, 5, hand.tiles.toSet().size)
                assertTrue(shown, deck.containsAll(hand.tiles))
                assertEquals(shown, target, HandGenerator.category(hand.tiles))
                assertTrue(shown, target in hand.choices)
                assertTrue(shown, hand.choices.size >= 3)
                assertEquals(shown, hand.choices.size, hand.choices.toSet().size)
                for (choice in hand.choices.filter { it != target }) assertFalse(shown, HandGenerator.fits(hand.tiles, choice))
                assertTrue(hand.explanation.isNotEmpty() && "\u2014" !in hand.explanation)
            }
        }
    }

    @Test
    fun batchCoversEverySkill() {
        val hands = HandGenerator.batch(60)
        assertTrue(hands.size > 40)
        assertEquals(HandGenerator.generatableCategories.toSet(), hands.map { it.answer }.toSet())
    }

    @Test
    fun endlessItemsAreWellFormed() {
        for (skill in PracticeSkill.entries) {
            val items = EndlessPractice.items(skill, 12)
            assertEquals(12, items.size)
            for (item in items) {
                assertTrue(item.id.startsWith(skill.itemPrefix))
                assertEquals(skill, PracticeSkill.skill(item.id))
                assertTrue(item.choices.size >= 3)
                assertTrue(item.answerIndex in item.choices.indices)
                assertEquals(item.choices.size, item.choices.toSet().size)
                assertTrue(item.explanation.isNotEmpty())
                assertNotNull(DrillLibrary.room(item.roomID))
            }
        }
    }

    @Test
    fun trumpItemsUseLegalCards() {
        val deck = PlayingCard.sheepsheadDeck.toSet()
        for (item in EndlessPractice.items(PracticeSkill.TRICK_PLAY, 40)) {
            val card = item.tiles.first()
            assertTrue(card in deck)
            assertTrue("classify" in item.prompt)
            assertEquals(if (card.isTrump) 0 else 1, item.answerIndex)
        }
    }

    @Test
    fun mixedItemsDrawFromEverySkill() {
        val items = EndlessPractice.mixedItems(40)
        assertEquals(40, items.size)
        assertEquals(PracticeSkill.entries.toSet(), items.mapNotNull { PracticeSkill.skill(it.id) }.toSet())
    }

    // MARK: - iOS SheepsheadMinuteContentTests

    @Test
    fun challengeIsStableAndHasTheFiveQuestionMix() {
        val day = LocalDate.of(2026, 8, 9)
        val first = SheepsheadMinuteContent.challenge(day)
        val second = SheepsheadMinuteContent.challenge(day)
        assertEquals("2026-08-09", first.dayKey)
        assertEquals(first.items, second.items)
        val counts = first.questions.groupingBy { it.category }.eachCount()
        assertEquals(SheepsheadMinuteContent.QUESTION_COUNT, first.questions.size)
        assertEquals(2, counts[SheepsheadMinuteCategory.HAND_READING])
        assertEquals(1, counts[SheepsheadMinuteCategory.BURYING])
        assertEquals(2, counts[SheepsheadMinuteCategory.TRICK_PLAY])
        for (question in first.questions) {
            val item = question.item
            assertTrue(item.choices.size >= 2)
            assertTrue(item.answerIndex in item.choices.indices)
            assertTrue(item.explanation.isNotEmpty() && "\u2014" !in item.explanation)
        }
        for (question in first.questions.filter { it.category == SheepsheadMinuteCategory.HAND_READING }) {
            assertFalse(question.item.isReviewable)
            assertEquals(PracticeSkill.HAND_READING.raw, question.item.trackingID)
        }
    }

    /** A day that fails to deal fails for every player at once, so sweep five years of day keys. */
    @Test
    fun everyDaySeedDealsTheFullQuestionSet() {
        var day = LocalDate.of(2026, 1, 1)
        var checked = 0
        while (day.isBefore(LocalDate.of(2031, 1, 1))) {
            val key = SheepsheadMinuteContent.key(day)
            assertEquals(key, 2, HandGenerator.batch(2, "sheepshead-minute-$key-hands").size)
            checked += 1
            day = day.plusDays(1)
        }
        assertTrue(checked > 1800)
    }

    /**
     * A bury choice is two cards, so "7 of Hearts, K of Spades" and "K of Spades, 7 of Hearts" are
     * one answer. plus-bury-3 is authored against its deal order, which put the right pair on screen
     * twice with one copy graded wrong. Compare the cards, not the strings.
     */
    @Test
    fun buryChoicesOfferTheRecommendedPairExactlyOnce() {
        val scenarios = DrillLibrary.rooms.flatMap { room ->
            room.drills.flatMap { (it.kind as? DrillKind.Discard)?.scenarios ?: emptyList() }
        }
        fun cards(label: String) = label.split(", ").toSet()
        var day = LocalDate.of(2026, 1, 1)
        var checked = 0
        while (day.isBefore(LocalDate.of(2031, 1, 1))) {
            val challenge = SheepsheadMinuteContent.challenge(day)
            val item = challenge.questions.first { it.category == SheepsheadMinuteCategory.BURYING }.item
            val scenario = scenarios.first { it.deal == item.tiles }
            val answer = scenario.recommendedDiscard.map { it.spokenName }.toSet()
            val copies = item.choices.count { cards(it) == answer }
            assertEquals("${challenge.dayKey} (${scenario.id}) lists the recommended pair $copies times: ${item.choices}", 1, copies)
            assertEquals(
                "${challenge.dayKey} (${scenario.id}) offers the same two cards twice: ${item.choices}",
                item.choices.size,
                item.choices.map(::cards).toSet().size,
            )
            assertEquals(answer, cards(item.choices[item.answerIndex]))
            checked += 1
            day = day.plusDays(1)
        }
        assertTrue(checked > 1800)
    }
}
