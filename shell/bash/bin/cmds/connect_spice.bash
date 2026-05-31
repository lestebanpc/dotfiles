#!/usr/bin/env bash

set -euo pipefail

#Colores principales usados
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"



declare -r g_monitor_name="HDMI-A-1"

declare -A gA_vms=(
        ['vmphoenix']='127.0.0.1:5930'
    )


m_get_vms() {

    # Recorrer la lista de parametros identificados ....
    local l_vm_infos=""

    local l_vm_id
    local l_vm_data

    for l_vm_id in "${!gA_vms[@]}"; do

        l_vm_data="${gA_vms[${l_vm_id}]}"

        if [ -z "$l_vm_infos" ]; then
            printf -v l_vm_infos "'%b%s%b' ('%b%s%b')" "$g_color_yellow1" "$l_vm_id" "$g_color_reset" "$g_color_gray1" "$l_vm_data" "$g_color_reset"
        else
            printf -v l_vm_infos "%b, '%b%s%b' ('%b%s%b')" "$l_vm_infos" "$g_color_yellow1" "$l_vm_id" "$g_color_reset" "$g_color_gray1" "$l_vm_data" "$g_color_reset"
        fi

    done

    echo "$l_vm_infos"

}


m_usage() {

    printf 'Usage:\n'
    printf '    %bconnect_spice%b -h%b\n' "$g_color_yellow1" "$g_color_gray1" "$g_color_reset"
    printf '    %bconnect_spice%b [-s full|16:9|8:5 ] %bPORT [HOST]%b\n' "$g_color_yellow1" "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"
    printf '    %bconnect_spice%b [-s full|16:9|8:5 ] %bVM_NAME%b\n\n' "$g_color_yellow1" "$g_color_gray1" "$g_color_yellow1" "$g_color_reset"
    printf 'Las opciones usados son:\n'
    printf '  > %b-h%b muestra la ayuda del comando.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %b-s full|16:9|8:5%b indica define el window rule de hyprland a usar. Sus valores puede ser:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    - %b%s%b Se muesta en un ventana float con relacion de aspecto 16:9 en el %bworspace actual%b\n' "$g_color_cian1" "16:9" "$g_color_gray1" \
           "$g_color_cian1" "$g_color_reset"
    printf '    - %b%s%b Se muesta en un ventana float con relacion de aspecto 8:5 en el %bworspace actual%b\n' "$g_color_cian1" "8:5" "$g_color_gray1" \
           "$g_color_cian1" "$g_color_reset"
    printf '    - %b%s%b Se muesta en un ventana normal en fullscreen con relacion de aspecto 16:9 en el %bworspace 8%b\n' "$g_color_cian1" "full" "$g_color_gray1" \
           "$g_color_cian1" "$g_color_reset"
    printf '    %bEl valor por defecto es "16:9"%b.\n\n' "$g_color_gray1" "$g_color_reset"
    printf 'Los argumentos usados son:\n'
    printf '  > %bPORT%b Puerto TCP del protocolo SPICE expuesto por la VM.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bHOST%b IP a usar donde se expone el puerto SPICE.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bVM_NAME%b Nombre de la VM al que se va a conectar.%b\n\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    printf 'Adicionalmente:\n'
    local l_vm_infos=$(m_get_vms)
    printf '  > %bEl VM_NAME pueden ser: %b%b\n\n' "$g_color_gray1" "$l_vm_infos" "$g_color_reset"
}



m_connect_spice() {

    #1. Argumentos
    local -i p_port="$1"
    local p_host="$2"
    local p_screen_type="$3"

    #2. Validaciones

    # Si se desea mostrar como full, debe estar habilitado el 2do monitor
    local l_title="SPICE screen 16:9 - Port ${p_port}"

    if [ "$p_screen_type" = "full" ]; then

        if ! hyprctl -j monitors | jq -e --arg MON "$g_monitor_name" '.[] | select(.name == $MON)' >/dev/null; then
            printf "Para el modo fullscreen, se requiuere que el 2do monitor '%b%s%b' está activo. Conecte su 2do monitor.\n" \
                   "$g_color_gray1" "$g_monitor_name" "$g_color_reset"
            return 1
        fi

        l_title="SPICE fullscreen - Port ${p_port}"

    elif [ "$p_screen_type" = "8:5" ]; then
        l_title="SPICE screen 8:5 - Port ${p_port}"
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


# -------------------------------------------------------------------------------------
# Main code
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


    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    local p_screen_type="16:9"

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage
                return 0
                ;;

            -s)
                if [ "$2" != "full" ] && [ "$2" != "16:9" ] && [ "$2" != "8:5" ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" es inválido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-s" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage
                    return 3
                fi

                p_screen_type="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage
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
        local l_aux="${gA_vms[${l_vm_id}]:-}"
        if [ -z "$l_aux" ]; then
            printf '[%bERROR%b] El argumento de la VM ingresada es inválido: %b%s%b\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$l_vm_id" "$g_color_reset"
            m_usage
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
    m_connect_spice $p_port "$p_host" "$p_screen_type"

    return 0

}



# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $_g_result
