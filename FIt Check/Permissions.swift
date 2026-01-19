import AppKit

enum Permissions {
    static func openCameraPrivacySettings() {
        // Attempts to open the Privacy & Security > Camera pane
        // Fallback to generic Privacy pane if direct URL fails
        let urls = [
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"),
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")
        ].compactMap { $0 }
        for url in urls {
            if NSWorkspace.shared.open(url) { return }
        }
    }
}
