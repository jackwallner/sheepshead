package com.jackwallner.sheepshead

import com.jackwallner.sheepshead.content.SheepsheadContent
import com.jackwallner.sheepshead.content.DrillLibrary
import com.jackwallner.sheepshead.content.HandGenerator
import com.jackwallner.sheepshead.content.HowToPlayContent
import com.jackwallner.sheepshead.content.SessionBuilder
import com.jackwallner.sheepshead.model.DiscardScenario
import com.jackwallner.sheepshead.model.DrillKind
import com.jackwallner.sheepshead.model.Flashcard
import com.jackwallner.sheepshead.model.HandCategory
import com.jackwallner.sheepshead.model.HandMatchQuestion
import com.jackwallner.sheepshead.model.PlayingCard
import com.jackwallner.sheepshead.model.QuizQuestion
import com.jackwallner.sheepshead.model.Suit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Port of iOS `ContentValidityTests`, run against the exported content the app ships. */
class ContentTest {
    private val drills = DrillLibrary.rooms.flatMap { it.drills }
    private val handMatch: List<HandMatchQuestion> = drills.flatMap { (it.kind as? DrillKind.HandMatch)?.questions.orEmpty() }
    private val quiz: List<QuizQuestion> = drills.flatMap { (it.kind as? DrillKind.Quiz)?.questions.orEmpty() }
    private val discards: List<DiscardScenario> = drills.flatMap { (it.kind as? DrillKind.Discard)?.scenarios.orEmpty() }
    private val flashcards: List<Flashcard> = drills.flatMap { (it.kind as? DrillKind.Flashcards)?.cards.orEmpty() }

    @Test
    fun countsMatchIos() {
        val expected = ParityFixtures.json.getJSONObject("drillCounts")
        assertEquals(expected.length(), drills.size)
        for (drill in drills) assertEquals(drill.id, expected.getInt(drill.id), drill.kind.itemCount)
        assertEquals(listOf("card-room", "trump-room", "bury-room", "trick-room", "pro-tables"), DrillLibrary.rooms.map { it.id })
        assertEquals(ParityFixtures.json.getInt("lockedDrillCount"), DrillLibrary.rooms.sumOf { it.plusDrillCount })
        assertEquals(9, SheepsheadContent.library.categoryText.size)
        assertEquals(6, HowToPlayContent.pages.size)
    }

    @Test
    fun handMatchQuestionsShowFiveDistinctCards() {
        for (question in handMatch) {
            assertEquals(question.id, 5, question.tiles.size)
            assertEquals(question.id, 5, question.tiles.toSet().size)
        }
    }

    @Test
    fun handMatchAnswerIsAmongDistinctChoices() {
        for (question in handMatch) {
            assertTrue(question.id, question.answer in question.choices)
            assertEquals(question.id, question.choices.size, question.choices.toSet().size)
            assertTrue(question.id, question.choices.size >= 3)
        }
    }

    /** The four generatable shapes are decidable from the cards, so no distractor may also fit. */
    @Test
    fun handMatchDistractorsDoNotAlsoFitTheHolding() {
        for (question in handMatch) {
            for (choice in question.choices.filter { it != question.answer }) {
                assertFalse("${question.id} also fits ${choice.raw}", HandGenerator.fits(question.tiles, choice))
            }
            if (question.answer in HandGenerator.generatableCategories) {
                assertTrue("${question.id} does not fit ${question.answer.raw}", HandGenerator.fits(question.tiles, question.answer))
            }
        }
    }

    @Test
    fun buryHoldingsHaveEightCardsAndRecommendTwo() {
        for (scenario in discards) {
            assertEquals(scenario.id, 8, scenario.deal.size)
            assertEquals(scenario.id, 2, scenario.recommendedDiscard.size)
            assertEquals(scenario.id, 8, scenario.deal.toSet().size)
            assertTrue(scenario.id, scenario.deal.containsAll(scenario.recommendedDiscard))
        }
    }

    // MARK: - Bury rules

    private val failSuits = listOf(Suit.CLUBS, Suit.HEARTS, Suit.SPADES)

    /** Empty a fail suit if you can, then bank as many points as possible. */
    private fun buryScore(deal: List<PlayingCard>, bury: List<PlayingCard>): Pair<Int, Int> {
        val keptFail = deal.filter { it.isFail && it !in bury }
        val emptied = failSuits.count { suit ->
            bury.any { it.isFail && it.suit == suit } && keptFail.none { it.suit == suit }
        }
        return emptied to bury.sumOf { it.pointValue }
    }

    /** Fail suits whose ace the picker could legally name after the bury. */
    private fun callableSuits(deal: List<PlayingCard>, bury: List<PlayingCard>): Set<Suit> {
        val dealtAceSuits = deal.filter { it.isFailAce }.mapNotNull { it.suit }.toSet()
        val kept = deal.filter { it !in bury }
        return kept.filter { it.isFail }.mapNotNull { it.suit }.toSet() - dealtAceSuits
    }

    private fun candidateBuries(scenario: DiscardScenario): List<List<PlayingCard>> {
        val fails = scenario.deal.filter { it.isFail }
        val pairs = mutableListOf<List<PlayingCard>>()
        for (first in fails.indices) {
            for (second in fails.indices) {
                if (second <= first) continue
                val pair = listOf(fails[first], fails[second])
                val called = scenario.calledSuit
                if (called != null) {
                    val kept = scenario.deal.filter { it !in pair }
                    if (kept.none { it.isFail && it.suit == called }) continue
                }
                pairs += pair
            }
        }
        return pairs
    }

    @Test
    fun buryRecommendationsNeverContainTrump() {
        for (scenario in discards) assertTrue(scenario.id, scenario.recommendedDiscard.all { it.isFail })
    }

    @Test
    fun buryRecommendationIsTheUniqueBestBury() {
        val order = compareBy<Pair<Int, Int>>({ it.first }, { it.second })
        for (scenario in discards) {
            val candidates = candidateBuries(scenario)
            assertTrue("${scenario.id} has no legal bury", candidates.isNotEmpty())
            val scores = candidates.map { buryScore(scenario.deal, it) }
            val best = scores.maxWithOrNull(order) ?: continue
            val winners = candidates.zip(scores).filter { it.second == best }.map { it.first }
            assertEquals("${scenario.id} is ambiguous", 1, winners.size)
            assertEquals(scenario.id, winners.first().toSet(), scenario.recommendedDiscard.toSet())
        }
    }

    @Test
    fun calledSuitScenariosObeyTheCallAnAceRules() {
        for (scenario in discards) {
            val called = scenario.calledSuit ?: continue
            assertTrue(scenario.id, called != Suit.DIAMONDS)
            assertFalse(scenario.id, PlayingCard.Standard(14, called) in scenario.deal)
            val kept = scenario.deal.filter { it !in scenario.recommendedDiscard }
            assertTrue(scenario.id, kept.any { it.isFail && it.suit == called })
            assertTrue(scenario.id, called in callableSuits(scenario.deal, scenario.recommendedDiscard))
        }
    }

    @Test
    fun buryScenariosAreEitherPartnershipHandsOrMarkedAlone() {
        for (scenario in discards) {
            val callable = callableSuits(scenario.deal, scenario.recommendedDiscard)
            assertEquals(scenario.id, scenario.isAlone, callable.isEmpty())
        }
    }

    @Test
    fun generatedFailSuitExplanationNamesTheSuit() {
        for (suit in failSuits) {
            val cards = listOf(14, 10, 13, 9, 8).map { PlayingCard.Standard(it, suit) }
            val text = HandGenerator.explain(cards, HandCategory.FAIL_SUIT)
            assertTrue(text, text.contains(suit.displayName, ignoreCase = true))
            assertFalse(text, "(suit)" in text)
        }
    }

    @Test
    fun allShownCardsUseTheSheepsheadDeck() {
        val deck = PlayingCard.sheepsheadDeck.toSet()
        assertEquals(32, deck.size)
        for (drill in drills) {
            val shown = when (val kind = drill.kind) {
                is DrillKind.Flashcards -> kind.cards.flatMap { it.frontTiles }
                is DrillKind.Quiz -> kind.questions.flatMap { it.tiles }
                is DrillKind.HandMatch -> kind.questions.flatMap { it.tiles }
                is DrillKind.Discard -> kind.scenarios.flatMap { it.deal }
            }
            assertTrue(drill.id, deck.containsAll(shown))
        }
        assertTrue(deck.containsAll(HowToPlayContent.pages.flatMap { it.tiles }))
    }

    @Test
    fun quizAndCardChoicesAreValid() {
        for (question in quiz) {
            assertTrue(question.id, question.answerIndex in question.choices.indices)
            assertTrue(question.id, question.choices.size >= 2)
            assertEquals(question.id, question.choices.size, question.choices.toSet().size)
        }
        for (card in flashcards) {
            val choice = card.choice ?: continue
            assertEquals(card.id, 2, choice.options.size)
            assertTrue(card.id, choice.answerIndex in choice.options.indices)
            assertEquals(card.id, 2, choice.options.toSet().size)
        }
    }

    @Test
    fun allContentIDsAreUnique() {
        val ids = DrillLibrary.rooms.flatMap { room ->
            listOf(room.id) + room.drills.flatMap { drill ->
                listOf(drill.id) + when (val kind = drill.kind) {
                    is DrillKind.Flashcards -> kind.cards.map { it.id }
                    is DrillKind.Quiz -> kind.questions.map { it.id }
                    is DrillKind.HandMatch -> kind.questions.map { it.id }
                    is DrillKind.Discard -> kind.scenarios.map { it.id }
                }
            }
        }
        assertEquals(ids.size, ids.toSet().size)
    }

    @Test
    fun freeBeginnerModelIsIntact() {
        assertTrue(DrillLibrary.rooms.first().isFree)
        for (room in DrillLibrary.rooms) {
            assertTrue(room.id, room.drills.isNotEmpty())
            for (drill in room.drills) assertTrue(drill.id, drill.kind.itemCount > 0)
            if (room.id == "pro-tables") {
                assertFalse(room.isFree)
            } else {
                assertTrue(room.isFree)
                assertEquals(room.id, 1, room.drills.count { it.isPlus })
            }
            for (drill in room.drills) {
                assertFalse(room.isLocked(drill, isMember = true))
                assertEquals(!room.isFree || drill.isPlus, room.isLocked(drill, isMember = false))
            }
        }
    }

    @Test
    fun noEmDashesOrStaleCardCopy() {
        val copy = mutableListOf<String>()
        for (room in DrillLibrary.rooms) {
            copy += listOf(room.name, room.tagline)
            for (drill in room.drills) {
                copy += listOf(drill.title, drill.subtitle)
                when (val kind = drill.kind) {
                    is DrillKind.Flashcards -> kind.cards.forEach {
                        copy += listOf(it.frontTitle, it.frontSubtitle.orEmpty(), it.backTitle, it.backBody) + it.choice?.options.orEmpty()
                    }
                    is DrillKind.Quiz -> kind.questions.forEach { copy += listOf(it.prompt, it.explanation) + it.choices }
                    is DrillKind.HandMatch -> kind.questions.forEach { copy += it.explanation }
                    is DrillKind.Discard -> kind.scenarios.forEach { copy += listOf(it.situation, it.reasoning, it.tip) }
                }
            }
        }
        HowToPlayContent.pages.forEach { copy += listOf(it.title, it.body, it.tip.orEmpty()) }
        for (text in copy) {
            assertFalse("Em dash: $text", "\u2014" in text)
            assertFalse("Stale tile copy: $text", text.contains("tile", ignoreCase = true))
            assertFalse("Stale source copy: $text", text.contains("crib" + "bage", ignoreCase = true))
            assertFalse("Stale fifteen copy: $text", text.contains("fifteen", ignoreCase = true))
            assertFalse("Stale pegging copy: $text", text.contains("pegging", ignoreCase = true))
        }
    }

    @Test
    fun primerPagesHaveUniqueIDsAndDistinctCards() {
        val pages = HowToPlayContent.pages
        assertEquals(pages.size, pages.map { it.id }.toSet().size)
        for (page in pages) assertEquals(page.id, page.tiles.size, page.tiles.toSet().size)
        assertEquals("card-room", HowToPlayContent.recommendedRoom("new").id)
        assertEquals("trump-room", HowToPlayContent.recommendedRoom("basics").id)
        assertEquals("trick-room", HowToPlayContent.recommendedRoom("played").id)
    }

    private val lockedItemIDs: Set<String> by lazy {
        DrillLibrary.rooms.flatMap { room ->
            room.drills.filter { room.isLocked(it, isMember = false) }.flatMap { drill ->
                when (val kind = drill.kind) {
                    is DrillKind.Flashcards -> kind.cards.map { it.id }
                    is DrillKind.Quiz -> kind.questions.map { it.id }
                    is DrillKind.HandMatch -> kind.questions.map { it.id }
                    is DrillKind.Discard -> kind.scenarios.map { it.id }
                }
            }
        }.toSet()
    }

    @Test
    fun quickSessionPullsTenAndPrioritizesMisses() {
        val mix = SessionBuilder.quickSession(seen = emptySet(), missed = emptySet(), includePro = false)
        assertEquals(10, mix.size)
        assertEquals(10, mix.map { it.id }.toSet().size)
        val missed = mix[0].id
        assertTrue(SessionBuilder.quickSession(seen = setOf(missed), missed = setOf(missed), includePro = false).any { it.id == missed })
    }

    @Test
    fun quickSessionRespectsThePaidBoundary() {
        assertTrue(lockedItemIDs.isNotEmpty())
        val free = SessionBuilder.quickSession(200, emptySet(), emptySet(), includePro = false)
        for (item in free) assertFalse("${item.id} leaked", item.id in lockedItemIDs)
        val member = SessionBuilder.quickSession(500, emptySet(), emptySet(), includePro = true)
        assertTrue(member.any { it.id in lockedItemIDs })
        val freeIDs = ParityFixtures.json.getJSONArray("freePoolIDs").strings().toSet()
        assertEquals(freeIDs, free.map { it.id }.toSet())
    }

    @Test
    fun quickSessionItemsAreChoiceOnly() {
        val plainCards = flashcards.filter { it.choice == null }.map { it.id }.toSet()
        val discardIDs = discards.map { it.id }.toSet()
        for (item in SessionBuilder.quickSession(200, emptySet(), emptySet(), includePro = true)) {
            assertTrue(item.choices.size >= 2)
            assertTrue(item.answerIndex in item.choices.indices)
            assertFalse(item.id in plainCards)
            assertFalse(item.id in discardIDs)
        }
    }

    @Test
    fun gameNightPrepLeadsWithDueThenWeakestRoom() {
        val pool = SessionBuilder.quickSession(500, emptySet(), emptySet(), includePro = true)
        val due = pool.first { it.roomID == "pro-tables" }.id
        val prep = SessionBuilder.gameNightPrep(seen = emptySet(), missed = emptySet(), dueIDs = listOf(due), weakestRoomID = "trick-room")
        assertEquals(10, prep.size)
        assertEquals(due, prep.first().id)
        assertTrue(prep.drop(1).take(9).all { it.roomID == "trick-room" })
    }

    @Test
    fun reviewSessionKeepsSchedulerOrderAndDropsLockedItems() {
        val member = SessionBuilder.quickSession(500, emptySet(), emptySet(), includePro = true)
        val locked = member.first { it.id in lockedItemIDs }.id
        val free = member.first { it.id !in lockedItemIDs }.id
        assertEquals(listOf(locked, free), SessionBuilder.reviewSession(listOf(locked, free), includePro = true).map { it.id })
        assertEquals(listOf(free), SessionBuilder.reviewSession(listOf(locked, free), includePro = false).map { it.id })
    }
}
