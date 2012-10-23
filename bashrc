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

alias locite='locate -ie'

alias free='free -mt'

alias mv='mv -v'

alias cp='cp -rv'

alias df='df -h'

alias rm='rm -v'

alias grep='grep --color=auto'

alias grip='grep -i'

alias rmd='rm -rv'

alias eject='eject -rv'

alias wcl='wmctrl -c'

alias wls='wmctrl -l | grip -w 0 | cut -f 5- -d " "'

alias du='du -h'

alias zip='zip -r1v'

alias shutd='sudo shutdown -hP 0'

alias reboot='sudo shutdown -r 0'

alias upgrade='packer -Syu --noconfirm --noedit'

alias apt-upgrade='sudo apt-get update && sudo apt-get upgrade'

alias now='date +%d%m%y-%H%M%S'

alias today='date +%d%m%y'

alias mkdir='mkdir -v'

alias pdflatex='pdflatex -interaction=nonstopmode'

alias wget='wget -c --directory-prefix="$HOME"/tmp'

alias gping='ping -c 3 www.google.com'

alias sbcl='rlwrap sbcl'

alias logout='gnome-session-quit --logout'

alias swap='setxkbmap -option caps:swapescape'

alias unswap='setxkbmap -option'

alias idle='idle & sleep 1s && redevil'

alias fire='firefox -P default &> /dev/null &'

alias fox='firefox -P private -no-remote &> /dev/null &'

alias blank='xset dpms force off'

alias clean-dhcpcd-lease='sudo rm /var/lib/dhcpcd/dhcpcd-*.lease /run/dhcpcd-*.pid'

alias redevil='killall -9 devilspie && devilspie -a &> /dev/null &'

alias standby='ssh -Y akhil@192.9.10.230'

alias dataman='ssh -Y dataman@192.9.10.230'

alias back='cdl -'

alias record-desktop='ffmpeg -f x11grab -s wxga -r 25 -i :0.0 -sameq /tmp/out.mpg'

alias new='/usr/bin/gnome-terminal && exit'

alias reset-ifs="export IFS=$' \t\n'"

alias line-ifs="export IFS=$'\n'"

alias test-ifs='echo -n "$IFS" | od -abc'

alias ig-svn='svn propset svn:ingore -F ./.svnignore .'

#########################
# Variables and Exports #
#########################

LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:*.wma=00;36:'

export LS_COLORS

export TERM="screen-256color"

export PATH="~/.gem/ruby/1.9.1/bin:~/scripts:$PATH"

export GREP_COLOR='1;31'

export PS1='\[\e[34;1m\]\D{%H:%M:%S} | \w | \u@\H $ \[\e[30;0m\]'

export OIFS=$IFS

export HISTCONTROL="ignoredups"

if [ -n "$DISPLAY" ]
then
  BROWSER=firefox
  EDITOR=gvim
else
  BROWSER=lynx
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

alias rc='sudo $EDITOR + /etc/rc.conf &'

alias paclog='sudo $EDITOR + /var/log/pacman.log &'

alias grub='sudo $EDITOR /etc/default/grub &'

alias cbash='cat "$HOME"/.bashrc'

alias quotes='$EDITOR + "$HOME"/tmp/perm/quotes.txt'

alias wipwd='cat "$HOME"/tmp/perm/wireless-passwords.txt'

###########
# Retired #
###########

#export http_proxy='http://192.9.10.3:3128/'
#export https_proxy='http://192.9.10.3:3128/'

#alias mp='mplayer -idx -fs'

#alias dvd='mplayer -idx -fs -stop-xscreensaver -nocache -alang en'

#alias all-music='mp -shuffle $(find "$HOME"/music/* -type f)'

#alias remove-accessibility-icon='gvim +/STANDARD_TRAY_ICON_ORDER /usr/share/gnome-shell/js/ui/panel.js'

#sed -i '/title_vertical_pad/s|value="[0-9]\{1,2\}"|value="0"|g' /usr/share/themes/Adwaita/metacity-1/metacity-theme-3.xml
