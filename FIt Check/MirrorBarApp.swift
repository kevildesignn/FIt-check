import SwiftUI
import AppKit

@main
struct MirrorBarApp: App {
    // Use NSApplicationDelegate for status item lifecycle
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window scenes; keep empty to avoid automatic windows
        Settings {
            // Provide an empty settings scene to satisfy App protocol
            EmptyView()
        }
    }
}
