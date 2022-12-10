#------------------------------------------------------------------------------------------------
#Function: Search for commit with FZF preview and copy hash
#------------------------------------------------------------------------------------------------
#  > [ENTER]           - Ver el detalle de commit y navegar en sus paginas
#  > [CTRL + Y]        - Copiar el hash del commit en portapapeles de windows
#  > [SHIFT + UP/DOWN] - Cambio de pagino en la vista de preview

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

        $gll_view1="pwsh -noprofile -command ""git show --color=always ""'{}'.Substring(0,7)"""" | delta"
        $gll_view2="pwsh -noprofile -command ""git show --color=always ""'{}'.Substring(0,7)"""""
    $gll_paste="pwsh -noprofile -command ""Set-Clipboard -Value ""'{}'.Substring(0,7)"""""

    #Mostrar los commit y su preview
    glogline | fzf -i -e --no-sort --reverse --tiebreak index --no-multi --ansi --preview "$gll_view1" `
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" --bind "enter:execute:$gll_view2" `
        --bind "ctrl-y:execute-silent:$gll_paste"
}



