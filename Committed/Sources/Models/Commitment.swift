import Foundation

final class Commitment: Identifiable, Codable, ObservableObject {
    let id: UUID
    var title: String
    var detail: String
    var deadline: Date
    var createdAt: Date
    var completedAt: Date?
    var status: CommitmentStatus
    var source: CommitmentSource
    var sourceID: String?
    var fatebookQuestionID: String?
    var forecastProbability: Double?
    var preMortems: [PreMortem]
    var postMortems: [PostMortem]
    var forecasts: [Forecast]

    var preMortemCompleted: Bool { !preMortems.isEmpty }
    var postMortemCompleted: Bool { !postMortems.isEmpty }
    var isOverdue: Bool { status == .active && Date() > deadline }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(deadline)
    }

    var isDueSoon: Bool {
        let hoursUntil = deadline.timeIntervalSinceNow / 3600
        return hoursUntil > 0 && hoursUntil <= 24
    }

    var timeRemaining: String {
        let interval = deadline.timeIntervalSinceNow
        if interval < 0 {
            return "overdue by \(formatDuration(-interval))"
        }
        return formatDuration(interval)
    }

    init(
        title: String,
        detail: String = "",
        deadline: Date,
        source: CommitmentSource = .manual,
        sourceID: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.deadline = deadline
        self.createdAt = Date()
        self.status = .active
        self.source = source
        self.sourceID = sourceID
        self.preMortems = []
        self.postMortems = []
        self.forecasts = []
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 48 {
            return "\(hours / 24)d"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

enum CommitmentStatus: String, Codable {
    case active, completed, failed, cancelled
}

enum CommitmentSource: String, Codable {
    case manual, reminders, obsidian, streaks
}
