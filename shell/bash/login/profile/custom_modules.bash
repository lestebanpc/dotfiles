#!/bin/bash

[ -z "$g_repo_name" ] && g_repo_name='.files'

## Exportar modulo determinado
## shellcheck source=/home/lucianoepc/.files/shell/bash/lib/mod_general.bash
##source ~/${g_repo_name}/shell/bash/lib/mod_general.bash

# Mostrar la ayuda de un comando usando bat
bhelp() {

    if [ -z "$1" ]; then
        printf 'Ingrese el comando que muestra una ayuda para poder presentarlo.\n'
        return 1
    fi

    local l_paging='--paging=always'
    if [ "$2" = "0" ]; then
        l_paging='--paging=auto'
    fi

    $1 | bat -pl man $l_paging

}

# Wrapper que abre yazi y se mueve al ultimo directorio navegado
function y() {

    # Crea un un archivo temporal creeado como empieza 'yazi-cwd' seguido de 6 caracteres aleatorios (ejemplo: '/tmp/yazi-cwd.ABC123')
    # Luego lo almacena su ruta en la variable 'l_tmp'
    local l_tmp="$(mktemp -t "yazi-cwd.XXXXXX")"

    # Ejecuta el comando yazi, ignorando cualquier alias o función que también se llame yazi.
    # > '--cwd-file' cuando cierra yazi, escribe el 'working directory' actual de yazi en este archivo temporal ($tmp).
	command yazi "$@" --cwd-file="$l_tmp"

    # Leer el contenido del archivo temporal sin usar sepradores de lineas (campos), en modo raw y usando con delimitador el caracter nulo.
    # Luego escribir en la variable 'l_cwd'
    local l_cwd
	IFS= read -r -d '' l_cwd < "$l_tmp"

    # Si el 'working directory' no es vacio y no es diferente del actual, ejecuta el comando interno 'cd' (omite alias y funciones)
	[ -n "$l_cwd" ] && [ "$l_cwd" != "$PWD" ] && builtin cd -- "$l_cwd"

    # Elimina el archivo temporal
	rm -f -- "$l_tmp"
}
