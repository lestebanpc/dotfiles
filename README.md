# Descripcion

Mi archivos de configuración

# Configuración

Se puede tener varios escenarios:

## 1. Configuración en Linux

Se tiene los siguientes pasos:

```shell
#Descargar el repositorio en ~/.files
git clone https://github.com/lestebanpc/dotfiles.git ~/.files
#Actualizar los paquetes, instalar VIM
chmod u+x ~/.files/setup/01_setup_init.bash
. ~/.files/setup/01_setup_init.bash
```

Se recomienda, Instalar o actualizar los comandos que mas uso que estan en el repositorio GitHub (mas actuales que los que estan en los repositorio de la distribución Linux):

```shell
. ~/.files/setup/02_setup_commands.bash
```

Configurar el profile ("~/.bashrc", "~/.tmux.conf", "~/.gitconfig", "~/.ssh/config", ..) y la configuración de VIM:

```shell
. ~/.files/setup/03_setup_profile_vm_fedora.bash
```

Este script instalar plugins de VIM (solo para usuario no-root instalara plugins para convertir VIM en IDE).

Una vez configurado el VIM como IDE (para un usuario no root) tambien debera:



```shell
#Instalar paquetes de VIM-Plug
:PlugInstall

#Para VIM como IDE, configurar COC
:CocInstall coc-tsserver coc-json coc-html coc-css
:CocInstall coc-pyright
:CocInstall coc-ultisnips
:CocConfig
```

El resumen:

1. Establecer permisos de ejecuacion de los script basicos: 
   
   ```shell
   chmod u+x ~/.files/terminal/linux/tmux/oh-my-tmux.sh
   chmod u+x ~/.files/terminal/linux/complete/fzf.bash
   chmod u+x ~/.files/terminal/linux/keybindings/fzf.bash
   chmod u+x ~/.files/setup/setup_commands.bash
   ```

2. Instalar el cliente Git
   
   ```shell
   #Para mi Ubuntu
   sudo apt install git-all
   #Para mi Fedora
   sudo dnf install git-all
   ```

3. Ejecutar el scritp que instala/actualiza los comandos que mas uso que estan en el repositorio GitHub (mas actuales que los que estan en los repositorio de la distribucion Linux)
   
   ```shell
   #
   . ~/.files/setup/setup_commands.bash
   #
   ...
   ```

4. Configurar '~/.dircolors' (para que se crea una variable LS_COLORS mas adecuada): 
   
   ```bash
   #Para mi WSL2 Ubuntu
   ln -s ~/.files/terminal/linux/profile/ubuntu_wls_dircolors.conf ~/.dircolors
   ```

5. Configurar el interprete shell "bash"
   
   ```shell
   #Para mi WSL2 Ubuntu
   ln -sf ~/.files/terminal/linux/profile/ubuntu_wls.bash ~/.bashrc
   #Para mi Fedora WS ...
   ```

6. Configuracion del TMUX
   
   ```shell
   ln -s ~/.files/terminal/linux/tmux/tmux.conf ~/.tmux.conf
   ```

7. Configuracion de Git
   
   ```shell
   #Para mi WSL2 Ubuntu
   ln -s ~/.files/git/wsl2_git.conf ~/.gitconfig
   ```

8. Registro de mis servidores SSH mas usados
   
   ```shell
   #Para mi WSL2 Ubuntu
   mkdir -p ~/.ssh/
   ln -sfn ~/.files/ssh/wsl2_ssh.conf ~/.ssh/config
   ```

9. Configuración de VIM
   
   Estoy usando mas VIM que Neovim, por tal motivo el script de inicializacíon esta pensado en uso VimScrip antes que Lua.
   
   1. Instalando del gestor de plugins Vim-Plug
   
   2. Instalando los plugins a usar
      
      ```vim
      #Para actualizar los paquetes de Vim-Plug
      :PlugInstall
      ```
   
   3. Configuracion de VIM
      
      ```shell
      #Para mi WSL2 Ubuntu
      ls -s ~/.files/vim/vimrc_wsl2.vim ~/.vimrc
      #Para mi Fedora WS ...
      ```

10. Configuración de NoeVIM
    Estoy usando Neovim como editor alternativo a VIM (uso mas Vim)
    
    1. Instalando del gestor de packetes Packer
    
    2. Instalando del gestor de plugins Vim-Plug
    
    3. Instalando los plugins a usar
       
       ```vim
       #Para actualizar los paquetes de Packer
       :PackerUpdate
       #Para actualizar los paquetes de Vim-Plug
       :PlugInstall
       ```
    
    4. Configuracion de NeoVim
       
       ```shell
       #Los script LUA a usar
       ln -s ~/.files/nvim/lua ~/.config/nvim/lua
       #Mi archivo de configuracion
       ln -s ~/.files/nvim/init_wsl2.vim ~/.config/nvim/init.vim
       ```

## 2. Configuración en Windows

Se tiene los siguientes pasos:

1. Establecer permisos de ejecuacion de los script basicos: 
   
   ```shell
   #
   ```

2. Instalar el cliente Git
   
   ```shell
   #Para mi Ubuntu
   sudo apt install git-all
   #Para mi Fedora
   sudo dnf install git-all
   ```

3. Ejecutar el scritp que instala/actualiza los comandos que mas uso que estan en el repositorio GitHub (mas actuales que los que estan en los repositorio de la distribucion Linux)
   
   ```shell
   #
   . ~/.files/setup/setup_git_commands.bash
   #
   setup_git_commands
   ```

4. Configurar '~/.dircolors' (para que se crea una variable LS_COLORS mas adecuada): 
   
   ```bash
   #Para mi WSL2 Ubuntu
   ln -s ~/.files/terminal/linux/profile/ubuntu_wls_dircolors.conf ~/.dircolors
   ```

5. Configurar el interprete shell "bash"
   
   ```shell
   #Para mi Powershell
   MKLINK E:\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 %USERPROFILE%\.files\terminal\windows\profile\pwsh_profile.ps1
   #Para mi Windows Powershell (opcional)
   MKLINK E:\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 %USERPROFILE%\.files\terminal\windows\profile\pwsh_profile.ps1
   ```

6. Configuracion de Git
   
   ```shell
   #Para ..
   MKLINK %USERPROFILE%\.gitconfig %USERPROFILE%\.files\git\windows_git.conf
   ```

7. Registro de mis servidores SSH mas usados
   
   ```shell
   #Para ...
   MKLINK %USERPROFILE%\.ssh\config %USERPROFILE%\.files\ssh\windows_ssh.conf
   ```

8. Configuración de VIM
   
   Estoy usando mas VIM que Neovim, por tal motivo el script de inicializacíon esta pensado en uso VimScrip antes que Lua.
   
   1. Instalando del gestor de plugins Vim-Plug
   
   2. Instalando los plugins a usar
      
      ```vim
      #Para actualizar los paquetes de Vim-Plug
      :PlugInstall
      ```
   
   3. Configuracion de VIM
      
      ```shell
      #Para ...
      MKLINK %USERPROFILE%\.vimrc %USERPROFILE%\.files\vim\vimrc_windows.vim
      #Para ...
      ```

9. Configuración de NoeVIM
   Estoy usando Neovim como editor alternativo a VIM (uso mas Vim)
   
   1. Instalando del gestor de packetes Packer
   
   2. Instalando del gestor de plugins Vim-Plug
   
   3. Instalando los plugins a usar
      
      ```vim
      #Para actualizar los paquetes de Packer
      :PackerUpdate
      #Para actualizar los paquetes de Vim-Plug
      :PlugInstall
      ```
   
   4.  Configuracion de VIM
      
      ```shell
      #Folder de los scripts
      MKLINK /D %LOCALAPPDATA%\nvim\lua %USERPROFILE%\.files\nvim\lua
      #El archivo de configuracion
      MKLINK %LOCALAPPDATA%\nvim\init.vim %USERPROFILE%\.files\nvim\init_windows.vim
      ```

# Actualización de la configuraciones

Se puede tener varios escenarios:
