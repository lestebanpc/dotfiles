#!/bin/bash


#Codigo respuesta con exito:
#    0  - OK (si se ejecuta directamente y o en caso de no hacerlo, no requiere alamcenar las credenciales de SUDO).
#  119  - OK (en caso que NO se ejecute directamente o interactivamente y se requiera credenciales de SUDO).
#         Las credenciales de SUDO se almaceno en este script (localmente). avisar para que lo cierre el caller
#Codigo respuesta con error:
#  110  - Argumentos invalidos.
#  111  - No se cumple los requisitos para ejecutar la logica principal del script.
#  120  - Se require permisos de root y se nego almacenar las credenciales de SUDO.
#  otro - Error en el procesamiento de la logica del script 



#------------------------------------------------------------------------------------------------------------------
#> Logica de inicialización {{{
#------------------------------------------------------------------------------------------------------------------
# Incluye variables globales constantes y variables globales que requieren ser calculados al iniciar el script.
#

#Variable cuyo valor esta CALCULADO por '_get_current_script_info':
g_shell_path=''

#Permite obtener  'g_shell_path' es cual es la ruta donde estan solo script, incluyendo los script instalacion.
#Parametros de entrada: Ninguno
#Parametros de salida> Variables globales: 'g_shell_path'
#Parametros de salida> Valor de retorno
#  0> Script valido (el script esta en la estructura de folderes de 'g_shell_path')
#  1> Script invalido
function _get_current_script_info() {

    #Obteniendo la ruta base de todos los script bash
    local l_aux=''
    local l_script_path="${BASH_SOURCE[0]}"
    l_script_path=$(realpath "$l_script_path" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then

        printf 'Error al obtener la ruta absoluta del script "%s" actual.\n' "$l_script_path"
        return 1

    fi

    return 0

}

_get_current_script_info
_g_status=$?
if [ $_g_status -ne 0 ]; then
    exit 111
fi


[ -z "$g_repo_name" ] && g_repo_name='.files'

#Funciones generales, determinar el tipo del SO y si es root
. ~/${g_repo_name}/shell/bash/lib/mod_common.bash

#Obtener informacion basica del SO
if [ -z "$g_os_type" ]; then

    #Determinar el tipo de SO compatible con interprete shell POSIX.
    #  00 > Si es Linux no-WSL
    #  01 > Si es Linux WSL2 (Kernel de Linux nativo sobre Windows)
    #  02 > Si es Unix
    #  03 > Si es MacOS
    #  04 > Compatible en Linux en Windows: CYGWIN
    #  05 > Compatible en Linux en Windows: MINGW
    #  06 > Emulador Bash Termux para Linux Android
    #  09 > No identificado
    get_os_type
    declare -r g_os_type=$?

    #Obtener información de la distribución Linux
    # > 'g_os_subtype_id'             : Tipo de distribucion Linux
    #    > 0000000 : Distribución de Linux desconocidos
    #    > 0000001 : Alpine Linux
    #    > 10 - 29 : Familia Fedora
    #           10 : Fedora
    #           11 : CoreOS Stream
    #           12 : Red Hat Enterprise Linux
    #           19 : Amazon Linux
    #    > 30 - 49 : Familia Debian
    #           30 : Debian
    #           31 : Ubuntu
    # > 'g_os_subtype_name'           : Nombre de distribucion Linux
    # > 'g_os_subtype_version'        : Version extendida de la distribucion Linux
    # > 'g_os_subtype_version_pretty' : Version corta de la distribucion Linux
    # > 'g_os_architecture_type'      : Tipo de la arquitectura del procesador
    if [ $g_os_type -le 1 ]; then
        get_linux_type_info
    fi

fi

#Obtener informacion basica del usuario
if [ -z "$g_runner_id" ]; then

    #Determinar si es root y el soporte de sudo
    # > 'g_runner_id'                     : ID del usuario actual (UID).
    # > 'g_runner_user'                   : Nombre del usuario actual.
    # > 'g_runner_sudo_support'           : Si el so y el usuario soportan el comando 'sudo'
    #    > 0 : se soporta el comando sudo con password
    #    > 1 : se soporta el comando sudo sin password
    #    > 2 : El SO no implementa el comando sudo
    #    > 3 : El usuario no tiene permisos para ejecutar sudo
    #    > 4 : El usuario es root (no requiere sudo)
    get_runner_options

fi



#Colores principales usados para presentar información (menu,...)
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

#Tamaño de la linea del menu
declare -r g_max_length_line=130




#}}}



#------------------------------------------------------------------------------------------------------------------
#> Funciones usadas durante configuración del profile {{{
#------------------------------------------------------------------------------------------------------------------
# 
# Incluye las variable globales usadas como parametro de entrada y salida de la funcion que no sea resuda por otras
# funciones, cuyo nombre inicia con '_g_'.
#

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


# Parametros:
# > Opcion ingresada por el usuario.
function _sutup_support_x11_clipboard() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #2. Determinar si se requiere instalar
    local l_option=4
    local l_flag_ssh_srv=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_ssh_srv=0
    fi
    
    l_option=2
    local l_flag_ssh_clt_without_xsrv=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_ssh_clt_without_xsrv=0
    fi

    l_option=1
    local l_flag_ssh_clt_with_xsrv=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_ssh_clt_with_xsrv=0
    fi

    #Si no se solicitar instalar no instalar ningun comando
    if [ $l_flag_ssh_srv -ne 0 ] && [ $l_flag_ssh_clt_with_xsrv -ne 0 ] && [ $l_flag_ssh_clt_without_xsrv -ne 0 ]; then
        return 99
    fi
   
    #3. Mostrar el titulo de instalacion

    #Obtener a quien aplica la configuración
    local l_tmp1=""
    if [ $l_flag_ssh_srv -eq 0 ]; then
        l_tmp1="SSH Server"
    fi

    if [ $l_flag_ssh_clt_with_xsrv -eq 0 ] || [ $l_flag_ssh_clt_without_xsrv -eq 0 ]; then
        if [ -z "$l_aux" ]; then
            l_tmp1="SSH Client"
        else
            l_tmp1="${l_aux}/Client"
        fi
    fi


    #Obtener lo que se va configurar/instalar
    local l_tmp2=""
    local l_pkg_options='xclip'
    printf -v l_tmp2 "instalar '%bxclip%b'" "$g_color_gray1" "$g_color_reset"

    if [ $l_flag_ssh_srv -eq 0 ]; then
        printf -v l_tmp2 "%s, '%bxorg-x11-xauth%b', configurar %bOpenSSH server%b" "$l_tmp" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        l_pkg_options="${l_pkg_options},xauth"
    fi

    if [ $l_flag_ssh_clt_without_xsrv -eq 0 ]; then
        printf -v l_tmp2 "%s, X virtual server '%bXvfb%b'" "$l_tmp" "$g_color_gray1" "$g_color_reset"
        l_pkg_options="${l_pkg_options},xvfb"
    fi

    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    #print_line '─' $g_max_length_line  "$g_color_blue1"
    printf "%bX11 Forwarding%b > Sobre '%b%s%b': %s\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_tmp1" "$g_color_reset" "$l_tmp2"
    #print_line '─' $g_max_length_line "$g_color_blue1"
    print_line '-' $g_max_length_line  "$g_color_gray1"

    #2. Si no se tiene permisos para root, solo avisar
    if [ $g_runner_sudo_support -eq 3 ] || {  [ $g_runner_id -ne 0 ] && [ $g_runner_sudo_support -eq 2 ]; }; then

        printf '%bNo tiene soporte para ejecutar en modo "root"%b. Para usar el clipbboard de su servidor remotos linux, usando el "%bX11 forwading for SSH%b".\n' \
               "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        printf 'Se recomienda usar la siguiente configuración:\n'

        printf ' > Instale el X cliente "XClip"\n'

        if [ $l_flag_ssh_srv -eq 0 ]; then

            printf ' > Configure el servidor SSH server %b(donde se ejecutará X client)%b\n' "$g_color_gray1" "$g_color_reset"
            printf '   > Configure el servidor OpenSSH server:\n'
            printf '     > Edite el archivo "%b%s%b" y modifique el campo  "%b%s%b" a "%b%sb".\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
                   "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "yes"
            printf '     > Reiniciar el servidor OpenSSH server: %b%s%b\n' "$g_color_gray1" "systemctl restart sshd.service" "$g_color_reset"
            printf '   > Validar si la componente "%bxorg-x11-xauth%b" de autorizacion de X11 esta instalando.\n' "$g_color_gray1" "$g_color_reset"

        fi

        if [ $l_flag_ssh_clt_without_xsrv -eq 0 ]; then
            printf ' > Configure el cliente SSH server en un "%bHeadless Server%b" %b(donde se ejecutará X server)%b\n' "$g_color_yellow1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
            printf '   > Instale el servidor X virtual "%bXvfb%b".\n' "$g_color_gray1" "$g_color_reset"
        fi

        return 1
    fi

    #3. Instalar los programas requeridos 
    local l_version
    local l_status
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi


    printf 'X forwarding> Iniciando %s...\n\n' "$l_tmp"

    #Parametros:
    # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
    # 2> Repositorios a instalar/acutalizar: 
    # 3> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    # 4> El estado de la credencial almacenada para el sudo
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 2 "$l_pkg_options" $g_status_crendential_storage
        l_status=$?
    else
        ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 4 "$l_pkg_options" $g_status_crendential_storage
        l_status=$?
    fi

    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #Si no se acepto almacenar credenciales
    elif [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    fi


    #5. Configurar OpenSSH server para soportar el 'X11 forwading'
    local l_ssh_config_data=""
    if [ $l_flag_ssh_srv -eq 0 ]; then

        printf '\n'
        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf '%bX11 Forwarding%b > Configurando el servidor OpenSSH...\n' "$g_color_gray1" "$g_color_reset"
        print_line '-' $g_max_length_line "$g_color_gray1"

        #Obtener la data del SSH config del servidor OpenSSH
        if [ $g_runner_sudo_support -eq 4 ]; then
            l_ssh_config_data=$(cat /etc/ssh/sshd_config 2> /dev/null)
            l_status=$?
        else
            l_ssh_config_data=$(sudo cat /etc/ssh/sshd_config 2> /dev/null)
            l_status=$?
        fi

        if [ $l_status -ne 0 ]; then
            printf 'No se obtuvo información del archivo "%b%s%b".\n' "$g_color_red1" "/etc/ssh/sshd_config" "$g_color_reset"
            return 1
        fi

    
        if ! echo "$l_ssh_config_data"  | grep '^X11Forwarding\s\+yes\s*$' &> /dev/null; then

            printf 'X forwarding> Modificando el archivo "%b%s%b": editanto el campo "%b%s%b" con el valor "%b%s%b".\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
                   "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "yes" "$g_color_reset"

            if [ $g_runner_sudo_support -eq 4 ]; then
                echo "$l_ssh_config_data" | sed 's/^#X11Forwarding\s\+\(no\|yes\)\s*$/X11Forwarding yes/' | sed 's/^X11Forwarding\s\+no\s*$/X11Forwarding yes/' \
                    > /etc/ssh/sshd_config
            else
                echo "$l_ssh_config_data" | sed 's/^#X11Forwarding\s\+\(no\|yes\)\s*$/X11Forwarding yes/' | sed 's/^X11Forwarding\s\+no\s*$/X11Forwarding yes/' | \
                    sudo tee /etc/ssh/sshd_config > /dev/null
            fi

            if [ $g_runner_sudo_support -eq 4 ]; then
                printf 'X forwarding> Reiniciando el servidor OpenSSH server: %b%s%b\n' "$g_color_gray1" "systemctl restart sshd.service" "$g_color_reset"
                systemctl restart sshd.service
            else
                printf 'X forwarding> Reiniciando el servidor OpenSSH server: %b%s%b\n' "$g_color_gray1" "sudo systemctl restart sshd.service" "$g_color_reset"
                sudo systemctl restart sshd.service
            fi

        else

            printf 'X forwarding> El archivo "%b%s%b" ya esta configurado (su campo "%b%s%b" tiene el valor "%b%s%b").\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
                   "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "yes" "$g_color_reset"

        fi

    fi


}


# Parametros:
# > Opcion ingresada por el usuario.
function _uninstall_support_x11_clipboard() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #2. Determinar si se requiere instalar VIM/NeoVIM
    local l_flag_ssh_srv=1

    local l_option=8
    local l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_ssh_srv=0; fi
    
    #Si no se solicitar instalar VIM o NeoVIM no instalar ningun comando
    if [ $l_flag_ssh_srv -ne 0 ]; then
        return 99
    fi
   
    #3. Mostrar el titulo de instalacion
    local l_title

    #Obtener a quien aplica la configuración
    local l_tmp="SSH Server"
    #printf -v l_title '%s: %s' "$l_title" "$l_tmp"

    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_blue1"
    printf "%bX11 Forwarding%b > Remover la configuración en '%b%s%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_tmp" "$g_color_reset"
    print_line '-' $g_max_length_line "$g_color_blue1"

    #2. Si no se tiene permisos para root, solo avisar
    if [ $g_runner_sudo_support -eq 3 ] || {  [ $g_runner_id -ne 0 ] && [ $g_runner_sudo_support -eq 2 ]; }; then

        printf '%bNo tiene soporte para ejecutar en modo "root"%b. Para remover la configuración "%bX11 forwading%b" del OpenSSH Server.\n' \
               "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        printf 'Se recomienda usar la siguiente configuración:\n'
        printf ' > Edite el archivo "%b%s%b" y modifique el campo  "%b%s%b" a "%b%sb".\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
               "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "no"

        return 1
    fi

    #3. Configurar OpenSSH server para soportar el 'X11 forwading'
    local l_ssh_config_data=""
    if [ $l_flag_ssh_srv -eq 0 ]; then

        printf '%bX forwarding%b> Configurando el servidor OpenSSH...\n' "$g_color_gray1" "$g_color_reset"

        #Obtener la data del SSH config del servidor OpenSSH
        if [ $g_runner_sudo_support -eq 4 ]; then
            l_ssh_config_data=$(cat /etc/ssh/sshd_config 2> /dev/null)
            l_status=$?
        else
            l_ssh_config_data=$(sudo cat /etc/ssh/sshd_config 2> /dev/null)
            l_status=$?
        fi

        if [ $l_status -ne 0 ]; then
            printf 'No se obtuvo información del archivo "%b%s%b".\n' "$g_color_red1" "/etc/ssh/sshd_config" "$g_color_reset"
            return 1
        fi

    
        if ! echo "$l_ssh_config_data"  | grep '^X11Forwarding\s\+no\s*$' &> /dev/null; then

            printf 'X forwarding> Modificando el archivo "%b%s%b": editanto el campo "%b%s%b" con el valor "%b%s%b".\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
                   "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "no" "$g_color_reset"

            if [ $g_runner_sudo_support -eq 4 ]; then
                echo "$l_ssh_config_data" | sed 's/^#X11Forwarding\s\+\(no\|yes\)\s*$/X11Forwarding no/' | sed 's/^X11Forwarding\s\+yes\s*$/X11Forwarding no/' \
                    > /etc/ssh/sshd_config
            else
                echo "$l_ssh_config_data" | sed 's/^#X11Forwarding\s\+\(no\|yes\)\s*$/X11Forwarding no/' | sed 's/^X11Forwarding\s\+yes\s*$/X11Forwarding no/' | \
                    sudo tee /etc/ssh/sshd_config > /dev/null
            fi

            if [ $g_runner_sudo_support -eq 4 ]; then
                printf 'X forwarding> Reiniciando el servidor OpenSSH server: %b%s%b\n' "$g_color_gray1" "systemctl restart sshd.service" "$g_color_reset"
                systemctl restart sshd.service
            else
                printf 'X forwarding> Reiniciando el servidor OpenSSH server: %b%s%b\n' "$g_color_gray1" "sudo systemctl restart sshd.service" "$g_color_reset"
                sudo systemctl restart sshd.service
            fi

        else

            printf 'X forwarding> El archivo "%b%s%b" ya esta configurado (su campo "%b%s%b" tiene el valor "%b%s%b").\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
                   "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "no" "$g_color_reset"

        fi

    fi


}


# Parametros de entrada:
#  1> Opción de menu a ejecutar
#
function _setup() {


    #01. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    local l_status
    
   
    #04. Eliminar el gestor 'VIM-Plug' y Packer
    #_remove_vim_plugin_manager $p_opciones
    #l_status=$?
    ##No se cumplen las precondiciones obligatorios
    #if [ $l_status -eq 111 ]; then
    #    return 111
    ##No se acepto almacenar las credenciales para usar sudo.
    #elif [ $l_status -eq 120 ]; then
    #    return 120
    #fi
    
    #05. Configurar para tener el soporte a 'X11 forwarding for SSH Server'
    _sutup_support_x11_clipboard $p_opciones
    l_status=$?
    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #No se acepto almacenar las credenciales para usar sudo.
    elif [ $l_status -eq 120 ]; then
        return 120
    fi

    #06. Configurar para tener el soporte a 'X11 forwarding for SSH Server'
    _uninstall_support_x11_clipboard $p_opciones
    l_status=$?
    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #No se acepto almacenar las credenciales para usar sudo.
    elif [ $l_status -eq 120 ]; then
        return 120
    fi


}


function _show_menu_core() {


    print_text_in_center "Menu de Opciones" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    local l_max_digits=2

    printf "     (%b%0${l_max_digits}d%b) %bCliente  SSH%b> %bX11 forwading%b> server with %bX Server%b> Instalar 'xclip'\n" \
           "$g_color_green1" "1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bCliente  SSH%b> %bX11 forwading%b> %bHeadless Server%b> Instalar el servidor X virtual '%bXvfb%b' e instalar 'xclip'\n" \
           "$g_color_green1" "2" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bServidor SSH%b> %bX11 forwading%b> Configurar OpenSSH server e instalar 'xclip', 'xorg-x11-xauth'\n" "$g_color_green1" \
           "4" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bServidor SSH%b> Eliminar el %bX11 forwading%b del OpenSSH server\n" "$g_color_green1" "8" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"


    print_line '-' $g_max_length_line "$g_color_gray1"

}

function g_main() {

    #1. Pre-requisitos
    
    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_green1" 
    _show_menu_core
    
    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -r l_options

        case "$l_options" in

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_green1" 
                    _setup $l_options
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_gray1" 
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_gray1" 
                ;;
        esac
        
    done

}


#}}}



#------------------------------------------------------------------------------------------------------------------
#> Logica principal del script {{{
#------------------------------------------------------------------------------------------------------------------

#1. Variables de los argumentos del script

#Argumento 1: el modo de ejecución del script

#printf 'Parametro 1: %s\n' "$1"
#printf 'Parametro 2: %s\n' "$2"
#printf 'Parametro 3: %s\n' "$3"
#printf 'Parametro 4: %s\n' "$4"
#printf 'Parametro 5: %s\n' "$5"
#printf 'Parametro 6: %s\n' "$6"
#printf 'Parametro 7: %s\n' "$7"
#printf 'Parametro 8: %s\n' "$8"
#printf 'Parametro 9: %s\n' "$9"



#2. Variables globales cuyos valor puede ser modificados el usuario


#3. Variables globales cuyos valor son AUTOGENERADOS internamente por el script

#Estado del almacenado temporalmente de las credenciales para sudo
# -1 - No se solicito el almacenamiento de las credenciales
#  0 - No es root: se almaceno las credenciales
#  1 - No es root: no se pudo almacenar las credenciales.
#  2 - Es root: no requiere realizar sudo.
g_status_crendential_storage=-1

#Si la credenciales de sudo es abierto externamente.
#  1 - No se abrio externamente
#  0 - Se abrio externamente (solo se puede dar en una ejecución no-interactiva)
g_is_credential_storage_externally=1


#Carpetas de archivos temporales
_g_tmp_data_path="/tmp/.files"
if [ ! -d "$_g_tmp_data_path" ]; then
    mkdir -p $_g_tmp_data_path
fi

#4. LOGICA: Configuración del profile 
_g_result=0
#_g_status=0

g_main

exit $_g_result


#}}}


