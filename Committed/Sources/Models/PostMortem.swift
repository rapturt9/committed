import Foundation

struct PostMortem: Identifiable, Codable {
    let id: UUID
    var outcome: String
    var whatWorked: String
    var whatFailed: String
    var lessonsLearned: String
    var succeeded: Bool
    var createdAt: Date

    init(outcome: String, whatWorked: String, whatFailed: String, lessonsLearned: String, succeeded: Bool) {
        self.id = UUID()
        self.outcome = outcome
        self.whatWorked = whatWorked
        self.whatFailed = whatFailed
        self.lessonsLearned = lessonsLearned
        self.succeeded = succeeded
        self.createdAt = Date()
    }
}
