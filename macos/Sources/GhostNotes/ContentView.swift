import SwiftUI
import AppKit

// Dedicated drag handle for the window header
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DragNSView {
        DragNSView()
    }
    func updateNSView(_ nsView: DragNSView, context: Context) {}
    
    class DragNSView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

struct ContentView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Neutral translucent background (Monochrome / Zinc dark)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
            
            VStack(spacing: 0) {
                // Top Header & Controls
                if !appState.isGhostMode {
                    headerToolbar
                    Divider()
                        .background(Color.white.opacity(0.10))
                } else {
                    // Minimalist indicator during Ghost Mode
                    ghostModeIndicator
                }
                
                // Unified Text Editor & Teleprompter
                TeleprompterTextView(appState: appState)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
            }
        }
        .frame(minWidth: 440, minHeight: 320)
    }
    
    // MARK: - Toolbar Controls
    private var headerToolbar: some View {
        VStack(spacing: 8) {
            // Row 1: Actions & Mode Toggles
            HStack(spacing: 10) {
                // Window drag handle
                HStack(spacing: 6) {
                    Image(systemName: "circle.grid.2x2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    Text("GhostNotes")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                .overlay(WindowDragHandle())
                
                Spacer()
                
                // Quick Paste button
                Button(action: {
                    appState.pasteClipboard()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 10))
                        Text("Tempel")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.10))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                // Clear text button
                Button(action: {
                    appState.clearText()
                }) {
                    Text("Hapus")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.06))
                        .foregroundColor(.white.opacity(0.7))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                // Play / Pause
                Button(action: {
                    appState.togglePlayPause()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 10))
                        Text(appState.isPlaying ? "Pause" : "Play")
                            .font(.system(size: 11, weight: .semibold))
                        Text("⌥P")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                // Reset Scroll
                Button(action: {
                    appState.resetScroll()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                // Lock / Ghost Mode (Click-Through)
                Button(action: {
                    appState.toggleGhostMode()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Kunci Layar")
                            .font(.system(size: 11, weight: .medium))
                        Text("⌥L")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.10))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            // Row 2: Sliders for Opacity, Speed, Font
            HStack(spacing: 16) {
                // Opacity Slider
                HStack(spacing: 6) {
                    Text("Opasitas")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Slider(value: Binding(
                        get: { appState.opacity },
                        set: { appState.setOpacity($0) }
                    ), in: 0.20...1.0, step: 0.05)
                    .frame(width: 80)
                    .controlSize(.mini)
                    
                    Text("\(Int(appState.opacity * 100))%")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, alignment: .leading)
                }
                
                // Font Size Slider
                HStack(spacing: 6) {
                    Text("Font")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Slider(value: $appState.fontSize, in: 14...36, step: 1)
                        .frame(width: 70)
                        .controlSize(.mini)
                    
                    Text("\(Int(appState.fontSize))pt")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 28, alignment: .leading)
                }
                
                // Speed Slider
                HStack(spacing: 6) {
                    Text("Speed")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Slider(value: $appState.scrollSpeed, in: 1.0...8.0, step: 0.5)
                        .frame(width: 70)
                        .controlSize(.mini)
                    
                    Text(String(format: "%.1fx", appState.scrollSpeed))
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, alignment: .leading)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Ghost Mode Active Banner
    private var ghostModeIndicator: some View {
        HStack(spacing: 10) {
            Text("Mode Tembus Klik (Ghost Mode)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("Scroll: Trackpad / ⌥↑↓")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("⌥P: \(appState.isPlaying ? "Pause" : "Play")")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("⌥L: Buka Kunci")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.35))
    }
}
