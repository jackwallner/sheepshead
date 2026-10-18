package com.jackwallner.sheepshead.content

import com.jackwallner.sheepshead.model.HandCategory
import com.jackwallner.sheepshead.model.PlayingCard
import com.jackwallner.sheepshead.model.RandomSource
import com.jackwallner.sheepshead.model.StableSeededGenerator
import com.jackwallner.sheepshead.model.Suit
import com.jackwallner.sheepshead.model.SystemRandomSource
import com.jackwallner.sheepshead.model.racked
import com.jackwallner.sheepshead.model.randomElement
import com.jackwallner.sheepshead.model.shuffledSwift

/**
 * Port of iOS `HandGenerator`: original five-card Sheepshead holdings that
 * foreground one rule, rejected whenever they read as two categories. Every
 * draw comes from the RandomSource in the same order as the Swift original,
 * so a seeded batch deals the same cards as iOS (`GeneratorParityTest`).
 */
object HandGenerator {
    val generatableCategories: List<HandCategory> =
        listOf(HandCategory.TRUMP_STACK, HandCategory.FAIL_SUIT, HandCategory.POINT_CARDS, HandCategory.LOW_CARDS)

    private fun suits(cards: List<PlayingCard>): List<Suit> = cards.mapNotNull { it.suit }

    private fun hasTrumpStack(cards: List<PlayingCard>): Boolean = cards.size == 5 && cards.all { it.isTrump }

    private fun hasFailSuit(cards: List<PlayingCard>): Boolean {
        if (cards.size != 5 || !cards.all { it.isFail }) return false
        val cardSuits = suits(cards)
        return cardSuits.size == 5 && cardSuits.toSet().size == 1
    }

    private fun hasPointCards(cards: List<PlayingCard>): Boolean =
        cards.size == 5 && cards.all { it.isStandard && it.pointValue > 0 } && !hasTrumpStack(cards) && !hasFailSuit(cards)

    private fun hasLowCards(cards: List<PlayingCard>): Boolean =
        cards.size == 5 && cards.all { it.isFail && it.pointValue == 0 } && !hasFailSuit(cards)

    fun fits(cards: List<PlayingCard>, category: HandCategory): Boolean = when (category) {
        HandCategory.TRUMP_STACK -> hasTrumpStack(cards)
        HandCategory.FAIL_SUIT -> hasFailSuit(cards)
        HandCategory.POINT_CARDS -> hasPointCards(cards)
        HandCategory.LOW_CARDS -> hasLowCards(cards)
        else -> false
    }

    fun category(cards: List<PlayingCard>): HandCategory? =
        generatableCategories.filter { fits(cards, it) }.singleOrNull()

    data class GeneratedHand(
        val tiles: List<PlayingCard>,
        val answer: HandCategory,
        val choices: List<HandCategory>,
        val explanation: String,
    )

    private fun randomHand(pool: List<PlayingCard>, source: RandomSource): List<PlayingCard>? {
        val cards = pool.shuffledSwift(source).take(5)
        if (cards.size != 5 || cards.toSet().size != 5) return null
        return cards
    }

    private fun deal(target: HandCategory, source: RandomSource): List<PlayingCard>? {
        val deck = PlayingCard.sheepsheadDeck
        val pool = when (target) {
            HandCategory.TRUMP_STACK -> deck.filter { it.isTrump }
            HandCategory.FAIL_SUIT -> {
                val suit = Suit.entries.filter { suit -> deck.count { it.isFail && it.suit == suit } >= 5 }
                    .randomElement(source) ?: Suit.CLUBS
                deck.filter { it.isFail && it.suit == suit }
            }
            HandCategory.POINT_CARDS -> deck.filter { it.isFail && it.pointValue > 0 }
            HandCategory.LOW_CARDS -> deck.filter { it.isFail && it.pointValue == 0 }
            else -> return null
        }
        return randomHand(pool, source)
    }

    fun hand(target: HandCategory, attempts: Int = 120, source: RandomSource = SystemRandomSource): GeneratedHand? {
        repeat(attempts) {
            val cards = deal(target, source) ?: return@repeat
            if (category(cards) != target) return@repeat
            val distractors = generatableCategories
                .filter { it != target && !fits(cards, it) }
                .shuffledSwift(source)
                .take(3)
            if (distractors.size < 2) return@repeat
            return GeneratedHand(
                tiles = cards.racked,
                answer = target,
                choices = (listOf(target) + distractors).shuffledSwift(source),
                explanation = explain(cards, target),
            )
        }
        return null
    }

    fun batch(count: Int): List<GeneratedHand> = batch(count, SystemRandomSource)

    /** A reproducible batch: the same seed deals the same holdings as iOS on every device. */
    fun batch(count: Int, seed: String): List<GeneratedHand> = batch(count, StableSeededGenerator(seed))

    private fun batch(count: Int, source: RandomSource): List<GeneratedHand> {
        if (count <= 0) return emptyList()
        val hands = mutableListOf<GeneratedHand>()
        var targetIndex = 0
        val maxAttempts = maxOf(count * 20, 40)
        while (hands.size < count && targetIndex < maxAttempts) {
            val target = generatableCategories[targetIndex % generatableCategories.size]
            hand(target, source = source)?.let { hands += it }
            targetIndex += 1
        }
        return hands.shuffledSwift(source)
    }

    fun explain(cards: List<PlayingCard>, answer: HandCategory): String = when (answer) {
        HandCategory.TRUMP_STACK ->
            "Every card shown is trump. Start by ordering the queens, jacks, and diamonds before thinking about a lead."
        HandCategory.FAIL_SUIT -> {
            val suit = suits(cards).firstOrNull()?.displayName?.lowercase() ?: "single-suit"
            "All five cards are $suit fail cards. Within that suit, ace is high, then 10, king, 9, 8, and 7."
        }
        HandCategory.POINT_CARDS ->
            "Every card carries points, but the holding is not a single fail suit or a pure trump stack. Ask which of those point cards can actually win a trick."
        HandCategory.LOW_CARDS ->
            "All five cards are zero-point fail cards from more than one suit. They are useful for following cheaply and preserving point cards."
        else -> answer.howToSpot
    }
}
