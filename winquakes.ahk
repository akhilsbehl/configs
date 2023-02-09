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
    If WinExist("ahk_exe WindowsTerminal.exe") {
        ; WinMaximize
        WinActivate
    } else {
        Run "C:\Users\akhil.behl\AppData\Local\Microsoft\WindowsApps\wt.exe"
    }
}

<#Enter:: {
    If WinExist("ahk_exe Teams.exe") {
        ; WinMaximize
        WinActivate
    } else {
        Run "C:\Users\akhil.behl\AppData\Local\Microsoft\Teams\Update.exe --processStart 'Teams.exe'"
    }
}
