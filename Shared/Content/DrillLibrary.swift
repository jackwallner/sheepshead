import Foundation

enum DrillLibrary {
    static let rooms: [Room] = [
        Room(
            id: "card-room",
            name: "The Card Room",
            tagline: "Meet the 32-card deck and its vocabulary",
            icon: "rectangle.portrait.on.rectangle.portrait.angled",
            isFree: true,
            drills: [
                Drill(
                    id: "meet-cards",
                    title: "Meet the Cards",
                    subtitle: "Flashcards: the deck, trump, points, and the blind",
                    kind: .flashcards(CardBasicsContent.meetTheCards)
                ),
                Drill(
                    id: "card-quiz",
                    title: "Card Check",
                    subtitle: "Quick quiz: the rules new players miss first",
                    kind: .quiz(CardBasicsContent.cardQuiz)
                ),
                Drill(
                    id: "plus-card-extras",
                    title: "Card Check: Extra Reps",
                    subtitle: "More deck, point, partner, and picker questions",
                    kind: .quiz(PlusContent.cardExtras + MoreContent.cardExtras),
                    isPlus: true
                ),
            ]
        ),
        Room(
            id: "trump-room",
            name: "The Trump Room",
            tagline: "Read strength, suits, and point value",
            icon: "crown.fill",
            isFree: true,
            drills: [
                Drill(
                    id: "trump-cards",
                    title: "Read the Cards",
                    subtitle: "Flashcards: permanent trump and fail-suit order",
                    kind: .flashcards(CategoryContent.categoryCards)
                ),
                Drill(
                    id: "hand-match",
                    title: "Read the Holding",
                    subtitle: "See five cards, name the rule to spot first",
                    kind: .handMatch(CategoryContent.handMatch)
                ),
                Drill(
                    id: "plus-hand-extras",
                    title: "Read the Holding: Extra Reps",
                    subtitle: "More hands with trump, points, and partnership clues",
                    kind: .handMatch(PlusContent.extraHandReading + MoreContent.handReading),
                    isPlus: true
                ),
            ]
        ),
        Room(
            id: "bury-room",
            name: "The Bury Room",
            tagline: "Take the blind and choose two cards to bury",
            icon: "arrow.down.to.line.circle.fill",
            isFree: true,
            drills: [
                Drill(
                    id: "bury-rules",
                    title: "Bury Playbook",
                    subtitle: "Flashcards: blind, hold cards, and picker plans",
                    kind: .flashcards(DiscardContent.strategyCards)
                ),
                Drill(
                    id: "bury-two",
                    title: "Choose Your Bury",
                    subtitle: "Eight-card holdings: choose two, then compare with the coach",
                    kind: .discard(DiscardContent.scenarios)
                ),
                Drill(
                    id: "plus-bury-extras",
                    title: "Choose Your Bury: Extra Reps",
                    subtitle: "More picker hands with points, trump, and hold cards",
                    kind: .discard(PlusContent.extraDiscards + MoreContent.discardExtras),
                    isPlus: true
                ),
            ]
        ),
        Room(
            id: "trick-room",
            name: "The Trick Room",
            tagline: "Follow legally and spend trump with a plan",
            icon: "arrow.up.right.circle.fill",
            isFree: true,
            drills: [
                Drill(
                    id: "trick-judgment",
                    title: "Trick Judgment",
                    subtitle: "Make the call, then flip to see the table read",
                    kind: .flashcards(KeepDiscardContent.judgmentCards)
                ),
                Drill(
                    id: "trick-quiz",
                    title: "Trick Rules",
                    subtitle: "Following suit, trump order, partners, and points",
                    kind: .quiz(MoreContent.tableQuiz)
                ),
                Drill(
                    id: "plus-trick-extras",
                    title: "Trick Judgment: Extra Reps",
                    subtitle: "More calls about leads, reveals, and score lines",
                    kind: .flashcards(PlusContent.extraJudgment + MoreContent.judgment),
                    isPlus: true
                ),
            ]
        ),
        Room(
            id: "pro-tables",
            name: "The Master Tables",
            tagline: "Advanced picker, partner, and table decisions",
            icon: "star.circle.fill",
            isFree: false,
            drills: [
                Drill(
                    id: "master-bury",
                    title: "Advanced Bury",
                    subtitle: "Blind value, hold cards, and table position together",
                    kind: .discard(ProContent.advancedDiscard)
                ),
                Drill(
                    id: "master-defense",
                    title: "Defense School",
                    subtitle: "Track live trump, partners, and the 61-point line",
                    kind: .quiz(ProContent.defenseQuiz)
                ),
                Drill(
                    id: "master-reading",
                    title: "Expert Holdings",
                    subtitle: "Read control, points, and partnership at once",
                    kind: .handMatch(ProContent.expertHandReading)
                ),
                Drill(
                    id: "master-rules",
                    title: "Master Rules",
                    subtitle: "The details that separate a legal play from a guess",
                    kind: .quiz(MoreContent.advancedRules)
                ),
            ]
        ),
    ]

    static func room(id: String) -> Room? {
        rooms.first { $0.id == id }
    }

    static func roomID(forDrillID drillID: String) -> String {
        rooms.first { $0.drills.contains { $0.id == drillID } }?.id ?? ""
    }
}
