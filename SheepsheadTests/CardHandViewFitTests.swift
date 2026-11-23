import SwiftUI
import UIKit
import XCTest
@testable import Sheepshead

/// A hand is never wider than the room it is offered. The bury drill deals
/// eight 48pt cards, seven to a row: 372pt. With Display Zoom a 6.1" iPhone
/// is 320pt wide and the drill offers 288pt, so a fixed row lost cards off
/// both screen edges.
@MainActor
final class CardHandViewFitTests: XCTestCase {
    private let eight: [PlayingCard] = [.c(12), .s(12), .h(11), .d(11), .d(14), .d(10), .c(14), .h(9)]

    private func size(_ cards: [PlayingCard], tileWidth: CGFloat, in width: CGFloat) -> CGSize {
        let host = UIHostingController(rootView: CardHandView(tiles: cards, tileWidth: tileWidth))
        return host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    func testAHandFitsTheWidthItIsOffered() {
        // The bury drill on a zoomed phone (288) and in Slide Over's question width (268).
        for width in [268, 288, 343] as [CGFloat] {
            let fitted = size(eight, tileWidth: 48, in: width)
            XCTAssertLessThanOrEqual(fitted.width, width + 0.5, "8 cards at 48pt in \(width)pt")
        }
        // Five-card flashcard fronts in a zoomed card (232) and question hands.
        for width in [232, 268, 288] as [CGFloat] {
            for tileWidth in [52, 44] as [CGFloat] {
                let fitted = size(Array(eight.prefix(5)), tileWidth: tileWidth, in: width)
                XCTAssertLessThanOrEqual(fitted.width, width + 0.5, "5 cards at \(tileWidth)pt in \(width)pt")
            }
        }
    }

    func testAHandThatFitsKeepsItsDesign() {
        // Seven 48pt cards and six 6pt gaps on the first row.
        XCTAssertEqual(size(eight, tileWidth: 48, in: 500).width, 7 * 48 + 6 * 6, accuracy: 0.5)
    }
}
