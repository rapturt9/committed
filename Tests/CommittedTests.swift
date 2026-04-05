import Foundation
import Testing
@testable import Committed

// MARK: - Commitment Model

@Test func commitmentCreation() {
    let deadline = Date().addingTimeInterval(86400)
    let c = Commitment(title: "Ship feature", detail: "v2 launch", deadline: deadline)
    #expect(c.title == "Ship feature")
    #expect(c.status == .active)
    #expect(c.source == .manual)
    #expect(!c.preMortemCompleted)
    #expect(!c.postMortemCompleted)
}

@Test func commitmentIsOverdue() {
    let past = Date().addingTimeInterval(-3600)
    let c = Commitment(title: "Late", deadline: past)
    #expect(c.isOverdue)

    let future = Date().addingTimeInterval(3600)
    let c2 = Commitment(title: "Future", deadline: future)
    #expect(!c2.isOverdue)
}

@Test func commitmentOverdueOnlyWhenActive() {
    let past = Date().addingTimeInterval(-3600)
    let c = Commitment(title: "Done", deadline: past)
    c.status = .completed
    #expect(!c.isOverdue)
}

@Test func commitmentIsDueSoon() {
    let soon = Date().addingTimeInterval(12 * 3600)
    let c = Commitment(title: "Soon", deadline: soon)
    #expect(c.isDueSoon)

    let far = Date().addingTimeInterval(48 * 3600)
    let c2 = Commitment(title: "Far", deadline: far)
    #expect(!c2.isDueSoon)
}

@Test func commitmentIsDueToday() {
    var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    comps.hour = 23; comps.minute = 59
    let c = Commitment(title: "Today", deadline: Calendar.current.date(from: comps)!)
    #expect(c.isDueToday)
}

@Test func timeRemainingOverdue() {
    let c = Commitment(title: "Late", deadline: Date().addingTimeInterval(-7200))
    #expect(c.timeRemaining.contains("overdue"))
}

@Test func timeRemainingFuture() {
    let c = Commitment(title: "Future", deadline: Date().addingTimeInterval(7200))
    #expect(!c.timeRemaining.contains("overdue"))
}

@Test func timeRemainingDays() {
    let c = Commitment(title: "Far", deadline: Date().addingTimeInterval(5 * 86400))
    #expect(c.timeRemaining.contains("d"))
}

// MARK: - Pre-Mortem

@Test func preMortemCreation() {
    let pm = PreMortem(risk1: "scope creep", risk2: "API changes", risk3: "testing gaps")
    #expect(pm.risk1 == "scope creep")
    #expect(pm.mitigations == "")
}

@Test func preMortemCompletedFlag() {
    let c = Commitment(title: "Test", deadline: Date())
    #expect(!c.preMortemCompleted)
    c.preMortems.append(PreMortem(risk1: "a", risk2: "b", risk3: "c"))
    #expect(c.preMortemCompleted)
}

// MARK: - Post-Mortem

@Test func postMortemCreation() {
    let pm = PostMortem(outcome: "Shipped", whatWorked: "Standups", whatFailed: "CI", lessonsLearned: "Invest in CI", succeeded: true)
    #expect(pm.succeeded)
    #expect(pm.outcome == "Shipped")
}

@Test func postMortemCompletedFlag() {
    let c = Commitment(title: "Test", deadline: Date())
    #expect(!c.postMortemCompleted)
    c.postMortems.append(PostMortem(outcome: "done", whatWorked: "x", whatFailed: "y", lessonsLearned: "z", succeeded: true))
    #expect(c.postMortemCompleted)
}

// MARK: - Forecast

@Test func forecastCreation() {
    let f = Forecast(probability: 0.85)
    #expect(f.probability == 0.85)
}

@Test func commitmentWithForecast() {
    let c = Commitment(title: "Test", deadline: Date())
    c.forecastProbability = 0.99
    c.forecasts.append(Forecast(probability: 0.99))
    #expect(c.forecastProbability == 0.99)
    #expect(c.forecasts.count == 1)
}

// MARK: - Codable Roundtrip

@Test func commitmentCodableRoundtrip() throws {
    let c = Commitment(title: "Roundtrip", detail: "test", deadline: Date().addingTimeInterval(86400))
    c.forecastProbability = 0.75
    c.forecasts.append(Forecast(probability: 0.75))
    c.preMortems.append(PreMortem(risk1: "a", risk2: "b", risk3: "c", mitigations: "d"))
    c.source = .reminders
    c.fatebookQuestionID = "https://fatebook.io/q/test--abc123"

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(c)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(Commitment.self, from: data)

    #expect(decoded.title == "Roundtrip")
    #expect(decoded.status == .active)
    #expect(decoded.source == .reminders)
    #expect(decoded.forecastProbability == 0.75)
    #expect(decoded.forecasts.count == 1)
    #expect(decoded.preMortems.first?.risk1 == "a")
    #expect(decoded.fatebookQuestionID == "https://fatebook.io/q/test--abc123")
}

@Test func multipleCommitmentsCodable() throws {
    let c1 = Commitment(title: "First", deadline: Date().addingTimeInterval(3600))
    let c2 = Commitment(title: "Second", deadline: Date().addingTimeInterval(7200))
    c2.status = .completed
    c2.completedAt = Date()

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode([c1, c2])

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode([Commitment].self, from: data)

    #expect(decoded.count == 2)
    #expect(decoded[0].title == "First")
    #expect(decoded[1].status == .completed)
}

// MARK: - Status Transitions

@Test func statusTransitions() {
    let c = Commitment(title: "Test", deadline: Date())
    #expect(c.status == .active)
    c.status = .completed
    c.completedAt = Date()
    #expect(c.status == .completed)
    #expect(c.completedAt != nil)
}

@Test func commitmentSources() {
    #expect(Commitment(title: "A", deadline: Date(), source: .manual).source == .manual)
    #expect(Commitment(title: "B", deadline: Date(), source: .reminders).source == .reminders)
    #expect(Commitment(title: "C", deadline: Date(), source: .obsidian).source == .obsidian)
    #expect(Commitment(title: "D", deadline: Date(), source: .streaks).source == .streaks)
}

// MARK: - Config

@Test func appConfigLoads() {
    let config = AppConfig.shared
    // Should load without crashing, vault path may or may not be set
    #expect(config.obsidianVaultPath != nil)
}

// MARK: - Brier Score

@Test func brierScorePerfect() {
    // Predicted 90% and succeeded: (0.9 - 1.0)^2 = 0.01
    let score = BrierScore.calculate(forecast: 0.9, succeeded: true)
    #expect(abs(score - 0.01) < 0.001)
}

@Test func brierScoreWorst() {
    // Predicted 99% and failed
    let score = BrierScore.calculate(forecast: 0.99, succeeded: false)
    #expect(score > 0.98) // (0.99 - 0.0)^2 = 0.9801
}

@Test func brierScoreCombinedWithStreaks() {
    let c = Commitment(title: "Test", deadline: Date())
    c.status = .completed
    c.forecastProbability = 0.8

    let completedStreak = StreakItem(title: "Done", currentStreak: 1, bestStreak: 1, status: "Y", targetTime: "08:00")
    // Can't easily test failed streak since isPastTargetTime depends on current time
    // But we can verify the function doesn't crash with mixed inputs
    let score = BrierScore.combinedScore(commitments: [c], streakItems: [completedStreak])
    #expect(score != nil)
}

@Test func brierScoreRating() {
    #expect(BrierScore.rating(0.05) == "Excellent")
    #expect(BrierScore.rating(0.15) == "Good")
    #expect(BrierScore.rating(0.25) == "Fair")
    #expect(BrierScore.rating(0.35) == "Poor")
    #expect(BrierScore.rating(0.55) == "Bad")
}

// MARK: - Streaks

@Test func streakItemProperties() {
    let item = StreakItem(title: "Meditate", currentStreak: 5, bestStreak: 30, status: "Y", targetTime: "06:30")
    #expect(item.title == "Meditate")
    #expect(item.currentStreak == 5)
    #expect(item.completedToday)
    #expect(item.formattedTime == "6:30 AM")

    let incomplete = StreakItem(title: "Run", currentStreak: 0, bestStreak: 10, status: "N", targetTime: "17:00")
    #expect(!incomplete.completedToday)
    #expect(incomplete.formattedTime == "5:00 PM")
}

@Test func streakItemPastTargetTime() {
    // A streak at 00:01 should always be past target time
    let past = StreakItem(title: "Early", currentStreak: 0, bestStreak: 0, status: "N", targetTime: "00:01")
    #expect(past.isPastTargetTime)

    // A streak at 23:59 should not be past target time (unless it's actually 23:59)
    let future = StreakItem(title: "Late", currentStreak: 0, bestStreak: 0, status: "N", targetTime: "23:59")
    // This depends on current time, so we can only check it doesn't crash
    _ = future.isPastTargetTime
}

@Test func streakItemFormattedTimePM() {
    let item = StreakItem(title: "Night", currentStreak: 0, bestStreak: 0, status: "N", targetTime: "23:00")
    #expect(item.formattedTime == "11:00 PM")
}

@Test func streakItemFormattedTimeNoon() {
    let item = StreakItem(title: "Noon", currentStreak: 0, bestStreak: 0, status: "N", targetTime: "12:00")
    #expect(item.formattedTime == "12:00 PM")
}

@Test func streakCacheRoundtrip() throws {
    let items = [
        StreakCacheItem(title: "Meditate", currentStreak: 5, bestStreak: 10, status: "Y", targetTime: "08:00"),
        StreakCacheItem(title: "Workout", currentStreak: 0, bestStreak: 3, status: "N", targetTime: "17:00"),
        StreakCacheItem(title: "Evening Meditation", currentStreak: 0, bestStreak: 0, status: "N", targetTime: "23:00")
    ]

    let data = try JSONEncoder().encode(items)
    let decoded = try JSONDecoder().decode([StreakCacheItem].self, from: data)

    #expect(decoded.count == 3)
    #expect(decoded[0].title == "Meditate")
    #expect(decoded[0].currentStreak == 5)
    #expect(decoded[0].status == "Y")
    #expect(decoded[2].title == "Evening Meditation")
    #expect(decoded[2].targetTime == "23:00")
}

// MARK: - Obsidian

@Test func obsidianReadCommitmentsFromEmpty() async {
    let tempDir = NSTemporaryDirectory() + "committed-test-\(UUID().uuidString)"
    try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let service = ObsidianService(vaultPath: tempDir)
    let commitments = await service.readCommitments()
    #expect(commitments.isEmpty)
}

@Test func obsidianReadCommitmentsParseFormat() async {
    let tempDir = NSTemporaryDirectory() + "committed-test-\(UUID().uuidString)"
    try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let content = "# Commitments\n- [ ] Ship v2 | 2026-04-10\n- [x] Write tests | 2026-04-01\n- [ ] Review PR | 2026-04-15\n"
    let filePath = (tempDir as NSString).appendingPathComponent("commitments.md")
    try? content.write(toFile: filePath, atomically: true, encoding: .utf8)

    let service = ObsidianService(vaultPath: tempDir)
    let commitments = await service.readCommitments()

    #expect(commitments.count == 3)
    #expect(commitments[0].title == "Ship v2")
    #expect(!commitments[0].isCompleted)
    #expect(commitments[1].isCompleted)
}

@Test func obsidianWritePreMortem() async {
    let tempDir = NSTemporaryDirectory() + "committed-test-\(UUID().uuidString)"
    let dailyDir = (tempDir as NSString).appendingPathComponent("Daily Notes")
    try? FileManager.default.createDirectory(atPath: dailyDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayFile = (dailyDir as NSString).appendingPathComponent("\(formatter.string(from: Date())).md")
    try? "# Daily Note\n".write(toFile: todayFile, atomically: true, encoding: .utf8)

    let service = ObsidianService(vaultPath: tempDir)
    await service.writePreMortem(commitment: "Ship v2", risks: ["scope creep", "API issues", "testing gaps"], date: Date())

    let content = try? String(contentsOfFile: todayFile, encoding: .utf8)
    #expect(content?.contains("Pre-Mortem: Ship v2") ?? false)
    #expect(content?.contains("scope creep") ?? false)
}

@Test func obsidianWritePostMortem() async {
    let tempDir = NSTemporaryDirectory() + "committed-test-\(UUID().uuidString)"
    let dailyDir = (tempDir as NSString).appendingPathComponent("Daily Notes")
    try? FileManager.default.createDirectory(atPath: dailyDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayFile = (dailyDir as NSString).appendingPathComponent("\(formatter.string(from: Date())).md")
    try? "# Daily Note\n".write(toFile: todayFile, atomically: true, encoding: .utf8)

    let service = ObsidianService(vaultPath: tempDir)
    await service.writePostMortem(
        commitment: "Ship v2", outcome: "Shipped late",
        whatWorked: "Team collab", whatFailed: "Scope creep",
        lessons: "Set smaller scope", succeeded: false, date: Date()
    )

    let content = try? String(contentsOfFile: todayFile, encoding: .utf8)
    #expect(content?.contains("Post-Mortem: Ship v2") ?? false)
    #expect(content?.contains("Scope creep") ?? false)
    #expect(content?.contains("failed") ?? false)
}

@Test func obsidianWriteCommitmentCreated() async {
    let tempDir = NSTemporaryDirectory() + "committed-test-\(UUID().uuidString)"
    let dailyDir = (tempDir as NSString).appendingPathComponent("Daily Notes")
    try? FileManager.default.createDirectory(atPath: dailyDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayFile = (dailyDir as NSString).appendingPathComponent("\(formatter.string(from: Date())).md")
    try? "# Daily Note\n".write(toFile: todayFile, atomically: true, encoding: .utf8)

    let service = ObsidianService(vaultPath: tempDir)
    await service.writeCommitmentCreated(
        title: "Launch v2", deadline: Date().addingTimeInterval(86400),
        probability: 0.85, risks: ["scope", "bugs", "reviews"]
    )

    let content = try? String(contentsOfFile: todayFile, encoding: .utf8)
    #expect(content?.contains("Commitment: Launch v2") ?? false)
    #expect(content?.contains("85%") ?? false)
}

// MARK: - Fatebook Service

@Test func fatebookServiceInit() {
    let service = FatebookService(apiKey: "test-key")
    #expect(service != nil)
}

@Test func fatebookServiceEmptyKey() async throws {
    let service = FatebookService(apiKey: "")
    let result = try await service.createQuestion(title: "test", resolveBy: Date(), forecast: 0.5)
    #expect(result == nil)
}

// MARK: - Long Term Goals

@Test func longTermGoalModel() {
    let goal = LongTermGoal(
        id: "abc123",
        title: "100 AF Karma",
        probability: 0.25,
        resolveBy: Date().addingTimeInterval(365 * 86400),
        url: "https://fatebook.io/q/test"
    )
    #expect(goal.title == "100 AF Karma")
    #expect(goal.probability == 0.25)
}
