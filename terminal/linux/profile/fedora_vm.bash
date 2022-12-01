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

#Function: Search for commit with FZF preview and copy hash
#  > [ENTER]           - Ver el detalle de commit y navegar en sus paginas
#  > [CTRL + Y]        - Copiar el hash del commit en portapapeles de windows
#  > [SHIFT + UP/DOWN] - Cambio de pagino en la vista de preview
alias glogline='git log --color=always --format="%C(cyan)%h%Creset %C(blue)%ar%Creset%C(auto)%d%Creset %C(yellow)%s%+b %C(white)%ae%Creset" "$@"'
gll_hash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
gll_view="$gll_hash | xargs git show --color=always | delta"
#gll_view="$gll_hash | xargs git show --color=always"

glog() {
    #Obtener el directorio .git pero no imprimir su valor ni los errores
    git rev-parse --git-dir > /dev/null 2>&1
    #Si no es un repositorio valido salir
    if [ $? != 0 ]; then
        echo 'Invalid git repository'
        return 0
    fi
    #Mostrar los commit y su preview
    glogline | fzf -i -e --no-sort --reverse --tiebreak index --no-multi --ansi --preview "$gll_view" \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" --bind "enter:execute:$gll_view" \
        --bind "ctrl-y:execute-silent:$gll_hash | clip.exe"
}

