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
export PATH

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

# Cliente de RH OCP
export PATH=$PATH:/opt/tools/rh-ocp-cli

# Opciones por defecto del comando fzf
export FZF_DEFAULT_OPTS="--height=80% --layout=reverse --info=inline --border --margin=1 --padding=1 --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"
source ~/.files/terminal/linux/complete/fzf.bash
source ~/.files/terminal/linux/keybindings/fzf.bash

#Funciones basicas
source ~/.files/terminal/linux/functions/func_basic.bash



