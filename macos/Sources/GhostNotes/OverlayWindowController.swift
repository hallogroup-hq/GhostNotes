import AppKit
import SwiftUI

final class GhostWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class OverlayWindowController: NSObject, NSWindowDelegate {
    private var window: GhostWindow!
    private var statusItem: NSStatusItem?
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
        super.init()
        setupWindow()
        setupStatusItem()
        setupScrollMonitor()
        bindAppState()
    }
    
    private func setupWindow() {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 100, y: 100, width: 440, height: 380)
        let initialWidth: CGFloat = 460
        let initialHeight: CGFloat = 380
        let initialX = screenRect.maxX - initialWidth - 40
        let initialY = screenRect.maxY - initialHeight - 40
        
        let contentRect = NSRect(x: initialX, y: initialY, width: initialWidth, height: initialHeight)
        
        window = GhostWindow(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.delegate = self
        window.isFloatingPanel = true
        window.hidesOnDeactivate = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        
        // CRITICAL: Hide from Screen Capture / Share Screen (Zoom, Meet, Teams, OBS, etc.)
        window.sharingType = .none
        
        // Always on top, visible across all spaces including FullScreen spaces
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.level = .popUpMenu
        
        // Initial opacity
        window.alphaValue = CGFloat(appState.opacity)
        
        // Host SwiftUI ContentView
        let hostingView = NSHostingView(rootView: ContentView(appState: appState))
        window.contentView = hostingView
        
        window.orderFrontRegardless()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.text.fill", accessibilityDescription: "GhostNotes")
        }
        
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "GhostNotes (Teleprompter)", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        let playItem = NSMenuItem(title: "Play / Pause (⌥P)", action: #selector(togglePlay), keyEquivalent: "")
        playItem.target = self
        menu.addItem(playItem)
        
        let lockItem = NSMenuItem(title: "Toggle Ghost Mode (⌥L)", action: #selector(toggleLock), keyEquivalent: "")
        lockItem.target = self
        menu.addItem(lockItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Opacity presets submenu
        let opacityMenu = NSMenu()
        let opacities: [(String, Double)] = [("30%", 0.3), ("50%", 0.5), ("65% (Default)", 0.65), ("80%", 0.8), ("100%", 1.0)]
        for (label, val) in opacities {
            let item = NSMenuItem(title: label, action: #selector(changeOpacityPreset(_:)), keyEquivalent: "")
            item.representedObject = val
            item.target = self
            opacityMenu.addItem(item)
        }
        let opacityParent = NSMenuItem(title: "Atur Opasitas", action: nil, keyEquivalent: "")
        opacityParent.submenu = opacityMenu
        menu.addItem(opacityParent)
        
        menu.addItem(NSMenuItem.separator())
        
        let resetPosItem = NSMenuItem(title: "Reset Posisi Jendela", action: #selector(resetWindowPosition), keyEquivalent: "")
        resetPosItem.target = self
        menu.addItem(resetPosItem)
        
        let quitItem = NSMenuItem(title: "Keluar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func bindAppState() {
        appState.onOpacityChanged = { [weak self] newOpacity in
            DispatchQueue.main.async {
                self?.window.alphaValue = CGFloat(newOpacity)
            }
        }
        
        appState.onGhostModeChanged = { [weak self] isGhost in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.window.ignoresMouseEvents = isGhost
                self.window.level = .popUpMenu
                if isGhost {
                    self.window.orderFrontRegardless()
                } else {
                    self.window.makeKeyAndOrderFront(nil)
                    self.window.orderFrontRegardless()
                }
            }
        }
    }
    
    private func setupScrollMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self = self, self.appState.isGhostMode else { return }
            let mouseLocation = NSEvent.mouseLocation
            if self.window.frame.contains(mouseLocation) {
                let delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.scrollingDeltaY * 12
                self.appState.scrollByDelta(delta)
            }
        }
    }
    
    @objc private func togglePlay() {
        appState.togglePlayPause()
    }
    
    @objc private func toggleLock() {
        appState.toggleGhostMode()
    }
    
    @objc private func changeOpacityPreset(_ sender: NSMenuItem) {
        if let val = sender.representedObject as? Double {
            appState.setOpacity(val)
        }
    }
    
    @objc private func resetWindowPosition() {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 100, y: 100, width: 460, height: 380)
        let initialWidth: CGFloat = 460
        let initialHeight: CGFloat = 380
        let newX = screenRect.maxX - initialWidth - 40
        let newY = screenRect.maxY - initialHeight - 40
        window.setFrame(NSRect(x: newX, y: newY, width: initialWidth, height: initialHeight), display: true, animate: true)
        window.level = .popUpMenu
        window.orderFrontRegardless()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
