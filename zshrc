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
  prompt asb
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

alias b='cd -'

alias logout='cinnamon-session-quit'

alias lock='cinnamon-screensaver-command --lock'

alias tpoff='synclient TouchpadOff=1'

alias tpon='synclient TouchpadOff=0'

alias netlog='sudo journalctl -f -u NetworkManager'

alias record-desktop='ffmpeg -f x11grab -video_size 1920x1080 -framerate 45 -i :0.0 -c:v libx264 -qp 0 -preset ultrafast /tmp/out.mkv'

alias resolv='echo "nameserver 8.8.4.4\nnameserver 8.8.8.8" | sudo tee /etc/resolv.conf'

OS=$(grep -w NAME /etc/os-release | cut -f 2 -d '=' | tr -d '"')

if [[ "$OS" == "Ubuntu" ]];
then
  alias upgrade='sudo apt-get update && sudo apt-get upgrade'
  alias sleep='sudo pm-suspend && lock'
  alias freeze='sudo pm-hibernate && lock'
  alias die='sudo shutdown -h 0'
  alias respawn='sudo shutdown -r 0'
else
  alias upgrade='packer -Syu --noconfirm --noedit'
  alias sleep='sudo systemctl suspend && lock'
  alias freeze='sudo systemctl hibernate && lock'
  alias die='sudo systemctl poweroff'
  alias respawn='sudo systemctl reboot'
fi

#########################
# Variables and Exports #
#########################

export SHELL='/usr/bin/zsh'

export TERM='xterm'

export PATH="$HOME/scripts:$PATH"

export SVN_EDITOR='e'

# Less is more!
export READNULLCMD='less'

if [ -n "$DISPLAY" ]
then
  BROWSER=google-chrome-stable
  EDITOR=e
else
  BROWSER=elinks
  EDITOR=e
fi

eval $(dircolors ~/.dircolors)

################
# File Aliases #
################

alias bashrc='$EDITOR "$HOME"/.bashrc &'

alias zshrc='$EDITOR "$HOME"/.zshrc &'

alias vimrc='$EDITOR "$HOME"/.vimrc &'

alias gvimrc='$EDITOR "$HOME"/.gvimrc &'

alias fstab='sudo $EDITOR /etc/fstab &'

alias show='gvfs-open'

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

source $HOME/git/configs/zshmodules/opp.zsh/opp.zsh
source $HOME/git/configs/zshmodules/opp.zsh/opp/*

source $HOME/git/configs/zshmodules/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Source this one last
source $HOME/git/configs/zshmodules/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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
alias cc='cd "$HOME"/git/configs'
alias gg='cd "$HOME"/git'
alias ww='cd "$HOME"/warchives'

#########
#  FZF  #
#########

# Setup fzf
if [[ ! "$PATH" =~ "$HOME/git/configs/fzf/bin" ]]; then
  export PATH="$PATH:$HOME/git/configs/fzf/bin"
fi

# Man path
if [[ ! "$MANPATH" =~ "$HOME/git/configs/fzf/man" && \
    -d "$HOME/git/configs/fzf/man" ]]; then
  export MANPATH="$MANPATH:$HOME/git/configs/fzf/man"
fi

# Auto-completion
[[ $- =~ i ]] && source "$HOME/git/configs/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
source "$HOME/git/configs/fzf/shell/key-bindings.zsh"

export FZF_CTRL_T_COMMAND="ag -l -g ''"
export FZF_DEFAULT_OPTS='--extended --cycle --reverse --multi --no-mouse --prompt="?: "'
export FZF_TMUX_HEIGHT='20%'
export FZF_COMPLETION_TRIGGER=';;'
export FZF_COMPLETION_OPTS='--extended --cycle --reverse --no-mouse --multi --no-mouse'

function fzshow () {
  local file
  file=$(find -L ~ -type f | fzf-tmux --query="$1" --select-1 --exit-0)
  [ -n "$file" ] && gvfs-open "$file"
}

function vi () {
  local out file key
  out=$(find -L ~ -type f | fzf-tmux --query="$1" --exit-0 --expect=ctrl-g)
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [[ -n "$file" ]]; then
    [ "$key" = ctrl-g ] && gvim "$file" || vim "$file"
  fi
}

function ez () {
  local out file key
  out=$(find -L ~ -type f | fzf-tmux --query="$1" --exit-0 --expect=ctrl-g)
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [[ -n "$file" ]]; then
    [ "$key" = ctrl-g ] && e "$file" || e "$file"
  fi
}

function play () {
  local file
  file=$(find -L ~/audio ~/video -type f | \
    fzf-tmux --query="$1" --select-1 --exit-0)
  [ -n "$file" ] && mpv $(echo $file)
}

function cdf() {
  local file
  local dir
  file=$(find -L ~ -type f | fzf-tmux --query="$1") && dir=$(dirname "$file") && cd "$dir"
}

function fzf-locate-widget() {
  local selected
  if selected=$(locate / | fzf-tmux); then
    LBUFFER="$LBUFFER$selected"
  fi
  zle redisplay
}
zle -N fzf-locate-widget
bindkey '\ei' fzf-locate-widget

function install () {
  pkgs=$(pacman -Slq | fzf-tmux --query="$1")
  [ -n "$pkgs" ] && sudo pacman -S "$pkgs"
}

function uninstall () {
  pkgs=$(pacman -Qq | fzf-tmux --query="$1")
  [ -n "$pkgs" ] && sudo pacman -Rns "$pkgs"
}

#############
# SSH Agent #
#############

eval $(ssh-agent) &> /dev/null
ssh-add &> /dev/null
find "$HOME"/.ssh -type f -name '*.pem' -exec ssh-add -k {} \; &> /dev/null

####################################
# Find the virtualenv and activate #
####################################

function penv () {
  local gitroot=$(git rev-parse --show-toplevel 2> /dev/null)
  [[ -n "$gitroot" ]] && gitroot=$(find $gitroot -type d -name '.virtualenv')
  [[ -n "$gitroot" ]] && gitroot=$(find $gitroot -type f -name 'activate')
  [[ -n "$gitroot" ]] && source $gitroot
}

###################
# Fortune cookies #
###################

fortune -s
