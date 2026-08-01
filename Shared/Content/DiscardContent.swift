import Foundation

/// The Bury Room: take the blind, then choose the two cards that disappear.
enum DiscardContent {
    static let strategyCards: [Flashcard] = [
        Flashcard(
            id: "bury-what",
            frontTitle: "Bury two cards",
            frontSubtitle: "The picker has six cards after taking the blind",
            backTitle: "Keep four, bury two",
            backBody: "The picker adds the two blind cards to the original six, chooses a four-card playing hand, and places the other two cards face down. Those buried cards count for the picking side."
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
            frontTiles: [.c(14), .c(7), .d(12), .h(9)],
            frontSubtitle: "A called-ace partnership rule",
            backTitle: "The picker keeps a fail card from that suit",
            backBody: "In the common call-an-ace game, the picker names a fail ace and must retain at least one card from that fail suit. Burying the only hold card creates an illegal call."
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
            situation: "You picked the blind and want a stable team hand. Choose two cards to bury.",
            deal: [.c(12), .s(11), .d(14), .d(9), .c(14), .h(7), .h(10), .s(8)],
            recommendedDiscard: [.d(9), .h(7)],
            reasoning: "Keep the queen of clubs, jack of spades, ace of diamonds, and club ace. The two lower cards add less control, while the kept hand has three strong trumps and a fail winner.",
            tip: "Start with sure winners, then decide which low cards are safe to bury."
        ),
        DiscardScenario(
            id: "bury-scenario-2",
            situation: "You call the ace of hearts and must keep a heart fail card. Choose two cards to bury.",
            deal: [.c(12), .d(10), .h(14), .h(8), .s(7), .d(9), .c(8), .s(13)],
            recommendedDiscard: [.s(7), .d(9)],
            reasoning: "Keep the queen of clubs and diamond 10 for trump control, the heart ace for the call, and the heart 8 as the required hold card. The spade 7 and diamond 9 are the least useful pair of cards here.",
            tip: "Check the called-suit hold before you finalize the bury."
        ),
        DiscardScenario(
            id: "bury-scenario-3",
            situation: "The blind gives you three fail aces. Keep the point cards you can actually support.",
            deal: [.c(14), .h(14), .s(14), .d(13), .c(7), .s(9), .h(10), .d(8)],
            recommendedDiscard: [.c(7), .s(9)],
            reasoning: "The three fail aces and diamond king are all point cards with a chance to win their suits. The two zero-point cards do not add a winner or a called-suit requirement in this example.",
            tip: "A high point total is useful only when the cards can take tricks."
        ),
        DiscardScenario(
            id: "bury-scenario-4",
            situation: "You have two top queens and two low diamonds. Choose the cards that reduce your fragile side.",
            deal: [.c(12), .c(11), .d(7), .d(8), .h(10), .s(9), .h(14), .c(13)],
            recommendedDiscard: [.d(7), .d(8)],
            reasoning: "The queen and jack of clubs are top trumps, while the heart 10 is a point card that can be protected by trump control. The low diamonds are trump, but they are the least likely to win when stronger trump remains out.",
            tip: "Low trump is still trump, but not every trump deserves a place in the final four."
        ),
        DiscardScenario(
            id: "bury-scenario-5",
            situation: "You have no queen or jack. Keep the fail aces and avoid burying a useful hold card.",
            deal: [.c(14), .c(10), .c(9), .h(14), .s(8), .h(7), .d(12), .h(13)],
            recommendedDiscard: [.s(8), .h(7)],
            reasoning: "The club ace, club 10, and heart ace are the hand's point winners. The spade 8 and heart 7 are zero-point cards, and the heart ace remains a possible called ace or hold card.",
            tip: "When trump is thin, preserve fail winners and keep your partnership options open."
        ),
        DiscardScenario(
            id: "bury-scenario-6",
            situation: "You are considering going alone with four queens. Choose a bury that keeps the strongest support.",
            deal: [.c(12), .s(12), .h(12), .d(12), .d(14), .c(14), .d(10), .s(13)],
            recommendedDiscard: [.d(14), .c(14)],
            reasoning: "The four queens are the top trumps and make the alone plan possible. The diamond ace and club ace add points, but keeping every high card is less important than retaining the trump structure that wins the hand.",
            tip: "Going alone is about guaranteed tricks, not only the number of points in hand."
        ),
    ]
}
