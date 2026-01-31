#!/bin/bash

# User specific environment
if ! [[ "$PATH" =~ $HOME/.local/bin:$HOME/bin: ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi


#-------------------------------------------------------------------------------------
# Command history
#-------------------------------------------------------------------------------------

# Tamaño maximo de comandos en memoria por shell interactivo
export HISTSIZE=10000

# Tamaño maximo del historial de comandos
export HISTFILESIZE=20000

# No almacenar comandos conscutivos repetidas y que inician con espacio.
export HISTCONTROL=ignoredups:erasedups

# Por defecto, la ultima instancia del shell interactivo, trunca el archivo y sobre-escribe el historial
# con su historia de comandos contenido en memoria.
# Activar la opcion 'histappend', no trunca el archivo, lo adiciona.
shopt -s histappend


#-----------------------------------------------------------------------------------
# Variables globales y de entorno basicas
#-----------------------------------------------------------------------------------

# Nombre del repositorio git o la ruta relativa del repositorio git respecto al HOME.
# - Si no se establece (valor vacio), se usara el valor '.files'.
# - Usado para generar la variable de entorno 'MY_REPO_PATH' usado en la configuración de programas como TMUX.
g_repo_name='.files'

# Folder base donde se almacena los subfolderes de los programas.
# - Si no es un valor valido (no existe o es vacio), su valor sera el valor por defecto "/var/opt/tools"
# - Si es un directorio valido se Convertira en la variable de entorno 'MY_TOOLS_PATH' usado en la configuración
#   de programas como TMUX.
export MY_TOOLS_PATH='/var/opt/tools'
#export MY_TOOLS_PATH=~/tools

# Folder donde se almacena los binarios de tipo comando.
# - Si los comandos instalados por el script '~/${g_repo_name}/shell/bash/bin/linuxsetup/01_setup_binaries.bash'
#   se ha instalado en una ruta personalizado (diferente a '/usr/local/bin' o '~/.local/bin'), es obligatorio
#   establecer la ruta correcta en dicha variable.
# - Si no se especifica (es vacio), se considera la ruta estandar '/usr/local/bin'
g_lnx_bin_path='/usr/local/bin'

# Ruta del tema de 'Oh-My-Posh' usada para establecer el prompt a usar.
# Si no se establecer (es vacio), se usara '~/${g_repo_name}/etc/oh-my-posh/default_settings.json'
#g_prompt_theme=~/${g_repo_name}/etc/oh-my-posh/lepc-montys-blue1.json
#g_prompt_theme=~/${g_repo_name}/etc/oh-my-posh/default_settings.json

# Tipo de origin de la sesion del profile. Si no se especifica, se calcula automaticamente.
# Sus valores puede ser:
#  > 0 Si se usa sesion remota SSH (ya se de un 'desktop server' o 'headless server').
#  > 1 Si se realiza una sesion local usando 'Console Linux'.
#  > 2 Si se usa sesion dentro del escritorio del servidor (ya sea local desktop o remote desktop).
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]; then
    export MY_SESSION_SRC=0
elif [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    export MY_SESSION_SRC=2
else
    export MY_SESSION_SRC=1
fi

# Ruta del folder donde se ubican comandos personalizado del usuario.
if [ "$g_lnx_bin_path" != "/usr/local/bin" ] && [ "$g_lnx_bin_path" != "$HOME/.local/bin" ]; then
    PATH="${g_lnx_bin_path}:${PATH}"
fi
unset g_lnx_bin_path

# Definir el tipo de entorno donde los shell del usuario se va a configurar.
# Su valores son:
#  > 0 Los script se ejecutan en un 'Headless Server'
#      > El script se ejecutan en un servidor donde no se tiene un gestor de ventanas (usualmente no se cuenta con GPU).
#      > No cuenta con aplicaciones GUI (no cuenta con emulador de terminal GUI).
#      > Se puede conectar localmente usando el emulador de terminal CLI 'Linux Console'.
#      > Se puede conectar remotamente usando SSH con su emulador de terminal externo (usualmente GUI) favorito.
#  > 1 Los script se ejecutan en un 'Desktop Server'
#      > El script se ejecutan en un servidor donde se tiene un gestor de ventanas (siempre cuenta con GPU).
#      > Cuenta con aplicaciones GUI, incluyendo un emulador de terminal GUI que permite ejecutar scrript localmente.
#      > Se puede ejecutar script localmente:
#        > Conectandose al escritorio del servidor (ingresando localmente al escritorio del servidor o conectandose
#          remotamente usando un programa de gestion de escritorio remoto como VNC) y usando el emulador de terminal GUI
#          existente en el servidor.
#        > Muy poco usual, conectandose localmente pero usando el emulador de terminal CLI 'Linux Console'.
#      > Se puede ejecutar script remotamente usando SSH con su emulador de terminal externo (usualmente GUI) favorito.
#  > 2 Los script se ejecutan en un contenedor dentro de un 'Desktop Server' y este tiene acceso a la GPU de este servidor.
#      > Los script de ejecutan dentro de proceso local de un 'Desktop Server' pero en un entorno aislado (contenedor)
#        pero que tiene acceso a GPU y progrmadas GUI del servidor.
#      > Aparte de tener acceso a la GPU tiene acceso a todo lo necesario para interactuar con estos (como bus de mensajes).
#      > No estan diseñados para que se conecten remotamente por ssh.
#      > Por defecto los contenedores no tiene acceso a la GPU del servidor donde se ejecuta.
#      > Ejemplo: Contenedores Distrobox o Toolbox en Linux.
#  > 3 Los script de ejecutan en un VM local dentro de un 'Desktop Server' tiene acceso a la GPU del servidor.
#      > Los script de ejecutan dentro de proceso remoto de un 'Desktop Server' (dentro de una VM) pero que tiene acceso a GPU
#        y programadas GUI del servidor.
#      > Aparte de tener acceso a la GPU tiene acceso a todo lo necesario para interactuar con estos (como bus de mensajes).
#      > No estan diseñados para que se conecten remotamente por ssh.
#      > Ejemplo: La VM ligera WSL2 que esta integrada con Windows en modo escritorio.
#  > Si no se define, su valor por defecto es '0' (Headless Server).
export MY_ENV_TYPE=0


#-----------------------------------------------------------------------------------
# Variable de entorno> PATH y similares
#-----------------------------------------------------------------------------------

# Java - GraalVM (RTE y Herramientas de desarrollo para Java y otros)
if [ -d "${MY_TOOLS_PATH}/graalvm" ]; then
    GRAALVM_HOME="${MY_TOOLS_PATH}/graalvm"
    export GRAALVM_HOME
fi

# Java - Jbang (scripting para java)
[ -d "${MY_TOOLS_PATH}/jbang/bin" ] && PATH="$PATH:${MY_TOOLS_PATH}/jbang/bin"

# Java - CLI tools creados por Java usando Jbang
[ -d "${HOME}/.jbang/bin" ] && PATH="$PATH:${HOME}/.jbang/bin"

# Java - Apache Maven (Builder para Java)
[ -d "${MY_TOOLS_PATH}/maven/bin" ] && PATH="${MY_TOOLS_PATH}/maven/bin:$PATH"

# Neovim path
[ -d "${MY_TOOLS_PATH}/neovim/bin" ] && PATH="$PATH:${MY_TOOLS_PATH}/neovim/bin"

# CMake - Sistema de contrucción para C/C++ y otros
[ -d "${MY_TOOLS_PATH}/cmake" ] && PATH="$PATH:${MY_TOOLS_PATH}/cmake/bin"

# Go - Tools estandar para desarrollo
[ -d "${MY_TOOLS_PATH}/go/bin" ] && PATH="$PATH:${MY_TOOLS_PATH}/go/bin"

# Go - CLI tools creados en Go
[ -d "${HOME}/go/bin" ] && PATH="$PATH:${HOME}/go/bin"

# Rust - Tools para desarrollo
[ -d "${MY_TOOLS_PATH}/rust/bin" ] && PATH="$PATH:${MY_TOOLS_PATH}/rust/bin"

# Go - CLI tools creados en Rust
[ -d "${HOME}/.cargo/bin" ] && PATH="$PATH:${HOME}/.cargo/bin"

# NodeJS - CLI tools creados en NodeJS y usando gestor de paquetes 'npm'
[ -d "${MY_TOOLS_PATH}/nodejs/bin" ] && PATH="${MY_TOOLS_PATH}/nodejs/bin:$PATH"

# DotNet
if [ -d "${MY_TOOLS_PATH}/dotnet" ]; then

    # Dotnet Path
    export DOTNET_ROOT="${MY_TOOLS_PATH}/dotnet"
    PATH="${DOTNET_ROOT}:$PATH"

    # Dotnet - CLI tools creados en .NET (Global .NET tools)
    [ -d "$DOTNET_ROOT/tools" ] && PATH="${DOTNET_ROOT}/tools:$PATH"

    # Para algunas distros en arm64, debe limitar la maxima de la memoria de heap GC: https://github.com/dotnet/runtime/issues/79612
    #export DOTNET_GCHeapHardLimit=1C0000000

fi

# gRPC - Ruta del compilador de ProtoBuffer de gRPC
[ -d "${MY_TOOLS_PATH}/protoc/bin" ] && PATH="${MY_TOOLS_PATH}/protoc/bin:$PATH"

# AWS CLI v2
[ -d "${MY_TOOLS_PATH}/aws-cli/v2/current/bin" ] && PATH="${MY_TOOLS_PATH}/aws-cli/v2/current/bin:$PATH"

# CTags
[ -d "${MY_TOOLS_PATH}/ctags" ] && PATH="${MY_TOOLS_PATH}/ctags/bin:$PATH"

# Rutas por defecto: Exportar la variable de rutas por defecto para el usuario
export PATH


#-----------------------------------------------------------------------------------
# Comando> FZF
#-----------------------------------------------------------------------------------

# FZF> Variables de entorno
export FZF_COMPLETION_PATH_OPTS="--walker=file,dir,hidden,follow"
export FZF_COMPLETION_DIR_OPTS="--walker=dir,hidden,follow"

export FZF_DEFAULT_OPTS="--height=80% --tmux=center,100%,80%
    --layout=reverse --walker-skip=.git,node_modules
    --info=inline --border
    --color=bg+:#293739,bg:#0F0F0F,border:#808080,spinner:#E6DB74,hl:#7E8E91,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672"

export FZF_CTRL_R_OPTS="--prompt 'History> '
    --preview 'echo {2..} | bat --color=always -pl sh'
    --preview-window up:3:hidden:wrap
    --bind 'ctrl-/:toggle-preview'
    --bind 'ctrl-t:track+clear-query'
    --bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
    --header '(Ctrl+/) Toggle preview, (Ctrl+t) Clear query, (Ctrl+y) Copy command'
    --color header:italic"

export FZF_CTRL_T_OPTS="--prompt 'Select> '
    --bind 'ctrl-y:execute-silent(echo -n {} | wl-copy)+abort'
    --header '(Ctrl+y) Copy file/folder path'
    --preview 'if [ -d {} ]; then eza --tree --color=always --icons always -L 4 {} | head -n 300; else bat --color=always --style=numbers,header-filename --line-range :500 {}; fi'"

export FZF_ALT_C_OPTS="--prompt 'Go to Folder> '
    --bind 'ctrl-y:execute-silent(echo -n {} | wl-copy)+abort'
    --header '(Ctrl+y) Copy folder path'
    --preview 'eza --tree --color=always --icons always -L 4 {} | head -n 300'"

# FZF> El script "keybindings" y "fuzzy completion" (autocomplete)
#eval "$(fzf --bash)"


#-----------------------------------------------------------------------------------
# Comando> Otros
#-----------------------------------------------------------------------------------

# Oh-my-posh> Ejecutar el script de inicializacion segun el tema escogido
#eval "$(oh-my-posh --init --shell bash --config ${g_prompt_theme})"
#unset g_prompt_theme

# Zoxide> Ejecutar el script de inicializacion
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 4 {2} | head -n 300' --preview-window=down,70%"
eval "$(zoxide init bash)"


#-----------------------------------------------------------------------------------
# Variable de entorno> Otros
#-----------------------------------------------------------------------------------

# Editor por defecto
export EDITOR="${EDITOR:-vim}"

# Editor por defecto para "systemctl edit"
export SYSTEMD_EDITOR="${SYSTEMD_EDITOR:-vim}"

#Usado por archivo de configuración de programas como TMUX, VIM, NeoVIM y CoC.
export MY_REPO_PATH="$HOME/$g_repo_name"

# La variable de entorno 'TMUX_NESTED' es usado por 'tmux' e indica si el tmux actual se ejecuta dentro de otro tmux padre.
# Es usado para definir para cambiar el prefijo de 'CTRL + b' (root tmux)  a 'Ctrl + a' (nested tmux).
#   > 0 ('true' ), es un 'nested tmux' (el tmux se ejecuta dentro de otro tmux en una mismo emulador de terminal).
#   > 1 ('false'), es un 'root tmux'.
# Si no se define, su valor por defecto es 1 ('false'), es decir el tmux no esta dentro de otro.
#export TMUX_NESTED=0

# Definir el identificador del emulador de terminal a usar.
# > Useló cuando desea usar OSC-52 y solo en ciertos escenarios especiales:
#   > Si si emulador de terminal soporta OSC-52 pero no genera la variable de entorno 'TERM_PROGRAM' o tiene un
#     valor que no esta en la lista
#   > Cuando usara pseudo-terminales creadas por programas (tmux, ssh, etc.) donde no se puede identificar que terminal se
#     esta usando.
# > En vim/nvim/tmux es usado para determinar, de manera automatica, el mecanismo de escritura al clipboard.
# > Si 'TERM_PROGRAM' es 'foot', 'WezTerm', 'contour', 'iTerm.app', 'kitty' o 'alacritty', se usara OSC-52 para
#   escribir al clipboard ('paste').
export TERM_PROGRAM='wezterm'

# La variable de entorno 'SET_CIPBOARD' define el mecanismo de escritura de clipboard que se usara en 'tmux':
# > 0 : No habilita la escritura en el clipboard.
# > 1 : Habilita la escritura usando el caracter de escape ANSI OSC-52 (la terminal debe soportarlo)
# > 2 : Habilita la escritura usando comandos externos (requiere tener instalado 'xsel', 'xclip' or 'wl-copy').
# >   : Se determina automaticamente el mecanismo a usar.
# Su no se define (valor ''), se determinara automaticamente el mecanismo a usar.
#export SET_CLIPBOARD=1

# La variable de entorno 'CIPBOARD' define el mecanismo de escritura de clipboard en un programa CLI.
# Actualmente, solo es usado por VIM/NeoVIM y su soporte incluye:
#  > Acciones de escritura al clipboard usanbdo el valor de los registros VIM.
#  > Escritura automatica al clipboard despues de realizar el yank (si esta habilitado la variable 'g:yank_to_clipboard'
#    o 'YANK_TO_CB').
# Los valores de la variable 'CLIPBOARD' son:
#  > 1 : Implementar un mecanismo usando OSC-52 (la terminal debe soportarlo).
#  > 2 : Implementar un mecanismo usando comandos externos de gestion de clipboard.
#  > 9 : Determinar automaticamente el mecanismo a usar.
# Si no se define, su valor depende de la variable VIM 'g:clipboard_osc52_format', si este no se define, el mecanismo
# es de escritura se descrubira automaticamente.
#export CLIPBOARD=0

# La variable de entorno 'YANK_TO_CB' es usado por VIM/NeoVIM, el es usado cuando se realize un 'yank' (en forma interactiva)
# este se pueda se copie automaticamente al clipboard.
# Su valor puede ser
#    > 0 ('true' ), si se cuando realiza un yank este se copiara automaticamente al clipboard.
#    > 1 ('false'), si realiza un yank este NO se copiara al clipboard.
# Si no se define, su valor depende de la variable VIM 'g:yank_to_clipboard', si este no se define, su valor es por defecto
# es 1 ('false').
#export YANK_TO_CB=1


#-----------------------------------------------------------------------------------
# Alias> Otros
#-----------------------------------------------------------------------------------

# Alias
alias j!=jbang
alias kc='kubectl'


#-----------------------------------------------------------------------------------
# Funciones> Otros
#-----------------------------------------------------------------------------------

# Funciones basicas
# shellcheck source=/home/lucianoepc/.files/shell/bash/login/profile/custom_modules.bash
source "${HOME}/${g_repo_name}/shell/bash/login/profile/custom_modules.bash"
