#------------------------------------------------------------------------------------------------
#Comando Oh-My-Posh
#------------------------------------------------------------------------------------------------

#$POSH_THEMES_PATH = "D:\Tools\Cmds\Common\config\oh-my-posh\themes"
oh-my-posh init pwsh --config "${env:USERPROFILE}\.files\terminal\oh-my-posh\lepc-montys.omp.json" | Invoke-Expression

#------------------------------------------------------------------------------------------------
#Comando FZF (fzf.exe)
#------------------------------------------------------------------------------------------------
#   > Colores por defecto para fzf (https://github.com/junegunn/fzf/wiki/Color-schemes)

$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --info=inline --border --margin=1 --padding=1 --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"
#$env:FZF_DEFAULT_COMMAND = 'fd -H --exclude .git'
#$env:FZF_DEFAULT_COMMAND = 'fd --type file'
#$env:FZF_DEFAULT_COMMAND = 'fd --type file --follow --hidden --exclude .git'
#$env:FZF_DEFAULT_COMMAND = "fd --type file --color=always"
#$env:FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND"

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


