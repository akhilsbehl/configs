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

KEYTIMEOUT=10

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

#####################
#  Emacs utilities  #
#####################

alias se='emacs --daemon'

alias ke='emacsclient --eval "(kill-emacs)"'

alias re='emacsclient --eval "(kill-emacs)" && emacs --daemon'

function e () {
  local tmp=$(emacsclient -n -e "(if (> (length (frame-list)) 1) 't)")
  if [[ "$tmp" == "nil" ]]; then
    emacsclient -nc "$@"
  else
    emacsclient -n "$@"
  fi
}

###################
# Command Aliases #
###################

alias ls='ls --color=auto'

alias ll='ls -l'

alias lsg='ls -shHF --group-directories-first'

alias lsm='ls -shHFltr'

alias lsa='lsg -A'

alias tmux='tmux -2'

alias launchpad='tmux new-session -s launchPad -n push-the-tempo'

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

OS=$(grep -w NAME /etc/os-release | cut -f 2 -d '=' | tr -d '"')
if [[ "$OS" == "Ubuntu" ]]; then
  alias upgrade='sudo apt-get update && sudo apt-get upgrade'
elif [[ "$OS" == "Arch Linux" ]]; then
  alias upgrade='packer -Syu --noconfirm --noedit'
else
  alias upgrade='echo Unknown OS!'
fi

#########################
# Variables and Exports #
#########################

export GEM_HOME="$HOME/.gem"

export PATH="$HOME/scripts:$HOME/git/packer:$PATH"

export SVN_EDITOR='vim'

# Less is more!
export READNULLCMD='less'

if [ -n "$DISPLAY" ]
then
  BROWSER=google-chrome-stable
  EDITOR=vim
else
  BROWSER=elinks
  EDITOR=vim
fi

eval $(dircolors ~/.dircolors)

################
# File Aliases #
################

alias bashrc='$EDITOR "$HOME"/.bashrc'

alias zshrc='$EDITOR "$HOME"/.zshrc'

alias vimrc='$EDITOR "$HOME"/.vimrc'

alias gvimrc='$EDITOR "$HOME"/.gvimrc'

alias fstab='sudo $EDITOR /etc/fstab'

alias show='gio open'

####################
#  Global aliases  #
####################

alias -g g='| rg'

alias -g G='| rg -i'

alias -g l='| less'

alias -g v='| vim -'

alias -g w='| wc -l'

alias -g n='>! /dev/null'

alias -g N='&>! /dev/null &'

alias -g hd='| head'

alias -g tl='| tail'

##############
#  Dirstack  #
##############

DIRSTACKFILE="$HOME/.cache/zsh/dirs"

if [[ -f $DIRSTACKFILE ]] && [[ $#dirstack -eq 0 ]]; then
  dirstack=( ${(f)"$(< $DIRSTACKFILE)"} )
  [[ -d $dirstack[1] ]] && cd $dirstack[1]
fi

chpwd() {
  print -l $PWD ${(u)dirstack} >! $DIRSTACKFILE
}

DIRSTACKSIZE=20
setopt autopushd pushdsilent pushdtohome
# Remove duplicate entries
setopt pushdignoredups
# This reverts the +/- operators.
setopt pushdminus

#############
#  Modules  #
#############

source $HOME/configs/zshmodules/opp.zsh/opp.zsh
source $HOME/configs/zshmodules/opp.zsh/opp/*

source $HOME/configs/zshmodules/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Source this one last
source $HOME/configs/zshmodules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#############################
#  up n to go up n folders  #
#############################

function up() {
  local n
  n=$1
  [[ -z "$n" ]] && n=1
  repeat $n ..
}

#############################
#  Redirect to a temp file  #
#############################

# Keep this at the end.

alias -g t='> ./tmp-$(date +%y%m%d-%H%M%S)'

alias -g T='| tee -a ./tmp-$(date +%y%m%d-%H%M%S)'

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
  alias gg$al="git $al"
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

export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'
export FZF_CTRL_T_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'
export FZF_ALT_C_COMMAND='find . -type d -not -empty | grep -v "/\.git/"'
export FZF_DEFAULT_OPTS='--extended --cycle --reverse --multi --no-mouse --prompt="?: "'
export FZF_TMUX_HEIGHT='20%'
export FZF_COMPLETION_TRIGGER=';;'
export FZF_COMPLETION_OPTS='--extended --cycle --reverse --no-mouse --multi --no-mouse'

function get_first_available() {
  local first
  for candidate in "$@"; do
    command -v "$candidate" > /dev/null && first="$candidate"
    (test "$first" && echo "$first") && break
  done
}

function fzbin () {
  local file
  if [[ -f "$2" ]]; then
    eval "$1 $2"
  elif [[ -d "$2" ]]; then
    file=$(print -r -l -- $2/**/*(.D:q) | \
      fzf-tmux --query="$3" --select-1 --exit-0)
  else
    echo 'I need a dir to start in.'
  fi
  [[ -n "$file" ]] && echo "$1" "$file"
  [[ -n "$file" ]] && eval "$1 $file"
}

function vif () { fzbin "vim" "$@" }

# This is possibly running on:
# Some flavor of WSL: Use wslopen
# Some flavor of Cygwin: Use start
# Some flavor of Linux: Use xdg-open
function open () { fzbin $(get_first_available wslopen start xdg-open) "$@" }

function fzp () {
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
    command -v sudo > /dev/null && prefix="sudo"
    echo "$prefix $install_cmd $install_args $pkgs"
    eval "$prefix $install_cmd $install_args $pkgs"
  fi
}

function install () { fzp "install" "$@" }
function uninstall () { fzp "uninstall" "$@" }

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

function forever() {
    echo 'This will loop the command forever.'
    echo 'You will need to kill the shell to exit.'
    echo '<Enter> now to proceed. <Ctrl-C> to interrupt.'
    read
    while true; do
        "$@"
    done
}

####################################
#  Source stuff local to each box  #
####################################

[[ -f ~/.zshrc.more ]] && source ~/.zshrc.more

###################
# Fortune cookies #
###################

cowsay -f milk -W 79 $(fortune)
