# GhostNotes (Versi Windows)

Teleprompter overlay transparan anti-share screen untuk presentasi online di sistem operasi Windows 10 & 11.

---

## Fitur Utama

1. **Anti-Share Screen (Win32 Native)**:
   - Menggunakan API Windows `SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE)`.
   - **Hasil**: Jendela GhostNotes sama sekali **tidak tertangkap oleh Zoom, Google Meet, Microsoft Teams, Discord, OBS, Snipping Tool, maupun screen recorder Windows** saat share screen.
2. **Mode Tembus Klik / Ghost Mode (`Alt + L`)**:
   - Menggunakan `WS_EX_TRANSPARENT`.
   - Mengunci jendela agar klik mouse tembus langsung ke slide di belakangnya (PowerPoint, Google Slides, Keynote web, Canva, browser).
3. **Auto-Scroll Teleprompter (`Alt + P`)**:
   - Scroll naskah otomatis dengan kecepatan yang dapat diatur via slider.
   - Tetap bisa di-scroll manual menggunakan mouse wheel atau shortcut `Alt + Panah Atas/Bawah` (`Alt + ↑/↓`).
4. **Geser dari Area Mana Saja**:
   - Selama tidak dikunci, klik dan tahan mouse di bagian mana saja pada jendela untuk memindahkannya.
5. **Auto-Save Real-Time**:
   - Teks naskah, ukuran font, opasitas, dan kecepatan tersimpan otomatis ke Windows Registry (`QSettings`).

---

## Cara Menjalankan di Windows

### Cara 1: Langsung Jalankan Script (Cepat)
1. Salin folder `GhostNotes-Windows` ini ke komputer Windows kamu.
2. Klik dua kali file `run.bat`.
   *(Script otomatis memeriksa dependensi PyQt6 dan langsung membuka aplikasi)*.

### Cara 2: Build Menjadi File Mandiri `GhostNotes.exe` (Standalone)
1. Di komputer Windows, klik dua kali file `build_exe.bat`.
2. Tunggu proses kompilasi PyInstaller selesai.
3. File executable mandiri `GhostNotes.exe` akan berada di dalam folder `dist/`. Kamu bisa memindahkannya ke Desktop atau flashdisk tanpa memerlukan Python lagi.

---

## Daftar Shortcut Keyboard Windows
- `Alt + P`: Play / Pause auto-scroll teleprompter.
- `Alt + L`: Kunci / Buka mode tembus klik (Ghost Mode).
- `Alt + Panah Bawah` (`Alt + ↓`): Scroll turun naskah.
- `Alt + Panah Atas` (`Alt + ↑`): Scroll naik naskah.
