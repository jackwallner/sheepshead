import Foundation

/// How well a room is actually known, as opposed to how much of it has been
/// opened. Finishing a drill once, badly, does not make a room known: an item
/// counts only after two correct answers in a row, and it stops counting once
/// its review interval has lapsed far enough that the player would probably
/// miss it again.
enum MasteryLevel: Int, Comparable, Sendable {
    case untouched
    case learning
    case solid
    case sharp

    static func < (lhs: MasteryLevel, rhs: MasteryLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .untouched: return "Not started"
        case .learning: return "Learning"
        case .solid: return "Solid"
        case .sharp: return "Sharp"
        }
    }

    var icon: String {
        switch self {
        case .untouched: return "circle.dotted"
        case .learning: return "book.fill"
        case .solid: return "checkmark.seal.fill"
        case .sharp: return "star.fill"
        }
    }

    /// What earns the next level, phrased as the thing to go do.
    var nextStep: String {
        switch self {
        case .untouched: return "Answer a few questions here to start tracking."
        case .learning: return "Get each question right twice running to lock it in."
        case .solid: return "Keep going. Sharp means nearly everything here is holding."
        case .sharp: return "Come back now and then so it stays sharp."
        }
    }

    /// Thresholds are on coverage, not accuracy: three perfect answers do not
    /// mean the room is known. A room practised but not yet locked in reads as
    /// Learning, never as untouched.
    static func level(known: Int, total: Int, attempted: Int = 0) -> MasteryLevel {
        guard total > 0 else { return .untouched }
        guard known > 0 else { return attempted > 0 ? .learning : .untouched }
        let fraction = Double(known) / Double(total)
        switch fraction {
        case 0.85...: return .sharp
        case 0.4..<0.85: return .solid
        default: return .learning
        }
    }
}

struct RoomMastery: Identifiable, Sendable {
    let roomID: String
    let known: Int
    let total: Int
    let level: MasteryLevel

    var id: String { roomID }
    var fraction: Double { total == 0 ? 0 : Double(known) / Double(total) }
}

extension PracticeRecord {
    /// Known means answered right twice running and not yet a full interval
    /// past due. The slack is deliberate: review wants an item back the moment
    /// it is due, but mastery should not evaporate the same day.
    func isKnown(now: Date = Date()) -> Bool {
        guard streak >= 2 else { return false }
        guard intervalDays > 0 else { return true }
        return now < dueDate.addingTimeInterval(intervalDays * 86_400)
    }
}

extension PracticeRecordStore {
    /// Mastery for one room, measured against what this player can open. Locked
    /// Sheepshead+ sets are excluded for a free player: a denominator nobody
    /// can close is a nag, not a goal.
    func mastery(for room: Room, isMember: Bool, now: Date = Date()) -> RoomMastery {
        let ids = Set(Self.trackableItemIDs(in: room, isMember: isMember))
        guard !ids.isEmpty else {
            return RoomMastery(roomID: room.id, known: 0, total: 0, level: .untouched)
        }
        let known = ids.filter { records[$0]?.isKnown(now: now) == true }.count
        let attempted = ids.filter { records[$0] != nil }.count
        return RoomMastery(
            roomID: room.id,
            known: known,
            total: ids.count,
            level: MasteryLevel.level(known: known, total: ids.count, attempted: attempted)
        )
    }

    func masteryByRoom(isMember: Bool, now: Date = Date()) -> [RoomMastery] {
        DrillLibrary.rooms.map { mastery(for: $0, isMember: isMember, now: now) }
    }

    /// Every gradeable item id in a room the player can open. Flashcards count
    /// whether they are self-tested or self-graded, because both are recorded.
    static func trackableItemIDs(in room: Room, isMember: Bool) -> [String] {
        var ids: [String] = []
        for drill in room.drills where !room.isLocked(drill, isMember: isMember) {
            switch drill.kind {
            case .quiz(let questions): ids += questions.map(\.id)
            case .handMatch(let questions): ids += questions.map(\.id)
            case .discard(let scenarios): ids += scenarios.map(\.id)
            case .flashcards(let cards): ids += cards.map(\.id)
            }
        }
        return ids
    }

    // MARK: - Skill coaching

    /// Accuracy per generated skill. Generated questions roll up onto one row
    /// per skill, so this is the only place a player's "trick winner" accuracy
    /// is visible.
    struct SkillStat: Identifiable {
        let skill: PracticeSkill
        let attempts: Int
        let correct: Int
        var id: String { skill.rawValue }
        var accuracy: Double { attempts == 0 ? 0 : Double(correct) / Double(attempts) }
    }

    func skillStats() -> [SkillStat] {
        PracticeSkill.allCases.compactMap { skill in
            guard let record = records[skill.rawValue], record.attempts > 0 else { return nil }
            return SkillStat(skill: skill, attempts: record.attempts, correct: record.correct)
        }
    }

    /// The generated skill to coach next: lowest accuracy once there are enough
    /// answers to mean it, and only if it is actually shaky.
    func skillToCoach(minimumAttempts: Int = 8, accuracyBelow: Double = 0.8) -> SkillStat? {
        skillStats()
            .filter { $0.attempts >= minimumAttempts && $0.accuracy < accuracyBelow }
            .min { $0.accuracy < $1.accuracy }
    }

    /// The room worth working on next: the least-mastered room that has been
    /// started. A room never opened is new, not weak.
    func roomToWorkOn(isMember: Bool, now: Date = Date()) -> RoomMastery? {
        masteryByRoom(isMember: isMember, now: now)
            .filter { $0.level != .untouched && $0.level != .sharp }
            .min { $0.fraction < $1.fraction }
    }
}
