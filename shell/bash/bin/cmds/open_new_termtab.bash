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
Usage: open_new_termtab [options] folder_or_file

> Crea una nueva ventana/tab en la terminar actual
  > El directorio de trabajo usado por la nueva ventana/panel es:
    > Si el argumento es un folder, el directorio de trabajo siempre es este folder.
    > Si el argumento es un archivo:
      > Si se especifica la opcion '-w', es el diferectorio de trabajo sera el folder donde esta el archivo.
      > Si no se especifca la opcion '-w', se usara el directorio por defecto del proceso padre actual.
> Los emuladores de terminal soportados son:
  > Si usa el multiplexor tmux, independendiente del emulador de terminal donde lo ejecute
  > Si no usa un multiplexor de terminal, solo se soporta las siguientes emuladores de terminal:
    > WezTerm

Ejemplos:

  $ open_new_termtab ../
  $ epen_new_termtab /home/lucianoepc/code
  $ open_new_termtab /home/lucianoepc/code/mynote.txt
  $ open_new_termtab -e /home/lucianoepc/code/mynote.txt

Options:
 -e     Si es un archivo, si es un archivo de texto lo abre con el editor \$EDITOR, si es binario muestra la informacion del archivo.
 -w     Si es un archivo, el nuevo tab se usara como directorio de trabajo el directorio por defecto.
        Si no se especifica (y es un archivo) se usara como diferectorio de trabajo el folder padre donde se ubica el archivo.

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
    local p_flag_use_default_working_dir=1
    local p_flag_show_infofile=1
    #echo "Init ${@}" >> /tmp/remove.txt

    while [ $# -gt 0 ]; do

        case "$1" in

            -h)
                _usage
                return 0
                ;;

            -w)
                p_flag_use_default_working_dir=0
                shift
                ;;


            -e)
                p_flag_show_infofile=0
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


    #4. Determinar datos requeridos para los archivos
    local l_parent_dir="$p_full_path"
    local l_file_path=''
    local l_is_text_file=1
    local l_data=""

    if [ $l_is_folder -ne 0 ]; then

        l_parent_dir="${p_full_path%/*}"

        # Determinar si el archivos es un archivo de texto o empty
        if [ $p_flag_show_infofile -eq 0 ]; then

            # Determinar el tipo MIME del archivo
            l_data=$(file -i "$p_full_path")
            if [[ "$l_data" == *"text/"* ]]; then
                l_is_text_file=0
            elif [[ "$l_data" == *"application/json"* ]]; then
                l_is_text_file=0
            elif [[ "$l_data" == *"inode/x-empty"* ]]; then
                l_is_text_file=0
            fi

            # Obtener el nombre y/o ruta del archivo a usar
            if [ $p_flag_use_default_working_dir -ne 0 ]; then

                # Usar solo el nombre del archivo
                l_file_path="${p_full_path##*/}"

            else

                # Usar la ruta completa del archivo
                l_file_path="$p_full_path"

            fi

        fi

    fi
    #echo "Step 2 ${p_full_path}" >> /tmp/remove.txt


    #5. Si esta dentro del multiplexor tmux
    local l_position=''
    if [ ! -z "$TMUX" ]; then

        # Obtener el directorio de trabajo del panel actual
        if [ $p_flag_use_default_working_dir -eq 0 ]; then
            l_parent_dir=$(tmux display-message -p "#{pane_current_path}")
        fi

        # Crear una ventana en la sesion actual
        l_position=$(tmux new-window -c "$l_parent_dir"  -PF "#{window_id}.#{pane_id}")
        if [ -z "$l_position" ]; then
            return 2
        fi

        # Si es un archivo
        if [ $l_is_folder -ne 0 ]; then


            # Limpiar la pantalla
            tmux send-keys -t "${l_position}" 'clear' Enter

            # Solo escribir el comandos en el prompt de panel creado
            if [ $l_is_text_file -eq 0 ]; then
                tmux send-keys -lt "${l_position}" "${EDITOR:-vim} \"$l_file_path\""
            else
                tmux send-keys -lt "${l_position}" "file \"$l_file_path\""
            fi

            # Ejecutar el comando enviado
            tmux send-keys -t "${l_position}" Enter

        fi

        return 0

    fi


    #6. Si es un emulador de terminal Wezterm
    if [ ! -z "$WEZTERM_UNIX_SOCKET" ] && [ "$TERM_PROGRAM" = "WezTerm" ]; then

        # Obtener el directorio de trabajo del panel actual
        if [ $p_flag_use_default_working_dir -eq 0 ]; then

            l_data=$(wezterm cli list --format json | jq -r --arg pid "$WEZTERM_PANE" '.[] | select(.pane_id == ($pid | tonumber)) | .cwd')
            if [ -z "$l_data" ]; then
                return 2
            fi

            l_parent_dir=$(echo "$l_data" | sed -E 's|^[^:]+://[^/]+||')

        fi

        # Crear un nuevo tab en el workspace actual del domunio actual
        l_position=$(wezterm cli spawn --cwd "$l_parent_dir" 2>/dev/null)
        if [ -z "$l_position" ]; then
            return 2
        fi

        # Si es un archivo
        if [ $l_is_folder -ne 0 ]; then

            # Escribir el comandos en el prompt de panel creado y ejecutar escribiendo el finde linea
            if [ $l_is_text_file -eq 0 ]; then
                wezterm cli send-text --pane-id "$l_position" --no-paste "${EDITOR:-vim} \"$l_file_path\""$'\n'
            else
                wezterm cli send-text --pane-id "$l_position" --no-paste "file \"$l_file_path\""$'\n'
            fi

        fi

        return 0

    fi


    #7. Cualquier otro caso (no hacer nada)
    return 0

}


# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $g_result
