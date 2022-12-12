#!/bin/bash

################################################################################################
# GIT Functions
################################################################################################

#01. Search for commit with FZF preview and copy hash
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
#    > [CTRL + o]    - Ver el detalle de commit y navegar en sus paginas
#    > [ENTER]       - Copiar el hash del commit en portapapeles de windows
#    > [SHIFT + ↓/↑] - Cambio de pagina en la vista de preview
#
alias glogline='git log --color=always --format="%C(cyan)%h%Creset %C(blue)%ar%Creset%C(auto)%d%Creset %C(yellow)%s%+b %C(white)%ae%Creset" "$@"'
gll_hash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
gll_view1="$gll_hash | xargs git show --color=always | delta"
#gll_view2="$gll_hash | xargs git show --color=always"

glog() {
    #Obtener el directorio .git pero no imprimir su valor ni los errores
    git rev-parse --git-dir > /dev/null 2>&1
    #Si no es un repositorio valido salir
    if [ $? != 0 ]; then
        echo 'Invalid git repository'
        return 0
    fi

    #Mostrar los commit y su preview
    glogline | fzf -i -e --no-sort --reverse --tiebreak index --no-multi --ansi --preview "$gll_view1" \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" --bind "ctrl-o:execute:$gll_view1" \
        --header $'Use [CTRL + o] para ver detalle, [ENTER] para mostrar el hash del commit\n\n' | grep -o '[a-f0-9]\{7\}' 
}


################################################################################################
# K8S Functions
################################################################################################


