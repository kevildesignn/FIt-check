import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let cameraManager = CameraManager()
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = NSImage(
                systemSymbolName: "viewfinder", accessibilityDescription: "Mirror")
            image?.isTemplate = true
            button.image = image
            button.action = #selector(togglePopover(_:))
            button.target = self

            // Add right-click menu
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Configure popover
        popover.behavior = .transient
        popover.delegate = self
        popover.animates = true
        popover.contentSize = NSSize(width: 360, height: 240)

        let contentView = MirrorPopoverView()
            .environmentObject(cameraManager)
        popover.contentViewController = NSHostingController(rootView: contentView)

        // Make app agent (no dock) at runtime as well; Info.plist also sets LSUIElement
        NSApp.setActivationPolicy(.accessory)
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        // Check if this was a right-click
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            // Show quit menu on right-click
            let menu = NSMenu()
            menu.addItem(
                NSMenuItem(
                    title: "Quit FIt Check", action: #selector(NSApplication.terminate(_:)),
                    keyEquivalent: "q"))
            statusItem.popUpMenu(menu)
            return
        }

        // Left-click: toggle popover
        if popover.isShown {
            closePopover()
        } else {
            showPopover(relativeTo: button.bounds, of: button)
        }
    }

    private func showPopover(relativeTo rect: NSRect, of view: NSView) {
        // Activate the app so it responds to keyboard/mouse events immediately
        NSApp.activate(ignoringOtherApps: true)

        popover.show(relativeTo: rect, of: view, preferredEdge: .minY)
        cameraManager.startSessionIfAuthorized()

        // Explicitly make the popover window key and bring to front
        // This ensures proper activation across multiple monitors
        DispatchQueue.main.async { [weak self] in
            if let popoverWindow = self?.popover.contentViewController?.view.window {
                popoverWindow.makeKeyAndOrderFront(nil)
                popoverWindow.orderFrontRegardless()
            }
        }

        // Install event monitor to detect clicks outside the popover
        if eventMonitor == nil {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [
                .leftMouseDown, .rightMouseDown,
            ]) { [weak self] event in
                guard let self = self else { return event }

                if self.popover.isShown {
                    // Get the click location
                    let clickLocation = event.locationInWindow

                    // Check if click is outside popover window
                    if let popoverWindow = self.popover.contentViewController?.view.window {
                        let clickInPopover = popoverWindow.frame.contains(
                            NSEvent.mouseLocation
                        )

                        // Also check if click is in status item button
                        let clickInButton =
                            self.statusItem.button?.window?.frame.contains(
                                NSEvent.mouseLocation
                            ) ?? false

                        if !clickInPopover && !clickInButton {
                            self.closePopover()
                        }
                    }
                }

                return event
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        cameraManager.stopSession()

        // Remove event monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    func popoverDidClose(_ notification: Notification) {
        cameraManager.stopSession()

        // Remove event monitor if popover closes by other means
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
