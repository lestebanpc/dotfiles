#Permiso de ejecucion de script
chmod u+x ~/.files/tmux/oh-my-tmux.sh
chmod u+x ~/.files/fzf/completion.bash
chmod u+x ~/.files/fzf/key-bindings.bash

#Enlaces de archivos:
ln -s ~/.files/shell/ubuntu/bashrc.sh ~/.bashrc
ln -sn ~/.files/ssh/wsl2.config ~/.ssh/config
ls -s ~/.files/vim/vimrc_wsl2.vim ~/.vimrc
ln -s ~/.files/nvim/init_wsl2.vim ~/.config/nvim/init.vim
ln -s ~/.files/tmux/tmux.conf ~/.tmux.conf
ln -s ~/.files/oh-my-posh/lepc-montys.omp.json /opt/tools/oh-my-posh/themes/lepc-montys.omp.json

#Enlaces de carpetas:
ln -s ~/.files/nvim/lua ~/.config/nvim/lua
