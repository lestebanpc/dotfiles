#------------------------------------------------------------------------------------------------
# Personalizacion de la terminal
#------------------------------------------------------------------------------------------------

# Cargar la información:
if(Test-Path "${env:USERPROFILE}/config.ps1") {
    . "${env:USERPROFILE}/config.ps1"
}

# Nombre del repositorio GIT o ruta relativa desde el HOME del repositorio GIT
if(-not ${g_repo_name}) {
    $g_repo_name= '.files'
}

# Tema por defecto de Oh-My-Posh:
if((-not ${g_prompt_theme}) -or (Test-Path "$g_prompt_theme")) {
    $g_prompt_theme= "${env:USERPROFILE}/${g_repo_name}/etc/oh-my-posh/lepc-montys-1.omp.json"
}

# Ruta del folder base donde estan los subfolderes del los programas (1 o mas comandos y otros archivos).
if((-not ${g_programs_path}) -or (Test-Path "$g_programs_path")) {
    $g_programs_path= 'C:\cli\prgs'
}

# Ruta del folder donde se ubican comandos personalizado del usuario.
if((-not ${g_bin_cmdpath}) -or (Test-Path "$g_bin_cmdpath")) {
    $g_bin_cmdpath= 'C:\cli\cmds\bin'
}


#------------------------------------------------------------------------------------------------
# Variable de entorno PATH
#------------------------------------------------------------------------------------------------

#Si path no contiene la ruta de comandos, adicionarlos.
if(-not ("$env:PATH" -match ";?$($g_bin_cmdpath.Replace("\", "\\"));?")) {
    $env:PATH= "${g_bin_cmdpath};${env:PATH}"
}

#Establecer los otros valores ...


#------------------------------------------------------------------------------------------------
# Personalizacion de la terminal
#------------------------------------------------------------------------------------------------

# Cambiar el color de los folderes
#PSStyle.FileInfo.Directory="`e[44;1m"
$PSStyle.FileInfo.Directory="`e[44;30m"


#------------------------------------------------------------------------------------------------
#Comando Oh-My-Posh
#------------------------------------------------------------------------------------------------

oh-my-posh init pwsh --config "${g_prompt_theme}" | Invoke-Expression


#------------------------------------------------------------------------------------------------
#Comando FZF (fzf.exe)
#------------------------------------------------------------------------------------------------

$env:FZF_COMPLETION_PATH_OPTS = "--walker=file,dir,hidden,follow"
$env:FZF_COMPLETION_DIR_OPTS  = "--walker=dir,hidden,follow"

$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --walker-skip=.git,node_modules --info=inline --border --color=bg+:#293739,bg:#1B1D1E,border:#808080,spinner:#E6DB74,hl:#7E8E91,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672"
#$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --info=inline --border --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"

$env:FZF_CTRL_T_COMMAND  = "fd -H -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
$env:FZF_ALT_C_COMMAND   = "fd -H -t d -E '.git' -E 'node_modules'"

$env:FZF_CTRL_R_OPTS = "--prompt 'History> '"
$env:FZF_CTRL_T_OPTS = "--prompt 'Select> ' --preview 'if exist {}\ ( eza --tree --color=always --icons always -L 5 {} ) else ( bat --color=always --style=numbers,header-filename,grid --line-range :500 {} )'"
$env:FZF_ALT_C_OPTS  = "--prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {}'"

#Sobrescribir 'Ctrl+t' y 'Ctrl+r' para usar FZF para el listado de archivos y el historial.
#Requiere tener instalado el modulo 'PSFzf' ("Install-Module -Name PSFzf -Scope AllUsers").
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'


#------------------------------------------------------------------------------------------------
#Comando Zoxide (zoxide.exe)
#------------------------------------------------------------------------------------------------

#Personalizar el uso comando 'zi'
$env:_ZO_FZF_OPTS="${env:FZF_DEFAULT_OPTS} --prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {2}' --preview-window=down,70%"

#Inicializacion de zoxide: crea el alias del comando 'zi' y 'z'
Invoke-Expression (& { (zoxide init powershell | Out-String) })


#------------------------------------------------------------------------------------------------
#Funciones personalizadas del usuario
#------------------------------------------------------------------------------------------------

. "${env:USERPROFILE}\${g_repo_name}\shell\powershell\login\windowsprofile\custom_profile_modules.ps1"



