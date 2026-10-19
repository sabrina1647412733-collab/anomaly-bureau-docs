@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0_setup\backup-docs.ps1"
echo.
pause
