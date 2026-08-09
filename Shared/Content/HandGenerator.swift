import Foundation

/// Deals original five-card Sheepshead holdings that foreground one rule.
/// Generated holdings are bounded and rejected whenever they read as two
/// different teaching categories.
enum HandGenerator {
    static let generatableCategories: [HandCategory] = [.trumpStack, .failSuit, .pointCards, .lowCards]

    private static func suits(_ cards: [PlayingCard]) -> [Suit] {
        cards.compactMap { card in
            if case .standard(_, let suit) = card { return suit }
            return nil
        }
    }

    private static func hasTrumpStack(_ cards: [PlayingCard]) -> Bool {
        cards.count == 5 && cards.allSatisfy(\.isTrump)
    }

    private static func hasFailSuit(_ cards: [PlayingCard]) -> Bool {
        guard cards.count == 5, cards.allSatisfy(\.isFail) else { return false }
        let cardSuits = suits(cards)
        return cardSuits.count == 5 && Set(cardSuits).count == 1
    }

    private static func hasPointCards(_ cards: [PlayingCard]) -> Bool {
        cards.count == 5 && cards.allSatisfy { $0.isStandard && $0.pointValue > 0 }
            && !hasTrumpStack(cards)
            && !hasFailSuit(cards)
    }

    private static func hasLowCards(_ cards: [PlayingCard]) -> Bool {
        cards.count == 5 && cards.allSatisfy { $0.isFail && $0.pointValue == 0 }
            && !hasFailSuit(cards)
    }

    static func fits(_ cards: [PlayingCard], _ category: HandCategory) -> Bool {
        switch category {
        case .trumpStack: return hasTrumpStack(cards)
        case .failSuit: return hasFailSuit(cards)
        case .pointCards: return hasPointCards(cards)
        case .lowCards: return hasLowCards(cards)
        default: return false
        }
    }

    static func category(for cards: [PlayingCard]) -> HandCategory? {
        let matches = generatableCategories.filter { fits(cards, $0) }
        return matches.count == 1 ? matches[0] : nil
    }

    struct GeneratedHand {
        let tiles: [PlayingCard]
        let answer: HandCategory
        let choices: [HandCategory]
        let explanation: String
    }

    private static func randomHand<R: RandomNumberGenerator>(
        from pool: [PlayingCard],
        using generator: inout R
    ) -> [PlayingCard]? {
        let cards = Array(pool.shuffled(using: &generator).prefix(5))
        guard cards.count == 5, Set(cards).count == 5 else { return nil }
        return cards
    }

    private static func deal<R: RandomNumberGenerator>(
        _ targetCategory: HandCategory,
        using generator: inout R
    ) -> [PlayingCard]? {
        let deck = PlayingCard.sheepsheadDeck
        let pool: [PlayingCard]
        switch targetCategory {
        case .trumpStack:
            pool = deck.filter(\.isTrump)
        case .failSuit:
            let suit = Suit.allCases.filter { suit in
                deck.filter { $0.isFail && $0.suit == suit }.count >= 5
            }.randomElement(using: &generator) ?? .clubs
            pool = deck.filter { $0.isFail && $0.suit == suit }
        case .pointCards:
            pool = deck.filter { $0.isFail && $0.pointValue > 0 }
        case .lowCards:
            pool = deck.filter { $0.isFail && $0.pointValue == 0 }
        default:
            return nil
        }
        return randomHand(from: pool, using: &generator)
    }

    static func hand(for target: HandCategory, attempts: Int = 120) -> GeneratedHand? {
        var generator = SystemRandomNumberGenerator()
        return hand(for: target, attempts: attempts, using: &generator)
    }

    /// The seeded variant. A dated challenge has to deal the SAME original hand
    /// on every device, so every source of randomness inside has to come from
    /// the caller's generator, not from the system one.
    static func hand<R: RandomNumberGenerator>(
        for target: HandCategory,
        attempts: Int = 120,
        using generator: inout R
    ) -> GeneratedHand? {
        for _ in 0..<attempts {
            guard let cards = deal(target, using: &generator), category(for: cards) == target else { continue }
            let distractors = generatableCategories
                .filter { $0 != target && !fits(cards, $0) }
                .shuffled(using: &generator)
                .prefix(3)
            guard distractors.count >= 2 else { continue }
            return GeneratedHand(
                tiles: cards.racked,
                answer: target,
                choices: ([target] + distractors).shuffled(using: &generator),
                explanation: explain(cards, answer: target)
            )
        }
        return nil
    }

    static func batch(count: Int) -> [GeneratedHand] {
        var generator = SystemRandomNumberGenerator()
        return batch(count: count, using: &generator)
    }

    /// A reproducible batch for a dated shared challenge. The same app build
    /// and seed produce the same original hands on every device, which is what
    /// lets every member answer the same daily challenge without a server.
    static func batch(count: Int, seed: String) -> [GeneratedHand] {
        var generator = StableSeededGenerator(seed: seed)
        return batch(count: count, using: &generator)
    }

    private static func batch<R: RandomNumberGenerator>(
        count: Int,
        using generator: inout R
    ) -> [GeneratedHand] {
        guard count > 0 else { return [] }
        var hands: [GeneratedHand] = []
        var targetIndex = 0
        let maxAttempts = max(count * 20, 40)
        while hands.count < count, targetIndex < maxAttempts {
            let target = generatableCategories[targetIndex % generatableCategories.count]
            if let hand = hand(for: target, using: &generator) {
                hands.append(hand)
            }
            targetIndex += 1
        }
        return hands.shuffled(using: &generator)
    }

    static func explain(_ cards: [PlayingCard], answer: HandCategory) -> String {
        switch answer {
        case .trumpStack:
            return "Every card shown is trump. Start by ordering the queens, jacks, and diamonds before thinking about a lead."
        case .failSuit:
            let suit = suits(cards).first?.displayName.lowercased() ?? "single-suit"
            return "All five cards are \(suit) fail cards. Within that suit, ace is high, then 10, king, 9, 8, and 7."
        case .pointCards:
            return "Every card carries points, but the holding is not a single fail suit or a pure trump stack. Ask which of those point cards can actually win a trick."
        case .lowCards:
            return "All five cards are zero-point fail cards from more than one suit. They are useful for following cheaply and preserving point cards."
        default:
            return answer.howToSpot
        }
    }
}
