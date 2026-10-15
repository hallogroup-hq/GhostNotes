import SwiftUI
import AppKit

// Subclass NSScrollView to detect manual trackpad / mouse wheel gestures
final class PrompterScrollView: NSScrollView {
    var isUserScrolling: Bool = false
    var userScrollDebounceTimer: Timer?
    
    override func scrollWheel(with event: NSEvent) {
        // User is manually scrolling
        isUserScrolling = true
        userScrollDebounceTimer?.invalidate()
        
        // Give 0.6s after gesture ends before auto-scroll continues
        userScrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
            self?.isUserScrolling = false
        }
        
        super.scrollWheel(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

// Subclass NSTextView to detect arrow key navigation and window dragging
final class PrompterTextView: NSTextView {
    override func mouseDragged(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    
    override func keyDown(with event: NSEvent) {
        if let prompterSV = enclosingScrollView as? PrompterScrollView {
            // Arrow keys or Page Up/Down
            if event.keyCode == 125 || event.keyCode == 126 || event.keyCode == 115 || event.keyCode == 116 || event.keyCode == 121 || event.keyCode == 119 {
                prompterSV.isUserScrolling = true
                prompterSV.userScrollDebounceTimer?.invalidate()
                prompterSV.userScrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak prompterSV] _ in
                    prompterSV?.isUserScrolling = false
                }
            }
        }
        super.keyDown(with: event)
    }
}

struct TeleprompterTextView: NSViewRepresentable {
    @ObservedObject var appState: AppState
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> PrompterScrollView {
        let scrollView = PrompterScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.scrollerStyle = .overlay
        scrollView.autoresizingMask = [.width, .height]
        
        let contentSize = scrollView.contentSize
        let textView = PrompterTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSSize(width: 0.0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        if let container = textView.textContainer {
            container.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            container.widthTracksTextView = true
            container.lineFragmentPadding = 12
        }
        
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textColor = NSColor.white
        textView.insertionPointColor = NSColor.white
        textView.font = NSFont.systemFont(ofSize: appState.fontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 10, height: 16)
        textView.string = appState.notesText
        textView.delegate = context.coordinator
        
        Self.applyParagraphStyle(to: textView, fontSize: appState.fontSize)
        
        scrollView.documentView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.textView = textView
        context.coordinator.startTimer()
        
        appState.onResetScroll = { [weak coordinator = context.coordinator] in
            coordinator?.resetScroll()
        }
        
        appState.onPasteText = { [weak textView] newText in
            guard let textView = textView else { return }
            textView.string = newText
            TeleprompterTextView.applyParagraphStyle(to: textView, fontSize: context.coordinator.parent.appState.fontSize)
        }
        
        appState.onManualScrollDelta = { [weak coordinator = context.coordinator] delta in
            coordinator?.scrollByDelta(delta)
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: PrompterScrollView, context: Context) {
        guard let textView = nsView.documentView as? PrompterTextView else { return }
        
        // Update font if changed
        if textView.font?.pointSize != appState.fontSize {
            textView.font = NSFont.systemFont(ofSize: appState.fontSize, weight: .regular)
            TeleprompterTextView.applyParagraphStyle(to: textView, fontSize: appState.fontSize)
        }
        
        // If string was changed externally and differs
        if textView.string != appState.notesText {
            textView.string = appState.notesText
            TeleprompterTextView.applyParagraphStyle(to: textView, fontSize: appState.fontSize)
        }
    }
    
    static func applyParagraphStyle(to textView: NSTextView, fontSize: CGFloat) {
        guard let storage = textView.textStorage, storage.length > 0 else { return }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = fontSize * 0.35
        style.paragraphSpacing = fontSize * 0.5
        
        let range = NSRange(location: 0, length: storage.length)
        storage.addAttribute(.paragraphStyle, value: style, range: range)
        storage.addAttribute(.foregroundColor, value: NSColor.white, range: range)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TeleprompterTextView
        weak var scrollView: PrompterScrollView?
        weak var textView: PrompterTextView?
        private var displayTimer: Timer?
        
        init(_ parent: TeleprompterTextView) {
            self.parent = parent
        }
        
        func startTimer() {
            displayTimer?.invalidate()
            displayTimer = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { [weak self] _ in
                self?.handleScrollTick()
            }
        }
        
        private func handleScrollTick() {
            guard parent.appState.isPlaying,
                  let scrollView = scrollView,
                  !scrollView.isUserScrolling, // Allow manual trackpad/mouse wheel scrolling without interruption
                  let clipView = scrollView.contentView as NSClipView?,
                  let documentView = scrollView.documentView else { return }
            
            let currentY = clipView.bounds.origin.y
            let maxScrollY = max(0, documentView.frame.height - clipView.bounds.height)
            
            if currentY < maxScrollY {
                let step = CGFloat(parent.appState.scrollSpeed) * 0.35
                let nextY = min(currentY + step, maxScrollY)
                clipView.scroll(to: NSPoint(x: 0, y: nextY))
                scrollView.reflectScrolledClipView(clipView)
            } else {
                DispatchQueue.main.async {
                    self.parent.appState.isPlaying = false
                }
            }
        }
        
        func resetScroll() {
            guard let scrollView = scrollView,
                  let clipView = scrollView.contentView as NSClipView? else { return }
            clipView.scroll(to: .zero)
            scrollView.reflectScrolledClipView(clipView)
        }
        
        func scrollByDelta(_ delta: CGFloat) {
            guard let scrollView = scrollView,
                  let clipView = scrollView.contentView as NSClipView?,
                  let documentView = scrollView.documentView else { return }
            
            scrollView.isUserScrolling = true
            scrollView.userScrollDebounceTimer?.invalidate()
            scrollView.userScrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak scrollView] _ in
                scrollView?.isUserScrolling = false
            }
            
            let currentY = clipView.bounds.origin.y
            let maxScrollY = max(0, documentView.frame.height - clipView.bounds.height)
            let targetY = max(0, min(currentY - delta, maxScrollY))
            clipView.scroll(to: NSPoint(x: 0, y: targetY))
            scrollView.reflectScrolledClipView(clipView)
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.appState.notesText = textView.string
        }
        
        deinit {
            displayTimer?.invalidate()
        }
    }
}
