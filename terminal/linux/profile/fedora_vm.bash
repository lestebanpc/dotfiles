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

# GraalVM (rutas)
GRAALVM_HOME=/opt/tools/graalvm
JAVA_HOME=${GRAALVM_HOME}
export GRAALVM_HOME JAVA_HOME

# Rutas por defecto: Adicionando rutas de programas especificos
PATH=$PATH:/opt/tools/neovim/bin

#RH-OCP - CLI
[ -d "/opt/tools/rh-ocp-cli" ] && PATH=$PATH:/opt/tools/rh-ocp-cli

#CMake - Sistema de contrucción para C/C++ y otros
[ -d "/opt/tools/cmake" ] && PATH=$PATH:/opt/tools/cmake/bin

#Go - Tools estandar para desarrollo
[ -d "/opt/tools/go/bin" ] && PATH=$PATH:/opt/tools/go/bin

#Go - Tools adicionales
[ -d ~/go/bin ] && PATH=$PATH:~/go/bin

#Rust - Tools para desarrollo
[ -d ~/.cargo/bin ] && PATH=$PATH:~/.cargo/bin

#GraalVM - RTE y Herramientas de desarrollo para Java y otros
[ -d "${JAVA_HOME}/bin" ] && PATH=$PATH:${JAVA_HOME}/bin

#Rust - LSP server
#[ -d "/opt/tools/lsp_servers/rust_analyzer" ] && PATH=$PATH:/opt/tools/lsp_servers/rust_analyzer

#LLVM/ClangD - LSP server
[ -d "/opt/tools/lsp_servers/clangd" ] && PATH=$PATH:/opt/tools/lsp_servers/clangd/bin

#Ruta del builder Apache Maven
[ -d "/opt/tools/maven/bin" ] && PATH=/opt/tools/maven/bin:$PATH


# Rutas por defecto: Exportar la variable de rutas por defecto para el usuario
export PATH


# Alias
alias kc='kubectl'


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

# Node.Js (nvm) - Usando varias Node.JS
export NVM_DIR="/opt/tools/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


# Ruta por defecto de los binarios de CNI plugin usados por un Container Runtime (como ContainerD)
[ -d "/opt/tools/cni_plugins" ] && export CNI_PATH=/opt/tools/cni_plugins


#Funciones basicas
source ~/.files/terminal/linux/functions/func_custom.bash



