#Requires AutoHotkey v2.0

!+Enter:: {
    If WinExist("ahk_exe firefox.exe") {
        WinActivate
    } else {
        Run "C:\Program Files\Mozilla Firefox\firefox.exe"
    }
}

!Enter:: {
    If WinExist("ahk_exe WindowsTerminal.exe") {
        WinActivate
    } else {
        Run "C:\Users\akhil\AppData\Local\Microsoft\WindowsApps\wt.exe"
    }
}
