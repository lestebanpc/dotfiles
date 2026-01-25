#------------------------------------------------------------------------------------------------
# Personalizacion de la terminal
#------------------------------------------------------------------------------------------------

# Cargar la información:
if(Test-Path "${HOME}/.config/powershell/custom_profile.ps1") {
    . "${HOME}/.config/powershell/custom_profile.ps1"
}

# Nombre del repositorio GIT o ruta relativa desde el HOME del repositorio GIT
if(-not ${g_repo_name}) {
    $g_repo_name= '.files'
}

if(-not ${g_tools_path}) {
    $g_tools_path='/var/opt/tools'
}

if(-not ${g_lnx_bin_path}) {
    $g_lnx_bin_path='/usr/local/bin'
}

# Tema por defecto de Oh-My-Posh:
if(-not ${g_prompt_theme}) {
    $g_prompt_theme= "${HOME}/${g_repo_name}/etc/oh-my-posh/default_settings.json"
}

$env:MY_REPO_PATH="${HOME}/${g_repo_name}"
$env:MY_TOOLS_PATH="$g_tools_path"


#------------------------------------------------------------------------------------------------
# Variable de entorno PATH
#------------------------------------------------------------------------------------------------

if (-not (${env:PATH} -like "*${HOME}/.local/bin*")) {

    $l_path = ${env:PATH}

    # Local bin path
    ${l_path}="${HOME}/.local/bin:${l_path}"

    # Custom local bin path
    if(${g_lnx_bin_path} -ne '/usr/local/bin' -and ${g_lnx_bin_path} -ne "${HOME}/.local/bin") {
        ${l_path}="${g_lnx_bin_path}:${l_path}"
    }
    Remove-Variable g_lnx_bin_path


    # Java - GraalVM (RTE y Herramientas de desarrollo para Java y otros)
    if (Test-Path -PathType Container -Path  "${g_tools_path}/graalvm" ) {

        $env:GRAALVM_HOME="${g_tools_path}/graalvm"

        #No adicionar para no perjudicar los programas del SO que corren usando el OpenJDK del SO
        #$env:JAVA_HOME="${g_tools_path}/graalvm"
        #$l_path="${l_path}:${g_tools_path}/graalvm/bin"

    }

    # Java - Jbang (scripting para java)
    if (Test-Path -PathType Container -Path  "${g_tools_path}/jbang/bin") {
        $l_path="${l_path}:${g_tools_path}/jbang/bin"
    }

    # Java - CLI tools creados por Java usando Jbang
    if (Test-Path -PathType Container -Path  "${HOME}/.jbang/bin" ) {
        $l_path="${l_path}:${HOME}/.jbang/bin"
    }

    # Java - Apache Maven (Builder para Java)
    if (Test-Path -PathType Container -Path  "${g_tools_path}/maven/bin" ) {
        $l_path="${g_tools_path}/maven/bin:${l_path}"
    }

    # Neovim path
    if (Test-Path -PathType Container -Path  "${g_tools_path}/neovim/bin" ) {
        $l_path="${l_path}:${g_tools_path}/neovim/bin"
    }

    # CMake - Sistema de contrucción para C/C++ y otros
    if (Test-Path -PathType Container -Path  "${g_tools_path}/cmake" ) {
        $l_path="${l_path}:${g_tools_path}/cmake/bin"
    }

    # Go - Tools estandar para desarrollo
    if (Test-Path -PathType Container -Path  "${g_tools_path}/go/bin" ) {
        $l_path="${l_path}:${g_tools_path}/go/bin"
    }

    # Go - CLI tools creados en Go
    if (Test-Path -PathType Container -Path  "${HOME}/go/bin" ) {
        $l_path="${l_path}:${HOME}/go/bin"
    }

    # Rust - Tools para desarrollo
    if (Test-Path -PathType Container -Path  "${g_tools_path}/rust/bin" ) {
        $l_path="${l_path}:${g_tools_path}/rust/bin"
    }

    # Go - CLI tools creados en Rust
    if (Test-Path -PathType Container -Path  "${HOME}/.cargo/bin" ) {
        $l_path="${l_path}:${HOME}/.cargo/bin"
    }

    # NodeJS - CLI tools creados en NodeJS y usando gestor de paquetes 'npm'
    if (Test-Path -PathType Container -Path  "${g_tools_path}/nodejs/bin" ) {
        $l_path="${g_tools_path}/nodejs/bin:${l_path}"
    }

    # DotNet
    if (Test-Path -PathType Container -Path  "${g_tools_path}/dotnet" ) {

        # Dotnet Path
        $env:DOTNET_ROOT="${g_tools_path}/dotnet"
        $l_path="${g_tools_path}/dotnet:${l_path}"

        # Dotnet - CLI tools creados en .NET (Global .NET tools)
        if (Test-Path -PathType Container -Path  "${g_tools_path}/dotnet/tools" ) {
            $l_path="${g_tools_path}/dotnet/tools:${l_path}"
        }

        # Para algunas distros en arm64, debe limitar la maxima de la memoria de heap GC: https://github.com/dotnet/runtime/issues/79612
        $env:DOTNET_GCHeapHardLimit= 0x1C0000000

    }

    # gRPC - Ruta del compilador de ProtoBuffer de gRPC
    if (Test-Path -PathType Container -Path  "${g_tools_path}/protoc/bin" ) {
        $l_path="${g_tools_path}/protoc/bin:${l_path}"
    }

    # AWS CLI v2
    if (Test-Path -PathType Container -Path  "${g_tools_path}/aws-cli/v2/current/bin" ) {
        $l_path="${g_tools_path}/aws-cli/v2/current/bin:${l_path}"
    }

    # CTags
    if (Test-Path -PathType Container -Path  "${g_tools_path}/ctags" ) {
        $l_path="${g_tools_path}/ctags/bin:${l_path}"
    }

    # Rutas por defecto: Exportar la variable de rutas por defecto para el usuario
    $env:PATH = $l_path
    Remove-Variable l_path
}

Remove-Variable g_tools_path


#------------------------------------------------------------------------------------------------
# Comando Oh-My-Posh
#------------------------------------------------------------------------------------------------

oh-my-posh init pwsh --config ${g_prompt_theme} | Invoke-Expression
Remove-Variable g_prompt_theme


#------------------------------------------------------------------------------------------------
# Comando FZF (fzf.exe)
#------------------------------------------------------------------------------------------------

if($null -eq $env:FZF_DEFAULT_OPTS) {

    $env:FZF_COMPLETION_PATH_OPTS="--walker=file,dir,hidden,follow"
    $env:FZF_COMPLETION_DIR_OPTS="--walker=dir,hidden,follow"

    $env:FZF_DEFAULT_OPTS="--height=80% --tmux=center,100%,80%
        --layout=reverse --walker-skip=.git,node_modules
        --info=inline --border
        --color=bg+:#293739,bg:#0F0F0F,border:#808080,spinner:#E6DB74,hl:#7E8E91,fg:#F8F8F2,header:#7E8E91,info:#A6E22E,pointer:#A6E22E,marker:#F92672,fg+:#F8F8F2,prompt:#F92672,hl+:#F92672"

    $env:FZF_CTRL_R_OPTS="--prompt 'History> '
        --preview 'echo {2..} | bat --color=always -pl sh'
        --preview-window up:3:hidden:wrap
        --bind 'ctrl-/:toggle-preview'
        --bind 'ctrl-t:track+clear-query'
        --bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
        --header '(Ctrl+/) Toggle preview, (Ctrl+t) Clear query, (Ctrl+y) Copy command'
        --color header:italic"

    $env:FZF_CTRL_T_OPTS="--prompt 'Select> '
        --bind 'ctrl-y:execute-silent(echo -n {} | wl-copy)+abort'
        --header '(Ctrl+y) Copy file/folder path'
        --preview 'if [ -d {} ]; then eza --tree --color=always --icons always -L 4 {} | head -n 300; else bat --color=always --style=numbers,header-filename,grid --line-range :500 {}; fi'"

    $env:FZF_ALT_C_OPTS="--prompt 'Go to Folder> '
        --bind 'ctrl-y:execute-silent(echo -n {} | wl-copy)+abort'
        --header '(Ctrl+y) Copy folder path'
        --preview 'eza --tree --color=always --icons always -L 4 {} | head -n 300'"

}

# Sobrescribir 'Ctrl+t' y 'Ctrl+r' para usar FZF para el listado de archivos y el historial.
# Requiere tener instalado el modulo 'PSFzf' ("Install-Module -Name PSFzf -Scope AllUsers").
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'


#------------------------------------------------------------------------------------------------
# Comando Zoxide (zoxide.exe)
#------------------------------------------------------------------------------------------------

if($null -eq $env:_ZO_FZF_OPTS) {

    # Personalizar el uso comando 'zi'
    $env:_ZO_FZF_OPTS="${env:FZF_DEFAULT_OPTS} --prompt 'Go to Folder> ' --preview 'eza --tree --color=always --icons always -L 4 {2} | head -n 300' --preview-window=down,70%"

}

# Inicializacion de zoxide: crea el alias del comando 'zi' y 'z'
Invoke-Expression (& { (zoxide init powershell | Out-String) })


#------------------------------------------------------------------------------------------------
# Otras variable de entorno
#------------------------------------------------------------------------------------------------

# Editor por defecto usando por programas como Yazi, Oh-my-tmux, etc.
if($null -eq $env:EDITOR) {
    $env:EDITOR="vim"
}

# Editor por defecto para "systemctl edit"
if($null -eq $env:SYSTEMD_EDITOR) {
    $env:SYSTEMD_EDITOR="vim"
}

# MPD> Para cliente CLI de MPD se conecten al servidor MPD usando Socket IPC
if($null -eq $env:MPD_HOST) {
    $env:MPD_HOST="/run/mpd/socket"
}


#------------------------------------------------------------------------------------------------
# Personalizacion de la terminal
#------------------------------------------------------------------------------------------------

# Cambiar el color de los folderes
#PSStyle.FileInfo.Directory="`e[44;1m"
$PSStyle.FileInfo.Directory="`e[44;30m"


#------------------------------------------------------------------------------------------------
# Funciones personalizado del usuario
#------------------------------------------------------------------------------------------------

. "${HOME}/${g_repo_name}/shell/powershell/login/linuxprofile/custom_modules.ps1"
