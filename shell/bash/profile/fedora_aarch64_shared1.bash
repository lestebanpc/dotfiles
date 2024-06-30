# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

#User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
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

#Rutas por defecto: Adicionando rutas de programas especificos
[ -d "${l_program_path}/neovim/bin" ] && PATH="$PATH:${l_program_path}/neovim/bin"

#CMake - Sistema de contrucción para C/C++ y otros
[ -d "${l_program_path}/cmake" ] && PATH="$PATH:${l_program_path}/cmake/bin"

#Go - Tools estandar para desarrollo
[ -d "${l_program_path}/go/bin" ] && PATH="$PATH:${l_program_path}/go/bin"

#Go - Tools adicionales
[ -d ~/go/bin ] && PATH="$PATH:~/go/bin"

#Rust - Tools para desarrollo
[ -d "${l_program_path}/rust/bin" ] && PATH="$PATH:${l_program_path}/rust/bin"
#[ -d ~/.cargo/bin ] && PATH="$PATH:~/.cargo/bin"

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

#AWS CLI v2
[ -d "${l_program_path}/aws-cli" ] && PATH="${l_program_path}/aws-cli:$PATH"
#[ -d "${l_program_path}/aws-cli/v2/current/bin" ] && PATH="${l_program_path}/aws-cli/v2/current/bin:$PATH"

# Rutas por defecto: Exportar la variable de rutas por defecto para el usuario
export PATH


#Alias
alias kc='kubectl'
alias step-jwt='step crypto jwt'


# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

#Oh-my-posh> Ejecutar el script de inicializacion segun el tema escogido
eval "$(oh-my-posh --init --shell bash --config ~/.files/etc/oh-my-posh/lepc-montys-1.omp.json)"

#Oh-my-tmux> Opciones
export EDITOR=vim

#FZF> Opciones del comando fzf

#Variables de entorno
export FZF_COMPLETION_PATH_OPTS="--walker=file,dir,hidden,follow"
export FZF_COMPLETION_DIR_OPTS="--walker=dir,hidden,follow"
export FZF_DEFAULT_OPTS="--height=80% --layout=reverse --walker-skip=.git,node_modules --info=inline --border --color=bg+:#293739,bg:#1B1D1E,border:#808080,spinner:#E6DB74,hl:#7E8E91,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672"
#export FZF_DEFAULT_OPTS="--height=80% --layout=reverse --walker-skip=.git,node_modules --info=inline --border --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"
export FZF_CTRL_R_OPTS="--prompt 'History> '"
export FZF_CTRL_T_OPTS="--prompt 'Select> ' --preview 'if [ -d {} ]; then eza --tree --color=always --icons always -L 5 {} | head -n 300; else bat --color=always --style=numbers,header-filename,grid --line-range :500 {}; fi'"
export FZF_ALT_C_OPTS="--prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {} | head -n 300'"
#export FZF_CTRL_T_COMMAND="fd -H -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
#export FZF_ALT_C_COMMAND="fd -H -t d -E '.git' -E 'node_modules'"

#El script "key bindings" y "fuzzy completion" (no puede ser modificado)
eval "$(fzf --bash)"

#El script "key bindings" y "fuzzy completion" (puede ser modificado)
#source ~/.files/shell/bash/autocomplete/fzf.bash
#source ~/.files/shell/bash/keybindings/fzf.bash

#Zoxide> Ejecutar el script de inicializacion
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {2} | head -n 300' --preview-window=down,70%"
eval "$(zoxide init bash)"

#MPD> Para cliente CLI de MPD se conecten al servidor MPD usando Socket IPC 
export MPD_HOST=/run/mpd/socket

#CNI Plugin> Ruta por defecto de los binarios de CNI plugin (no se usara, se usara su archivo de configuración nerdctl.tom)
#[ -d "${l_program_path}/cni_plugins" ] && export CNI_PATH=${l_program_path}/cni_plugins

#Funciones basicas
source ~/.files/shell/bash/profile/_profile_functions.bash


