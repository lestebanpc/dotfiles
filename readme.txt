#Permiso de ejecucion de script
chmod u+x ~/.files/tmux/oh-my-tmux.sh
chmod u+x ~/.files/fzf/completion.bash
chmod u+x ~/.files/fzf/key-bindings.bash

#Enlaces de archivos
# 1> Interprete shell> Bash
ln -s ~/.files/shell/ubuntu/bashrc.sh ~/.bashrc
# 2> SSH Config
ln -sn ~/.files/ssh/wsl2.config ~/.ssh/config
# 3> VIM
ls -s ~/.files/vim/vimrc_wsl2.vim ~/.vimrc
# 4> NeoVim
ln -s ~/.files/nvim/init_wsl2.vim ~/.config/nvim/init.vim
# 5> Oh-My-Posh
ln -s ~/.files/oh-my-posh/lepc-montys.omp.json /opt/tools/oh-my-posh/themes/lepc-montys.omp.json
# 6> Git
ln -s ~/.files/git/wsl2.gitconfig ~/.gitconfig
# 7> TMUX
ln -s ~/.files/tmux/tmux.conf ~/.tmux.conf

#Enlaces de carpetas:
# 1> NeoVim
ln -s ~/.files/nvim/lua ~/.config/nvim/lua



#Enlaces de archivos/carpetas
# 1> Interprete shell> Poweshell
MKLINK E:\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 %USERPROFILE%\.files\shell\windows\profile.ps1
MKLINK E:\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 %USERPROFILE%\.files\shell\windows\profile.ps1
# 2> Git
MKLINK %USERPROFILE%\.gitconfig %USERPROFILE%\.files\git\windows.gitconfig
# 3> VIM
MKLINK %USERPROFILE%\.vimrc %USERPROFILE%\.files\vim\vimrc_windows.vim
# 4> NeoVim
MKLINK %LOCALAPPDATA%\nvim\init.vim %USERPROFILE%\.files\nvim\init_windows.vim
MKLINK /D %LOCALAPPDATA%\nvim\lua %USERPROFILE%\.files\nvim\lua
# 5> SSH Config
MKLINK %USERPROFILE%\.ssh\config %USERPROFILE%\.files\ssh\windows.config
# 6> Oh-My-Posh
MKLINK D:\Tools\Cmds\Windows\oh-my-posh\themes\lepc-montys.omp.json %USERPROFILE%\.files\oh-my-posh\lepc-montys.omp.json

