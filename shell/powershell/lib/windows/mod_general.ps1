################################################################################################
# GIT Functions
################################################################################################

#01. Search for commit with FZF preview and copy hash
#. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
#    > [CTRL + y]    - Ver el detalle de commit y navegar en sus paginas
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

    #El comando pwsh no se ejecuta en la terminal Powershell, si no la terminal nativo CMD
    $gll_view1="pwsh -noprofile -command ""git show --color=always ""'{}'.Substring(0,7)"""" | delta"
    $gll_view2="pwsh -noprofile -command ""git show --color=always ""'{}'.Substring(0,7)"""""
    #$gll_paste="pwsh -noprofile -command ""Set-Clipboard -Value ""'{}'.Substring(0,7)"""""

    #Mostrar los commit y su preview
    glogline | fzf -i -e --no-sort --reverse --tiebreak index -m --ansi --preview "$gll_view1" `
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" --bind "ctrl-y:execute:$gll_view2" `
        --header 'Use [CTRL + y] para ver detalle, [ENTER] imprimir el hash del commit' `
        --print-query
}


################################################################################################
# K8S Functions
################################################################################################



################################################################################################
# Others Functions
################################################################################################

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
