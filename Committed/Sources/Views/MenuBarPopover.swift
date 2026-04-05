import SwiftUI

// Unified item that can be a commitment, reminder, or streak
struct TimelineItem: Identifiable {
    let id = UUID()
    let title: String
    let time: Date?
    let timeString: String?
    let kind: Kind
    let status: ItemStatus
    let probability: Double?
    let brierScore: Double?
    let streakCount: Int?
    let sourceCommitment: Commitment?
    let sourceReminderID: String?
    let hasPreMortem: Bool
    let hasPostMortem: Bool
    let fatebookURL: String?

    enum Kind {
        case commitment, reminder, streak
    }

    enum ItemStatus {
        case pending, completed, failed, overdue
    }

    var sortTime: Date {
        if let time = time { return time }
        // Parse timeString like "07:30" into today's date
        if let ts = timeString {
            let parts = ts.components(separatedBy: ":")
            if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                comps.hour = h
                comps.minute = m
                if let d = Calendar.current.date(from: comps) { return d }
            }
        }
        return Date.distantFuture
    }
}

struct MenuBarPopover: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var overlayManager: OverlayManager
    @EnvironmentObject var integrationManager: IntegrationManager

    @Environment(\.openWindow) private var openWindow
    @State private var showingAddSheet = false

    private var allItems: [TimelineItem] {
        var items: [TimelineItem] = []

        // Commitments
        for c in store.commitments {
            let status: TimelineItem.ItemStatus
            switch c.status {
            case .active: status = c.isOverdue ? .overdue : .pending
            case .completed: status = .completed
            case .failed: status = .failed
            case .cancelled: continue
            }

            var brier: Double? = nil
            if (c.status == .completed || c.status == .failed), let prob = c.forecastProbability {
                brier = BrierScore.calculate(forecast: prob, succeeded: c.status == .completed)
            }

            items.append(TimelineItem(
                title: c.title, time: c.deadline, timeString: nil,
                kind: .commitment, status: status,
                probability: c.forecastProbability, brierScore: brier,
                streakCount: nil, sourceCommitment: c, sourceReminderID: nil,
                hasPreMortem: c.preMortemCompleted, hasPostMortem: c.postMortemCompleted,
                fatebookURL: c.fatebookQuestionID
            ))
        }

        // Reminders (skip ones that match a commitment title to avoid duplicates)
        let commitmentTitles = Set(store.commitments.map { $0.title })
        for r in integrationManager.reminderItems {
            if commitmentTitles.contains(r.title) { continue }
            let rStatus: TimelineItem.ItemStatus
            if r.isCompleted {
                rStatus = .completed
            } else if r.dueDate < Date() {
                rStatus = .failed
            } else {
                rStatus = .pending
            }
            items.append(TimelineItem(
                title: r.title, time: r.dueDate, timeString: nil,
                kind: .reminder, status: rStatus,
                probability: nil, brierScore: nil,
                streakCount: nil, sourceCommitment: nil, sourceReminderID: r.id,
                hasPreMortem: false, hasPostMortem: false,
                fatebookURL: nil
            ))
        }

        // Streaks - auto-fail if past target time and not completed
        let now = Date()
        for s in integrationManager.streakItems {
            let streakStatus: TimelineItem.ItemStatus
            if s.completedToday {
                streakStatus = .completed
            } else if let targetTime = s.targetTime {
                let parts = targetTime.components(separatedBy: ":")
                if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                    var comps = Calendar.current.dateComponents([.year, .month, .day], from: now)
                    comps.hour = h
                    comps.minute = m
                    if let targetDate = Calendar.current.date(from: comps), now > targetDate {
                        streakStatus = .failed
                    } else {
                        streakStatus = .pending
                    }
                } else {
                    streakStatus = .pending
                }
            } else {
                streakStatus = .pending
            }

            items.append(TimelineItem(
                title: s.title, time: nil, timeString: s.targetTime,
                kind: .streak, status: streakStatus,
                probability: nil, brierScore: nil,
                streakCount: s.currentStreak, sourceCommitment: nil, sourceReminderID: nil,
                hasPreMortem: false, hasPostMortem: false,
                fatebookURL: nil
            ))
        }

        return items.sorted { $0.sortTime < $1.sortTime }
    }

    private var todayItems: [TimelineItem] {
        allItems.filter { item in
            // Streaks always show in today
            if item.kind == .streak { return true }
            // Anything due today (any status) or overdue
            guard let t = item.time else { return false }
            return Calendar.current.isDateInToday(t) || item.status == .overdue
        }
    }

    private var pastItems: [TimelineItem] {
        let cutoff = Date().addingTimeInterval(-24 * 3600)
        return allItems.filter { item in
            if item.kind == .streak { return false }
            guard item.status == .completed || item.status == .failed else { return false }
            guard let t = item.time else { return false }
            // Only show in past if NOT today
            return !Calendar.current.isDateInToday(t) && t > cutoff
        }
    }

    private var futureItems: [TimelineItem] {
        allItems.filter { item in
            guard item.status == .pending else { return false }
            if item.kind == .streak { return false }
            guard let t = item.time else { return false }
            return !Calendar.current.isDateInToday(t) && t > Date()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("committed")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    if let score = BrierScore.combinedScore(commitments: store.commitments, streakItems: integrationManager.streakItems) {
                        HStack(spacing: 4) {
                            Text("Brier: \(String(format: "%.2f", score))")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(brierColor(score))
                            Text(BrierScore.rating(score))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 16))
                }.buttonStyle(.plain)

                Button(action: { Task { await integrationManager.syncAll() } }) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 12))
                }.buttonStyle(.plain)

                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Image(systemName: "gear").font(.system(size: 12))
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !todayItems.isEmpty {
                        SectionHeader(title: "TODAY", color: .orange)
                        ForEach(todayItems) { item in
                            TimelineRow(item: item, onAction: { handleAction(item) })
                        }
                    }

                    if !futureItems.isEmpty {
                        SectionHeader(title: "UPCOMING", color: .blue)
                        ForEach(futureItems) { item in
                            TimelineRow(item: item, onAction: { handleAction(item) })
                        }
                    }

                    if !pastItems.isEmpty {
                        SectionHeader(title: "PAST 48H", color: .secondary)
                        ForEach(pastItems) { item in
                            TimelineRow(item: item, onAction: nil)
                        }
                    }

                    if todayItems.isEmpty && futureItems.isEmpty && pastItems.isEmpty {
                        VStack(spacing: 8) {
                            Text("No items yet")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text("Add a commitment with +")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }

                    // Long Term Goals
                    LongTermGoalsSection(goals: integrationManager.longTermGoals)

                    if let syncTime = integrationManager.lastSyncTime {
                        Text("Synced \(syncTime.formatted(.relative(presentation: .named)))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 500)

            Divider()

            HStack {
                Text("\(store.activeCommitments.count) active")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                if let s = BrierScore.combinedScore(commitments: store.commitments, streakItems: integrationManager.streakItems) {
                    Text("48h: \(String(format: "%.2f", s))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(brierColor(s))
                }
                Spacer()

                Button("Track Record") {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                }
                .font(.system(size: 11)).buttonStyle(.plain).foregroundColor(.accentColor)

                Button("Quit") { NSApp.terminate(nil) }
                    .font(.system(size: 11)).buttonStyle(.plain).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 400)
        .sheet(isPresented: $showingAddSheet) {
            AddCommitmentView()
                .environmentObject(store)
                .environmentObject(integrationManager)
        }
    }

    private func handleAction(_ item: TimelineItem) {
        let title = item.title
        switch item.kind {
        case .commitment:
            if let c = item.sourceCommitment {
                overlayManager.showPostMortem(for: c)
            }
        case .reminder:
            Task {
                if let id = item.sourceReminderID {
                    await integrationManager.completeReminder(id: id)
                }
                overlayManager.showOptionalPostMortem(title: title)
            }
        case .streak:
            Task {
                await integrationManager.completeStreak(title: title)
                overlayManager.showOptionalPostMortem(title: title)
            }
        }
    }

    private func brierColor(_ score: Double) -> Color {
        switch score {
        case 0..<0.1: return .green
        case 0.1..<0.2: return .blue
        case 0.2..<0.3: return .yellow
        default: return .red
        }
    }
}

// MARK: - Components

struct SectionHeader: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.top, 4)
    }
}

struct TimelineRow: View {
    let item: TimelineItem
    let onAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            // Status icon
            statusIcon

            // Time
            timeLabel

            // Title + metadata
            VStack(alignment: .leading, spacing: 2) {
                if let fbURL = item.fatebookURL, let url = URL(string: fbURL) {
                    Button(action: { NSWorkspace.shared.open(url) }) {
                        Text(item.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .strikethrough(item.status == .completed)
                            .underline(true, color: .purple.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Open in Fatebook")
                } else {
                    Text(item.title)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .strikethrough(item.status == .completed)
                }

                HStack(spacing: 4) {
                    // Kind badge
                    kindBadge

                    // Probability
                    if let p = item.probability {
                        Text("P=\(Int(p * 100))%")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 3)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(2)
                    }

                    // Brier score
                    if let bs = item.brierScore {
                        Text("BS=\(String(format: "%.2f", bs))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(bs < 0.1 ? .green : bs < 0.25 ? .yellow : .red)
                    }

                    // Streak count
                    if let streak = item.streakCount, streak > 0 {
                        Text("\(streak)d")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.orange)
                    }

                    // Pre/post mortem indicators
                    if item.hasPreMortem {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 8))
                            .foregroundColor(.green)
                    }
                    if item.hasPostMortem {
                        Image(systemName: "doc.text")
                            .font(.system(size: 8))
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            // Actions - only for pending items that can still be completed
            if let action = onAction, item.status == .pending {
                Button(action: action) {
                    Image(systemName: item.kind == .commitment ? "checkmark.circle" : "circle")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help(item.kind == .commitment ? "Complete (post-mortem)" : "Check off")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .overdue:
            Circle().fill(.red).frame(width: 8, height: 8)
        case .pending:
            if item.kind == .streak {
                Image(systemName: "flame")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .frame(width: 8)
            } else {
                Circle().fill(.orange).frame(width: 8, height: 8)
            }
        case .completed:
            if item.kind == .streak {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                    .frame(width: 8)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                    .frame(width: 8)
            }
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 10))
                .foregroundColor(.red)
                .frame(width: 8)
        }
    }

    @ViewBuilder
    private var timeLabel: some View {
        if let ts = item.timeString {
            // Streak time
            let parts = ts.components(separatedBy: ":")
            let h = Int(parts.first ?? "") ?? 0
            let m = Int(parts.last ?? "") ?? 0
            let hDisp = h > 12 ? h - 12 : (h == 0 ? 12 : h)
            let ampm = h >= 12 ? "p" : "a"
            Text("\(hDisp):\(String(format: "%02d", m))\(ampm)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
        } else if let t = item.time {
            if Calendar.current.isDateInToday(t) || item.status == .overdue {
                Text(t.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(item.status == .overdue ? .red : .secondary)
                    .frame(width: 50, alignment: .trailing)
            } else {
                Text(t.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        } else {
            Text("")
                .frame(width: 50)
        }
    }

    @ViewBuilder
    private var kindBadge: some View {
        switch item.kind {
        case .commitment:
            EmptyView()
        case .reminder:
            Text("reminder")
                .font(.system(size: 8))
                .padding(.horizontal, 3)
                .background(Color.cyan.opacity(0.15))
                .cornerRadius(2)
                .foregroundColor(.cyan)
        case .streak:
            Text("streak")
                .font(.system(size: 8))
                .padding(.horizontal, 3)
                .background(Color.green.opacity(0.15))
                .cornerRadius(2)
                .foregroundColor(.green)
        }
    }
}

// MARK: - Long Term Goals

struct LongTermGoal: Identifiable {
    let id: String
    let title: String
    let probability: Double
    let resolveBy: Date
    let url: String
}

struct LongTermGoalsSection: View {
    let goals: [LongTermGoal]

    var body: some View {
        if goals.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                SectionHeader(title: "LONG TERM GOALS", color: .purple)

                ForEach(goals) { goal in
                    Button(action: {
                        if let url = URL(string: goal.url) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.purple)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(goal.title)
                                    .font(.system(size: 12, weight: .medium))

                                HStack(spacing: 6) {
                                    Text("P=\(Int(goal.probability * 100))%")
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(.purple)
                                        .padding(.horizontal, 3)
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(2)

                                    Text("by \(goal.resolveBy.formatted(.dateTime.month(.abbreviated).year()))")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        )
    }
}
