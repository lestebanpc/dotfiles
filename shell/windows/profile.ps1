#Import-Module -Name Terminal-Icons

#Oh-My-Posh
$POSH_PATH="D:\Tools\Cmds\Windows\oh-my-posh"
$POSH_THEMES_PATH = Join-Path -Path $POSH_PATH -ChildPath "themes"
$env:PATH = $POSH_PATH + [System.IO.Path]::PathSeparator + $env:PATH
oh-my-posh init pwsh --config "$POSH_THEMES_PATH\lepc-montys.omp.json" | Invoke-Expression

#Comando FZF (fzf.exe)
#Colores por defecto para fzf (https://github.com/junegunn/fzf/wiki/Color-schemes)
$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --info=inline --border --margin=1 --padding=1 --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"
#$env:FZF_DEFAULT_COMMAND = 'fd -H --exclude .git'
$env:FZF_DEFAULT_COMMAND = 'fd --type file'
#$env:FZF_DEFAULT_COMMAND = 'fd --type file --follow --hidden --exclude .git'
#$env:FZF_DEFAULT_COMMAND = "fd --type file --color=always"
#$env:FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND"

#Modulo de ayuda de FZF (requiere el comando fzf.exe)
Import-Module PSFzf
# Replace 'Ctrl+t' (Reverse Search) and 'Ctrl+r' (History) with your preferred bindings:
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
# Selected Directory (use $Location with a different command, by defualt is Set-Location)
$commandOverride = [ScriptBlock]{ param($Location) Write-Host $Location }
Set-PsFzfOption -AltCCommand $commandOverride
# Override default tab completion
#Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
