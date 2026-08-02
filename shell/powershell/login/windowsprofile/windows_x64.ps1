#------------------------------------------------------------------------------------------------
# Personalizacion de la terminal
#------------------------------------------------------------------------------------------------

# Cargar parametros iniciales del profile
if(Test-Path "${env:USERPROFILE}/initial_profile.ps1") {
    . "${env:USERPROFILE}/initial_profile.ps1"
}

# Nombre del repositorio GIT o ruta relativa desde el HOME del repositorio GIT
if(-not ${g_repo_name}) {
    $g_repo_name= '.files'
}

# Tema por defecto de Oh-My-Posh:
if((-not ${g_prompt_theme}) -or (Test-Path "$g_prompt_theme")) {
    $g_prompt_theme= "${env:USERPROFILE}/${g_repo_name}/etc/cli/oh-my-posh/default_settings.json"
}

# Ruta del folder base donde estan los subfolderes del los programas (1 o mas comandos y otros archivos).
if((-not ${g_tools_path}) -or (Test-Path "$g_tools_path")) {
    $g_tools_path= 'C:\apps\tools'
}

# Ruta del folder donde se ubican comandos personalizado del usuario.
if((-not ${g_bin_path}) -or (Test-Path "$g_bin_path")) {
    $g_bin_path= 'C:\apps\cmds\bin'
}


#------------------------------------------------------------------------------------------------
# Variable de entorno PATH
#------------------------------------------------------------------------------------------------

# Si path no contiene la ruta de comandos, adicionarlos.
if(-not ("$env:PATH" -match ";?$($g_bin_path.Replace("\", "\\"));?")) {
    $env:PATH= "${g_bin_path};${env:PATH}"
}

# Establecer los otros valores ...:


#------------------------------------------------------------------------------------------------
# Personalizacion de la terminal
#------------------------------------------------------------------------------------------------

# Cambiar el color de los folderes
#PSStyle.FileInfo.Directory="`e[44;1m"
$PSStyle.FileInfo.Directory="`e[44;30m"


#------------------------------------------------------------------------------------------------
# Comando Oh-My-Posh
#------------------------------------------------------------------------------------------------

oh-my-posh init pwsh --config "${g_prompt_theme}" | Invoke-Expression


#------------------------------------------------------------------------------------------------
# Comando FZF (fzf.exe)
#------------------------------------------------------------------------------------------------

$env:FZF_COMPLETION_PATH_OPTS = "--walker=file,dir,hidden,follow"
$env:FZF_COMPLETION_DIR_OPTS  = "--walker=dir,hidden,follow"

$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --walker-skip=.git,node_modules --info=inline --border --color=bg+:#293739,bg:#0F0F0F,border:#808080,spinner:#E6DB74,hl:#7E8E91,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672"
#$env:FZF_DEFAULT_OPTS = "--height=80% --layout=reverse --info=inline --border --color fg:242,bg:233,hl:65,fg+:15,bg+:234,hl+:108 --color info:108,prompt:109,spinner:108,pointer:168,marker:168"

$env:FZF_CTRL_T_COMMAND  = "fd -H -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"
$env:FZF_ALT_C_COMMAND   = "fd -H -t d -E '.git' -E 'node_modules'"

$env:FZF_CTRL_R_OPTS = "--prompt 'History> '"
$env:FZF_CTRL_T_OPTS = "--prompt 'Select> ' --preview 'if exist {}\ ( eza --tree --color=always --icons always -L 5 {} ) else ( bat --color=always --style=numbers,header-filename --line-range :500 {} )'"
$env:FZF_ALT_C_OPTS  = "--prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {}'"

# Sobrescribir 'Ctrl+t' y 'Ctrl+r' para usar FZF para el listado de archivos y el historial.
# Requiere tener instalado el modulo 'PSFzf' ("Install-Module -Name PSFzf -Scope AllUsers").
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'


#------------------------------------------------------------------------------------------------
# Comando Zoxide (zoxide.exe)
#------------------------------------------------------------------------------------------------

# Personalizar el uso comando 'zi'
$env:_ZO_FZF_OPTS="${env:FZF_DEFAULT_OPTS} --prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 5 {2}' --preview-window=down,70%"

# Inicializacion de zoxide: crea el alias del comando 'zi' y 'z'
Invoke-Expression (& { (zoxide init powershell | Out-String) })


#------------------------------------------------------------------------------------------------
# Comando> Yazi (yazi.exe)
#------------------------------------------------------------------------------------------------

# Wrapper que abre yazi y se mueve al ultimo directorio navegado
function y {

    # Crea un un archivo temporal creeado y luego lo almacena su ruta en la variable 'l_tmp'
    $tmp = (New-TemporaryFile).FullName

    # Ejecuta el comando yazi, ignorando cualquier alias o función que también se llame yazi.
    # > '--cwd-file' cuando cierra yazi, escribe el 'working directory' actual de yazi en este archivo temporal ($tmp).
    yazi.exe $args --cwd-file="$tmp"

    # Leer el contenido de archivo temporal y lo almacena en '$cwd'
    $cwd = Get-Content -Path $tmp -Encoding UTF8

    # Si el 'working directory' no es vacio y no es diferente del actual, ejecuta el comando interno 'cd' (omite alias y funciones)
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }

    # Elimina el archivo temporal
    Remove-Item -Path $tmp
}


#------------------------------------------------------------------------------------------------
# Personalizacion del profile
#------------------------------------------------------------------------------------------------

# Carga de logica personalizada del profile
if(Test-Path "${env:USERPROFILE}/custom_profile.ps1") {
    . "${env:USERPROFILE}/custom_profile.ps1"
}
