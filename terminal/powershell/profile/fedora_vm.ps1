#------------------------------------------------------------------------------------------------
#Comando Oh-My-Posh
#------------------------------------------------------------------------------------------------

#$POSH_THEMES_PATH = "D:\Tools\Cmds\Common\config\oh-my-posh\themes"
oh-my-posh init pwsh --config ~/.files/terminal/oh-my-posh/lepc-montys.omp.json | Invoke-Expression

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
#Funciones basicas
#------------------------------------------------------------------------------------------------

. ~/.files/terminal/powershell/functions/func_basic_linux.ps1



