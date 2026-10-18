package com.jackwallner.sheepshead.model

// Case order matches the iOS `allCases` order. The seeded generators walk
// these lists, so reordering a case changes every shared daily challenge.

enum class Suit(val raw: String, val symbol: String) {
    CLUBS("clubs", "♣"),
    DIAMONDS("diamonds", "♦"),
    HEARTS("hearts", "♥"),
    SPADES("spades", "♠");

    val displayName: String get() = raw.replaceFirstChar { it.uppercase() }
    val isRed: Boolean get() = this == DIAMONDS || this == HEARTS

    companion object {
        fun fromRaw(raw: String): Suit = entries.first { it.raw == raw }
    }
}

sealed interface PlayingCard {
    data class Standard(val rank: Int, override val suit: Suit) : PlayingCard
    data object Joker : PlayingCard

    val shortLabel: String
        get() = when (this) {
            is Standard -> "${rankLabel(rank)}${suit.symbol}"
            Joker -> "Joker"
        }

    val spokenName: String
        get() = when (this) {
            is Standard -> "${rankLabel(rank)} of ${suit.displayName}"
            Joker -> "Joker"
        }

    val rankValue: Int get() = (this as? Standard)?.rank ?: 0

    val suit: Suit? get() = null

    val isStandard: Boolean get() = this is Standard

    /** Queens, jacks and every diamond are trump. */
    val isTrump: Boolean
        get() = when (this) {
            is Standard -> suit == Suit.DIAMONDS || rank == 11 || rank == 12
            Joker -> false
        }

    val isFail: Boolean get() = this is Standard && !isTrump

    /** A fail ace is the only card the picker can name for a partner. */
    val isFailAce: Boolean get() = isFail && rankValue == 14

    val pointValue: Int
        get() = when ((this as? Standard)?.rank) {
            14 -> 11
            10 -> 10
            13 -> 4
            12 -> 3
            11 -> 2
            else -> 0
        }

    val sheepsheadValue: Int get() = pointValue

    val trumpStrength: Int
        get() {
            if (this !is Standard || !isTrump) return 0
            val suitStrength = when (suit) {
                Suit.CLUBS -> 4
                Suit.SPADES -> 3
                Suit.HEARTS -> 2
                Suit.DIAMONDS -> 1
            }
            if (rank == 12) return 300 + suitStrength
            if (rank == 11) return 200 + suitStrength
            return when (rank) {
                14 -> 106
                10 -> 105
                13 -> 104
                9 -> 103
                8 -> 102
                7 -> 101
                else -> 0
            }
        }

    val failStrength: Int
        get() {
            if (this !is Standard || !isFail) return 0
            return when (rank) {
                14 -> 6
                10 -> 5
                13 -> 4
                9 -> 3
                8 -> 2
                7 -> 1
                else -> 0
            }
        }

    val sortKey: Int
        get() = when (this) {
            is Standard -> suit.ordinal * 20 + rank
            Joker -> 100
        }

    /** The card's code in the exported content, e.g. `H11` for the jack of hearts. */
    val code: String
        get() = when (this) {
            is Standard -> "${suit.raw.take(1).uppercase()}$rank"
            Joker -> "JK"
        }

    companion object {
        fun c(rank: Int): PlayingCard = Standard(rank, Suit.CLUBS)
        fun d(rank: Int): PlayingCard = Standard(rank, Suit.DIAMONDS)
        fun h(rank: Int): PlayingCard = Standard(rank, Suit.HEARTS)
        fun s(rank: Int): PlayingCard = Standard(rank, Suit.SPADES)

        val sheepsheadRanks: List<Int> = (7..14).toList()

        fun rankLabel(rank: Int): String = when (rank) {
            14 -> "A"
            11 -> "J"
            12 -> "Q"
            13 -> "K"
            else -> rank.toString()
        }

        /** Suit by suit, 7 to ace, the same order as iOS `sheepsheadDeck`. */
        val sheepsheadDeck: List<PlayingCard> = Suit.entries.flatMap { suit -> sheepsheadRanks.map { Standard(it, suit) } }

        private val byCode: Map<String, PlayingCard> =
            (Suit.entries.flatMap { suit -> (1..14).map { Standard(it, suit) } } + Joker).associateBy { it.code }

        fun fromCode(code: String): PlayingCard = byCode[code] ?: error("Unknown card code $code")
    }
}

/** Sorted by suit then rank, the way the hand is fanned on screen. */
val List<PlayingCard>.racked: List<PlayingCard> get() = sortedBy { it.sortKey }
