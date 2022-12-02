#!/bin/bash

#Definiciones globales, Inicialización {{{


#}}}

ln -snf ~/.files/terminal/linux/tmux/tmux.conf ~/.tmux.conf
ln -snf ~/.files/git/vm_linux_git.conf ~/.gitconfig
ln -snf ~/.files/ssh/vm_linux_ssh.conf ~/.ssh/config
ln -snf ~/.files/terminal/linux/profile/fedora_vm.bash ~/.bashrc

echo "Configuración de NodeJS"
curl -fsSL https://rpm.nodesource.com/setup_19.x | sudo bash -
sudo yum install -y nodejs
node -v

#Configuracion de VIM
echo "Configuración de VIM"
mkdir -p ~/.vim/pack/themes/start
mkdir -p ~/.vim/pack/themes/opt
mkdir -p ~/.vim/pack/ui/start
mkdir -p ~/.vim/pack/ui/opt
mkdir -p ~/.vim/pack/typing/start
mkdir -p ~/.vim/pack/typing/opt
mkdir -p ~/.vim/pack/ide/start
mkdir -p ~/.vim/pack/ide/opt

mkdir -p ~/.vim/autoload
curl -fLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

cd ~/.vim/pack/themes/opt
git clone https://github.com/tomasr/molokai.git
git clone https://github.com/dracula/vim.git

cd ~/.vim/pack/ui/opt
git clone https://github.com/vim-airline/vim-airline.git
git clone https://github.com/vim-airline/vim-airline-themes.git
git clone https://github.com/preservim/nerdtree.git
git clone https://github.com/christoomey/vim-tmux-navigator.git
git clone --depth 1 https://github.com/junegunn/fzf.git
git clone https://github.com/junegunn/fzf.vim.git


cd ~/.vim/pack/typing/opt
git clone https://github.com/tpope/vim-surround.git
git clone https://github.com/mg979/vim-visual-multi

cd ~/.vim/pack/ide/opt
git clone https://github.com/dense-analysis/ale.git
git clone --branch release https://github.com/neoclide/coc.nvim.git --depth=1
git clone https://github.com/OmniSharp/omnisharp-vim
git clone https://github.com/SirVer/ultisnips.git
git clone https://github.com/honza/vim-snippets.git
git clone https://github.com/nickspoons/vim-sharpenup.git

ln -snf ~/.files/vim/vimrc_vm_linux_ide.vim ~/.vimrc

