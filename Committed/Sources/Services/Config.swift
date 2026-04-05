import Foundation

struct AppConfig {
    static let shared = AppConfig()

    let fatebookAPIKey: String
    let obsidianVaultPath: String

    private init() {
        var envVars: [String: String] = [:]

        // Try multiple paths for .env
        let envPaths = [
            Bundle.main.resourcePath.map { $0 + "/.env" },
            Bundle.main.path(forResource: ".env", ofType: nil),
            (NSHomeDirectory() as NSString).appendingPathComponent(".committed.env"),
            ProcessInfo.processInfo.environment["COMMITTED_ENV_PATH"]
        ].compactMap { $0 }

        for path in envPaths {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                for line in content.components(separatedBy: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
                    let parts = trimmed.components(separatedBy: "=")
                    guard parts.count >= 2 else { continue }
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)
                    envVars[key] = value
                }
                break
            }
        }

        // Also check process environment
        if let key = ProcessInfo.processInfo.environment["FATEBOOK_API_KEY"] {
            envVars["FATEBOOK_API_KEY"] = key
        }
        if let path = ProcessInfo.processInfo.environment["OBSIDIAN_VAULT_PATH"] {
            envVars["OBSIDIAN_VAULT_PATH"] = path
        }

        fatebookAPIKey = envVars["FATEBOOK_API_KEY"] ?? ""
        obsidianVaultPath = envVars["OBSIDIAN_VAULT_PATH"] ?? ""

        NSLog("[Config] API key loaded: \(!fatebookAPIKey.isEmpty), vault: \(obsidianVaultPath)")
    }
}
