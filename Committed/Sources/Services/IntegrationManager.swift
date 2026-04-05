import Foundation
import SwiftUI

@MainActor
class IntegrationManager: ObservableObject {
    let fatebook: FatebookService
    let reminders = RemindersService()
    let streaks = StreaksService()
    let obsidian: ObsidianService

    @Published var reminderItems: [ReminderItem] = []
    @Published var streakItems: [StreakItem] = []
    @Published var longTermGoals: [LongTermGoal] = []
    @Published var lastSyncTime: Date?

    // Long term goals loaded from config file
    private var longTermGoalConfigs: [(id: String, url: String)] {
        let configPath = NSHomeDirectory() + "/Library/Application Support/Committed/goals.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let goals = try? JSONDecoder().decode([GoalConfig].self, from: data) else {
            return []
        }
        return goals.map { (id: $0.questionId, url: $0.url) }
    }

    private struct GoalConfig: Codable {
        let questionId: String
        let url: String
    }

    init() {
        let config = AppConfig.shared
        self.fatebook = FatebookService(apiKey: config.fatebookAPIKey)
        self.obsidian = ObsidianService(vaultPath: config.obsidianVaultPath)
    }

    func syncAll() async {
        async let remindersResult = reminders.fetchRemindersWithDueDates()
        async let streaksResult = streaks.fetchStreaks()
        async let goalsResult = fetchLongTermGoals()

        let (r, s, g) = await (remindersResult, streaksResult, goalsResult)
        reminderItems = r
        streakItems = s
        longTermGoals = g
        lastSyncTime = Date()
    }

    private func fetchLongTermGoals() async -> [LongTermGoal] {
        var goals: [LongTermGoal] = []
        let iso = ISO8601DateFormatter()
        let configs = longTermGoalConfigs

        for config in configs {
            if let response = try? await fatebook.getQuestion(questionId: config.id) {
                let title = response.title ?? config.id
                let prob = response.forecasts?.last?.forecast ?? 0
                let resolveBy: Date
                if let dateStr = response.resolveBy, let d = iso.date(from: dateStr) {
                    resolveBy = d
                } else {
                    resolveBy = Date.distantFuture
                }

                goals.append(LongTermGoal(
                    id: config.id,
                    title: title,
                    probability: prob,
                    resolveBy: resolveBy,
                    url: config.url
                ))
            }
        }
        return goals
    }

    func createFatebookForecast(title: String, deadline: Date, probability: Double) async -> String? {
        let questionTitle = "Will I complete '\(title)' by deadline?"
        return try? await fatebook.createQuestion(
            title: questionTitle,
            resolveBy: deadline,
            forecast: probability
        )
    }

    func completeReminder(id: String) async {
        _ = await reminders.completeReminder(id: id)
        reminderItems = await reminders.fetchRemindersWithDueDates()
    }

    func completeStreak(title: String) async {
        await streaks.markCompleted(title: title)
        streakItems = await streaks.fetchStreaks()
    }

    func createReminder(title: String, deadline: Date, probability: Double) async -> String? {
        let notes = "P(complete)=\(Int(probability * 100))% | Created by Committed"
        return await reminders.createReminder(title: title, dueDate: deadline, notes: notes)
    }

    func writePreMortemToObsidian(commitment: String, risks: [String]) async {
        await obsidian.writePreMortem(commitment: commitment, risks: risks, date: Date())
    }

    func writePostMortemToObsidian(commitment: String, outcome: String, whatWorked: String, whatFailed: String, lessons: String, succeeded: Bool) async {
        await obsidian.writePostMortem(
            commitment: commitment,
            outcome: outcome,
            whatWorked: whatWorked,
            whatFailed: whatFailed,
            lessons: lessons,
            succeeded: succeeded,
            date: Date()
        )
    }
}
