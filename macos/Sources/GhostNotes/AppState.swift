import SwiftUI
import Combine

final class AppState: ObservableObject {
    private let defaultNotes = """
Panduan Presentasi Online:
- Salam pembuka & topik utama.
- Latar belakang & permasalahan.
- Solusi inovatif yang ditawarkan.
- Roadmap & timeline eksekusi.
- Kesimpulan & sesi tanya jawab.
"""

    @Published var notesText: String {
        didSet {
            UserDefaults.standard.set(notesText, forKey: "ghostnotes_text")
        }
    }

    @Published var fontSize: CGFloat {
        didSet {
            UserDefaults.standard.set(Double(fontSize), forKey: "ghostnotes_fontsize")
        }
    }
    
    @Published var opacity: Double {
        didSet {
            UserDefaults.standard.set(opacity, forKey: "ghostnotes_opacity")
            onOpacityChanged?(opacity)
        }
    }
    
    @Published var scrollSpeed: Double {
        didSet {
            UserDefaults.standard.set(scrollSpeed, forKey: "ghostnotes_speed")
        }
    }
    
    @Published var isPlaying: Bool = false
    @Published var isGhostMode: Bool = false
    
    var onOpacityChanged: ((Double) -> Void)?
    var onGhostModeChanged: ((Bool) -> Void)?
    var onResetScroll: (() -> Void)?
    var onPasteText: ((String) -> Void)?
    var onManualScrollDelta: ((CGFloat) -> Void)?
    
    func scrollByDelta(_ delta: CGFloat) {
        onManualScrollDelta?(delta)
    }
    
    init() {
        let savedText = UserDefaults.standard.string(forKey: "ghostnotes_text")
        self.notesText = savedText ?? defaultNotes
        
        let savedFontSize = UserDefaults.standard.double(forKey: "ghostnotes_fontsize")
        self.fontSize = savedFontSize > 0 ? CGFloat(savedFontSize) : 18.0
        
        let savedOpacity = UserDefaults.standard.double(forKey: "ghostnotes_opacity")
        self.opacity = savedOpacity > 0 ? savedOpacity : 0.65
        
        let savedSpeed = UserDefaults.standard.double(forKey: "ghostnotes_speed")
        self.scrollSpeed = savedSpeed > 0 ? savedSpeed : 2.0
    }
    
    func togglePlayPause() {
        isPlaying.toggle()
    }
    
    func toggleGhostMode() {
        isGhostMode.toggle()
        onGhostModeChanged?(isGhostMode)
    }
    
    func setOpacity(_ value: Double) {
        opacity = min(max(value, 0.15), 1.0)
    }
    
    func resetScroll() {
        isPlaying = false
        onResetScroll?()
    }
    
    func pasteClipboard() {
        if let clip = NSPasteboard.general.string(forType: .string), !clip.isEmpty {
            self.notesText = clip
            onPasteText?(clip)
        }
    }
    
    func clearText() {
        self.notesText = ""
        onPasteText?("")
    }
}
