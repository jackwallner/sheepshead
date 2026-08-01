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
    ]

    static let handReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "more-hand-1",
            tiles: [.c(12), .d(10), .d(8), .h(14), .s(7)],
            choices: [.trumpStack, .pointCards, .lowCards],
            answer: .trumpStack,
            explanation: "The queen and both diamonds are trump. The heart ace is a point card and the spade 7 is a low fail card."
        ),
        HandMatchQuestion(
            id: "more-hand-2",
            tiles: [.c(7), .c(8), .c(9), .c(10), .c(14)],
            choices: [.failSuit, .pointCards, .trickTaking],
            answer: .failSuit,
            explanation: "This is the full club fail suit from 7 through ace, without the club queen or jack because those are trump."
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
            explanation: "The club ace and club 7 show how the picker can name the club ace while retaining a club hold card."
        ),
        HandMatchQuestion(
            id: "more-hand-6",
            tiles: [.c(12), .s(12), .h(11), .d(14), .d(10)],
            choices: [.trumpStack, .picking, .lowCards],
            answer: .picking,
            explanation: "Four strong trumps and a point diamond make taking the blind an attractive picking shape."
        ),
    ]

    static let discardExtras: [DiscardScenario] = [
        DiscardScenario(
            id: "more-bury-1",
            situation: "The blind leaves you with four trumps and two small fail cards. Choose two to bury.",
            deal: [.c(12), .s(11), .d(10), .d(8), .c(7), .h(9), .h(14), .s(13)],
            recommendedDiscard: [.c(7), .h(9)],
            reasoning: "Keep the queen, jack, and two diamonds as a strong trump core. The club 7 and heart 9 carry no points and are the least likely to take a trick.",
            tip: "A compact trump core can be more useful than a scattered point card."
        ),
        DiscardScenario(
            id: "more-bury-2",
            situation: "You need a fail card to hold the called suit. Choose two cards without breaking that requirement.",
            deal: [.c(14), .c(8), .d(12), .h(13), .s(7), .h(14), .d(9), .h(8)],
            recommendedDiscard: [.h(13), .s(7)],
            reasoning: "The club ace and club 8 preserve a legal club hold for a called-ace hand. The queen of clubs is trump, while the king of hearts and spade 7 add less to this plan.",
            tip: "A legal partnership plan comes before a theoretical extra point."
        ),
        DiscardScenario(
            id: "more-bury-3",
            situation: "You have two fail aces and two low cards. Keep the point winners and bury the zeros.",
            deal: [.h(14), .s(14), .c(10), .d(7), .h(8), .s(9), .c(13), .d(8)],
            recommendedDiscard: [.h(8), .s(9)],
            reasoning: "The two aces and club 10 carry points and can win when their suits are led. The low heart and spade are zero-point cards with no special hold requirement here.",
            tip: "Point cards need support, but zero cards still have to earn their place."
        ),
        DiscardScenario(
            id: "more-bury-4",
            situation: "The blind gives you the four queens. Choose the two cards that leave the cleanest trump hand.",
            deal: [.c(12), .s(12), .h(12), .d(12), .c(9), .h(7), .c(8), .s(8)],
            recommendedDiscard: [.c(9), .h(7)],
            reasoning: "The four queens are the top trumps and already form the core of an alone decision. The two low fail cards carry no points and do not improve the trump plan.",
            tip: "When the trump plan is clear, do not bury a top trump to keep a zero."
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
