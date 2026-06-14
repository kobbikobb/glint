import SwiftUI
import AppKit

@main
struct GlintApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(storage: appDelegate.storage)
        }
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    let storage: Storage = UserDefaultsStorage()
    private lazy var jobRunner: JobRunner = .init(storage: storage)

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

        UserDefaults.standard.set(Date(), forKey: "lastGlintDate")

        Task {
            await jobRunner.runAll()

            await MainActor.run { [weak self] in
                self?.showWindow()
            }
        }
    }

    @objc func showWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
