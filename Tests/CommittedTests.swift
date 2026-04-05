import Foundation
import Testing
@testable import Committed

// MARK: - Commitment Model

@Test func commitmentCreation() {
    let deadline = Date().addingTimeInterval(86400)
    let c = Commitment(title: "Ship feature", detail: "v2 launch", deadline: deadline)

    #expect(c.title == "Ship feature")
    #expect(c.detail == "v2 launch")
    #expect(c.status == .active)
    #expect(c.source == .manual)
    #expect(c.preMortems.isEmpty)
    #expect(c.postMortems.isEmpty)
    #expect(c.forecasts.isEmpty)
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
    let soonDeadline = Date().addingTimeInterval(12 * 3600)
    let c = Commitment(title: "Soon", deadline: soonDeadline)
    #expect(c.isDueSoon)

    let farDeadline = Date().addingTimeInterval(48 * 3600)
    let c2 = Commitment(title: "Far", deadline: farDeadline)
    #expect(!c2.isDueSoon)
}

@Test func commitmentIsDueToday() {
    let cal = Calendar.current
    var components = cal.dateComponents([.year, .month, .day], from: Date())
    components.hour = 23
    components.minute = 59
    let laterToday = cal.date(from: components)!

    let c = Commitment(title: "Today", deadline: laterToday)
    #expect(c.isDueToday)
}

@Test func timeRemainingOverdue() {
    let past = Date().addingTimeInterval(-7200)
    let c = Commitment(title: "Late", deadline: past)
    #expect(c.timeRemaining.contains("overdue"))
}

@Test func timeRemainingFuture() {
    let future = Date().addingTimeInterval(7200)
    let c = Commitment(title: "Future", deadline: future)
    #expect(!c.timeRemaining.contains("overdue"))
}

@Test func timeRemainingDays() {
    let farFuture = Date().addingTimeInterval(5 * 86400)
    let c = Commitment(title: "Far", deadline: farFuture)
    #expect(c.timeRemaining.contains("d"))
}

// MARK: - Pre-Mortem

@Test func preMortemCreation() {
    let pm = PreMortem(risk1: "scope creep", risk2: "API changes", risk3: "testing gaps")
    #expect(pm.risk1 == "scope creep")
    #expect(pm.risk2 == "API changes")
    #expect(pm.risk3 == "testing gaps")
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
    let pm = PostMortem(
        outcome: "Shipped on time", whatWorked: "Daily standups",
        whatFailed: "CI was slow", lessonsLearned: "Invest in CI", succeeded: true
    )
    #expect(pm.succeeded)
    #expect(pm.outcome == "Shipped on time")
}

@Test func postMortemCompletedFlag() {
    let c = Commitment(title: "Test", deadline: Date())
    #expect(!c.postMortemCompleted)

    c.postMortems.append(PostMortem(
        outcome: "done", whatWorked: "x", whatFailed: "y",
        lessonsLearned: "z", succeeded: true
    ))
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
    let deadline = Date().addingTimeInterval(86400)
    let c = Commitment(title: "Roundtrip", detail: "test encoding", deadline: deadline)
    c.forecastProbability = 0.75
    c.forecasts.append(Forecast(probability: 0.75))
    c.preMortems.append(PreMortem(risk1: "a", risk2: "b", risk3: "c", mitigations: "d"))
    c.source = .reminders

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(c)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(Commitment.self, from: data)

    #expect(decoded.title == "Roundtrip")
    #expect(decoded.detail == "test encoding")
    #expect(decoded.status == .active)
    #expect(decoded.source == .reminders)
    #expect(decoded.forecastProbability == 0.75)
    #expect(decoded.forecasts.count == 1)
    #expect(decoded.preMortems.count == 1)
    #expect(decoded.preMortems.first?.risk1 == "a")
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

// MARK: - Source Types

@Test func commitmentSources() {
    let manual = Commitment(title: "A", deadline: Date(), source: .manual)
    let reminder = Commitment(title: "B", deadline: Date(), source: .reminders)
    let obsidian = Commitment(title: "C", deadline: Date(), source: .obsidian)
    let streak = Commitment(title: "D", deadline: Date(), source: .streaks)

    #expect(manual.source == .manual)
    #expect(reminder.source == .reminders)
    #expect(obsidian.source == .obsidian)
    #expect(streak.source == .streaks)
}

// MARK: - Config

@Test func appConfigLoads() {
    let config = AppConfig.shared
    #expect(!config.obsidianVaultPath.isEmpty)
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

    let content = """
    # Commitments
    - [ ] Ship v2 | 2026-04-10
    - [x] Write tests | 2026-04-01
    - [ ] Review PR | 2026-04-15
    """
    let filePath = (tempDir as NSString).appendingPathComponent("commitments.md")
    try? content.write(toFile: filePath, atomically: true, encoding: .utf8)

    let service = ObsidianService(vaultPath: tempDir)
    let commitments = await service.readCommitments()

    #expect(commitments.count == 3)
    #expect(commitments[0].title == "Ship v2")
    #expect(!commitments[0].isCompleted)
    #expect(commitments[1].isCompleted)
    #expect(commitments[2].title == "Review PR")
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
    await service.writePreMortem(
        commitment: "Ship v2",
        risks: ["scope creep", "API issues", "testing gaps"],
        date: Date()
    )

    let content = try? String(contentsOfFile: todayFile, encoding: .utf8)
    #expect(content?.contains("Pre-Mortem: Ship v2") ?? false)
    #expect(content?.contains("scope creep") ?? false)
}
