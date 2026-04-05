import AppKit
import ServiceManagement
import SwiftUI
import UserNotifications

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let overlayManager = OverlayManager()
    let integrationManager = IntegrationManager()
    var deadlineTimer: Timer?

    // Persist post-mortemed items to disk so they survive restarts
    private var postMortemedItems: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: "postMortemedItems") ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "postMortemedItems")
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        do { try SMAppService.mainApp.register() } catch {}

        // Clear yesterday's post-mortem records
        let today = todayString()
        let current = postMortemedItems
        postMortemedItems = current.filter { $0.hasSuffix(today) }

        Task {
            await integrationManager.syncAll()
            checkDeadlines()

            deadlineTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                Task { @MainActor [weak self] in
                    self?.checkDeadlines()
                }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }

    func checkDeadlines() {
        let store = Store.shared
        guard !overlayManager.isShowingOverlay else { return }

        let today = todayString()

        // 1. Auto-fail overdue commitments
        for commitment in store.activeCommitments where commitment.isOverdue && !commitment.postMortemCompleted {
            let key = "commitment-\(commitment.id)-\(today)"
            if postMortemedItems.contains(key) { continue }
            commitment.status = .failed
            store.save()
            var items = postMortemedItems
            items.insert(key)
            postMortemedItems = items
            overlayManager.showPostMortem(for: commitment)
            return
        }

        // 2. Failed streaks
        for streak in integrationManager.streakItems {
            if !streak.completedToday && streak.isPastTargetTime {
                let key = "streak-\(streak.title)-\(today)"
                if postMortemedItems.contains(key) { continue }
                var items = postMortemedItems
                items.insert(key)
                postMortemedItems = items
                overlayManager.showFailedItemPostMortem(title: streak.title)
                return
            }
        }

        // 3. Failed reminders
        for reminder in integrationManager.reminderItems {
            if !reminder.isCompleted && reminder.dueDate < Date() {
                let key = "reminder-\(reminder.id)-\(today)"
                if postMortemedItems.contains(key) { continue }
                var items = postMortemedItems
                items.insert(key)
                postMortemedItems = items
                overlayManager.showFailedItemPostMortem(title: reminder.title)
                return
            }
        }

        // 4. Force new commitment if none in next 24h
        let next24h = Date().addingTimeInterval(24 * 3600)
        let hasUpcoming = store.activeCommitments.contains {
            $0.preMortemCompleted && $0.deadline <= next24h && $0.deadline > Date()
        }

        if !hasUpcoming {
            overlayManager.showForceNewCommitment()
        }
    }

    private func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
