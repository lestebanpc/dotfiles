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
Usage: go_folder_new_termtab [options] folder_or_file

> Crea una nueva ventana/tab en la terminal con un nuevo panel y cuyo directorio de trabajo es caclulado, segun prioridad:
    > El folder especificado por la opcion '-w'.
    > Si se usa la opcion '-p', el directorio de trabajo sera calculado pot el script y su valor depende del valor de la opcion:
      > '1' Se usa el directorio de trabajo usado por el proceso de ejecucion del panel actual.
            > Programas como 'yazi' modifican el directorio de trabajo de sus proceso segun que directorio se este navegando.
      > '2' Se usa el directorio padre donde pertenece el archivo del argumento. Si el argumento es un archivo se usara el
            directorio padre donde pertenece el archivo.
    > Si no se usa ni '-w' ni '-p', no se especificara el directorio trabajo al crear el panel.
> Los emuladores de terminal soportados son:
  > Si usa el multiplexor tmux, independendiente del emulador de terminal donde lo ejecute
  > Si no usa un multiplexor de terminal, solo se soporta las siguientes emuladores de terminal:
    > WezTerm

Ejemplos:

  $ go_folder_new_termtab ../
  $ go_folder_new_termtab /home/lucianoepc/code
  $ go_folder_new_termtab /home/lucianoepc/code/mynote.txt
  $ go_folder_new_termtab -p 1 /home/lucianoepc/code

Las opciones usadas son:

 -p         El directorio de trabajo para crear el nuevo panel sera calculado por el script. Los valores permitido para esta opcion son:
            > '1' Se usa el directorio de trabajo usado por el proceso de ejecucion del panel actual.
                  > Programas como 'yazi' modifican el directorio de trabajo de sus proceso segun que directorio se este navegando.
            > '2' Se usa el directorio padre donde pertenece el archivo del argumento. Si el argumento es un archivo se usara el
                  directorio padre donde pertenece el archivo.

 -w wordir  El valor de esta opcion se usara como directorio de trabajo del nuevo tab.
            > Si se especifica tanto esta opcion como la opcion '-p', esta opcion tendra mayor prioridad.

El argumento es la ruta de un folder u archivo. La ruta puede ser absoluta o relativa.
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

        l_working_dir=$(echo "$l_data" | sed -E 's|^[^:]+://[^/]+||')
        l_status=$?

        if [ $l_status -ne 0 ]; then
            return 1
        fi

    fi

    # Devolver el directorio de trabajo
    r_working_dir="$l_working_dir"
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
       #tmux send-keys -lt "${l_position}" "$p_cmd_to_exec"

       # Escribir en un buffer nombrado
       tmux set-buffer -b 'yazifiles' "$p_cmd_to_exec"

       # Pegar el texto en el buffer nombrado respetando el texto (no realizara ninguna expansion)
       tmux paste-buffer -b 'yazifiles' -t "$p_position"

       # Ejecutar el comando escrito en el panel
       tmux send-keys -t "${l_position}" Enter

        #if [ $l_status -ne 0 ]; then
        #    return 1
        #fi

    # Si es WezTerm
    elif [ $p_multiplexor_type -eq 1 ]; then

        # Escribir el comandos en el prompt de panel creado y ejecutar escribiendo el fin de linea
        # Para ello se usara 'echo', en vez de 'printf' para enviar el fin de linea
        echo "$p_cmd_to_exec" | wezterm cli send-text --pane-id "$l_position" --no-paste

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
    local p_working_dir_src=2

    while [ $# -gt 0 ]; do

        case "$1" in

            -h)
                _usage
                return 0
                ;;

            -p)
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


    #6. Determinar el working dir ausar para crear el nuevo panel (Calculo automatico del working dir)
    if [ $p_working_dir_src -eq 2 ]; then

        m_get_workdir_current_pane $l_multiplexor_type "p_working_dir"
        l_status=$?

        if [ $l_status -ne 0 ]; then
            printf '[%bERROR%b] No se puede calcular el directorio de trabajo.\n\n' "$g_color_red1" "$g_color_reset"
            return 7
        fi

    elif [ $p_working_dir_src -eq 3 ]; then
        p_working_dir="${l_full_path##*/}"
    fi



    #8. Crear el comando que visualiza los archivos a visualizar
    local l_cmd_to_exec=""


    #9. Crear el panel y ejecutar el comando de visualizacion
    local l_pane_position=""
    m_create_new_pane $l_multiplexor_type "l_pane_position"
    #echo "Step 2 ${p_full_path}" >> /tmp/remove.txt


    #10. Ejecutar el comando en el panel indicado
    if [ -z "$l_cmd_to_exec" ]; then
        m_exec_cmd_in_pane $l_multiplexor_type "$l_pane_position" "$l_cmd_to_exec"
    fi

    return 0

}


# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $g_result
