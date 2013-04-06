# If not an interactive shell, just give up.
if [[ -z "$PS1" ]];then 
  exit
else
  export PS1='\[\e[29;1m\]\D{%H:%M:%S} | \w | \u@\H $ \[\e[30;0m\]'
fi

#############
# Functions #
#############

function cdl () {
  if [[ $# -eq 0 ]]
  then
    builtin cd "$HOME" && ls -shHF --group-directories-first --color=auto;
  else
    builtin cd "$1" && ls -shHF --group-directories-first --color=auto;
  fi
}

function upsvn () {
  (
    cdl ~/svn
    for d in *; do
      svn update "$d"
    done
  )
}

###################
# Command Aliases #
###################

alias up='cdl ..'

alias ls='ls --color=auto'

alias lsg='ls -shHF --group-directories-first'

alias lst='ls -shHtF'

alias lsm='ls -shHFltr'

alias lsa='lsg -A'

alias cd..='cd ..'

alias locate='locate -e'

alias free='free -mt'

alias cp='cp -r'

alias df='df -h'

alias grep='grep --color=auto'

alias rmd='rm -rv'

alias du='du -sh'

alias zip='zip -r1v'

alias upgrade='packer -Syu --noconfirm --noedit'

alias apt-upgrade='sudo apt-get update && sudo apt-get upgrade'

alias now='date +%d%m%y-%H%M%S'

alias today='date +%d%m%y'

alias mkdir='mkdir -v'

alias pdflatex='pdflatex -interaction=nonstopmode'

alias wget='wget -c --directory-prefix="$HOME"/tmp'

alias gping='ping -c 3 www.google.com'

alias sbcl='rlwrap sbcl'

alias swap='setxkbmap -option caps:swapescape'

alias unswap='setxkbmap -option'

alias ak230='ssh -Y akhil@192.9.10.230'

alias ak231='ssh -Y akhil@192.9.10.231'

alias ak232='ssh -Y akhil@192.9.10.232'

alias dman230='ssh -Y dataman@192.9.10.230'

alias dman231='ssh -Y dataman@192.9.10.231'

alias dman232='ssh -Y dataman@192.9.10.232'

alias german='ssh -Y akhil@78.46.69.107'

alias back='cdl -'

alias record-desktop='ffmpeg -f x11grab -s wxga -r 25 -i :0.0 -sameq /tmp/out.mpg'

alias new='/usr/bin/gnome-terminal && exit'

alias logout='gnome-session-quit'

alias lock='gnome-screensaver-command --lock'

alias susp='sudo systemctl suspend && lock'

alias shutd='sudo systemctl poweroff'

alias reboot='sudo systemctl reboot'

alias tpoff='synclient TouchpadOff=1'

alias tpon='synclient TouchpadOff=0'

alias t='cdl "$HOME"/tmp'

alias n='cdl /run/media/akhilsbehl/Nebucchadnezzar'

alias m='cdl "$HOME"/music'

alias s='cdl /run/media/akhilsbehl/Snapper'

alias c='cdl "$HOME"/git/configs'

alias igimov='sudo mount.cifs //192.9.10.10/movie /mnt -o username=fsrr,password=20igi13frgdr,uid=1000,gid=100 && cdl /mnt'

#########################
# Variables and Exports #
#########################

LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:*.wma=00;36:'

export LS_COLORS

export TERM="xterm"

export PATH="$HOME/scripts:$PATH"

export GREP_COLOR='1;31'

export OIFS=$IFS

export HISTCONTROL="ignoredups"

if [ -n "$DISPLAY" ]
then
  BROWSER=firefox
  EDITOR=gvim
else
  BROWSER=elinks
  EDITOR=vim
fi

force_color_prompt=yes

################
# File Aliases #
################

alias bashrc='$EDITOR "$HOME"/.bashrc &'

alias vimrc='$EDITOR "$HOME"/.vimrc &'

alias gvimrc='$EDITOR "$HOME"/.gvimrc &'

alias fstab='sudo $EDITOR /etc/fstab &'

alias paclog='sudo $EDITOR + /var/log/pacman.log &'
