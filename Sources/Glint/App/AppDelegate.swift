import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    let itemStore: ItemStore = UserDefaultsItemStore()
    private let configStore: ConfigStore = UserDefaultsConfigStore()
    private lazy var jobRunner: JobRunner = .init(itemStore: itemStore, configStore: configStore)
    private lazy var scheduler: Scheduler = .init(jobRunner: jobRunner) 
        
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

    @objc private func screenDidWake() {
        if scheduler.digest() {
            showWindow()
        }
    }

    @objc func showWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
