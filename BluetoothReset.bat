@echo off
:: BluetoothReset.bat — self-elevating launcher
:: 1. If we're not running as admin, re-launch via UAC
:: 2. Once elevated, invoke BluetoothReset.ps1 (must sit alongside this file)
::
:: Note: -ExecutionPolicy Bypass is scoped to this one PowerShell invocation
:: only. It does not change machine policy. Standard pattern for distributing
:: single-use admin scripts. (User authorized 2026-05-18.)

setlocal

:: --- Check for admin ---
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Requesting administrator access...
    powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath cmd -ArgumentList '/c \"\"%~f0\"\"'"
    exit /b
)

:: --- Now elevated; locate the PS1 sitting next to us ---
set "PS1=%~dp0BluetoothReset.ps1"
if not exist "%PS1%" (
    echo.
    echo ERROR: Cannot find BluetoothReset.ps1 in the same folder as this script.
    echo Make sure you extracted both files together before running.
    echo.
    pause
    exit /b 1
)

:: --- Run the PS1 with single-invocation policy bypass ---
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"

endlocal
