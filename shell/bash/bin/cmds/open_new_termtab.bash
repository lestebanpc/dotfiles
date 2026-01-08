#!/bin/bash

# Constantes

#Colores principales usados
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"




_usage() {

    cat <<EOF
Usage: tmux_new_tabterm [options] folder_or_file

> Crea una nueva ventana/ta en la terminar actual donde el directorio de trabajo es el folder enviado como argumento (si el arugmento es un archivo se considera folder donde esta el archivo).
> Actualmente solo esta soportoadp para los emuladores de terminal:
  > Si usa el multiplexor tmux, independendiente del emulador de terminal donde lo ejecute
  > Si no usa un multiplexor de terminal, solo se soporta las siguientes emuladores de terminal:
    > WezTerm

Ejemplos:

  $ tmux_new_tabterm ../
  $ tmux_new_tabterm /home/lucianoepc/code
  $ tmux_new_tabterm /home/lucianoepc/code/mynote.txt

Options:
 -c           Limpiar el contenido de la ventana despues de ser creado.
 -d           La ventana/tab creada se estable en el activo. Si no se especifica la ventana creada/tab no es el activo.
 -o           Si es un archivo abre el archivo con el editor \$EDITOR.

Arguments
 <file_or_folder> Ruta del folder.
EOF

}



# -------------------------------------------------------------------------------------
# Main code
# -------------------------------------------------------------------------------------

# Funcion principal de entrada
main() {

    #0. Validaciones previas
    if ! command -v realpath >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "realpath" instalado.\n' "$g_color_red1" "$g_color_reset"
        return 1
    fi

    #1. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local p_flag_set_active=1
    local p_flag_clean=1
    local p_flag_openfile_on_editor=1
    #echo "Init ${@}" >> /tmp/remove.txt

    while [ $# -gt 0 ]; do

        case "$1" in

            -h)
                _usage
                return 0
                ;;

            #-h)
            #    if ! [[ "$2" =~ ^[0-9]+$ ]]; then
            #        printf '[%bERROR%b] Valor de la opción "%b%s%b" es invalida: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
            #               "$g_color_gray1" "-h" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
            #        _usage
            #        return 1
            #    fi

            #    if [ $2 -le 10 ] && [ $2 -ge 90 ]; then
            #        printf '[%bERROR%b] Valor de la opción "%b%s%b" debe esta [10, 90]: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
            #               "$g_color_gray1" "-h" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
            #        _usage
            #        return 1
            #    fi

            #    p_hight=$2
            #    shift 2
            #    ;;

            -d)
                p_flag_set_active=0
                shift
                ;;


            -o)
                p_flag_openfile_on_editor=0
                shift
                ;;

            -c)
                p_flag_clean=0
                shift
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                _usage
                return 1
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done
    #echo "Setp 0 ${1}" >> /tmp/remove.txt

    #2. Leer los argumentos
    if [ -z "$1" ]; then
        printf '[%bERROR%b] Debe especificar como argumento la ruta de un folder o archivo.\n' "$g_color_red1" "$g_color_reset"
        return 1
    fi

    # Si es una ruta absoluta que inicia con '~', expandierlo
    local p_full_path="$1"
    #if [[ "$p_full_path" == "~"* ]]; then
    #    p_full_path="$HOME/${p_full_path#~/}"
    #fi

    # Obtener la ruta real
    if ! p_full_path=$(realpath -m "$p_full_path" 2> /dev/null); then
        printf '[%bERROR%b] El argumento "%b%s%b" no es la ruta de un folder/archivo valido.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$1" "$g_color_reset"
        return 1
    fi
    #echo "Step 1 ${p_full_path}" >> /tmp/remove.txt

    #3. Determinar si es folder o archivo
    local l_is_folder=1
    if [ -d "$p_full_path" ]; then
        l_is_folder=0
    elif [ ! -f "$p_full_path" ]; then

        printf '[%bERROR%b] El argumento "%b%s%b" no es la ruta de un folder ni un archivo.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$p_full_path" "$g_color_reset"
        return 1

    fi


    #4. Determinar el working dir
    local l_working_dir="$p_full_path"
    if [ $l_is_folder -ne 0 ]; then
        l_working_dir="${p_full_path%/*}"
    fi
    #echo "Step 2 ${p_full_path}" >> /tmp/remove.txt


    #5. Si esta dentro del multiplexor tmux
    if [ ! -z "$TMUX" ]; then

        # Crear una ventana en la sesion actual
        tmux new-window -c "$l_working_dir"
        return 0

    fi


    #6. Si es un emulador de terminal Wezterm
    if [ ! -z "$WEZTERM_UNIX_SOCKET" ] && [ "$TERM_PROGRAM" = "WezTerm" ]; then

        # Crear un nuevo tab en el workspace actual del domunio actual
        wezterm cli spawn --cwd "$l_working_dir"
        return 0

    fi


    #7. Cualquier otro caso (no hacer nada)
    return 0

}


# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $g_result
