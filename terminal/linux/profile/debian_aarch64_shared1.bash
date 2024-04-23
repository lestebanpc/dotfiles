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

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

#Colores por defecto a usar


# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias kc='kubectl'
alias step-jwt='step crypto jwt'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

#Ruta por defecto donde se instalan los programas (incluye, entre otros, 1 o mas comandos)
l_program_path='/var/opt/tools'

#GraalVM - RTE y Herramientas de desarrollo para Java y otros
if [ -d "${l_program_path}/graalvm" ]; then
    GRAALVM_HOME="${l_program_path}/graalvm"
    export GRAALVM_HOME

    #No adicionar por defecto para no perjudicar a los programas que corren usando el OpenJDK
    #JAVA_HOME="${GRAALVM_HOME}"
    #export GRAALVM_HOME JAVA_HOME
    #PATH="$PATH:${JAVA_HOME}/bin"
fi

# Rutas por defecto: Adicionando rutas de programas especificos
[ -d "${l_program_path}/neovim/bin" ] && PATH="$PATH:${l_program_path}/neovim/bin"

#CMake - Sistema de contrucción para C/C++ y otros
[ -d "${l_program_path}/cmake" ] && PATH="$PATH:${l_program_path}/cmake/bin"

#Go - Tools estandar para desarrollo
[ -d "${l_program_path}/go/bin" ] && PATH="$PATH:${l_program_path}/go/bin"

#Go - Tools adicionales
[ -d ~/go/bin ] && PATH="$PATH:${HOME}/go/bin"

#Rust - Tools para desarrollo
[ -d "${l_program_path}/rust/bin" ] && PATH="$PATH:${l_program_path}/rust/bin"
#[ -d ~/.cargo/bin ] && PATH="$PATH:${HOME}/.cargo/bin"

#LLVM/Clang/Clangd
if [ -d "${l_program_path}/llvm/bin" ]; then
    PATH="${l_program_path}/llvm/bin:$PATH"
elif [ -d "${l_program_path}/lsp_servers/clangd/bin" ]; then
    PATH="${l_program_path}/lsp_servers/clangd/bin:$PATH"
fi

#Ruta del builder Apache Maven
[ -d "${l_program_path}/maven/bin" ] && PATH="${l_program_path}/maven/bin:$PATH"

#Ruta del compilador de ProtoBuffer de gRPC
[ -d "${l_program_path}/protoc/bin" ] && PATH="${l_program_path}/protoc/bin:$PATH"

#Node.Js (RTE)
[ -d "${l_program_path}/nodejs/bin" ] && PATH="${l_program_path}/nodejs/bin:$PATH"

#DotNet
if [ -d "${l_program_path}/dotnet" ]; then
    export DOTNET_ROOT="${l_program_path}/dotnet"
    PATH="${DOTNET_ROOT}:$PATH"
    [ -d "$DOTNET_ROOT/tools" ] && PATH="${DOTNET_ROOT}/tools:$PATH"
    #Limitar la maxima de la memoria de heap GC: https://github.com/dotnet/runtime/issues/79612
    export DOTNET_GCHeapHardLimit=1C0000000
fi

# Rutas por defecto: Exportar la variable de rutas por defecto para el usuario
export PATH


# "Oh My Posh" - Usando el profile
eval "$(oh-my-posh --init --shell bash --config ~/.files/terminal/oh-my-posh/lepc-montys-1.omp.json)"

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# TMUX - Usando "oh-my-tmux", especificando el editor VIM
export EDITOR=vim

# FZF - Opciones por defecto del comando
export FZF_DEFAULT_OPTS="--height=80% --layout=reverse --info=inline --border --margin=1 --padding=1 --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"
source ~/.files/terminal/linux/complete/fzf.bash
source ~/.files/terminal/linux/keybindings/fzf.bash


# Para cliente CLI de MPD se conecten al servidor MPD usando Socket IPC 
export MPD_HOST=/run/mpd/socket


# Ruta por defecto de los binarios de CNI plugin usados por CLI de Container Runtime como NerdCtl (no se usara, se usara su archivo de configuración nerdctl.tom)
#[ -d "${l_program_path}/cni_plugins" ] && export CNI_PATH=${l_program_path}/cni_plugins

#Funciones basicas
source ~/.files/terminal/linux/functions/profile_functions.bash

# Para corregir el error en diseño al inicio del promt 'Oh My Posh'
#clear

