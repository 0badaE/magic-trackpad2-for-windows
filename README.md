# Apple Magic Trackpad on Windows: multi-touch and click-and-drag

A guide to getting an **Apple Magic Trackpad** working fully on Windows 11:

1. **[Multi-touch](#part-1-get-multi-touch-working)**: the pad moves the cursor and clicks,
   but two-finger scroll, pinch to zoom, two-finger right-click and 3–4 finger gestures
   don't work.
2. **[Click-and-drag](#part-2-fix-click-and-drag)**: gestures work, but you can't select
   text or move a window by pressing and dragging. Drag may also work over Bluetooth, then
   stop when you plug the pad in to charge.

## Part 1: Get multi-touch working

### The cause

On its own, Windows treats the Magic Trackpad as a basic Bluetooth mouse. You need a
third-party driver that makes it a Windows **precision touchpad**.

The widely linked driver, [imbushuo/mac-precision-touchpad](https://github.com/imbushuo/mac-precision-touchpad)
(last released in 2021), **doesn't recognize the newer USB-C Magic Trackpad**. That model
reports a new product ID, `0x0324`, instead of the Lightning model's `0x0265`. The driver
installs without any error, but Windows never attaches it to the trackpad, so nothing
changes. There are open issues about this on that project
([#548](https://github.com/imbushuo/mac-precision-touchpad/issues/548),
[#556](https://github.com/imbushuo/mac-precision-touchpad/issues/556)).

To check which model you have, run this in PowerShell:
```powershell
Get-PnpDevice -PresentOnly | Where-Object InstanceId -match 'PID&0324|PID_0324|PID&0265|PID_0265' | Select-Object FriendlyName, InstanceId
```
`0324` means the USB-C model and `0265` means the Lightning model.

### The fix

Use [**MagicTrackpad2ForWindows**](https://github.com/vitoplantamura/MagicTrackpad2ForWindows)
(vitoplantamura), which supports the USB-C model over both Bluetooth and USB, and whose
release files are Microsoft-signed.

1. **Remove the old imbushuo driver if you installed it.** Its project says to do this
   first. In **Terminal (Admin)**, list the installed drivers:
   ```powershell
   pnputil /enum-drivers | Select-String -Context 2,6 'amtptp'
   ```
   Find the `oemNN.inf` entry from the old driver (the 2021 version or date), then remove it:
   ```powershell
   pnputil /delete-driver oemNN.inf /uninstall /force
   ```
2. **Download** the latest `...-MSSigned.zip` from the
   [releases page](https://github.com/vitoplantamura/MagicTrackpad2ForWindows/releases) and unzip it.
3. Open the **AMD64** folder, right-click **`AmtPtpDevice.inf`**, and choose **Install**.
   On Windows 11 it may be under *Show more options*.
4. In **Settings → Bluetooth & devices**, remove the trackpad and pair it again, or just
   restart Windows.
5. Open **Settings → Bluetooth & devices → Touchpad**. The scroll, zoom, tap and
   three-/four-finger gesture settings should now be there.

The zip also contains `AmtPtpControlPanel.exe` for haptics and other settings. Keep it in a
normal folder if you want to use it.

## Part 2: Fix click-and-drag

### The cause

The driver has a setting called `IgnoreButtonFinger`, and it's **on by default**. While the
trackpad is pressed down, the driver ignores the finger doing the pressing, which stops the
cursor from jumping when you click. The intended style is to click with your thumb and move
with another finger, but this also blocks normal one-finger drag.

The driver also has **two halves**, and each reads its own copy of the setting:

| Connection | Driver | Registry key |
|---|---|---|
| Bluetooth | `AmtPtpHidFilter` (kernel) | `HKLM\SYSTEM\CurrentControlSet\Services\AmtPtpHidFilter\Parameters` |
| USB cable | `AmtPtpDeviceUsbUm` (user-mode) | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF\Services\AmtPtpDeviceUsbUm\Parameters` |

If only one key is set, drag works on one connection and not the other.

### The fix

1. Download `Fix-TrackpadDrag.ps1` from this repo.
2. Right-click Start, choose **Terminal (Admin)**, and click Yes.
3. Run the script (change the path to wherever you saved it):
   ```powershell
   powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\Fix-TrackpadDrag.ps1"
   ```
4. Unplug and replug the cable, and/or turn the trackpad off and on. Rebooting also works.

To undo it:
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\Fix-TrackpadDrag.ps1" -Undo
```

#### Doing it by hand

Run this in an admin PowerShell:
```powershell
foreach ($k in 'HKLM:\SYSTEM\CurrentControlSet\Services\AmtPtpHidFilter\Parameters',
               'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF\Services\AmtPtpDeviceUsbUm\Parameters') {
    New-Item -Path $k -Force | Out-Null
    New-ItemProperty -Path $k -Name IgnoreButtonFinger -PropertyType DWord -Value 0 -Force | Out-Null
}
```

If the driver's control panel app (`AmtPtpControlPanel.exe`) is installed, you can also just
uncheck **"Ignore input from the finger used to click"** there. It writes both keys. Many
driver packages don't include the app, though.

### Trade-off

With the setting off, the cursor can shift slightly at the moment you press down to click.
One user on the driver's issue tracker reported that it affected other gestures. In my
testing, scrolling, zoom and 3–4 finger gestures all kept working.

## Notes

- **After a driver update or reinstall**, the drag setting may reset. Run the script again.
- **If gestures stop after a big Windows update**, Windows may have replaced the driver.
  Reinstall it (Part 1, steps 2–4).
- This only changes driver settings. It doesn't modify, patch or re-sign the driver.
- Related upstream issues: [#48](https://github.com/vitoplantamura/MagicTrackpad2ForWindows/issues/48),
  [#45](https://github.com/vitoplantamura/MagicTrackpad2ForWindows/issues/45),
  [#27](https://github.com/vitoplantamura/MagicTrackpad2ForWindows/issues/27).
- Not affiliated with Apple or with the MagicTrackpad2ForWindows project. Use at your own risk.

## License

MIT
