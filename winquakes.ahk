#Requires AutoHotkey v2.0

!+Enter:: {
    If WinExist("ahk_exe msedge.exe") {
        WinActivate
    } else {
        Run "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    }
}

!Enter:: {
    If WinExist("ahk_exe WindowsTerminal.exe") {
        WinActivate
    } else {
        Run "C:\Users\akhil.behl\AppData\Local\Microsoft\WindowsApps\wt.exe"
    }
}

<#Enter:: {
    If WinExist("ahk_exe Teams.exe") {
        WinActivate
    } else {
        Run "C:\Users\akhil.behl\AppData\Local\Microsoft\Teams\Update.exe --processStart 'Teams.exe'"
    }
}
