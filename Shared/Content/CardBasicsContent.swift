import Foundation

/// The Card Room: the vocabulary a new player needs before the first hand.
enum CardBasicsContent {
    static let meetTheCards: [Flashcard] = [
        Flashcard(
            id: "cards-deck",
            frontTitle: "The Sheepshead deck",
            frontSubtitle: "Start with the shape of the game",
            backTitle: "32 cards, not 52",
            backBody: "Sheepshead uses the 7 through ace of each suit. That makes 32 cards. In the common five-player game, each player receives six cards and two cards form the blind.",
            choice: CardChoice("32 cards", "52 cards", answerIndex: 0)
        ),
        Flashcard(
            id: "cards-trump",
            frontTitle: "What is trump?",
            frontTiles: [.c(12), .s(11), .d(14)],
            frontSubtitle: "The first rule to make automatic",
            backTitle: "Every queen, every jack, and every diamond",
            backBody: "The four queens, four jacks, and six diamonds are permanent trump. Their printed suits do not behave like fail suits once they are trump.",
            choice: CardChoice("Queens, jacks, and diamonds", "Diamonds only", answerIndex: 0)
        ),
        Flashcard(
            id: "cards-queens-jacks",
            frontTitle: "Permanent trump",
            frontTiles: [.c(12), .s(12), .h(11), .d(11)],
            frontSubtitle: "Queens and jacks change the deck",
            backTitle: "A queen or jack is always trump",
            backBody: "The queen and jack of clubs, spades, hearts, and diamonds are trump. A queen of hearts is not a heart fail card, and a jack of clubs is not a club fail card.",
            choice: CardChoice("Always trump", "Trump only if diamonds are called", answerIndex: 0)
        ),
        Flashcard(
            id: "cards-points",
            frontTitle: "Point cards",
            frontTiles: [.c(14), .h(10), .s(13), .d(12), .c(11)],
            frontSubtitle: "The whole deck is worth 120",
            backTitle: "Ace 11, 10 10, king 4, queen 3, jack 2",
            backBody: "Aces carry 11 points, 10s carry 10, kings 4, queens 3, and jacks 2. Sevens, eights, and nines carry zero points. Every card still has trick strength.",
            choice: CardChoice("Ace", "Seven", answerIndex: 0)
        ),
        Flashcard(
            id: "cards-fail",
            frontTitle: "Fail suits",
            frontTiles: [.c(14), .c(10), .c(13), .c(9)],
            frontSubtitle: "The suits that are not trump",
            backTitle: "Clubs, hearts, and spades",
            backBody: "A fail card keeps its printed suit. Within a fail suit, the order is ace, 10, king, 9, 8, 7. Queens and jacks leave their printed suits and join trump instead.",
            choice: CardChoice("Three suits", "Only clubs", answerIndex: 0)
        ),
        Flashcard(
            id: "cards-trump-order",
            frontTitle: "Trump order",
            frontTiles: [.c(12), .s(12), .h(11), .d(14)],
            frontSubtitle: "Not every trump is equal",
            backTitle: "Queens, jacks, then diamonds",
            backBody: "The queen of clubs is the highest trump, followed by queen of spades, queen of hearts, queen of diamonds, then the jacks in the same suit order. Diamonds then run ace, 10, king, 9, 8, 7.",
            choice: CardChoice("Queen of clubs", "Ace of diamonds", answerIndex: 0)
        ),
        Flashcard(
            id: "cards-deal",
            frontTitle: "The five-player deal",
            frontTiles: [.c(14), .d(10), .h(9), .s(7), .c(8)],
            frontSubtitle: "Six cards and a blind",
            backTitle: "Six to each player, two in the blind",
            backBody: "The common five-player deal gives each player six cards and leaves two face down in the blind. The picker later takes the blind and buries two cards.",
            choice: CardChoice("6 cards each", "8 cards each", answerIndex: 0)
        ),
        Flashcard(
            id: "cards-blind",
            frontTitle: "The blind",
            frontSubtitle: "The hidden swing",
            backTitle: "The picker takes it",
            backBody: "After picking, the picker adds both blind cards to their hand, then buries two cards face down. Those buried cards count for the picking side at the end of the hand.",
            choice: CardChoice("Picker takes it", "Dealer keeps it", answerIndex: 0)
        ),
        Flashcard(
            id: "cards-picker",
            frontTitle: "The picker",
            frontSubtitle: "One player takes responsibility",
            backTitle: "Pick, bury, and name a partner",
            backBody: "The picker chooses the blind, buries two cards, and usually calls a fail ace as a silent partner. Strong hands can choose to go alone under the table's agreed rules.",
            choice: CardChoice("Calls the hand", "Sits out the hand", answerIndex: 0)
        ),
        Flashcard(
            id: "cards-goal",
            frontTitle: "The target",
            frontSubtitle: "Win the point race",
            backTitle: "The picking team needs 61",
            backBody: "There are 120 points in the deck. The picking team wins the basic game with 61 or more points in captured tricks. The other players win with 60 or fewer for the picker.",
            choice: CardChoice("61 points", "31 points", answerIndex: 0)
        ),
    ]

    static let cardQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "card-quiz-1",
            prompt: "How many cards are in a standard Sheepshead deck?",
            choices: ["24", "32", "52"],
            answerIndex: 1,
            explanation: "The deck keeps the 7 through ace in all four suits, for 32 cards."
        ),
        QuizQuestion(
            id: "card-quiz-2",
            prompt: "Which cards are permanent trump?",
            tiles: [.c(12), .h(11), .d(9)],
            choices: ["Queens, jacks, and diamonds", "Diamonds only", "Aces and 10s"],
            answerIndex: 0,
            explanation: "All four queens, all four jacks, and every diamond are trump."
        ),
        QuizQuestion(
            id: "card-quiz-3",
            prompt: "How many points does an ace carry?",
            tiles: [.c(14)],
            choices: ["0", "4", "11"],
            answerIndex: 2,
            explanation: "An ace is worth 11 of the deck's 120 points."
        ),
        QuizQuestion(
            id: "card-quiz-4",
            prompt: "How many cards does each player receive in the common five-player deal?",
            choices: ["5", "6", "7"],
            answerIndex: 1,
            explanation: "Five players receive six cards each, leaving two cards in the blind."
        ),
        QuizQuestion(
            id: "card-quiz-5",
            prompt: "Who takes the blind?",
            choices: ["The picker", "The player to the dealer's left", "Nobody"],
            answerIndex: 0,
            explanation: "The picker takes both blind cards and then buries two cards."
        ),
        QuizQuestion(
            id: "card-quiz-6",
            prompt: "Which card is the highest trump?",
            tiles: [.c(12), .d(12), .d(14)],
            choices: ["Queen of clubs", "Queen of diamonds", "Ace of diamonds"],
            answerIndex: 0,
            explanation: "The queen of clubs is the highest trump in the common ordering."
        ),
        QuizQuestion(
            id: "card-quiz-7",
            prompt: "What is the point value of a 9?",
            tiles: [.h(9)],
            choices: ["0", "9", "10"],
            answerIndex: 0,
            explanation: "Sevens, eights, and nines carry no points, though they can still win a trick."
        ),
        QuizQuestion(
            id: "card-quiz-8",
            prompt: "How many points are in the full deck?",
            choices: ["60", "100", "120"],
            answerIndex: 2,
            explanation: "The card values add to 120, so 61 is the basic majority needed by the picking team."
        ),
        QuizQuestion(
            id: "card-quiz-9",
            prompt: "In the common call-an-ace game, what kind of card is named?",
            choices: ["A fail ace", "Any queen", "The highest diamond"],
            answerIndex: 0,
            explanation: "The picker names a fail ace they do not hold, and its owner becomes the silent partner."
        ),
        QuizQuestion(
            id: "card-quiz-10",
            prompt: "What is the basic picking-team target?",
            choices: ["31 points", "61 points", "90 points"],
            answerIndex: 1,
            explanation: "The picking team needs at least 61 of the 120 points to win the basic game."
        ),
    ]
}
