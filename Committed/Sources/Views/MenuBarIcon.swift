import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var integrationManager: IntegrationManager
    @State private var now = Date()

    // Update every second when close, every 30s otherwise
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var nextItem: (title: String, deadline: Date)? {
        var candidates: [(String, Date)] = []

        // Active commitments
        for c in store.activeCommitments where c.deadline > now {
            candidates.append((c.title, c.deadline))
        }

        // Pending streaks (not completed, not yet past target time)
        for s in integrationManager.streakItems where !s.completedToday && !s.isPastTargetTime {
            if let ts = s.targetTime {
                let parts = ts.components(separatedBy: ":")
                if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                    var comps = Calendar.current.dateComponents([.year, .month, .day], from: now)
                    comps.hour = h
                    comps.minute = m
                    if let target = Calendar.current.date(from: comps), target > now {
                        candidates.append((s.title, target))
                    }
                }
            }
        }

        return candidates.sorted(by: { $0.1 < $1.1 }).first
    }

    private func countdown(to date: Date) -> String {
        let interval = date.timeIntervalSince(now)
        if interval <= 0 { return "NOW" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        if minutes < 30 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "\(minutes)m"
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")

            if let next = nextItem {
                let short = next.title.prefix(12)
                Text("\(short) \(countdown(to: next.deadline))")
                    .font(.system(size: 11, design: .monospaced))
            }
        }
        .onReceive(timer) { _ in
            now = Date()
        }
    }
}
