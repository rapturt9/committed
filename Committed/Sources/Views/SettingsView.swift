import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("preMortemHours") private var preMortemHours = 24.0
    @AppStorage("postMortemDelayMinutes") private var postMortemDelayMinutes = 30.0
    @AppStorage("obsidianVaultPath") private var obsidianVaultPath = ""
    @AppStorage("fatebookEnabled") private var fatebookEnabled = true
    @AppStorage("remindersEnabled") private var remindersEnabled = true
    @AppStorage("streaksEnabled") private var streaksEnabled = true

    var body: some View {
        TabView {
            GeneralSettings(
                launchAtLogin: $launchAtLogin,
                preMortemHours: $preMortemHours,
                postMortemDelayMinutes: $postMortemDelayMinutes
            )
            .tabItem { Label("General", systemImage: "gear") }

            IntegrationSettings(
                obsidianVaultPath: $obsidianVaultPath,
                fatebookEnabled: $fatebookEnabled,
                remindersEnabled: $remindersEnabled,
                streaksEnabled: $streaksEnabled
            )
            .tabItem { Label("Integrations", systemImage: "link") }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettings: View {
    @Binding var launchAtLogin: Bool
    @Binding var preMortemHours: Double
    @Binding var postMortemDelayMinutes: Double

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("[Settings] Launch at login error: \(error)")
                    }
                }

            VStack(alignment: .leading) {
                Text("Pre-mortem trigger: \(Int(preMortemHours))h before deadline")
                    .font(.system(size: 12))
                Slider(value: $preMortemHours, in: 1...72, step: 1)
            }

            VStack(alignment: .leading) {
                Text("Post-mortem delay: \(Int(postMortemDelayMinutes))min after deadline")
                    .font(.system(size: 12))
                Slider(value: $postMortemDelayMinutes, in: 0...120, step: 5)
            }
        }
        .padding()
    }
}

struct IntegrationSettings: View {
    @Binding var obsidianVaultPath: String
    @Binding var fatebookEnabled: Bool
    @Binding var remindersEnabled: Bool
    @Binding var streaksEnabled: Bool

    var body: some View {
        Form {
            Section("Obsidian") {
                HStack {
                    TextField("Vault path", text: $obsidianVaultPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        if panel.runModal() == .OK, let url = panel.url {
                            obsidianVaultPath = url.path
                        }
                    }
                }
            }

            Section("Services") {
                Toggle("Fatebook forecasting", isOn: $fatebookEnabled)
                Toggle("Apple Reminders sync", isOn: $remindersEnabled)
                Toggle("Streaks integration", isOn: $streaksEnabled)
            }
        }
        .padding()
    }
}
