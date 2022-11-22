#Permiso de ejecucion de script
chmod u+x ~/.files/terminal/linux/tmux/oh-my-tmux.sh
chmod u+x ~/.files/terminal/linux/complete/fzf.bash
chmod u+x ~/.files/terminal/linux/keybindings/fzf.bash
chmod u+x ~/.files/setup/setup_git_commands.bash

#Enlaces de archivos (generalmente los archivos de configuracion se les colocara la extension '.conf')
# 1> Interprete shell> Bash
ls -sf ~/.files/terminal/linux/profile/ubuntu_wls_bash.sh ~/.bashrc
# 2> SSH Config
ln -sn ~/.files/ssh/wsl2_ssh.conf ~/.ssh/config
# 3> VIM
ls -s ~/.files/vim/vimrc_wsl2.vim ~/.vimrc
# 4> NeoVim
ln -s ~/.files/nvim/init_wsl2.vim ~/.config/nvim/init.vim
# 5> Oh-My-Posh
ln -s ~/.files/terminal/oh-my-posh/lepc-montys.omp.json /opt/tools/oh-my-posh/themes/lepc-montys.omp.json
# 6> Git
ln -s ~/.files/git/wsl2_git.conf ~/.gitconfig
# 7> TMUX
ln -s ~/.files/terminal/linux/tmux/tmux.conf ~/.tmux.conf
# 8> Crear ~/.dircolors y modificarlo para crear una variable LS_COLORS mas adecuada
dircolors --print-database > ~/.files/terminal/linux/profile/ubuntu_wls_dircolors.conf
vim ~/.files/terminal/linux/profile/ubuntu_wls_dircolors.conf
ln -s ~/.files/terminal/linux/profile/ubuntu_wls_dircolors.conf ~/.dircolors

#Enlaces de carpetas:
# 1> NeoVim
ln -s ~/.files/nvim/lua ~/.config/nvim/lua



#Enlaces de archivos/carpetas
# 1> Interprete shell> Poweshell
MKLINK E:\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 %USERPROFILE%\.files\terminal\windows\pwsh_profile.ps1
MKLINK E:\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 %USERPROFILE%\.files\terminal\windows\pwsh_profile.ps1
# 2> Git
MKLINK %USERPROFILE%\.gitconfig %USERPROFILE%\.files\git\windows_git.conf
# 3> VIM
MKLINK %USERPROFILE%\.vimrc %USERPROFILE%\.files\vim\vimrc_windows.vim
# 4> NeoVim
MKLINK %LOCALAPPDATA%\nvim\init.vim %USERPROFILE%\.files\nvim\init_windows.vim
MKLINK /D %LOCALAPPDATA%\nvim\lua %USERPROFILE%\.files\nvim\lua
# 5> SSH Config
MKLINK %USERPROFILE%\.ssh\config %USERPROFILE%\.files\ssh\windows_ssh.conf
# 6> Oh-My-Posh
MKLINK D:\Tools\Cmds\Windows\oh-my-posh\themes\lepc-montys.omp.json %USERPROFILE%\.files\oh-my-posh\lepc-montys.omp.json

