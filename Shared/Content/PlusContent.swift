import Foundation

/// Sheepshead+ adds volume without changing the beginner rooms.
enum PlusContent {
    static let cardExtras: [QuizQuestion] = [
        QuizQuestion(
            id: "plus-card-1",
            prompt: "Which card is the highest trump?",
            tiles: [.c(12), .s(12), .d(14)],
            choices: ["Queen of clubs", "Queen of spades", "Ace of diamonds"],
            answerIndex: 0,
            explanation: "The queen of clubs tops the queen order, then queen of spades, queen of hearts, and queen of diamonds."
        ),
        QuizQuestion(
            id: "plus-card-2",
            prompt: "How many points does the queen of diamonds carry?",
            tiles: [.d(12)],
            choices: ["2", "3", "12"],
            answerIndex: 1,
            explanation: "Queens carry 3 points, even though their printed ranks are not used as fail-suit strength."
        ),
        QuizQuestion(
            id: "plus-card-3",
            prompt: "Which of these is a low fail card?",
            choices: ["Jack of hearts", "8 of spades", "9 of diamonds"],
            answerIndex: 1,
            explanation: "The jack is permanent trump and the diamond is trump. The 8 of spades is a zero-point fail card."
        ),
        QuizQuestion(
            id: "plus-card-4",
            prompt: "How many cards does the picker bury after taking the blind?",
            choices: ["1", "2", "3"],
            answerIndex: 1,
            explanation: "The picker starts with eight cards after taking the blind, then buries two and plays six."
        ),
        QuizQuestion(
            id: "plus-card-5",
            prompt: "Which card carries 11 points?",
            tiles: [.c(14), .d(13), .h(12)],
            choices: ["Ace", "King", "Queen"],
            answerIndex: 0,
            explanation: "An ace carries 11 points. Kings carry 4 and queens carry 3."
        ),
        QuizQuestion(
            id: "plus-card-6",
            prompt: "What is the common five-player hand size?",
            choices: ["5 cards", "6 cards", "8 cards"],
            answerIndex: 1,
            explanation: "Each of the five players receives six cards, with two cards left in the blind."
        ),
    ]

    static let extraHandReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "plus-hand-1",
            tiles: [.c(12), .s(11), .d(8), .d(7), .h(9)],
            choices: [.trumpStack, .lowCards, .pointCards],
            answer: .trumpStack,
            explanation: "The queen, jack, and both diamonds are trump. The heart 9 is the only fail card shown."
        ),
        HandMatchQuestion(
            id: "plus-hand-2",
            tiles: [.c(7), .c(8), .c(9), .c(10), .c(13)],
            choices: [.failSuit, .pointCards, .trickTaking],
            answer: .failSuit,
            explanation: "This is a complete club fail holding from 7 through king. The club queen and jack are trump and are not in the fail suit."
        ),
        HandMatchQuestion(
            id: "plus-hand-3",
            tiles: [.c(14), .h(10), .s(13), .c(10), .s(14)],
            choices: [.pointCards, .lowCards, .trumpStack],
            answer: .pointCards,
            explanation: "Every card in the holding carries points, but none is permanent trump. Winning those fail suits is the challenge."
        ),
        HandMatchQuestion(
            id: "plus-hand-4",
            tiles: [.c(7), .h(8), .s(9), .c(8), .s(7)],
            choices: [.lowCards, .failSuit, .scoring],
            answer: .lowCards,
            explanation: "All five cards are zero-point fail cards. The hand is about following cheaply, not immediate scoring."
        ),
        HandMatchQuestion(
            id: "plus-hand-5",
            tiles: [.h(14), .h(7), .d(10), .c(9), .s(8)],
            choices: [.partnership, .trumpStack, .pointCards],
            answer: .partnership,
            explanation: "The heart ace and heart 7 show the required hold-card pattern if the picker calls the heart ace."
        ),
        HandMatchQuestion(
            id: "plus-hand-6",
            tiles: [.c(12), .s(12), .h(12), .d(12), .d(9)],
            choices: [.picking, .lowCards, .failSuit],
            answer: .picking,
            explanation: "Four queens are the strongest possible trump core and make a serious alone discussion."
        ),
    ]

    static let extraDiscards: [DiscardScenario] = [
        DiscardScenario(
            id: "plus-bury-1",
            situation: "Keep three trumps and a fail ace. Choose the two cards to bury.",
            deal: [.c(12), .s(11), .d(10), .c(14), .h(8), .s(7), .c(13), .d(8)],
            recommendedDiscard: [.h(8), .s(7)],
            reasoning: "The three trump cards give control, and the club ace can win a fail trick and bring points. The low cards carry no points and do not improve the plan.",
            tip: "Preserve a fail winner when your trump is not yet a full lock."
        ),
        DiscardScenario(
            id: "plus-bury-2",
            situation: "You call the spade ace. Leave a spade hold card in the final hand.",
            deal: [.d(12), .d(9), .s(14), .s(7), .h(10), .c(8), .h(7), .c(9)],
            recommendedDiscard: [.h(10), .c(8)],
            reasoning: "The spade ace and spade 7 satisfy the called-suit hold, while the two diamonds are trump. Burying the heart 10 and club 8 keeps the partnership line legal and the trump count healthy.",
            tip: "The hold card can be low. It only needs to belong to the called fail suit."
        ),
        DiscardScenario(
            id: "plus-bury-3",
            situation: "Your best cards are three fail aces. Choose two zero cards to bury.",
            deal: [.c(14), .h(14), .s(14), .d(8), .c(7), .h(9), .s(8), .d(7)],
            recommendedDiscard: [.c(7), .h(9)],
            reasoning: "The three fail aces hold the hand's point value. The diamond 8 is still trump and may win a late trick, so the two zero-point fail cards are the cleanest bury.",
            tip: "A zero-point diamond can still be a trump winner."
        ),
        DiscardScenario(
            id: "plus-bury-4",
            situation: "You have the queen of clubs and several weak cards. Choose two to bury.",
            deal: [.c(12), .d(14), .d(7), .h(13), .s(9), .c(8), .h(14), .s(7)],
            recommendedDiscard: [.s(9), .c(8)],
            reasoning: "The queen of clubs is the top trump and both diamonds are trump. The heart king is a point card and the low fail cards are the least useful cards to keep.",
            tip: "Keep the card that can win the point trick, not only the card with the best label."
        ),
    ]

    static let extraJudgment: [Flashcard] = [
        Flashcard(
            id: "plus-trick-1",
            frontTitle: "A diamond is led",
            frontTiles: [.d(10), .d(7), .c(12)],
            frontSubtitle: "Trump is led",
            backTitle: "Play trump if you have it",
            backBody: "A diamond lead is a trump lead. Any queen, jack, or diamond follows trump, and the strongest trump wins the trick.",
            choice: CardChoice("Play a trump", "Play a heart", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-trick-2",
            frontTitle: "The club ace is led",
            frontTiles: [.c(14), .d(7), .h(10)],
            frontSubtitle: "You have no clubs",
            backTitle: "Choose freely",
            backBody: "Without a club, you may play a diamond, a queen, a jack, or another fail card. A diamond can take the trick, but spending it may not be right.",
            choice: CardChoice("Any card", "Only another ace", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-trick-3",
            frontTitle: "The partner is exposed",
            frontTiles: [.s(14), .c(12), .d(9)],
            frontSubtitle: "Information changes the lead",
            backTitle: "Use the known side",
            backBody: "Once the called ace is played, you know one teammate. Leads can now protect that player or send points toward the picking side.",
            choice: CardChoice("Adjust the plan", "Ignore the reveal", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-trick-4",
            frontTitle: "The picking team has 60",
            frontSubtitle: "One point from a basic win",
            backTitle: "Every point card matters",
            backBody: "The next captured point makes 61. A zero-point trick can still change the lead, but do not lose sight of the immediate score line.",
            choice: CardChoice("Protect the point", "Chase only empty tricks", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-trick-5",
            frontTitle: "A queen is still hidden",
            frontTiles: [.c(12), .d(8), .h(14)],
            frontSubtitle: "Count live trump",
            backTitle: "Remember what has not appeared",
            backBody: "If a higher queen or jack is still unseen, a low diamond is not automatically safe. Card memory keeps a winning line honest.",
            choice: CardChoice("Track unseen trump", "Assume low trump wins", answerIndex: 0)
        ),
    ]
}
