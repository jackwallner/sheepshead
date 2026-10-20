import SwiftUI

/// Practice history: overall accuracy, a bar per room, and the weak spot worth
/// working on next. Free for everyone. Stats about your own effort are not a
/// feature to sell back to you, and a free player who can see they are 58% in
/// the Auction Room has a reason to care about the drills that would fix it.
struct StatsView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @StateObject private var records = PracticeRecordStore.shared

    private var roomStats: [PracticeRecordStore.RoomStat] { records.roomStats() }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if records.totalAttempts == 0 {
                    emptyState
                } else {
                    summaryCard
                    if let weakest = records.weakestRoom(), roomStats.count > 1 {
                        weakSpotCard(weakest)
                    }
                    if subscriptions.isPro, let coach = records.skillToCoach() {
                        coachCard(coach)
                    }
                    masteryCard
                    roomBreakdown
                    if !records.skillStats().isEmpty {
                        skillBreakdown
                    }
                }
                streakCard
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Your Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Cards

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.jade.opacity(0.5))
            Text("No practice yet")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text("Answer a few questions and your accuracy for every room shows up here.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .themedCard()
        .padding(.top, 12)
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            metric(value: percent(records.overallAccuracy), caption: "accuracy", color: Theme.jade)
            divider
            metric(value: "\(records.totalAttempts)", caption: "answered", color: Theme.ink)
            divider
            metric(value: "\(records.bestChallengeScore)", caption: "best challenge", color: Theme.coral)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .themedCard()
        .padding(.top, 12)
    }

    private func metric(value: String, caption: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.display(26))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(caption)
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.rule)
            .frame(width: 1, height: 34)
    }

    private func weakSpotCard(_ stat: PracticeRecordStore.RoomStat) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "target")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.coral)
                .frame(width: 38, height: 38)
                .background(Theme.coral.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Work on \(stat.name)")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("\(percent(stat.accuracy)) right across \(stat.attempts) questions, your lowest so far.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .themedCard(corner: 16)
    }

    private var roomBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BY ROOM")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            ForEach(roomStats) { stat in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(stat.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(percent(stat.accuracy))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(barColor(stat.accuracy))
                            .monospacedDigit()
                    }
                    accuracyBar(stat.accuracy)
                    Text("\(stat.correct) of \(stat.attempts) right")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
    }

    private var masteryCard: some View {
        let rooms = records.masteryByRoom(isMember: subscriptions.isPro)
        return VStack(alignment: .leading, spacing: 14) {
            Text("ROOM MASTERY")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            ForEach(rooms) { mastery in
                if let room = DrillLibrary.room(id: mastery.roomID), mastery.total > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: mastery.level.icon)
                                .foregroundStyle(room.accent)
                                .accessibilityHidden(true)
                            Text(room.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text(mastery.level.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(room.accent)
                        }
                        accuracyBar(mastery.fraction, color: room.accent)
                        Text("\(mastery.known) of \(mastery.total) locked in. \(mastery.level.nextStep)")
                            .font(.caption2)
                            .foregroundStyle(Theme.inkTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
    }

    private var skillBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ENDLESS SKILLS")
                .font(.caption.weight(.heavy))
                .kerning(1.4)
                .foregroundStyle(Theme.inkSecondary)
            ForEach(records.skillStats()) { stat in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(stat.skill.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(percent(stat.accuracy))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(barColor(stat.accuracy))
                            .monospacedDigit()
                    }
                    accuracyBar(stat.accuracy)
                    Text("\(stat.correct) of \(stat.attempts) right")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkTertiary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
    }

    /// The coaching nudge: the one generated skill that is shaky, with a direct
    /// way into it. Only offered to members because Endless Practice is theirs.
    private func coachCard(_ stat: PracticeRecordStore.SkillStat) -> some View {
        NavigationLink {
            PracticeRunView(mode: .endless(stat.skill))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: stat.skill.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.plum)
                    .frame(width: 38, height: 38)
                    .background(Theme.plum.opacity(0.13), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Coach: \(stat.skill.title)")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("\(percent(stat.accuracy)) right across \(stat.attempts) answers. A few more reps will lift it.")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(14)
            .themedCard(corner: 16)
        }
        .buttonStyle(PressableCardStyle())
    }

    private func accuracyBar(_ fraction: Double, color: Color? = nil) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.well)
                Capsule()
                    .fill(color ?? barColor(fraction))
                    .frame(width: max(6, geo.size.width * fraction))
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private var streakCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.coral)
                .frame(width: 38, height: 38)
                .background(Theme.coral.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("\(progress.streakCount)-day streak")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("\(progress.totalSessions) drill\(progress.totalSessions == 1 ? "" : "s") finished")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .themedCard(corner: 16)
    }

    // MARK: - Helpers

    private func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    private func barColor(_ fraction: Double) -> Color {
        if fraction >= 0.8 { return Theme.bamGreen }
        if fraction >= 0.6 { return Theme.gold }
        return Theme.coral
    }
}
