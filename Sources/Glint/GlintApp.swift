import SwiftUI
import AppKit
import Factory

@main
struct GlintApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Injected(\.itemStore) private var itemStore

    var body: some Scene {
        WindowGroup {
            ContentView(itemStore: itemStore)
        }
        .windowResizability(.contentSize)
    }
}
