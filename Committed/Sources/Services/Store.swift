import Foundation

@MainActor
class Store: ObservableObject {
    static let shared = Store()

    @Published var commitments: [Commitment] = []

    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Committed", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("commitments.json")
        load()
    }

    var activeCommitments: [Commitment] {
        commitments.filter { $0.status == .active }.sorted { $0.deadline < $1.deadline }
    }

    var overdueCommitments: [Commitment] {
        activeCommitments.filter { $0.isOverdue }
    }

    var dueTodayCommitments: [Commitment] {
        activeCommitments.filter { $0.isDueToday && !$0.isOverdue }
    }

    var upcomingCommitments: [Commitment] {
        activeCommitments.filter { !$0.isOverdue && !$0.isDueToday }
    }

    var needsPreMortem: [Commitment] {
        activeCommitments.filter { $0.isDueSoon && !$0.preMortemCompleted }
    }

    var needsPostMortem: [Commitment] {
        commitments.filter { $0.isOverdue && !$0.postMortemCompleted && $0.status == .active }
    }

    func add(_ commitment: Commitment) {
        commitments.append(commitment)
        save()
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(commitments) {
            try? data.write(to: fileURL)
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let loaded = try? decoder.decode([Commitment].self, from: data) {
            commitments = loaded
        }
    }
}
