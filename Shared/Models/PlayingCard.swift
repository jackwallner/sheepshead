import Foundation

enum Suit: String, Codable, CaseIterable, Hashable, Sendable {
    case clubs, diamonds, hearts, spades

    var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        case .spades: return "♠"
        }
    }

    var displayName: String { rawValue.capitalized }
}

enum PlayingCard: Hashable, Codable, Sendable {
    case standard(rank: Int, suit: Suit)
    case joker

    // Shortcuts keep authored examples compact and make suits obvious.
    static func c(_ rank: Int) -> PlayingCard { .standard(rank: rank, suit: .clubs) }
    static func d(_ rank: Int) -> PlayingCard { .standard(rank: rank, suit: .diamonds) }
    static func h(_ rank: Int) -> PlayingCard { .standard(rank: rank, suit: .hearts) }
    static func s(_ rank: Int) -> PlayingCard { .standard(rank: rank, suit: .spades) }

    static let sheepsheadRanks = Array(7...14)

    static var sheepsheadDeck: [PlayingCard] {
        Suit.allCases.flatMap { suit in
            sheepsheadRanks.map { rank in
                .standard(rank: rank, suit: suit)
            }
        }
    }

    var shortLabel: String {
        switch self {
        case .standard(let rank, let suit): return "\(Self.rankLabel(rank))\(suit.symbol)"
        case .joker: return "Joker"
        }
    }

    var spokenName: String {
        switch self {
            case .standard(let rank, let suit): return "\(Self.rankLabel(rank)) of \(suit.displayName)"
            case .joker: return "Joker"
        }
    }

    var rankValue: Int {
        switch self {
            case .standard(let rank, _): return rank
            case .joker: return 0
        }
    }

    var isTrump: Bool {
        switch self {
        case .standard(let rank, let suit):
            return suit == .diamonds || rank == 11 || rank == 12
        case .joker:
            return false
        }
    }

    var isFail: Bool {
        switch self {
        case .standard:
            return !isTrump
        case .joker:
            return false
        }
    }

    var pointValue: Int {
        switch self {
        case .standard(let rank, _):
            switch rank {
            case 14: return 11
            case 10: return 10
            case 13: return 4
            case 12: return 3
            case 11: return 2
            default: return 0
            }
        case .joker: return 0
        }
    }

    var sheepsheadValue: Int { pointValue }

    var trumpStrength: Int {
        guard case .standard(let rank, let suit) = self, isTrump else { return 0 }
        let suitStrength: Int
        switch suit {
        case .clubs: suitStrength = 4
        case .spades: suitStrength = 3
        case .hearts: suitStrength = 2
        case .diamonds: suitStrength = 1
        }
        if rank == 12 { return 300 + suitStrength }
        if rank == 11 { return 200 + suitStrength }
        switch rank {
        case 14: return 106
        case 10: return 105
        case 13: return 104
        case 9: return 103
        case 8: return 102
        case 7: return 101
        default: return 0
        }
    }

    var failStrength: Int {
        guard case .standard(let rank, _) = self, isFail else { return 0 }
        switch rank {
        case 14: return 6
        case 10: return 5
        case 13: return 4
        case 9: return 3
        case 8: return 2
        case 7: return 1
        default: return 0
        }
    }

    var sortKey: Int {
        switch self {
            case .standard(let rank, let suit):
            let suitOrder: Int
            switch suit {
            case .clubs: suitOrder = 0
            case .diamonds: suitOrder = 1
            case .hearts: suitOrder = 2
            case .spades: suitOrder = 3
            }
            return suitOrder * 20 + rank
            case .joker: return 100
        }
    }

    static func rankLabel(_ rank: Int) -> String {
        switch rank {
        case 14: return "A"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        default: return String(rank)
        }
    }
}

extension Array where Element == PlayingCard {
    var racked: [PlayingCard] { sorted { $0.sortKey < $1.sortKey } }
}
