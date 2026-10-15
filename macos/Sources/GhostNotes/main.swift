import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appState: AppState!
    private var windowController: OverlayWindowController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as regular app so it receives standard keyboard focus and input events reliably
        NSApp.setActivationPolicy(.regular)
        setupMainMenu()
        
        let state = AppState()
        self.appState = state
        self.windowController = OverlayWindowController(appState: state)
        
        // Setup Global HotKeys
        let hotKeyMgr = HotKeyManager.shared
        hotKeyMgr.onTogglePlayPause = { [weak state] in
            state?.togglePlayPause()
        }
        hotKeyMgr.onToggleGhostMode = { [weak state] in
            state?.toggleGhostMode()
        }
        hotKeyMgr.onScrollUp = { [weak state] in
            state?.scrollByDelta(60)
        }
        hotKeyMgr.onScrollDown = { [weak state] in
            state?.scrollByDelta(-60)
        }
        hotKeyMgr.registerHotKeys()
    }
    
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        editMenuItem.submenu = editMenu
        NSApp.mainMenu = mainMenu
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
