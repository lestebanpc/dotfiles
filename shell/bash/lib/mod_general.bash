#!/bin/bash


#Constantes: Colores
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

#Expresiones regulares de sustitucion mas usuadas para las versiones
if [ -z "$g_regexp_sust_version1" ]; then
    #La version 'x.y.z' esta la inicio o despues de caracteres no numericos
    declare -r g_regexp_sust_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'
fi


################################################################################################
# Funciones Generales
################################################################################################


################################################################################################
# NerdCtl con CRT 'ContainerD'
################################################################################################

start_nerdctl() {

    #1. Argumentos
    local l_tag_mode="rootless"
    local p_root_mode=1
    if [ "$1" = "0" ]; then
        p_root_mode=0
        l_tag_mode="root"
    fi

    #Obtener el UID del usuario actual
    local l_runner_id=-1
    local l_aux

    if [ ! -z "$UID" ]; then
        l_runner_id=$UID
    elif [ ! -z "$EUID" ]; then
        l_runner_id=$EUID
    elif l_aux=$(id -u 2> /dev/null); then
        l_runner_id=$l_aux
    else
        return 1
    fi

    #Si es root
    if [ $l_runner_id -eq 0 ]; then
        p_root_mode=0
        l_tag_mode="root"
    fi

    #Validar si existe los comandos
    local l_version
    l_version=$(nerdctl --version 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ]; then
       printf 'El programa "%b%s%b" no esta instalado.\n' "$g_color_gray1" "nerdctl" "$g_color_reset"
       return 1
    else
       l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
       printf 'El programa "%b%s%b" con la versión "%b%s%b" esta instalado.\n' "$g_color_gray1" "nerdctl" "$g_color_reset" \
              "$g_color_gray1" "$l_version" "$g_color_reset"
    fi

    l_version=$(containerd --version 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ]; then
       printf 'El programa "%b%s%b" no esta instalado.\n' "$g_color_gray1" "containerd" "$g_color_reset"
       return 2
    else
       l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
       printf 'El programa "%b%s%b" con la versión "%b%s%b" esta instalado.\n' "$g_color_gray1" "containerd" "$g_color_reset" \
              "$g_color_gray1" "$l_version" "$g_color_reset"
    fi

    local l_flag_buildkit=1
    l_version=$(buildkitd --version 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ]; then
       printf 'El programa "%b%s%b" no esta instalado.\n' "$g_color_gray1" "buildkitd" "$g_color_reset"
    else
       l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
       printf 'El programa "%b%s%b" con la versión "%b%s%b" esta instalado.\n' "$g_color_gray1" "buildkitd" "$g_color_reset" \
              "$g_color_gray1" "$l_version" "$g_color_reset"
       l_flag_buildkit=0
    fi

    #Validar si esta configurado la unidad systemd
    if [ $p_root_mode -ne 0 ]; then

        if [ ! -f "${HOME}/.config/systemd/user/containerd.service" ]; then
           printf 'El archivos de configuración "%b%s%b" de la unidad "%b%s%b" no existe.\n' "$g_color_gray1" "~/.config/systemd/user/containerd.service" \
                  "$g_color_reset" "$g_color_gray1" "containerd" "$g_color_reset"
           return 3
        fi

        if [ $l_flag_buildkit -eq 0 ] && [ ! -f "${HOME}/.config/systemd/user/buildkit.service" ]; then
           printf 'El archivos de configuración "%b%s%b" de la unidad "%b%s%b" no existe.\n' "$g_color_gray1" "~/.config/systemd/user/buildkit.service" \
                  "$g_color_reset" "$g_color_gray1" "containerd" "$g_color_reset"
           l_flag_buildkit=1
        fi

    else

        if [ ! -f "/usr/lib/systemd/system/containerd.service" ]; then
           printf 'El archivos de configuración "%b%s%b" de la unidad "%b%s%b" no existe.\n' "$g_color_gray1" "/usr/lib/systemd/system/containerd.service" \
                  "$g_color_reset" "$g_color_gray1" "containerd" "$g_color_reset"
           return 3
        fi

        if [ $l_flag_buildkit -eq 0 ] && [ ! -f "/usr/lib/systemd/system/buildkit.service" ]; then
           printf 'El archivos de configuración "%b%s%b" de la unidad "%b%s%b" no existe.\n' "$g_color_gray1" "/usr/lib/systemd/system/buildkit.service" \
                  "$g_color_reset" "$g_color_gray1" "containerd" "$g_color_reset"
           l_flag_buildkit=1
        fi

    fi

    printf 'Ejecutando el Container Runtime "%b%s%b" en modo "%b%s%b"...\n' "$g_color_cian1" "containerd" "$g_color_reset" \
           "$g_color_cian1" "$l_tag_mode" "$g_color_reset"

    #3. Iniciando la unidad systemd
    if [ $p_root_mode -ne 0 ]; then
        if systemctl --user is-active containerd.service 2>&1 > /dev/null; then
            printf 'La unidad systemd %b%s%b ya esta iniciado.\n' "$g_color_gray1" "containerd.service" "$g_color_reset"
        else
            printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                   "$g_color_gray1" "systemctl --user start containerd.service" "$g_color_reset"
            systemctl --user start containerd.service
        fi
    else
        if systemctl is-active containerd.service 2>&1 > /dev/null; then
            printf 'La unidad systemd %b%s%b ya esta iniciado.\n' "$g_color_gray1" "containerd.service" "$g_color_reset"
        else
            if [ $l_runner_id -eq 0 ]; then
                printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                       "$g_color_gray1" "systemctl start containerd.service" "$g_color_reset"
                systemctl start containerd.service
            else
                printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                       "$g_color_gray1" "sudo systemctl start containerd.service" "$g_color_reset"
                sudo systemctl start containerd.service
            fi
        fi
    fi

    if [ $l_flag_buildkit -eq 0 ]; then

        printf 'Ejecutando el Image Builder "%b%s%b" en modo "%b%s%b"...\n' "$g_color_cian1" "buildkit" "$g_color_reset" \
           "$g_color_cian1" "$l_tag_mode" "$g_color_reset"

        if [ $p_root_mode -ne 0 ]; then
            if systemctl --user is-active buildkit.service 2>&1 > /dev/null; then
                printf 'La unidad systemd %b%s%b ya esta iniciado.\n' "$g_color_gray1" "buildkit.service" "$g_color_reset"
            else
                sleep 1
                printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                       "$g_color_gray1" "systemctl --user start buildkit.service" "$g_color_reset"
                systemctl --user start buildkit.service
            fi
        else
            if systemctl is-active buildkit.service 2>&1 > /dev/null; then
                printf 'La unidad systemd %b%s%b ya esta iniciado.\n' "$g_color_gray1" "buildkit.service" "$g_color_reset"
            else
                sleep 1
                if [ $l_runner_id -eq 0 ]; then
                    printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                           "$g_color_gray1" "systemctl start buildkit.service" "$g_color_reset"
                    systemctl start buildkit.service
                else
                    printf 'La unidad systemd %b%s%b se esta iniciando: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                           "$g_color_gray1" "sudo systemctl start buildkit.service" "$g_color_reset"
                    sudo systemctl start buildkit.service
                fi
            fi
        fi
    fi

    return 0
        
}


stop_nerdctl() {

    #1. Argumentos
    local l_tag_mode="rootless"
    local p_root_mode=1
    if [ "$1" = "0" ]; then
        p_root_mode=0
        l_tag_mode="root"
    fi

    #Obtener el UID del usuario actual
    local l_runner_id=-1
    local l_aux

    if [ ! -z "$UID" ]; then
        l_runner_id=$UID
    elif [ ! -z "$EUID" ]; then
        l_runner_id=$EUID
    elif l_aux=$(id -u 2> /dev/null); then
        l_runner_id=$l_aux
    else
        return 1
    fi

    #Si es root
    if [ $l_runner_id -eq 0 ]; then
        p_root_mode=0
        l_tag_mode="root"
    fi

    printf 'Deteniendo las unidades vinculadas al Container Runtime "%b%s%b" de modo "%b%s%b"...\n' "$g_color_cian1" "containerd" "$g_color_reset" \
           "$g_color_gray1" "$l_tag_mode" "$g_color_reset"

    #2. Deteniendo las unidades systemd

    if [ $p_root_mode -ne 0 ]; then
        if systemctl --user is-active buildkit.service 2>&1 > /dev/null; then
            printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                   "$g_color_gray1" "systemctl --user stop buildkit.service" "$g_color_reset"
            systemctl --user stop buildkit.service
        else
            printf 'La unidad systemd %b%s%b ya esta detenido.\n' "$g_color_gray1" "buildkit.service" "$g_color_reset"
        fi
    else

        if systemctl is-active buildkit.service 2>&1 > /dev/null; then
            if [ $l_runner_id -eq 0 ]; then
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                       "$g_color_gray1" "systemctl stop buildkit.service" "$g_color_reset"
                systemctl stop buildkit.service
            else
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "buildkit.service" "$g_color_reset" \
                       "$g_color_gray1" "sudo systemctl stop buildkit.service" "$g_color_reset"
                sudo systemctl stop buildkit.service
            fi
        else
            printf 'La unidad systemd %b%s%b ya esta deteniendo.\n' "$g_color_gray1" "buildkit.service" "$g_color_reset"
        fi

        if systemctl is-active buildkit.socket 2>&1 > /dev/null; then
            if [ $l_runner_id -eq 0 ]; then
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "buildkit.socket" "$g_color_reset" \
                       "$g_color_gray1" "systemctl stop containerd.socket" "$g_color_reset"
                systemctl stop buildkit.socket
            else
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "buildkit.socket" "$g_color_reset" \
                       "$g_color_gray1" "sudo systemctl stop buildkit.socket" "$g_color_reset"
                sudo systemctl stop buildkit.socket
            fi
        else
            printf 'La unidad systemd %b%s%b ya esta deteniendo.\n' "$g_color_gray1" "containerd.socket" "$g_color_reset"
        fi

    fi

    if [ $p_root_mode -ne 0 ]; then
        if systemctl --user is-active containerd.service 2>&1 > /dev/null; then
            sleep 1
            printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                   "$g_color_gray1" "systemctl --user stop containerd.service" "$g_color_reset"
            systemctl --user stop containerd.service
        else
            printf 'La unidad systemd %b%s%b ya esta detenido.\n' "$g_color_gray1" "containerd.service" "$g_color_reset"
        fi
    else
        if systemctl is-active containerd.service 2>&1 > /dev/null; then
            if [ $l_runner_id -eq 0 ]; then
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                       "$g_color_gray1" "systemctl stop containerd.service" "$g_color_reset"
                systemctl stop containerd.service
            else
                printf 'La unidad systemd %b%s%b se esta deteniendo: "%b%s%b".\n' "$g_color_cian1" "containerd.service" "$g_color_reset" \
                       "$g_color_gray1" "sudo systemctl stop containerd.service" "$g_color_reset"
                sudo systemctl stop containerd.service
            fi
        else
            printf 'La unidad systemd %b%s%b ya esta deteniendo.\n' "$g_color_gray1" "containerd.service" "$g_color_reset"
        fi
    fi


    return 0
        
}


################################################################################################
# Funciones de ayuda en WSL
################################################################################################

connect_win_sshagent() {

    #1. Argumentos


    #2. Validaciones

    #2.1 Validar que sea WSL
    local l_aux=$(uname -s)
    local l_kernel
    
    case "$l_aux" in
        Linux*)
            l_kernel=$(uname -r)
            if [[ "$l_kernel" != *WSL* ]] || [ ! -f "/etc/wsl.conf" ]; then
                printf 'La distribucion Linux no esta sobre un kernel "%b%s%b" WSL.\n' "$g_color_gray1" "$l_kernel" "$g_color_reset"
                return 1
            fi
            ;;

        *)
            printf 'La distribucion "%b%s%b" no es Linux.\n' "$g_color_gray1" "$l_aux" "$g_color_reset"
            return 1
            ;;
    esac

    #2.2 Validar si esta instalado socat
    local l_socat_version
    l_socat_version=$(socat -V | head -n 2 | tail -n 1 | sed "$g_regexp_sust_version1")
    local l_status=$?

    if [ -z "$l_socat_version" ] || [ $l_status -ne 0 ]; then
        printf 'Se requiere que este instalado el comando "%b%s%b".\n' "$g_color_gray1" "socat" "$g_color_reset"
        return 1
    fi

    #2.2 Validar si esta instalado 'npiperelay'
    
    if [ -z "$g_win_base_path" ] || [ ! -d "$g_win_base_path" ]; then
        printf 'La ruta base "%b%s%b" donde se almacena programas windows no valida.\n' "$g_color_gray1" "$g_win_base_path" "$g_color_reset"
        return 1
    fi

    if [ ! -f "$g_win_base_path/cmds/bin/npiperelay.exe" ]; then
        printf 'El comando windows %b%s%b no esta instalado.\n' "$g_color_gray1" "$g_win_base_path/cmds/bin/npiperelay.exe" "$g_color_reset"
        return 1
    fi

    SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
    printf 'Kernel Linux     : "%b%s%b"\n' "$g_color_gray1" "$l_kernel" "$g_color_reset"
    printf 'Socat version    : "%b%s%b"\n' "$g_color_gray1" "$l_socat_version" "$g_color_reset"
    printf 'NPipeRelay path  : "%b%s%b"\n' "$g_color_gray1" "$g_win_base_path/cmds/bin/npiperelay.exe" "$g_color_reset"
    printf 'Socket IPC a usar: "%b%s%b"\n' "$g_color_gray1" "$SSH_AUTH_SOCK" "$g_color_reset"

    #2.3 Validar si el socket se esta usando

    if ss -a | grep -q "$SSH_AUTH_SOCK"; then
        printf 'El socket "%b%s%b" ya se esta usando. Valida si su agente esta funcionando o dentenga el servicio que genera el socket.\n' \
               "$g_color_gray1" "$SSH_AUTH_SOCK" "$g_color_reset"
        return 1
    fi

    #3. Iniciar un socket IPC que se conecta al SSH agente de Windows
    printf 'Iniciando el socket IPC "%b%s%b" que se conecte al agente SSH de Windows...\n' "$g_color_gray1" "$l_aux" "$g_color_reset"

    if [ -f "$SSH_AUTH_SOCK" ]; then
        rm -f "$SSH_AUTH_SOCK"
    fi

    (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"$g_win_base_path/cmds/bin/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &)

}





