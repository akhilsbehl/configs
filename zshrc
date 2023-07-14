# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=100000
setopt appendhistory autocd extendedglob nomatch notify
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit

autoload -Uz bashcompinit
bashcompinit
# End of lines added by compinstall

##################
#  Misc options  #
##################

KEYTIMEOUT=1

bindkey '^r' history-incremental-search-backward

# Share history between terminals. Seriously, already.
setopt share_history

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

# Let's you suspend a half-finished command and come back to it.
bindkey '^o' push-input

# vi-backward-delete-char is just really weird
bindkey -v '^?' backward-delete-char

# do not hang my terminal
stty -ixon

###################
# Command Aliases #
###################

function exists_command {
  command -v "$1" > /dev/null
}

function get_first_available {
  local first
  for candidate in "$@"; do
    exists_command "$candidate" && first="$candidate"
    (test "$first" && echo "$first") && break
  done
}

function cdl {
    if [[ -n "$1" ]]; then
        cd "$1" || return 1
        ls --color=auto -shHF --group-directories-first
    else
        echo "Error: no directory specified."
        return 1
    fi
}

alias ls='ls --color=auto'

alias ll='ls -l'

alias lsg='ls -shHF --group-directories-first'

alias lsm='ls -shHFltr'

alias lsa='lsg -A'

alias tmux='tmux -2'

alias locate='locate -e'

alias free='free -mt'

alias cp='cp -r'

alias df='df -h'

alias grep='grep --color=auto'

alias rmd='rm -rv'

alias rmfn='rm -rvf > /dev/null'

alias dus='du -sh'

alias zip='zip -r1v'

alias untar='tar -xvzf'

alias mktar='tar -cvzf'

alias now='date +%Y-%m-%d-%H-%M'

alias today='date +%Y-%m-%d'

alias mkdir='mkdir -v'

alias pdflatex='pdflatex -interaction=nonstopmode'

alias wget='wget -c --directory-prefix="$HOME"/tmp'

alias gping='ping -c 3 www.google.com'

alias swap='setxkbmap -option caps:swapescape'

alias unswap='setxkbmap -option'

alias b='cd -'

alias logout='cinnamon-session-quit'

alias lock='cinnamon-screensaver-command --lock'

alias tpoff='synclient TouchpadOff=1'

alias tpon='synclient TouchpadOff=0'

alias netlog='sudo journalctl -f -u NetworkManager'

alias resolv='echo "nameserver 8.8.4.4\nnameserver 8.8.8.8" | sudo tee /etc/resolv.conf'

alias susp='sudo systemctl suspend && lock'

alias freeze='sudo systemctl hibernate && lock'

alias die='sudo systemctl poweroff'

alias respawn='sudo systemctl reboot'

alias csay='cowsay -f milk -W 79 $(fortune)'

alias remux='tmux source-file ~/configs/tmux.conf'

alias rez='. ~/.zshrc'

OS=$(grep -w NAME /etc/os-release | cut -f 2 -d '=' | tr -d '"')
if [[ "$OS" == "Ubuntu" ]]; then
  alias upgrade='sudo apt-get update && sudo apt-get upgrade'
  alias autorm='sudo apt-get autoremove'
elif [[ "$OS" == "Arch Linux" ]]; then
  alias upgrade='paru -Syu --noconfirm'
  alias autorm='sudo pacman -Rns $(pacman -Qqdt)'
else
  alias upgrade='echo Unknown OS!'
  alias autorm='echo Unknown OS!'
fi

if exists_command bat; then
  alias less='bat --paging always'
  alias page='bat --paging always'
fi

#########################
# Variables and Exports #
#########################

export PATH="$HOME/scripts:$HOME/.local/bin:$PATH"

export SVN_EDITOR='nvim'

# Less is more!
export READNULLCMD='less'

if [ -n "$DISPLAY" ]
then
  BROWSER=chromium
  EDITOR=nvim
else
  BROWSER=elinks
  EDITOR=nvim
fi

eval $(dircolors ~/.dircolors)

################
# File Aliases #
################

alias bashrc='$EDITOR "$HOME"/.bashrc'

alias zshrc='$EDITOR "$HOME"/configs/zshrc'

alias vimrc='$EDITOR "$HOME"/configs/vimrc'

alias vrc='$EDITOR -O "$HOME"/configs/init.lua "$HOME"/configs/init.vim'

alias gvimrc='$EDITOR "$HOME"/configs/gvimrc'

alias fstab='sudo $EDITOR /etc/fstab'

alias show='gio open'

####################
#  Global aliases  #
####################

export GREPPER=$(get_first_available rg grep)

alias -g g="| $GREPPER"

alias -g G="| $GREPPER -i"

alias -g l='| less'

alias -g v='nvim'

alias -g V='| vim -'

alias -g w='| wc -l'

alias -g n='>! /dev/null'

alias -g N='&>! /dev/null &'

alias -g hd='| head'

alias -g tl='| tail'

#############
#  Modules  #
#############

# Remove the conflicting aliases
unalias \t &> /dev/null
unalias \T &> /dev/null

source $HOME/configs/zshmodules/opp.zsh/opp.zsh
source $HOME/configs/zshmodules/opp.zsh/opp/*

source $HOME/configs/zshmodules/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Source this one last
source $HOME/configs/zshmodules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#############################
#  Redirect to a temp file  #
#############################

# Keep these after modules being loaded

alias -g t='> ./tmp-$(date +%y%m%d-%H%M%S)'

alias -g T='| tee -a ./tmp-$(date +%y%m%d-%H%M%S)'

#############################
#  up n to go up n folders  #
#############################

function up() {
  local n
  n=$1
  [[ -z "$n" ]] && n=1
  repeat $n ..
}

###############
#  Bookmarks  #
###############

alias aa='cd "$HOME"/audio'
alias vv='cd "$HOME"/video'
alias tt='cd "$HOME"/tmp'
alias cc='cd "$HOME"/configs'
alias ww='cd "$HOME"/warchives'

#####################
#  Aliases for Git  #
#####################

local GIT_ALIASES=$(git config -l | grep alias | cut -c 7- | cut -f 1 -d '=' | tr '\r\n' ' ')
for al in ${(z)GIT_ALIASES}; do
  alias g$al="git $al"
done

#########
#  FZF  #
#########

# Setup fzf
if [[ ! "$PATH" =~ "$HOME/configs/fzf/bin" ]]; then
  export PATH="$PATH:$HOME/configs/fzf/bin"
fi

# Man path
if [[ ! "$MANPATH" =~ "$HOME/configs/fzf/man" && \
    -d "$HOME/configs/fzf/man" ]]; then
  export MANPATH="$MANPATH:$HOME/configs/fzf/man"
fi

# Auto-completion
[[ $- =~ i ]] && source "$HOME/configs/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
source "$HOME/configs/fzf/shell/key-bindings.zsh"

GREP_IGNORE_PATHS='-e "/\.git/" -e "/\.virtualenv/" -e "__pycache__"'
RG_IGNORE_PATHS="-g '!.git/*' -g '!.virtualenv/*' -g '!__pycache__'"

if [[ $(get_first_available rg grep) == "rg" ]]; then
  FZF_IGNORE_PATHS=$RG_IGNORE_PATHS
  export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow '
elif [[ $(get_first_available rg ag grep) == "grep" ]]; then
  FZF_IGNORE_PATHS=$RG_IGNORE_PATHS
  export FZF_DEFAULT_COMMAND='find . -type f | grep -v '
fi

FZF_DEFAULT_COMMAND+=$FZF_IGNORE_PATHS
export FZF_DEFAULT_COMMAND
export FZF_DEFAULT_OPTS='--exact --extended --cycle --reverse --multi --no-mouse --prompt="?: " --preview "[[ -f {} ]] && [[ $(file -b --mime-type {} | cut -f 1 -d '/') == "text" ]] && bat --color=always {} | head -30"'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND

FZF_ALT_C_COMMAND='find . -type d -not -empty | grep -v '
FZF_ALT_C_COMMAND+=$GREP_IGNORE_PATHS
export FZF_ALT_C_COMMAND
export FZF_ALT_C_OPTS=$FZF_DEFAULT_OPTS

export FZF_TMUX_HEIGHT='20%'
export FZF_COMPLETION_TRIGGER=';;'
export FZF_COMPLETION_OPTS='--extended --cycle --reverse --no-mouse --multi'

function fzbin {
  local orig_dir=$PWD
  local file
  if [[ -z "$1" ]]; then
    echo 'I need at least a program to start with.'
  elif [[ -z "$2" ]]; then
    file=$(fzf-tmux -1 --exit-0 | tr '\n' ' ')
  elif [[ -f "$2" ]]; then
    file="$2"
  elif [[ -d "$2" ]]; then
    cd "$2"
    file=$(fzf-tmux --query="$3" -1 --exit-0 | tr '\n' ' ')
  else
    echo "$2 is not a file or directory."
    return 0
  fi
  [[ -n "$file" ]] && echo "$1" "$file"
  [[ -n "$file" ]] && eval "$1 $file"
  cd "$orig_dir"
}

# Simplify this
function vif { fzbin "nvim -O" "$1" }

# This is possibly running on:
# Some flavor of WSL: Use wslopen
# Some flavor of Cygwin: Use start
# Some flavor of Linux: Use xdg-open
function open { fzbin $(get_first_available wslopen start xdg-open) "$@" }

function fzp {
  local mode prefix search_cmd search_args install_cmd install_args
  mode="$1"
  prefix=""
  install_cmd=$(get_first_available pacman apt-get)
  if [[ "$install_cmd" == "pacman" ]]; then
    search_cmd="$install_cmd"
    if [[ "$mode" == "install" ]]; then
      search_args="-Slq"
      install_args="-S --needed"
    elif [[ "$mode" == "uninstall" ]]; then
      search_args="-Qq"
      install_args="-Rns"
    fi
  elif [[ "$install_cmd" == "apt-get" ]]; then
    if [[ "$mode" == "install" ]]; then
      search_cmd="apt-cache"
      search_args="pkgnames"
      install_args="install"
    elif [[ "$mode" == "uninstall" ]]; then
      search_cmd="dpkg-query"
      search_args="-W | cut -f 1"
      install_args="remove"
    fi
  fi
  pkgs=$(eval "$search_cmd $search_args" | fzf-tmux --query="$2" | tr '\n' ' ')
  if [[ -n "$pkgs" ]]; then
    exists_command sudo && prefix="sudo"
    echo "$prefix $install_cmd $install_args $pkgs"
    eval "$prefix $install_cmd $install_args $pkgs"
  fi
}

function install { fzp "install" "$@" }
function uninstall { fzp "uninstall" "$@" }

function gloc {
  local file handler
  file=$(plocate -r '.*' | fzf-tmux --query="$1" --select-1 --exit-0)
  handler=$(get_first_available wslopen start xdg-open)
  [[ -n "$file" ]] && echo "$handler" "$file"
  [[ -n "$file" ]] && "$handler" "$file"
}

#############
# SSH Agent #
#############

export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.$HOST.sock"
ssh-add -l &>/dev/null
if [ $? -ge 2 ]; then
  ssh-agent -a "$SSH_AUTH_SOCK" &>/dev/null
  find "$HOME"/.ssh -type f -name '*.pem' -exec ssh-add -k {} \; &> /dev/null
  find "$HOME"/.ssh -type f -name 'id_rsa*' -exec ssh-add {} \; &> /dev/null
fi

########################
# Do something forever #
########################

function forever {
    echo 'This will loop the command forever.'
    echo 'You will need to kill the shell to exit.'
    echo '<Enter> now to proceed. <Ctrl-C> to interrupt.'
    read
    while true; do
        "$@"
    done
}

####################
#  Pandoc aliases  #
####################

function md2x {
    [[ $# -ne 2 ]] && echo "Usage: md2x <input> <output-extension>" && return 1
    [[ ! -r "$1" ]] && echo "Cannot read $1" && return 2
    if [[ ! exists_command ]]; then
        echo "pandoc not found."
        return 3
    fi
    pandoc "$1" -o "$(basename $1 $(getext $1)).$2"
    return $?
}

######################
# Start tmux session #
######################

function launchpad-tmux {
  test $TMUX ||
    tmux attach-session -t launchPad ||
    tmux new-session -s launchPad
}

function launchpad-zellij {
  zellij list-sessions | grep -q "launchPad" && zellij attach launchPad
}

function launchpad {
    exists_command tmux && launchpad-tmux && return 0
    exists_command zellij && launchpad-zellij && return 0
    return 1
}

launchpad

#######################
#  Set up the prompt  #
#######################

[[ "$OS" == "Ubuntu" ]] && fpath+=($HOME/.zprompt/pure)
autoload -U promptinit
promptinit
prompt pure
export RPROMPT='%F{magenta}%D{%L:%M:%S}'

####################################
#  Source stuff local to each box  #
####################################

[[ -f ~/.zshrc.wsl ]] && source ~/.zshrc.wsl
[[ -f ~/.zshrc.docker ]] && source ~/.zshrc.docker
[[ -f ~/.zshrc.more ]] && source ~/.zshrc.more
