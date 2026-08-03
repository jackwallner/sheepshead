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
            tiles: [.c(12), .s(11), .d(8), .d(7), .h(12)],
            choices: [.trumpStack, .lowCards, .pointCards],
            answer: .trumpStack,
            explanation: "Every card here is trump. Two queens and a jack are permanent trump, and the 8 and 7 of diamonds are trump because every diamond is."
        ),
        HandMatchQuestion(
            id: "plus-hand-2",
            tiles: [.c(7), .c(8), .c(9), .c(10), .c(13)],
            choices: [.failSuit, .pointCards, .trickTaking],
            answer: .failSuit,
            explanation: "Every card is a club fail card, running 7 up to the king. Only the club ace is missing, and the club queen and jack are trump rather than clubs."
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
            explanation: "This is the partner's shape. If the picker names the heart ace, the player who was dealt it plays with the picker, and the heart 7 is the card that follows the reveal."
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
            situation: "You picked with four trumps, two clubs, and two hearts. Choose two cards to bury.",
            deal: [.c(12), .s(11), .d(10), .d(8), .c(14), .c(13), .h(8), .h(7)],
            recommendedDiscard: [.c(14), .c(13)],
            reasoning: "The club ace and king are 15 points that no opponent can ever capture once they are face down, and burying both empties clubs for a later trump. Every trump stays, and the two hearts leave a hold card for calling the heart ace.",
            tip: "The best bury usually banks points and empties a suit in the same move."
        ),
        DiscardScenario(
            id: "plus-bury-2",
            situation: "You plan to call the spade ace, so a spade has to stay. Choose two cards to bury.",
            deal: [.d(12), .d(9), .s(13), .s(7), .h(10), .c(8), .h(7), .c(9)],
            recommendedDiscard: [.h(10), .h(7)],
            reasoning: "Burying both hearts banks the heart 10 and empties the suit. Both spades stay, so the called-ace hold is never in doubt, and the queen and 9 of diamonds keep your trump intact.",
            tip: "The hold card can be low. It only needs to belong to the called fail suit.",
            calledSuit: .spades
        ),
        DiscardScenario(
            id: "plus-bury-3",
            situation: "You picked with two queens, two diamonds, three spades, and a lone heart. Choose two cards to bury.",
            deal: [.c(12), .h(12), .d(11), .d(10), .s(13), .s(9), .s(8), .h(7)],
            recommendedDiscard: [.h(7), .s(13)],
            reasoning: "The lone heart goes so hearts are empty, and the spade king rides along to bank 4 points. Two spades still remain, so you keep a legal hold card if you name the spade ace.",
            tip: "Empty the suit you hold once, not the suit you hold three times."
        ),
        DiscardScenario(
            id: "plus-bury-4",
            situation: "Two queens, two diamonds, and two singleton point cards. Choose two cards to bury.",
            deal: [.c(12), .s(12), .d(11), .d(9), .h(10), .s(13), .c(9), .c(8)],
            recommendedDiscard: [.h(10), .s(13)],
            reasoning: "Both singletons go. That banks 14 points and empties hearts and spades, so only clubs can still be led at you, and the two clubs keep a legal hold card for calling the club ace.",
            tip: "Two singletons can empty two suits with one bury."
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
