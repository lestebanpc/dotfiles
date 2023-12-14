# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

#Ruta por defecto donde se instalan los programas (incluye, entre otros, 1 o mas comandos)
l_program_path=~/tools

# GraalVM (rutas)
GRAALVM_HOME=${l_program_path}/graalvm
JAVA_HOME=${GRAALVM_HOME}
export GRAALVM_HOME JAVA_HOME

# Rutas por defecto: Adicionando rutas de programas especificos
PATH=$PATH:${l_program_path}/neovim/bin

#RH-OCP - CLI
[ -d "${l_program_path}/rh-ocp-cli" ] && PATH=$PATH:${l_program_path}/rh-ocp-cli

#CMake - Sistema de contrucción para C/C++ y otros
[ -d "${l_program_path}/cmake" ] && PATH=$PATH:${l_program_path}/cmake/bin

#Go - Tools estandar para desarrollo
[ -d "${l_program_path}/go/bin" ] && PATH=$PATH:${l_program_path}/go/bin

#Go - Tools adicionales
[ -d ~/go/bin ] && PATH=$PATH:~/go/bin

#Rust - Tools para desarrollo
[ -d ~/.cargo/bin ] && PATH=$PATH:~/.cargo/bin

#GraalVM - RTE y Herramientas de desarrollo para Java y otros
[ -d "${JAVA_HOME}/bin" ] && PATH=$PATH:${JAVA_HOME}/bin

#Rust - LSP server
#[ -d "${l_program_path}/lsp_servers/rust_analyzer" ] && PATH=$PATH:${l_program_path}/lsp_servers/rust_analyzer

#LLVM/ClangD - LSP server
[ -d "${l_program_path}/lsp_servers/clangd" ] && PATH=$PATH:${l_program_path}/lsp_servers/clangd/bin

#Ruta del builder Apache Maven
[ -d "${l_program_path}/maven/bin" ] && PATH=${l_program_path}/maven/bin:$PATH

#Ruta del compilador de ProtoBuffer de gRPC
[ -d "${l_program_path}/protoc/bin" ] && PATH=${l_program_path}/protoc/bin:$PATH

#Node.Js (RTE)
[ -d "${l_program_path}/nodejs/bin" ] && PATH=${l_program_path}/nodejs/bin:$PATH

#DotNet
export DOTNET_ROOT=${l_program_path}/dotnet
[ -d "$DOTNET_ROOT" ] && PATH=${DOTNET_ROOT}:$PATH
[ -d "$DOTNET_ROOT/tools" ] && PATH=${DOTNET_ROOT}/tools:$PATH


# Rutas por defecto: Exportar la variable de rutas por defecto para el usuario
export PATH


# Alias
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


# Tema por defecto de "Oh My Posh"
eval "$(oh-my-posh --init --shell bash --config ~/.files/terminal/oh-my-posh/lepc-montys.omp.json)"

# Para tmux (usando la configuracion de "oh-my-tmux")
export EDITOR=vim

# Opciones por defecto del comando fzf
export FZF_DEFAULT_OPTS="--height=80% --layout=reverse --info=inline --border --margin=1 --padding=1 --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"
source ~/.files/terminal/linux/complete/fzf.bash
source ~/.files/terminal/linux/keybindings/fzf.bash


# Ruta por defecto de los binarios de CNI plugin usados por CLI de Container Runtime como NerdCtl (no se usara, se usara su archivo de configuración nerdctl.tom)
#[ -d "${l_program_path}/cni_plugins" ] && export CNI_PATH=${l_program_path}/cni_plugins


#Funciones basicas
source ~/.files/terminal/linux/functions/func_custom.bash



