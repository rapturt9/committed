import Foundation

struct Forecast: Identifiable, Codable {
    let id: UUID
    var probability: Double
    var createdAt: Date

    init(probability: Double) {
        self.id = UUID()
        self.probability = probability
        self.createdAt = Date()
    }
}
