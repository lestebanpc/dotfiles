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


# Obtener el ID window y el ID del panel disponible de la ventana siguiente a la actual.
get_pane_id_of_next_windows() {

    #1. Obtener el indice (a diferencia de ID, el indice siempre es ordenado e inicia con 0)  de la ventana actual
    local l_current_win_index
    l_current_win_index=$(tmux display-message -p '#{window_index}')
    l_current_win_index="${l_current_win_index#@}"

    #2. Obtener los ID de las ventanas siguiente a la ventana actual
    local l_data1
    l_data1=$(tmux list-windows -F '#{window_id}' -f "#{>:#{window_index},${l_current_win_index}}" 2> /dev/null)

    #3. Obtener los ID de los paneles disponibles (que ejecutan 'bash')
    local l_next_window_id
    local l_pane_id
    local l_current_cmd='bash'

    if [ ! -z "$l_data1" ]; then

        # Por cada buscar el primer panel que ejecuta una interprete shell
        local l_data2
        local l_item
        local la_data=()

        for l_item in $l_data1; do

            # Buscar paneles de la ventana donde esta ejecutando el interprete shell
            l_data2=$(tmux list-panes -F '#{pane_id}' -t "$l_item" -f "#{==:#{pane_current_command},${l_current_cmd}}" 2> /dev/null)
            if [ -z "$l_data2" ]; then
                continue
            fi

            # Si existe uno, se encontro y salir
            l_next_window_id="${l_item#@}"

            la_data=(${l_data2})
            l_pane_id="${la_data[0]}"
            l_pane_id="${l_pane_id#%}"
            break

        done

    fi


    # Si no se encontra el panel disponible en la ventana siguiente a la actual.
    if [ -z "$l_pane_id" ] || [ -z "$l_next_window_id" ]; then
        return 1
    fi

    #4. Devolver el ID del windows y ID de su panel disponible
    echo "${l_next_window_id} ${l_pane_id}"
    return 0

}


# Obtener o crear el ID window y el ID del panel disponible de la ventana siguiente a la actual.
get_or_create_pane_next_window() {

    #1. Parametros
    local p_working_dir="$1"

    #2. Obtiene el ID del panel, de la ventana siguiente, cuyo programa actual sea el interprete shell
    local l_data
    #set -x
    l_data=$(get_pane_id_of_next_windows)
    #set +x

    if [ ! -z "$l_data" ]; then
        echo "$l_data"
        return 0
    fi


    #3. Si no existe, crear la ventana (con el panel por defecto)
    if [ -z "$p_working_dir" ]; then
        l_data=$(tmux new-window -PF "#{window_id} #{pane_id}")
    else
        l_data=$(tmux new-window -c "$p_working_dir" -PF "#{window_id} #{pane_id}")
    fi

    if [ -z "$l_data" ]; then
        return 1
    fi

    la_data=(${l_data})

    local l_window_id="${la_data[0]}"
    l_window_id="${l_window_id#@}"

    local l_pane_id="${la_data[1]}"
    l_pane_id="${l_pane_id#%}"

    #4. Devolver el ID del windows y ID su panel disponible
    echo "${l_window_id} ${l_pane_id}"
    return 0

}


# Obtiene el ID (sin el '%') del panel disponible de la ventana actual.
# El del ID del panel a usar se obtendra segun orden de prioridad:
#  > Si se especifica la opcion '-n' (nearest panel), buscara el primer panel diferente al actual que exista en la ventana tmux.
#  > Si se especifica la opcion '-p <pane_id>', si el '<pane_id>' es un ID de panel valido, se usara este panel.
#  > Se usara el valor almacenado en la opcion de la ventana '@cmd_pane_idx'.
# Si no existe el panel, se retorna vacio.
get_pane_id_of_current_windows() {

    #1. Parametros
    local p_flag_nearest_pane=$1
    local p_suggested_pane_id=-1
    if [ ! -z "$2" ]; then
        p_suggested_pane_id=$2
    fi

    #2. Prioridad 1: Usar el panel mas cercano, si esto existe
    local l_data
    local l_pane_info
    local l_pane_id

    if [ $p_flag_nearest_pane -eq 0 ]; then

        #Listar los paneles de la ventana tmux actual
        l_data=$(tmux list-panes -F '#{pane_active}:#{pane_id}' 2> /dev/null)

        # Usar el ID del 1er panel que no es actual/activo
        if [ ! -z "$l_data" ]; then
            for l_pane_info in $l_data; do
                # El panel activo siempre inicia con tiene el formato '1:%<pane_id>'
                if [[ "$l_pane_info" == 0:* ]]; then
                    l_pane_id=${l_pane_info#0:%}
                    break
                fi
            done
        fi

        # Si existe el panel cercano (no almacenarlo en la variable '@cmd_pane_idx')
        if [ ! -z "$l_pane_id" ]; then

            echo $l_pane_id
            return 0

        fi

    fi


    #3. Prioridad 2: Usar el ID del panel sugerido
    if [ $p_suggested_pane_id -ge 0 ]; then

        # Validar si el panel existe
        if tmux list-panes -F "#{pane_id}" | grep -q "^%${p_suggested_pane_id}$"; then

            l_pane_id=$(tmux show-window-options -v @cmd_pane_idx 2> /dev/null || echo "")

            # Si el panel ID almacenado no existe, almacenar el panel sugerido.
            if [ -z "$l_pane_id" ]; then
                tmux set-window-option @cmd_pane_idx "$p_suggested_pane_id"
                echo $p_suggested_pane_id
                return 0
            fi

            # Si el panel ID no es valido, almacenar el panel sugerido
            if ! tmux list-panes -F "#{pane_id}" | grep -q "^%${l_pane_id}$"; then
                tmux set-window-option @cmd_pane_idx "$p_suggested_pane_id"
                echo $p_suggested_pane_id
                return 0
            fi

            #Si el panel ID alamcenado existe y valido, no almacenar el penal sugerido
            echo $p_suggested_pane_id
            return 0

        fi

    fi


    #4. Prioirdad 3: Usar el ID almacenado en la opcion '@cmd_pane_idx'

    # Obtener el ID del panel ID de la ventada actual almacena en una opcion de la ventana
    l_pane_id=$(tmux show-window-options -v @cmd_pane_idx 2> /dev/null || echo "")

    if [ -z "$l_pane_id" ]; then
        return 0
    fi

    # Validar que no sea el panel actual
    local l_current_pane_id
    l_current_pane_id=$(tmux display-message -p '#{pane_id}')
    l_current_pane_id="${l_current_pane_id#%}"

    if [ $l_current_pane_id -eq $l_pane_id ]; then
        # Si ya existe, limpiar el valor
        tmux set-window-option @cmd_pane_idx ""
        return 0
    fi

    # Validar si el panel aun existe
    if ! tmux list-panes -F "#{pane_id}" | grep -q "^%${l_pane_id}$"; then
        # Si ya no existe, limpiar el valor
        tmux set-window-option @cmd_pane_idx ""
        return 0
    fi

    echo $l_pane_id
    return 0

}


# Obtiene o crea el ID (sin el '%') del panel disponible de la ventana actual.
get_or_create_pane_current_window() {

    # Parametros
    local p_working_dir="$1"
    local p_height=$2
    local p_flag_nearest_pane=$3
    local p_suggested_pane_id="$4"

    # Obtiene el ID del panel actual
    local l_pane_id
    l_pane_id=$(get_pane_id_of_current_windows $p_flag_nearest_pane ${p_suggested_pane_id#%})

    if [ ! -z "$l_pane_id" ]; then
        echo "$l_pane_id"
        return 0
    fi

    # Si no existe, crear el panel horizontal pero sin establecerlo como activo ('-d' o deattach)
    if [ -z "$p_working_dir" ]; then
        l_pane_id=$(tmux split-window -vdp $p_height -PF "#{pane_id}")
    else
        l_pane_id=$(tmux split-window -c "$p_working_dir" -vdp $p_height -PF "#{pane_id}")
    fi

    l_pane_id="${l_pane_id#%}"

    # Almacenar el ID del panel
    tmux set-window-option @cmd_pane_idx "$l_pane_id"

    echo "$l_pane_id"
    return 0

}


# Obtiene el identificador de panel disponible creado o existe de la ventana actual o de la ventana siguiente.
get_pane_position() {

    # Parametros
    local p_working_dir="$1"
    local p_height=$2
    local p_flag_nearest_pane=$3
    local p_suggested_pane_id="$4"
    local p_flag_use_next_windows=$5

    #Obtener el panel existente o crearlo
    local l_pane_position=''
    local l_data

    if [ $p_flag_use_next_windows -eq 0 ]; then

        l_data=$(get_or_create_pane_next_window "$p_working_dir")
        local la_data=(${l_data})

        l_pane_position="@${la_data[0]}.%${la_data[1]}"

    else

        l_data=$(get_or_create_pane_current_window "$p_working_dir" $p_hight $p_flag_nearest_pane "$p_suggested_pane_id")
        l_pane_position="%${l_data}"

    fi

    echo "$l_pane_position"
    return 0

}


_usage() {

    cat <<EOF
Usage: tmux_run_cmd [options] -- [command]

> Crea un panel tmux horizontal unico (si existe lo reusa), donde ejecuta el comando establecido por [commnand].
> El del ID del panel a usar se obtendra segun orden de prioridad:
  > Si se especifica la opcion '-n' (nearest panel), buscara el primer panel diferente al actual que exista en la ventana tmux.
  > Si se especifica la opcion '-p <pane_id>', si el '<pane_id>' es un ID de panel valido, se usara este panel.
  > Se usara el valor almacenado en la opcion de la ventana '@cmd_pane_idx'.
> Si no encuentra un ID de panel, este creara un panel horizontal y almacenara el entero asociadoa su ID de panel en la opcion de ventana '@cmd_pane_idx'.
> El [commnand] puede representar como:
  > Un solo argumento entrecomillado o
  > Varios argumentos (entrecomillado o no)

Ejemplos:

> Un comando enviado como 1 solo argumento entrecomillado:
  $ tmux_run_cmd -h 20 -- 'echo "Ruta: \$HOME"'
  $ tmux_run_cmd -dczw /home/lucianoepc/code -- 'echo "Ruta: \$HOME"'

> Un comando enviado como varios argumentos:
  $ tmux_run_cmd -h 20 -- echo 'Ruta: \$HOME'
  $ tmux_run_cmd -dczw /home/lucianoepc/code -- echo 'Ruta: \$HOME'

Options:
 -d           El panel donde se ejecuta el comando lo estable en el activo. Si no se especifica el panel no es el activo.
 -c           Limpiar el contenido del panel antes de ejecutar el comando.
 -z           El panel donde se ejecuta el comando lo establece en activo y lo realiza zoom.
 -w <workdir> Solo en la creacion del panel. El directorio de trabajo que se usara para crear el panel.

Options usado cuando se crea/usa un panel dentro de la ventana siguiente a la actual:
 -s           Valida si existe una ventana siguiente al actual para ejecutar el comando cuyo comando actual sea el interprete shell ('bash').
              Si no existe esa ventana creara la ventana. Si se establece, se omite las opciones '-p', '-n' o '-h'.

Options usado cuando se crea/usa un panel dentro de la ventana actual:
 -p <pane_id> ID del panel temux a usar (si se especifa y existe, tendra mayor prioridad respecto al almacenado en '@cmd_pane_idx').
              Usado para reusar el panel generado por vimux.
 -n           Usar el 'nearest panel' si existe. Buscara el primer panel diferente al actual que exista en la ventana tmux.
 -h <n>       Solo en la creacion del panel. El % de la altura (<n> debe ser 10 a 90 incluyendo estos) que debera tener el nuevo panel a crear.
EOF

}



# -------------------------------------------------------------------------------------
# Main code
# -------------------------------------------------------------------------------------

# Funcion principal de entrada
main() {

    # Validar si esta en un panel tmux
    if [ -z "$TMUX" ]; then

        printf '[%bERROR%b] Debe ejecutarse dentro de panel de tmux.\n' "$g_color_red1" "$g_color_reset"
        return 1
    fi

    # Variable por defecto
    local p_working_dir=''
    local p_flag_set_active=1
    local p_flag_clean=1
    local p_flag_zoom=1
    local p_flag_use_next_windows=1
    local p_hight=20
    local p_flap_nearest_pane=1
    local p_suggested_pane_id=''

    # Procesar los argumentos (opciones) antes del '--'
    while [ $# -gt 0 ]; do

        case "$1" in

            -w)
                p_working_dir="$2"
                shift 2
                ;;


            -h)
                if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es invalida: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-h" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    _usage
                    return 1
                fi

                if [ $2 -le 10 ] && [ $2 -ge 90 ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" debe esta [10, 90]: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-h" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    _usage
                    return 1
                fi

                p_hight=$2
                shift 2
                ;;


            -p)
                if ! [[ "$2" =~ ^%[0-9]+$ ]]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es invalida: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-p" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    _usage
                    return 1
                fi

                p_suggested_pane_id="$2"
                shift 2
                ;;


            -d)
                p_flag_set_active=0
                shift
                ;;


            -n)
                p_flag_nearest_pane=0
                shift
                ;;

            -c)
                p_flag_clean=0
                shift
                ;;

            -z)
                p_flag_set_active=0
                p_flag_zoom=0
                shift
                ;;

            -s)
                p_flag_use_next_windows=0
                shift
                ;;

            --)
                shift

                # Solo continuar si se encuentra la opcion '--'
                break
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                _usage
                return 1
                ;;

            *)
                printf '[%bERROR%b] Argumento "%b%s%b" no es esperado antes de opcion --.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                _usage
                return 1
                ;;

        esac

    done

    # Procesar los argumentos restantes después de "--" (comando a ejecutar)
    local l_command_args=("$@")

    if [ ${#l_command_args[@]} -le 0 ]; then
        printf '[%bERROR%b] Debe especificar un comando a ejecutar.\n\n' "$g_color_red1" "$g_color_reset"
        _usage
        return 1
    fi

    # Obtener el comando a scribir y ejecutar en el panel tmux
    local g_tmux_command=''

    if [ ${#l_command_args[@]} -gt 1 ]; then

        # Adicionar el entrecomillado/¿caracteres de escape? removido
        # > Adicionar 1 espacio inicial a todos los argumentos menos el primero.
        #   Tmux escribirara cada argumento colocado en 'send-keys' consecutivos y sin espacio.
        # > Cuando se pasan argumentos con espacios, dentro de script/funcion se elimina el entrecomillado.
        # > ¿Adicionar los caracteres de escape removidos?
        g_i=0
        g_item=''

        for (( g_i = 0; g_i < ${#l_command_args[@]}; g_i++ )); do

            g_item="${l_command_args[$g_i]}"

            if [ $g_i -eq 0 ]; then

                if [[ "${g_item}" == *" "* ]]; then
                    g_tmux_command="\"${g_item}\""
                    #g_tmux_command="\\\"${g_item}\\\""
                else
                    g_tmux_command="${g_item}"
                fi

            else

                if [[ "${g_item}" == *" "* ]]; then
                    g_tmux_command+=" \"${g_item}\""
                    #g_tmux_command+=" \\\"${g_item}\\\""
                else
                    g_tmux_command+=" ${g_item}"
                fi

            fi

        done

    else

        # Si solo tiene un argumento se tratara como un solo argumento en 'send-keys' de tmux
        g_tmux_command="${l_command_args[0]}"

    fi

    # Crear u obtener el panel para ejecutar comandos
    local l_pane_position
    #set -x
    l_pane_position=$(get_pane_position "$p_working_dir" $p_hight $p_flag_nearest_pane "$p_suggested_pane_id" $p_flag_use_next_windows)
    #set +x

    # Limpiar la pantalla
    if [ $p_flag_clean -eq 0 ]; then
        tmux send-keys -t "${l_pane_position}" 'clear' Enter
    fi

    # Enviar comandos ingesados al script al panel del DAP
    tmux send-keys -lt "${l_pane_position}" "$g_tmux_command"
    tmux send-keys -t "${l_pane_position}" Enter

    if [ $p_flag_set_active -eq 0 ] || [ $p_flag_zoom -eq 0 ]; then
        tmux select-pane -t "${l_pane_position}"
    fi

    if [ $p_flag_zoom -eq 0 ]; then
        tmux resize-pane -t "${l_pane_position}" -Z
    fi

    return 0

}


# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $g_result
