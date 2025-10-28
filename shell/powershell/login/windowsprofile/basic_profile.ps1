#------------------------------------------------------------------------------------------------
# Variables globales basicas
#------------------------------------------------------------------------------------------------

# Nombre del repositorio git o la ruta relativa del repositorio git respecto al HOME.
$g_repo_name= '.files'

# Folder base donde se almacena los subfolderes de los programas.
$g_tools_path= 'D:\apps\tools'
#$g_tools_path= 'C:\apps\tools'

# Folder donde se almacena los binarios de tipo comando.
$g_bin_path='D:\apps\cmds\bin'
#$g_bin_path='C:\apps\cmds\bin'

# Ruta del tema de 'Oh-My-Posh' usada para establecer el prompt a usar.
$g_prompt_theme= "${env:USERPROFILE}\${g_repo_name}\etc\oh-my-posh\default_settings.json"
#$g_prompt_theme= "${env:USERPROFILE}\${g_repo_name}\etc\oh-my-posh\lepc-montys-green1.json"


#------------------------------------------------------------------------------------------------
# Variable de entorno PATH
#------------------------------------------------------------------------------------------------

# Si path no contiene la ruta de comandos, adicionarlos.
if(-not ("$env:PATH" -match ";?$($g_bin_path.Replace("\", "\\"));?")) {
    $env:PATH= "${g_bin_path};${env:PATH}"
}

# Binarios de compresor 7zip
if(Test-Path "C:\Program Files\7-Zip") {
    $env:PATH= "C:\Program Files\7-Zip;${env:PATH}"
}

# Binarios de CTags
if(Test-Path "${g_tools_path}\ctags\bin") {
    $env:PATH= "${g_tools_path}\ctags\bin;${env:PATH}"
}

# Binarios de compresor 7zip
if(Test-Path "C:\Program Files\7-Zip") {
    $env:PATH= "C:\Program Files\7-Zip;${env:PATH}"
}

# Binarios de Git
if(Test-Path "${g_tools_path}\git\cmd") {
    $env:PATH= "${g_tools_path}\git\cmd;${env:PATH}"
}

# Binario de NeoVIM
if(Test-Path "${g_tools_path}\neovim\bin") {
    $env:PATH= "${g_tools_path}\neovim\bin;${env:PATH}"
}

# Binario de VIM
if(Test-Path "${g_tools_path}\vim") {
    $env:PATH= "${g_tools_path}\vim;${env:PATH}"
}

# Binario de Node.JS
if(Test-Path "${g_tools_path}\node") {
    $env:PATH= "${g_tools_path}\node;${env:PATH}"
}

# Binario de Python3
if(Test-Path "${g_tools_path}\python3") {
    $env:PATH= "${g_tools_path}\python3;${env:PATH}"
}

# Binario de MinGW-64
if(Test-Path "${g_tools_path}\mingw64\bin") {
    $env:PATH= "${env:PATH};${g_tools_path}\mingw64\bin"
}

# Binario de LLVM y Clang
#if(Test-Path "${g_tools_path}\llvm\bin") {
#    $env:PATH= "${g_tools_path}\llvm\bin;${env:PATH}"
#}


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

$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --walker-skip=.git,node_modules --info=inline --border --color=bg+:#293739,bg:#0F0F0F,border:#808080,spinner:#E6DB74,hl:#7E8E91,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672"
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

. "${env:USERPROFILE}\${g_repo_name}\shell\powershell\login\windowsprofile\custom_modules.ps1"
