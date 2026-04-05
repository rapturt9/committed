import EventKit
import Foundation

actor RemindersService {
    private let store = EKEventStore()
    private var authorized = false

    func requestAccess() async -> Bool {
        do {
            authorized = try await store.requestFullAccessToReminders()
            return authorized
        } catch {
            return false
        }
    }

    func ensureAuthorized() async -> Bool {
        if authorized { return true }
        return await requestAccess()
    }

    func fetchRemindersWithDueDates() async -> [ReminderItem] {
        guard await ensureAuthorized() else { return [] }

        return await withCheckedContinuation { continuation in
            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: nil, ending: nil, calendars: nil
            )

            store.fetchReminders(matching: predicate) { reminders in
                let items = (reminders ?? [])
                    .filter { $0.dueDateComponents != nil }
                    .compactMap { reminder -> ReminderItem? in
                        guard let dueDate = reminder.dueDateComponents?.date else { return nil }
                        return ReminderItem(
                            id: reminder.calendarItemIdentifier,
                            title: reminder.title ?? "Untitled",
                            dueDate: dueDate,
                            notes: reminder.notes,
                            listName: reminder.calendar?.title ?? "Reminders",
                            isCompleted: reminder.isCompleted
                        )
                    }
                continuation.resume(returning: items)
            }
        }
    }

    func completeReminder(id: String) async -> Bool {
        guard authorized else { return false }

        let eventStore = store
        return await withCheckedContinuation { continuation in
            let predicate = eventStore.predicateForReminders(in: nil)
            eventStore.fetchReminders(matching: predicate) { reminders in
                guard let reminder = reminders?.first(where: { $0.calendarItemIdentifier == id }) else {
                    continuation.resume(returning: false)
                    return
                }
                reminder.isCompleted = true
                do {
                    try eventStore.save(reminder, commit: true)
                    continuation.resume(returning: true)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func createReminder(title: String, dueDate: Date, notes: String?) async -> String? {
        guard await ensureAuthorized() else { return nil }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = store.defaultCalendarForNewReminders()

        let cal = Calendar.current
        reminder.dueDateComponents = cal.dateComponents(
            [.year, .month, .day, .hour, .minute], from: dueDate
        )

        // Add an alarm at the due date
        reminder.addAlarm(EKAlarm(absoluteDate: dueDate))

        do {
            try store.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            return nil
        }
    }
}

struct ReminderItem: Identifiable {
    let id: String
    let title: String
    let dueDate: Date
    let notes: String?
    let listName: String
    let isCompleted: Bool
}
