package com.jackwallner.sheepshead.model

/** Five-player called ace and the explicitly agreed called-ten alternative. */
object SheepsheadRules {
    fun callableTenSuits(dealIncludingBlind: List<PlayingCard>, bury: List<PlayingCard>): List<Suit> {
        val suits = listOf(Suit.CLUBS, Suit.HEARTS, Suit.SPADES)
        if (!suits.all { PlayingCard.Standard(14, it) in dealIncludingBlind }) return emptyList()
        val kept = dealIncludingBlind.filter { it !in bury }
        return suits.filter { PlayingCard.Standard(10, it) !in dealIncludingBlind && PlayingCard.Standard(14, it) in kept }
    }
    fun callableSuits(dealIncludingBlind: List<PlayingCard>, bury: List<PlayingCard>): List<Suit> {
        val kept = dealIncludingBlind.filter { it !in bury }
        return listOf(Suit.CLUBS, Suit.HEARTS, Suit.SPADES).filter { suit ->
            PlayingCard.Standard(14, suit) !in dealIncludingBlind && kept.any { it.isFail && it.suit == suit }
        }
    }
    fun canBury(cards: List<PlayingCard>, deal: List<PlayingCard>) =
        cards.size == 2 && cards.toSet().size == 2 && cards.all { it in deal }
    fun legal(hand: List<PlayingCard>, led: PlayingCard?, calledSuit: Suit? = null,
        isPicker: Boolean = false, calledSuitOpened: Boolean = true, calledRank: Int = 14): List<PlayingCard> {
        if (led == null) return hand
        val following = hand.filter { if (led.isTrump) it.isTrump else it.isFail && it.suit == led.suit }
        val normal = following.ifEmpty { hand }
        if (calledSuit == null || calledSuitOpened || hand.size == 1) return normal
        val ace = PlayingCard.Standard(calledRank, calledSuit)
        val reservedAce = PlayingCard.Standard(14, calledSuit)
        if (led.isFail && led.suit == calledSuit) {
            if (isPicker && calledRank == 10 && reservedAce in hand) return listOf(reservedAce)
            return if (ace in hand) listOf(ace) else normal
        }
        val holds = hand.filter { it.isFail && it.suit == calledSuit }
        return normal.filter { if (!isPicker) it != ace else if (calledRank == 10) it != reservedAce else holds.size != 1 || it != holds[0] }
    }
    fun winner(trick: List<PlayingCard>): Int? {
        val led = trick.firstOrNull() ?: return null
        fun strength(c: PlayingCard) = if (c.isTrump) 1000 + c.trumpStrength
            else if (!led.isTrump && c.suit == led.suit) c.failStrength else 0
        return trick.indices.maxByOrNull { strength(trick[it]) }
    }
    fun pickerWins(trickPoints: Int, bury: List<PlayingCard>) = trickPoints + bury.sumOf { it.pointValue } >= 61
}
