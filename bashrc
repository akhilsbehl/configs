# If not an interactive shell, just give up.
[[ -z "$PS1" ]] && exit 0

OS=$(grep -w NAME /etc/os-release | cut -f 2 -d '=' | tr -d '"')

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

bashclean() {
    local tmpdir="$(mktemp -d)"
    local tmprc="$(mktemp)"
    cat > "$tmprc" << EOF
PS1='\$ '
cd "$tmpdir"
EOF
    env - HOME="$HOME" TERM="$TERM" bash --noprofile --rcfile "$tmprc"
    rm -r "$tmpdir" "$tmprc"
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

alias dus='du -sh'

alias zip='zip -r1v'

if [[ "$OS" == "Ubuntu" ]];
then
  alias upgrade='sudo apt-get update && sudo apt-get upgrade'
else
  alias upgrade='packer -Syu --noconfirm --noedit'
fi

alias now='date +%d%m%y-%H%M%S'

alias today='date +%d%m%y'

alias mkdir='mkdir -v'

alias pdflatex='pdflatex -interaction=nonstopmode'

alias wget='wget -c --directory-prefix="$HOME"/tmp'

alias gping='ping -c 3 www.google.com'

alias swap='setxkbmap -option caps:swapescape'

alias unswap='setxkbmap -option'

alias back='cdl -'

alias record-desktop='ffmpeg -f x11grab -s wxga -r 25 -i :0.0 -sameq /tmp/out.mpg'

alias new='/usr/bin/gnome-terminal && exit'

alias logout='gnome-session-quit'

alias lock='gnome-screensaver-command --lock'

if [[ "$OS" == "Ubuntu" ]];
then
  alias susp='sudo pm-suspend && lock'
else
  alias susp='sudo systemctl suspend && lock'
fi

alias shutd='sudo shutdown -h 0'

alias reboot='sudo shutdown -r 0'

alias tpoff='synclient TouchpadOff=1'

alias tpon='synclient TouchpadOff=0'

alias t='cdl "$HOME"/tmp'

if [[ "$OS" != "Ubuntu" ]];
then
  alias n='cdl /run/media/akhilsbehl/Nebucchadnezzar'
  alias s='cdl /run/media/akhilsbehl/Snapper'
else
  alias mfm24='sudo mount.cifs //192.168.18.24/aig ~/winshare/falmum24 \
    -o username=akhil.behl,password=SteelBank\(1,uid=1000,gid=1000'
  alias fm24='cdl "$HOME"/winshare/falmum24'
fi

alias m='cdl "$HOME"/music'

alias c='cdl "$HOME"/git/configs'

################
# File Aliases #
################

alias bashrc='$EDITOR "$HOME"/.bashrc &'

alias vimrc='$EDITOR "$HOME"/.vimrc &'

alias gvimrc='$EDITOR "$HOME"/.gvimrc &'

alias fstab='sudo $EDITOR /etc/fstab &'
