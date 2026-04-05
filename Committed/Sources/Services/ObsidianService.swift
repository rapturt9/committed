import Foundation

actor ObsidianService {
    let vaultPath: String

    init(vaultPath: String) {
        self.vaultPath = vaultPath
    }

    func readCommitments() async -> [ObsidianCommitment] {
        let filePath = (vaultPath as NSString).appendingPathComponent("commitments.md")
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            return []
        }

        var commitments: [ObsidianCommitment] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- [") else { continue }

            let isCompleted = trimmed.hasPrefix("- [x]")
            let rest = trimmed
                .replacingOccurrences(of: "- [x] ", with: "")
                .replacingOccurrences(of: "- [ ] ", with: "")

            let parts = rest.components(separatedBy: " | ")
            guard parts.count >= 2 else { continue }

            let title = parts[0].trimmingCharacters(in: .whitespaces)
            let dateStr = parts[1].trimmingCharacters(in: .whitespaces)

            if let date = dateFormatter.date(from: dateStr) {
                commitments.append(ObsidianCommitment(title: title, deadline: date, isCompleted: isCompleted))
            }
        }

        return commitments
    }

    func writePreMortem(commitment: String, risks: [String], date: Date) {
        let content = """

        ## Pre-Mortem: \(commitment)
        **Date:** \(formatDate(date))
        **Risks:**
        1. \(risks.indices.contains(0) ? risks[0] : "")
        2. \(risks.indices.contains(1) ? risks[1] : "")
        3. \(risks.indices.contains(2) ? risks[2] : "")
        """
        appendToDailyNote(content: content, date: date)
    }

    func writePostMortem(commitment: String, outcome: String, whatWorked: String, whatFailed: String, lessons: String, succeeded: Bool, date: Date) {
        let emoji = succeeded ? "completed" : "failed"
        let content = """

        ## Post-Mortem: \(commitment) (\(emoji))
        **Date:** \(formatDate(date))
        **Outcome:** \(outcome)
        **What worked:** \(whatWorked)
        **What failed:** \(whatFailed)
        **Lessons:** \(lessons)
        """
        appendToDailyNote(content: content, date: date)
    }

    func writeCommitmentCreated(title: String, deadline: Date, probability: Double, risks: [String]) {
        let content = """

        ## Commitment: \(title)
        **Deadline:** \(formatDate(deadline))
        **P(complete):** \(Int(probability * 100))%
        **Risks:**
        1. \(risks.indices.contains(0) ? risks[0] : "")
        2. \(risks.indices.contains(1) ? risks[1] : "")
        3. \(risks.indices.contains(2) ? risks[2] : "")
        """
        appendToDailyNote(content: content, date: Date())
    }

    func markCommitmentComplete(title: String) {
        let filePath = (vaultPath as NSString).appendingPathComponent("commitments.md")
        guard var content = try? String(contentsOfFile: filePath, encoding: .utf8) else { return }
        content = content.replacingOccurrences(of: "- [ ] \(title)", with: "- [x] \(title)")
        try? content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }

    private func appendToDailyNote(content: String, date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = dateFormatter.string(from: date) + ".md"

        let possiblePaths = [
            (vaultPath as NSString).appendingPathComponent("daily/\(fileName)"),
            (vaultPath as NSString).appendingPathComponent("Daily Notes/\(fileName)"),
            (vaultPath as NSString).appendingPathComponent("\(fileName)")
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                if var existing = try? String(contentsOfFile: path, encoding: .utf8) {
                    existing += content
                    try? existing.write(toFile: path, atomically: true, encoding: .utf8)
                    NSLog("[Obsidian] Wrote to \(path)")
                    return
                }
            }
        }

        // Create in first path if no daily note exists
        let targetPath = possiblePaths[0]
        let dir = (targetPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? content.write(toFile: targetPath, atomically: true, encoding: .utf8)
        NSLog("[Obsidian] Created \(targetPath)")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

struct ObsidianCommitment: Identifiable {
    let id = UUID()
    let title: String
    let deadline: Date
    let isCompleted: Bool
}
