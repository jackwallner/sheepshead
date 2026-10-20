import Foundation

/// Deals original five-card tricks and scores them with the standard rules, so
/// every generated "who takes it" and "how many points" answer comes from the
/// rules rather than from authored text.
///
/// A trick is the five cards played in order, one per player. The first card is
/// the lead. The winner is the highest trump if any trump was played, otherwise
/// the highest card of the suit that was led. A fail card of another suit can
/// never win, however high: that player was void and discarded.
enum TrickGenerator {
    /// The shapes a trick can teach. Each one is built so a single rule decides
    /// the winner, which keeps the explanation honest.
    enum Shape: CaseIterable, Sendable {
        /// A fail suit is led, a higher off-suit card sits in the trick, and no
        /// trump is played: the highest card OF THE LED SUIT wins.
        case followSuit
        /// A fail suit is led and one or more players trump in.
        case trumpIn
        /// Trump is led or heavily played: the order of queens, jacks, then
        /// diamonds decides it.
        case trumpOrder
    }

    struct Trick: Sendable {
        let cards: [PlayingCard]
        let shape: Shape
        let winnerIndex: Int
        var winner: PlayingCard { cards[winnerIndex] }
        var points: Int { cards.reduce(0) { $0 + $1.pointValue } }
    }

    /// Index of the winning card in `cards` (play order, first card led).
    static func winnerIndex(of cards: [PlayingCard]) -> Int? {
        guard cards.count >= 2, Set(cards).count == cards.count,
              cards.allSatisfy(\.isStandard) else { return nil }
        let trumpIndices = cards.indices.filter { cards[$0].isTrump }
        if !trumpIndices.isEmpty {
            return trumpIndices.max { cards[$0].trumpStrength < cards[$1].trumpStrength }
        }
        guard let ledSuit = cards[0].suit else { return nil }
        let followers = cards.indices.filter { cards[$0].suit == ledSuit }
        return followers.max { cards[$0].failStrength < cards[$1].failStrength }
    }

    static func deal(_ shape: Shape) -> Trick? {
        var generator = SystemRandomNumberGenerator()
        return deal(shape, using: &generator)
    }

    static func deal<R: RandomNumberGenerator>(_ shape: Shape, using generator: inout R) -> Trick? {
        for _ in 0..<400 {
            let cards = candidate(for: shape, using: &generator)
            guard fits(cards, shape), let winner = winnerIndex(of: cards) else { continue }
            return Trick(cards: cards, shape: shape, winnerIndex: winner)
        }
        return nil
    }

    /// Draws from a pool that makes the shape likely, so the rejection check in
    /// `fits` is a safety net and not the thing doing the dealing: a uniform
    /// five-card draw is trump-free only about 4% of the time.
    private static func candidate<R: RandomNumberGenerator>(for shape: Shape, using generator: inout R) -> [PlayingCard] {
        let deck = PlayingCard.sheepsheadDeck
        let trump = deck.filter(\.isTrump).shuffled(using: &generator)
        let fail = deck.filter(\.isFail).shuffled(using: &generator)
        switch shape {
        case .followSuit:
            return Array(fail.prefix(5))
        case .trumpIn:
            let trumpCount = Int.random(in: 1...2, using: &generator)
            let led = fail[0]
            let rest = (Array(fail.dropFirst().prefix(4 - trumpCount)) + trump.prefix(trumpCount))
                .shuffled(using: &generator)
            return [led] + rest
        case .trumpOrder:
            let trumpCount = Int.random(in: 3...5, using: &generator)
            let hand = Array(trump.prefix(trumpCount)) + fail.prefix(5 - trumpCount)
            return [hand[0]] + hand.dropFirst().shuffled(using: &generator)
        }
    }

    static func fits(_ cards: [PlayingCard], _ shape: Shape) -> Bool {
        guard cards.count == 5, Set(cards).count == 5 else { return false }
        let trumpCount = cards.filter(\.isTrump).count
        switch shape {
        case .followSuit:
            guard trumpCount == 0, let led = cards[0].suit else { return false }
            let followers = cards.filter { $0.suit == led }
            let best = followers.map(\.failStrength).max() ?? 0
            let offSuitHigher = cards.contains { $0.suit != led && $0.failStrength > best }
            return followers.count >= 2 && followers.count <= 4 && offSuitHigher
        case .trumpIn:
            return cards[0].isFail && (1...2).contains(trumpCount)
        case .trumpOrder:
            return cards[0].isTrump && trumpCount >= 3
        }
    }

    static func explain(_ trick: Trick) -> String {
        let cards = trick.cards
        let winner = trick.winner
        let lead = cards[0]
        switch trick.shape {
        case .followSuit:
            let suit = lead.suit?.displayName.lowercased() ?? "the led suit"
            return "\(lead.spokenName) led \(suit) and nobody played trump, so only \(suit) cards compete. The \(winner.spokenName) is the highest of them (ace, 10, king, 9, 8, 7). Off-suit fail cards cannot win, even a higher one."
        case .trumpIn:
            let best = winner.spokenName
            return "\(lead.spokenName) led a fail suit, but a trump beats any fail card. The highest trump played is the \(best), so it takes the trick."
        case .trumpOrder:
            return "Trump was led and trump order decides it: queens (clubs, spades, hearts, diamonds), then jacks in the same order, then diamonds from ace down. The \(winner.spokenName) is the highest trump here."
        }
    }

    /// Wrong answers worth offering: other cards actually in the trick. Always
    /// at least three exist because a trick has five distinct cards.
    static func choices<R: RandomNumberGenerator>(for trick: Trick, using generator: inout R) -> [PlayingCard] {
        let others = trick.cards.enumerated()
            .filter { $0.offset != trick.winnerIndex }
            .map(\.element)
            .shuffled(using: &generator)
            .prefix(3)
        return ([trick.winner] + others).shuffled(using: &generator)
    }

    // MARK: - Point counting

    /// A trick score that the player has to add up from card values.
    /// Distractors are the common slips: forgetting one scoring card, or
    /// treating a nine, eight or seven as scoring.
    static func pointChoices(for cards: [PlayingCard]) -> [Int] {
        let total = cards.reduce(0) { $0 + $1.pointValue }
        let scoring = cards.filter { $0.pointValue > 0 }
        var wrong: [Int] = []
        if let smallest = scoring.map(\.pointValue).min() { wrong.append(total - smallest) }
        if let largest = scoring.map(\.pointValue).max() { wrong.append(total - largest) }
        wrong.append(total + 10)
        wrong.append(total + 2)
        wrong.append(total + 4)
        var seen: Set<Int> = [total]
        var result = [total]
        for value in wrong where value >= 0 && !seen.contains(value) {
            seen.insert(value)
            result.append(value)
            if result.count == 4 { break }
        }
        return result
    }

    static func explainPoints(_ cards: [PlayingCard]) -> String {
        let scoring = cards.filter { $0.pointValue > 0 }
        guard !scoring.isEmpty else {
            return "Nine, eight and seven carry no points, so these cards add up to 0. Aces are 11, tens 10, kings 4, queens 3, and jacks 2."
        }
        let parts = scoring.map { "\($0.shortLabel) \($0.pointValue)" }.joined(separator: " + ")
        let total = scoring.reduce(0) { $0 + $1.pointValue }
        return "Only aces (11), tens (10), kings (4), queens (3) and jacks (2) score. \(parts) = \(total). The other cards are worth 0."
    }
}
