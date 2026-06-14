import SwiftUI
import AppKit

@main
struct GlintApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(itemStore: appDelegate.itemStore)
        }
        .windowResizability(.contentSize)
    }
}
