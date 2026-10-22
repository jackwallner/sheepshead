import Foundation

/// One page of the beginner Sheepshead primer.
struct HowToPlayPage: Identifiable, Sendable {
    let id: String
    let icon: String
    let title: String
    let body: String
    let tiles: [PlayingCard]
    let tip: String?

    init(id: String, icon: String, title: String, body: String, tiles: [PlayingCard] = [], tip: String? = nil) {
        self.id = id
        self.icon = icon
        self.title = title
        self.body = body
        self.tiles = tiles
        self.tip = tip
    }
}

/// The six-page primer for players who picked "brand new" in onboarding.
enum HowToPlayContent {
    static let pages: [HowToPlayPage] = [
        HowToPlayPage(
            id: "sheep-goal",
            icon: "flag.checkered",
            title: "The goal",
            body: "Sheepshead is a trick-taking game. The five-player picking team needs 61 of 120 points, including the bury. These bury drills use called ace with no under calls or called tens; tables may agree on those additional calls.",
            tiles: [.c(14), .d(12)],
            tip: "The number of tricks matters less than the point cards inside them."
        ),
        HowToPlayPage(
            id: "sheep-deck",
            icon: "rectangle.stack.fill",
            title: "Meet the deck",
            body: "Use the 7 through ace of all four suits, for 32 cards. Every queen, every jack, and every diamond is trump. The remaining clubs, hearts, and spades are fail suits.",
            tiles: [.c(12), .s(11), .d(9), .h(14)]
        ),
        HowToPlayPage(
            id: "sheep-deal",
            icon: "person.3.fill",
            title: "Deal and pick",
            body: "Five players receive six cards and two cards form the blind. The picker takes the blind, buries two cards, and usually names a fail ace they were not dealt. Whoever holds that ace becomes the silent partner.",
            tiles: [.c(14), .d(10), .h(9), .s(7), .c(8), .d(13)],
            tip: "When everyone passes, many tables play a leaster and some make the dealer pick, so agree before the deal."
        ),
        HowToPlayPage(
            id: "sheep-points",
            icon: "number.circle.fill",
            title: "Learn the points",
            body: "Aces carry 11, 10s carry 10, kings 4, queens 3, and jacks 2. Sevens, eights, and nines carry zero. The whole deck is worth 120.",
            tiles: [.c(14), .h(10), .s(13), .d(12), .c(11)],
            tip: "A card's point value and its trick strength are separate questions."
        ),
        HowToPlayPage(
            id: "sheep-tricks",
            icon: "arrow.up.right.circle.fill",
            title: "Take the trick",
            body: "Follow the led suit, including trump, when you can. On the first lead of the called suit, partner must play the called ace. Until then, partner reserves that ace and picker reserves a card of its suit. Otherwise, when void you may play any card. Trump beats every fail card, and the strongest card in the winning suit takes the trick.",
            tiles: [.c(14), .c(7), .d(8)],
            tip: "Queens and jacks are trump even when their printed suit looks like a fail suit."
        ),
        HowToPlayPage(
            id: "sheep-ready",
            icon: "checkmark.seal.fill",
            title: "You are ready",
            body: "That is the loop: read the trump, choose the blind, protect your partnership, follow legally, and count the points you capture. The rooms turn each skill into a short practice rep.",
            tiles: [.c(12), .d(14), .h(14)]
        ),
    ]

    static func recommendedRoom(forSkillLevel skillLevel: String) -> Room {
        let roomID: String
        switch skillLevel {
        case "basics": roomID = "trump-room"
        case "played": roomID = "trick-room"
        default: roomID = "card-room"
        }
        return DrillLibrary.rooms.first { $0.id == roomID } ?? DrillLibrary.rooms[0]
    }
}
