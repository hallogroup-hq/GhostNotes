@echo off
title Build GhostNotes Standalone EXE
echo ========================================================
echo Membangun GhostNotes.exe (Standalone Windows Executable)
echo ========================================================

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python tidak ditemukan di PATH.
    pause
    exit /b
)

echo 1. Menginstal dependensi & PyInstaller...
pip install -r requirements.txt

echo 2. Mengompilasi menjadi satu file .exe...
pyinstaller --clean --onefile --noconsole --name "GhostNotes" main.py

echo.
echo ========================================================
echo SUKSES! GhostNotes.exe siap digunakan di folder:
echo dist\GhostNotes.exe
echo ========================================================
pause
