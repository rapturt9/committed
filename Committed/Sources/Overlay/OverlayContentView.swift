import SwiftUI

struct OverlayContentView: View {
    @EnvironmentObject var overlayManager: OverlayManager
    @EnvironmentObject var store: Store

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            switch overlayManager.overlayType {
            case .postMortem:
                if let commitment = overlayManager.currentCommitment {
                    PostMortemOverlay(commitment: commitment)
                        .environmentObject(overlayManager)
                }
            case .failedItemPostMortem:
                if let title = overlayManager.failedItemTitle {
                    FailedItemPostMortemOverlay(itemTitle: title)
                        .environmentObject(overlayManager)
                }
            case .forceNewCommitment:
                ForceNewCommitmentOverlay()
                    .environmentObject(overlayManager)
                    .environmentObject(store)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Post-Mortem (forced when completing a commitment)

struct PostMortemOverlay: View {
    let commitment: Commitment
    @EnvironmentObject var overlayManager: OverlayManager
    @State private var succeeded = true
    @State private var outcome = ""
    @State private var whatWorked = ""
    @State private var whatFailed = ""
    @State private var lessons = ""

    private var canDismiss: Bool {
        !outcome.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lessons.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("POST-MORTEM")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                    .tracking(4)
                Text(commitment.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                if let prob = commitment.forecastProbability {
                    Text("You predicted \(Int(prob * 100))% chance of success")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                }

                Text("Deadline has passed")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }

            HStack(spacing: 16) {
                Button(action: { succeeded = true }) {
                    Text("Completed")
                        .padding(.horizontal, 24).padding(.vertical, 8)
                        .background(succeeded ? Color.green : Color.white.opacity(0.1))
                        .foregroundColor(succeeded ? .black : .white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: { succeeded = false }) {
                    Text("Failed")
                        .padding(.horizontal, 24).padding(.vertical, 8)
                        .background(!succeeded ? Color.red : Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 16) {
                PostMortemField(label: "What happened?", text: $outcome)
                PostMortemField(label: "What worked?", text: $whatWorked)
                PostMortemField(label: "What failed?", text: $whatFailed)
                PostMortemField(label: "Key lesson (be specific)", text: $lessons)
            }
            .frame(maxWidth: 500)

            Button(action: submit) {
                Text(canDismiss ? "Record and move on" : "Fill in outcome and lessons to continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canDismiss ? .black : .gray)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(canDismiss ? Color.white : Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .disabled(!canDismiss)
            .buttonStyle(.plain)
        }
        .padding(48)
    }

    private func submit() {
        let postMortem = PostMortem(
            outcome: outcome, whatWorked: whatWorked,
            whatFailed: whatFailed, lessonsLearned: lessons, succeeded: succeeded
        )
        commitment.postMortems.append(postMortem)
        commitment.status = succeeded ? .completed : .failed
        if succeeded { commitment.completedAt = Date() }
        Store.shared.save()

        Task {
            let obsidian = ObsidianService(vaultPath: AppConfig.shared.obsidianVaultPath)
            await obsidian.writePostMortem(
                commitment: commitment.title, outcome: outcome,
                whatWorked: whatWorked, whatFailed: whatFailed,
                lessons: lessons, succeeded: succeeded, date: Date()
            )
        }

        overlayManager.dismissOverlay()
    }
}

// MARK: - Force New Commitment (blocks screen if no predictions in next 7 days)

struct ForceNewCommitmentOverlay: View {
    @EnvironmentObject var overlayManager: OverlayManager
    @EnvironmentObject var store: Store

    @State private var title = ""
    @State private var deadline = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date())!
    @State private var probability = 0.99
    @State private var risk1 = ""
    @State private var risk2 = ""
    @State private var risk3 = ""
    @State private var isCreating = false

    private var canDismiss: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !risk1.trimmingCharacters(in: .whitespaces).isEmpty &&
        !risk2.trimmingCharacters(in: .whitespaces).isEmpty &&
        !risk3.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("NO COMMITMENTS")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
                    .tracking(4)
                Text("You have nothing on the line")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("Make a prediction for today to continue")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What are you committing to?")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    TextField("", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }

                HStack {
                    DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .colorScheme(.dark)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("P =")
                            .foregroundColor(.gray)
                        Text("\(Int(probability * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                }

                Slider(value: $probability, in: 0.05...0.99, step: 0.05)
                    .tint(.purple)

                Text("Pre-Mortem: What could go wrong?")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.orange)

                RiskField(number: 1, text: $risk1, placeholder: "Biggest risk?")
                RiskField(number: 2, text: $risk2, placeholder: "What else?")
                RiskField(number: 3, text: $risk3, placeholder: "Sneaky risk?")
            }
            .frame(maxWidth: 500)

            Button(action: create) {
                if isCreating {
                    ProgressView().controlSize(.regular)
                } else {
                    Text(canDismiss ? "Commit (\(Int(probability * 100))%)" : "Fill in commitment + 3 risks to continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canDismiss ? .black : .gray)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(canDismiss ? Color.white : Color.white.opacity(0.2))
            .cornerRadius(8)
            .disabled(!canDismiss || isCreating)
            .buttonStyle(.plain)
        }
        .padding(48)
    }

    private func create() {
        isCreating = true

        let commitment = Commitment(title: title, deadline: deadline)
        commitment.forecastProbability = probability
        commitment.forecasts.append(Forecast(probability: probability))
        commitment.preMortems.append(PreMortem(risk1: risk1, risk2: risk2, risk3: risk3))

        store.add(commitment)

        // Fatebook forecast in background
        Task {
            let fatebook = FatebookService(apiKey: AppConfig.shared.fatebookAPIKey)
            _ = try? await fatebook.createQuestion(
                title: "Will I complete '\(title)' by deadline?",
                resolveBy: deadline,
                forecast: probability
            )
        }

        // Create Apple Reminder
        Task {
            let reminders = RemindersService()
            _ = await reminders.createReminder(
                title: title, dueDate: deadline,
                notes: "P(complete)=\(Int(probability * 100))% | Created by Committed"
            )
        }

        // Write commitment + pre-mortem to Obsidian daily note
        Task {
            let obsidian = ObsidianService(vaultPath: AppConfig.shared.obsidianVaultPath)
            await obsidian.writeCommitmentCreated(
                title: title, deadline: deadline,
                probability: probability, risks: [risk1, risk2, risk3]
            )
        }

        overlayManager.dismissOverlay()
    }
}

// MARK: - Failed Item Post-Mortem (streaks, reminders, etc.)

struct FailedItemPostMortemOverlay: View {
    let itemTitle: String
    @EnvironmentObject var overlayManager: OverlayManager
    @State private var whatHappened = ""
    @State private var lesson = ""

    private var canDismiss: Bool {
        !whatHappened.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lesson.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("FAILED")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
                    .tracking(4)
                Text(itemTitle)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("You missed this. Reflect before continuing.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 16) {
                PostMortemField(label: "What happened? Why did you miss it?", text: $whatHappened)
                PostMortemField(label: "What will you do differently tomorrow?", text: $lesson)
            }
            .frame(maxWidth: 500)

            Button(action: submit) {
                Text(canDismiss ? "Record and move on" : "Fill in both fields to continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canDismiss ? .black : .gray)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(canDismiss ? Color.white : Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .disabled(!canDismiss)
            .buttonStyle(.plain)
        }
        .padding(48)
    }

    private func submit() {
        // Write to Obsidian
        Task {
            let obsidian = ObsidianService(vaultPath: AppConfig.shared.obsidianVaultPath)
            await obsidian.writePostMortem(
                commitment: itemTitle,
                outcome: "Failed - missed deadline",
                whatWorked: "",
                whatFailed: whatHappened,
                lessons: lesson,
                succeeded: false,
                date: Date()
            )
        }

        // Save to store - avoid duplicates for same item on same day
        let store = Store.shared
        let todayStr = { () -> String in
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
        }()
        let alreadyRecorded = store.commitments.contains {
            $0.title == itemTitle && $0.status == .failed &&
            $0.createdAt > Calendar.current.startOfDay(for: Date())
        }
        if !alreadyRecorded {
            let failRecord = Commitment(title: itemTitle, deadline: Date())
            failRecord.status = .failed
            failRecord.forecastProbability = 0.99
            failRecord.postMortems.append(PostMortem(
                outcome: "Missed",
                whatWorked: "",
                whatFailed: whatHappened,
                lessonsLearned: lesson,
                succeeded: false
            ))
            store.add(failRecord)
        }

        overlayManager.dismissOverlay()
    }
}

// MARK: - Shared Components

struct RiskField: View {
    let number: Int
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Risk \(number)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
        }
    }
}

struct PostMortemField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
        }
    }
}
