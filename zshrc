#######################
# COMPINIT AUTO SETUP #
#######################

zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit
compinit
autoload -Uz bashcompinit
bashcompinit

##################
#  Misc options  #
##################

# Shut up
unsetopt beep

# do not hang my terminal
stty -ixon

# Set vim keybindings
bindkey -v
KEYTIMEOUT=1 # React fast to my Esc key
bindkey '^o' push-input # suspend a half-finished command to come back to it.
bindkey -v '^?' backward-delete-char # vi-backward-delete-char is really weird
bindkey '^r' history-incremental-search-backward # Fallback behavior

# History settings
HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=100000
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt histignoredups
setopt histignorealldups
setopt histsavenodups
setopt histfindnodups

# Spell correct
setopt correct

# Do not clobber with >. Use >! for clobbering.
setopt noclobber

# Allow comments in the shell.
setopt interactivecomments

# Let hidden files (.*) be matched against globs. And fancier globbing.
setopt globdots extendedglob nomatch

# Send me a notification if possible
setopt notify

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

function cpf() {
    copier=$(get_first_available wl-copy xclip clip.exe)
    [[ -n "$copier" ]] && "$copier" < "$1"
}

function enact() {
    local -a ENVSEARCH=(
        "$(git rev-parse --show-toplevel 2> /dev/null)"
        "$PWD"
        "$HOME"
    )

    for envroot in "${ENVSEARCH[@]}"; do
        [[ -n "$envroot" ]] || continue
        if [[ -d "$envroot/.virtualenv" ]]; then
            echo "Found $envroot/.virtualenv"
            local act="$envroot/.virtualenv/bin/activate"
            if [[ -f "$act" ]]; then
                source "$act"
                if [[ $? -eq 0 ]]; then
                    echo "Activated .virtualenv at $envroot."
                    return 0
                else
                    echo "Could not activate this .virtualenv. Moving on"
                fi
            fi
        fi
    done
    echo "No usable virtualenv found. Giving up." && return 1
}

if exists_command lsd; then
    alias ls='lsd'
    alias ll='lsd -l'
    alias lsg='lsd'
    alias lsa='lsd -a'
    alias lla='lsd -la'
    alias lst='lsd -t'
    alias lss='lsd -S'
    alias lsx='lsd -X'
    alias lsv='lsd -v'
    alias tree='lsd --tree'
else
    alias ls='ls --color=auto'
    alias ll='ls -l'
    alias lsg='ls -shHF --group-directories-first' # Inconsistent alias
    alias lst='ls -shHFltr'
    alias lss='ls -SshHF --group-directories-first'
    alias lsa='lsg -A'
fi

function cdl {
    if [[ -n "$1" ]]; then
        cd "$1" || return 1
        lsg
    else
        cd "$HOME" || return 1
        lsg
    fi
}

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

alias shfmt='shfmt -s -i 2 -ci -sr'

alias pdflatex='pdflatex -interaction=nonstopmode'

alias wget='wget -c --directory-prefix="$HOME"/tmp'

alias gping='ping -c 3 www.google.com'

alias swap='setxkbmap -option caps:swapescape'

alias unswap='setxkbmap -option'

alias b='cd -'

alias logout='gnome-session-quit'

alias tpoff='synclient TouchpadOff=1'

alias tpon='synclient TouchpadOff=0'

alias netlog='sudo journalctl -f -u NetworkManager'

alias resolv='echo "nameserver 8.8.4.4\nnameserver 8.8.8.8" | sudo tee /etc/resolv.conf'

alias susp='sudo systemctl suspend'

alias freeze='sudo systemctl hibernate'

alias die='sudo systemctl poweroff'

alias respawn='sudo systemctl reboot'

alias csay='cowsay -f milk -W 79 $(fortune)'

alias remux='tmux source-file ~/configs/tmux.conf'

alias rez='. ~/.zshrc'

alias sc='sudo systemctl'

alias sj='sudo journalctl'

alias wch='watch -n 1 '

OS=$(grep -w NAME /etc/os-release | cut -f 2 -d '=' | tr -d '"')

if exists_command bat; then
  alias less='bat --paging always'
  alias page='bat --paging always'
fi

if [[ "$OS" == "Ubuntu" ]]; then
  alias upgrade='sudo apt-get update && sudo apt-get upgrade'
  alias autorm='sudo apt-get autoremove'
elif [[ "$OS" == "Arch Linux" ]]; then
  alias upgrade='yay -Syu --noconfirm'
  alias autorm='sudo pacman -Rns $(pacman -Qqdt)'
  alias explicit-packages='(yay -Qqent; yay -Qqemt) | less'
else
  alias upgrade='echo Unknown OS!'
  alias autorm='echo Unknown OS!'
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

if exists_command vivid; then
  export LS_COLORS=$(vivid generate ayu)
else
  eval $(dircolors ~/.dircolors)
fi

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

alias -g v='$EDITOR'

alias -g V='| $EDITOR -'

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

alias -g tea='> ./tmp-$(date +%y%m%d-%H%M%S)'

alias -g Tea='| tee -a ./tmp-$(date +%y%m%d-%H%M%S)'

#############################
#  up n to go up n folders  #
#############################

function up() {
  local ndirs
  ndirs=$1
  [[ -z "$ndirs" ]] && ndirs=1
  repeat $ndirs { cd .. }
}

###############
#  Bookmarks  #
###############

alias aa='cd "$HOME"/audio'
alias vv='cd "$HOME"/video'
alias ii='cd "$HOME"/images'
alias tt='cd "$HOME"/tmp'
alias cc='cd "$HOME"/configs'
alias ww='cd "$HOME"/warchives'
alias zz='cd "$HOME"/zettelkasten'

#####################
#  Aliases for Git  #
#####################

local GIT_ALIASES=$(git config -l | grep alias | cut -c 7- | cut -f 1 -d '=' | tr '\r\n' ' ')
for al in ${(z)GIT_ALIASES}; do
  alias g$al="git $al"
done

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

######################
#  Simple converters #
######################

function md2x {
    [[ $# -ne 2 ]] && echo "Usage: md2x <input> <output-extension>" && return 1
    [[ ! -r "$1" ]] && echo "Cannot read $1" && return 2
    if ! exists_command pandoc; then
        echo "pandoc not found."
        return 3
    fi
    pandoc "$1" -o "$(basename $1 $(getext $1)).$2"
    return $?
}

# Image conversion using magick

function img2x {
    [[ $# -ne 2 ]] && echo "Usage: img2x <input> <output-ext>" && return 1
    [[ ! -r "$1" ]] && echo "Cannot read $1" && return 2
    if ! exists_command magick; then
        echo "magick not found."
        return 3
    fi
    magick "$1" "$(basename $1 $(getext $1)).$2"
    return $?
}

function vid2mp3 {
    [[ $# -ne 1 ]] && echo "Usage: vid2mp3 <input>" && return 1
    [[ ! -r "$1" ]] && echo "Cannot read $1" && return 2
    if ! exists_command ffmpeg; then
        echo "ffmpeg not found."
        return 3
    fi
    ffmpeg -i "$1" -ab 192k -ar 44100 -ac 2 "$(basename $1 $(getext $1)).mp3"
    return $?
}

function compress-pdf {
    [[ $# -ne 1 ]] && echo "Usage: compress-pdf <input>" && return 1
    [[ ! -r "$1" ]] && echo "Cannot read $1" && return 2
    if ! exists_command gs; then
        echo "gs not found."
        return 3
    fi
    /usr/bin/gs \
        -sDEVICE=pdfwrite \
        -dCompatibilityLevel=1.5 \
        -dPDFSETTINGS=/ebook \
        -dNOPAUSE \
        -dQUIET \
        -dBATCH \
        -sOutputFile="$(basename $1 $(getext $1))"-compressed.pdf "$1"
    return $?
}

################################
#  Colorschemes & backgrounds  #
################################

function list-colorschemes-wt {
    jq '.schemes | .[] | .name' $WIN_TERM_SETTINGS | sed -e 's/"//g'
}

function list-colorschemes-gnome-terminal {
    local profile
    for profile in $(dconf list /org/gnome/terminal/legacy/profiles:/); do
        dconf read /org/gnome/terminal/legacy/profiles:/"$profile"visible-name
    done
}

function wt-or-gt {
    if [[ -n "$WIN_TERM_SETTINGS" ]]; then
        "$1" "${@:3}"
    elif exists_command gnome-terminal; then
        "$2" "${@:3}"
    else
        echo "Unknown terminal emulator."
    fi
}

function apply-colorscheme-wt {
    local TMPF
    TMPF="$(mktemp)"
    jq --arg cs "$1" '.profiles.defaults.colorScheme = $cs' $WIN_TERM_SETTINGS >! $TMPF
    mv $TMPF $WIN_TERM_SETTINGS
}

function apply-colorscheme-gnome-terminal {
    local profile pname changed
    for profile in $(dconf list /org/gnome/terminal/legacy/profiles:/); do
        pname=$(dconf read /org/gnome/terminal/legacy/profiles:/"$profile"visible-name)
        if [[ "$pname" == "'$1'" ]]; then
            profile=$(echo "'$profile'" | tr -d '[:/]')
            dconf write /org/gnome/terminal/legacy/profiles:/default "$profile" && changed=1
            echo "Gnome Terminal can not change colorschemes mid-session."
            echo "Please restart your terminal for the change to take effect."
            break
        fi
    done
    if [[ "$changed" != "1" ]]; then
        echo "$1 was not found as an available Gnome Terminal colorscheme."
    fi
}

function list-colorschemes {
    wt-or-gt list-colorschemes-wt list-colorschemes-gnome-terminal | sort -u
}

function apply-colorscheme {
    [[ -z "$1" ]] && echo "Usage: apply-colorscheme <colorscheme>" && return 1
    wt-or-gt apply-colorscheme-wt apply-colorscheme-gnome-terminal "$1"
}

function randomize-colorscheme {
    local schemes line scheme randi
    schemes=()
    while IFS= read -r line; do
        schemes+=("$line")
    done < <(list-colorschemes)
    randi=$(od -An -N1 -i /dev/urandom | tr -d ' ')
    randi=$((randi % ${#schemes[@]}))
    scheme="${schemes[$randi]}"
    echo "Selected colorscheme: $scheme"
    apply-colorscheme "$(echo $scheme | tr -d "'")"
}

######################
# Ollama Convenience #
######################

function zllama () {
    local subcmds="list run stop show rm pull update version"
    local subcmd=$(echo "$subcmds" | tr ' ' '\n' | fzf)
    if [[ "$subcmd" == "list" ]]; then
        ollama list
        return 0
    fi
    if [[ "$subcmd" == "pull" ]]; then
        zllama-pull
        return 0
    fi
    if [[ "$subcmd" == "update" ]]; then
        local url=https://raw.githubusercontent.com/ollama/
        url+=ollama/refs/heads/main/scripts/install.sh
        curl -fsSL $url | sh
        return 0
    fi
    if [[ "$subcmd" == "version" ]]; then
        ollama --version
        return 0
    fi
    local choice=$(ollama list | fzf | awk '{print $1}')
    echo ollama "$subcmd" "$choice"
    ollama "$subcmd" "$choice"
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
  test $ZELLIJ ||
    zellij attach launchPad || zellij
}

function launchpad {
    exists_command zellij && launchpad-zellij && return 0
    exists_command tmux && launchpad-tmux && return 0
    return 1
}

#######################
#  Set up the prompt  #
#######################

# Keep some vertical padding around the prompt
preexec() {
    echo
}

if [[ "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select" || \
      "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select-wrapped" ]]; then
    zle -N zle-keymap-select "";
fi
eval "$(starship init zsh)"

####################################
#  Source stuff local to each box  #
####################################

[[ -f ~/.zshrc.fzf ]] && source ~/.zshrc.fzf
[[ -f ~/.zshrc.wsl ]] && source ~/.zshrc.wsl
[[ -f ~/.zshrc.docker ]] && source ~/.zshrc.docker
[[ -f ~/.zshrc.more ]] && source ~/.zshrc.more
