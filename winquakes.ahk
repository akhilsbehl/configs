#Requires AutoHotkey v2.0

!Enter:: {
    If WinExist("ahk_exe warp.exe") {
        WinActivate
    } else {
        If WinExist("ahk_exe WindowsTerminal.exe") {
            WinActivate
        } else {
            Run "C:\Users\akhil.behl\AppData\Local\Microsoft\WindowsApps\wt.exe"
                ;; Run "C:\Users\akhil.behl\AppData\Local\Programs\Warp\warp.exe"
        }
    }
}

<#Enter::
{
    If WinExist("ahk_exe ms-teams.exe") {
        WinActivate
    } else {
        Run "C:\Users\akhil.behl\AppData\Local\Microsoft\WindowsApps\ms-teams.exe"
    }
}

#+Enter:: {
    If WinExist("Gemini ahk_exe chrome.exe") {
        WinActivate
    } else {
        Run '"C:\Program Files (x86)\Microsoft\Edge\Application\msedge_proxy.exe" --profile-directory="Profile 1" --app-id=lbneikkiodgjddaaeedphegfkehhpnjg --app-url=https://gemini.google.com/u/1/app --app-run-on-os-login-mode=windowed --app-launch-source=19'
    }
}


!+Enter:: {
    If WinExist("ahk_exe msedge.exe") {
        WinActivate
    } else {
        Run "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    }
}
