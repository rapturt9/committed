import SwiftUI

struct AddCommitmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: Store
    @EnvironmentObject var integrationManager: IntegrationManager

    @State private var title = ""
    @State private var detail = ""
    @State private var deadline = Date().addingTimeInterval(86400)
    @State private var forecastProbability = 0.99
    @State private var createFatebookForecast = true
    @State private var isCreating = false

    // Pre-mortem fields (forced on creation)
    @State private var risk1 = ""
    @State private var risk2 = ""
    @State private var risk3 = ""
    @State private var mitigations = ""

    @State private var step: Step = .details

    enum Step {
        case details
        case preMortem
    }

    private var detailsValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var preMortemValid: Bool {
        !risk1.trimmingCharacters(in: .whitespaces).isEmpty &&
        !risk2.trimmingCharacters(in: .whitespaces).isEmpty &&
        !risk3.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch step {
            case .details:
                detailsStep
            case .preMortem:
                preMortemStep
            }
        }
        .padding(20)
        .frame(width: 380)
        .animation(.easeInOut(duration: 0.2), value: step)
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Commitment")
                .font(.system(size: 18, weight: .bold))

            VStack(alignment: .leading, spacing: 8) {
                Text("What are you committing to?")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("Ship the feature by Friday", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Details (optional)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("Context, scope, definition of done", text: $detail)
                    .textFieldStyle(.roundedBorder)
            }

            DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: [.date, .hourAndMinute])

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("P(complete by deadline)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(forecastProbability * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.purple)
                }
                Slider(value: $forecastProbability, in: 0.05...0.99, step: 0.05)

                Toggle("Create Fatebook forecast", isOn: $createFatebookForecast)
                    .font(.system(size: 12))
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Next: Pre-Mortem") { step = .preMortem }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!detailsValid)
            }
        }
    }

    private var preMortemStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pre-Mortem")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text("Required")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }

            Text("Imagine \"\(title)\" has failed. What went wrong?")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                RiskField(number: 1, text: $risk1, placeholder: "Biggest risk?")
                RiskField(number: 2, text: $risk2, placeholder: "What else could go wrong?")
                RiskField(number: 3, text: $risk3, placeholder: "Sneaky risk you're ignoring?")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mitigations (optional)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    TextField("How will you prevent these?", text: $mitigations)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack {
                Button("Back") { step = .details }
                Spacer()
                Button(action: create) {
                    if isCreating {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Commit (\(Int(forecastProbability * 100))%)")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!preMortemValid || isCreating)
            }
        }
    }

    private func create() {
        isCreating = true

        let commitment = Commitment(title: title, detail: detail, deadline: deadline)
        commitment.forecastProbability = forecastProbability
        commitment.forecasts.append(Forecast(probability: forecastProbability))

        // Attach pre-mortem
        let preMortem = PreMortem(risk1: risk1, risk2: risk2, risk3: risk3, mitigations: mitigations)
        commitment.preMortems.append(preMortem)

        store.add(commitment)

        // Create Fatebook forecast
        if createFatebookForecast {
            Task {
                if let questionID = await integrationManager.createFatebookForecast(
                    title: title, deadline: deadline, probability: forecastProbability
                ) {
                    commitment.fatebookQuestionID = questionID
                    store.save()
                }
            }
        }

        // Create Apple Reminder
        Task {
            _ = await integrationManager.createReminder(
                title: title, deadline: deadline, probability: forecastProbability
            )
            await integrationManager.syncAll()
        }

        // Write commitment + pre-mortem to Obsidian daily note
        Task {
            await integrationManager.obsidian.writeCommitmentCreated(
                title: title, deadline: deadline,
                probability: forecastProbability, risks: [risk1, risk2, risk3]
            )
        }

        dismiss()
    }
}
