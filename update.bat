@echo off
REM Windows 更新入口：以 Bypass 執行策略呼叫 update_win.ps1
echo === Windows 環境更新 ===
powershell -ExecutionPolicy Bypass -File "%~dp0update_win.ps1"
pause
