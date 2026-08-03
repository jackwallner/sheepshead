import Foundation

/// Additional original questions used by the Sheepshead+ sets and Master Tables.
enum MoreContent {
    static let cardExtras: [QuizQuestion] = [
        QuizQuestion(
            id: "more-card-1",
            prompt: "Which of these is a fail card?",
            tiles: [.c(12), .d(9), .h(14)],
            choices: ["Queen of clubs", "9 of diamonds", "Ace of hearts"],
            answerIndex: 2,
            explanation: "The queen is permanent trump and the diamond is trump. The ace of hearts remains a fail card."
        ),
        QuizQuestion(
            id: "more-card-2",
            prompt: "How many points does a king carry?",
            tiles: [.c(13)],
            choices: ["2", "4", "10"],
            answerIndex: 1,
            explanation: "A king carries 4 points. Its trick strength is separate from its point value."
        ),
        QuizQuestion(
            id: "more-card-3",
            prompt: "Which card is the highest fail card in hearts?",
            tiles: [.h(14), .h(10), .h(13)],
            choices: ["Ace of hearts", "10 of hearts", "King of hearts"],
            answerIndex: 0,
            explanation: "Within a fail suit, ace is high, then 10, king, 9, 8, and 7."
        ),
        QuizQuestion(
            id: "more-card-4",
            prompt: "What happens to the queens and jacks of the fail suits?",
            choices: ["They are removed from the deck", "They become permanent trump", "They count as low cards"],
            answerIndex: 1,
            explanation: "All four queens and all four jacks are permanent trump, regardless of their printed suit."
        ),
        QuizQuestion(
            id: "more-card-5",
            prompt: "How many cards remain in the blind in a five-player hand?",
            choices: ["1", "2", "4"],
            answerIndex: 1,
            explanation: "Five players receive six cards each from a 32-card deck, leaving two in the blind."
        ),
        QuizQuestion(
            id: "more-card-6",
            prompt: "What is the point value of the 8 of spades?",
            tiles: [.s(8)],
            choices: ["0", "8", "10"],
            answerIndex: 0,
            explanation: "Sevens, eights, and nines carry zero points. They still have trick strength in their fail suit."
        ),
        QuizQuestion(
            id: "more-card-7",
            prompt: "What must the picker do with the blind before play?",
            choices: ["Take it, then bury two", "Give it to the dealer", "Leave it face up"],
            answerIndex: 0,
            explanation: "The picker takes both blind cards and buries two cards before the first trick."
        ),
        QuizQuestion(
            id: "more-card-8",
            prompt: "Which score is a basic win for the picking team?",
            choices: ["59", "60", "61"],
            answerIndex: 2,
            explanation: "The picking team needs a majority of the 120 points, so 61 is the basic winning total."
        ),
        QuizQuestion(
            id: "more-card-9",
            prompt: "Can the picker name a fail ace that was dealt to them?",
            tiles: [.c(14), .h(14)],
            choices: ["No, only an ace they were not dealt", "Yes, any fail ace", "Only if it is the club ace"],
            answerIndex: 0,
            explanation: "The call is how the picker finds a partner, so the named ace has to be in someone else's hand. A picker holding every fail ace has no ace to name and plays alone."
        ),
        QuizQuestion(
            id: "more-card-10",
            prompt: "How many cards does the picker hold after taking the blind, before burying?",
            choices: ["6", "7", "8"],
            answerIndex: 2,
            explanation: "Six dealt cards plus the two blind cards make eight. The picker then buries two and plays a six-card hand."
        ),
    ]

    static let handReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "more-hand-1",
            tiles: [.d(12), .c(11), .s(11), .d(14), .d(9)],
            choices: [.trumpStack, .pointCards, .lowCards],
            answer: .trumpStack,
            explanation: "Every card here is trump. The queen of diamonds and the two jacks are permanent trump, and the diamond ace and 9 are trump because every diamond is."
        ),
        HandMatchQuestion(
            id: "more-hand-2",
            tiles: [.c(7), .c(8), .c(9), .c(10), .c(14)],
            choices: [.failSuit, .pointCards, .trickTaking],
            answer: .failSuit,
            explanation: "Every card is a club fail card. A fail suit holds six cards, so the club king is the only one missing here, and the club queen and jack are trump rather than clubs."
        ),
        HandMatchQuestion(
            id: "more-hand-3",
            tiles: [.c(14), .h(14), .s(14), .c(10), .h(10)],
            choices: [.pointCards, .lowCards, .trumpStack],
            answer: .pointCards,
            explanation: "Every card carries points, but the holding has no permanent trump. It is valuable only if those fail suits can be won."
        ),
        HandMatchQuestion(
            id: "more-hand-4",
            tiles: [.c(7), .h(7), .s(8), .c(9), .h(8)],
            choices: [.lowCards, .failSuit, .pointCards],
            answer: .lowCards,
            explanation: "All five cards are zero-point fail cards. They are useful for following suit without spending point cards."
        ),
        HandMatchQuestion(
            id: "more-hand-5",
            tiles: [.c(14), .c(7), .d(9), .h(10), .s(8)],
            choices: [.partnership, .scoring, .trumpStack],
            answer: .partnership,
            explanation: "Holding the named fail ace is what makes you the picker's silent partner, so read this holding as a partnership question. The picker can never name an ace they were dealt."
        ),
        HandMatchQuestion(
            id: "more-hand-6",
            tiles: [.c(12), .s(12), .h(11), .d(14), .h(14)],
            choices: [.trumpStack, .picking, .lowCards],
            answer: .picking,
            explanation: "Two queens, a jack, and the diamond ace give real trump control, and the heart ace adds points. It is not a pure trump stack, but it is exactly the shape that makes taking the blind attractive."
        ),
    ]

    static let discardExtras: [DiscardScenario] = [
        DiscardScenario(
            id: "more-bury-1",
            situation: "Four trumps, two hearts, and two clubs. Choose two cards to bury.",
            deal: [.c(12), .s(11), .d(10), .d(8), .h(14), .h(7), .c(9), .c(8)],
            recommendedDiscard: [.h(14), .h(7)],
            reasoning: "Burying both hearts banks the ace's 11 points and empties the suit, so the next heart lead can be trumped. The two clubs stay behind as a legal hold card for calling the club ace.",
            tip: "A fail ace is worth 11 points whether you win it or bury it."
        ),
        DiscardScenario(
            id: "more-bury-2",
            situation: "You plan to call the club ace, so a club has to stay. Choose two cards to bury.",
            deal: [.d(12), .c(11), .d(10), .d(9), .c(9), .c(8), .h(14), .h(13)],
            recommendedDiscard: [.h(14), .h(13)],
            reasoning: "The heart ace and king are 15 banked points and burying both empties hearts. The club 9 and 8 stay so the called-ace hold is legal, and the jack of clubs counts as trump rather than as a club.",
            tip: "A jack of clubs is trump, so it cannot serve as your club hold card.",
            calledSuit: .clubs
        ),
        DiscardScenario(
            id: "more-bury-3",
            situation: "Your trump is the diamond 7 and 8. Choose two cards to bury.",
            deal: [.h(14), .s(13), .c(10), .c(13), .h(8), .s(9), .d(7), .d(8)],
            recommendedDiscard: [.c(10), .c(13)],
            reasoning: "The club 10 and king are 14 points that two low trumps cannot protect once clubs are led. Burying both banks the points and empties clubs, and the spade king and 9 keep a legal hold card for calling the spade ace.",
            tip: "Thin trump means the safest place for your points is face down."
        ),
        DiscardScenario(
            id: "more-bury-4",
            situation: "The blind gives you the four queens plus two clubs and two hearts. Choose two cards to bury.",
            deal: [.c(12), .s(12), .h(12), .d(12), .c(9), .c(8), .h(13), .h(7)],
            recommendedDiscard: [.h(13), .h(7)],
            reasoning: "The four queens already control every trick they enter, so the bury banks points and empties a suit. Both hearts go for 4 points, and the two clubs stay so you can still name the club ace and play with a partner.",
            tip: "Total trump control is a reason to keep a hold card, not to abandon the partnership."
        ),
    ]

    static let tableQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "more-trick-1",
            prompt: "A club is led and you hold a club. What must you do?",
            tiles: [.c(7), .d(9), .h(10)],
            choices: ["Play a club", "Play the diamond 9", "Play any card"],
            answerIndex: 0,
            explanation: "You must follow the led fail suit when possible. Trump is not a free choice while you hold a club."
        ),
        QuizQuestion(
            id: "more-trick-2",
            prompt: "A club is led and you have no clubs. What is true?",
            choices: ["You may play any card", "You must play a heart", "You must play a 7"],
            answerIndex: 0,
            explanation: "If you cannot follow the led fail suit, you may play any card, including trump."
        ),
        QuizQuestion(
            id: "more-trick-3",
            prompt: "A queen of hearts is led. What kind of lead is it?",
            tiles: [.h(12)],
            choices: ["Trump", "Heart fail", "A special no-suit lead"],
            answerIndex: 0,
            explanation: "Every queen is trump. Its printed heart suit no longer matters for following."
        ),
        QuizQuestion(
            id: "more-trick-4",
            prompt: "Which card wins between the queen of diamonds and the jack of clubs?",
            tiles: [.d(12), .c(11)],
            choices: ["Queen of diamonds", "Jack of clubs", "They tie"],
            answerIndex: 0,
            explanation: "Every queen beats every jack, even though both cards are permanent trump."
        ),
        QuizQuestion(
            id: "more-trick-5",
            prompt: "Which fail card wins a trick led in hearts?",
            tiles: [.h(14), .h(10), .h(13)],
            choices: ["Ace of hearts", "10 of hearts", "King of hearts"],
            answerIndex: 0,
            explanation: "Fail-suit strength is ace, 10, king, 9, 8, 7."
        ),
        QuizQuestion(
            id: "more-trick-6",
            prompt: "What does the partner do in a call-an-ace hand?",
            choices: ["Stay silent until the called ace appears", "Announce the partnership immediately", "Take the blind"],
            answerIndex: 0,
            explanation: "The ace holder is a silent partner. The table learns the partnership from the play of the called ace."
        ),
        QuizQuestion(
            id: "more-trick-7",
            prompt: "What should you count when judging a captured trick?",
            choices: ["Only the number of cards", "The point value of every captured card", "Only the highest card"],
            answerIndex: 1,
            explanation: "The trick winner takes all cards in the trick, and the captured point cards determine the score."
        ),
        QuizQuestion(
            id: "more-trick-8",
            prompt: "What is a common reason to lead trump?",
            choices: ["To draw opposing trump", "To make every fail card follow", "To change the called ace"],
            answerIndex: 0,
            explanation: "A trump lead can draw out opposing trump and clarify which side controls the remaining tricks."
        ),
    ]

    static let judgment: [Flashcard] = [
        Flashcard(
            id: "more-judgment-1",
            frontTitle: "You hold the called ace",
            frontTiles: [.c(14), .c(7), .d(10)],
            frontSubtitle: "The partnership is hidden",
            backTitle: "Keep the reveal quiet",
            backBody: "Do not announce that you are the partner. When the called fail suit is first led, the ace identifies you and your side."
        ),
        Flashcard(
            id: "more-judgment-2",
            frontTitle: "The picker leads",
            frontTiles: [.c(12), .d(9), .h(14)],
            frontSubtitle: "Trump or fail?",
            backTitle: "Choose the lead that serves the team",
            backBody: "A trump lead can draw opposing trump, while a fail lead can search for a partner or ask for a specific suit. There is no automatic lead every time."
        ),
        Flashcard(
            id: "more-judgment-3",
            frontTitle: "A zero-point trick",
            frontTiles: [.c(7), .h(8), .s(9)],
            frontSubtitle: "Not every trick is a scoring trick",
            backTitle: "Use it to control the next lead",
            backBody: "A zero-point trick can still be valuable because the winner leads the next trick. Position and information are part of the score."
        ),
        Flashcard(
            id: "more-judgment-4",
            frontTitle: "The opponent shows a queen",
            frontTiles: [.c(12), .s(12), .d(14)],
            frontSubtitle: "Track the trump",
            backTitle: "Remember what remains",
            backBody: "Every visible queen or jack narrows the live trump. Card memory is especially valuable when deciding whether a low diamond can win later."
        ),
        Flashcard(
            id: "more-judgment-5",
            frontTitle: "The picking team has 58",
            frontSubtitle: "The next point changes the hand",
            backTitle: "61 is the basic line",
            backBody: "The picking team needs three more points for a basic win. A small point card can matter more than an extra empty trick when the hand is close."
        ),
    ]

    static let advancedRules: [QuizQuestion] = [
        QuizQuestion(
            id: "more-rule-1",
            prompt: "Which card is not a fail card in a heart hand?",
            tiles: [.h(12), .h(14)],
            choices: ["Queen of hearts", "Ace of hearts", "Both cards are fail"],
            answerIndex: 0,
            explanation: "The queen of hearts is permanent trump. The ace of hearts is the highest heart fail card."
        ),
        QuizQuestion(
            id: "more-rule-2",
            prompt: "Why does a picker keep a card from the called suit?",
            choices: ["The common call-an-ace rule requires a hold card", "It adds a bonus point", "It makes the card trump"],
            answerIndex: 0,
            explanation: "In the common call-an-ace game, the picker must retain at least one card from the called fail suit."
        ),
        QuizQuestion(
            id: "more-rule-3",
            prompt: "What is the first question after a fail card is led?",
            choices: ["Can I follow that fail suit?", "Do I have a queen?", "Who dealt the cards?"],
            answerIndex: 0,
            explanation: "Following suit is the first legality check. Only if you cannot follow may you choose another suit or trump."
        ),
        QuizQuestion(
            id: "more-rule-4",
            prompt: "What does the word majority mean in the basic score?",
            choices: ["At least 61 of 120 points", "At least four tricks", "The most cards in hand"],
            answerIndex: 0,
            explanation: "The picking team wins the basic game by taking 61 or more of the deck's 120 points."
        ),
        QuizQuestion(
            id: "more-rule-5",
            prompt: "Which statement about a diamond 7 is true?",
            tiles: [.d(7), .c(14)],
            choices: ["It is trump but carries zero points", "It is a fail card worth 7", "It is removed from the deck"],
            answerIndex: 0,
            explanation: "Every diamond is trump. The 7 still carries zero points."
        ),
        QuizQuestion(
            id: "more-rule-6",
            prompt: "What should a beginner do when house rules differ?",
            choices: ["State the table's version before the hand", "Assume the app decides", "Mix both versions during play"],
            answerIndex: 0,
            explanation: "Sheepshead has regional variations. Agree on partner selection and scoring before the first deal."
        ),
    ]
}
