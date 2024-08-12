#!/bin/bash

GIT_DIRTY_FILES=$(git status --porcelain | wc -l)
if [[ $GIT_DIRTY_FILES -gt 0 ]]; then
  echo "Git repo is dirty. Please commit or stash changes before updating."
  exit 1
fi

sudo echo 'Cache sudo credentials'

OS=$(cat /etc/os-release | grep ^ID= | cut -d '=' -f 2)
echo "Running on $OS"

git submodule update --init

update () {
  rm -rf "$HOME/.$1"
  ln -s "$PWD/$1" "$HOME/.$1"
}

mk-dir-if-not-found () {
  [[ ! -d "$1" ]] &&
    mkdir -p "$1"
}

update zshrc
update inputrc
update gvimrc
update vimrc
update tmux.conf
update gitignore
update gitconfig
update R
update Rprofile
update dircolors

rm -rf $HOME/scripts
ln -s $PWD/scripts $HOME/scripts

[[ -f $HOME/.config/user-dirs.dirs ]] && rm $HOME/.config/user-dirs.dirs
ln -s $PWD/xdg-dirs $HOME/.config/user-dirs.dirs
xdg-user-dirs-update
echo "Remove any old XDG dirs manually if they exist."

mk-dir-if-not-found $HOME/.config/nvim
[[ -f $HOME/.config/nvim/init.lua ]] && rm $HOME/.config/nvim/init.lua
ln -s $PWD/init.lua $HOME/.config/nvim/
[[ -f $HOME/.config/nvim/vimrc ]] && rm $HOME/.config/nvim/vimrc
ln -s $PWD/init.vim $HOME/.config/nvim/vimrc

mk-dir-if-not-found $HOME/.ssh
sudo chown -R $USER:$USER $HOME/.ssh
[[ -f $HOME/.ssh/config ]] && mv $HOME/.ssh/config{,.bkup}
unlink $HOME/.ssh/config 2> /dev/null
ln -s $PWD/ssh-config $HOME/.ssh/config
chmod 700 $HOME/.ssh
chmod 400 $HOME/.ssh/*
[[ -f $HOME/.ssh/known_hosts ]] && chmod 600 $HOME/.ssh/known_hosts

mk-dir-if-not-found $HOME/.cache/zsh

mk-dir-if-not-found $HOME/.rstat/lib

mk-dir-if-not-found $HOME/.ipython/profile_default
[[ -f $HOME/.ipython/profile_default/ipython_config.py ]] &&
  mv $HOME/.ipython/profile_default/ipython_config.py{,.bkup}
unlink $HOME/.ipython/profile_default/ipython_config.py 2> /dev/null
ln -s $PWD/ipython_config.py $HOME/.ipython/profile_default/ipython_config.py

# Assuming the submodule is populated
fzf/uninstall
fzf/install
rm $HOME/.fzf.{ba,z}sh
git checkout .

rm -rf $HOME/.tmux/plugins/tpm
git clone 'https://github.com/tmux-plugins/tpm' $HOME/.tmux/plugins/tpm

if [[ "$OS" == "ubuntu" ]]; then
  rm -rf $HOME/.zprompt/pure
  git clone 'https://github.com/sindresorhus/pure.git' $HOME/.zprompt/pure
fi

if [[ "$OS" == "arch" ]]; then
  if [[ "$(command -v paru)" ]]; then
    paru -S --needed zsh-pure-prompt-git
  else
    echo "paru not found. Install paru first and then zsh-pure-prompt-git"
  fi
fi

sudo pacman -Syyu
sudo pacman -S --needed \
	bat \
	cowsay \
	dos2unix \
	fd \
	fortune-mod \
	plocate \
	mplayer \
	mupdf \
	python \
	python-pip \
	r \
	ripgrep \
	tree \
	ttf-cascadia-code \
	ttf-fira-code \
	unzip \
	gvim \
	python-virtualenv
