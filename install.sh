#!/bin/bash
# clone dotfiles repo and then run me

set -e # -e: exit on error

# check for required dependencies
MISSING_DEPS=()
if ! command -v curl &> /dev/null; then
	MISSING_DEPS+=("curl")
fi
if ! command -v git &> /dev/null; then
	MISSING_DEPS+=("git")
fi

# handle missing dependencies
if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
	echo "Missing required dependencies: ${MISSING_DEPS[*]}"
	
	if [[ -t 0 ]]; then
		# Interactive mode
		read -e -p "Should the script attempt to install missing dependencies? [y/N]: " YN
		if [[ $YN != "y" && $YN != "Y" ]]; then
			echo "Please install the missing dependencies and run the script again."
			exit 1
		fi
	else
		# Non-interactive mode - exit if dependencies missing
		echo "Non-interactive mode: Please install missing dependencies (${MISSING_DEPS[*]}) and run again."
		exit 1
	fi
	
	# install missing dependencies
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then
		if [ "$(command -v apt)" ]; then
			(apt update && apt install -y build-essential procps curl file git) || (sudo apt update && sudo apt install -y build-essential procps curl file git)
		elif [ "$(command -v dnf)" ]; then
			(dnf install -y procps-ng curl file git) || (sudo dnf install -y procps-ng curl file git)
		elif [ "$(command -v yum)" ]; then
			(yum install -y procps-ng curl file git) || (sudo yum install -y procps-ng curl file git)
		else
			echo "ERROR: Unsupported package manager" 1>&2
			exit 1
		fi
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		echo "On macOS, please install Xcode Command Line Tools: xcode-select --install"
		exit 1
	else
		echo "ERROR: Unsupported operating system" 1>&2
		exit 1
	fi
fi

# set up user
if [[ -t 0 ]]; then
	# Interactive mode
	read -e -p "What username do you want to use?: " USERNAME
else
	# Non-interactive mode - use current user
	USERNAME=$(whoami)
	echo "Non-interactive mode: using current user $USERNAME"
fi

if [ ! `id -u $USERNAME` ]  # determine in username exists
then
	echo "Username doesn't exist. Let's create it."
	useradd $USERNAME
	if [[ -t 0 ]]; then
		echo "Make password for $USERNAME: "
		passwd $USERNAME
	else
		echo "Non-interactive mode: skipping password setup for $USERNAME"
	fi
	USERHOMEDIR="$( eval echo ~$USERNAME )"
	mkdir -p $USERHOMEDIR
	chown -R $USERNAME $USERHOMEDIR
	usermod -aG sudo $USERNAME
else
	echo "Username exists. Setting it to be used for this script."
	USERHOMEDIR="$( eval echo ~$USERNAME )"
fi

# setup git
if [[ -t 0 ]]; then
	# Interactive mode
	read -e -p "Do you want to setup your git author? [y/N]: " YN
	if [[ $YN == "y" || $YN == "Y" ]]
	then
		read -e -p "git name: " -i "Jaron Lundwall" GITNAME
		read -e -p "git email: " -i "13423952+jaron-l@users.noreply.github.com" GITEMAIL
		if [[ $(whoami) == $USERNAME ]]
		then
			git config --global user.name $GITNAME
			git config --global user.email $GITEMAIL
		else
			su -l $USERNAME -c "git config --global user.name \"$GITNAME\""
			su -l $USERNAME -c "git config --global user.email \"$GITEMAIL\""
		fi
	fi
else
	# Non-interactive mode - use defaults
	echo "Non-interactive mode: setting up git with default author"
	GITNAME="Jaron Lundwall"
	GITEMAIL="13423952+jaron-l@users.noreply.github.com"
	if [[ $(whoami) == $USERNAME ]]
	then
		git config --global user.name "$GITNAME"
		git config --global user.email "$GITEMAIL"
	else
		su -l $USERNAME -c "git config --global user.name \"$GITNAME\""
		su -l $USERNAME -c "git config --global user.email \"$GITEMAIL\""
	fi
fi

# ask about brew and package installation
INSTALL_BREW=false
if [[ -t 0 ]]; then
	# Interactive mode
	read -e -p "Should the script install brew and default packages? [y/N]: " YN
	if [[ $YN == "y" || $YN == "Y" ]]; then
		INSTALL_BREW=true
	fi
else
	# Non-interactive mode - skip brew installation
	echo "Non-interactive mode: skipping brew installation"
fi

if [ "$INSTALL_BREW" = true ]; then
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
	if [[ $(whoami) == $USERNAME ]]
	then
		$chezmoi init --apply https://github.com/jaron-l/dotfiles.git
		mkdir -p $USERHOMEDIR/.oh-my-zsh/custom/plugins/chezmoi && $chezmoi completion zsh > $USERHOMEDIR/.oh-my-zsh/custom/plugins/chezmoi/_chezmoi

		# set chezmoi author
		$chezmoi git config -- user.name "Jaron Lundwall"
		$chezmoi git config -- user.email "13423952+jaron-l@users.noreply.github.com"
	else
		su -l $USERNAME -c "$chezmoi init --apply https://github.com/jaron-l/dotfiles.git"
		su -l $USERNAME -c "mkdir -p $USERHOMEDIR/.oh-my-zsh/custom/plugins/chezmoi && $chezmoi completion zsh > $USERHOMEDIR/.oh-my-zsh/custom/plugins/chezmoi/_chezmoi"

		# set chezmoi author
		su -l $USERNAME -c "$chezmoi git config -- user.name \"Jaron Lundwall\""
		su -l $USERNAME -c "$chezmoi git config -- user.email \"13423952+jaron-l@users.noreply.github.com\""
	fi
else
	# install chezmoi directly and init
	GITHUB_USERNAME="jaron-l"
	if [[ $(whoami) == $USERNAME ]]
	then
		sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
	else
		su -l $USERNAME -c "sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- init --apply $GITHUB_USERNAME"
	fi
fi

