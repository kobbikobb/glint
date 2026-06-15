import SwiftUI
import AppKit
import Factory

@main
struct GlintApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Injected(\.digestService) private var digest

    var body: some Scene {
        WindowGroup {
            PopupView(digest: digest)
        }
        .windowResizability(.contentSize)
    }
}
