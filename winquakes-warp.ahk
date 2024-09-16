#Requires AutoHotkey v2.0

!+Enter:: {
    If WinExist("ahk_exe msedge.exe") {
        ; WinMaximize
        WinActivate
    } else {
        Run "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    }
}

!Enter:: {
    ;If WinExist("ahk_exe WindowsTerminal.exe") {
    If WinExist("ahk_exe msrdc.exe") {
        ; WinMaximize
        WinActivate
    } else {
        ;Run "C:\Users\akhil.behl\AppData\Local\Microsoft\WindowsApps\wt.exe"
        Run "C:\Windows\system32\bash.exe -c 'WARP_ENABLE_WAYLAND=1 MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA warp-terminal'"
    }
}

<#Enter:: {
    If WinExist("ahk_exe ms-teams.exe") {
        ; WinMaximize
        WinActivate
    } else {
        Run "C:\Users\akhil.behl\AppData\Local\Microsoft\WindowsApps\ms-teams.exe"
    }
}