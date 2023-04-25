#!/bin/bash
# clone dotfiles repo and then run me

set -e # -e: exit on error

# install system dependencies
# curl is needed to grab chezmoi and brew
# build tools are for brew
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	if [ "$(command -v apt)" ]; then
		apt update && apt install -y build-essential procps curl file git
	elif [ "$(command -v dnf)" ]; then
		dnf install -y procps-ng curl file git
	elif [ "$(command -v yum)" ]; then
		yum groupinstall 'Development Tools'
		yum install -y procps-ng curl file git
	else
		echo "ERROR: Unsupported package manager" 1>&2
		exit 1
	fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
	:
else
	echo "ERROR: Unsupported operating system" 1>&2
	exit 1
fi

# set up user
read -e -p "What username do you want to use?: " USERNAME
if [ ! `id -u $USERNAME` ]  # determine in username exists
then
	echo "Username doesn't exist. Let's create it."
	useradd $USERNAME
	echo "Make password for $USERNAME: "
	passwd $USERNAME
	USERHOMEDIR="$( eval echo ~$USERNAME )"
	mkdir -p $USERHOMEDIR
	chown -R $USERNAME $USERHOMEDIR
	usermod -aG sudo $USERNAME
else
	echo "Username exists. Setting it to be used for this script."
	USERHOMEDIR="$( eval echo ~$USERNAME )"
fi

# setup git
read -e -p "Do you want to setup your git author? [y/N]: " YN
if [[ $YN == "y" || $YN == "Y" ]]
then
	read -e -p "git name: " -i "Jaron Lundwall" GITNAME
	read -e -p "git email: " -i "13423952+jaron-l@users.noreply.github.com" GITEMAIL
	su -l $USERNAME -c "git config --global user.name \"$GITNAME\""
	su -l $USERNAME -c "git config --global user.email \"$GITEMAIL\""
fi

# install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# add brew to path
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
	test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
brew install zsh tmux neovim thefuck fzf chezmoi

# init chezmoi
chezmoi=$(brew --prefix)/bin/chezmoi
su -l $USERNAME -c "$chezmoi init --apply https://github.com/jaron-l/dotfiles.git"
su -l $USERNAME -c "mkdir -p $USERHOMEDIR/.oh-my-zsh/custom/plugins/chezmoi && $chezmoi completion zsh > $USERHOMEDIR/.oh-my-zsh/custom/plugins/chezmoi/_chezmoi"

# set chezmoi author
su -l $USERNAME -c "$chezmoi git config -- user.name \"Jaron Lundwall\""
su -l $USERNAME -c "$chezmoi git config -- user.email \"13423952+jaron-l@users.noreply.github.com\""

