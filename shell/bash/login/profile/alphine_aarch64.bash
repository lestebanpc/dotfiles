# ~/.bashrc: executed by bash for interactive non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

#export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
#export SYSTEMD_PAGER=

# User specific aliases and functions
#if [ -d ~/.bashrc.d ]; then
#    for rc in ~/.bashrc.d/*; do
#        if [ -f "$rc" ]; then
#            . "$rc"
#        fi
#    done
#fi
#
#unset rc


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
# Variables globales obtenidos del archivo de configuración '~/.profile_config.bash'
#-----------------------------------------------------------------------------------

# Obtener los parametros del archivos de configuración
if [ -f ~/.profile_config.bash ]; then
    . ~/.profile_config.bash
fi

# Nombre del repositorio GIT o ruta relativa desde el HOME del repositorio GIT
[ -z "$g_repo_name" ] && g_repo_name='.files'

# Ruta del folder base donde estan los subfolderes del los programas (1 o mas comandos y otros archivos).
if [ -z "$g_programs_path" ] || [ ! -f "$g_programs_path" ]; then
    g_programs_path='/var/opt/tools'
fi

# Ruta del folder donde se ubican comandos personalizado del usuario.
if [ -z "$g_bin_cmdpath" ] || [ ! -f "$g_bin_cmdpath" ]; then
    g_bin_cmdpath='/usr/local/bin'
fi

# Ruta del tema de 'Oh-My-Posh' a usar.
if [ -z "$g_prompt_theme" ] || [ ! -f "$g_prompt_theme" ]; then
    g_prompt_theme=~/${g_repo_name}/etc/oh-my-posh/default_settings.json
fi

#Usado por archivo de configuración de programas como TMUX, VIM, NeoVIM y CoC.
export MY_REPO_PATH="$HOME/$g_repo_name"
export MY_PRGS_PATH="$g_programs_path"
unset g_programs_path


#-----------------------------------------------------------------------------------
# Variable de entorno> PATH y de otros programas
#-----------------------------------------------------------------------------------

# Ruta del folder donde se ubican comandos personalizado del usuario.
if [ "$g_bin_cmdpath" != "/usr/local/bin" ] && [ "$g_bin_cmdpath" != "$HOME/.local/bin" ]; then
    PATH="${g_bin_cmdpath}:${PATH}"
fi
unset g_bin_cmdpath

# Java - GraalVM (RTE y Herramientas de desarrollo para Java y otros)
if [ -d "${MY_PRGS_PATH}/graalvm" ]; then
    GRAALVM_HOME="${MY_PRGS_PATH}/graalvm"
    export GRAALVM_HOME

    #No adicionar para no perjudicar los programas del SO que corren usando el OpenJDK del SO
    #JAVA_HOME="${GRAALVM_HOME}"
    #export GRAALVM_HOME JAVA_HOME
    #PATH="$PATH:${JAVA_HOME}/bin"
fi

# Java - Jbang (scripting para java)
[ -d "${MY_PRGS_PATH}/jbang/bin" ] && PATH="$PATH:${MY_PRGS_PATH}/jbang/bin"

# Java - CLI tools creados por Java usando Jbang
[ -d ~/.jbang/bin ] && PATH="$PATH:${HOME}/.jbang/bin"

# Java - Apache Maven (Builder para Java)
[ -d "${MY_PRGS_PATH}/maven/bin" ] && PATH="${MY_PRGS_PATH}/maven/bin:$PATH"

# Neovim path
[ -d "${MY_PRGS_PATH}/neovim/bin" ] && PATH="$PATH:${MY_PRGS_PATH}/neovim/bin"

# CMake - Sistema de contrucción para C/C++ y otros
[ -d "${MY_PRGS_PATH}/cmake" ] && PATH="$PATH:${MY_PRGS_PATH}/cmake/bin"

# Go - Tools estandar para desarrollo
[ -d "${MY_PRGS_PATH}/go/bin" ] && PATH="$PATH:${MY_PRGS_PATH}/go/bin"

# Go - CLI tools creados en Go
[ -d ~/go/bin ] && PATH="$PATH:${HOME}/go/bin"

# Rust - Tools para desarrollo
[ -d "${MY_PRGS_PATH}/rust/bin" ] && PATH="$PATH:${MY_PRGS_PATH}/rust/bin"

# Go - CLI tools creados en Rust
[ -d ~/.cargo/bin ] && PATH="$PATH:${HOME}/.cargo/bin"

# NodeJS - CLI tools creados en NodeJS y usando gestor de paquetes 'npm'
[ -d "${MY_PRGS_PATH}/nodejs/bin" ] && PATH="${MY_PRGS_PATH}/nodejs/bin:$PATH"

# DotNet
if [ -d "${MY_PRGS_PATH}/dotnet" ]; then

    # Dotnet Path
    export DOTNET_ROOT="${MY_PRGS_PATH}/dotnet"
    PATH="${DOTNET_ROOT}:$PATH"

    # Dotnet - CLI tools creados en .NET (Global .NET tools)
    [ -d "$DOTNET_ROOT/tools" ] && PATH="${DOTNET_ROOT}/tools:$PATH"

    # Limitar la maxima de la memoria de heap GC: https://github.com/dotnet/runtime/issues/79612
    export DOTNET_GCHeapHardLimit=1C0000000
fi

# gRPC - Ruta del compilador de ProtoBuffer de gRPC
[ -d "${MY_PRGS_PATH}/protoc/bin" ] && PATH="${MY_PRGS_PATH}/protoc/bin:$PATH"

# AWS CLI v2
[ -d "${MY_PRGS_PATH}/aws-cli/v2/current/bin" ] && PATH="${MY_PRGS_PATH}/aws-cli/v2/current/bin:$PATH"

# CTags
[ -d "${MY_PRGS_PATH}/ctags" ] && PATH="${MY_PRGS_PATH}/ctags/bin:$PATH"

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
    --preview 'if [ -d {} ]; then eza --tree --color=always --icons always -L 5 {} | head -n 300; else bat --color=always --style=numbers,header-filename,grid --line-range :500 {}; fi'"
#export FZF_CTRL_T_COMMAND="fd -H -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"

export FZF_ALT_C_OPTS="--prompt 'Go to Folder> '
    --preview 'eza --tree --color=always --icons always -L 5 {} | head -n 300'"
#export FZF_ALT_C_COMMAND="fd -H -t d -E '.git' -E 'node_modules'"


# FZF> El script "key bindings" y "fuzzy completion" (no puede ser modificado)
eval "$(fzf --bash)"

# FZF> El script "key bindings" y "fuzzy completion" (puede ser modificado)
#source ~/${g_repo_name}/shell/bash/login/autocomplete/fzf.bash
#source ~/${g_repo_name}/shell/bash/login/keybindings/fzf.bash


#-----------------------------------------------------------------------------------
# Comando> Otros
#-----------------------------------------------------------------------------------

# Oh-my-posh> Ejecutar el script de inicializacion segun el tema escogido
eval "$(oh-my-posh --init --shell bash --config ${g_prompt_theme})"
unset g_prompt_theme

# Oh-my-tmux> Opciones
export EDITOR=vim

# Zoxide> Ejecutar el script de inicializacion
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {2} | head -n 300' --preview-window=down,70%"
eval "$(zoxide init bash)"

# MPD> Para cliente CLI de MPD se conecten al servidor MPD usando Socket IPC
export MPD_HOST=/run/mpd/socket

# Editor por defecto para "systemctl edit"
export SYSTEMD_EDITOR=vim


#-----------------------------------------------------------------------------------
# Alias> Otros
#-----------------------------------------------------------------------------------

# Alias
alias j!=jbang
alias kc='kubectl'
alias step-jwt='step crypto jwt'


#-----------------------------------------------------------------------------------
# Funciones> Otros
#-----------------------------------------------------------------------------------

# Funciones basicas
source ~/${g_repo_name}/shell/bash/login/profile/custom_modules.bash
