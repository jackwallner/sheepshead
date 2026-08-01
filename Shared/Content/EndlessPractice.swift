import Foundation

/// Generated practice skills. Each skill still becomes the same QuickItem
/// shape used by authored drills, so the runner never cares where a question
/// came from.
enum PracticeSkill: String, CaseIterable, Identifiable, Sendable {
    case handReading
    case trickPlay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .handReading: return "Read the Holding"
        case .trickPlay: return "Read the Trump"
        }
    }

    var subtitle: String {
        switch self {
        case .handReading: return "Fresh five-card holdings, unlimited reps"
        case .trickPlay: return "Classify cards before you play them"
        }
    }

    var icon: String {
        switch self {
        case .handReading: return "rectangle.portrait.on.rectangle.portrait.angled"
        case .trickPlay: return "crown.fill"
        }
    }

    var roomID: String {
        switch self {
        case .handReading: return "trump-room"
        case .trickPlay: return "trick-room"
        }
    }

    var itemPrefix: String { "gen-\(rawValue)-" }

    static func skill(forItemID id: String) -> PracticeSkill? {
        allCases.first { id.hasPrefix($0.itemPrefix) }
    }
}

enum EndlessPractice {
    static func drill(for skill: PracticeSkill) -> Drill {
        Drill(id: "endless-\(skill.rawValue)", title: skill.title, subtitle: skill.subtitle, kind: .quiz([]))
    }

    static let challengeDrill = Drill(
        id: "timed-challenge",
        title: "Timed Challenge",
        subtitle: "Beat the clock with mixed card reads",
        kind: .quiz([])
    )

    static func items(for skill: PracticeSkill, count: Int) -> [QuickItem] {
        switch skill {
        case .handReading: return handItems(count: count)
        case .trickPlay: return trickItems(count: count)
        }
    }

    static func mixedItems(count: Int) -> [QuickItem] {
        guard count > 0 else { return [] }
        let skills = PracticeSkill.allCases
        let perSkill = max(1, count / skills.count + 1)
        return skills.flatMap { items(for: $0, count: perSkill) }.shuffled().prefix(count).map { $0 }
    }

    private static func handItems(count: Int) -> [QuickItem] {
        HandGenerator.batch(count: count).map { hand in
            let labels = hand.choices.map(\.displayName)
            let answerIndex = hand.choices.firstIndex(of: hand.answer) ?? 0
            return QuickItem(
                id: PracticeSkill.handReading.itemPrefix + UUID().uuidString,
                prompt: "Which rule should you spot first?",
                tiles: hand.tiles,
                choices: labels,
                answerIndex: answerIndex,
                explanation: hand.explanation,
                sourceLabel: "Endless Practice",
                roomID: PracticeSkill.handReading.roomID
            )
        }
    }

    private static func trickItems(count: Int) -> [QuickItem] {
        let deck = PlayingCard.sheepsheadDeck
        return (0..<max(0, count)).compactMap { _ in
            guard let card = deck.randomElement() else { return nil }
            let choices = ["Trump", "Fail card", "Not in the deck"]
            let answerIndex = card.isTrump ? 0 : 1
            let explanation = card.isTrump
                ? "\(card.spokenName) is trump because every queen, every jack, and every diamond is trump."
                : "\(card.spokenName) is a fail card because it is not a queen, jack, or diamond. It follows its printed suit."
            return QuickItem(
                id: PracticeSkill.trickPlay.itemPrefix + UUID().uuidString,
                prompt: "How should you classify the \(card.spokenName) before play?",
                tiles: [card],
                choices: choices,
                answerIndex: answerIndex,
                explanation: explanation,
                sourceLabel: "Endless Practice",
                roomID: PracticeSkill.trickPlay.roomID
            )
        }
    }
}
