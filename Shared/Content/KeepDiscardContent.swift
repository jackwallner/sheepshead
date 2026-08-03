import Foundation

/// The Trick Room: short table decisions about leads, following, and trump.
enum KeepDiscardContent {
    static let judgmentCards: [Flashcard] = [
        Flashcard(
            id: "trick-follow",
            frontTitle: "Clubs are led",
            frontTiles: [.c(14), .d(9), .h(10)],
            frontSubtitle: "You hold the club ace",
            backTitle: "Play the club ace",
            backBody: "A fail card was led and you have a card of that suit. You must follow clubs. The diamond 9 is trump, but it cannot be used while a club is available.",
            choice: CardChoice("Follow clubs", "Trump with diamond 9", answerIndex: 0)
        ),
        Flashcard(
            id: "trick-no-follow",
            frontTitle: "Clubs are led",
            frontTiles: [.h(10), .d(9), .s(7)],
            frontSubtitle: "You hold no clubs",
            backTitle: "Trump is available",
            backBody: "Because you have no clubs, you may play any card. A diamond is trump and can win the trick, while the heart 10 and spade 7 are fail cards that cannot beat a club winner.",
            choice: CardChoice("Any card", "Must play hearts", answerIndex: 0)
        ),
        Flashcard(
            id: "trick-queen-suit",
            frontTitle: "A queen is led",
            frontTiles: [.h(12), .h(14), .d(10)],
            frontSubtitle: "Printed suit is a trap",
            backTitle: "The queen led trump",
            backBody: "A queen is trump even when it is printed with a heart. You must follow trump if you have another trump, so the heart ace is not a legal response while the diamond 10 is available.",
            choice: CardChoice("Play diamond 10", "Play heart ace", answerIndex: 0)
        ),
        Flashcard(
            id: "trick-queen-high",
            frontTitle: "Two queens meet",
            frontTiles: [.s(12), .d(12), .c(11)],
            frontSubtitle: "The permanent trump order",
            backTitle: "Queen of spades wins",
            backBody: "The queen of spades is higher than the queen of diamonds. The jack of clubs is also trump, but every queen beats every jack.",
            choice: CardChoice("Queen of spades", "Queen of diamonds", answerIndex: 0)
        ),
        Flashcard(
            id: "trick-fail-winner",
            frontTitle: "Hearts are led",
            frontTiles: [.h(10), .h(13), .h(7)],
            frontSubtitle: "No trump appears",
            backTitle: "The heart 10 wins",
            backBody: "Within a fail suit, the order is ace, 10, king, 9, 8, 7. The 10 beats the king, which surprises players who expect a king to outrank a number card.",
            choice: CardChoice("Heart 10", "Heart king", answerIndex: 0)
        ),
        Flashcard(
            id: "trick-partner",
            frontTitle: "The called ace appears",
            frontTiles: [.c(14), .d(12), .s(9)],
            frontSubtitle: "The silent reveal",
            backTitle: "The ace holder is the partner",
            backBody: "In the common call-an-ace game, the player holding the named fail ace becomes the picker's partner. The partner does not announce it before the ace is played.",
            choice: CardChoice("The ace holder", "The dealer", answerIndex: 0)
        ),
        Flashcard(
            id: "trick-lead",
            frontTitle: "Choose a lead",
            frontTiles: [.c(14), .c(7), .d(9)],
            frontSubtitle: "The lead tells a story",
            backTitle: "Lead with a reason",
            backBody: "A fail lead can ask for a suit, while a trump lead can draw opposing trump. The right lead depends on your side, the called suit, and what the table has shown.",
            choice: CardChoice("Use the hand plan", "Always lead the lowest card", answerIndex: 0)
        ),
        Flashcard(
            id: "trick-points",
            frontTitle: "Capture points",
            frontTiles: [.c(14), .h(10), .s(9)],
            frontSubtitle: "A trick is more than a winner",
            backTitle: "Track the cards inside it",
            backBody: "The winner takes every card in the trick, so the point value of the cards captured matters. A zero-point trick can still be useful if it protects a future lead.",
            choice: CardChoice("Count captured cards", "Count only tricks", answerIndex: 0)
        ),
    ]
}
