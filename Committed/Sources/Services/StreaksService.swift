import Foundation

final class StreaksService: Sendable {
    private var cachePath: String {
        NSHomeDirectory() + "/Library/Application Support/Committed/streaks-cache.json"
    }

    func markCompleted(title: String) async {
        guard var items = loadCache() else { return }
        if let idx = items.firstIndex(where: { $0.title == title }) {
            items[idx] = StreakCacheItem(
                title: items[idx].title,
                currentStreak: items[idx].currentStreak + 1,
                bestStreak: max(items[idx].bestStreak, items[idx].currentStreak + 1),
                status: "Y",
                targetTime: items[idx].targetTime
            )
            saveCache(items)
        }
    }

    func markFailed(title: String) async {
        guard var items = loadCache() else { return }
        if let idx = items.firstIndex(where: { $0.title == title }) {
            items[idx] = StreakCacheItem(
                title: items[idx].title,
                currentStreak: 0,
                bestStreak: items[idx].bestStreak,
                status: "F",
                targetTime: items[idx].targetTime
            )
            saveCache(items)
        }
    }

    func resetDaily() async {
        guard var items = loadCache() else { return }
        for i in items.indices {
            // Reset status for new day but keep streaks
            if items[i].status == "Y" {
                // Keep the streak going
            } else if items[i].status == "F" || items[i].status == "N" {
                items[i] = StreakCacheItem(
                    title: items[i].title,
                    currentStreak: 0,
                    bestStreak: items[i].bestStreak,
                    status: "N",
                    targetTime: items[i].targetTime
                )
            }
        }
        saveCache(items)
    }

    private func loadCache() -> [StreakCacheItem]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: cachePath)) else { return nil }
        return try? JSONDecoder().decode([StreakCacheItem].self, from: data)
    }

    private func saveCache(_ items: [StreakCacheItem]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(items) {
            try? data.write(to: URL(fileURLWithPath: cachePath))
        }
    }

    func fetchStreaks() async -> [StreakItem] {
        guard let items = loadCache() else { return [] }

        return items.map {
            StreakItem(
                title: $0.title,
                currentStreak: $0.currentStreak,
                bestStreak: $0.bestStreak,
                status: $0.status,
                targetTime: $0.targetTime
            )
        }.sorted { ($0.targetTime ?? "99:99") < ($1.targetTime ?? "99:99") }
    }
}

struct StreakCacheItem: Codable {
    let title: String
    let currentStreak: Int
    let bestStreak: Int
    let status: String
    let targetTime: String?
}

struct StreakItem: Identifiable {
    let id = UUID()
    let title: String
    let currentStreak: Int
    let bestStreak: Int
    let status: String
    let targetTime: String?

    var completedToday: Bool {
        status == "Y"
    }

    var isPastTargetTime: Bool {
        guard let time = targetTime else { return false }
        let parts = time.components(separatedBy: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return false }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = h
        comps.minute = m
        guard let target = Calendar.current.date(from: comps) else { return false }
        return Date() > target
    }

    var formattedTime: String? {
        guard let time = targetTime else { return nil }
        let parts = time.components(separatedBy: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let min = Int(parts[1]) else { return time }
        let h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let ampm = hour >= 12 ? "PM" : "AM"
        return "\(h):\(String(format: "%02d", min)) \(ampm)"
    }
}
