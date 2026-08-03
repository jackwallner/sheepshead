import Foundation

/// The Bury Room: take the blind, then choose the two cards that disappear.
enum DiscardContent {
    static let strategyCards: [Flashcard] = [
        Flashcard(
            id: "bury-what",
            frontTitle: "Bury two cards",
            frontSubtitle: "The picker holds eight cards after taking the blind",
            backTitle: "Keep six, bury two",
            backBody: "The picker adds the two blind cards to the original six, keeps a six-card playing hand, and places the other two cards face down. Those buried cards count for the picking side."
        ),
        Flashcard(
            id: "bury-trump-first",
            frontTitle: "Protect trump control",
            frontTiles: [.c(12), .s(11), .d(14), .d(9)],
            frontSubtitle: "The first bury question",
            backTitle: "Do not bury a key winner casually",
            backBody: "Queens, jacks, and high diamonds can control several tricks. A low fail card is often easier to bury, unless it is the only card that lets you hold the called suit."
        ),
        Flashcard(
            id: "bury-called-suit",
            frontTitle: "Hold the called suit",
            frontTiles: [.c(9), .c(7), .d(12), .h(9)],
            frontSubtitle: "A called-ace partnership rule",
            backTitle: "The picker keeps a fail card from that suit",
            backBody: "In the common call-an-ace game, the picker names a fail ace they were not dealt, and must retain at least one card from that fail suit. Burying the only hold card creates an illegal call.",
            choice: CardChoice("Name an ace you were not dealt", "Name your own strongest ace", answerIndex: 0)
        ),
        Flashcard(
            id: "bury-no-trump",
            frontTitle: "Which two go?",
            frontTiles: [.d(8), .d(7), .s(9), .h(8)],
            frontSubtitle: "Two low diamonds, a spade, and a heart",
            backTitle: "Bury fail cards, not trump",
            backBody: "A diamond 7 still beats every fail card in the deck, so the two diamonds stay. When you have a choice, the bury comes out of the fail suits and every queen, jack, and diamond stays in the playing hand.",
            choice: CardChoice("The spade and the heart", "The two low diamonds", answerIndex: 0)
        ),
        Flashcard(
            id: "bury-empty-a-suit",
            frontTitle: "Two hearts and two clubs",
            frontTiles: [.h(13), .h(7), .c(9), .c(8)],
            frontSubtitle: "All four are safe to bury. Which pair?",
            backTitle: "A suit you no longer hold is a suit you can trump",
            backBody: "Burying both hearts banks the king's 4 points and leaves you free to play trump the next time hearts are led. Splitting the bury across two suits banks less and empties neither.",
            choice: CardChoice("Both hearts", "One heart and one club", answerIndex: 0)
        ),
        Flashcard(
            id: "bury-points",
            frontTitle: "Point cards are not all winners",
            frontTiles: [.c(14), .h(10), .s(13), .c(7)],
            frontSubtitle: "Strength and value are different",
            backTitle: "Keep a plan for capturing them",
            backBody: "An ace or 10 is valuable when captured, but a fail point card can be stranded if you cannot win its suit. Weigh likely tricks, not point value alone."
        ),
        Flashcard(
            id: "bury-low-cards",
            frontTitle: "Low cards can be useful",
            frontTiles: [.c(7), .h(8), .s(9)],
            frontSubtitle: "Zero points, real choices",
            backTitle: "A low card can save a winner",
            backBody: "Low fail cards can follow a suit without spending a point card. Keeping one can also preserve a legal lead after the other players run out of that suit."
        ),
        Flashcard(
            id: "bury-alone",
            frontTitle: "Going alone is a separate call",
            frontTiles: [.c(12), .s(12), .h(12), .d(12)],
            frontSubtitle: "Do not bury with the team plan",
            backTitle: "Count winners before choosing alone",
            backBody: "A hand with many top trumps may support going alone, but the decision depends on the blind, the buried cards, and the table's agreed scoring rules."
        ),
        Flashcard(
            id: "bury-blind-points",
            frontTitle: "Buried points still count",
            frontTiles: [.d(14), .c(14), .h(13), .s(9)],
            frontSubtitle: "The blind is not thrown away",
            backTitle: "The picking side keeps the point value",
            backBody: "The two buried cards are part of the picker's captured total at the end. Burying a point card may be right, but remember that it is helping your side rather than vanishing."
        ),
    ]

    static let scenarios: [DiscardScenario] = [
        DiscardScenario(
            id: "bury-scenario-1",
            situation: "You picked with four trumps and two singleton fail cards. Choose two cards to bury.",
            deal: [.c(12), .s(11), .d(14), .d(9), .c(13), .h(7), .h(9), .s(8)],
            recommendedDiscard: [.c(13), .s(8)],
            reasoning: "Burying the lone club and the lone spade banks the club king's 4 points and empties two fail suits at once, so a club or spade lead can be trumped. Every trump stays, and the two hearts leave you a legal hold card for calling the heart ace.",
            tip: "A singleton fail card is the cheapest way to empty a suit."
        ),
        DiscardScenario(
            id: "bury-scenario-2",
            situation: "You plan to call the ace of hearts, so a heart has to stay. Choose two cards to bury.",
            deal: [.c(12), .d(10), .d(9), .h(13), .h(8), .s(7), .c(8), .c(7)],
            recommendedDiscard: [.h(13), .s(7)],
            reasoning: "Bury the heart king and the lone spade. That banks 4 points, empties spades, and keeps the heart 8 as the required hold card for the call. A hold card only has to belong to the called suit, so the low heart does the job and the king is safer face down.",
            tip: "Keep the cheapest legal hold card and bank the expensive one.",
            calledSuit: .hearts
        ),
        DiscardScenario(
            id: "bury-scenario-3",
            situation: "You were dealt all three fail aces, so no ace is left to call. Choose two cards to bury.",
            deal: [.c(14), .h(14), .s(14), .d(13), .c(7), .s(9), .h(10), .d(8)],
            recommendedDiscard: [.h(14), .h(10)],
            reasoning: "Burying both hearts banks 21 points where nobody can capture them and leaves hearts empty for a trump. A picker who holds every fail ace has no ace to name, so this hand is played alone under the table's rules.",
            tip: "You can only call an ace you were not dealt.",
            isAlone: true
        ),
        DiscardScenario(
            id: "bury-scenario-4",
            situation: "You hold the queen and jack of clubs plus two low diamonds. Choose two cards to bury.",
            deal: [.c(12), .c(11), .d(7), .d(8), .h(10), .h(13), .s(9), .s(8)],
            recommendedDiscard: [.h(10), .h(13)],
            reasoning: "The diamond 7 and 8 look like the weakest cards, but they are trump and beat every fail card in the deck. Burying both hearts banks 14 points and empties the suit, while the two spades stay as a hold card for a called ace.",
            tip: "Low trump is still trump. The bury comes out of the fail suits."
        ),
        DiscardScenario(
            id: "bury-scenario-5",
            situation: "Your only trump is the queen and 8 of diamonds. Choose two cards to bury.",
            deal: [.d(12), .d(8), .h(14), .h(13), .c(9), .c(8), .c(7), .s(9)],
            recommendedDiscard: [.h(14), .h(13)],
            reasoning: "With two trumps you cannot protect a fail ace once the opponents start drawing suits. Burying the heart ace and king banks 15 points safely and empties hearts, so the queen of diamonds can trump the first heart lead.",
            tip: "Points you cannot defend are worth more face down than in your hand."
        ),
        DiscardScenario(
            id: "bury-scenario-6",
            situation: "You picked with the four queens and the diamond ace. Choose two cards to bury.",
            deal: [.c(12), .s(12), .h(12), .d(12), .d(14), .c(14), .s(13), .s(9)],
            recommendedDiscard: [.c(14), .s(13)],
            reasoning: "The four queens and the diamond ace already control the hand, so the bury banks points instead of adding trump. The club ace and spade king are 15 points face down, clubs are empty, and the spade 9 remains as a legal hold card for a called ace.",
            tip: "With trump control secured, bury for points."
        ),
    ]
}
