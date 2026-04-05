import Foundation

struct PreMortem: Identifiable, Codable {
    let id: UUID
    var risk1: String
    var risk2: String
    var risk3: String
    var mitigations: String
    var createdAt: Date

    init(risk1: String, risk2: String, risk3: String, mitigations: String = "") {
        self.id = UUID()
        self.risk1 = risk1
        self.risk2 = risk2
        self.risk3 = risk3
        self.mitigations = mitigations
        self.createdAt = Date()
    }
}
