import AppKit
import SwiftUI

// Borderless windows don't accept key events by default
class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
class OverlayManager: ObservableObject {
    private var overlayWindow: NSWindow?
    @Published var isShowingOverlay = false
    @Published var currentCommitment: Commitment?
    @Published var failedItemTitle: String?
    @Published var overlayType: OverlayType = .postMortem

    enum OverlayType {
        case postMortem
        case failedItemPostMortem
        case forceNewCommitment
    }

    func showPostMortem(for commitment: Commitment) {
        currentCommitment = commitment
        failedItemTitle = nil
        overlayType = .postMortem
        showOverlay()
    }

    func showFailedItemPostMortem(title: String) {
        currentCommitment = nil
        failedItemTitle = title
        overlayType = .failedItemPostMortem
        showOverlay()
    }

    func showForceNewCommitment() {
        currentCommitment = nil
        failedItemTitle = nil
        overlayType = .forceNewCommitment
        showOverlay()
    }

    func showOverlay() {
        guard overlayWindow == nil else { return }

        let overlayView = OverlayContentView()
            .environmentObject(self)
            .environmentObject(Store.shared)

        let hostingView = NSHostingView(rootView: overlayView)

        guard let screen = NSScreen.main else { return }
        let frame = screen.frame

        let window = KeyableWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.9)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        window.makeKey()
        window.makeMain()

        overlayWindow = window
        isShowingOverlay = true
    }

    func dismissOverlay() {
        overlayWindow?.close()
        overlayWindow = nil
        isShowingOverlay = false
        currentCommitment = nil
    }
}
