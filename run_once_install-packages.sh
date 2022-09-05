#!/bin/bash
sudo apt-get update
if [ ! "$(command -v curl)"; ]
then
	sudo apt-get install -y curl
fi
curl -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.deb -o /tmp/nvim-linux64.deb
sudo apt-get install -y zsh libglib2.0-dev git tmux /tmp/nvim-linux64.deb
sudo chsh -s $(which zsh) $USER
