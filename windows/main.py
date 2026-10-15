import sys
import os
from PyQt6.QtCore import Qt, QTimer, QPoint, QSettings
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QSlider, QTextEdit, QSystemTrayIcon, QMenu
)
from PyQt6.QtGui import QFont, QColor, QPalette, QIcon, QPainter, QPixmap

# Win32 API Definitions
IS_WINDOWS = sys.platform == "win32"

if IS_WINDOWS:
    import ctypes
    from ctypes import wintypes

    user32 = ctypes.windll.user32
    
    # Anti-Share Screen Flags
    WDA_NONE = 0x00000000
    WDA_MONITOR = 0x00000001
    WDA_EXCLUDEFROMCAPTURE = 0x00000011  # Windows 10 (2004+) & Windows 11
    
    # Extended Window Styles for Click-Through (Ghost Mode)
    GWL_EXSTYLE = -20
    WS_EX_TRANSPARENT = 0x00000020
    WS_EX_LAYERED = 0x00080000
    
    # SetWindowPos Flags
    HWND_TOPMOST = -1
    SWP_NOMOVE = 0x0002
    SWP_NOSIZE = 0x0001
    SWP_NOACTIVATE = 0x0010
    
    # HotKey Modifiers & Keys
    MOD_ALT = 0x0001
    MOD_NOREPEAT = 0x4000
    VK_P = 0x50
    VK_L = 0x4C
    VK_UP = 0x26
    VK_DOWN = 0x28
    
    HOTKEY_PLAY_PAUSE = 101
    HOTKEY_GHOST_MODE = 102
    HOTKEY_SCROLL_UP = 103
    HOTKEY_SCROLL_DOWN = 104


class GhostNotesWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        
        self.settings = QSettings("GhostNotes", "Settings")
        
        # State variables
        self.is_ghost_mode = False
        self.is_playing = False
        self.is_user_scrolling = False
        self.drag_start_position = None
        
        # Load saved settings or defaults
        self.saved_text = self.settings.value("notes_text", """Panduan Presentasi Online:
- Salam pembuka & topik utama.
- Latar belakang & permasalahan.
- Solusi inovatif yang ditawarkan.
- Roadmap & timeline eksekusi.
- Kesimpulan & sesi tanya jawab.""")
        self.current_font_size = int(self.settings.value("font_size", 18))
        self.current_opacity = float(self.settings.value("opacity", 0.65))
        self.current_speed = float(self.settings.value("scroll_speed", 2.0))
        
        self.init_window_properties()
        self.init_ui()
        self.init_timers()
        
        if IS_WINDOWS:
            self.init_win32()

    def init_window_properties(self):
        # Frameless, Always on Top, Tool window (no taskbar clutter)
        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint |
            Qt.WindowType.WindowStaysOnTopHint |
            Qt.WindowType.SubWindow
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground, True)
        self.resize(460, 380)
        self.setMinimumSize(400, 260)
        self.setWindowOpacity(self.current_opacity)

    def init_ui(self):
        central_widget = QWidget(self)
        central_widget.setObjectName("CentralWidget")
        
        # Styling (Clean, minimalist, monochrome dark slate/zinc)
        central_widget.setStyleSheet("""
            QWidget#CentralWidget {
                background-color: rgba(20, 23, 28, 235);
                border: 1px solid rgba(255, 255, 255, 35);
                border-radius: 10px;
            }
            QLabel {
                color: rgba(255, 255, 255, 200);
                font-family: 'Segoe UI', sans-serif;
            }
            QPushButton {
                background-color: rgba(255, 255, 255, 22);
                color: #ffffff;
                border: 1px solid rgba(255, 255, 255, 28);
                border-radius: 5px;
                padding: 4px 8px;
                font-family: 'Segoe UI', sans-serif;
                font-size: 11px;
                font-weight: 500;
            }
            QPushButton:hover {
                background-color: rgba(255, 255, 255, 38);
            }
            QPushButton:pressed {
                background-color: rgba(255, 255, 255, 50);
            }
            QSlider::groove:horizontal {
                height: 4px;
                background: rgba(255, 255, 255, 40);
                border-radius: 2px;
            }
            QSlider::sub-page:horizontal {
                background: rgba(255, 255, 255, 160);
                border-radius: 2px;
            }
            QSlider::handle:horizontal {
                background: #ffffff;
                width: 12px;
                margin-top: -4px;
                margin-bottom: -4px;
                border-radius: 6px;
            }
            QTextEdit {
                background-color: transparent;
                color: #ffffff;
                border: none;
                padding: 10px;
                selection-background-color: rgba(255, 255, 255, 60);
            }
            QScrollBar:vertical {
                border: none;
                background: transparent;
                width: 6px;
                margin: 0px;
            }
            QScrollBar::handle:vertical {
                background: rgba(255, 255, 255, 60);
                min-height: 20px;
                border-radius: 3px;
            }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                height: 0px;
            }
        """)

        layout = QVBoxLayout(central_widget)
        layout.setContentsMargins(12, 10, 12, 10)
        layout.setSpacing(8)

        # Header: Title & Action Buttons
        header_layout = QHBoxLayout()
        header_layout.setSpacing(6)

        title_label = QLabel("GhostNotes")
        title_font = QFont("Segoe UI", 10, QFont.Weight.DemiBold)
        title_label.setFont(title_font)
        title_label.setStyleSheet("color: rgba(255, 255, 255, 230); font-family: monospace;")
        header_layout.addWidget(title_label)

        header_layout.addStretch()

        # Tempel / Paste Button
        self.paste_btn = QPushButton("Tempel")
        self.paste_btn.setToolTip("Tempel teks dari clipboard")
        self.paste_btn.clicked.connect(self.paste_clipboard)
        header_layout.addWidget(self.paste_btn)

        # Hapus / Clear Button
        self.clear_btn = QPushButton("Hapus")
        self.clear_btn.setToolTip("Kosongkan teks")
        self.clear_btn.clicked.connect(self.clear_text)
        header_layout.addWidget(self.clear_btn)

        # Play / Pause Button
        self.play_btn = QPushButton("Play [Alt+P]")
        self.play_btn.setToolTip("Jalankan auto-scroll (Alt+P)")
        self.play_btn.clicked.connect(self.toggle_play_pause)
        header_layout.addWidget(self.play_btn)

        # Reset Scroll Button
        self.reset_btn = QPushButton("↺")
        self.reset_btn.setToolTip("Kembali ke baris teratas")
        self.reset_btn.clicked.connect(self.reset_scroll)
        header_layout.addWidget(self.reset_btn)

        # Lock / Ghost Mode Button
        self.lock_btn = QPushButton("Kunci [Alt+L]")
        self.lock_btn.setToolTip("Aktifkan mode tembus klik untuk presentasi (Alt+L)")
        self.lock_btn.clicked.connect(self.toggle_ghost_mode)
        header_layout.addWidget(self.lock_btn)

        layout.addLayout(header_layout)

        # Sliders Row (Opacity, Font, Speed)
        slider_layout = QHBoxLayout()
        slider_layout.setSpacing(14)

        # Opacity Slider
        opacity_box = QHBoxLayout()
        opacity_box.setSpacing(6)
        lbl_op = QLabel("Opasitas")
        lbl_op.setStyleSheet("color: rgba(255,255,255,140); font-size: 10px;")
        self.opacity_slider = QSlider(Qt.Orientation.Horizontal)
        self.opacity_slider.setRange(20, 100)
        self.opacity_slider.setValue(int(self.current_opacity * 100))
        self.opacity_slider.setFixedWidth(70)
        self.opacity_val_lbl = QLabel(f"{int(self.current_opacity * 100)}%")
        self.opacity_val_lbl.setStyleSheet("color: rgba(255,255,255,170); font-size: 10px; font-family: monospace;")
        self.opacity_slider.valueChanged.connect(self.on_opacity_slider_changed)
        opacity_box.addWidget(lbl_op)
        opacity_box.addWidget(self.opacity_slider)
        opacity_box.addWidget(self.opacity_val_lbl)
        slider_layout.addLayout(opacity_box)

        # Font Size Slider
        font_box = QHBoxLayout()
        font_box.setSpacing(6)
        lbl_font = QLabel("Font")
        lbl_font.setStyleSheet("color: rgba(255,255,255,140); font-size: 10px;")
        self.font_slider = QSlider(Qt.Orientation.Horizontal)
        self.font_slider.setRange(14, 36)
        self.font_slider.setValue(self.current_font_size)
        self.font_slider.setFixedWidth(65)
        self.font_val_lbl = QLabel(f"{self.current_font_size}pt")
        self.font_val_lbl.setStyleSheet("color: rgba(255,255,255,170); font-size: 10px; font-family: monospace;")
        self.font_slider.valueChanged.connect(self.on_font_slider_changed)
        font_box.addWidget(lbl_font)
        font_box.addWidget(self.font_slider)
        font_box.addWidget(self.font_val_lbl)
        slider_layout.addLayout(font_box)

        # Speed Slider
        speed_box = QHBoxLayout()
        speed_box.setSpacing(6)
        lbl_speed = QLabel("Speed")
        lbl_speed.setStyleSheet("color: rgba(255,255,255,140); font-size: 10px;")
        self.speed_slider = QSlider(Qt.Orientation.Horizontal)
        self.speed_slider.setRange(10, 80)
        self.speed_slider.setValue(int(self.current_speed * 10))
        self.speed_slider.setFixedWidth(65)
        self.speed_val_lbl = QLabel(f"{self.current_speed:.1f}x")
        self.speed_val_lbl.setStyleSheet("color: rgba(255,255,255,170); font-size: 10px; font-family: monospace;")
        self.speed_slider.valueChanged.connect(self.on_speed_slider_changed)
        speed_box.addWidget(lbl_speed)
        speed_box.addWidget(self.speed_slider)
        speed_box.addWidget(self.speed_val_lbl)
        slider_layout.addLayout(speed_box)

        slider_layout.addStretch()
        layout.addLayout(slider_layout)

        # Ghost Mode Banner (Hidden by default)
        self.ghost_banner = QLabel("Mode Tembus Klik Aktif • Alt+P: Pause • Alt+L: Buka Kunci • Alt+↑↓: Scroll")
        self.ghost_banner.setStyleSheet("""
            background-color: rgba(0, 0, 0, 90);
            color: rgba(255, 255, 255, 220);
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 10px;
            font-family: monospace;
        """)
        self.ghost_banner.setVisible(False)
        layout.addWidget(self.ghost_banner)

        # Teleprompter Text Editor
        self.text_edit = QTextEdit()
        self.text_edit.setPlainText(self.saved_text)
        self.update_font()
        self.text_edit.textChanged.connect(self.on_text_changed)
        layout.addWidget(self.text_edit)

        self.setCentralWidget(central_widget)

    def init_timers(self):
        # Auto-scroll timer (runs every 30ms for smooth 33fps movement)
        self.scroll_timer = QTimer(self)
        self.scroll_timer.setInterval(30)
        self.scroll_timer.timeout.connect(self.on_scroll_tick)

        # Debounce timer for manual user scrolling (trackpad / mouse wheel)
        self.user_scroll_debounce = QTimer(self)
        self.user_scroll_debounce.setSingleShot(True)
        self.user_scroll_debounce.setInterval(600)
        self.user_scroll_debounce.timeout.connect(self.resume_auto_scroll_after_user)

    def init_win32(self):
        hwnd = int(self.winId())
        
        # 1. Anti-Share Screen: Hide from Zoom, Meet, Teams, OBS, Discord, etc.
        try:
            res = user32.SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE)
            if not res:
                user32.SetWindowDisplayAffinity(hwnd, WDA_MONITOR)
        except Exception as e:
            print(f"SetWindowDisplayAffinity notice: {e}")
            
        # 2. Always on Top across Fullscreen presentations
        user32.SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE)

        # 3. Register Global HotKeys
        # Alt+P (Play/Pause), Alt+L (Ghost Mode), Alt+Up (Scroll Up), Alt+Down (Scroll Down)
        user32.RegisterHotKey(hwnd, HOTKEY_PLAY_PAUSE, MOD_ALT | MOD_NOREPEAT, VK_P)
        user32.RegisterHotKey(hwnd, HOTKEY_GHOST_MODE, MOD_ALT | MOD_NOREPEAT, VK_L)
        user32.RegisterHotKey(hwnd, HOTKEY_SCROLL_UP, MOD_ALT | MOD_NOREPEAT, VK_UP)
        user32.RegisterHotKey(hwnd, HOTKEY_SCROLL_DOWN, MOD_ALT | MOD_NOREPEAT, VK_DOWN)

    # Win32 Message Hook for Global HotKeys
    def nativeEvent(self, eventType, message):
        if IS_WINDOWS and eventType == b"windows_generic_MSG":
            msg = wintypes.MSG.from_address(int(message))
            if msg.message == 0x0312:  # WM_HOTKEY
                hotkey_id = msg.wParam
                if hotkey_id == HOTKEY_PLAY_PAUSE:
                    self.toggle_play_pause()
                elif hotkey_id == HOTKEY_GHOST_MODE:
                    self.toggle_ghost_mode()
                elif hotkey_id == HOTKEY_SCROLL_UP:
                    self.scroll_by_delta(-60)
                elif hotkey_id == HOTKEY_SCROLL_DOWN:
                    self.scroll_by_delta(60)
                return True, 0
        return super().nativeEvent(eventType, message)

    # Drag window from anywhere
    def mousePressEvent(self, event):
        if not self.is_ghost_mode and event.button() == Qt.MouseButton.LeftButton:
            self.drag_start_position = event.globalPosition().toPoint() - self.frameGeometry().topLeft()
            event.accept()

    def mouseMoveEvent(self, event):
        if not self.is_ghost_mode and self.drag_start_position and event.buttons() == Qt.MouseButton.LeftButton:
            self.move(event.globalPosition().toPoint() - self.drag_start_position)
            event.accept()

    def mouseReleaseEvent(self, event):
        self.drag_start_position = None

    # Handle manual trackpad / mouse wheel scroll during play
    def wheelEvent(self, event):
        self.is_user_scrolling = True
        self.user_scroll_debounce.start(600)
        super().wheelEvent(event)

    def resume_auto_scroll_after_user(self):
        self.is_user_scrolling = False

    def scroll_by_delta(self, delta_y: int):
        self.is_user_scrolling = True
        self.user_scroll_debounce.start(600)
        scrollbar = self.text_edit.verticalScrollBar()
        scrollbar.setValue(scrollbar.value() + delta_y)

    def on_scroll_tick(self):
        if self.is_playing and not self.is_user_scrolling:
            scrollbar = self.text_edit.verticalScrollBar()
            if scrollbar.value() < scrollbar.maximum():
                step = max(1, int(self.current_speed * 0.8))
                scrollbar.setValue(scrollbar.value() + step)
            else:
                self.is_playing = False
                self.play_btn.setText("Play [Alt+P]")

    def toggle_play_pause(self):
        self.is_playing = not self.is_playing
        if self.is_playing:
            self.play_btn.setText("Pause [Alt+P]")
            self.scroll_timer.start()
        else:
            self.play_btn.setText("Play [Alt+P]")
            self.scroll_timer.stop()

    def reset_scroll(self):
        self.is_playing = False
        self.play_btn.setText("Play [Alt+P]")
        self.scroll_timer.stop()
        self.text_edit.verticalScrollBar().setValue(0)

    def toggle_ghost_mode(self):
        self.is_ghost_mode = not self.is_ghost_mode
        self.ghost_banner.setVisible(self.is_ghost_mode)
        
        if self.is_ghost_mode:
            self.lock_btn.setText("Buka [Alt+L]")
            if IS_WINDOWS:
                hwnd = int(self.winId())
                ex_style = user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
                user32.SetWindowLongW(hwnd, GWL_EXSTYLE, ex_style | WS_EX_TRANSPARENT | WS_EX_LAYERED)
        else:
            self.lock_btn.setText("Kunci [Alt+L]")
            if IS_WINDOWS:
                hwnd = int(self.winId())
                ex_style = user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
                user32.SetWindowLongW(hwnd, GWL_EXSTYLE, ex_style & ~WS_EX_TRANSPARENT)

    def on_opacity_slider_changed(self, value):
        self.current_opacity = value / 100.0
        self.setWindowOpacity(self.current_opacity)
        self.opacity_val_lbl.setText(f"{value}%")
        self.settings.setValue("opacity", self.current_opacity)

    def on_font_slider_changed(self, value):
        self.current_font_size = value
        self.font_val_lbl.setText(f"{value}pt")
        self.update_font()
        self.settings.setValue("font_size", self.current_font_size)

    def on_speed_slider_changed(self, value):
        self.current_speed = value / 10.0
        self.speed_val_lbl.setText(f"{self.current_speed:.1f}x")
        self.settings.setValue("scroll_speed", self.current_speed)

    def update_font(self):
        font = QFont("Segoe UI", self.current_font_size)
        font.setStyleHint(QFont.StyleHint.SansSerif)
        self.text_edit.setFont(font)

    def on_text_changed(self):
        self.settings.setValue("notes_text", self.text_edit.toPlainText())

    def paste_clipboard(self):
        text = QApplication.clipboard().text()
        if text:
            self.text_edit.setPlainText(text)
            self.settings.setValue("notes_text", text)

    def clear_text(self):
        self.text_edit.clear()
        self.settings.setValue("notes_text", "")

    def closeEvent(self, event):
        if IS_WINDOWS:
            hwnd = int(self.winId())
            user32.UnregisterHotKey(hwnd, HOTKEY_PLAY_PAUSE)
            user32.UnregisterHotKey(hwnd, HOTKEY_GHOST_MODE)
            user32.UnregisterHotKey(hwnd, HOTKEY_SCROLL_UP)
            user32.UnregisterHotKey(hwnd, HOTKEY_SCROLL_DOWN)
        super().closeEvent(event)


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("GhostNotes")
    
    window = GhostNotesWindow()
    window.show()
    
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
