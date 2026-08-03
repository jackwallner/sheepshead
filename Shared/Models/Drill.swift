import Foundation

/// A two-option self-test on a card's front. Answering flips the card and
/// grades the decision before the explanation lands.
struct CardChoice: Sendable {
    let options: [String]
    let answerIndex: Int

    init(_ first: String, _ second: String, answerIndex: Int) {
        options = [first, second]
        self.answerIndex = answerIndex
    }
}

struct Flashcard: Identifiable, Sendable {
    let id: String
    let frontTitle: String
    let frontTiles: [PlayingCard]
    let frontSubtitle: String?
    let backTitle: String
    let backBody: String
    let choice: CardChoice?

    init(id: String, frontTitle: String, frontTiles: [PlayingCard] = [], frontSubtitle: String? = nil,
         backTitle: String, backBody: String, choice: CardChoice? = nil) {
        self.id = id
        self.frontTitle = frontTitle
        self.frontTiles = frontTiles
        self.frontSubtitle = frontSubtitle
        self.backTitle = backTitle
        self.backBody = backBody
        self.choice = choice
    }
}

struct QuizQuestion: Identifiable, Sendable {
    let id: String
    let prompt: String
    let tiles: [PlayingCard]
    let choices: [String]
    let answerIndex: Int
    let explanation: String

    init(id: String, prompt: String, tiles: [PlayingCard] = [], choices: [String], answerIndex: Int,
         explanation: String) {
        self.id = id
        self.prompt = prompt
        self.tiles = tiles
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
    }
}

struct HandMatchQuestion: Identifiable, Sendable {
    let id: String
    let tiles: [PlayingCard]
    let choices: [HandCategory]
    let answer: HandCategory
    let explanation: String
}

struct DiscardScenario: Identifiable, Sendable {
    let id: String
    let situation: String
    let deal: [PlayingCard]
    let recommendedDiscard: [PlayingCard]
    let reasoning: String
    let tip: String
    /// The fail suit whose ace this scenario plans to call. A picker can only
    /// name an ace they were not dealt, and must keep one card of that suit,
    /// so `ContentValidityTests` enforces both rules against the deal.
    let calledSuit: Suit?
    /// True when the kept hand leaves no legal ace to call, which makes the
    /// scenario an alone decision rather than a partnership hand.
    let isAlone: Bool

    init(id: String, situation: String, deal: [PlayingCard], recommendedDiscard: [PlayingCard],
         reasoning: String, tip: String, calledSuit: Suit? = nil, isAlone: Bool = false) {
        self.id = id
        self.situation = situation
        self.deal = deal
        self.recommendedDiscard = recommendedDiscard
        self.reasoning = reasoning
        self.tip = tip
        self.calledSuit = calledSuit
        self.isAlone = isAlone
    }
}

enum DrillKind: Sendable {
    case flashcards([Flashcard])
    case quiz([QuizQuestion])
    case handMatch([HandMatchQuestion])
    case discard([DiscardScenario])

    var itemCount: Int {
        switch self {
        case .flashcards(let cards): return cards.count
        case .quiz(let questions): return questions.count
        case .handMatch(let questions): return questions.count
        case .discard(let scenarios): return scenarios.count
        }
    }
}

struct Drill: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let kind: DrillKind
    /// Extra practice sets inside an otherwise-free room. These are additions
    /// behind Sheepshead+, so the beginner set remains open to everyone.
    let isPlus: Bool

    init(id: String, title: String, subtitle: String, kind: DrillKind, isPlus: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.isPlus = isPlus
    }
}

struct Room: Identifiable, Sendable {
    let id: String
    let name: String
    let tagline: String
    let icon: String
    let isFree: Bool
    let drills: [Drill]

    var plusDrillCount: Int {
        isFree ? drills.filter(\.isPlus).count : drills.count
    }

    func isLocked(_ drill: Drill, isMember: Bool) -> Bool {
        guard !isMember else { return false }
        return !isFree || drill.isPlus
    }
}
