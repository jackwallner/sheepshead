import Foundation

/// The Master Tables: advanced picker, partner, and trick decisions.
enum ProContent {
    static let advancedDiscard: [DiscardScenario] = [
        DiscardScenario(
            id: "master-bury-1",
            situation: "You plan to call the heart ace. Two clubs and two hearts are competing for the bury.",
            deal: [.c(12), .s(12), .d(10), .d(9), .h(13), .h(7), .c(14), .c(13)],
            recommendedDiscard: [.c(14), .c(13)],
            reasoning: "The club ace and king are 15 banked points and burying both empties clubs. Keeping both hearts means the called-ace hold survives even when you are forced to spend the heart king later, which the one-heart line cannot promise.",
            tip: "A single hold card is a liability. Keep two when the bury allows it.",
            calledSuit: .hearts
        ),
        DiscardScenario(
            id: "master-bury-2",
            situation: "Three queens and the diamond ace give you real control. Choose two cards to bury.",
            deal: [.c(12), .s(12), .h(12), .d(14), .d(8), .c(10), .c(13), .s(7)],
            recommendedDiscard: [.c(10), .c(13)],
            reasoning: "Burying the club 10 and king banks 14 points and empties clubs, which beats burying the lone spade for 10. The spade 7 is worth more as the hand's only hold card, since without it there is no ace left to call.",
            tip: "Count what the bury banks, then check that a legal call survives it."
        ),
        DiscardScenario(
            id: "master-bury-3",
            situation: "You were dealt all three fail aces and only two low trumps. Choose two cards to bury.",
            deal: [.c(14), .h(14), .s(14), .c(10), .h(9), .s(8), .d(10), .d(7)],
            recommendedDiscard: [.c(14), .c(10)],
            reasoning: "The club ace and 10 are 21 points that two low trumps will never protect, and burying both empties clubs. Holding every fail ace leaves no ace to name, so this is an alone hand.",
            tip: "A hand this thin in trump is often a pass. If you do pick, bank the points you cannot defend.",
            isAlone: true
        ),
        DiscardScenario(
            id: "master-bury-4",
            situation: "Six trumps including the four queens, plus one heart and one club. Choose two cards to bury.",
            deal: [.c(12), .s(12), .h(12), .d(12), .d(10), .d(9), .h(8), .c(7)],
            recommendedDiscard: [.h(8), .c(7)],
            reasoning: "Burying both fail cards leaves a hand of pure trump that can never be forced to follow a fail lead. It also leaves no card of any fail suit, so there is no legal hold card and the hand is played alone.",
            tip: "Agree the table's alone scoring before you take this line.",
            isAlone: true
        ),
    ]

    static let defenseQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "master-defense-1",
            prompt: "The picker names the ace of hearts. Which card must the picker retain?",
            tiles: [.h(8), .d(12)],
            choices: ["A heart fail card", "Any queen", "The ace of hearts"],
            answerIndex: 0,
            explanation: "The common call-an-ace rule requires the picker to hold a card from the called fail suit. The picker never holds the called ace itself, because you can only name an ace you were not dealt."
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
            choices: [.picking, .failSuit, .lowCards],
            answer: .picking,
            explanation: "Three high trumps plus a diamond ace and club ace create a strong blind-taking shape with both control and points."
        ),
        HandMatchQuestion(
            id: "master-hand-2",
            tiles: [.c(14), .h(14), .s(14), .c(10), .h(13)],
            choices: [.trumpStack, .failSuit, .scoring],
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
            explanation: "Every card is a heart fail card, missing only the heart 8. The heart queen and jack are absent because both are permanent trump."
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
            explanation: "You were dealt the club ace, so a club call makes you the silent partner rather than the picker. The queen of diamonds is the trump support you bring to that side."
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
