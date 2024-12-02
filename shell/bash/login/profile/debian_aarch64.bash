# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    [ -r ~/.dircolors ] && eval "$(dircolors -b ~/.dircolors)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:  sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


#-----------------------------------------------------------------------------------
# Variables globales obtenidos del archivo de configuración '~/_config.bash' 
#-----------------------------------------------------------------------------------

# Obtener los parametros del archivos de configuración
if [ -f ~/.config.bash ]; then

    # Obtener los valores por defecto de las variables
    . ~/.config.bash

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

#Usado por mi archivo de configuración de Tmux
export MY_REPO_PATH="$HOME/$g_repo_name"


#-----------------------------------------------------------------------------------
# Variable de entorno> PATH y de otros programas
#-----------------------------------------------------------------------------------

# Ruta del folder donde se ubican comandos personalizado del usuario.
if [ "$g_bin_cmdpath" != "/usr/local/bin" ] && [ "$g_bin_cmdpath" != "$HOME/.local/bin" ]; then
    PATH="${g_bin_cmdpath}:${PATH}"
fi

# GraalVM - RTE y Herramientas de desarrollo para Java y otros
if [ -d "${g_programs_path}/graalvm" ]; then
    GRAALVM_HOME="${g_programs_path}/graalvm"
    export GRAALVM_HOME

    # No adicionar por defecto para no perjudicar a los programas que corren usando el OpenJDK
    #JAVA_HOME="${GRAALVM_HOME}"
    #export GRAALVM_HOME JAVA_HOME
    #PATH="$PATH:${JAVA_HOME}/bin"
fi

# Rutas por defecto: Adicionando rutas de programas especificos
[ -d "${g_programs_path}/neovim/bin" ] && PATH="$PATH:${g_programs_path}/neovim/bin"

# CMake - Sistema de contrucción para C/C++ y otros
[ -d "${g_programs_path}/cmake" ] && PATH="$PATH:${g_programs_path}/cmake/bin"

# Go - Tools estandar para desarrollo
[ -d "${g_programs_path}/go/bin" ] && PATH="$PATH:${g_programs_path}/go/bin"

# Go - Tools adicionales
[ -d ~/go/bin ] && PATH="$PATH:${HOME}/go/bin"

# Rust - Tools para desarrollo
[ -d "${g_programs_path}/rust/bin" ] && PATH="$PATH:${g_programs_path}/rust/bin"
#[ -d ~/.cargo/bin ] && PATH="$PATH:${HOME}/.cargo/bin"

# LLVM/Clang/Clangd
if [ -d "${g_programs_path}/llvm/bin" ]; then
    PATH="${g_programs_path}/llvm/bin:$PATH"
elif [ -d "${g_programs_path}/lsp_servers/clangd/bin" ]; then
    PATH="${g_programs_path}/lsp_servers/clangd/bin:$PATH"
fi

# Ruta del builder Apache Maven
[ -d "${g_programs_path}/maven/bin" ] && PATH="${g_programs_path}/maven/bin:$PATH"

# Ruta del compilador de ProtoBuffer de gRPC
[ -d "${g_programs_path}/protoc/bin" ] && PATH="${g_programs_path}/protoc/bin:$PATH"

# Node.Js (RTE)
[ -d "${g_programs_path}/nodejs/bin" ] && PATH="${g_programs_path}/nodejs/bin:$PATH"

# DotNet
if [ -d "${g_programs_path}/dotnet" ]; then
    export DOTNET_ROOT="${g_programs_path}/dotnet"
    PATH="${DOTNET_ROOT}:$PATH"
    [ -d "$DOTNET_ROOT/tools" ] && PATH="${DOTNET_ROOT}/tools:$PATH"

    #Limitar la maxima de la memoria de heap GC: https://github.com/dotnet/runtime/issues/79612
    export DOTNET_GCHeapHardLimit=1C0000000
fi

# AWS CLI v2
[ -d "${g_programs_path}/aws-cli/v2/current/bin" ] && PATH="${g_programs_path}/aws-cli/v2/current/bin:$PATH"

# CTags
[ -d "${g_programs_path}/ctags" ] && PATH="${g_programs_path}/ctags/bin:$PATH"

# CNI Plugin> Ruta por defecto de los binarios de CNI plugin (no se usara, se usara su archivo de configuración nerdctl.tom)
#[ -d "${g_programs_path}/cni_plugins" ] && export CNI_PATH=${g_programs_path}/cni_plugins

# Rutas por defecto: Exportar la variable de rutas por defecto para el usuario
export PATH



#-----------------------------------------------------------------------------------
# Comando> FZF
#-----------------------------------------------------------------------------------

# FZF> Variables de entorno
export FZF_COMPLETION_PATH_OPTS="--walker=file,dir,hidden,follow"
export FZF_COMPLETION_DIR_OPTS="--walker=dir,hidden,follow"
export FZF_DEFAULT_OPTS="--height=80% --tmux=center,100%,80% --layout=reverse --walker-skip=.git,node_modules --info=inline --border --color=bg+:#293739,bg:#1B1D1E,border:#808080,spinner:#E6DB74,hl:#7E8E91,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672"
#export FZF_DEFAULT_OPTS="--height=80% --layout=reverse --walker-skip=.git,node_modules --info=inline --border --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"
export FZF_CTRL_R_OPTS="--prompt 'History> '"
export FZF_CTRL_T_OPTS="--prompt 'Select> ' --preview 'if [ -d {} ]; then eza --tree --color=always --icons always -L 5 {} | head -n 300; else bat --color=always --style=numbers,header-filename,grid --line-range :500 {}; fi'"
export FZF_ALT_C_OPTS="--prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {} | head -n 300'"
#export FZF_CTRL_T_COMMAND="fd -H -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
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

# Oh-my-tmux> Opciones
export EDITOR=vim

# Zoxide> Ejecutar el script de inicializacion
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {2} | head -n 300' --preview-window=down,70%"
eval "$(zoxide init bash)"

# MPD> Para cliente CLI de MPD se conecten al servidor MPD usando Socket IPC 
export MPD_HOST=/run/mpd/socket


#-----------------------------------------------------------------------------------
# Alias> Otros
#-----------------------------------------------------------------------------------

# Alias
alias kc='kubectl'
alias step-jwt='step crypto jwt'


#-----------------------------------------------------------------------------------
# Funciones> Otros
#-----------------------------------------------------------------------------------

# Funciones basicas
source ~/${g_repo_name}/shell/bash/login/profile/custom_profile_modules.bash


