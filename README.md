# Bluetooth Device Reset

A small Windows tool that fully removes a paired Bluetooth device — Win32 API, Plug-and-Play, and registry — so it can be re-paired from scratch. Useful when a Bluetooth speaker or headset gets stuck and Windows refuses to reconnect even after you "Remove device" from Settings.

## Download

1. Go to the [latest release](https://github.com/CloudCraftPro/bluetooth-device-reset/releases/latest)
2. Download **`BluetoothReset.zip`**
3. Right-click the zip → **Extract All…** → pick any folder (Desktop is fine)
4. Open the extracted folder

## Run

1. Double-click **`BluetoothReset.bat`**
2. Windows will pop up "Do you want to allow this app to make changes?" — click **Yes**. Admin access is needed because the registry cleanup writes to `HKLM\SYSTEM`.
3. If Windows SmartScreen says "Windows protected your PC":
   - Click **More info**
   - Click **Run anyway**
4. A list of your paired Bluetooth devices will appear. Type the **number** of the one you want to reset and press **Enter**.
5. When the script finishes:
   - **Reboot Windows** (clears any leftover Bluetooth caches)
   - Put the device into pairing mode
   - Re-pair it from **Settings → Bluetooth & devices**

## What it actually does

For the device you select, in order:

1. **Win32 API call** — `BluetoothRemoveDevice` from `bthprops.cpl`, using the address parsed out of the device's HardwareID
2. **PnP removal** — `Disable-PnpDevice` then `Remove-PnpDevice` for every instance of that device
3. **Registry cleanup** — deletes the matching entry under `HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Devices`

Most "Bluetooth won't re-pair" issues are caused by stale state in step 3 that the normal "Remove device" UI doesn't touch.

## Requirements

- Windows 10 or 11
- An account with admin rights (or the password to one — UAC handles the rest)

## License

MIT
