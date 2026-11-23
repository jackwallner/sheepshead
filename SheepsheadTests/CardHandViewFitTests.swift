import SwiftUI
import UIKit
import XCTest
@testable import Sheepshead

/// CardHandView must never be wider than the width it is offered, so cards are
/// not clipped on a 320pt (Display Zoom, Slide Over) or 375pt (SE, mini) screen.
@MainActor
final class CardHandViewFitTests: XCTestCase {
    private let gap: CGFloat = 6

    /// Counts and card widths used by the call sites: onboarding (54),
    /// question fronts (44), how-to pages (up to 6 cards), flashcard fronts
    /// (52, up to 5 cards) and the Discard drill's 8-card deal (48).
    private let shapes: [(label: String, count: Int, width: CGFloat)] = [
        ("onboarding 3", 3, 54),
        ("onboarding 5", 5, 54),
        ("question 5", 5, 44),
        ("how-to 6", 6, 46),
        ("flashcard 5", 5, 52),
        ("flashcard 3", 3, 52),
        ("discard 8", 8, 48),
        ("seven", 7, 48),
    ]

    private func hand(_ count: Int) -> [PlayingCard] {
        Array(PlayingCard.sheepsheadDeck.prefix(count))
    }

    private func fittedWidth(count: Int, tileWidth: CGFloat, offered: CGFloat) -> CGFloat {
        let view = CardHandView(tiles: hand(count), tileWidth: tileWidth)
        let controller = UIHostingController(rootView: view)
        return controller.sizeThatFits(
            in: CGSize(width: offered, height: .greatestFiniteMagnitude)
        ).width
    }

    /// The narrowest card is 30pt, so a row of n cards is never narrower than
    /// n * 30 + (n - 1) * 6 (210pt for six, 246pt for seven). Below that
    /// the hand bottoms out at the floor; above it the hand must fit. Real
    /// screens are at least 288pt wide inside the 16pt page padding.
    func testHandNeverExceedsOfferedWidth() {
        for offered in [200, 232, 268, 288, 320] as [CGFloat] {
            for shape in shapes {
                let perRow = CGFloat(min(shape.count, 7))
                let floorWidth = perRow * 30 + (perRow - 1) * gap
                let width = fittedWidth(count: shape.count, tileWidth: shape.width, offered: offered)
                XCTAssertLessThanOrEqual(
                    width, max(offered, floorWidth) + 0.5,
                    "\(shape.label) at \(shape.width)pt is \(width)pt wide in \(offered)pt"
                )
                if offered >= 288 {
                    XCTAssertLessThanOrEqual(width, offered + 0.5, shape.label)
                }
            }
        }
    }

    func testWideScreenKeepsTheDesignWidth() {
        for shape in shapes {
            let perRow = CGFloat(min(shape.count, 7))
            let design = perRow * shape.width + (perRow - 1) * gap
            let width = fittedWidth(count: shape.count, tileWidth: shape.width, offered: 500)
            XCTAssertEqual(width, design, accuracy: 0.5, shape.label)
        }
    }
}
