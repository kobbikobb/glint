import SwiftUI
import AppKit

@main
struct GlintApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "sun.max", accessibilityDescription: "Glint")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Glint", action: #selector(showWindow), keyEquivalent: ""))
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

    @objc func screenDidWake() {
        let hour = Calendar.current.component(.hour, from: Date())
        let totalMinutes = hour * 60 + Calendar.current.component(.minute, from: Date())

        guard (300...660).contains(totalMinutes) else { return }

        let today = Calendar.current.startOfDay(for: Date())
        if let last = UserDefaults.standard.object(forKey: "lastGlintDate") as? Date,
           Calendar.current.isDate(last, inSameDayAs: today) {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            UserDefaults.standard.set(Date(), forKey: "lastGlintDate")
            self?.showWindow()
        }
    }

    @objc func showWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
