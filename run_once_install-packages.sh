#!/bin/sh
sudo apt-get update
sudo apt-get install -y zsh
sudo snap install --classic nvim
sudo chsh -s $(which zsh) $USER
