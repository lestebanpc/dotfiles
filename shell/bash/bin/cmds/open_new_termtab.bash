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
    > Si el 1er argumento es un folder, el directorio de trabajo siempre es este folder, los demas argumentos se omitiran.
    > Si el 1er argumento es un archivo, depende del valor de la opcion '-w' o la opcion '-p'.
> Los emuladores de terminal soportados son:
  > Si usa el multiplexor tmux, independendiente del emulador de terminal donde lo ejecute
  > Si no usa un multiplexor de terminal, solo se soporta las siguientes emuladores de terminal:
    > WezTerm

Ejemplos:

  $ open_new_termtab ../
  $ epen_new_termtab /home/lucianoepc/code
  $ open_new_termtab /home/lucianoepc/code/mynote.txt
  $ open_new_termtab -e /home/lucianoepc/code/mynote.txt

Opciones que solo se consideran si el 1er argumento es un archivo:
 -f         Si el 1er archivo es un archivo de texto lo abre con el editor '\$EDITOR', si es binario muestra la informacion usando 'file'.
            > Los argumentos que son folderes se omiten.

 -p         Si el directorio de trabajo para crear el nuevo tab es el folder padre donde esta el 1er archivo.
            > Los argumentos que son folderes se omiten.

 -w wordir  El valor de esta opcion se usara como directorio de trabajo del nuevo tab.
            Si se especifica tanto esta opcion como la opcion '-p', esta opcion tendra mayor prioridad.

Argumentos son:
 <file_or_folder>
   > Ruta del archivos y/o folderes.

EOF

}


# Retorna 0 si es un archivo de texto. Si es binario retorna 1.
m_is_text_file() {

    local p_full_path="$1"

    local l_data=''
    local l_is_text_file=1

    # Determinar el tipo MIME del archivo
    l_data=$(file -i "$p_full_path")
    if [[ "$l_data" == *"text/"* ]]; then
        l_is_text_file=0
    elif [[ "$l_data" == *"application/json"* ]]; then
        l_is_text_file=0
    elif [[ "$l_data" == *"inode/x-empty"* ]]; then
        l_is_text_file=0
    fi

    return $l_is_text_file

}


# > Valor de retorno:
#   (0) si es un folder.
#   (1) si son archivos sin formato.
#   (2) si son archivos de texto.
#   (3) si son archivos binarios.
#   (n) Cualquier otro valor es un error.
m_get_fullpath_files() {

    #1. Argumentos
    local -r ra_files_in="$1"
    local -r ra_files_out="$2"
    local p_flag_show_infofile=$3

    #2. Obtener la lista de archivos o el folder
    local l_i=0
    local l_j=0
    local l_item=''
    local l_full_path=''
    local l_is_folder=1
    local l_first_is_text_file=1
    local l_is_text_file=1

    for (( l_i = 0; l_i < ${#ra_files_in[@]}; g_i++ )); do

        l_item="${ra_files_in[$l_i]}"

        # Expandir la ruta relativa (y/o enlaces simbolicos) en rutas absolutas
        if ! l_full_path=$(realpath -m "$l_item" 2> /dev/null); then
            printf '[%bERROR%b] El argumento "%b%s%b" no es la ruta de un folder/archivo valido.\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$l_item" "$g_color_reset"
            return 4
        fi

        # Validar si el archivo existe
        l_is_folder=1
        if [ -d "$l_full_path" ]; then
            l_is_folder=0
        elif [ ! -f "$l_full_path" ]; then
            printf '[%bERROR%b] El argumento "%b%s%b" no es la ruta de un folder ni un archivo.\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$l_full_path" "$g_color_reset"
            return 5
        fi

        # Si el 1er argumento
        if [ $l_i -eq 0 ]; then

            # Si es un archivo, registrar su ruta absoluta
            ra_files_out[$l_j]="$l_full_path"
            ((l_j++))

            # Si es folder, no analizar otros argumentos
            if [ $l_is_folder -eq 0 ]; then
                return 0
            fi

            if [ $p_flag_show_infofile -eq 0 ]; then
                m_is_text_file "$l_full_path"
                l_first_is_text_file=$?
            fi

            continue

        fi

        # Si no es el 1er argumento (pero el 1ro argumento es archivo)

        # Filtar los que son folderes
        if [ $l_is_folder -eq 0 ]; then
            continue
        fi

        # Filtrar solo los archivos del mismo tipo
        if [ $p_flag_show_infofile -eq 0 ]; then

            m_is_text_file "$l_full_path"
            l_is_text_file=$?

            # Si no es el tipo de archivo, omitirlo
            if [ $l_first_is_text_file -ne $l_is_text_file ]; then
                continue
            fi

        fi

        # Si es del mismo tipo que el 1er Remplazar la ruta absoluta
        ra_files_out[$l_j]="$l_full_path"
        ((l_j++))

    done

    # Si es archivo, indicar el tipo de archivo
    if [ $p_flag_show_infofile -ne 0 ]; then
        return 1
    fi

    if [ $l_is_text_file -eq 0 ]; then
        return 2
    fi
    return 3

}



m_get_cmd_of_files() {
    echo ""
}


# > Valor de retorno indica el tipo de multiplexor
#   ( 0) Si es tmux
#   ( 1) Si es WezTerm
#   ( 9) Unknown
m_get_multiplexor_type() {

    # Si usa el multiplexor
    if [ ! -z "$TMUX" ]; then
        return 0
    fi

    # Si es un emulador de terminal Wezterm
    if [ ! -z "$WEZTERM_UNIX_SOCKET" ] && [ "$TERM_PROGRAM" = "WezTerm" ]; then
        return 1
    fi

    return 9
}


# > Argumentos de entrada
#   1> El tipo de multiplexor
#   2> Tipo de mecanismo para obtener el
#   3> Ruta del primer archivo/folder
m_get_pane_workdir() {

    echo ""
    return 0
}

# > Argumentos de entrada
#   1> El tipo de multiplexor
#   1> Working dir
#   2> Comando a ejecutar
#   3>
#
m_open_new_termtab() {

    echo ""
    return 0
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
    local p_working_dir=""
    local p_working_dir_type=0
    local p_flag_show_infofile=1

    #echo "Init ${@}" >> /tmp/remove.txt

    while [ $# -gt 0 ]; do

        case "$1" in

            -h)
                _usage
                return 0
                ;;

            -f)
                p_flag_show_infofile=0
                shift
                ;;

            -p)
                p_working_dir_type=0
                shift
                ;;

            -w)
                if [ ! -d "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" debe ser un folder valido: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-w" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    _usage
                    return 1
                fi

                p_working_dir="$2"
                p_working_dir_type=1
                shift 2
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


    #2. Leer los argumentos restantes
    local -a pa_files=("$@")

    if [ ${#pa_files[@]} -le 0 ]; then
        printf '[%bERROR%b] Debe especificar 1 o mas rutas de archivos y/o carpetas.\n\n' "$g_color_red1" "$g_color_reset"
        _usage
        return 3
    fi


    #3. Obtener la lista de archivo o la ruta del folder
    local -a la_files=()
    local l_file_type=0  # (0) si es folder, (1) si es un archivo independiente, (2) si es un archivo de texto, (3) si es un archivo binarop

    m_get_fullpath_files "pa_files" "la_files" $p_flag_show_infofile
    l_file_type=$?

    if [ $l_file_type -gt 3 ]; then
        return $l_file_type
    fi
    #echo "Step 1 ${p_full_path}" >> /tmp/remove.txt


    #4. Determinar si es folder o archivo
    l_full_path="${pa_files[0]}"



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
            if [ $p_working_dir_type -eq 0 ]; then

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
        if [ $p_working_dir_type -eq 2 ]; then
            l_parent_dir=$(tmux display-message -p "#{pane_current_path}")
        elif [ $p_working_dir_type -eq 1 ]; then
            l_parent_dir=""
        fi

        # Crear una ventana en la sesion actual
        if [ -z "$l_parent_dir" ]; then
            l_position=$(tmux new-window -PF "#{window_id}.#{pane_id}")
        else
            l_position=$(tmux new-window -c "$l_parent_dir" -PF "#{window_id}.#{pane_id}")
        fi

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
        if [ $p_working_dir_type -eq 2 ]; then

            l_data=$(wezterm cli list --format json | jq -r --arg pid "$WEZTERM_PANE" '.[] | select(.pane_id == ($pid | tonumber)) | .cwd')
            if [ -z "$l_data" ]; then
                return 2
            fi

            l_parent_dir=$(echo "$l_data" | sed -E 's|^[^:]+://[^/]+||')

        elif [ $p_working_dir_type -eq 1 ]; then
            l_parent_dir=""
        fi

        # Crear un nuevo tab en el workspace actual del domunio actual
        if [ -z "$l_parent_dir" ]; then
            l_position=$(wezterm cli spawn 2>/dev/null)
        else
            l_position=$(wezterm cli spawn --cwd "$l_parent_dir" 2>/dev/null)
        fi

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
