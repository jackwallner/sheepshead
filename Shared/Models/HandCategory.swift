import Foundation

/// The rule families a Sheepshead player learns to recognize.
/// These are teaching categories, not a replacement for house rules.
enum HandCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case trumpStack
    case failSuit
    case pointCards
    case lowCards
    case picking
    case partnership
    case trickTaking
    case scoring
    case strategy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .trumpStack: return "Trump Stack"
        case .failSuit: return "Fail Suit"
        case .pointCards: return "Point Cards"
        case .lowCards: return "Low Cards"
        case .picking: return "Picking"
        case .partnership: return "Partnership"
        case .trickTaking: return "Trick Taking"
        case .scoring: return "Scoring"
        case .strategy: return "Strategy"
        }
    }

    var shortName: String {
        switch self {
        case .trumpStack: return "Trump Stack"
        case .failSuit: return "Fail Suit"
        case .pointCards: return "Point Cards"
        case .lowCards: return "Low Cards"
        case .picking: return "Picking"
        case .partnership: return "Partnership"
        case .trickTaking: return "Trick Taking"
        case .scoring: return "Scoring"
        case .strategy: return "Strategy"
        }
    }

    var howToSpot: String {
        switch self {
        case .trumpStack:
            return "Queens, jacks, and every diamond are trump. The queen of clubs is highest, followed by the other permanent trumps."
        case .failSuit:
            return "Clubs, hearts, and spades keep their suits. Within a fail suit, ace is high, then 10, king, 9, 8, and 7."
        case .pointCards:
            return "Aces, 10s, kings, queens, and jacks carry the 120 points. Sevens, eights, and nines carry no points."
        case .lowCards:
            return "Low fail cards do not carry points, but they can protect a lead, follow cheaply, or keep a trump hidden."
        case .picking:
            return "The picker takes the blind, buries two cards, and chooses whether the hand is strong enough to name a partner or go alone."
        case .partnership:
            return "In the common call-an-ace game, the player holding the named fail ace is the picker's silent partner."
        case .trickTaking:
            return "Follow the led fail suit when possible. A trump beats every fail card, and the strongest card in the winning suit takes the trick."
        case .scoring:
            return "The picking team needs at least 61 of the 120 points. Count the points in captured tricks, not the number of tricks alone."
        case .strategy:
            return "Good play weighs trump control, the called suit, point cards, position, and what the other players have shown."
        }
    }
}
