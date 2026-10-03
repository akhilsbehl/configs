This runbook configures **Alt + Enter** as a global Windows hotkey that launches Ghostty in Ubuntu under WSLg when closed and immediately restores and focuses the existing window when open.

The working design uses one hidden PowerShell process started at Windows sign-in. It registers the hotkey once and then sleeps until Windows delivers a hotkey event. This avoids PowerToys application tracking, per-press PowerShell startup, intermediary console windows, and repeated runtime compilation.

## Resulting architecture

- **Trigger:** Alt + Enter

- **Window title:** Quake (Ubuntu)

- **Launch target:** C:\Program Files\WSL\wslg.exe

- **Linux application:** /usr/bin/ghostty

- **Distribution:** Ubuntu

- **Lifecycle:** One hidden PowerShell listener started by Task Scheduler

- **PowerToys:** Not involved in this shortcut

## Prerequisites

- WSL 2 with Ubuntu and WSLg installed

- Ghostty available at `/usr/bin/ghostty`

- Windows PowerShell 5.1

- Permission to create a per-user scheduled task

- No other application currently registering Alt + Enter globally

## Configure Ghostty

Inside Ubuntu, edit:

```text
~/.config/ghostty/config.ghostty
```

Ensure it contains:

```ini
title = Quake
gtk-single-instance = true
```

WSLg appends the distribution name to the projected Windows title, producing:

```text
Quake (Ubuntu)
```

Restart Ghostty after changing the configuration.

## Create the listener

Create:

```text
C:\Users\akhil.behl\QuakeHotkeyListener.ps1
```

Use the following complete script:

```powershell
$ErrorActionPreference = 'Stop'

Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

public static class QuakeHotkey
{
    public delegate bool EnumWindowsProc(
        IntPtr hWnd,
        IntPtr lParam
    );

    private const int WM_HOTKEY = 0x0312;

    private const uint MOD_ALT = 0x0001;
    private const uint MOD_NOREPEAT = 0x4000;
    private const uint VK_RETURN = 0x0D;

    private const int HOTKEY_ID = 0x5155;
    private const int SW_RESTORE = 9;

    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MSG
    {
        public IntPtr hwnd;
        public uint message;
        public UIntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public POINT pt;
        public uint lPrivate;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(
        IntPtr hWnd,
        int id,
        uint modifiers,
        uint virtualKey
    );

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(
        IntPtr hWnd,
        int id
    );

    [DllImport("user32.dll")]
    private static extern int GetMessage(
        out MSG message,
        IntPtr hWnd,
        uint minimumFilter,
        uint maximumFilter
    );

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(
        EnumWindowsProc callback,
        IntPtr parameter
    );

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(
        IntPtr hWnd,
        StringBuilder text,
        int count
    );

    [DllImport("user32.dll")]
    private static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(
        IntPtr hWnd,
        out uint processId
    );

    [DllImport("user32.dll")]
    private static extern bool ShowWindowAsync(
        IntPtr hWnd,
        int command
    );

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    public static void Register()
    {
        bool registered = RegisterHotKey(
            IntPtr.Zero,
            HOTKEY_ID,
            MOD_ALT | MOD_NOREPEAT,
            VK_RETURN
        );

        if (!registered)
        {
            int error = Marshal.GetLastWin32Error();

            throw new InvalidOperationException(
                "Could not register Alt+Enter. Win32 error: " + error
            );
        }
    }

    public static void Unregister()
    {
        UnregisterHotKey(IntPtr.Zero, HOTKEY_ID);
    }

    public static void WaitForActivation()
    {
        MSG message;

        while (GetMessage(
            out message,
            IntPtr.Zero,
            WM_HOTKEY,
            WM_HOTKEY
        ) > 0)
        {
            if (
                message.message == WM_HOTKEY &&
                message.wParam.ToUInt32() == HOTKEY_ID
            )
            {
                return;
            }
        }
    }

    public static IntPtr FindWindow(string requiredTitle)
    {
        IntPtr match = IntPtr.Zero;

        EnumWindows(delegate(IntPtr hWnd, IntPtr unused)
        {
            if (!IsWindowVisible(hWnd))
                return true;

            int length = GetWindowTextLength(hWnd);

            if (length == 0)
                return true;

            StringBuilder title = new StringBuilder(length + 1);

            GetWindowText(
                hWnd,
                title,
                title.Capacity
            );

            // Suffix matching deliberately tolerates WSLg prefixes such as
            // "[WARN: COPY MODE] " without launching duplicate windows.
            if (!title.ToString().EndsWith(
                requiredTitle,
                StringComparison.Ordinal
            ))
            {
                return true;
            }

            uint processId;

            GetWindowThreadProcessId(
                hWnd,
                out processId
            );

            try
            {
                Process process =
                    Process.GetProcessById((int)processId);

                if (!String.Equals(
                    process.ProcessName,
                    "msrdc",
                    StringComparison.OrdinalIgnoreCase
                ))
                {
                    return true;
                }
            }
            catch
            {
                return true;
            }

            match = hWnd;
            return false;
        }, IntPtr.Zero);

        return match;
    }

    public static void Activate(IntPtr hWnd)
    {
        if (IsIconic(hWnd))
            ShowWindowAsync(hWnd, SW_RESTORE);

        SetForegroundWindow(hWnd);
    }
}
'@

[QuakeHotkey]::Register()

try {
    while ($true) {
        [QuakeHotkey]::WaitForActivation()

        $window = [QuakeHotkey]::FindWindow(
            'Quake (Ubuntu)'
        )

        if ($window -ne [IntPtr]::Zero) {
            [QuakeHotkey]::Activate($window)
            continue
        }

        Start-Process `
            -FilePath 'C:\Program Files\WSL\wslg.exe' `
            -ArgumentList '-d Ubuntu --cd "~" -- /usr/bin/ghostty'
    }
}
finally {
    [QuakeHotkey]::Unregister()
}
```

The suffix match is intentional. WSLg may temporarily prefix a title with text such as `[WARN: COPY MODE]`. Exact-title matching would then fail and launch duplicates.

The `msrdc.exe` ownership check ensures that a native Windows application ending in the same title is not activated accidentally.

## Test interactively

First disable any PowerToys mapping for Alt + Enter.

Open Windows PowerShell and run:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Users\akhil.behl\QuakeHotkeyListener.ps1"
```

Verify all three cases:

1. With Ghostty closed, Alt + Enter launches it.

2. With Ghostty behind another application, Alt + Enter focuses it.

3. With Ghostty minimized, Alt + Enter restores and focuses it.

Stop the interactive test with Ctrl + C before creating or starting the scheduled task. Only one listener should run.

## Start the listener at sign-in

Open **Task Scheduler** and select **Create Task**, not Create Basic Task.

### General

- **Name:** QuakeHotkeyListener

- Select **Run only when user is logged on**

- Enable **Hidden**

- Do not select **Run with highest privileges** unless Ghostty must interact with elevated windows

### Triggers

Create one trigger:

- **Begin the task:** At log on

- **Specific user:** your Windows account

- **Enabled:** Yes

### Actions

Create one action:

- **Action:** Start a program

- **Program/script:**

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

- **Add arguments:**

```text
-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\akhil.behl\QuakeHotkeyListener.ps1"
```

- **Start in:**

```text
C:\Users\akhil.behl
```

### Conditions and Settings

- Disable any idle-only requirement.

- Disable **Stop the task if it runs longer than**.

- Set **If the task is already running** to **Do not start a new instance**.

Save the task, right-click it, and select **Run**.

## Validate the scheduled configuration

In Task Manager, one hidden `powershell.exe` process should correspond to the listener.

Test launch, focus, and restore again. Then sign out and back in once to verify that the listener starts automatically.

If Alt + Enter does nothing, check Task Scheduler history and run the script interactively. An error saying the hotkey could not be registered means another application or another listener instance already owns Alt + Enter.

## WSLg copy mode recovery

`[WARN: COPY MODE]` is a WSLg transport warning, not a Ghostty mode. It indicates that WSLg has fallen back from its shared-memory graphics path to copying pixels through the RDP channel, which can make GUI applications slow.

Close WSL applications and run:

```powershell
wsl --shutdown
wsl --update
```

Then launch Ghostty again. If the warning persists, inspect Ubuntu with:

```bash
findmnt /mnt/shared_memory

grep -Ei \
'shared_memory|copy.mode|vail|rail|error|fail' \
/mnt/wslg/weston.log |
tail -100
```

The title-suffix logic prevents the warning prefix from causing duplicate Ghostty launches, but it does not repair the underlying WSLg transport problem.

Relevant Microsoft WSLg references:

- [https://github.com/microsoft/wslg/discussions/312](https://github.com/microsoft/wslg/discussions/312)

- [https://github.com/microsoft/wslg/issues/972](https://github.com/microsoft/wslg/issues/972)

## Final files and settings to retain

Keep only:

- `C:\Users\akhil.behl\QuakeHotkeyListener.ps1`

- Task Scheduler task `QuakeHotkeyListener`

- Ghostty configuration containing `title = Quake`

- Ghostty configuration containing `gtk-single-instance = true`

- The standard WSLg-generated Start-menu shortcut, if otherwise useful

## Remap the zellij clipboard to clip.exe

In ~/configs/zellij-conf.kdl, remove copy_clipboard "primary" and replace with:

```
// Send selected text directly to the Windows clipboard.
copy_command "/mnt/c/Windows/System32/clip.exe"

// Automatically copy when the mouse selection is released.
copy_on_select true
```
