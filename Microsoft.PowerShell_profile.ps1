. C:\ProgramData\Anaconda3\shell\condabin\conda-hook.ps1
conda activate 'C:\ProgramData\Anaconda3'
New-Alias -Name less -Value more
Set-Alias -Name zip -Value Compress-Archive
Set-Alias -Name unzip -Value Expand-Archive

function Ipython-Vim () {
  ipython.exe --TerminalInteractiveShell.editing_mode=vi
}
New-Alias -Name ipy -Value Ipython-Vim
