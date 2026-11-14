# Bluetooth Device Reset

A small Windows tool that fully removes a paired Bluetooth device — Win32 API, Plug-and-Play, and registry — so it can be re-paired from scratch. Useful when a Bluetooth speaker or headset gets stuck and Windows refuses to reconnect even after you "Remove device" from Settings.

## Why this exists

A client's Windows PC kept losing its Bluetooth connection to a Monster speaker every few days. The usual fix — "Remove device" from **Settings → Bluetooth & devices**, then re-pair — didn't stick: Windows would either fail to reconnect or pair the speaker in a half-broken state where audio wouldn't route to it.

The root cause was stale state in three different places that Windows' UI doesn't fully clean:

1. The kernel's internal Bluetooth handle (cleared only by the Win32 `BluetoothRemoveDevice` API)
2. The Plug-and-Play device records
3. The pairing entry in `HKLM:\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Devices`

Removing all three is what finally produces a clean re-pair. This tool is a packaged version of the script I was running manually for the client — now they (and anyone else with the same problem) can run it themselves with a double-click.

## Download

1. Go to the [latest release](https://github.com/digneat/bluetooth-device-reset/releases/latest)
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

## Disclaimer / Use at Your Own Risk

This tool is provided **as-is, with no warranty or guarantee of any kind**. It modifies the Windows registry and removes paired Bluetooth devices — normally safe, but you're running unsigned code with administrator privileges, and software can always have bugs or behave unexpectedly on a specific machine configuration.

**By running this, you accept that:**

- You're doing so **at your own risk**.
- The author and contributors are **not responsible** for any data loss, system instability, lost device pairings, or other consequences.
- You should **read the source** (`BluetoothReset.ps1`) before running it if you have any concerns about what it does.
- If you're not comfortable with the above, **don't run it.**

The MIT License attached covers the legal side of this — this section is the plain-English version.

## License

MIT
