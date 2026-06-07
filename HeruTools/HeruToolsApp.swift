import SwiftUI
import AppKit

@main
struct HeruToolsApp: App {
    // Adapt standard AppKit Lifecycle events to host status bar items
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        // Prevent launching standard empty macOS app windows
        Settings {
            EmptyView()
        }
    }
}

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public var statusItem: NSStatusItem?
    public var popover: NSPopover?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
    }
    
    private func setupStatusItem() {
        // Register Menu Bar item in system status extra area
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        
        // Define clean monochrome wrench/screwdriver symbol
        if let image = NSImage(systemSymbolName: "wrench.and.screwdriver.fill", accessibilityDescription: "HeruTools") {
            image.isTemplate = true // Ensures monochrome styling matches system themes
            button.image = image
        }
        
        button.action = #selector(togglePopover(_:))
        button.target = self
    }
    
    private func setupPopover() {
        let popover = NSPopover()
        
        // Configure behaviors
        popover.contentSize = NSSize(width: 380, height: 475)
        popover.behavior = .transient // Automatically closes on click-away
        popover.animates = true
        popover.contentViewController = PopoverViewController()
        
        self.popover = popover
    }
    
    @objc public func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }
        guard let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            // Anchor popover directly under the status bar icon
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            // Bring application to focus to capture active keys/clicks
            NSApp.activate(ignoringOtherApps: true)
            
            // Force status checks upon display
            Task { @MainActor in
                AppState.shared.checkAllStatuses()
            }
        }
    }
}
