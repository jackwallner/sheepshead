import Foundation

/// Five-player called-ace play, plus the explicitly agreed called-ten alternative.
enum SheepsheadRules {
    /// The called-ten alternative described in the lessons, when agreed at the table.
    static func callableTenSuits(dealIncludingBlind: [PlayingCard], bury: [PlayingCard]) -> [Suit] {
        let suits: [Suit] = [.clubs, .hearts, .spades]
        guard suits.allSatisfy({ dealIncludingBlind.contains(.standard(rank: 14, suit: $0)) }) else { return [] }
        let kept = dealIncludingBlind.filter { !bury.contains($0) }
        return suits.filter { suit in
            !dealIncludingBlind.contains(.standard(rank: 10, suit: suit))
                && kept.contains(.standard(rank: 14, suit: suit))
        }
    }
    static func callableSuits(dealIncludingBlind: [PlayingCard], bury: [PlayingCard]) -> [Suit] {
        let kept = dealIncludingBlind.filter { !bury.contains($0) }
        return [Suit.clubs, .hearts, .spades].filter { suit in
            !dealIncludingBlind.contains(.standard(rank: 14, suit: suit))
                && kept.contains { $0.isFail && $0.suit == suit }
        }
    }
    static func canBury(_ cards: [PlayingCard], from deal: [PlayingCard]) -> Bool {
        cards.count == 2 && Set(cards).count == 2 && cards.allSatisfy(deal.contains)
    }
    static func legal(_ hand: [PlayingCard], led: PlayingCard?, calledSuit: Suit? = nil,
                      isPicker: Bool = false, calledSuitOpened: Bool = true, calledRank: Int = 14) -> [PlayingCard] {
        guard let led else { return hand }
        let following = hand.filter { led.isTrump ? $0.isTrump : $0.isFail && $0.suit == led.suit }
        let normal = following.isEmpty ? hand : following
        guard let calledSuit, !calledSuitOpened, hand.count > 1 else { return normal }
        let ace = PlayingCard.standard(rank: calledRank, suit: calledSuit)
        let reservedAce = PlayingCard.standard(rank: 14, suit: calledSuit)
        if led.isFail && led.suit == calledSuit {
            if isPicker && calledRank == 10 && hand.contains(reservedAce) { return [reservedAce] }
            return hand.contains(ace) ? [ace] : normal
        }
        // Until the called suit is led, partner reserves the ace and picker
        // reserves at least one hold card. Both may lead the called suit.
        let holds = hand.filter { $0.isFail && $0.suit == calledSuit }
        return normal.filter { card in
            if !isPicker { return card != ace }
            if calledRank == 10 { return card != reservedAce }
            return holds.count != 1 || card != holds[0]
        }
    }
    static func winner(_ trick: [PlayingCard]) -> Int? {
        guard let led = trick.first else { return nil }
        func strength(_ card: PlayingCard) -> Int {
            if card.isTrump { return 1000 + card.trumpStrength }
            return !led.isTrump && card.suit == led.suit ? card.failStrength : 0
        }
        return trick.indices.max { strength(trick[$0]) < strength(trick[$1]) }
    }
    static func pickerWins(trickPoints: Int, bury: [PlayingCard]) -> Bool {
        trickPoints + bury.reduce(0) { $0 + $1.pointValue } >= 61
    }
}
