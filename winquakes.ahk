#Requires AutoHotkey v2.0

!+Enter:: {
    If WinExist("ahk_exe msedge.exe") || WinExist("ahk_class Chrome_WidgetWin_1") {
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
    If WinExist("ahk_exe ms-teams.exe") || WinExist("ahk_class TeamsWebView") {
        WinActivate
    } else {
        Run "EXPLORER.EXE shell:AppsFolder\MSTeams_8wekyb3d8bbwe!MSTeams"
    }
}
