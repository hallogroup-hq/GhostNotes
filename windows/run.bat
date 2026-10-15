@echo off
title GhostNotes (Windows)
echo Menjalankan GhostNotes untuk Windows...

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python belum terinstall atau belum dimasukkan ke PATH Windows.
    echo Silakan install Python dari python.org dan centang "Add Python to PATH".
    pause
    exit /b
)

echo Memeriksa dan menginstal dependensi...
pip install -r requirements.txt

echo Membuka aplikasi GhostNotes...
start "" pythonw main.py
exit
