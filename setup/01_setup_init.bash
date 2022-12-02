#!/bin/bash

#Definiciones globales, Inicialización {{{


#}}}

sudo dnf upgrade
#sudo dnf --refresh upgrade


#git clone https://github.com/lestebanpc/dotfiles.git ~/.files

chmod u+x ~/.files/terminal/linux/tmux/oh-my-tmux.sh
chmod u+x ~/.files/terminal/linux/complete/fzf.bash
chmod u+x ~/.files/terminal/linux/keybindings/fzf.bash
#chmod u+x ~/.files/setup/01_setup_init.bash
chmod u+x ~/.files/setup/02_setup_commands.bash
chmod u+x ~/.files/setup/03_setup_profile_vm_fedora.bash


sudo mkdir -m 755 /u01
sudo mkdir -m 755 /u01/userkeys
sudo chown lucianoepc:lucianoepc /u01/userkeys
mkdir -m 755 /u01/userkeys/ssh/

#echo  "Instalar VIM-Enhanced"
#sudo dnf install vim-enhanced


