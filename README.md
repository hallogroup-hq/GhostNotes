# GhostNotes

> **Invisible Overlay Teleprompter for Online Presentations (macOS & Windows)**

GhostNotes is a lightweight, floating teleprompter overlay designed for speakers presenting slides or sharing screens. It stays visible and legible on your screen while remaining completely invisible to your audience during screen shares and recordings.

---

## Key Features

1. **Anti-Share Screen Protection**:
   - **macOS**: Native WindowServer exclusion (`NSWindow.sharingType = .none`).
   - **Windows**: Native DWM capture exclusion (`SetWindowDisplayAffinity` with `WDA_EXCLUDEFROMCAPTURE`).
   - **Result**: The teleprompter is completely invisible to Zoom, Google Meet, Microsoft Teams, Discord, OBS, QuickTime, and Snipping Tool. Your audience only sees your presentation slides.

2. **Ghost Mode (Click-Through)**:
   - When presenting, lock the window so all mouse clicks pass directly through to your slides (Keynote, PowerPoint, Google Slides, Canva, or browser) without losing focus.
   - Shortcut: `Option + L` (`⌥L`) on macOS / `Alt + L` on Windows.

3. **Fullscreen & Slideshow Compatible**:
   - Stays on top across all Spaces and above native fullscreen slideshow presentations.

4. **Smooth Auto-Scroll & Manual Scroll Override**:
   - Auto-scrolls your notes at an adjustable speed.
   - Supports manual scrolling (trackpad 2-finger scroll, mouse wheel, or arrow keys) even while playing and even while in locked Ghost Mode.
   - Shortcut: `Option + P` (`⌥P`) on macOS / `Alt + P` on Windows.

5. **Adjustable Opacity & Typography**:
   - Real-time opacity slider (20% to 100%, default 65%) to read notes without obstructing slide visibility.
   - Dynamic font size slider (14pt to 36pt).
   - One-click clipboard paste and clear buttons.
   - Auto-saves notes and settings in real time.

6. **Move From Anywhere**:
   - Drag and reposition the window from anywhere on its canvas when unlocked.

---

## macOS Version

Built natively with **Swift**, **SwiftUI**, and **AppKit**.

### Quick Start
Clone the repository and build the `.app` bundle:
```bash
cd macos
chmod +x build.sh
./build.sh
open GhostNotes.app
```

### Shortcuts (macOS)
| Action | Shortcut |
| :--- | :--- |
| **Play / Pause Auto-Scroll** | `Option + P` (`⌥P`) |
| **Lock / Unlock Ghost Mode** | `Option + L` (`⌥L`) |
| **Manual Scroll Up** | `Option + ↑` (`⌥↑`) or Trackpad |
| **Manual Scroll Down** | `Option + ↓` (`⌥↓`) or Trackpad |

---

## Windows Version

Built with **Python**, **PyQt6**, and native **Win32 APIs** (`ctypes`).

### Quick Start
1. Ensure Python 3.10+ is installed on Windows.
2. Open the `windows` folder and run:
   ```cmd
   run.bat
   ```
   *(Automatically installs `PyQt6` and launches the app)*.

### Build Standalone Executable (`GhostNotes.exe`)
To package into a single `.exe` file that runs without Python:
```cmd
build_exe.bat
```
The compiled executable will be located in `windows\dist\GhostNotes.exe`.

### Shortcuts (Windows)
| Action | Shortcut |
| :--- | :--- |
| **Play / Pause Auto-Scroll** | `Alt + P` |
| **Lock / Unlock Ghost Mode** | `Alt + L` |
| **Manual Scroll Up** | `Alt + ↑` or Mouse Wheel |
| **Manual Scroll Down** | `Alt + ↓` or Mouse Wheel |

---

## License

MIT License. Free for personal and commercial use.
