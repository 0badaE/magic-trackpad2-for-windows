<#
.SYNOPSIS
    Enables one-finger click-and-drag for the Apple Magic Trackpad 2 on Windows
    when using the MagicTrackpad2ForWindows driver (vitoplantamura/MagicTrackpad2ForWindows).

.DESCRIPTION
    The driver ships with IgnoreButtonFinger = 1, which freezes the finger that presses
    the click. Clicking works, but that finger cannot move the cursor, so you cannot
    select text or drag windows.

    The driver has two halves that each read their own copy of this setting:
      - Bluetooth (kernel HID filter): HKLM\SYSTEM\CurrentControlSet\Services\AmtPtpHidFilter\Parameters
      - USB cable (user-mode driver):  HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF\Services\AmtPtpDeviceUsbUm\Parameters

    Fixing only one is why drag can work over Bluetooth and break as soon as you plug the
    trackpad in to charge (or the other way round). This script sets both.

.PARAMETER Undo
    Restores the driver default (IgnoreButtonFinger = 1) in both places.

.EXAMPLE
    .\Fix-TrackpadDrag.ps1
.EXAMPLE
    .\Fix-TrackpadDrag.ps1 -Undo
#>
[CmdletBinding()]
param(
    [switch]$Undo
)

$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'This script needs administrator rights.' -ForegroundColor Red
    Write-Host 'Right-click Start > "Terminal (Admin)", then run it again.'
    exit 1
}

if (-not (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\AmtPtpHidFilter')) {
    Write-Host 'Warning: the MagicTrackpad2ForWindows Bluetooth filter (AmtPtpHidFilter) does not appear to be installed.' -ForegroundColor Yellow
    Write-Host 'The settings will still be written, but they only take effect with that driver.'
}

$value = if ($Undo) { 1 } else { 0 }

$keys = @(
    @{ Name = 'Bluetooth'; Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\AmtPtpHidFilter\Parameters' },
    @{ Name = 'USB cable'; Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF\Services\AmtPtpDeviceUsbUm\Parameters' }
)

foreach ($k in $keys) {
    if (-not (Test-Path $k.Path)) { New-Item -Path $k.Path -Force | Out-Null }
    New-ItemProperty -Path $k.Path -Name IgnoreButtonFinger -PropertyType DWord -Value $value -Force | Out-Null
    $now = (Get-ItemProperty -Path $k.Path).IgnoreButtonFinger
    Write-Host ("{0,-10} IgnoreButtonFinger = {1}" -f $k.Name, $now) -ForegroundColor Green
}

Write-Host ''
if ($Undo) {
    Write-Host 'Restored the driver default (cursor freezes while clicking).'
} else {
    Write-Host 'Done. One-finger click-and-drag is enabled.'
}
Write-Host 'To apply it: unplug and replug the cable, and/or turn the trackpad off and on (or reboot).'
