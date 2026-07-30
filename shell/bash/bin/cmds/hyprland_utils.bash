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

# Alias de las VM a conectarse
declare -A gA_spice_targets=(
        ['vmphoenix']='127.0.0.1:5930'
    )

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
# Hyprland utilities
# -------------------------------------------------------------------------------------

# Determina si un workspace tiene ventanas
m_workspace_is_empty() {

    local p_workspace_id="$1"

    local l_result
    l_result=$(hyprctl clients -j | jq -e --argjson ws "$p_workspace_id" '.[] | select(.workspace.id == $ws)' 2> /dev/null)

    if [ -z "$l_result" ]; then
        return 0
    fi

    return 1

}

# Obtiene informacion del workspace actual
m_current_workspace_info() {

    local -i l_status=0

    local l_jquery='"\(.id)|\(.tiledLayout)|\(.windows)|\(.monitor)"'

    local l_result
    l_result=$(hyprctl activeworkspace -j | jq -r "$l_jquery" 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_result" ]; then
        return 9
    fi

    echo "$l_result"
    return 0

}


# Obtiene la direccion de la 1ra ventana de un workspace que sea de una determinada clases
m_get_window_address() {

    local p_workspace_id="$1"

    local p_class="$2"
    local p_title="$3"

    local -i p_is_prefix=1
    if [ "$4" = "0" ]; then
        p_is_prefix=0
    fi
    local -n r_address="$5"

    local l_jquery=".workspace.id == ${p_workspace_id}"

    if [ ! -z "$p_class" ]; then
        printf -v l_jquery '%s and .class == "%s"' "$l_jquery" "$p_class"
    fi

    if [ ! -z "$p_title" ]; then
        if [ $p_is_prefix -eq 0 ]; then
            printf -v l_jquery '%s and (.title | startswith("%s"))' "$l_jquery" "$p_title"
        else
            printf -v l_jquery '%s and .title == "%s"' "$l_jquery" "$p_title"
        fi
    fi

    printf -v l_jquery '.[] | select(%s) | .address' "$l_jquery"
    #echo "l_jquery: ${l_jquery}"

    local l_result
    local -i l_status=0
    l_result=$(hyprctl clients -j | jq -r "$l_jquery")
    l_status=$?

    if [ $l_status -ne 0 ] || [ -z "$l_result" ]; then
        r_address=""
        return 1
    fi

    # Mostrar siempre el primero de la fila
    r_address=$(echo "$l_result" | head -n 1)
    return 0

}

# Busca la primera ventana de una clase especifica que existe en un workspace y devuelve su address.
m_wait_for_window() {

    local p_workspace_id="$1"

    local p_class="$2"
    local p_title="$3"

    local -i p_is_prefix=1
    if [ "$4" = "0" ]; then
        p_is_prefix=0
    fi

    local -n r_address="$5"

    local -i l_n=20
    local -i l_i
    local l_address

    for l_i in {1..20}; do

        m_get_window_address "$p_workspace_id" "$p_class" "$p_title" "$p_is_prefix" "l_address"
        if [ ! -z "$l_address" ]; then
            r_address="$l_address"
            return 0
        fi

        printf 'Esperando %b%s%b segundos al window "%b%s%b" (%b%s de %s intentos%b)\n' "$g_color_reset" "0.2" "$g_color_reset" \
           "$g_color_gray1" "$p_class" "$g_color_reset" "$g_color_gray1" "$l_i" "$l_n" "$g_color_reset"
        sleep 0.2

    done

    r_address=""
    return 1

}

 # Tolerancia para comparar posiciones/tamaños (considera los huecos entre ventanas 'gaps_in' y 'gaps_out'.
 declare -ri g_tolerance_window=4

# > Valor de retorno :
#   > 9 : Parametros invalidos (por ejemplo, no existe una de las ventanas a comparar).
#   > 0 : Esta en posicion horizontal
#   > 1 : Esta en posicion vertical
#   > 2 : No se pudo determinar la posicion de los splits
m_compare_split_windows() {

    local p_address_rviewer="$1"
    local p_address_foot="$2"

    local -i l_status=0

    local l_result
    local l_jquery='.[] | select(.address == $addr) | "\(.at[0])|\(.at[1])|\(.size[0])|\(.size[1])"'

    # Leer la informacion de la ventana remote-viewer
    l_result=$(hyprctl clients -j | jq -r --arg addr "$p_address_rviewer" "$l_jquery" 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_result" ]; then
        return 9
    fi
    #echo "l_result: $l_result"

    local -i l_x1=0 l_y1=0 l_w1=0 l_h1=0
    IFS='|' read -r l_x1 l_y1 l_w1 l_h1 <<< "$l_result"

    # Leer la informacion de la ventana foot
    l_result=$(hyprctl clients -j | jq -r --arg addr "$p_address_foot" "$l_jquery" 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_result" ]; then
        return 9
    fi
    #echo "l_result: $l_result"


    local -i l_x2=0 l_y2=0 l_w2=0 l_h2=0
    IFS='|' read -r l_x2 l_y2 l_w2 l_h2 <<< "$l_result"

    # Comprobar si están en split horizontal (misma X y mismo ancho)
    if (( (l_x1 - l_x2) < g_tolerance_window && (l_x2 - l_x1) < g_tolerance_window )) && \
       (( (l_w1 - l_w2) < g_tolerance_window && (l_w2 - l_w1) < g_tolerance_window )); then
        return 0
    fi

    # Comprobar si están en split vertical (misma Y y misma altura)
    if (( (l_y1 - l_y2) < g_tolerance_window && (l_y2 - l_y1) < g_tolerance_window )) && \
       (( (l_h1 - l_h2) < g_tolerance_window && (l_h2 - l_h1) < g_tolerance_window )); then
        return 1
    fi

    # No se puede determinar la posicion de los splits.
    return 2

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
        ['newcol']='Permite crear una nueva columna en un layout scrolling mostando un dispositivo android'
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

g_default_android_aspect_ratio=''



# -------------------------------------------------------------------------------------
# Subcomand > Android > Resize
# -------------------------------------------------------------------------------------

m_usage_android_resize() {

    local l_scmd_id='resize'
    local l_scmd_description="${gA_android_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s android %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s android %s%b ASPECT_SRC %bASPECT_DST%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" \
           "$g_color_yellow1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h%b o %b--help%b Permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_green1" \
           "$g_color_gray1" "$g_color_reset"

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

    if [ -z "$p_aspect_source" ]; then
        return 1
    fi

    local l_aspect="$p_aspect_source"
    if [ "$p_aspect_source" = "full" ]; then
        l_aspect="fullscreen"
    fi

    # Obtneer el ID del workspace
    local -i l_status=0
    local l_data
    l_data=$(m_current_workspace_info)
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf 'No se ha podido obtener informacion del workspace actual ("%b%s%b").\n' "$g_color_gray1" "$p_workspace_id" \
               "$g_color_reset"
        return 1
    fi

    local l_ws_id l_ws_layout l_ws_windows l_ws_monitor
    IFS='|' read -r l_ws_id l_ws_layout l_ws_windows l_ws_monitor <<< "$l_data"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf 'No se ha podido obtener informacion del workspace actual ("%b%s%b").\n' "$g_color_gray1" "$p_workspace_id" \
               "$g_color_reset"
        return 1
    fi

    printf '> El workspace actual: ID " %b%s%b", Layout "%b%s%b", Nbr Windows "%b%s%b", Monitor "%b%s%b".\n' "$g_color_gray1" \
           "$l_ws_id" "$g_color_reset" "$g_color_gray1" "$l_ws_layout" "$g_color_reset" "$g_color_gray1" "$l_ws_windows" "$g_color_reset" \
           "$g_color_gray1" "$l_ws_monitor" "$g_color_reset"

    #if [ "$l_ws_layout" != "scrolling" ]; then
    #    printf 'El workspace actual debe tener layout "%b%s%b".\n' "$g_color_gray1" "dwindle" "$g_color_reset"
    #    return 1
    #fi


    # Esperar que aparezca la mirror de android y buscar su address
    local l_winclass_scrcpy='scrcpy'
    local l_title_prefix="Android screen ${l_aspect}"
    printf '> Buscando el %baddress%b de la ventana class "%b%s%b" y con titulo prefijo "%b%s%b" ...\n' "$g_color_gray1" "$g_color_reset" \
           "$g_color_gray1" "$l_winclass_scrcpy" "$g_color_reset" "$g_color_gray1" "$l_title_prefix" "$g_color_reset"

    local l_addr_scrcpy=""
    m_wait_for_window "$l_ws_id" "$l_winclass_scrcpy" "$l_title_prefix" 0 "l_addr_scrcpy"

    if [ -z "$l_addr_scrcpy" ]; then
        printf 'Window class "%b%s%b" no fue encontrado dentro de un rango de tiempo.\n' "$g_color_gray1" "$l_winclass_scrcpy" "$g_color_reset"
        return 1
    fi

    printf 'Window class "%b%s%b" encontrado con address "%b%s%b".\n' "$g_color_gray1" "$l_winclass_scrcpy" "$g_color_reset" \
           "$g_color_gray1" "$l_addr_scrcpy" "$g_color_reset"


    #4. Obtener el ancho del monitor actual
    local l_mon_width=0   # MOnitor actual es de 5120
    l_mon_width=$(hyprctl monitors -j | jq -r '.[] | select(.focused).width' 2> /dev/null)
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf "[%bERROR%b] No se puede obtener el ancho del monitor actual'.\n" \
               "$g_color_red1" "$g_color_reset"
        return 1
    fi

    printf '> El monitor actual "%b%s%b" tiene un width de "%b%s%b".\n' "$g_color_gray1" "$l_ws_monitor" "$g_color_reset" \
           "$g_color_gray1" "$l_mon_width" "$g_color_reset"

    #5. Cambiar las dimensiones de la ventana
    printf "> Se redimenciona la ventana '%b%s%b' con address '%b%s%b' ...\n" \
           "$g_color_gray1" "$l_winclass_scrcpy" "$g_color_reset" "$g_color_gray1" "$l_addr_scrcpy" "$g_color_reset"

    local l_width
    local l_height
    local l_at_x
    local l_at_y

    if [ "$p_aspect_destination" = "9:20" ]; then

        l_width=602
        l_height=1342
        l_at_x=$((l_mon_width - 606))
        l_at_y=45

    elif [ "$p_aspect_destination" = "20:9" ]; then

        l_width=1714
        l_height=778
        l_at_x=$((l_mon_width - 1718 - 1024))
        l_at_y=45

    fi

    if [ -z "$l_width" ]; then

        printf "[%bERROR%b] No se implementado la logica para pasar a la relacion de aspecto destino '%b%s%b'.\n" \
               "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$p_aspect_destination" "$g_color_reset"

        return 1

    fi


    printf '> Change size: %bhyprctl dispatch "hl.dsp.window.resize({ x = %s, y = %s, window = \"address:%s\" })"%b\n' \
           "$g_color_gray1" "$l_width" "$l_height" "$l_addr_scrcpy"  "$g_color_reset"
    hyprctl dispatch "hl.dsp.window.resize({ x = ${l_width}, y = ${l_height}, window = \"address:${l_addr_scrcpy}\" })"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    printf '> Move: %bhyprctl dispatch "hl.dsp.window.move({ x = %s, y = %s, window = \"address:%s\" })"%b\n' \
           "$g_color_gray1" "$l_at_x" "$l_at_y" "$l_addr_scrcpy"  "$g_color_reset"
    hyprctl dispatch "hl.dsp.window.move({ x = ${l_at_x}, y = ${l_at_y}, window = \"address:${l_addr_scrcpy}\" })"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    return 0

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
    printf '    %b%s android %s%b [-s ASPECT] [-w] [-k] [-d] [-o] %b[-d DEV_SERIAL]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
                "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"
    printf '    %b%s android %s%b [-s ASPECT] [-w] [-k] [-d] [-o] %bDEV_ALIAS%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h%b o %b--help%b Permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_green1" \
           "$g_color_gray1" "$g_color_reset"
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

    if [ -z "$p_screen_type" ]; then
        l_title="Android normal"
    elif [ "$p_screen_type" = "full" ]; then

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
    printf ' Log: %b%s%b\n' "$g_color_gray1" "$l_log_file" "$g_color_reset"

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

        printf '[%bINFO%b] El usuario no especifico el dispositivo android a usar. Se ha escogio el dispositivo android "%b%s%b".\n' \
               "$g_color_yellow1" "$g_color_reset" "$g_color_gray1" "$l_device_serial" "$g_color_reset"

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
# Subcomand > showandroid > Main controller
# -------------------------------------------------------------------------------------

declare -A gA_android_nc_height=(
        # Mi celular
        ['7TD6OF8TH6U8XSAA']='-222'
        # Mi tablet
        ['XCD1205AF825B14305']='62'
    )

declare -r g_winclass_term_nc='foot_newcol'

m_usage_android_newcol() {

    local l_scmd_id='newcol'
    local l_scmd_description="${gA_global_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '  %b%s android %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s android %s%b [-x WORKDIR] [-w] [-k] [-d] [-o] %b[-d DEV_SERIAL]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"
    printf '  %b%s android %s%b [-x WORKDIR] [-w] [-k] [-d] [-o] %bDEV_ALIAS%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h%b o %b--help%b Permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_green1" \
           "$g_color_gray1" "$g_color_reset"
    printf '  > %b-d DEV_SERIAL%b Define numero de serial del dispositivo que se desea conectar. Si especifca DEV_ALIAS, esta opcion se omitira.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf '%b  > %b-x WORKDIR%b Ruta de directorio de trabajo con la que se abrira la terminal.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
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



m_android_newcol() {

    #1. Argumentos
    local p_device_serial="$1"
    local p_flag_stay_awake="$2"
    local p_flag_keep_active="$3"
    local p_flag_disable_screensaver="$4"
    local p_flag_turn_screen_off="$5"
    local p_workdir="$6"

    # Validar que el workspace sea de layout dwindle
    local -i l_status=0
    local l_data
    l_data=$(m_current_workspace_info)
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf 'No se ha podido obtener informacion del workspace actual ("%b%s%b").\n' "$g_color_gray1" "$p_workspace_id" \
               "$g_color_reset"
        return 1
    fi

    local l_ws_id l_ws_layout l_ws_windows l_ws_monitor
    IFS='|' read -r l_ws_id l_ws_layout l_ws_windows l_ws_monitor <<< "$l_data"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf 'No se ha podido obtener informacion del workspace actual ("%b%s%b").\n' "$g_color_gray1" "$p_workspace_id" \
               "$g_color_reset"
        return 1
    fi

    printf '> El workspace actual: ID " %b%s%b", Layout "%b%s%b", Nbr Windows "%b%s%b", Monitor "%b%s%b".\n' "$g_color_gray1" \
           "$l_ws_id" "$g_color_reset" "$g_color_gray1" "$l_ws_layout" "$g_color_reset" "$g_color_gray1" "$l_ws_windows" "$g_color_reset" \
           "$g_color_gray1" "$l_ws_monitor" "$g_color_reset"

    if [ "$l_ws_layout" != "scrolling" ]; then
        printf 'El workspace actual debe tener layout "%b%s%b".\n' "$g_color_gray1" "dwindle" "$g_color_reset"
        return 1
    fi

    # Abrir foot (ventana C)
    printf '> Iniciando window "%b%s%b" ...\n' "$g_color_gray1" "$g_winclass_term_nc" "$g_color_reset"
    if [ -z "$p_workdir" ]; then
        printf '%bfootclient --no-wait --app-id "%s"%b\n' "$g_color_gray1" "$g_winclass_term_nc" "$g_color_reset"
        footclient --no-wait --app-id "$g_winclass_term_nc"
    else
        printf '%bfootclient --no-wait --app-id "%s" -D "%s"%b\n' "$g_color_gray1" "$g_winclass_term_nc" "$p_workdir" "$g_color_reset"
        footclient --no-wait --app-id "$g_winclass_term_nc" -D "$p_workdir"
    fi


    local l_wait_time="0.5"
    printf 'Wait %b%s%b seconds ...\n' "$g_color_gray1" "$l_wait_time" "$g_color_reset"
    sleep "$l_wait_time"

    # Abrir la ventana de mirror del dispositivo android
    local l_winclass_scrcpy='scrcpy'
    printf '> Iniciando window "%b%s%b" ...\n' "$g_color_gray1" "$l_winclass_scrcpy" "$g_color_reset"

    m_connect_android "" "$p_device_serial" "$p_flag_stay_awake" "$p_flag_keep_active" "$p_flag_disable_screensaver" \
                     "$p_flag_turn_screen_off"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    local l_wait_time="1.0"
    printf 'Wait %b%s%b seconds ...\n' "$g_color_gray1" "$l_wait_time" "$g_color_reset"
    sleep "$l_wait_time"

    # Esperar que aparezca la terminal y buscar su address
    printf '> Buscando el %baddress%b de la ventana class "%b%s%b" recien creada ...\n' "$g_color_gray1" "$g_color_reset" \
           "$g_color_gray1" "$g_winclass_term_nc" "$g_color_reset"

    local l_addr_term=""
    m_wait_for_window "$l_ws_id" "$g_winclass_term_nc" "" 1 "l_addr_term"

    if [ -z "$l_addr_term" ]; then
        printf 'Window class "%b%s%b" no fue encontrado dentro de un rango de tiempo.\n' "$g_color_gray1" "$g_winclass_term_nc" "$g_color_reset"
        return 1
    fi

    printf 'Window class "%b%s%b" encontrado con address "%b%s%b".\n' "$g_color_gray1" "$g_winclass_term_nc" "$g_color_reset" \
           "$g_color_gray1" "$l_addr_term" "$g_color_reset"


    # Esperar que aparezca la mirror de android y buscar su address
    local l_title_prefix='Android normal'
    printf '> Buscando el %baddress%b de la ventana class "%b%s%b" recien creada ...\n' "$g_color_gray1" "$g_color_reset" \
           "$g_color_gray1" "$l_winclass_scrcpy" "$g_color_reset"

    local l_addr_scrcpy=""
    m_wait_for_window "$l_ws_id" "$l_winclass_scrcpy" "$l_title_prefix" 0 "l_addr_scrcpy"

    if [ -z "$l_addr_scrcpy" ]; then
        printf 'Window class "%b%s%b" no fue encontrado dentro de un rango de tiempo.\n' "$g_color_gray1" "$l_winclass_scrcpy" "$g_color_reset"
        return 1
    fi

    printf 'Window class "%b%s%b" encontrado con address "%b%s%b".\n' "$g_color_gray1" "$l_winclass_scrcpy" "$g_color_reset" \
           "$g_color_gray1" "$l_addr_scrcpy" "$g_color_reset"


    # Mover la columna actual (screen mirror) hacia la derecha
    printf '> Move column of "%b%s%b" to left: %bhyprctl dispatch "hl.dsp.layout(\"swapcol l\")"%b\n' "$g_color_gray1" \
           "$l_winclass_scrcpy" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    hyprctl dispatch "hl.dsp.layout(\"swapcol l\")"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    l_wait_time="0.2"
    printf 'Wait %b%s%b seconds ...\n' "$g_color_gray1" "$l_wait_time" "$g_color_reset"
    sleep "$l_wait_time"


    # Incluir la terminal como ventana seguncaria en la columna del 'screen mirror'
    printf '> Include window "%b%s%b" to current column: %bhyprctl dispatch "hl.dsp.layout(\"consume\")"%b\n' "$g_color_gray1" \
           "$g_winclass_term_nc" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    hyprctl dispatch "hl.dsp.layout(\"consume\")"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    l_wait_time="0.2"
    printf 'Wait %b%s%b seconds ...\n' "$g_color_gray1" "$l_wait_time" "$g_color_reset"
    sleep "$l_wait_time"

    #at: 8,44
    #size: 1359,1681

    # Redimensionar la ventana de la termina a altura  deseada
    local l_height="${gA_android_nc_height[${p_device_serial}]}"

    if [ ! -z "$l_height" ]; then
        printf '> Change size: %bhyprctl dispatch "hl.dsp.window.resize({ x = 0, y = %s, relative = true, window = \"address:%s\" })"%b\n' \
               "$g_color_gray1" "$l_height" "$l_addr_scrcpy"  "$g_color_reset"
        hyprctl dispatch "hl.dsp.window.resize({ x = 0, y = ${l_height}, relative = true, window = \"address:${l_addr_scrcpy}\" })"
        l_status=$?

        if [ $l_status -ne 0 ]; then
            return 1
        fi
    fi

    return 0


}


# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
m_controller_android_newcol() {

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
    local l_device_serial=""
    local -i l_flag_stay_awake=1
    local -i l_flag_keep_active=1
    local -i l_flag_disable_screensaver=1
    local -i l_flag_turn_screen_off=1
    local l_workdir=""

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_android_newcol
                return 0
                ;;

            -x)
                if [ -z "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no puede ser vacio.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-d" "$g_color_reset"
                    m_usage_android_newcol
                    return 3
                fi

                if [ ! -d "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es inválido "%b%s%b". Debe ser un folder valido.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-d" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    return 3
                fi

                l_workdir="$2"
                shift 2
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


            -d)
                if [ -z "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" debe indicar la serial del dispositivo android\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-d" "$g_color_reset"
                    m_usage_android_newcol
                    return 3
                fi

                l_device_serial="$2"
                shift 2
                ;;



            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_android_newcol
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
            m_usage_android_newcol
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

        printf '[%bINFO%b] El usuario no especifico el dispositivo android a usar. Se ha escogio el dispositivo android "%b%s%b".\n' \
               "$g_color_yellow1" "$g_color_reset" "$g_color_gray1" "$l_device_serial" "$g_color_reset"

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
    m_android_newcol "$l_device_serial" "$l_flag_stay_awake" "$l_flag_keep_active" "$l_flag_disable_screensaver" \
                     "$l_flag_turn_screen_off" "$l_workdir"

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
        ['newws']='Configura un workspace dwindle para mostrar una VM proporcional a mi monitor.'
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
    printf ' Log: %b%s%b\n' "$g_color_gray1" "$l_log_file" "$g_color_reset"

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
# Subcomand > connect> newws > Main controller
# -------------------------------------------------------------------------------------

m_usage_spice_newws() {

    local l_scmd_id='newws'
    local l_scmd_description="${gA_global_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '  %b%s spice %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s spice %s%b [-w WORKSPACE] [-d WORKDIR] %bPORT [HOST]%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"
    printf '  %b%s spice %s%b [-w WORKSPACE] [-d WORKDIR] %bVM_NAME%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" \
           "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"

    printf '\nLas opciones globales usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-w WORKSPACE%b ID del workspace donde se crearan las ventanas. Si no se especifica se usa "2".%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bEl workspace debe estar vacio y su ID solo puede ser [1,7].%b\n' \
           "$g_color_gray1" "$g_color_reset"
    printf '%b  > %b-d WORKDIR%b Ruta de directorio de trabajo con la que se abrira la terminal.%b\n' \
           "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

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
    printf '\n'

}


declare -r g_winclass_term_wina="foot_wina"
declare -r g_winclass_term_winc="foot_winb"
#declare -r g_winclass_edge="microsoft-edge"
declare -r g_winclass_rviewer_winb="remote-viewer"
#declare -r g_wintitle_rviewer_winb="SPICE normal screen - Port"
declare -ri g_height_term=355

m_spice_newws() {

    local p_workspace_id="$1"
    local p_vm_host="$2"
    local p_vm_port="$3"
    local p_workdir="$4"

    # Validar que el workspace no tenga ventanas
    local -i l_status=0
    m_workspace_is_empty "$p_workspace_id"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf 'El workspace "%b%s%b" ya cuenta con ventanas. Especifique un workspace sin ventanas.\n' "$g_color_gray1" "$p_workspace_id" \
               "$g_color_reset"
        return 1
    fi

    # Ir al workspace
    printf '> Go workspace %b%s%b: %bhyprctl dispatch "hl.dsp.focus({ workspace = %s })"%b\n' "$g_color_gray1" "$p_workspace_id" "$g_color_reset" \
           "$g_color_gray1" "$p_workspace_id" "$g_color_reset"
    hyprctl dispatch "hl.dsp.focus({ workspace = $p_workspace_id })"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    local l_wait_time="0.5"
    printf 'Wait %b%s%b seconds ...\n' "$g_color_gray1" "$l_wait_time" "$g_color_reset"
    sleep "$l_wait_time"

    # Validar que el workspace sea de layout dwindle
    local l_data
    l_data=$(m_current_workspace_info)
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf 'No se ha podido obtener informacion del workspace actual (status "%b%s%b").\n' "$g_color_gray1" "$l_status" \
               "$g_color_reset"
        return 1
    fi

    local l_ws_id l_ws_layout l_ws_windows l_ws_monitor
    IFS='|' read -r l_ws_id l_ws_layout l_ws_windows l_ws_monitor <<< "$l_data"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf 'No se ha podido obtener informacion del workspace actual ("%b%s%b").\n' "$g_color_gray1" "$p_workspace_id" \
               "$g_color_reset"
        return 1
    fi

    printf '> El workspace actual: ID " %b%s%b", Layout "%b%s%b", Nbr Windows "%b%s%b", Monitor "%b%s%b".\n' "$g_color_gray1" \
           "$l_ws_id" "$g_color_reset" "$g_color_gray1" "$l_ws_layout" "$g_color_reset" "$g_color_gray1" "$l_ws_windows" "$g_color_reset" \
           "$g_color_gray1" "$l_ws_monitor" "$g_color_reset"

    if [ "$p_workspace_id" != "$l_ws_id" ] || [ "$l_ws_layout" != "dwindle" ]; then
        printf 'El workspace actual debe tener layout "%b%s%b".' "$g_color_gray1" "dwindle" "$g_color_reset"
        return 1
    fi

    # Abrir la terminal foot (ventana A)
    printf '> Iniciando window "%b%s%b" ...\n' "$g_color_gray1" "$g_winclass_term_wina" "$g_color_reset"
    if [ -z "$p_workdir" ]; then
        printf '%bfootclient --no-wait --app-id "%s"%b\n' "$g_color_gray1" "$g_winclass_term_wina" "$g_color_reset"
        footclient --no-wait --app-id "$g_winclass_term_wina"
    else
        printf '%bfootclient --no-wait --app-id "%s" -D "%s"%b\n' "$g_color_gray1" "$g_winclass_term_wina" "$p_workdir" "$g_color_reset"
        footclient --no-wait --app-id "$g_winclass_term_wina" -D "$p_workdir"
    fi

    # Abrir remote-viewer (ventana B)
    printf '> Iniciando window "%b%s%b" ...\n' "$g_color_gray1" "$g_winclass_rviewer_winb" "$g_color_reset"
    m_connect_spice "$p_vm_port" "$p_vm_host" ""
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    local l_wait_time="0.5"
    printf 'Wait %b%s%b seconds ...\n' "$g_color_gray1" "$l_wait_time" "$g_color_reset"
    sleep "$l_wait_time"

    # Abrir foot (ventana C)
    printf '> Iniciando window "%b%s%b" ...\n' "$g_color_gray1" "$g_winclass_term_winc" "$g_color_reset"
    if [ -z "$p_workdir" ]; then
        printf '%bfootclient --no-wait --app-id "%s"%b\n' "$g_color_gray1" "$g_winclass_term_winc" "$g_color_reset"
        footclient --no-wait --app-id "$g_winclass_term_winc"
    else
        printf '%bfootclient --no-wait --app-id "%s" -D "%s"%b\n' "$g_color_gray1" "$g_winclass_term_winc" "$p_workdir" "$g_color_reset"
        footclient --no-wait --app-id "$g_winclass_term_winc" -D "$p_workdir"
    fi

    # Esperar que aparezcan la ventana A
    printf '> Buscando el %baddress%b de la ventana class "%b%s%b" recien creada ...\n' "$g_color_gray1" "$g_color_reset" \
           "$g_color_gray1" "$g_winclass_term_wina" "$g_color_reset"
    local l_addr_a_term=""
    m_wait_for_window "$p_workspace_id" "$g_winclass_term_wina" "" 1 "l_addr_a_term"

    if [ -z "$l_addr_a_term" ]; then
        printf 'Window class "%b%s%b" no fue encontrado dentro de un rango de tiempo.\n' "$g_color_gray1" "$g_winclass_term_wina" "$g_color_reset"
        return 1
    fi

    printf 'Window class "%b%s%b" encontrado con address "%b%s%b".\n' "$g_color_gray1" "$g_winclass_term_wina" "$g_color_reset" \
           "$g_color_gray1" "$l_addr_a_term" "$g_color_reset"


    # Esperar que aparezcan la ventana B
    printf '> Buscando el %baddress%b de la ventana class "%b%s%b" recien creada ...\n' "$g_color_gray1" "$g_color_reset" \
           "$g_color_gray1" "$g_winclass_rviewer_winb" "$g_color_reset"
    local l_addr_b_rv=""
    m_wait_for_window "$p_workspace_id" "$g_winclass_rviewer_winb" "" 1 "l_addr_b_rv"

    if [ -z "$l_addr_b_rv" ]; then
        printf 'Window class "%b%s%b" no fue encontrado dentro de un rango de tiempo.\n' "$g_color_gray1" "$g_winclass_rviewer_winb" "$g_color_reset"
        return 1
    fi

    printf 'Window class "%b%s%b" encontrado con address "%b%s%b".\n' "$g_color_gray1" "$g_winclass_rviewer_winb" "$g_color_reset" \
           "$g_color_gray1" "$l_addr_b_rv" "$g_color_reset"


    # Esperar que aparezcan la ventana C
    printf '> Buscando el %baddress%b de la ventana class "%b%s%b" recien creada ...\n' "$g_color_gray1" "$g_color_reset" \
           "$g_color_gray1" "$g_winclass_term_winc" "$g_color_reset"
    local l_addr_c_term=""
    m_wait_for_window "$p_workspace_id" "$g_winclass_term_winc" "" 1 "l_addr_c_term"

    if [ -z "$l_addr_c_term" ]; then
        printf 'Window class "%b%s%b" no fue encontrado dentro de un rango de tiempo.\n' "$g_color_gray1" "$g_winclass_term_winc" "$g_color_reset"
        return 1
    fi

    printf 'Window class "%b%s%b" encontrado con address "%b%s%b".\n' "$g_color_gray1" "$g_winclass_term_winc" "$g_color_reset" \
           "$g_color_gray1" "$l_addr_c_term" "$g_color_reset"


    # Cambiar la posicion de la ventana B y C
    printf '> Estableciendo la orientacion de la ventana class "%b%s%b" y la ventana class "%b%s%b" ...\n' "$g_color_gray1" \
           "$g_winclass_rviewer_winb" "$g_color_reset" "$g_color_gray1" "$g_winclass_term_winc" "$g_color_reset"

    local -i l_is_horizontal
    m_compare_split_windows "$l_addr_b_rv" "$l_addr_c_term"
    l_is_horizontal=$?

    if [ $l_is_horizontal -ne 0 ] && [ $l_is_horizontal -ne 1 ]; then
        printf 'No se puede determinar la posicion de los split windows "%b%s%b" y "%b%s%b": status %s.\n' "$g_color_gray1" \
               "$g_winclass_rviewer_winb" "$g_color_reset" "$g_color_gray1" "$g_winclass_term_winc" "$g_color_reset" "$l_is_horizontal"
        return 1
    fi

    if [ $l_is_horizontal -eq 0 ]; then

        printf 'Los split windows windows "%b%s%b" y "%b%s%b" estan en orientacion horizontal.\n' "$g_color_gray1" \
               "$g_winclass_rviewer_winb" "$g_color_reset" "$g_color_gray1" "$g_winclass_term_winc" "$g_color_reset"

    else

        printf 'Los split windows windows "%b%s%b" y "%b%s%b" estan en orientacion vertical, se debe cambiar a la orientacion horizontal.\n' \
               "$g_color_gray1" "$g_winclass_rviewer_winb" "$g_color_reset" "$g_color_gray1" "$g_winclass_term_winc" "$g_color_reset"

        printf 'Change orientation: %bhyprctl dispatch "hl.dsp.layout(\"togglesplit\")"%b\n' "$g_color_gray1" "$g_color_reset"
        hyprctl dispatch "hl.dsp.layout(\"togglesplit\")"
        l_status=$?

        if [ $l_status -ne 0 ]; then
            return 1
        fi

        l_wait_time="0.2"
        printf 'Wait %b%s%b seconds ...\n' "$g_color_gray1" "$l_wait_time" "$g_color_reset"
        sleep "$l_wait_time"

    fi


    # Redimensionar la ventana C a la altura exacta deseada
    printf '> Change size: %bhyprctl dispatch "hl.dsp.window.resize({ x = 0, y = %s, relative = true, window = \"address:%s\" })"%b\n' \
           "$g_color_gray1" "$g_height_term" "$l_addr_c_term"  "$g_color_reset"
    hyprctl dispatch "hl.dsp.window.resize({ x = 0, y = ${g_height_term}, relative = true, window = \"address:${l_addr_c_term}\" })"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    # Enfocar la ventana A y convertirla en un grupo
    printf '> Focus window "%b%s%b": %bhyprctl dispatch "hl.dsp.focus({ window = \"address:%s\" })"%b\n' "$g_color_gray1" \
           "$g_winclass_term_wina" "$g_color_reset" "$g_color_gray1" "$l_addr_a_term" "$g_color_reset"
    hyprctl dispatch "hl.dsp.focus({ window = \"address:${l_addr_a_term}\" })"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    l_wait_time="0.2"
    printf 'Wait %b%s%b seconds ...\n' "$g_color_gray1" "$l_wait_time" "$g_color_reset"
    sleep "$l_wait_time"

    # Crear un grupo deonde la ventana A forma parte de esta.
    printf '> Create windows group: %bhyprctl dispatch "hl.dsp.group.toggle()"%b\n' "$g_color_gray1" "$g_color_reset"
    hyprctl dispatch "hl.dsp.group.toggle()"
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 1
    fi

    l_wait_time="0.2"
    printf 'Wait %b%s%b seconds ...\n' "$g_color_gray1" "$l_wait_time" "$g_color_reset"
    sleep "$l_wait_time"

    # Abrir Microsoft Edge y moverlo dentro del grupo de A
    microsoft-edge > /dev/null 2>&1 &
    disown

    return 0

}


# Funcion principal de entrada
# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
#
m_controller_spice_newws() {

    #1. Validaciones previas

    #2. Procesar las opciones globales
    local -i l_workspace_id=2
    local l_workdir=''

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help|help)
                m_usage_spice_newws
                return 0
                ;;

            -w)
                if [ -z "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no puede ser vacio.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-w" "$g_color_reset"
                    m_usage_spice_newws
                    return 3
                fi

                if ! [[ "$2" =~ ^[1-7]$ ]]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es inválido "%b%s%b". Debe estar entre [1,5]\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-w" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    return 3
                fi

                l_workspace_id="$2"
                shift 2
                ;;

            -d)
                if [ -z "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no puede ser vacio.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-d" "$g_color_reset"
                    m_usage_spice_newws
                    return 3
                fi

                if [ ! -d "$2" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es inválido "%b%s%b". Debe ser un folder valido.\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-d" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    return 3
                fi

                l_workdir="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_spice_newws
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
            m_usage_spice_newws
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

    # Validar si el puerto SPICE esta en escucha
    if ! ss -ltn | grep ":${p_port} " &> /dev/null; then

        printf 'El puerto TCP "%b%s%b" NO esta activo y en escucha. Debe iniciar la VM antes de conectarse a ella.\n' \
               "$g_color_gray1" "$p_port" "$g_color_reset"
        return 1

    fi

    # Ejecutar la logica
    m_spice_newws "$l_workspace_id" "$p_host" "$p_port" "$l_workdir"
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
