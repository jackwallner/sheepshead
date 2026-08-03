import Foundation

/// The Trump Room: read the card's job before thinking about a play.
enum CategoryContent {
    static let categoryCards: [Flashcard] = [
        Flashcard(
            id: "read-trump",
            frontTitle: "Find the trump",
            frontTiles: [.c(12), .s(11), .d(9), .h(14)],
            frontSubtitle: "Start here on every deal",
            backTitle: "Queens, jacks, and diamonds",
            backBody: "The queen of clubs, the jack of spades, and the 9 of diamonds are all trump. The ace of hearts is a fail card because hearts is not trump."
        ),
        Flashcard(
            id: "read-queen-order",
            frontTitle: "Queens lead trump",
            frontTiles: [.c(12), .s(12), .h(12), .d(12)],
            frontSubtitle: "The four highest cards",
            backTitle: "Clubs, spades, hearts, diamonds",
            backBody: "The four queens are the top four trumps in that suit order. Remembering the order prevents a queen of diamonds from being mistaken for the highest queen."
        ),
        Flashcard(
            id: "read-jack-order",
            frontTitle: "Then the jacks",
            frontTiles: [.c(11), .s(11), .h(11), .d(11)],
            frontSubtitle: "The next four trumps",
            backTitle: "Jacks follow the queens",
            backBody: "The jacks use the same suit order as the queens. The jack of clubs beats every other jack, but every jack loses to every queen."
        ),
        Flashcard(
            id: "read-diamond-trump",
            frontTitle: "Diamonds finish trump",
            frontTiles: [.d(14), .d(10), .d(13), .d(9)],
            frontSubtitle: "Printed suit does not change the rule",
            backTitle: "Ace through 7 of diamonds",
            backBody: "After the eight queens and jacks, diamond trump runs ace, 10, king, 9, 8, 7. A diamond beats any fail card."
        ),
        Flashcard(
            id: "read-fail-order",
            frontTitle: "Read a fail suit",
            frontTiles: [.c(14), .c(10), .c(13), .c(9), .c(7)],
            frontSubtitle: "A suit without queens or jacks",
            backTitle: "Ace, 10, king, 9, 8, 7",
            backBody: "A fail suit keeps six cards. The ace is high, followed by 10, king, 9, 8, and 7. The queen and jack are missing because they are already trump."
        ),
        Flashcard(
            id: "read-point-cards",
            frontTitle: "Count the points",
            frontTiles: [.c(14), .h(10), .s(13), .d(12), .c(11)],
            frontSubtitle: "Trick strength and point value differ",
            backTitle: "High point cards matter twice",
            backBody: "A card can be weak in trick strength but valuable to capture. A king is only third in its fail suit, behind the ace and the 10, yet it is worth 4 points."
        ),
        Flashcard(
            id: "read-low-cards",
            frontTitle: "Zeros still matter",
            frontTiles: [.c(7), .h(8), .s(9)],
            frontSubtitle: "No points does not mean no purpose",
            backTitle: "Use low cards to follow cheaply",
            backBody: "Sevens, eights, and nines carry zero points. They can still win when they are the highest card in the led fail suit, or help you avoid giving away a point card."
        ),
        Flashcard(
            id: "read-trick-winner",
            frontTitle: "Who wins the trick?",
            frontTiles: [.c(14), .c(10), .d(7), .h(14)],
            frontSubtitle: "Trump beats the led suit",
            backTitle: "Highest trump, otherwise highest led suit",
            backBody: "The diamond 7 is trump, so it beats the ace and 10 of clubs. The heart ace is not part of the contest because it does not follow clubs and is not trump."
        ),
        Flashcard(
            id: "read-follow-suit",
            frontTitle: "Follow when you can",
            frontTiles: [.c(14), .c(7), .d(9)],
            frontSubtitle: "The obligation before the opportunity",
            backTitle: "Play the led fail suit if you have it",
            backBody: "If clubs are led and you hold a club, you must play a club. A diamond or a queen cannot be used as a free trump while you still hold the led fail suit."
        ),
    ]

    static let handMatch: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "read-match-1",
            tiles: [.c(12), .s(11), .d(9), .h(12), .d(14)],
            choices: [.trumpStack, .failSuit, .lowCards],
            answer: .trumpStack,
            explanation: "Every card shown is trump: the queens and jack are permanent trump, and both diamonds are trump."
        ),
        HandMatchQuestion(
            id: "read-match-2",
            tiles: [.c(14), .c(10), .c(13), .c(9), .c(7)],
            choices: [.failSuit, .pointCards, .trumpStack],
            answer: .failSuit,
            explanation: "These are all clubs from a fail suit. The six-card club suit loses its queen and jack to the trump group."
        ),
        HandMatchQuestion(
            id: "read-match-3",
            tiles: [.c(14), .h(10), .s(13), .c(10), .h(14)],
            choices: [.pointCards, .lowCards, .failSuit],
            answer: .pointCards,
            explanation: "Every card carries points, and the cards are spread across fail suits. The shape is useful when judging which tricks are worth fighting for."
        ),
        HandMatchQuestion(
            id: "read-match-4",
            tiles: [.c(7), .h(8), .s(9), .c(8), .h(7)],
            choices: [.lowCards, .pointCards, .trumpStack],
            answer: .lowCards,
            explanation: "All five cards are low fail cards worth zero points. Their value is in following cheaply and preserving information."
        ),
        HandMatchQuestion(
            id: "read-match-5",
            tiles: [.c(14), .c(7), .d(12), .h(8), .s(13)],
            choices: [.partnership, .trumpStack, .failSuit],
            answer: .partnership,
            explanation: "Read this as a partnership question. If the picker names the club ace, whoever was dealt it becomes the silent partner, so this holding is the partner's side of the deal."
        ),
        HandMatchQuestion(
            id: "read-match-6",
            tiles: [.d(14), .d(10), .c(12), .s(12), .h(7)],
            choices: [.picking, .lowCards, .failSuit],
            answer: .picking,
            explanation: "This is a picker-shaped holding: several high trumps plus a useful fail card can make taking the blind attractive."
        ),
        HandMatchQuestion(
            id: "read-match-7",
            tiles: [.c(14), .c(10), .h(14), .s(14), .d(7)],
            choices: [.scoring, .trickTaking, .lowCards],
            answer: .scoring,
            explanation: "The three fail aces and diamond carry a large share of the deck's points. Read the point cards before chasing empty tricks."
        ),
        HandMatchQuestion(
            id: "read-match-8",
            tiles: [.c(12), .d(7), .h(9), .s(10), .c(7)],
            choices: [.trickTaking, .pointCards, .failSuit],
            answer: .trickTaking,
            explanation: "This mix asks a play question: the queen of clubs is a high trump, while the fail cards must be read by their led suit."
        ),
    ]
}
