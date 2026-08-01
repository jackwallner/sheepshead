import Foundation

/// The Master Tables: advanced picker, partner, and trick decisions.
enum ProContent {
    static let advancedDiscard: [DiscardScenario] = [
        DiscardScenario(
            id: "master-bury-1",
            situation: "You picked with two queens and a fail ace. Preserve the called-suit line while choosing two cards.",
            deal: [.c(12), .s(12), .h(14), .h(7), .d(9), .c(8), .d(10), .s(13)],
            recommendedDiscard: [.c(8), .h(7)],
            reasoning: "Keep both queens, the heart ace, and the diamond 9. The heart 7 is a legal hold card if hearts is called, but this line values the ace as the fail winner and removes both low cards from the final hand.",
            tip: "Advanced burying starts with the partnership rule, then weighs trick control."
        ),
        DiscardScenario(
            id: "master-bury-2",
            situation: "You have three queens and a diamond ace. The table is close. Choose two cards to bury.",
            deal: [.c(12), .s(12), .h(12), .d(14), .c(10), .s(7), .d(8), .h(9)],
            recommendedDiscard: [.c(10), .s(7)],
            reasoning: "The three queens and diamond ace form a powerful trump core. The club 10 is a point card, but the table position favors keeping the trump winners and burying the less certain fail cards.",
            tip: "When the board is tight, certain control can beat a speculative point card."
        ),
        DiscardScenario(
            id: "master-bury-3",
            situation: "You have no queen or jack, but three fail aces and a diamond 7. Choose two cards.",
            deal: [.c(14), .h(14), .s(14), .d(7), .c(8), .h(9), .s(8), .d(10)],
            recommendedDiscard: [.c(8), .h(9)],
            reasoning: "The three fail aces carry 33 points and may take their suits. The diamond 7 is low trump and can still win a late trick. The two remaining low fail cards do not carry points or improve the partnership plan.",
            tip: "A low trump is a resource when all opposing fail cards are exhausted."
        ),
        DiscardScenario(
            id: "master-bury-4",
            situation: "You are weighing a solo attempt with all four queens. Choose the cleanest bury.",
            deal: [.c(12), .s(12), .h(12), .d(12), .d(10), .h(8), .d(9), .c(7)],
            recommendedDiscard: [.d(10), .h(8)],
            reasoning: "The four queens are the highest trumps and are the foundation of a solo plan. The diamond 10 adds points but is lower in trump strength, while the heart 8 is a zero-point fail card.",
            tip: "The table's solo scoring rules must be agreed before you use this line."
        ),
    ]

    static let defenseQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "master-defense-1",
            prompt: "The picker names the ace of hearts. Which card must the picker retain?",
            tiles: [.h(14), .h(8), .d(12)],
            choices: ["A heart fail card", "Any queen", "The ace of clubs"],
            answerIndex: 0,
            explanation: "The common call-an-ace rule requires the picker to hold a card from the called fail suit."
        ),
        QuizQuestion(
            id: "master-defense-2",
            prompt: "A diamond 7 is played against a club ace. Which statement is true?",
            tiles: [.d(7), .c(14)],
            choices: ["The diamond 7 is trump", "The club ace must win", "The cards have equal strength"],
            answerIndex: 0,
            explanation: "Every diamond is trump, so even the diamond 7 beats a fail ace when it is legal to play."
        ),
        QuizQuestion(
            id: "master-defense-3",
            prompt: "Why track the queens and jacks already played?",
            choices: ["To estimate the trump still live", "To change their point value", "To identify the dealer"],
            answerIndex: 0,
            explanation: "Permanent trump is finite. Knowing what has appeared tells you whether a low diamond can realistically win."
        ),
        QuizQuestion(
            id: "master-defense-4",
            prompt: "Your side has 59 points. Which capture changes the basic result?",
            choices: ["A 2-point jack", "A zero-point 7", "A second trick with no points"],
            answerIndex: 0,
            explanation: "The picking team needs 61. Any captured point card worth at least 2 crosses the basic majority line."
        ),
        QuizQuestion(
            id: "master-defense-5",
            prompt: "The called ace has not appeared. What should you assume about its holder?",
            choices: ["The partner may be hidden anywhere at the table", "The dealer must hold it", "The picker holds it"],
            answerIndex: 0,
            explanation: "The partner is silent until the called ace is played. Do not reveal or assume the partnership early."
        ),
        QuizQuestion(
            id: "master-defense-6",
            prompt: "What is the strongest general defense against a trump lead?",
            choices: ["Follow trump when required and track what is spent", "Always throw a point card", "Ignore the trick winner"],
            answerIndex: 0,
            explanation: "Trump management is an information problem. Follow legally, preserve useful winners, and update the live-trump count."
        ),
    ]

    static let expertHandReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "master-hand-1",
            tiles: [.c(12), .s(12), .d(14), .d(10), .c(14)],
            choices: [.picking, .pointCards, .lowCards],
            answer: .picking,
            explanation: "Three high trumps plus a diamond ace and club ace create a strong blind-taking shape with both control and points."
        ),
        HandMatchQuestion(
            id: "master-hand-2",
            tiles: [.c(14), .h(14), .s(14), .c(10), .h(13)],
            choices: [.pointCards, .failSuit, .scoring],
            answer: .scoring,
            explanation: "The three fail aces and two additional point cards make this a scoring read. The hard part is turning fail points into captured tricks."
        ),
        HandMatchQuestion(
            id: "master-hand-3",
            tiles: [.c(12), .s(11), .d(9), .h(8), .c(7)],
            choices: [.trumpStack, .strategy, .lowCards],
            answer: .strategy,
            explanation: "Two strong trumps, a low diamond, and two low fail cards create a strategy question. The hand is about which suit to control and which card to keep as a hold."
        ),
        HandMatchQuestion(
            id: "master-hand-4",
            tiles: [.h(14), .h(10), .h(13), .h(9), .h(7)],
            choices: [.failSuit, .pointCards, .trumpStack],
            answer: .failSuit,
            explanation: "This is the full heart fail suit. The heart queen and jack are absent because both are permanent trump."
        ),
        HandMatchQuestion(
            id: "master-hand-5",
            tiles: [.c(12), .s(12), .h(12), .d(12), .d(7)],
            choices: [.picking, .trumpStack, .lowCards],
            answer: .trumpStack,
            explanation: "All five cards are trump and four of them are the highest trumps in the deck. This is the purest possible control shape."
        ),
        HandMatchQuestion(
            id: "master-hand-6",
            tiles: [.c(7), .h(8), .s(9), .d(8), .c(10)],
            choices: [.strategy, .lowCards, .pointCards],
            answer: .strategy,
            explanation: "The holding has low fail cards, a low trump, and one club 10. It needs a plan for following, not a simple point count."
        ),
        HandMatchQuestion(
            id: "master-hand-7",
            tiles: [.c(14), .c(7), .d(12), .h(10), .s(9)],
            choices: [.partnership, .picking, .scoring],
            answer: .partnership,
            explanation: "The club ace and club 7 give a legal hold pattern for a club-ace call, while the queen provides trump support."
        ),
        HandMatchQuestion(
            id: "master-hand-8",
            tiles: [.d(14), .d(13), .d(9), .d(8), .c(12)],
            choices: [.trickTaking, .pointCards, .failSuit],
            answer: .trickTaking,
            explanation: "The holding contains five trump cards with a mix of strength and point value. The advanced question is how to spend them across tricks."
        ),
    ]
}
