#!/bin/bash

#set -euo pipefail

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
Usage: go_files_new_termtab [options] file1 file2 ... filen

> Crea una nueva ventana/tab en la terminal con un nuevo panel y cuyo directorio de trabajo es caclulado, segun prioridad:
    > El folder especificado por la opcion '-w'.
    > Si se usa la opcion '-p', el directorio de trabajo sera calculado pot el script y su valor depende del valor de la opcion:
      > '1' Se usa el directorio de trabajo usado por el proceso de ejecucion del panel actual.
            > Programas como 'yazi' modifican el directorio de trabajo de sus proceso segun que directorio se este navegando.
      > '2' Se usa el directorio padre donde pertenece el archivo del 1er argumento.
    > Si no se usa ni '-w' ni '-p', no se especificara el directorio trabajo al crear el panel.
> En el panel creado, se muestran los archivos ingresados como argumentos:
    > Si el 1er argumento es un archivo de texto lo abriran todos los archivos de texto ingresados con el editor '\$EDITOR' (se
      excluyen los archivos binarios).
    > Si el 1er argumento es un archivo binario se muestra la informacion de todos los archivos ingresando usando 'file'.
> Los emuladores de terminal soportados son:
  > Si usa el multiplexor tmux, independendiente del emulador de terminal donde lo ejecute
  > Si no usa un multiplexor de terminal, solo se soporta las siguientes emuladores de terminal:
    > WezTerm

Ejemplos:

  $ go_files_new_termtab /home/lucianoepc/code/mynote.txt
  $ go_files_new_termtab -p 1 /home/lucianoepc/code/mynote.txt

Opciones usadas son:

 -p         El directorio de trabajo para crear el nuevo panel sera calculado por el script. Los valores permitido para esta opcion son:
            > '1' Se usa el directorio de trabajo usado por el proceso de ejecucion del panel actual.
                  > Programas como 'yazi' modifican el directorio de trabajo de sus proceso segun que directorio se este navegando.
            > '2' Se usa el directorio padre donde pertenece el archivo del 1er argumento.

 -w wordir  El valor de esta opcion se usara como directorio de trabajo del nuevo tab.
            > Si se especifica tanto esta opcion como la opcion '-p', esta opcion tendra mayor prioridad.

 -l n,..,z  Listado de numero enteros que representan el numero de liena separado por ','.
            > Si un archivo no tienen una liena asignada no se usara.
            > Solo aplicable si son archivo de texto y el editor es 'vim' o 'nvim'.
            > Si en los argumentos se colocan folderes y archivos binarios seran excluidos, y por ende, el orden no se respetara.

Argumentos son unlistado de archivos:
   > El primer argumento siempre debe ser un archivo.
   > La ruta puede ser absoluta o relativa.
   > Si se incluye ruta de folderes, estos seran omitidos.
   > Si se incluye archivos que no sean del mismo tipo (binario o texto) que el 1er archivo, estos seran omitidos.
   > Los archivos deben tener diferentes rutas.
EOF

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


# > Valor de retorno:
#   (0) si es un archivo de texto.
#   (1) si es un archivos binarios.
#   (5) El 1er argumento no tiene una ruta de archivo valida.
#   (6) El 1er argumento no es folder o es un archivo valido.
m_validate_first_file() {

    #1. Argumentos
    local p_file_path="$1"
    local -n r_file_full_path="$2"

    #2. Expandir la ruta relativa (y/o enlaces simbolicos) en rutas absolutas
    local l_path=''
    if ! l_path=$(realpath -m "$p_file_path" 2> /dev/null); then
        printf '[%bERROR%b] El 1er argumento "%b%s%b" no es la ruta de un archivo valido.\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$p_file_path" "$g_color_reset"
        return 5
    fi
    echo "local l_path: ${l_path}"

    #3. Validar si el archivo existe
    if [ ! -f "$l_path" ]; then
        printf '[%bERROR%b] El 1er argumento "%b%s%b" no es un archivo valido.\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$p_full_path" "$g_color_reset"
        return 6
    fi

    #4. Determinar si es un archivo de texto
    r_file_full_path="$l_path"

    local l_is_text_file=1
    m_is_text_file "$l_path"
    l_is_text_file=$?

    return $l_is_text_file

}


# > Valor de retorno:
#   (0) OK.
#   (1) Ocurrio un error.
m_get_workdir_current_pane() {

    #1. Argumentos
    local p_multiplexor_type=$1
    local -n r_working_dir="$2"


    local l_working_dir=""
    local l_status=0

    # Si es tmux
    if [ $p_multiplexor_type -eq 0 ]; then

        l_working_dir=$(tmux display-message -p "#{pane_current_path}")
        l_status=$?

        if [ $l_status -ne 0 ]; then
            return 1
        fi

    # Si es WezTerm
    elif [ $p_multiplexor_type -eq 1 ]; then

        local l_data=""
        l_data=$(wezterm cli list --format json | jq -r --arg pid "$WEZTERM_PANE" '.[] | select(.pane_id == ($pid | tonumber)) | .cwd')
        l_status=$?

        if [ $l_status -ne 0 ]; then
            return 1
        fi

        if [ -z "$l_data" ]; then
            return 1
        fi

        # Remover el prefijo 'file://' o 'file:/host/'
        l_working_dir="${l_data#file:/*/}"
        l_status=$?

        if [ $l_status -ne 0 ]; then
            return 1
        fi

    fi

    # Devolver el directorio de trabajo
    r_working_dir="$l_working_dir"
    return 0

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


m_get_fullpath_files() {

    #1. Argumentos
    local -n ra_files_in="$1"
    local p_use_text_file=$2
    local p_first_full_path="$3"
    local p_working_dir="$4"
    local -n ra_files_out="$5"

    #2. Registrar el 1er elemento
    local l_path=''

    # Si se define un directorio de trabajo, usar la ruta relativa a dicho directorio de trabajo
    if [ -z "$p_working_dir" ]; then
        ra_files_out[0]="$p_first_full_path"
    else
        ra_files_out[0]="${p_first_full_path#${p_working_dir}/}"
    fi

    local l_n=${#ra_files_in[@]}
    if [ $l_n -eq 1 ]; then
        return 0
    fi

    #3. Registrar los otros elementos
    local l_i=1
    local l_j=1
    local l_item=''
    local l_full_path=''
    local l_is_text_file=1

    for (( l_i = 1; l_i < l_n; l_i++ )); do

        l_item="${ra_files_in[$l_i]}"

        # Expandir la ruta relativa (y/o enlaces simbolicos) en rutas absolutas
        if ! l_full_path=$(realpath -m "$l_item" 2> /dev/null); then
            continue
        fi

        # Si no es un archivo omitirlo
        if [ ! -f "$l_full_path" ]; then
            continue
        fi

        # Filtrar solo los archivos del mismo tipo
        m_is_text_file "$l_full_path"
        l_is_text_file=$?

        # Si no es el tipo de archivo, omitirlo
        if [ $l_is_text_file -ne $p_use_text_file ]; then
            continue
        fi

        # Si se define un directorio de trabajo, usar la ruta relativa a dicho directorio de trabajo
        if [ ! -z "$p_working_dir" ]; then
            l_full_path="${l_full_path#${p_working_dir}/}"
        fi

        # Si es del mismo tipo que el 1er Remplazar la ruta absoluta
        ra_files_out[$l_j]="$l_full_path"
        ((l_j++))

    done

    return 0

}


# Solo si es un archivo de texto
# > Valor de retorno:
#   (0) OK.
#   (1) Ocurrio un error.
m_get_nbrline_files() {

    #1. Argumentos
    local p_data="$1"
    local -n ra_nbrlines="$2"

    if [ -z "$p_data" ]; then
        return 0
    fi

    #2. Obtener los numeros de lineas
    local IFS=','
    local -a la_data=(${p_data})

    #3. Validar los elementos del arreglo
    local l_i=0
    local l_item=''

    for (( l_i = 0; l_i < ${#la_data[@]}; l_i++ )); do

        l_item="${la_data[$l_i]}"

        # Si no es el tipo de archivo, omitirlo
        if ! [[ "$l_item" =~ ^[0-9]+$ ]]; then
            printf '[%bERROR%b] El elemento de la opcion "%b-l%b" es invalido "%b%s%b".\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$l_item" "$g_color_reset"
            return 1
        fi

        # Si es del mismo tipo que el 1er Remplazar la ruta absoluta
       ra_nbrlines[$l_i]="$l_item"

    done

    return 0

}



# > Valor de retorno:
#   (0) OK.
#   (1) Ocurrio un error.
m_get_cmd_to_exec() {

    #1. Argumentos
    local p_is_text_file=$1
    local p_viewer_cmd="$2"
    local -n ra_files="$3"
    local -n ra_nbrlines="$4"
    local -n r_cmd_to_exec="$5"


    #2. Recorrer todos los archivos a visualizar
    local l_cmd=""

    local l_is_vim=1
    if [ $p_is_text_file -eq 0 ] && { [ "$p_viewer_cmd" = "vim" ] || [ "$p_viewer_cmd" = "nvim" ]; }; then
        l_is_vim=0
    fi

    local l_n=${#ra_files[@]}
    local l_i=0
    local l_aux=""
    local l_file_path=''
    local l_nbr_line=0

    for (( l_i = 0; l_i < l_n; l_i++ )); do

        l_file_path="${ra_files[$l_i]}"

        # Si es un archivo texto, obtener el numero de liena a posicionarse
        l_nbr_line=0
        if [ $l_is_vim -eq 0 ]; then
            l_aux="${ra_nbrlines[$l_i]}"
            if [ ! -z "$l_aux" ]; then
                l_nbr_line=$l_aux
            fi
        fi

        # Si el primer archivo
        if [ $l_i -eq 0 ]; then

            # Si el comando es vim o nvim
            if [ $l_nbr_line -gt 0 ]; then
                printf -v l_cmd '%s +%s "%s"' "$p_viewer_cmd" "$l_nbr_line" "$l_file_path"
            else
                printf -v l_cmd '%s "%s"' "$p_viewer_cmd" "$l_file_path"
            fi

        else

            # Si no es el primer archivo
            if [ $l_nbr_line -gt 0 ]; then
                printf -v l_cmd '%s -c "e %s | %s"' "$l_cmd" "$l_file_path" "$l_nbr_line"
            else
                printf -v l_cmd '%s "%s"' "$l_cmd" "$l_file_path"
            fi

        fi


    done

    r_cmd_to_exec="$l_cmd"
    return 0

}


# > Argumentos de entrada
#   1> El tipo de multiplexor
# > Valor de retorno:
#   (0) OK.
#   (1) Ocurrio un error.
m_create_new_pane() {

    #1. Argumentos
    local p_multiplexor_type=$1
    local p_working_dir="$2"
    local -n r_position="$3"


    local l_position=""
    local l_status=0

    # Si es tmux
    if [ $p_multiplexor_type -eq 0 ]; then

        if [ -z "$p_working_dir" ]; then
            l_position=$(tmux new-window -PF "#{window_id}.#{pane_id}")
            l_status=$?
        else
            l_position=$(tmux new-window -c "$p_working_dir" -PF "#{window_id}.#{pane_id}")
            l_status=$?
        fi

        if [ $l_status -ne 0 ]; then
            return 1
        fi

    # Si es WezTerm
    elif [ $p_multiplexor_type -eq 1 ]; then

        if [ -z "$p_working_dir" ]; then
            l_position=$(wezterm cli spawn 2>/dev/null)
            l_status=$?
        else
            l_position=$(wezterm cli spawn --cwd "$p_working_dir" 2>/dev/null)
            l_status=$?
        fi

        if [ $l_status -ne 0 ]; then
            return 1
        fi

    fi

    # Devolver la posicion del panel
    r_position="$l_position"
    return 0

}

# Escribe el texto relacionado como comando a ejecutar en el panel actual y luego lo ejecuta.
# > Se recomiend usar otros mecanismo que eviten que al escribir el comando al panel se evite la expansion y reprocesamiento antes
#   de la ejecucion dentro del panel. Se escriba el texto tal como esta.
#   > No se recomienda escribir el texto del comando en el panel como argumento del CLI del emulador de terminal.
#     Limitaciones de pasar el texto de un comando a ejecutar como argumento del CLI de emulador de terminal.
#     - Para evitar la interpretacion del texto por tmux (caracteres especiales como 'Enter', 'Up', ...), se usa '-l'
#     - Para evitar la expansion bash se usa comillado simple.
#     - Problema: ¿que pasa si el texto tiene comillado simple?
#   > Usar mecanismo alternativo como pasar la informacion por STDIN o por otros mecanismos como buffer tmux
# > Argumentos de entrada
#   1> El tipo de multiplexor
# > Valor de retorno:
#   (0) OK.
#   (1) Ocurrio un error.
m_exec_cmd_in_pane() {

    #1. Argumentos
    local p_multiplexor_type=$1
    local p_position="$2"
    local p_cmd_to_exec="$3"


    #local l_status=0

    # Si es tmux
    if [ $p_multiplexor_type -eq 0 ]; then

       #1. Limpiar la pantalla
       tmux send-keys -t "${p_position}" 'clear' Enter

       #2. Escribir el comandos en el prompt de panel creado

       # No se usara 'send-keys' debido a que se desea evitar al expansion y soporte al commillado simple
       #tmux send-keys -lt "${p_position}" "$p_cmd_to_exec"

       # Escribir en un buffer nombrado
       tmux set-buffer -b 'yazifiles' "$p_cmd_to_exec"

       # Pegar el texto en el buffer nombrado respetando el texto (no realizara ninguna expansion)
       tmux paste-buffer -b 'yazifiles' -t "$p_position"

       # Ejecutar el comando escrito en el panel
       tmux send-keys -t "${p_position}" Enter

        #if [ $l_status -ne 0 ]; then
        #    return 1
        #fi

    # Si es WezTerm
    elif [ $p_multiplexor_type -eq 1 ]; then

        # Escribir el comandos en el prompt de panel creado y ejecutar escribiendo el fin de linea
        # Para ello se usara 'echo' o 'printf' con un fin de linea
        printf "%s\n" "$p_cmd_to_exec" | wezterm cli send-text --pane-id "$p_position" --no-paste

        #if [ $l_status -ne 0 ]; then
        #    return 1
        #fi

    fi

    return 0

}




# -------------------------------------------------------------------------------------
# Main code
# -------------------------------------------------------------------------------------

# Funcion principal de entrada
# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (2) No se tiene soporta al multiplexor o emulador de terminal usado.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos (archivos).
#   (5) El 1er argumento no tiene una ruta de archivo valida.
#   (6) El 1er argumento no es folder o es un archivo valido.
#   (7) No se puede calcular el directorio de trabajo
#
main() {

    #1. Validaciones previas

    # Validar comando requeridos
    if ! command -v realpath >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "realpath" instalado.\n' "$g_color_red1" "$g_color_reset"
        return 1
    fi

    # Determinar el emulador de terminal a usar
    local l_multiplexor_type=0
    m_get_multiplexor_type
    l_multiplexor_type=$?

    if [ $l_multiplexor_type -eq 9 ]; then
        printf '[%bERROR%b] El multiplexor o emulador es inválido.\n' "$g_color_red1" "$g_color_reset"
        return 2
    fi


    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local p_working_dir=""

    # (0) El directorio esta espeificado por la opciones '-w'
    # (1) Se usara el directorio de trabajo usado por el proceso ejecutandose en el panel actual.
    # (2) Se usara el directorio donde pertenece el archivo indicado como 1er argumento.
    # (3) No se especifica un directorio de trabajo durante la creacion del panel.
    local p_working_dir_src=3
    local p_data_lines=""

    while [ $# -gt 0 ]; do

        case "$1" in

            -h)
                _usage
                return 0
                ;;

            -p)
                # Si se ingreso el directorio de trabajo con la opcion '-w', este tiene mayor prioridad.
                if [ $p_working_dir_src -ne 0 ]; then

                    if ! [[ "$2" =~ ^[1-2]$ ]]; then
                        printf '[%bERROR%b] Valor de la opción "%b%s%b" es inválido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                               "$g_color_gray1" "-p" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                        _usage
                        exit 3
                    fi

                    if [ $2 -eq 1 ]; then
                        p_working_dir_src=1
                    elif [ $2 -eq 2 ]; then
                        p_working_dir_src=2
                    fi

                fi
                shift 2
                ;;

            -w)
                if [ ! -d "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" debe ser un folder valido: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-w" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    _usage
                    return 3
                fi

                p_working_dir="$2"
                p_working_dir_src=0
                shift 2
                ;;


            -l)
                p_data_lines="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                _usage
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done
    #echo "Setp 0 ${1}" >> /tmp/remove.txt


    #3. Leer los argumentos restantes
    local -a pa_files=("$@")

    if [ ${#pa_files[@]} -le 0 ]; then
        printf '[%bERROR%b] Debe especificar 1 o mas rutas de archivos y/o carpetas.\n\n' "$g_color_red1" "$g_color_reset"
        _usage
        return 4
    fi
    #printf "pa_files: "
    #printf '"%s"\n' "${pa_files[@]}"
    #echo "p_working_dir_src: ${p_working_dir_src}"


    #4. Validar el primer argumento
    local l_full_path=""
    local l_is_text_file=0  # (0) si es un archivo de texto, (1) si es un archivo binario

    m_validate_first_file "${pa_files[0]}" "l_full_path"
    l_is_text_file=$?

    # Si no es un archivo o la ruta es invalida
    if [ $l_is_text_file -gt 1 ]; then
        return $l_is_text_file
    fi
    #echo "l_is_text_file: ${l_is_text_file}, l_full_path: ${l_full_path}"

    # Determinar el comando usado para visualizar el archivo
    local l_viewer_cmd='file'

    if [ $l_is_text_file -eq 0 ]; then
        l_viewer_cmd="${EDITOR:-vim}"
    fi


    #5. Si es un archivo de texto, obtener las posiciones de las lineas
    local l_status=0
    local -a la_nbrlines=()

    if [ $l_is_text_file -eq 0 ]; then
        if [ "$l_viewer_cmd" = "vim" ] || [ "$l_viewer_cmd" = "nvim" ]; then

            m_get_nbrline_files "$p_data_lines" "la_nbrlines"
            l_status=$?

            if [ $l_status -ne 0 ]; then
                return 2
            fi
            #printf "la_nbrlines: "
            #printf '"%s"\n' "${la_nbrlines[@]}"


        fi
    fi


    #6. Determinar el working dir a usar para crear el nuevo panel
    if [ $p_working_dir_src -eq 1 ]; then

        # Si el working-dir se calcula automiaticamenbte en base al usado por el proceso actual del panel actual
        m_get_workdir_current_pane $l_multiplexor_type "p_working_dir"
        l_status=$?

        if [ $l_status -ne 0 ]; then
            printf '[%bERROR%b] No se puede calcular el directorio de trabajo.\n\n' "$g_color_red1" "$g_color_reset"
            return 7
        fi

    elif [ $p_working_dir_src -eq 2 ]; then

        # Si el working se cacula automaticamente en base la ruta donde esta el archvio/folder
        p_working_dir="${l_full_path%/*}"

    elif [ $p_working_dir_src -ne 0 ]; then

        #Si no se ingreso desde la opcion '-w'
        p_working_dir=""

    fi
    #echo "p_working_dir: ${p_working_dir}"


    #7. Obtener la lista de archivos a visualizar
    local -a la_files=()

    m_get_fullpath_files "pa_files" $l_is_text_file "$l_full_path" "$p_working_dir" "la_files"
    #echo "Step 1 ${p_full_path}" >> /tmp/remove.txt
    #printf "la_files: "
    #printf '"%s"\n' "${la_files[@]}"


    #8. Crear el comando que visualiza los archivos a visualizar
    local l_cmd_to_exec=""
    m_get_cmd_to_exec $l_is_text_file "$l_viewer_cmd" "la_files" "la_nbrlines" "l_cmd_to_exec"

    if [ -z "$l_cmd_to_exec" ]; then
        return 2
    fi
    #echo "l_cmd_to_exec: ${l_cmd_to_exec}"


    #9. Crear el panel y ejecutar el comando de visualizacion
    local l_pane_position=""
    m_create_new_pane $l_multiplexor_type "$p_working_dir" "l_pane_position"
    #echo "Step 2 ${p_full_path}" >> /tmp/remove.txt
    #echo "l_pane_position: ${l_pane_position}"

    #10. Ejecutar el comando en el panel indicado
    m_exec_cmd_in_pane $l_multiplexor_type "$l_pane_position" "$l_cmd_to_exec"

    return 0

}


# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $_g_result
