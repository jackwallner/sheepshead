import SwiftUI
import UIKit
import XCTest
@testable import Sheepshead

@MainActor
final class PracticeRecordStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: PracticeRecordStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "PracticeRecordStoreTests")!
        defaults.removePersistentDomain(forName: "PracticeRecordStoreTests")
        store = PracticeRecordStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "PracticeRecordStoreTests")
        super.tearDown()
    }

    private let room = "card-room"

    func testRecordsAccuracy() {
        store.record(itemID: "q1", roomID: room, correct: true)
        store.record(itemID: "q1", roomID: room, correct: false)
        let record = store.records["q1"]
        XCTAssertEqual(record?.attempts, 2)
        XCTAssertEqual(record?.correct, 1)
        XCTAssertEqual(record?.accuracy, 0.5)
    }

    /// A missed item goes into the queue; two clean answers retire it. Without
    /// the second condition an item would either nag forever or vanish on the
    /// first lucky guess.
    func testMissedItemEntersAndLeavesTheQueue() {
        let id = SessionBuilder.choiceItems(in: room, includePro: true)[0].id
        store.record(itemID: id, roomID: room, correct: false)
        XCTAssertEqual(store.reviewQueue(), [id])

        store.record(itemID: id, roomID: room, correct: true)
        XCTAssertEqual(store.reviewQueue(), [], "One correct answer schedules it a day out")

        store.record(itemID: id, roomID: room, correct: true)
        XCTAssertFalse(store.records[id]!.needsReview, "Two in a row retires it")
    }

    func testQueueRanksWorstFirst() {
        let items = SessionBuilder.choiceItems(in: room, includePro: true)
        let id = items[0].id
        let otherID = items[1].id
        // The first item has lower accuracy, so it should lead.
        for correct in [false, false, false] {
            store.record(itemID: id, roomID: room, correct: correct)
        }
        store.record(itemID: otherID, roomID: room, correct: true)
        store.record(itemID: otherID, roomID: room, correct: false)
        XCTAssertEqual(store.reviewQueue().first, id)
    }

    /// Generated items mint a new id per question. They must roll up onto one
    /// per-skill row and must never enter the review queue, or the queue would
    /// fill with questions that can never be shown again.
    func testGeneratedItemsCollapseAndStayOutOfTheQueue() {
        let prefix = PracticeSkill.handReading.itemPrefix
        store.record(itemID: prefix + "a", roomID: room, correct: false)
        store.record(itemID: prefix + "b", roomID: room, correct: true)

        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records[PracticeSkill.handReading.rawValue]?.attempts, 2)
        XCTAssertTrue(store.reviewQueue().isEmpty)
        XCTAssertEqual(store.dueCount, 0)
    }

    func testOnlyReplayableMistakesAreDueAfterReload() throws {
        var supported: [String] = []
        var unsupported: [String] = ["removed-item"]
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                switch drill.kind {
                case .quiz(let questions): supported += questions.map(\.id)
                case .handMatch(let questions): supported += questions.map(\.id)
                case .flashcards(let cards):
                    supported += cards.filter { $0.choice != nil }.map(\.id)
                    unsupported += cards.filter { $0.choice == nil }.map(\.id)
                case .discard(let scenarios): unsupported += scenarios.map(\.id)
                }
            }
        }
        XCTAssertFalse(supported.isEmpty)
        XCTAssertGreaterThan(unsupported.count, 1)
        // Legacy records have no reviewSuppressed flag. Filter them on read too.
        let legacy = Dictionary(uniqueKeysWithValues: (supported + unsupported).map {
            ($0, PracticeRecord(attempts: 1, roomID: room))
        })
        defaults.set(try JSONEncoder().encode(legacy), forKey: "practice.records")
        let reloaded = PracticeRecordStore(defaults: defaults)
        let queue = reloaded.reviewQueue(limit: legacy.count)
        XCTAssertEqual(reloaded.dueCount, Set(supported).count)
        XCTAssertEqual(Set(queue), Set(supported))
        XCTAssertEqual(SessionBuilder.reviewSession(ids: queue, includePro: true).map(\.id), queue)
        let limited = reloaded.reviewQueue(limit: 3)
        XCTAssertEqual(limited.count, 3)
        XCTAssertEqual(SessionBuilder.reviewSession(ids: limited, includePro: true).count, 3)
        XCTAssertEqual(reloaded.totalAttempts, legacy.count, "Keep unsupported history for stats")
    }

    func testUnsupportedMissesNeverOfferReview() {
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                switch drill.kind {
                case .discard(let scenarios):
                    for scenario in scenarios {
                        store.record(itemID: scenario.id, roomID: room.id, correct: false)
                    }
                case .flashcards(let cards):
                    for card in cards where card.choice == nil {
                        store.record(itemID: card.id, roomID: room.id, correct: false)
                    }
                default: break
                }
            }
        }
        XCTAssertGreaterThan(store.totalAttempts, 0)
        XCTAssertEqual(store.dueCount, 0)
        XCTAssertTrue(store.reviewQueue().isEmpty)
    }

    func testEmptyRunsDoNotCompleteSessions() async throws {
        let progress = ProgressStore(defaults: defaults)
        let drill = SessionBuilder.reviewDrill
        let screens: [(AnyView, Int)] = [
            (AnyView(PracticeRunView(mode: .review)), 0),
            (AnyView(DrillCompleteView(drill: drill, score: 0, total: 0)), 0),
            (AnyView(DrillCompleteView(drill: drill, score: 1, total: 1)), 1)
        ]
        for (screen, expectedSessions) in screens {
            let view = screen
                .environmentObject(progress)
                .environmentObject(SubscriptionService.shared)
            let controller = UIHostingController(rootView: view)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = controller
            window.isHidden = false
            controller.view.layoutIfNeeded()
            controller.beginAppearanceTransition(true, animated: false)
            controller.endAppearanceTransition()
            defer {
                window.isHidden = true
                window.rootViewController = nil
            }
            try await Task.sleep(for: .milliseconds(300))
            XCTAssertEqual(progress.totalSessions, expectedSessions)
            XCTAssertEqual(progress.streakCount, expectedSessions)
            XCTAssertEqual(progress.completions(for: drill.id), expectedSessions)
        }
    }

    func testRoomStatsAggregate() {
        store.record(itemID: "q1", roomID: "card-room", correct: true)
        store.record(itemID: "q2", roomID: "card-room", correct: false)
        store.record(itemID: "q3", roomID: "trump-room", correct: true)

        let stats = store.roomStats()
        XCTAssertEqual(stats.count, 2)
        let cardRoom = stats.first { $0.id == "card-room" }
        XCTAssertEqual(cardRoom?.attempts, 2)
        XCTAssertEqual(cardRoom?.accuracy, 0.5)
        XCTAssertEqual(store.overallAccuracy, 2.0 / 3.0, accuracy: 0.0001)
    }

    func testChallengeScoreKeepsTheBest() {
        store.recordChallengeScore(12)
        store.recordChallengeScore(7)
        XCTAssertEqual(store.bestChallengeScore, 12)
    }

    func testPersistsAcrossInstances() {
        store.record(itemID: "q1", roomID: room, correct: true)
        let reloaded = PracticeRecordStore(defaults: defaults)
        XCTAssertEqual(reloaded.records["q1"]?.attempts, 1)
    }

    func testResetClearsEverything() {
        store.record(itemID: "q1", roomID: room, correct: true)
        store.recordChallengeScore(9)
        store.resetAll()
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertEqual(store.bestChallengeScore, 0)
        XCTAssertTrue(PracticeRecordStore(defaults: defaults).records.isEmpty)
    }
}

final class WhatsNewTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "WhatsNewTests")!
        defaults.removePersistentDomain(forName: "WhatsNewTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "WhatsNewTests")
        super.tearDown()
    }

    func testNeverShownBeforeOnboarding() {
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: false, defaults: defaults))
    }

    /// A player updating from a build that predates the feature has no stored
    /// marker at all. That is exactly who the sheet is for, but only when the
    /// running version actually has notes: a patch release with nothing
    /// player-visible ships no entry, and must show no sheet.
    func testShownToAnUpgraderWithNoMarker() {
        XCTAssertEqual(
            WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults),
            WhatsNew.currentRelease != nil
        )
    }

    func testShownOnlyOnce() {
        WhatsNew.markSeen(defaults: defaults)
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults))
    }

    func testFreshInstallBaselineSuppressesIt() {
        WhatsNew.markCurrentAsBaseline(defaults: defaults)
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults))
    }

    /// Checks every entry, not just the running version's. A patch release with
    /// no notes is legitimate, and `try!` on a nil unwrap used to trap and take
    /// the rest of the test process down with it.
    func testReleaseNotesAreWellFormed() {
        XCTAssertFalse(WhatsNew.releases.isEmpty)
        XCTAssertEqual(
            Set(WhatsNew.releases.map(\.version)).count,
            WhatsNew.releases.count,
            "One entry per version"
        )
        for release in WhatsNew.releases {
            XCTAssertFalse(release.items.isEmpty, release.version)
            XCTAssertEqual(
                Set(release.items.map(\.id)).count,
                release.items.count,
                "Duplicate item id in \(release.version)"
            )
            for item in release.items {
                XCTAssertFalse(item.title.isEmpty, release.version)
                XCTAssertFalse(item.body.isEmpty, release.version)
                XCTAssertFalse(item.body.contains("\u{2014}"), "No em dashes in copy")
                XCTAssertFalse(item.title.contains("\u{2014}"), "No em dashes in copy")
            }
        }
    }

    /// The sheet reads `currentRelease`: the newest entry at or below the
    /// bundle's version, so an entry authored for a later version never shows.
    func testCurrentReleaseIsNotNewerThanTheRunningVersion() {
        guard let release = WhatsNew.currentRelease else { return }
        XCTAssertFalse(WhatsNew.isOlder(WhatsNew.currentVersion, than: release.version))
    }

    /// A player who skipped a version still sees the last notes, once; a
    /// player who already saw them does not see them again on a patch build.
    func testPatchReleaseCarriesTheLastNotesOnce() {
        guard let release = WhatsNew.currentRelease else { return }
        defaults.set("1.0", forKey: "whatsnew.lastSeenVersion")
        XCTAssertEqual(
            WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults),
            WhatsNew.isOlder("1.0", than: release.version)
        )
        defaults.set(release.version, forKey: "whatsnew.lastSeenVersion")
        XCTAssertFalse(WhatsNew.shouldPresent(hasOnboarded: true, defaults: defaults))
        XCTAssertTrue(WhatsNew.isOlder("1.4.1", than: "1.4.10"))
    }
}
