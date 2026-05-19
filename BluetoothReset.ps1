# BluetoothReset.ps1
# Lists paired Bluetooth devices and fully removes the user's selection
# (Win32 API + PnP + registry) so it can be re-paired from scratch.
#
# Requires Administrator (the registry cleanup writes to HKLM\SYSTEM).
# The companion BluetoothReset.bat handles the UAC prompt for you.

$ErrorActionPreference = 'Continue'

# Load the Win32 Bluetooth API
$csSource = @"
using System;
using System.Runtime.InteropServices;
public class BluetoothRemover {
    [DllImport("bthprops.cpl", SetLastError = true)]
    public static extern bool BluetoothRemoveDevice(ref ulong pAddress);
}
"@
Add-Type -TypeDefinition $csSource -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Bluetooth Device Reset" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Pull paired Bluetooth peripherals. The DEV_ filter rules out drivers/interfaces.
$all = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object {
    $_.HardwareID -match 'DEV_'
}

if (-not $all -or $all.Count -eq 0) {
    Write-Host "No paired Bluetooth devices found." -ForegroundColor Yellow
    Write-Host "Make sure the device you want to reset has been paired before (or is currently paired)." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

# Group by name so the same device's multiple instances appear once
$grouped = $all | Group-Object FriendlyName | Sort-Object Name

Write-Host "Paired Bluetooth devices:" -ForegroundColor Cyan
Write-Host ""

$choices = @()
$i = 1
foreach ($g in $grouped) {
    $name = $g.Name
    $status = ($g.Group | Select-Object -First 1).Status
    Write-Host ("  {0,2}) {1}  [{2}]" -f $i, $name, $status) -ForegroundColor White
    $choices += [PSCustomObject]@{ Number = $i; Name = $name; Devices = $g.Group }
    $i++
}

Write-Host ""
$pick = Read-Host "Enter the number of the device to reset (or 'q' to quit)"

if ($pick -match '^[qQ]') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

$pickInt = 0
if (-not [int]::TryParse($pick, [ref]$pickInt)) {
    Write-Host "Invalid input." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

$selected = $choices | Where-Object { $_.Number -eq $pickInt } | Select-Object -First 1
if (-not $selected) {
    Write-Host "No device with number $pickInt." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""
Write-Host "Resetting: $($selected.Name)" -ForegroundColor Cyan
Write-Host ""

foreach ($dev in $selected.Devices) {
    Write-Host "  Instance: $($dev.InstanceId)" -ForegroundColor Gray

    # 1. Win32 API removal — pulls the BT address from the HardwareID
    try {
        $addressHex = $dev.HardwareID[0].Substring(12)
        $addressInt = [Convert]::ToUInt64($addressHex, 16)
        $result = [BluetoothRemover]::BluetoothRemoveDevice([ref]$addressInt)
        if ($result) {
            Write-Host "    API removal: success" -ForegroundColor Green
        } else {
            Write-Host "    API removal: returned false (PnP will catch it)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    API removal: skipped (could not parse address)" -ForegroundColor Yellow
    }

    # 2. PnP removal — disable then remove (belt and suspenders)
    try {
        Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Remove-PnpDevice  -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "    PnP removal: complete" -ForegroundColor Green
    } catch {
        Write-Host "    PnP removal: failed ($($_.Exception.Message))" -ForegroundColor Red
    }
}

# 3. Registry pairing cache — the part that needs admin
Write-Host ""
Write-Host "Cleaning Bluetooth registry cache..." -ForegroundColor Cyan
$btRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Devices"
if (Test-Path $btRegPath) {
    $removed = 0
    Get-ChildItem $btRegPath -ErrorAction SilentlyContinue | ForEach-Object {
        $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($props.FriendlyName -eq $selected.Name) {
            Write-Host "  Removing registry entry for: $($props.FriendlyName)" -ForegroundColor Yellow
            Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            $removed++
        }
    }
    if ($removed -eq 0) {
        Write-Host "  No matching registry entries found (already clean)" -ForegroundColor Gray
    }
} else {
    Write-Host "  Bluetooth registry path not found, skipping." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host "  Done." -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Reboot Windows (clears any remaining Bluetooth caches)"
Write-Host "  2. Put the device into pairing mode"
Write-Host "  3. Re-pair from Settings > Bluetooth & devices"
Write-Host ""
Read-Host "Press Enter to exit"
