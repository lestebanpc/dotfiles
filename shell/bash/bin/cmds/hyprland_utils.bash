#!/bin/bash

# Colores principales usados
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

# Obtener la del script
#g_script_path="${BASH_SOURCE[0]}"

g_cmd_name='hypru'

declare -a ga_exported_functions=(
    )

# Diccionario de sbucomandos. La key es 'id del subcomando' y value es 'la descripcion del subcomando'.
# > Segun el ID de subcomando, se debe tener 2 funciones bash cuyo nombre tiene dicho ID
#   > Funcion de ayuda del comando tiene el nombre 'm_usage_CMD-ID'.
#   > Funcion de controlador del comando tiene el nombre 'controller_CMD-ID'.
declare -A gA_global_subcmd_ids=(
        ['spice']='Permite gestionar de ventanas de remote-viewer: conectarse a una VM usando SPICE, cambiar el size de la ventana.'
        #['rdp']='Permite gestionar de ventanas de sdl-freerdp: conectarse a una equipo remoto usando RDP, cambiar el size de la ventana.'
        ['android']='Permite gestionar de ventanas de scrcpy: screen mirrow a una dispositivo android, cambiar el size de la ventana.'
    )


# Diccionario de sbucomandos. La key es 'alias' y value es 'ID del subcomando'.
declare -A gA_global_subcmd_alias=(
    )


# Monitor alternativo (al cual esta asociado el workspace 8 y 9). Usado para mostrar ventanas en modo fullscreen.
declare -r g_monitor_name="HDMI-A-1"


# -------------------------------------------------------------------------------------
# General functions
# -------------------------------------------------------------------------------------


m_get_dictionary_info() {

    local -n rA_dictionary="$1"

    # Recorrer la lista de parametros identificados ....
    local l_infos=""

    local l_id
    local l_data

    for l_id in "${!rA_dictionary[@]}"; do

        l_data="${rA_dictionary[${l_id}]}"

        if [ -z "$l_infos" ]; then
            printf -v l_infos "'%b%s%b' ('%b%s%b')" "$g_color_yellow1" "$l_id" "$g_color_reset" "$g_color_gray1" "$l_data" "$g_color_reset"
        else
            printf -v l_infos "%b, '%b%s%b' ('%b%s%b')" "$l_infos" "$g_color_yellow1" "$l_id" "$g_color_reset" "$g_color_gray1" "$l_data" "$g_color_reset"
        fi

    done

    echo "$l_infos"

}



m_get_subcmd_infos() {

    local -n rA_subcmd_ids="$1"
    local -n rA_subcmd_alias="$2"

    local l_scmd_id
    local l_scmd_description
    local l_alias
    local l_alias_list
    local l_id

    for l_scmd_id in "${!rA_subcmd_ids[@]}"; do

        printf "%b  > %b%s%b\n" "$g_color_gray1" "$g_color_yellow1" "$l_scmd_id" "$g_color_reset"

        # Obtener los alias del comando
        l_alias_list=''

        for l_alias in "${!rA_subcmd_alias[@]}"; do

            l_id="${rA_subcmd_alias[${l_alias}]}"

            if [ "$l_id" = "$l_scmd_id" ]; then
                if [ -z "$l_alias_list" ]; then
                    printf -v l_alias_list "'%b%s%b'" "$g_color_yellow1" "$l_alias" "$g_color_reset"
                else
                    printf -v l_alias_list "%b, '%b%s%b'" "$l_alias_list" "$g_color_yellow1" "$l_alias" "$g_color_reset"
                fi
            fi

        done

        # Mostrar el alias
        if [ ! -z "$l_alias_list" ]; then
            printf '    Alias: %b\n' "$l_alias_list"
        fi

        # Mostrar la descripcion
        l_scmd_description="${rA_subcmd_ids[${l_scmd_id}]}"
        printf "    %b%s%b\n" "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    done


}


m_show_aspect_info() {

    local -n rA_aspect_ratios="$1"
    local p_default_aspect_ratio="$2"

    # Recorrer la lista de parametros identificados ....
    if [ -z "$p_default_aspect_ratio" ]; then
        printf '    %bSus valores pueden ser:%b\n' "$g_color_gray1" "$g_color_reset"
    else
        printf '    %bEl valor por defecto es "%s". Sus valores pueden ser:%b\n' "$g_color_gray1" "$p_default_aspect_ratio" "$g_color_reset"
    fi

    local l_id
    local l_data

    for l_id in "${!rA_aspect_ratios[@]}"; do

        l_data="${rA_aspect_ratios[${l_id}]}"
        printf '%b    - %b%s%b %s%b\n' "$g_color_gray1" "$g_color_cian1" "$l_id" "$g_color_gray1" "$l_data" "$g_color_reset"

        if [ ! -z "$p_default_aspect_ratio" ] && [ "$l_id" = "$p_default_aspect_ratio" ]; then
            printf '      %bValor por defecto.%b\n' "$g_color_gray1" "$g_color_reset"
        fi

    done

}



# -------------------------------------------------------------------------------------
# Exported functions
# -------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------
# Subcomand > Android > Utility
# -------------------------------------------------------------------------------------

# Diccionario de subcomandos. La key es 'id del subcomando' y value es 'la descripcion del subcomando'.
# > Segun el ID de subcomando, se debe tener 2 funciones bash cuyo nombre tiene dicho ID
#   > Funcion de ayuda del comando tiene el nombre 'm_usage_SUBCMD-ID_SUBCMD-ID'.
#   > Funcion de controlador del comando tiene el nombre 'controller_SUBCMD-ID_SUBCMD-ID'.
declare -A gA_android_subcmd_ids=(
        ['connect']='Permite realizar un screen-mirrow de un dispositivo android usando scrcpy y ADB.'
        ['resize']='Permite modificar el tamaño de una ventana de screen-mirrow de android.'
    )

# Diccionario de subcomandos. La key es 'alias' y value es 'ID del subcomando'.
declare -A gA_android_subcmd_alias=(
    )

declare -A gA_android_aspect_ratios=(
        ['full']='Muestra en un ventana normal en fullscreen en el workspace 9.'
        ['3:2']='Muestra en un ventana float con relacion de aspecto 3:2 en el workspace actual.'
        ['9:20']='Muestra en un ventana float con relacion de aspecto 9:20 en el workspace actual.'
        ['20:9']='Muestra en un ventana float con relacion de aspecto 20:9 en el workspace actual.'
    )

g_default_android_aspect_ratio='3:2'



# -------------------------------------------------------------------------------------
# Subcomand > Android > Resize
# -------------------------------------------------------------------------------------

m_usage_android_resize() {

    local l_scmd_id='resize'
    local l_scmd_description="${gA_android_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s android %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s android %s%b ASPECT_SRC %bASPECT_DST%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h%b o %b--help%b Permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLos argumentos usados son:\n'
    printf '  > %bASPECT_SRC%b Define la primera ventana con dicha relacion de aspecto que se desea modificar el tamaño.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    m_show_aspect_info "gA_android_aspect_ratios" ""

    printf '  > %bASPECT_DST%b Define la relacion de aspecto destino usado para cambiar el tamaño de la ventana origen.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    m_show_aspect_info "gA_android_aspect_ratios" ""

}


m_android_window_resize() {

    #1. Argumentos
    local p_aspect_source="$1"
    local p_aspect_destination="$2"


    #2. Validaciones

    local l_aspect="$p_aspect_source"
    if [ "$p_aspect_source" = "full" ]; then
        l_aspect="fullscreen"
    fi

    #3. Obtener el titulo de la ventana con dicho aspecto
    local l_address=''
    local -i l_status=0
    l_address=$(hyprctl clients -j | jq -r --arg ASPECT "$l_aspect" '.[] | select(.class == "scrcpy" and (.title | startswith("Android screen " + $ASPECT))) | .address' | head -n 1 2> /dev/null)
    l_status=$?

    if [ $l_status -ne 0 ] || [ -z "$l_address" ] || [ "$l_address" = "null" ]; then
        printf "[%bERROR%b] No se encuentra un ventana mirrow-screen de un dispositivo android que sea creo con la relacion de aspecto '%b%s%b'.\n" \
               "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$p_aspect_source" "$g_color_reset"
        return 1
    fi

    printf "Se encuentra al menos una ventana mirrow-screen de '%b%s%b'. Se escoge la ventana con address '%b%s%b'.\n" \
           "$g_color_gray1" "scrcpy" "$g_color_reset" "$g_color_gray1" "$l_address" "$g_color_reset"


    #4. Obtener el ancho del monitor actual
    local l_mon_width=0
    l_mon_width=$(hyprctl monitors -j | jq -r '.[] | select(.focused).width' 2> /dev/null)
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf "[%bERROR%b] No se puede obtener el ancho del monitor actual'.\n" \
               "$g_color_red1" "$g_color_reset"
        return 1
    fi

    #5. Cambiar las dimensiones de la ventana
    printf "\nSe redimenciona la ventana con address '%b%s%b' a una relacion de aspecto '%b%s%b' ...\n" \
           "$g_color_gray1" "$l_address" "$g_color_reset" "$g_color_gray1" "$p_aspect_destination" "$g_color_reset"

    local l_cmd=''
    if [ "$p_aspect_destination" = "9:20" ]; then

        l_cmd="resizewindowpixel exact 602 1342,address:${l_address}"
        printf 'Ejecutando: %bhyprctl dispatch%b "%b%s%b" %b.\n' "$g_color_cian1" "$g_color_gray1" "$g_color_green1" "$l_cmd" "$g_color_gray1" "$g_color_reset"
        hyprctl dispatch "$l_cmd"

        l_cmd="movewindowpixel exact $((l_mon_width-606)) 45,address:${l_address}"
        printf 'Ejecutando: %bhyprctl dispatch%b "%b%s%b" %b.\n' "$g_color_cian1" "$g_color_gray1" "$g_color_green1" "$l_cmd" "$g_color_gray1" "$g_color_reset"
        hyprctl dispatch "$l_cmd"

        return 0

    fi

    if [ "$p_aspect_destination" = "20:9" ]; then

        l_cmd="resizewindowpixel exact 1714 778,address:${l_address}"
        printf 'Ejecutando: %bhyprctl dispatch%b "%b%s%b" %b.\n' "$g_color_cian1" "$g_color_gray1" "$g_color_green1" "$l_cmd" "$g_color_gray1" "$g_color_reset"
        hyprctl dispatch "$l_cmd"

        l_cmd="movewindowpixel exact $((l_mon_width-1718)) 45,address:${l_address}"
        printf 'Ejecutando: %bhyprctl dispatch%b "%b%s%b" %b.\n' "$g_color_cian1" "$g_color_gray1" "$g_color_green1" "$l_cmd" "$g_color_gray1" "$g_color_reset"
        hyprctl dispatch "$l_cmd"

        return 0
    fi


    printf "[%bERROR%b] No se implementado la logica para pasar a la relacion de aspecto destino '%b%s%b'.\n" \
           "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$p_aspect_destination" "$g_color_reset"

    return 1


}



# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
m_controller_android_resize() {

    #1. Validaciones previas


    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_android_resize
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_android_resize
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #3. Leer los argumentos restantes

    # 1er argumento
    if [ -z "$1" ]; then

        printf '[%bERROR%b] Se debe especificar la relacion de especto de la ventana origen a modificar su tamaño.\n' "$g_color_red1" "$g_color_reset"
        m_usage_android_resize
        return 3

    fi

    local l_aux=''
    local l_aspect_source="$1"
    l_aux="${gA_android_aspect_ratios[${l_aspect_source}]:-}"
    if [ -z "$l_aux" ]; then
        printf '[%bERROR%b] La relacion de aspecto de la ventana origen es inválido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$l_aspect_source" "$g_color_reset"
        m_usage_android_resize
        return 3
    fi

    # 2do argumento
    if [ -z "$2" ]; then

        printf '[%bERROR%b] Se debe especificar la relacion de especto de la ventana destino a modificar su tamaño.\n' "$g_color_red1" "$g_color_reset"
        m_usage_android_resize
        return 3

    fi

    local l_aux=''
    local l_aspect_destination="$2"
    l_aux="${gA_android_aspect_ratios[${l_aspect_destination}]:-}"
    if [ -z "$l_aux" ]; then
        printf '[%bERROR%b] La relacion de aspecto de la ventana destino es inválido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$l_aspect_destination" "$g_color_reset"
        m_usage_android_resize
        return 3
    fi


    #5. Ejecutando el comando
    m_android_window_resize "$l_aspect_source" "$l_aspect_destination"

    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand > Android > Connect
# -------------------------------------------------------------------------------------

declare -A gA_android_targets=(
        ['myphone']='7TD6OF8TH6U8XSAA'
        ['mytablet']='XCD1205AF825B14305'
    )


m_usage_android_connect() {

    local l_scmd_id='connect'
    local l_scmd_description="${gA_android_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s android %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s android %s%b [-s ASPECT] [-w] [-k] [-d] [-o] %b[-d DEV_SERIAL]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"
    printf '    %b%s android %s%b [-s ASPECT] [-w] [-k] [-d] [-o] %bDEV_ALIAS%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h%b o %b--help%b Permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-s ASPECT%b Define la relacion de aspecto de la ventana a usar. Esto define el window rule de hyprland a usar.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    m_show_aspect_info "gA_android_aspect_ratios" "$g_default_android_aspect_ratio"

    printf '  > %b-d DEV_SERIAL%b Define numero de serial del dispositivo que se desea conectar. Si especifca DEV_ALIAS, esta opcion se omitira.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '  > %b-w%b Evita que el dispositivo se considere inactivo (modo sleeping) si no se realiza una activada durante un determinado lapso de tiempo.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b    Activa temporalmente la opción de Android "Stay awake" mientras este conectado por USB y este cargandose. Requiere permisos para modificar "Settings.Global".%b\n' \
           "$g_color_gray1" "$g_color_reset"

    printf '  > %b-k%b Evita que el dispositivo se considere inactivo (modo sleeping) si no se realiza una activada durante un determinado lapso de tiempo.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b    Simula actividad periódica y NO requiere permisos para modificar "Settings.Global".%b\n' \
           "$g_color_gray1" "$g_color_reset"

    printf '  > %b-e%b Permite que la pantalla del computador (no del dispositivo android) se bloquee por inactividad.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '  > %b-o%b Apagar la pantalla física del teléfono cuando se conecta.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLos argumentos usados son:\n'
    printf '  > %bDEV_ALIAS%b Alias del dispositivo android al que se va a conectar.%b\n\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf 'Adicionalmente:\n'
    local l_targets=$(m_get_dictionary_info "gA_android_targets")
    printf '  > %bEl DEV_ALIAS pueden ser: %b%b\n\n' "$g_color_gray1" "$l_targets" "$g_color_reset"

}


m_connect_android() {

    #1. Argumentos
    local p_screen_type="$1"
    local p_device_serial="$2"
    local p_flag_stay_awake="$3"
    local p_flag_keep_active="$4"
    local p_flag_disable_screensaver="$5"
    local p_flag_turn_screen_off="$6"


    #2. Validaciones

    # Si se desea mostrar como full, debe estar habilitado el 2do monitor
    local l_title=""

    if [ "$p_screen_type" = "full" ]; then

        if ! hyprctl -j monitors | jq -e --arg MON "$g_monitor_name" '.[] | select(.name == $MON)' >/dev/null; then
            printf "Para el modo fullscreen, se requiuere que el 2do monitor '%b%s%b' está activo. Conecte su 2do monitor.\n" \
                   "$g_color_gray1" "$g_monitor_name" "$g_color_reset"
            return 1
        fi

        l_title="Android fullscreen"
    else
        l_title="Android screen ${p_screen_type}"
    fi

    #3. Determinar la ruta de los logs
    local l_log_path="${XDG_STATE_HOME:-$HOME/.local/state}/scrcpy"

    if [ ! -d "$l_log_path" ]; then
        mkdir -p "$l_log_path"
    fi


    #4. Creando el comando a ejecutar
    local l_log_file=''
    printf -v l_log_file '%s/scrcpy_%s.log' "$l_log_path" "$p_device_serial"

    local l_aux="-s ${p_device_serial} --window-title \"${l_title}\""

    local -a la_args=(
        "-s"
        "$p_device_serial"
        "--window-title"
        "${l_title}"
        )

    if [ "$p_flag_stay_awake" -eq 0 ]; then
        la_args+=("--stay-awake")
        l_aux="${l_aux} --stay-awake"
    fi

    if [ "$p_flag_keep_active" -eq 0 ]; then
        la_args+=("--keep-active")
        l_aux="${l_aux} --keep-active"
    fi


    if [ "$p_flag_disable_screensaver" -eq 0 ]; then
        la_args+=("--disable-screensaver")
        l_aux="${l_aux} --disable-screensaver"
    fi

    if [ "$p_flag_turn_screen_off" -eq 0 ]; then
        la_args+=("--turn-screen-off")
        l_aux="${l_aux} --turn-screen-off"
    fi


    #5. Ejecutando el comando
    printf 'Conectandose a la dispositivo android "%b%s%b" ...\n' "$g_color_gray1" "$p_device_serial" "$g_color_reset"
    printf '%bsetsid %bscrcpy %b%s > "%s" 2>&1 < /dev/null &%b\n' "$g_color_green1" "$g_color_cian1" "$g_color_gray1" \
           "$l_aux" "$l_log_file" "$g_color_reset"

    #echo "${la_args[@]}"
    local l_pid=0
    #scrcpy "${la_args[@]}"
    setsid scrcpy "${la_args[@]}" > "${l_log_file}" 2>&1 < /dev/null &

    # Obtener el ID del proceso (PID) del ultimo proceso ejecutado en background
    l_pid=$!

    printf '\nSe ha lanzado %bscrcpy%b en background:\n' "$g_color_gray1" "$g_color_reset"
    printf ' PID: %b%s%b\n' "$g_color_gray1" "$l_pid" "$g_color_reset"
    printf ' Log: %b%s%b\n\n' "$g_color_gray1" "$l_log_file" "$g_color_reset"

    return 0

}



# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
m_controller_android_connect() {

    #1. Validaciones previas
    if ! command -v adb >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "adb" "$g_color_reset"
        return 1
    fi

    if ! command -v scrcpy >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "scrcpy" "$g_color_reset"
        return 1
    fi


    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_screen_type="$g_default_android_aspect_ratio"
    local l_device_serial=""
    local -i l_flag_stay_awake=1
    local -i l_flag_keep_active=1
    local -i l_flag_disable_screensaver=1
    local -i l_flag_turn_screen_off=1


    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_android_connect
                return 0
                ;;

            -w)
                l_flag_stay_awake=0
                shift 1
                ;;

            -k)
                l_flag_keep_active=0
                shift 1
                ;;


            -e)
                l_flag_disable_screensaver=0
                shift 1
                ;;

            -o)
                l_flag_turn_screen_off=0
                shift 1
                ;;

            -s)
                local l_aux="${gA_android_aspect_ratios[${2}]:-}"
                if [ -z "$l_aux" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es inválido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-s" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage_android_connect
                    return 3
                fi

                l_screen_type="$2"
                shift 2
                ;;


            -d)
                if [ -z "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" debe indicar la serial del dispositivo android\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-d" "$g_color_reset"
                    m_usage_android_connect
                    return 3
                fi

                l_device_serial="$2"
                shift 2
                ;;



            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_android_connect
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #3. Leer los argumentos restantes
    local l_aux=''
    # Obtener el serial del dispositivo (wifi o usb)
    if [ ! -z "$1" ]; then

        # Se envia el ID de la VM de QEMU
        local l_alias="$1"
        l_aux="${gA_android_targets[${l_alias}]:-}"
        if [ -z "$l_aux" ]; then
            printf '[%bERROR%b] El alias del dispositivo android ingresada es inválido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$l_vm_id" "$g_color_reset"
            m_usage_android_connect
            return 3
        fi

        l_device_serial="$l_aux"

    fi

    # Si no especifico una serial, obtener el 1er dispositivo conectado
    local -i l_status=0
    if [ -z "$l_device_serial" ]; then

        # Obtenener el resultado excepto la 1ra linea y de alli obtener el 1er dispostivos que estan en estado conectado
        l_aux=$(adb devices 2> /dev/null | tail -n +2 | grep 'device$' | tail -n 1)
        l_status=$?

        if [ $l_status -ne 0 ]; then
            printf '[%bERROR%b] Ocurrio un error en obtener el 1er dispositivo android en estado conectado.\n' "$g_color_red1" "$g_color_reset"
            return 3
        fi

        if [ -z "$l_aux" ]; then
            printf '[%bERROR%b] No se encuentra al menos un dispositivo android conectado.\n' "$g_color_red1" "$g_color_reset"
            return 3
        fi

        local la_items=(${l_aux})
        l_device_serial="${la_items[0]}"

        printf '[%bINFO%b] El usuario no especifico el dispositivo android a usar. Se ha escogio el dispositivo android "%b%s%b".\n' "$g_color_yellow1" "$g_color_reset" \
               "$g_color_gray1" "$l_device_serial" "$g_color_reset"

    # Si especifica una serial, validar si es de un disposito conectado
    else

        l_aux=$(adb -s "$l_device_serial" get-state 2>&1)
        l_status=$?

        if [ $l_status -ne 0 ]; then

            case "$l_aux" in
                *found*)
                    printf '[%bERROR%b] El dispositivo android "%b%s%b" no esta conectado.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "$l_device_serial" "$g_color_reset"
                    ;;
                *unauthorized*)
                    printf '[%bERROR%b] El dispositivo android "%b%s%b" esta conectado pero no esta autorizado.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "$l_device_serial" "$g_color_reset"
                    ;;
                *)
                    printf '[%bERROR%b] El dispositivo android "%b%s%b" esta disponible.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "$l_device_serial" "$g_color_reset"
                    ;;
            esac

            return 3
        fi

        if [ "$l_aux" != "device" ]; then

            printf '[%bERROR%b] El dispositivo android "%b%s%b" esta en estado "%b%s%b".\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$l_device_serial" "$g_color_reset" "$g_color_red1" "$l_aux" "$g_color_reset"

            return 3

        fi

    fi

    #5. Ejecutando el comando
    m_connect_android "$l_screen_type" "$l_device_serial" "$l_flag_stay_awake" "$l_flag_keep_active" "$l_flag_disable_screensaver" "$l_flag_turn_screen_off"

    return 0

}



# -------------------------------------------------------------------------------------
# Subcomand > Android > Main controller
# -------------------------------------------------------------------------------------


m_usage_android() {

    local l_scmd_id='android'
    local l_scmd_description="${gA_global_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '  %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b SUBCOMMAND%b [options] [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones globales usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nEl argumento principal es el nombre del subcomando %bSUBCOMMAND%b. Los cuales puede ser:\n' "$g_color_green1" "$g_color_reset"
    m_get_subcmd_infos "gA_android_subcmd_ids" "gA_android_subcmd_alias"
    printf '\n'

}


# Funcion principal de entrada
# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
#
m_controller_android() {

    #1. Validaciones previas

    #2. Procesar las opciones globales
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help|help)
                m_usage_android
                return 0
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_android
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Procesar el 1er argumentos (nombre del subcomando o alias)
    if [ -z "$1" ]; then
        printf '[%bERROR%b] Se debe especificarse un subcomando.\n\n' "$g_color_red1" "$g_color_reset"
        m_usage_android
        return 3
    fi

    # Identificar si es un alias
    local l_scmd_id="${gA_android_subcmd_alias[${1}]:-}"

    # Validar si es un ID de subcomando valido
    if [ -z "$l_scmd_id" ]; then
        l_scmd_id="$1"
    fi

    local l_scmd_description="${gA_android_subcmd_ids[${l_scmd_id}]:-}"

    if [ -z "$l_scmd_description" ]; then
        printf '[%bERROR%b] El subcomando ingresado "%b%s%b" no es valida\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$l_scmd_id" "$g_color_reset"
        m_usage_android
        return 3
    fi

    shift

    #5. Ejecutando el controlador principal del subcomando

    "m_controller_android_${l_scmd_id}" "$@"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand > Spice > Utility
# -------------------------------------------------------------------------------------

# Diccionario de subcomandos. La key es 'id del subcomando' y value es 'la descripcion del subcomando'.
# > Segun el ID de subcomando, se debe tener 2 funciones bash cuyo nombre tiene dicho ID
#   > Funcion de ayuda del comando tiene el nombre 'm_usage_SUBCMD-ID_SUBCMD-ID'.
#   > Funcion de controlador del comando tiene el nombre 'controller_SUBCMD-ID_SUBCMD-ID'.
declare -A gA_spice_subcmd_ids=(
        ['connect']='Permite conectar a una VM usando remote-viewer y SPICE'
    )

# Diccionario de subcomandos. La key es 'alias' y value es 'ID del subcomando'.
declare -A gA_spice_subcmd_alias=(
    )

declare -A gA_spice_aspect_ratios=(
        ['full']='Muestra en un ventana normal en fullscreen en el workspace 8.'
        ['16:9']='Muestra en un ventana float con relacion de aspecto 16:9 en el workspace actual.'
        ['8:5']='Muestra en un ventana float con relacion de aspecto 8:5 en el workspace actual.'
    )

g_default_spice_aspect_ratio=''
#g_default_spice_aspect_ratio='16:9'



# -------------------------------------------------------------------------------------
# Subcomand > Spice > Connect
# -------------------------------------------------------------------------------------

declare -A gA_spice_targets=(
        ['vmphoenix']='127.0.0.1:5930'
    )

m_usage_spice_connect() {

    local l_scmd_id='connect'
    local l_scmd_description="${gA_spice_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s spice %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s spice %s%b [-s ASPECT] %bPORT [HOST]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"
    printf '    %b%s spice %s%b [-s ASPECT] %bVM_NAME%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h%b o %b--help%b Permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-s ASPECT%b Define la relacion de aspecto de la ventana a usar. Esto define el window rule de hyprland a usar.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    m_show_aspect_info "gA_spice_aspect_ratios" "$g_default_spice_aspect_ratio"

    printf '\nLos argumentos usados son:\n'
    printf '  > %bPORT%b Puerto TCP del protocolo SPICE expuesto por la VM.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bHOST%b IP a usar donde se expone el puerto SPICE.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bVM_NAME%b Nombre de la VM al que se va a conectar.%b\n\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf 'Adicionalmente:\n'
    local l_targets=$(m_get_dictionary_info "gA_spice_targets")
    printf '  > %bEl VM_NAME pueden ser: %b%b\n\n' "$g_color_gray1" "$l_targets" "$g_color_reset"

}


m_connect_spice() {

    #1. Argumentos
    local -i p_port="$1"
    local p_host="$2"
    local p_screen_type="$3"

    #2. Validaciones

    # Si se desea mostrar como full, debe estar habilitado el 2do monitor
    local l_title=""

    if [ "$p_screen_type" = "full" ]; then

        if ! hyprctl -j monitors | jq -e --arg MON "$g_monitor_name" '.[] | select(.name == $MON)' >/dev/null; then
            printf "Para el modo fullscreen, se requiuere que el 2do monitor '%b%s%b' está activo. Conecte su 2do monitor.\n" \
                   "$g_color_gray1" "$g_monitor_name" "$g_color_reset"
            return 1
        fi

        l_title="SPICE fullscreen - Port ${p_port}"
    else
        if [ -z "$p_screen_type" ]; then
            l_title="SPICE normal screen - Port ${p_port}"
        else
            l_title="SPICE screen ${p_screen_type} - Port ${p_port}"
        fi
    fi

    # Validar si el puerto SPICE esta en escucha
    if ! ss -ltn | grep ":${p_port} " &> /dev/null; then

        printf 'El puerto TCP "%b%s%b" NO esta activo y en escucha. Debe iniciar la VM antes de conectarse a ella.\n' \
               "$g_color_gray1" "$p_port" "$g_color_reset"
        return 1

    fi


    #3. Determinar la ruta de los logs
    local l_log_path="${XDG_STATE_HOME:-$HOME/.local/state}/spice"

    if [ ! -d "$l_log_path" ]; then
        mkdir -p "$l_log_path"
    fi


    #4. Creando el comando a ejecutar
    local l_log_file=''
    printf -v l_log_file '%s/remote-viewer_%s_%s.log' "$l_log_path" "$p_host" "$p_port"

    #5. Ejecutando el comando
    printf 'Conectandose a la VM "%b%s:%s%b" ...\n' "$g_color_gray1" "$p_host" "$p_port" "$g_color_reset"
    printf '%bsetsid %bremote-viewer %b--title "%s" "spice://%s:%s" > "%s" 2>&1 < /dev/null &%b\n' "$g_color_green1" "$g_color_cian1" "$g_color_gray1" \
           "$l_title" "$p_host" "$p_port" "$l_log_file" "$g_color_reset"

    local l_pid=0
    setsid remote-viewer --title "$l_title" "spice://${p_host}:${p_port}" > "${l_log_file}" 2>&1 < /dev/null &

    # Obtener el ID del proceso (PID) del ultimo proceso ejecutado en background
    l_pid=$!

    printf '\nSe ha lanzado %bremote-viewer%b en background:\n' "$g_color_gray1" "$g_color_reset"
    printf ' PID: %b%s%b\n' "$g_color_gray1" "$l_pid" "$g_color_reset"
    printf ' Log: %b%s%b\n\n' "$g_color_gray1" "$l_log_file" "$g_color_reset"

    return 0

}



# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
m_controller_spice_connect() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local l_screen_type="$g_default_spice_aspect_ratio"

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_spice_connect
                return 0
                ;;

            -s)
                local l_aux="${gA_spice_aspect_ratios[${2}]:-}"
                if [ -z "$l_aux" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es inválido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-s" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage_spice_connect
                    return 3
                fi

                l_screen_type="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_spice_connect
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #3. Leer los argumentos restantes
    local -i p_port=0
    local p_host=""

    if [[ "$1" =~ ^[0-9]+$ ]]; then

        # Se envia el puerto y el host
        p_port=$1
        if [ ! -z "$2" ]; then
            p_host="$2"
        else
            p_host="127.0.0.1"
        fi

    else

        # Se envia el ID de la VM de QEMU
        local l_vm_id="$1"
        local l_aux="${gA_spice_targets[${l_vm_id}]:-}"
        if [ -z "$l_aux" ]; then
            printf '[%bERROR%b] El argumento de la VM ingresada es inválido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$l_vm_id" "$g_color_reset"
            m_usage_spice_connect
            return 3
        fi

        # Obtener el puerto y el host
        local IFS=':'
        local la_items=(${l_aux})
        p_host="${la_items[0]}"
        p_port="${la_items[1]}"

    fi

    #4. Validaciones generales
    if [ -z "$p_host" ]; then

        printf '[%bERROR%b] El host "%s" es invalido(s)\n' "$g_color_red1" "$g_color_reset" "$p_host"
        return 3
    fi

    if [ $p_port -le 0 ] || [ $p_port -ge 65535 ]; then

        printf 'El TCP port "%b%s%b" no es valido, este debe estar entre <0, 65535>.\n' \
            "$g_color_gray1" "$p_port" "$g_color_reset"
        return 1
    fi


    #5. Ejecutando el comando
    m_connect_spice $p_port "$p_host" "$l_screen_type"

    return 0

}



# -------------------------------------------------------------------------------------
# Subcomand > Spice > Main controller
# -------------------------------------------------------------------------------------


m_usage_spice() {

    local l_scmd_id='spice'
    local l_scmd_description="${gA_global_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '  %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s %s%b SUBCOMMAND%b [options] [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nLas opciones globales usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '\nEl argumento principal es el nombre del subcomando %bSUBCOMMAND%b. Los cuales puede ser:\n' "$g_color_green1" "$g_color_reset"
    m_get_subcmd_infos "gA_spice_subcmd_ids" "gA_spice_subcmd_alias"
    printf '\n'

}


# Funcion principal de entrada
# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
#
m_controller_spice() {

    #1. Validaciones previas
    if ! command -v remote-viewer >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "remote-viewer" "$g_color_reset"
        return 1
    fi


    #2. Procesar las opciones globales
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help|help)
                m_usage_spice
                return 0
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_spice
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Procesar el 1er argumentos (nombre del subcomando o alias)
    if [ -z "$1" ]; then
        printf '[%bERROR%b] Se debe especificarse un subcomando.\n\n' "$g_color_red1" "$g_color_reset"
        m_usage_spice
        return 3
    fi

    # Identificar si es un alias
    local l_scmd_id="${gA_spice_subcmd_alias[${1}]:-}"

    # Validar si es un ID de subcomando valido
    if [ -z "$l_scmd_id" ]; then
        l_scmd_id="$1"
    fi

    local l_scmd_description="${gA_spice_subcmd_ids[${l_scmd_id}]:-}"

    if [ -z "$l_scmd_description" ]; then
        printf '[%bERROR%b] El subcomando ingresado "%b%s%b" no es valida\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$l_scmd_id" "$g_color_reset"
        m_usage_spice
        return 3
    fi

    shift

    #5. Ejecutando el controlador principal del subcomando

    "m_controller_spice_${l_scmd_id}" "$@"
    return 0

}



# -------------------------------------------------------------------------------------
# Main code > Utilities
# -------------------------------------------------------------------------------------

m_get_exported_functions() {

    # Recorrer la lista de parametros identificados ....
    local l_infos=""
    local l_id

    for l_id in "${ga_exported_functions[@]}"; do

        if [ -z "$l_infos" ]; then
            printf -v l_infos "'%b%s%b'" "$g_color_yellow1" "$l_id" "$g_color_reset"
        else
            printf -v l_infos "%b, '%b%s%b'" "$l_infos" "$g_color_yellow1" "$l_id" "$g_color_reset"
        fi

    done

    echo "$l_infos"

}

m_is_function_exported() {

    local p_func_name="$1"

    if [ -z "$p_func_name" ]; then
        return 1
    fi

    local l_found=1
    local l_item

    for l_item in "${ga_exported_functions[@]}"; do

        if [[ "$l_item" == "$p_func_name" ]]; then
            l_found=0
            break
        fi

    done

    return $l_found

}

m_usage_global() {

    local l_infos=""
    l_infos=$(m_get_exported_functions)

    printf 'Usage:\n'
    printf '  %b%s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s%b SUBCOMMAND%b [options] [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    if [ ! -z "$l_infos" ]; then
        printf '  %b%s%b -i FUNC_NAME [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    fi

    printf '\nLas opciones globales usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    if [ ! -z "$l_infos" ]; then
        printf '%b  > %b-i FUNC_NAME%b Especifica el nombre de la funcion interna del script a ejecutar (uso interno y/o debugging).%b\n' \
               "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
        printf '    %bFUNC_NAME puede ser:%b %b\n' "$g_color_gray1" "$g_color_reset" "$l_infos"
    fi

    printf '\nEl argumento principal es el nombre del subcomando %bSUBCOMMAND%b. Los cuales puede ser:\n' "$g_color_green1" "$g_color_reset"
    m_get_subcmd_infos "gA_global_subcmd_ids" "gA_global_subcmd_alias"
    printf '\n'

}



# -------------------------------------------------------------------------------------
# Main code > Main Function
# -------------------------------------------------------------------------------------

# Funcion principal de entrada
# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
#
main() {

    #1. Validaciones previas

    # Validar comando requeridos
    if ! command -v jq >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "jq" "$g_color_reset"
        return 1
    fi

    if ! command -v hyprland >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "hyprland" "$g_color_reset"
        return 1
    fi

    if ! command -v hyprctl >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "hyprctl" "$g_color_reset"
        return 1
    fi


    #2. Procesar las opciones globales
    local l_func_name=""

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help|help)
                m_usage_global
                return 0
                ;;

            -i)
                m_is_function_exported "$2"
                local l_found=$?
                if [ "$l_found" -ne 0 ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no es function exportada valida: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-i" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage_global
                    return 3
                fi

                l_func_name="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_global
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #3. Si es una funcion exportada, invocarlo
    if [ ! -z "$l_func_name" ]; then
        "$l_func_name" "$@"
        return 0
    fi


    #4. Procesar el 1er argumentos (nombre del subcomando o alias)
    if [ -z "$1" ]; then
        printf '[%bERROR%b] Se debe especificarse un subcomando.\n\n' "$g_color_red1" "$g_color_reset"
        m_usage_global
        return 3
    fi

    # Identificar si es un alias
    local l_scmd_id="${gA_global_subcmd_alias[${1}]:-}"

    # Validar si es un ID de subcomando valido
    if [ -z "$l_scmd_id" ]; then
        l_scmd_id="$1"
    fi

    local l_scmd_description="${gA_global_subcmd_ids[${l_scmd_id}]:-}"

    if [ -z "$l_scmd_description" ]; then
        printf '[%bERROR%b] El subcomando ingresado "%b%s%b" no es valida\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$l_scmd_id" "$g_color_reset"
        m_usage_global
        return 3
    fi

    shift

    #5. Ejecutando el controlador principal del subcomando

    "m_controller_${l_scmd_id}" "$@"
    return 0

}



# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $_g_result
