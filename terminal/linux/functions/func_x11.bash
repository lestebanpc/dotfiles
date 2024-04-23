#!/bin/bash

g_color_gray1="\x1b[90m"
g_color_reset="\x1b[0m"

#Carpetas de archivos temporales
_g_tmp_data_path="/tmp/.files"
if [ ! -d "$_g_tmp_data_path" ]; then
    mkdir -p $_g_tmp_data_path
fi


################################################################################################
# Servidor X11 virtual: Xvfb 
################################################################################################

xvfb_start() {

    #1. Argumentos
    local p_display_number=-1
    if [ -z "$1" ]; then
        p_display_number=9
    elif [[ "$1" =~ ^[0-9]+$ ]]; then
        p_display_number=$1
    fi

    local p_flag_use_tcp=-1
    if [ -z "$2" ]; then
        p_flag_use_tcp=1
    elif [ "$2" = "0" ]; then
        p_flag_use_tcp=0
    elif [ "$2" = "1" ]; then
        p_flag_use_tcp=1
    fi

    if [ $p_display_number -lt 0 ] || [ $p_flag_use_tcp -lt 0 ]; then
        printf '%bUse:\n' "$g_color_gray1"
        printf '    xvfb_start\n'
        printf '    xvfb_start DISPLAY_NUMBER\n'
        printf '    xvfb_start DISPLAY_NUMBER FLAG_ENABLE_TCP\n'
        printf 'Donde:\n'
        printf '    > "DISPLAY_NUMBER" es un entero que representa el "Display Number". Por defecto es 9.\n'
        printf '    > "FLAG_ENABLE_TCP" es 0 si desea habilitar acceso al servidor sobre red usando socket TCP. Use 1, si solo usa localmente mediante un socket IPC.\n\n%b' "$g_color_reset"
        return 1
    fi

    #2. Validar si esta instalado Xvfb
    if [ ! -x /usr/bin/Xvfb ]; then
        printf 'No esta instalado el servidor de visualizacion virtual para X11 "Xvfb".\n'
        return 2
    fi

    #3. Validar si el servidor de visualizacion ya esta iniciado con el 'display number' indicado:
    local l_cmd_options=":${p_display_number}"
    local l_display_value=":${p_display_number}"
    if [ $p_flag_use_tcp -eq 0 ]; then
        #Con '-ac', se elimina la autorizacion por host/usuario del servidor
        l_cmd_options="${l_cmd_options} -listen tcp -ac"
        l_display_value="localhost:${p_display_number}"
    fi 

    if [ -e /tmp/.X11-unix/X${p_display_number} ]; then
        printf 'Existe un servidor x11 iniciado en display number %s %b(vea: /tmp/.X11-unix/X%s)%b\n' "$p_display_number" "$g_color_gray1" "$p_display_number" "$g_color_reset"
        printf 'Para ejecutar un cliente en este servidor de visualizacion, defina antes: %bexport DISPLAY=%s%b\n' "$g_color_gray1" "$l_display_value" "$g_color_reset"
        return 3
    fi

    #4. Si es WSL2, remontar la unidad de solo lectura '/tmp/.X11-unix'
    local l_info=$(uname -r)
    local l_status

    #Si es WSL
    if [[ "$l_info" == *WSL* ]]; then

        #Si '/tmp/.X11-unix' esta montado
        if l_info=$(cat /proc/mounts | grep '/tmp/.X11-unix'); then

            #Si esta montado en modo lecutura
            if l_info=$(echo "$l_info" | grep -P '\sro[\s,]'); then
                printf 'Su WSL tiene montado "%b%s%b" en modo lectura. Intentando montarlo en modo escritura ...\n' "$g_color_gray1" "/tmp/.X11-unix" "$g_color_reset"
                sudo mount -o remount,rw /tmp/.X11-unix
                l_status=$?

                if [ $l_status -ne 0 ]; then
                    printf 'Ocurrio un error %s al re-montar "%s" en modo escritura.\n' "$l_status" "/tmp/.X11-unix"
                    return 4
                fi
            fi
        fi
    fi
    

    #5. Iniciar el servidor X11
    local l_log_file="${_g_tmp_data_path}/xvfb_${UID}.log"
    local l_pid
    printf 'Iniciando el servidor de visualizacion virtual "%bXvfb %s -screen 0 1920x1080x24 > %s 2>&1 &%b" ...\n' "$g_color_gray1" "$l_cmd_options" "$l_log_file" "$g_color_reset"
    Xvfb ${l_cmd_options} -screen 0 1920x1080x24 > ${l_log_file} 2>&1 &
    l_status=$?
    l_pid=$!
    #l_info=$(echo "$l_info" | sed 's/\[[0-9]\+\]\s\([0-9]\+\)/\1/')

    printf 'Status: %b%s%b, PID: %b%s%b\n' "$g_color_gray1" "$l_status" "$g_color_reset" "$g_color_gray1" "$l_pid" "$g_color_reset"
    printf 'Para ejecutar un cliente en este servidor de visualizacion, defina antes: %bexport DISPLAY=%s%b\n' "$g_color_gray1" "$l_display_value" "$g_color_reset"
    printf 'Para detener el servidor de visualizacion, use: %bkill %s%b\n' "$g_color_gray1" "$l_pid" "$g_color_reset"
    return 0
        
}








