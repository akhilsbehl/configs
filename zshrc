# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=100000
setopt appendhistory autocd extendedglob nomatch notify
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/asb/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

##################
#  Misc options  #
##################

bindkey '^r' history-incremental-search-backward

# Spell correct
setopt correct

# Do not clobber with >. Use >! for clobbering.
setopt noclobber

# Allow comments in the shell.
setopt interactivecomments

# Ignore duplicates in history.
setopt histignoredups

# Let hidden files (.*) be matched against globs.
setopt globdots

# http://unix.stackexchange.com/questions/10825/remember-a-half-typed-command-while-i-check-something
bindkey '^o' push-input

########################
#  Prompting goodness  #
########################

autoload -U promptinit
promptinit
prompt asb

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

shclean() {
    local tmpdir="$(mktemp -d)"
    local tmprc="$(mktemp)"
    cat > "$tmprc" << EOF
PS1='\$ '
cd "$tmpdir"
EOF
    env - HOME="$HOME" TERM="$TERM" zsh --noprofile --rcfile "$tmprc"
    rm -r "$tmpdir" "$tmprc"
}

###################
# Command Aliases #
###################

alias up='cdl ..'

alias ls='ls --color=auto'

alias ll='ls -l'

alias lsg='ls -shHF --group-directories-first'

alias lsm='ls -shHFltr'

alias lsa='lsg -A'

alias cd..='cd ..'

alias tmux='tmux -2'

alias launchpad='tmux new-session -s launchPad'

alias locate='locate -e'

alias free='free -mt'

alias cp='cp -r'

alias df='df -h'

alias grep='grep --color=auto'

alias rmd='rm -rv'

alias dus='du -sh'

alias zip='zip -r1v'

alias now='date +%Y-%m-%d-%H-%M'

alias today='date +%Y-%m-%d'

alias mkdir='mkdir -v'

alias pdflatex='pdflatex -interaction=nonstopmode'

alias wget='wget -c --directory-prefix="$HOME"/tmp'

alias gping='ping -c 3 www.google.com'

alias swap='setxkbmap -option caps:swapescape'

alias unswap='setxkbmap -option'

alias back='cdl -'

alias record-desktop='ffmpeg -f x11grab -s wxga -r 25 -i :0.0 -sameq /tmp/out.mpg'

alias logout='cinnamon-session-quit'

alias lock='cinnamon-screensaver-command --lock'

alias tpoff='synclient TouchpadOff=1'

alias tpon='synclient TouchpadOff=0'

alias t='cdl "$HOME"/tmp'

alias c='cdl "$HOME"/git/configs'

alias netlog='sudo journalctl -f -u NetworkManager'

alias show='gvfs-open'

OS=$(grep -w NAME /etc/os-release | cut -f 2 -d '=' | tr -d '"')

if [[ "$OS" == "Ubuntu" ]];
then
  alias upgrade='sudo apt-get update && sudo apt-get upgrade'
  alias sleep='sudo pm-suspend && lock'
  alias freeze='sudo pm-hibernate && lock'
  alias die='sudo shutdown -h 0'
  alias reboot='sudo shutdown -r 0'
else
  alias upgrade='packer -Syu --noconfirm --noedit'
  alias sleep='sudo systemctl suspend && lock'
  alias freeze='sudo systemctl hibernate && lock'
  alias die='sudo systemctl poweroff'
  alias reboot='sudo systemctl reboot'
fi

#########################
# Variables and Exports #
#########################

export SHELL='/usr/bin/zsh'

export TERM='xterm'

export PATH="$HOME/scripts:$PATH"

export SVN_EDITOR='vim'

if [ -n "$DISPLAY" ]
then
  BROWSER=firefox
  EDITOR=gvim
else
  BROWSER=elinks
  EDITOR=vim
fi

################
# File Aliases #
################

alias bashrc='$EDITOR "$HOME"/.bashrc &'

alias zshrc='$EDITOR "$HOME"/.zshrc &'

alias vimrc='$EDITOR "$HOME"/.vimrc &'

alias gvimrc='$EDITOR "$HOME"/.gvimrc &'

alias fstab='sudo $EDITOR /etc/fstab &'

####################
#  Global aliases  #
####################

alias -g g='| grep'

alias -g G='| grep -i'

alias -g l='| less'

alias -g v='| vim -'

alias -g n='> /dev/null'

####################################
#  Source stuff local to each box  #
####################################

[[ -f ~/.zshrc.more ]] && source ~/.zshrc.more

##############
#  Dirstack  #
##############

DIRSTACKFILE="$HOME/.cache/zsh/dirs"
if [[ -f $DIRSTACKFILE ]] && [[ $#dirstack -eq 0 ]]; then
  dirstack=( ${(f)"$(< $DIRSTACKFILE)"} )
  [[ -d $dirstack[1] ]] && cd $dirstack[1]
fi
chpwd() {
  print -l $PWD ${(u)dirstack} >$DIRSTACKFILE
}
DIRSTACKSIZE=9
setopt autopushd pushdsilent pushdtohome
# Remove duplicate entries
setopt pushdignoredups
# This reverts the +/- operators.
setopt pushdminus

#######################
#  Vi mode indicator  #
#######################

autoload -U colors && colors

vim_ins_mode="%B%{$fg[green]%}<<< INS%{$reset_color%}"
vim_cmd_mode="%B%{$fg[cyan]%}<<< CMD%{$reset_color%}"
vim_mode=$vim_ins_mode

function zle-keymap-select {
  vim_mode="${${KEYMAP/vicmd/${vim_cmd_mode}}/(main|viins)/${vim_ins_mode}}"
  zle reset-prompt
}
zle -N zle-keymap-select

function zle-line-finish {
  vim_mode=$vim_ins_mode
}
zle -N zle-line-finish

function TRAPINT() {
  vim_mode=$vim_ins_mode
  zle && zle reset-prompt
  return $(( 128 + $1 ))
}
RPROMPT='${vim_mode}'

#############
#  Modules  #
#############

source $HOME/git/configs/zshmodules/opp.zsh/opp.zsh
source $HOME/git/configs/zshmodules/opp.zsh/opp/*
source $HOME/git/configs/zshmodules/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
source $HOME/git/configs/zshmodules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
