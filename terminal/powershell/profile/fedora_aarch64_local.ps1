#------------------------------------------------------------------------------------------------
#Comando Oh-My-Posh
#------------------------------------------------------------------------------------------------

oh-my-posh init pwsh --config ~/.files/terminal/oh-my-posh/lepc-montys-1.omp.json | Invoke-Expression

#------------------------------------------------------------------------------------------------
#Comando FZF (fzf.exe)
#------------------------------------------------------------------------------------------------

$env:FZF_COMPLETION_PATH_OPTS = "--walker=file,dir,hidden,follow"
$env:FZF_COMPLETION_DIR_OPTS  = "--walker=dir,hidden,follow"

$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --walker-skip=.git,node_modules --info=inline --border --color=bg+:#293739,bg:#1B1D1E,border:#808080,spinner:#E6DB74,hl:#7E8E91,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672"
#$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --info=inline --border --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"

$env:FZF_CTRL_R_OPTS = "--prompt 'History> '"
$env:FZF_CTRL_T_OPTS = "--prompt 'Select> ' --preview 'if [ -d {} ]; then eza --tree --color=always --icons always -L 5 {} | head -n 300; else bat --color=always --style=numbers,header-filename,grid --line-range :500 {}; fi'"
$env:FZF_ALT_C_OPTS  = "--prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {} | head -n 300'"

#$env:FZF_CTRL_T_COMMAND  = "fd -H -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
#$env:FZF_ALT_C_COMMAND   = "fd -H -t d -E '.git' -E 'node_modules'"

#Sobrescribir 'Ctrl+t' y 'Ctrl+r' para usar FZF para el listado de archivos y el historial.
#Requiere tener instalado el modulo 'PSFzf' ("Install-Module -Name PSFzf -Scope AllUsers").
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'



#------------------------------------------------------------------------------------------------
#Comando Zoxide (zoxide.exe)
#------------------------------------------------------------------------------------------------

#Personalizar el uso comando 'zi'
$env:_ZO_FZF_OPTS="${env:FZF_DEFAULT_OPTS} --prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {2} | head -n 300' --preview-window=down,70%"

#Inicializacion de zoxide: crea el alias del comando 'zi' y 'z'
Invoke-Expression (& { (zoxide init powershell | Out-String) })


#------------------------------------------------------------------------------------------------
#Funciones basicas
#------------------------------------------------------------------------------------------------

. ~/.files/terminal/powershell/functions/func_custom_lnx.ps1



