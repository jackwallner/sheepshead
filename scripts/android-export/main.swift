import Foundation

// Exports the iOS content and generator fixtures for the Android port.
// Run through scripts/sync-android-content.sh, never by hand.
//
//   content.json  every authored drill, the primer, the rule categories and
//                 the What's New notes, read by the app at runtime.
//   parity.json   card facts, seeded generator output and the daily
//                 challenge, read only by the Android unit tests to prove the
//                 Kotlin engine counts and deals exactly what iOS does.

func code(_ card: PlayingCard) -> String {
    switch card {
    case .standard(let rank, let suit): return "\(suit.rawValue.prefix(1).uppercased())\(rank)"
    case .joker: return "JK"
    }
}
func codes(_ cards: [PlayingCard]) -> [String] { cards.map(code) }

func flashcard(_ card: Flashcard) -> [String: Any] {
    var json: [String: Any] = [
        "id": card.id,
        "frontTitle": card.frontTitle,
        "frontTiles": codes(card.frontTiles),
        "backTitle": card.backTitle,
        "backBody": card.backBody,
    ]
    if let subtitle = card.frontSubtitle { json["frontSubtitle"] = subtitle }
    if let choice = card.choice {
        json["choice"] = ["options": choice.options, "answerIndex": choice.answerIndex]
    }
    return json
}

func quiz(_ question: QuizQuestion) -> [String: Any] {
    [
        "id": question.id,
        "prompt": question.prompt,
        "tiles": codes(question.tiles),
        "choices": question.choices,
        "answerIndex": question.answerIndex,
        "explanation": question.explanation,
    ]
}

func handMatch(_ question: HandMatchQuestion) -> [String: Any] {
    [
        "id": question.id,
        "tiles": codes(question.tiles),
        "choices": question.choices.map(\.rawValue),
        "answer": question.answer.rawValue,
        "explanation": question.explanation,
    ]
}

func discard(_ scenario: DiscardScenario) -> [String: Any] {
    [
        "id": scenario.id,
        "situation": scenario.situation,
        "deal": codes(scenario.deal),
        "recommendedDiscard": codes(scenario.recommendedDiscard),
        "reasoning": scenario.reasoning,
        "tip": scenario.tip,
        "calledSuit": scenario.calledSuit?.rawValue ?? NSNull(),
        "isAlone": scenario.isAlone,
    ]
}

func drill(_ drill: Drill) -> [String: Any] {
    var json: [String: Any] = [
        "id": drill.id,
        "title": drill.title,
        "subtitle": drill.subtitle,
        "isPlus": drill.isPlus,
    ]
    switch drill.kind {
    case .flashcards(let cards): json["kind"] = "flashcards"; json["items"] = cards.map(flashcard)
    case .quiz(let questions): json["kind"] = "quiz"; json["items"] = questions.map(quiz)
    case .handMatch(let questions): json["kind"] = "handMatch"; json["items"] = questions.map(handMatch)
    case .discard(let scenarios): json["kind"] = "discard"; json["items"] = scenarios.map(discard)
    }
    return json
}

func content() -> [String: Any] {
    let rooms: [[String: Any]] = DrillLibrary.rooms.map { room in
        [
            "id": room.id,
            "name": room.name,
            "tagline": room.tagline,
            "icon": room.icon,
            "isFree": room.isFree,
            "drills": room.drills.map(drill),
        ]
    }
    let categories: [[String: Any]] = HandCategory.allCases.map { category in
        [
            "id": category.rawValue,
            "displayName": category.displayName,
            "shortName": category.shortName,
            "howToSpot": category.howToSpot,
        ]
    }
    let primer: [[String: Any]] = HowToPlayContent.pages.map { page in
        var json: [String: Any] = [
            "id": page.id, "icon": page.icon, "title": page.title, "body": page.body, "tiles": codes(page.tiles),
        ]
        if let tip = page.tip { json["tip"] = tip }
        return json
    }
    // The iPad line is Apple-only; Android has no iPad layout to announce.
    let whatsNew: [[String: Any]] = WhatsNew.releases.map { release in
        [
            "version": release.version,
            "headline": release.headline,
            "items": release.items.filter { $0.id != "ipad" }.map { item in
                ["id": item.id, "icon": item.icon, "title": item.title, "body": item.body, "isPlus": item.isPlus]
            },
        ]
    }
    return [
        "rooms": rooms,
        "categories": categories,
        "primer": primer,
        "whatsNew": whatsNew,
    ]
}

// MARK: - Parity fixtures

func quickItem(_ item: QuickItem) -> [String: Any] {
    [
        "id": item.id,
        "prompt": item.prompt,
        "tiles": codes(item.tiles),
        "choices": item.choices,
        "answerIndex": item.answerIndex,
        "explanation": item.explanation,
        "sourceLabel": item.sourceLabel,
        "roomID": item.roomID,
        "trackingID": item.trackingID,
        "isReviewable": item.isReviewable,
    ]
}

func parity() -> [String: Any] {
    let seeds = ["alpha", "sheepshead-minute-2026-09-30-hands", "card-quiz-3", "", "Picker"]
    var streams: [String: [String]] = [:]
    for seed in seeds {
        var generator = StableSeededGenerator(seed: seed)
        streams[seed] = (0..<8).map { _ in String(generator.next()) }
    }
    var permutations: [String: [Int]] = [:]
    for seed in seeds {
        for count in [2, 3, 4, 7, 13] {
            permutations["\(seed)|\(count)"] = ChoiceShuffle.permutation(count: count, seed: seed)
        }
    }

    var hands: [String: Any] = [:]
    for seed in ["h1", "h2", "daily-2026-10-01", "sheepshead-minute-2026-10-16-hands"] {
        hands[seed] = HandGenerator.batch(count: 7, seed: seed).map { hand in
            [
                "tiles": codes(hand.tiles),
                "answer": hand.answer.rawValue,
                "choices": hand.choices.map(\.rawValue),
                "explanation": hand.explanation,
            ] as [String: Any]
        }
    }

    // Every card's trump, fail and point facts, so the Kotlin deck is held to
    // the Swift one card by card.
    let cards: [[String: Any]] = PlayingCard.sheepsheadDeck.map { card in
        [
            "code": code(card),
            "isTrump": card.isTrump,
            "isFail": card.isFail,
            "isFailAce": card.isFailAce,
            "pointValue": card.pointValue,
            "trumpStrength": card.trumpStrength,
            "failStrength": card.failStrength,
            "sortKey": card.sortKey,
            "shortLabel": card.shortLabel,
            "spokenName": card.spokenName,
        ]
    }

    // Seeded random five-card holdings classified every way the generator can,
    // so the Kotlin rule shapes are held to the Swift ones on hundreds of deals.
    var reads: [[String: Any]] = []
    var dealer = StableSeededGenerator(seed: "category-parity")
    for _ in 0..<300 {
        let holding = Array(PlayingCard.sheepsheadDeck.shuffled(using: &dealer).prefix(5))
        reads.append([
            "cards": codes(holding),
            "category": HandGenerator.category(for: holding)?.rawValue ?? NSNull(),
            "fits": HandGenerator.generatableCategories.filter { HandGenerator.fits(holding, $0) }.map(\.rawValue),
            "racked": codes(holding.racked),
        ])
    }

    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    var minutes: [String: Any] = [:]
    for day in ["2026-09-30", "2026-10-01", "2027-01-15", "2026-02-28", "2026-10-16"] {
        let parts = day.split(separator: "-").map { Int($0)! }
        let date = utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))!
        let challenge = SheepsheadMinuteContent.challenge(for: date, calendar: utc)
        minutes[day] = [
            "shortDate": challenge.shortDate,
            "questions": challenge.questions.map { ["category": $0.category.rawValue, "item": quickItem($0.item)] },
        ]
    }

    let roomIDs = DrillLibrary.rooms.map(\.id)
    let memberPool = roomIDs.flatMap { SessionBuilder.choiceItems(in: $0, includePro: true) }
    let freePool = roomIDs.flatMap { SessionBuilder.choiceItems(in: $0, includePro: false) }

    return [
        "streams": streams,
        "permutations": permutations,
        "hands": hands,
        "cards": cards,
        "reads": reads,
        "minutes": minutes,
        "memberPool": memberPool.map { quickItem(SessionBuilder.prepared($0)) },
        "freePoolIDs": freePool.map(\.id),
        "drillCounts": Dictionary(uniqueKeysWithValues: DrillLibrary.rooms.flatMap(\.drills).map { ($0.id, $0.kind.itemCount) }),
        "lockedDrillCount": DrillLibrary.rooms.reduce(0) { $0 + $1.plusDrillCount },
    ]
}

func write(_ object: Any, to path: String) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    try data.write(to: URL(fileURLWithPath: path))
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write("usage: export <content.json> <parity.json>\n".data(using: .utf8)!)
    exit(2)
}
try write(content(), to: arguments[1])
try write(parity(), to: arguments[2])
