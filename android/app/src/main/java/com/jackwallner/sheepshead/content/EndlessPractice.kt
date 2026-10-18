package com.jackwallner.sheepshead.content

import com.jackwallner.sheepshead.model.Drill
import com.jackwallner.sheepshead.model.DrillKind
import com.jackwallner.sheepshead.model.PlayingCard
import java.util.UUID

/** Generated practice skills. Each one becomes the same QuickItem shape as authored drills. */
enum class PracticeSkill(val raw: String, val title: String, val subtitle: String, val icon: String, val roomID: String) {
    HAND_READING("handReading", "Read the Holding", "Fresh five-card holdings, unlimited reps", "rectangle.portrait.on.rectangle.portrait.angled", "trump-room"),
    TRICK_PLAY("trickPlay", "Read the Trump", "Classify cards before you play them", "crown.fill", "trick-room");

    /** Every generated item carries this prefix so stats roll it up into one row. */
    val itemPrefix: String get() = "gen-$raw-"

    companion object {
        fun fromRaw(raw: String): PracticeSkill? = entries.firstOrNull { it.raw == raw }

        fun skill(forItemID: String): PracticeSkill? = entries.firstOrNull { forItemID.startsWith(it.itemPrefix) }
    }
}

object EndlessPractice {
    fun drill(skill: PracticeSkill) = Drill("endless-${skill.raw}", skill.title, skill.subtitle, DrillKind.Quiz(emptyList()))

    val challengeDrill = Drill("timed-challenge", "Timed Challenge", "Beat the clock with mixed card reads", DrillKind.Quiz(emptyList()))

    fun items(skill: PracticeSkill, count: Int): List<QuickItem> = when (skill) {
        PracticeSkill.HAND_READING -> handItems(count)
        PracticeSkill.TRICK_PLAY -> trickItems(count)
    }

    /** A mixed batch across every skill, for the timed challenge. */
    fun mixedItems(count: Int): List<QuickItem> {
        if (count <= 0) return emptyList()
        val skills = PracticeSkill.entries
        val perSkill = maxOf(1, count / skills.size + 1)
        return skills.flatMap { items(it, perSkill) }.shuffled().take(count)
    }

    private fun newID(skill: PracticeSkill) = skill.itemPrefix + UUID.randomUUID().toString().uppercase()

    private fun handItems(count: Int): List<QuickItem> = HandGenerator.batch(count).map { hand ->
        QuickItem(
            id = newID(PracticeSkill.HAND_READING),
            prompt = "Which rule should you spot first?",
            tiles = hand.tiles,
            choices = hand.choices.map { it.displayName },
            answerIndex = hand.choices.indexOf(hand.answer).coerceAtLeast(0),
            explanation = hand.explanation,
            sourceLabel = "Endless Practice",
            roomID = PracticeSkill.HAND_READING.roomID,
        )
    }

    private fun trickItems(count: Int): List<QuickItem> = (0 until maxOf(0, count)).map {
        val card = PlayingCard.sheepsheadDeck.random()
        val explanation = if (card.isTrump) {
            "${card.spokenName} is trump because every queen, every jack, and every diamond is trump."
        } else {
            "${card.spokenName} is a fail card because it is not a queen, jack, or diamond. It follows its printed suit."
        }
        QuickItem(
            id = newID(PracticeSkill.TRICK_PLAY),
            prompt = "How should you classify the ${card.spokenName} before play?",
            tiles = listOf(card),
            choices = listOf("Trump", "Fail card", "Not in the deck"),
            answerIndex = if (card.isTrump) 0 else 1,
            explanation = explanation,
            sourceLabel = "Endless Practice",
            roomID = PracticeSkill.TRICK_PLAY.roomID,
        )
    }
}
