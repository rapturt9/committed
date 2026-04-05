import SwiftUI

@main
struct CommittedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopover()
                .environmentObject(Store.shared)
                .environmentObject(appDelegate.overlayManager)
                .environmentObject(appDelegate.integrationManager)
        } label: {
            MenuBarLabel()
                .environmentObject(Store.shared)
                .environmentObject(appDelegate.integrationManager)
        }
        .menuBarExtraStyle(.window)

        Window("Committed", id: "main") {
            TrackRecordView()
                .environmentObject(Store.shared)
                .environmentObject(appDelegate.integrationManager)
                .frame(minWidth: 600, minHeight: 500)
        }

        Settings {
            SettingsView()
                .environmentObject(appDelegate.integrationManager)
        }
    }
}
