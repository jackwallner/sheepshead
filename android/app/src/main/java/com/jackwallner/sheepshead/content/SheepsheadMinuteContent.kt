package com.jackwallner.sheepshead.content

import com.jackwallner.sheepshead.model.ChoiceShuffle
import com.jackwallner.sheepshead.model.DiscardScenario
import com.jackwallner.sheepshead.model.Drill
import com.jackwallner.sheepshead.model.DrillKind
import com.jackwallner.sheepshead.model.PlayingCard
import com.jackwallner.sheepshead.model.StableSeededGenerator
import java.time.LocalDate
import java.util.Locale

enum class SheepsheadMinuteCategory(val raw: String, val title: String, val icon: String) {
    HAND_READING("handReading", "Hand Reading", "rectangle.on.rectangle.angled"),
    BURYING("burying", "The Bury", "arrow.down.circle.fill"),
    TRICK_PLAY("trickPlay", "Trick Play", "hand.point.up.left.fill"),
}

data class SheepsheadMinuteQuestion(val category: SheepsheadMinuteCategory, val item: QuickItem)

data class SheepsheadMinuteChallenge(
    val day: LocalDate,
    val dayKey: String,
    val shortDate: String,
    val questions: List<SheepsheadMinuteQuestion>,
) {
    val items: List<QuickItem> get() = questions.map { it.item }
}

/**
 * One shared five-question set per calendar date, identical to the iOS set for
 * the same date: two generated hand reads, one bury decision and two
 * trick calls, all picked with the same seeds as iOS.
 */
object SheepsheadMinuteContent {
    const val QUESTION_COUNT = 5

    val drill = Drill("sheepshead-minute", "Sheepshead Minute", "Today's shared five-question challenge", DrillKind.Quiz(emptyList()), isPlus = true)

    fun key(day: LocalDate): String = String.format(Locale.US, "%04d-%02d-%02d", day.year, day.monthValue, day.dayOfMonth)

    fun challenge(day: LocalDate = LocalDate.now()): SheepsheadMinuteChallenge {
        val dayKey = key(day)
        val generated = generatedQuestions(dayKey)
        val middle = listOfNotNull(buryQuestion(dayKey))
        val last = roomQuestions(dayKey, "trick-room", SheepsheadMinuteCategory.TRICK_PLAY, 2)
        // Interleaved so the run does not read as three separate quizzes.
        val questions = buildList {
            generated.getOrNull(0)?.let(::add)
            addAll(middle)
            last.getOrNull(0)?.let(::add)
            generated.getOrNull(1)?.let(::add)
            last.getOrNull(1)?.let(::add)
        }
        val shortDate = String.format(Locale.US, "%02d/%02d", day.monthValue, day.dayOfMonth)
        return SheepsheadMinuteChallenge(day, dayKey, shortDate, questions)
    }

    private fun generatedQuestions(dayKey: String): List<SheepsheadMinuteQuestion> =
        HandGenerator.batch(2, "sheepshead-minute-$dayKey-hands").mapIndexed { index, hand ->
            val item = QuickItem(
                id = PracticeSkill.HAND_READING.itemPrefix + "minute-$dayKey-$index",
                prompt = "What is this hand worth?",
                tiles = hand.tiles,
                choices = hand.choices.map { it.displayName },
                answerIndex = hand.choices.indexOf(hand.answer).coerceAtLeast(0),
                explanation = hand.explanation,
                sourceLabel = "Sheepshead Minute: Hand Read",
                roomID = PracticeSkill.HAND_READING.roomID,
                trackingID = PracticeSkill.HAND_READING.raw,
                isReviewable = false,
            )
            SheepsheadMinuteQuestion(SheepsheadMinuteCategory.HAND_READING, SessionBuilder.prepared(item))
        }

    /** Built straight from the authored scenarios: the quick-session pool leaves buries out. */
    private fun buryQuestion(dayKey: String): SheepsheadMinuteQuestion? {
        val scenarios = DrillLibrary.rooms.flatMap { room ->
            room.drills.flatMap { (it.kind as? DrillKind.Discard)?.scenarios ?: emptyList() }
        }
        if (scenarios.isEmpty()) return null
        val generator = StableSeededGenerator("sheepshead-minute-$dayKey-bury")
        val scenario = scenarios[(generator.next() % scenarios.size.toULong()).toInt()]
        val answer = label(scenario.recommendedDiscard)
        val distractors = distractorLabels(scenario, dayKey, answer)
        if (distractors.size < 2) return null
        val item = QuickItem(
            id = "sheepshead-minute-bury-$dayKey",
            prompt = "${scenario.situation} Which two cards do you bury?",
            tiles = scenario.deal,
            choices = listOf(answer) + distractors,
            answerIndex = 0,
            explanation = scenario.reasoning,
            sourceLabel = "Sheepshead Minute: The Bury",
            roomID = "bury-room",
            trackingID = "sheepshead-minute-bury",
            isReviewable = false,
        )
        return SheepsheadMinuteQuestion(SheepsheadMinuteCategory.BURYING, SessionBuilder.prepared(item))
    }

    /** Every other pair from the same deal, so a wrong answer is a real alternative. */
    private fun distractorLabels(scenario: DiscardScenario, dayKey: String, answer: String): List<String> {
        val labels = mutableSetOf<String>()
        for (first in 0 until maxOf(0, scenario.deal.size - 1)) {
            for (second in first + 1 until scenario.deal.size) {
                labels += label(listOf(scenario.deal[first], scenario.deal[second]))
            }
        }
        labels -= answer
        val sorted = labels.sorted()
        val order = ChoiceShuffle.permutation(sorted.size, "sheepshead-minute-$dayKey-bury-choices")
        return order.take(3).map { sorted[it] }
    }

    private fun label(cards: List<PlayingCard>): String = cards.joinToString(", ") { it.spokenName }

    /** Authored questions from one room, picked by a permutation of the day key. */
    private fun roomQuestions(dayKey: String, roomID: String, category: SheepsheadMinuteCategory, count: Int): List<SheepsheadMinuteQuestion> {
        val pool = SessionBuilder.choiceItems(roomID, includePro = true)
        if (pool.isEmpty()) return emptyList()
        val indices = ChoiceShuffle.permutation(pool.size, "sheepshead-minute-$dayKey-$roomID")
        return indices.take(count).map { SheepsheadMinuteQuestion(category, SessionBuilder.prepared(pool[it])) }
    }
}
