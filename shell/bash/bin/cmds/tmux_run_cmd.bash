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


# Obtiene el ID (sin el '%') del panel ID donde se muestra la psuedo-terminal usada para ejecutar comandos.
# Si no existe el panel, se retorna vacio.
get_current_panel_id() {

    # Parametros

    # Obtener el ID del panel ID de la ventada actual almacena en una opcion de la ventana
    local l_panel_id
    l_panel_id=$(tmux show-window-options -v @cmd_panel 2> /dev/null || echo "")

    if [ -z "$l_panel_id" ]; then
        return 0
    fi

    # Validar que no sea el panel actual
    local l_current_panel_id
    l_current_panel_id=$(tmux display-message -p '#{pane_id}')
    l_current_panel_id="${l_current_panel_id#%}"

    if [ $l_current_panel_id -eq $l_panel_id ]; then
        # Si ya existe, limpiar el valor
        tmux set-window-option @cmd_panel ""
        return 0
    fi


    # Validar si el panel aun existe
    if ! tmux list-panes -F "#{pane_id}" | grep -q "^%${l_panel_id}$"; then
        # Si ya no existe, limpiar el valor
        tmux set-window-option @cmd_panel ""
        return 0
    fi

    echo $l_panel_id
    return 0

}


get_or_create_panel() {

    # Parametros
    local p_height=$1
    local p_working_dir="$2"

    # Obtiene el ID del panel actual para DAP
    local l_panel_id
    l_panel_id=$(get_current_panel_id)

    # Si no existe, crearlo
    if [ -z "$l_panel_id" ]; then

        # Crear el panel
        if [ -z "$p_working_dir" ]; then
            l_panel_id=$(tmux split-window -vdp $p_height -PF "#{pane_id}")
        else
            l_panel_id=$(tmux split-window -c "$p_working_dir" -vdp $p_height -PF "#{pane_id}")
        fi

        # Crear un panel horizontal pero sin establecerlo como activo ('-d' o deattach)
        l_panel_id="${l_panel_id#%}"

        # Almacenar el ID del panel
        tmux set-window-option @cmd_panel "$l_panel_id"

    fi

    echo "$l_panel_id"

}


_usage() {

    cat <<EOF
Usage: tmux_run_cmd [options] -- [command]

> Crea un panel tmux horizontal unico (si existe lo reusa), donde ejecuta el comando establecido por [commnand].
> El ID del panel horizontal se almacena en la opcion de la sesion '@cmd_panel_of_win[n]' donde '[n]' la parte entera del ID del Windows actual.
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
 -d           El panel donde se ejecuta el comando lo estable en el activo. Si no se especifa el panel no es el activo.
 -c           Limpiar la terminal antes de ejecutar el comando.
 -z           El panel donde se ejecuta el comando lo establece en activo y lo realiza zoom.

Options (solo usado cuando se crea el panel):
 -w <workdir> El directorio de trabajo que se usara para crear el panel.
 -h <n>       Porcentaje de la altura (<n> debe ser 10 a 90 incluyendo estos) que debera tener el nuevo panel a crear.
EOF

}



# -------------------------------------------------------------------------------------
# Main code
# -------------------------------------------------------------------------------------

# Validar si esta en un panel tmux
if [ -z "$TMUX" ]; then

    printf '[%bERROR%b] Debe ejecutarse dentro de panel de tmux.\n' "$g_color_red1" "$g_color_reset"
    exit 1
fi

# Variable por defecto
g_working_dir=''
g_flag_set_active=1
g_flag_clean=1
g_flag_zoom=1
g_hight=20

# Procesar las opciones (antes del '--')
while [ $# -gt 0 ]; do

    case "$1" in

        -w)
            g_working_dir="$2"
            shift 2
            ;;

        -h)
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                printf '[%bERROR%b] Valor de la opción "%b%s%b" es invalida: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "-h" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                _usage
                exit 1
            fi

            if [ $2 -le 10 ] && [ $2 -ge 90 ]; then
                printf '[%bERROR%b] Valor de la opción "%b%s%b" debe esta [10, 90]: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "-h" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                _usage
                exit 1
            fi

            g_hight=$2
            shift 2
            ;;

        -d)
            g_flag_set_active=0
            shift
            ;;

        -c)
            g_flag_clean=0
            shift
            ;;

        -z)
            g_flag_set_active=0
            g_flag_zoom=0
            shift
            ;;

        --)
            shift
            break
            ;;

        *)
            printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$1" "$g_color_reset"
            _usage
            exit 1
            ;;

    esac

done

# Argumentos restantes después de "--" (comando a ejecutar)
g_command_args=("$@")

if [ ${#g_command_args[@]} -le 0 ]; then
    printf '[%bERROR%b] Debe especificar un comando a ejecutar.\n\n' "$g_color_red1" "$g_color_reset"
    _usage
    exit 1
fi

# Obtener el comando a scribir y ejecutar en el panel tmux
g_tmux_command=''

if [ ${#g_command_args[@]} -gt 1 ]; then

    # Adicionar el entrecomillado/¿caracteres de escape? removido
    # > Adicionar 1 espacio inicial a todos los argumentos menos el primero.
    #   Tmux escribirara cada argumento colocado en 'send-keys' consecutivos y sin espacio.
    # > Cuando se pasan argumentos con espacios, dentro de script/funcion se elimina el entrecomillado.
    # > ¿Adicionar los caracteres de escape removidos?
    g_i=0
    g_item=''

    for (( g_i = 0; g_i < ${#g_command_args[@]}; g_i++ )); do

        g_item="${g_command_args[$g_i]}"

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
    g_tmux_command="${g_command_args[0]}"

fi

# Crear u obtener el panel para ejecutar comandos
g_panel_id=$(get_or_create_panel $g_hight "$g_working_dir")


# Limpiar la pantalla
if [ $g_flag_clean -eq 0 ]; then
    tmux send-keys -t "%${g_panel_id}" 'clear' Enter
fi

# Enviar comandos ingesados al script al panel del DAP
tmux send-keys -lt "%${g_panel_id}" "$g_tmux_command"
tmux send-keys -t "%${g_panel_id}" Enter

if [ $g_flag_set_active -eq 0 ] || [ $g_flag_zoom -eq 0 ]; then
    tmux select-pane -t "%${g_panel_id}"
fi

if [ $g_flag_zoom -eq 0 ]; then
    tmux resize-pane -t "%${g_panel_id}" -Z
fi
