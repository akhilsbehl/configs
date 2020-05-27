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

########################
#  Prompting goodness  #
########################

# Vi mode indicator
###################

PLPRMT='/usr/lib/python2.7/site-packages/powerline/bindings/zsh/powerline.zsh'

if [[ -f $PLPRMT ]]; then
  source $PLPRMT
else
  autoload -U promptinit
  promptinit
  autoload -U colors && colors

  vim_ins_mode="%B%{$fg[red]%}<<< INS%{$reset_color%}"
  vim_cmd_mode="%B%{$fg[blue]%}<<< CMD%{$reset_color%}"
  vim_mode=$vim_cmd_mode

  function zle-keymap-select {
    vim_mode="${${KEYMAP/vicmd/${vim_cmd_mode}}/(main|viins)/${vim_ins_mode}}"
    zle reset-prompt
  }
  zle -N zle-keymap-select

  function zle-line-finish {
    vim_mode=$vim_cmd_mode
  }
  zle -N zle-line-finish

  function TRAPINT() {
    vim_mode=$vim_ins_mode
    zle && zle reset-prompt
    return $(( 128 + $1 ))
  }
  prompt adam2
  RPROMPT='${vim_mode}'
fi

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

alias sleep='sudo systemctl suspend && lock'

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

alias -g g='| grep'

alias -g G='| grep -i'

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
alias gg='cd "$HOME"/git'
alias ww='cd "$HOME"/warchives'

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

export FZF_CTRL_T_COMMAND="ag -l -g ''"
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

function fz () {
  local cmd file 
  file=$(locate * | fzf-tmux --select-1 --exit-0)
  if [[ -n "$file" ]]; then
    cmd=$(compgen -abckA function | fzf-tmux --select-1 --exit-0)
    [[ -n "$cmd" ]] && "$cmd" "$file"
  fi
}

function fzs () {
  local cmd args search_dir file 
  cmd=$(get_first_available gio start)
  args=""
  [[ "$cmd" == gio ]] && args="open"
  search_dir="."
  [[ -n "$1" ]] && search_dir="$1"
  file=$(find -L "$search_dir" -type f | fzf-tmux --query="$2" --select-1 --exit-0)
  [[ -n "$file" ]] && "$cmd" "$args" "$file"
}

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

####################################
# Find the virtualenv and activate #
####################################

function penv () {
  declare -a ENVSEARCH=(
    "$(git rev-parse --show-toplevel 2> /dev/null)"
    "$PWD"
    "$HOME"
  )
  ENVSEARCH=($(echo ${ENVSEARCH[@]} | tr [:space:] '\n' | awk '!x[$0]++'))
  for envroot in "${ENVSEARCH[@]}"; do
    test -n "$envroot" || continue
    if test -d $envroot/.virtualenv; then
      echo Found $envroot/.virtualenv
      act="$envroot/.virtualenv/bin/activate"
      test -f $act && source $act
      if [[ $? -eq 0 ]]; then
        return 0
      else
        echo 'Could not activate this .virtualenv. Moving on'
      fi
    fi
  done
  echo "No usable virtualenv found. Giving up." && return 1
}

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

fortune -s
