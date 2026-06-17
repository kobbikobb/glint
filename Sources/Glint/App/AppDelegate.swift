import SwiftUI
import AppKit
import Factory

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var preferencesWindow: NSWindow?

    @Injected(\.scheduler) private var scheduler

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "sun.max", accessibilityDescription: "Glint")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Glint", action: #selector(showWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screenDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func screenDidWake() {
        if scheduler.digest() {
            showWindow()
        }
    }

    @objc func showPreferences() {
        if preferencesWindow == nil {
            let hosting = NSHostingController(rootView: PreferencesView())
            let window = NSWindow(contentViewController: hosting)
            window.title = "Preferences"
            window.setFrameAutosaveName("Preferences")
            preferencesWindow = window
        }
        NSApp.setActivationPolicy(.regular)
        preferencesWindow?.orderFrontRegardless()
        preferencesWindow?.makeKey()
    }

    @objc func showWindow() {
        NSApp.setActivationPolicy(.regular)
        if let window = NSApplication.shared.windows.first {
            window.orderFrontRegardless()
            window.makeKey()
        }
    }
}
