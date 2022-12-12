################################################################################################
# GIT Functions
################################################################################################

#01. Search for commit with FZF preview and copy hash
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
#    > [CTRL + o]    - Ver el detalle de commit y navegar en sus paginas
#    > [ENTER]       - Copiar el hash del commit en portapapeles de windows
#    > [SHIFT + ↓/↑] - Cambio de pagina en la vista de preview
#
function glogline()
{
    #falta adicionar los argumentos variables, similar "$@" de bash
    git log --color=always --format="%C(cyan)%h%Creset %C(blue)%ar%Creset%C(auto)%d%Creset %C(yellow)%s%+b %C(white)%ae%Creset"
}

function glog()
{
    #Obtener el directorio .git pero no imprimir su valor ni los errores
    git rev-parse --git-dir > $null 2>&1
    #Si no es un repositorio valido salir
    if (! $?)
    {
        echo 'Invalid git repository'
        return
    }

    #El comando pwsh no se ejecuta en una terminal Powershell, si no la terminal nativo Bash,
    #Es decir: es un cadena powershell que se ejecutara en bash, no en powershell
    $gll_hash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
    $gll_view1="$gll_hash | xargs git show --color=always | delta"
    $gll_view2="$gll_hash | xargs git show --color=always"

    #Mostrar los commit y su preview
    glogline | fzf -i -e --no-sort --reverse --tiebreak index --no-multi --ansi --preview "$gll_view1" `
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" --bind "ctrl-o:execute:$gll_view2" `
        --header 'Use [CTRL + o] para ver detalle, [ENTER] imprimir el hash del commit' `
        --print-query | grep -o '[a-f0-9]\{7\}'
}



################################################################################################
# K8S Functions
################################################################################################


