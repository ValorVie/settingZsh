@echo off
REM Windows 安裝入口：以 Bypass 執行策略呼叫 setup_win.ps1
echo === Windows 環境安裝 ===
powershell -ExecutionPolicy Bypass -File "%~dp0setup_win.ps1"
pause
