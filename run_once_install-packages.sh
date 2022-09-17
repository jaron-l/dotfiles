#!/bin/bash
# assumes that install.sh script in this repo was run

# install piu
curl https://raw.githubusercontent.com/keithieopia/piu/master/piu -o piu && chmod +x piu && sudo mv piu /usr/local/bin
# install what can be through piu
piu install -y zsh git tmux
# set default shell
sudo chsh -s $(which zsh) $USER
# install debian specific packages if using apt
if [[ "$(command -v apt)" ]]; then
	curl -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.deb -o /tmp/nvim-linux64.deb
	sudo apt install -y /tmp/nvim-linux64.deb libglib2.0-dev 
else
	piu install -y neovim
fi
# try to install thefuck package (may not work on all systems)
piu install -y thefuck
