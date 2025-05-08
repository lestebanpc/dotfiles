#!/bin/bash


# Solo WSL: Folder base, donde se almacena el programas, comando y afines usados por Windows.
if [ -z "$g_win_base_path" ] || [ ! -d "$g_win_base_path" ]; then
    g_win_base_path='/mnt/c/cli'
fi

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
# Integracion con el agente SSH de Windows
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

    local l_socket_path="$HOME/.ssh/agent.sock"
    printf 'Kernel Linux (WSL): "%b%s%b"\n' "$g_color_gray1" "$l_kernel" "$g_color_reset"
    printf 'Socat version     : "%b%s%b"\n' "$g_color_gray1" "$l_socat_version" "$g_color_reset"
    printf 'NPipeRelay path   : "%b%s%b"\n' "$g_color_gray1" "$g_win_base_path/cmds/bin/npiperelay.exe" "$g_color_reset"
    printf 'Socket IPC a usar : "%b%s%b"\n' "$g_color_gray1" "$l_socket_path" "$g_color_reset"

    #2.3 Validar si el socket se esta usando
    if ss -a | grep -q "$l_socket_path"; then

        if [ -z "$SSH_AUTH_SOCK" ]; then

            printf 'Se define la variable de entorno "%b%s%b" con el valor "%b%s%b".\n' \
                   "$g_color_gray1" "SSH_AUTH_SOCK" "$g_color_reset" "$g_color_gray1" "$l_socket_path" "$g_color_reset"
            export SSH_AUTH_SOCK="$l_socket_path"

        elif [ "$SSH_AUTH_SOCK" = "$l_source_path" ]; then
            export SSH_AUTH_SOCK
        else

            printf 'Se cambia el valor de la variable de entorno "%b%s%b" de "%b%s%b" a "%b%s%b".\n' \
                   "$g_color_gray1" "SSH_AUTH_SOCK" "$g_color_reset" "$g_color_gray1" "$SSH_AUTH_SOCK" "$g_color_reset" \
                   "$g_color_gray1" "$l_socket_path" "$g_color_reset"
            export SSH_AUTH_SOCK="$l_socket_path"

        fi

        printf 'El socket "%b%s%b" ya se esta operativo.\n' "$g_color_gray1" "$l_socket_path" "$g_color_reset"
        return 0
    fi

    #3. Iniciar un socket IPC que se conecta al SSH agente de Windows
    printf 'Iniciando el socket IPC "%b%s%b" que se conecte al agente SSH de Windows...\n' "$g_color_gray1" "$SSH_AUTH_SOCK" "$g_color_reset"

    #Si existe el archivo de socket eliminarlo
    if [ -e "$l_socket_path" ]; then
        rm -f "$l_socket_path"
    fi

    if [ -z "$SSH_AUTH_SOCK" ]; then

        printf 'Se define la variable de entorno "%b%s%b" con el valor "%b%s%b".\n' \
               "$g_color_gray1" "SSH_AUTH_SOCK" "$g_color_reset" "$g_color_gray1" "$l_socket_path" "$g_color_reset"
        export SSH_AUTH_SOCK="$l_socket_path"

    elif [ "$SSH_AUTH_SOCK" = "$l_source_path" ]; then
        export SSH_AUTH_SOCK
    else

        printf 'Se cambia el valor de la variable de entorno "%b%s%b" de "%b%s%b" a "%b%s%b".\n' \
               "$g_color_gray1" "SSH_AUTH_SOCK" "$g_color_reset" "$g_color_gray1" "$SSH_AUTH_SOCK" "$g_color_reset" \
               "$g_color_gray1" "$l_socket_path" "$g_color_reset"
        export SSH_AUTH_SOCK="$l_socket_path"

    fi
    export SSH_AUTH_SOCK="$l_socket_path"

    printf "Ejecutando '"'%b(setsid socat UNIX-LISTEN:%s,fork EXEC:"%s/cmds/bin/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &)%b'"'...\n" \
           "$g_color_gray1" "$l_socket_path" "$g_win_base_path" "$g_color_reset"
    (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"$g_win_base_path/cmds/bin/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &)

}
