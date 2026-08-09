import Foundation

enum SheepsheadMinuteCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case handReading
    case burying
    case trickPlay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .handReading: return "Hand Reading"
        case .burying: return "The Bury"
        case .trickPlay: return "Trick Play"
        }
    }

    var icon: String {
        switch self {
        case .handReading: return "rectangle.on.rectangle.angled"
        case .burying: return "arrow.down.circle.fill"
        case .trickPlay: return "hand.point.up.left.fill"
        }
    }
}

struct SheepsheadMinuteQuestion: Sendable {
    let category: SheepsheadMinuteCategory
    let item: QuickItem
}

struct SheepsheadMinuteChallenge: Identifiable, Sendable {
    let day: Date
    let dayKey: String
    let shortDate: String
    let questions: [SheepsheadMinuteQuestion]

    var id: String { dayKey }
    var items: [QuickItem] { questions.map(\.item) }
}

/// One shared five-question set per calendar date: two generated hand reads, one bury decision, and two trick calls. Hands are dealt procedurally from the same classifier that grades Endless Practice; the bury and trick questions come from the app's authored teaching content. The day key is the whole protocol, so there is no account, no server, and no leaderboard.
enum SheepsheadMinuteContent {
    static let questionCount = 5

    static let drill = Drill(
        id: "sheepshead-minute",
        title: "Sheepshead Minute",
        subtitle: "Today's shared five-question challenge",
        kind: .quiz([]),
        isPlus: true
    )

    static func challenge(for day: Date = Date(), calendar: Calendar = .current) -> SheepsheadMinuteChallenge {
        let dayKey = key(for: day, calendar: calendar)
        let generated = generatedQuestions(dayKey: dayKey)
        let middle = buryQuestion(dayKey: dayKey).map { [$0] } ?? []
        let last = roomQuestions(dayKey: dayKey, roomID: "trick-room", category: .trickPlay, count: 2)

        // Interleaved so the run does not read as three separate quizzes.
        var questions: [SheepsheadMinuteQuestion] = []
        if let first = generated.first { questions.append(first) }
        questions += middle
        if let firstLast = last.first { questions.append(firstLast) }
        if generated.count > 1 { questions.append(generated[1]) }
        if last.count > 1 { questions.append(last[1]) }

        let parts = calendar.dateComponents([.month, .day], from: day)
        let shortDate = String(format: "%02d/%02d", parts.month ?? 1, parts.day ?? 1)
        return SheepsheadMinuteChallenge(day: day, dayKey: dayKey, shortDate: shortDate, questions: questions)
    }

    static func key(for day: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 1970,
            parts.month ?? 1,
            parts.day ?? 1
        )
    }

    private static func generatedQuestions(dayKey: String) -> [SheepsheadMinuteQuestion] {
        let hands = HandGenerator.batch(count: 2, seed: "sheepshead-minute-\(dayKey)-hands")
        return hands.enumerated().map { index, hand in
            let labels = hand.choices.map(\.displayName)
            let answerIndex = hand.choices.firstIndex(of: hand.answer) ?? 0
            let item = QuickItem(
                id: PracticeSkill.handReading.itemPrefix + "minute-\(dayKey)-\(index)",
                prompt: "What is this hand worth?",
                tiles: hand.tiles,
                choices: labels,
                answerIndex: answerIndex,
                explanation: hand.explanation,
                sourceLabel: "Sheepshead Minute: Hand Read",
                roomID: PracticeSkill.handReading.roomID,
                trackingID: PracticeSkill.handReading.rawValue,
                isReviewable: false
            )
            return SheepsheadMinuteQuestion(category: .handReading, item: SessionBuilder.prepared(item))
        }
    }

    /// Built straight from the authored scenarios rather than through
    /// `SessionBuilder.choiceItems`. The quick-session pool deliberately
    /// excludes these drills because picking cards out of a hand is not a
    /// uniform choice flow, so drawing the daily from the pool silently
    /// produced a four-question challenge with this skill missing entirely.
    /// The same scenario reads fine as a labelled choice of card pairs.
    private static func buryQuestion(dayKey: String) -> SheepsheadMinuteQuestion? {
        let scenarios = DrillLibrary.rooms.flatMap { room in
            room.drills.flatMap { drill -> [DiscardScenario] in
                if case .discard(let values) = drill.kind { return values }
                return []
            }
        }
        guard !scenarios.isEmpty else { return nil }

        var generator = StableSeededGenerator(seed: "sheepshead-minute-\(dayKey)-bury")
        let scenario = scenarios[Int(generator.next() % UInt64(scenarios.count))]
        let answer = label(scenario.recommendedDiscard)
        let distractors = distractorLabels(for: scenario, dayKey: dayKey, answer: answer)
        guard distractors.count >= 2 else { return nil }

        let item = QuickItem(
            id: "sheepshead-minute-bury-\(dayKey)",
            prompt: "\(scenario.situation) Which two cards do you bury?",
            tiles: scenario.deal,
            choices: [answer] + distractors,
            answerIndex: 0,
            explanation: scenario.reasoning,
            sourceLabel: "Sheepshead Minute: The Bury",
            roomID: "bury-room",
            trackingID: "sheepshead-minute-bury",
            isReviewable: false
        )
        return SheepsheadMinuteQuestion(category: .burying, item: SessionBuilder.prepared(item))
    }

    /// Every other pair from the same deal, so a wrong answer is always a real
    /// alternative the player could have chosen rather than an obvious dud.
    private static func distractorLabels(
        for scenario: DiscardScenario,
        dayKey: String,
        answer: String
    ) -> [String] {
        var labels: Set<String> = []
        for first in 0..<max(0, scenario.deal.count - 1) {
            for second in (first + 1)..<scenario.deal.count {
                labels.insert(label([scenario.deal[first], scenario.deal[second]]))
            }
        }
        labels.remove(answer)
        let sorted = labels.sorted()
        let order = ChoiceShuffle.permutation(count: sorted.count, seed: "sheepshead-minute-\(dayKey)-bury-choices")
        return order.prefix(3).map { sorted[$0] }
    }

    private static func label(_ cards: [PlayingCard]) -> String {
        cards.map(\.spokenName).joined(separator: ", ")
    }

    /// Authored questions drawn from one room, picked by a permutation of the
    /// day key so the same date always yields the same questions for everyone.
    private static func roomQuestions(
        dayKey: String,
        roomID: String,
        category: SheepsheadMinuteCategory,
        count: Int
    ) -> [SheepsheadMinuteQuestion] {
        let pool = SessionBuilder.choiceItems(in: roomID, includePro: true)
        guard !pool.isEmpty else { return [] }
        let indices = ChoiceShuffle.permutation(count: pool.count, seed: "sheepshead-minute-\(dayKey)-\(roomID)")
        return indices.prefix(count).map { index in
            SheepsheadMinuteQuestion(category: category, item: SessionBuilder.prepared(pool[index]))
        }
    }
}
