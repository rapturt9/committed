import Foundation

enum BrierScore {
    // Brier score = (forecast - outcome)^2
    // Lower is better. 0 = perfect, 1 = worst

    static func calculate(forecast: Double, succeeded: Bool) -> Double {
        let outcome: Double = succeeded ? 1.0 : 0.0
        return pow(forecast - outcome, 2)
    }

    // Score from commitments only
    static func commitmentScore(_ commitments: [Commitment]) -> Double? {
        let resolved = commitments.filter {
            ($0.status == .completed || $0.status == .failed) && $0.forecastProbability != nil
        }
        guard !resolved.isEmpty else { return nil }

        let total = resolved.reduce(0.0) { sum, c in
            sum + calculate(forecast: c.forecastProbability!, succeeded: c.status == .completed)
        }
        return total / Double(resolved.count)
    }

    // Combined score including streaks (streaks are implicit P=99% predictions)
    static func combinedScore(commitments: [Commitment], streakItems: [StreakItem]) -> Double? {
        var scores: [Double] = []

        // Commitments with forecasts
        for c in commitments where (c.status == .completed || c.status == .failed) && c.forecastProbability != nil {
            scores.append(calculate(forecast: c.forecastProbability!, succeeded: c.status == .completed))
        }

        // Streaks: treat each as P=0.99 prediction
        for s in streakItems {
            if s.completedToday {
                scores.append(calculate(forecast: 0.99, succeeded: true))
            } else if s.isPastTargetTime {
                scores.append(calculate(forecast: 0.99, succeeded: false))
            }
            // Skip streaks not yet due
        }

        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    // Recent score (commitments only, last N days)
    static func recentScore(commitments: [Commitment], days: Int) -> Double? {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)
        let recent = commitments.filter {
            ($0.status == .completed || $0.status == .failed) &&
            $0.forecastProbability != nil &&
            ($0.completedAt ?? $0.deadline) > cutoff
        }
        guard !recent.isEmpty else { return nil }

        let total = recent.reduce(0.0) { sum, c in
            sum + calculate(forecast: c.forecastProbability!, succeeded: c.status == .completed)
        }
        return total / Double(recent.count)
    }

    static func rating(_ score: Double) -> String {
        switch score {
        case 0..<0.1: return "Excellent"
        case 0.1..<0.2: return "Good"
        case 0.2..<0.3: return "Fair"
        case 0.3..<0.5: return "Poor"
        default: return "Bad"
        }
    }
}
