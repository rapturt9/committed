import SwiftUI

struct TrackRecordView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var integrationManager: IntegrationManager

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header with scores
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("committed")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                    Text("Track Record")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Score cards
                if let allTime = BrierScore.combinedScore(commitments: store.commitments, streakItems: integrationManager.streakItems) {
                    ScoreCard(label: "All-Time Brier", value: String(format: "%.3f", allTime), rating: BrierScore.rating(allTime), color: brierColor(allTime))
                }

                if let recent = BrierScore.recentScore(commitments: store.commitments, days: 2) {
                    ScoreCard(label: "48h Brier", value: String(format: "%.3f", recent), rating: BrierScore.rating(recent), color: brierColor(recent))
                }

                let total = store.commitments.count
                let completed = store.commitments.filter { $0.status == .completed }.count
                let failed = store.commitments.filter { $0.status == .failed }.count
                ScoreCard(label: "Record", value: "\(completed)/\(total)", rating: "\(failed) failed", color: .primary)
            }
            .padding(24)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Tab bar
            HStack(spacing: 0) {
                TabButton(title: "All Commitments", selected: selectedTab == 0) { selectedTab = 0 }
                TabButton(title: "Pre-Mortems", selected: selectedTab == 1) { selectedTab = 1 }
                TabButton(title: "Post-Mortems", selected: selectedTab == 2) { selectedTab = 2 }
                TabButton(title: "Long Term Goals", selected: selectedTab == 3) { selectedTab = 3 }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Divider().padding(.top, 8)

            // Content
            ScrollView {
                switch selectedTab {
                case 0: allCommitmentsTab
                case 1: preMortemsTab
                case 2: postMortemsTab
                case 3: longTermGoalsTab
                default: EmptyView()
                }
            }
        }
    }

    // MARK: - Tabs

    private var allCommitmentsTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.commitments.sorted(by: { $0.deadline > $1.deadline })) { c in
                HStack(spacing: 12) {
                    // Status
                    statusIcon(for: c)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(c.title)
                            .font(.system(size: 14, weight: .medium))
                            .strikethrough(c.status == .completed)

                        HStack(spacing: 8) {
                            Text(c.deadline.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            if let p = c.forecastProbability {
                                Text("P=\(Int(p * 100))%")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.purple)
                            }

                            Text(c.source.rawValue)
                                .font(.system(size: 10))
                                .padding(.horizontal, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(3)

                            if c.preMortemCompleted {
                                Label("Pre-mortem", systemImage: "shield.checkered")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                            }

                            if c.postMortemCompleted {
                                Label("Post-mortem", systemImage: "doc.text")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                            }

                            if (c.status == .completed || c.status == .failed), let p = c.forecastProbability {
                                let bs = BrierScore.calculate(forecast: p, succeeded: c.status == .completed)
                                Text("BS=\(String(format: "%.3f", bs))")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(bs < 0.1 ? .green : bs < 0.25 ? .yellow : .red)
                            }
                        }
                    }

                    Spacer()

                    Text(c.status.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(statusColor(for: c))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)

                Divider().padding(.leading, 60)
            }
        }
    }

    private var preMortemsTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            let withPM = store.commitments.filter { !$0.preMortems.isEmpty }

            if withPM.isEmpty {
                Text("No pre-mortems yet. They're required when creating commitments.")
                    .foregroundColor(.secondary)
                    .padding(24)
            }

            ForEach(withPM.sorted(by: { $0.deadline > $1.deadline })) { c in
                ForEach(c.preMortems) { pm in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(c.title)
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            Text(pm.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            riskRow(number: 1, text: pm.risk1)
                            riskRow(number: 2, text: pm.risk2)
                            riskRow(number: 3, text: pm.risk3)
                        }

                        if !pm.mitigations.isEmpty {
                            Text("Mitigations: \(pm.mitigations)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)

                    Divider()
                }
            }
        }
    }

    private var postMortemsTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            let withPM = store.commitments.filter { !$0.postMortems.isEmpty }

            if withPM.isEmpty {
                Text("No post-mortems yet. They're triggered when completing or failing commitments.")
                    .foregroundColor(.secondary)
                    .padding(24)
            }

            ForEach(withPM.sorted(by: { $0.deadline > $1.deadline })) { c in
                ForEach(c.postMortems) { pm in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(c.title)
                                .font(.system(size: 14, weight: .bold))

                            Text(pm.succeeded ? "completed" : "failed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(pm.succeeded ? .green : .red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background((pm.succeeded ? Color.green : Color.red).opacity(0.1))
                                .cornerRadius(4)

                            Spacer()

                            Text(pm.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        LabeledField(label: "Outcome", text: pm.outcome)
                        LabeledField(label: "What worked", text: pm.whatWorked)
                        LabeledField(label: "What failed", text: pm.whatFailed)
                        LabeledField(label: "Lessons", text: pm.lessonsLearned)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)

                    Divider()
                }
            }
        }
    }

    private var longTermGoalsTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(integrationManager.longTermGoals) { goal in
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.system(size: 16, weight: .bold))

                        HStack(spacing: 12) {
                            Text("P=\(Int(goal.probability * 100))%")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(.purple)

                            Text("Resolve by \(goal.resolveBy.formatted(.dateTime.month(.abbreviated).year()))")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button("Open in Fatebook") {
                        NSWorkspace.shared.open(URL(string: goal.url)!)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                Divider()
            }

            if integrationManager.longTermGoals.isEmpty {
                Text("Loading goals from Fatebook...")
                    .foregroundColor(.secondary)
                    .padding(24)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statusIcon(for c: Commitment) -> some View {
        switch c.status {
        case .active:
            Circle().fill(c.isOverdue ? .red : .orange).frame(width: 10, height: 10)
        case .completed:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.system(size: 14))
        case .failed:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.system(size: 14))
        case .cancelled:
            Image(systemName: "minus.circle").foregroundColor(.gray).font(.system(size: 14))
        }
    }

    private func statusColor(for c: Commitment) -> Color {
        switch c.status {
        case .active: return c.isOverdue ? .red : .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }

    private func riskRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(number).")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.red)
            Text(text)
                .font(.system(size: 12))
        }
    }

    private func brierColor(_ score: Double) -> Color {
        switch score {
        case 0..<0.1: return .green
        case 0.1..<0.2: return .blue
        case 0.2..<0.3: return .yellow
        default: return .red
        }
    }
}

struct ScoreCard: View {
    let label: String
    let value: String
    let rating: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(rating)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct TabButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: selected ? .bold : .regular))
                .foregroundColor(selected ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.accentColor.opacity(0.1) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct LabeledField: View {
    let label: String
    let text: String

    var body: some View {
        if !text.isEmpty {
            HStack(alignment: .top, spacing: 4) {
                Text("\(label):")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.system(size: 12))
            }
        }
    }
}
