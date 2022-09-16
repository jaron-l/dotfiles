#!/bin/bash
# clone dotfiles repo and then run me
# requires root privaledges and apt to run

set -e # -e: exit on error

# install dependencies
# curl is needed to grab chezmoi, piu, etc.
# sudo is needed for piu and package managers
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	if [ "$(command -v apt)" ]; then
		apt update && apt install -y sudo curl
	elif [ "$(command -v dnf)" ]; then
		dnf install -y sudo curl
	elif [ "$(command -v yum)" ]; then
		yum install -y sudo curl
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

# install chezmoi
if [ ! "$(command -v chezmoi)" ]; then
  if [ ! "$(command -v snap)" ]; then
	  bin_dir="$USERHOMEDIR/.local/bin"
	  chezmoi="$bin_dir/chezmoi"
	  if [ "$(command -v curl)" ]; then
	    su -l $USERNAME -c "sh -c \"\$(curl -fsLS https://git.io/chezmoi)\" -- -b \"$bin_dir\""
	  elif [ "$(command -v wget)" ]; then
	    su -l $USERNAME -c "sh -c \"\$(wget -qO- https://git.io/chezmoi)\" -- -b \"$bin_dir\""
	  else
	    echo "To install chezmoi, you must have curl, wget, or snapd installed." >&2
	    exit 1
	  fi
  else
	  snap install --classic chezmoi
  fi
else
  chezmoi=chezmoi
fi

# init chezmoi
su -l $USERNAME -c "$chezmoi init --apply https://github.com/jaron-l/dotfiles.git"

# set chezmoi author
su -l $USERNAME -c "$chezmoi git config -- user.name \"Jaron Lundwall\""
su -l $USERNAME -c "$chezmoi git config -- user.email \"13423952+jaron-l@users.noreply.github.com\""

