import Foundation

@MainActor
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    @Published private(set) var streakCount: Int
    @Published private(set) var totalSessions: Int
    @Published private(set) var completions: [String: Int]
    @Published private(set) var seenItems: Set<String>
    @Published private(set) var missedItems: Set<String>

    private let defaults: UserDefaults

    private enum Keys {
        static let streakCount = "progress.streakCount"
        static let lastActiveDay = "progress.lastActiveDay"
        static let totalSessions = "progress.totalSessions"
        static let completions = "progress.completions"
        static let hasOnboarded = "progress.hasOnboarded"
        static let reviewGateShown = "progress.reviewGateShown"
        static let seenItems = "progress.seenItems"
        static let missedItems = "progress.missedItems"
        static let lastQuickSessionDay = "progress.lastQuickSessionDay"
        static let sessionsAtOnboarding = "progress.sessionsAtOnboarding"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        streakCount = defaults.integer(forKey: Keys.streakCount)
        totalSessions = defaults.integer(forKey: Keys.totalSessions)
        completions = (defaults.dictionary(forKey: Keys.completions) as? [String: Int]) ?? [:]
        seenItems = Set(defaults.stringArray(forKey: Keys.seenItems) ?? [])
        missedItems = Set(defaults.stringArray(forKey: Keys.missedItems) ?? [])
    }

    var hasOnboarded: Bool {
        get { defaults.bool(forKey: Keys.hasOnboarded) }
        set { defaults.set(newValue, forKey: Keys.hasOnboarded) }
    }

    /// Sessions finished before onboarding ended: the tour's closing
    /// practice. Players who onboarded earlier have none stored (0).
    var sessionsAtOnboarding: Int {
        get { defaults.integer(forKey: Keys.sessionsAtOnboarding) }
        set { defaults.set(newValue, forKey: Keys.sessionsAtOnboarding) }
    }

    /// True once the player has finished a practice of their own after
    /// onboarding. Home's extras wait for it, so the first Home after the tour
    /// is the plain lobby.
    var hasPracticedSinceOnboarding: Bool { totalSessions > sessionsAtOnboarding }

    func completions(for drillID: String) -> Int {
        completions[drillID] ?? 0
    }

    func roomProgress(_ room: Room) -> Double {
        guard !room.drills.isEmpty else { return 0 }
        let done = room.drills.filter { completions(for: $0.id) > 0 }.count
        return Double(done) / Double(room.drills.count)
    }

    func recordSession(drillID: String, now: Date = Date(), calendar: Calendar = .gregorianLocal) {
        completions[drillID, default: 0] += 1
        totalSessions += 1
        bumpStreak(now: now, calendar: calendar)
        defaults.set(completions, forKey: Keys.completions)
        defaults.set(totalSessions, forKey: Keys.totalSessions)
    }

    /// The streak as it stands right now. `streakCount` only changes when a
    /// drill is finished, so after a missed day it still held the old number
    /// and Home showed a streak the player had already lost.
    func currentStreak(now: Date = Date(), calendar: Calendar = .gregorianLocal) -> Int {
        guard let last = storedDay(forKey: Keys.lastActiveDay, calendar: calendar) else { return streakCount }
        let gap = Self.days(from: last, to: Self.dayKey(now, calendar: calendar)) ?? 0
        return gap > 1 ? 0 : streakCount
    }

    /// Streak counts consecutive calendar days with at least one finished drill.
    private func bumpStreak(now: Date, calendar: Calendar) {
        let today = Self.dayKey(now, calendar: calendar)

        if let last = storedDay(forKey: Keys.lastActiveDay, calendar: calendar) {
            let gap = Self.days(from: last, to: today) ?? 0
            if gap == 1 {
                streakCount += 1
            } else if gap > 1 {
                streakCount = 1
            } else if gap < 0 {
                // The clock went backwards (travel, a manual change). Keep the
                // later day so the streak is not counted twice on the way back.
                return
            } // gap == 0: same day, streak unchanged
        } else {
            streakCount = 1
        }
        defaults.set(today, forKey: Keys.lastActiveDay)
        defaults.set(streakCount, forKey: Keys.streakCount)
    }

    // MARK: - Stored days

    /// A calendar day as "yyyy-MM-dd", the date the phone showed then. The
    /// days used to be stored as that day's midnight, an instant: read back
    /// in a zone further west it fell on the evening before, so a westward
    /// trip broke the streak, counted one day twice, and reopened Get Started.
    nonisolated static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Whole days from one day key to another, whatever the zone.
    nonisolated static func days(from start: String, to end: String) -> Int? {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        func date(_ key: String) -> Date? {
            let parts = key.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { return nil }
            return utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
        }
        guard let from = date(start), let to = date(end) else { return nil }
        return utc.dateComponents([.day], from: from, to: to).day
    }

    /// The stored day key. Builds before this stored a local midnight
    /// instead; the nearest midnight to that instant in today's zone is the
    /// day it meant, for any trip of less than twelve hours either way.
    private func storedDay(forKey key: String, calendar: Calendar) -> String? {
        if let day = defaults.string(forKey: key) { return day }
        guard let midnight = defaults.object(forKey: key) as? Date else { return nil }
        return Self.dayKey(midnight.addingTimeInterval(12 * 3600), calendar: calendar)
    }

    /// Item-level memory that feeds the Get Started mix: anything answered wrong
    /// (or self-graded "again") comes back first; unseen items come next.
    func recordItem(id: String, correct: Bool) {
        seenItems.insert(id)
        if correct {
            missedItems.remove(id)
        } else {
            missedItems.insert(id)
        }
        defaults.set(Array(seenItems), forKey: Keys.seenItems)
        defaults.set(Array(missedItems), forKey: Keys.missedItems)
    }

    /// Whether `id` is in the seen and missed sets, taken before grading so
    /// an Undo can put both back.
    struct ItemMark: Equatable {
        let seen: Bool
        let missed: Bool
    }

    func itemMark(id: String) -> ItemMark {
        ItemMark(seen: seenItems.contains(id), missed: missedItems.contains(id))
    }

    func restoreItem(id: String, to mark: ItemMark) {
        if mark.seen { seenItems.insert(id) } else { seenItems.remove(id) }
        if mark.missed { missedItems.insert(id) } else { missedItems.remove(id) }
        defaults.set(Array(seenItems), forKey: Keys.seenItems)
        defaults.set(Array(missedItems), forKey: Keys.missedItems)
    }

    // MARK: - Daily Quick Session

    /// Get Started is a once-a-day ritual: a fresh mix each day, and once
    /// today's is done the Home card rests until tomorrow rather than handing
    /// back the same questions (repeating a question you just answered teaches
    /// nothing). Missed items still return on later days as spaced repetition.
    func quickSessionCompletedToday(now: Date = Date(), calendar: Calendar = .gregorianLocal) -> Bool {
        storedDay(forKey: Keys.lastQuickSessionDay, calendar: calendar) == Self.dayKey(now, calendar: calendar)
    }

    func markQuickSessionCompleted(now: Date = Date(), calendar: Calendar = .gregorianLocal) {
        defaults.set(Self.dayKey(now, calendar: calendar), forKey: Keys.lastQuickSessionDay)
    }

    /// Clears every practice stat. Leaves onboarding and purchases alone.
    func resetAll() {
        streakCount = 0
        totalSessions = 0
        completions = [:]
        seenItems = []
        missedItems = []
        defaults.removeObject(forKey: Keys.streakCount)
        defaults.removeObject(forKey: Keys.lastActiveDay)
        defaults.removeObject(forKey: Keys.totalSessions)
        defaults.removeObject(forKey: Keys.completions)
        defaults.removeObject(forKey: Keys.seenItems)
        defaults.removeObject(forKey: Keys.missedItems)
        defaults.removeObject(forKey: Keys.reviewGateShown)
        defaults.removeObject(forKey: Keys.lastQuickSessionDay)
        defaults.removeObject(forKey: Keys.sessionsAtOnboarding)
    }
}
