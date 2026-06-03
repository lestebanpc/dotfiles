#!/bin/bash

# Obtenido y modificado de https://github.com/junegunn/fzf-git.sh

# Constantes
g_fzf_height='60%'
g_fzf_popup_height='80%'
g_fzf_popup_width='99%'

# Colores principales usados
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

# Obtener la del script
g_script_path="${BASH_SOURCE[0]}"
#echo "$g_script_path"

g_cmd_name='nerdctlu'

declare -a ga_exported_functions=(
    )

# Diccionario de sbucomandos. La key es 'id del subcomando' y value es 'la descripcion del subcomando'.
# > Segun el ID de subcomando, se debe tener 2 funciones bash cuyo nombre tiene dicho ID
#   > Funcion de ayuda del comando tiene el nombre 'm_usage_CMD-ID'.
#   > Funcion de controlador del comando tiene el nombre 'controller_CMD-ID'.
declare -A gA_subcmd_ids=(
        ['stop']='Inicia nerdctl y todos sus servicios requeridos'
        ['start']='Detiene nerdctl y todos sus servicios iniciados'
    )


# Diccionario de sbucomandos. La key es 'alias' y value es 'ID del subcomando'.
declare -A gA_subcmd_alias=(
    )


# Expresiones regulares de sustitucion mas usuadas para las versiones
# > La version 'x.y.z' esta la inicio o despues de caracteres no numericos
declare -r g_regexp_sust_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'



# -------------------------------------------------------------------------------------
# General functions
# -------------------------------------------------------------------------------------



# -------------------------------------------------------------------------------------
# Exported functions
# -------------------------------------------------------------------------------------




# -------------------------------------------------------------------------------------
# Subcomand Controller> Start
# -------------------------------------------------------------------------------------

m_usage_start() {

    local l_scmd_id='start'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [args]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


m_start_nerdctl() {

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


controller_start() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_start
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_start
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_start_nerdctl "$@"
    return 0

}



# -------------------------------------------------------------------------------------
# Subcomand Controller> Stop
# -------------------------------------------------------------------------------------

m_usage_stop() {

    local l_scmd_id='stop'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [args]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


m_stop_nerdctl() {

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


controller_stop() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_stop
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_stop
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_stop_nerdctl "$@"
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

m_get_subcmd_infos() {

    local l_scmd_id
    local l_scmd_description
    local l_alias
    local l_alias_list
    local l_id

    for l_scmd_id in "${!gA_subcmd_ids[@]}"; do

        printf "%b  > %b%s%b\n" "$g_color_gray1" "$g_color_yellow1" "$l_scmd_id" "$g_color_reset"

        # Obtener los alias del comando
        l_alias_list=''

        for l_alias in "${!gA_subcmd_alias[@]}"; do

            l_id="${gA_subcmd_alias[${l_alias}]}"

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
        l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
        printf "    %b%s%b\n" "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    done


}


m_usage_global() {

    local l_infos=""
    l_infos=$(m_get_exported_functions)

    printf 'Usage:\n'
    printf '  %b%s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s%b SUBCOMMAND%b [options] [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    if [ ! -z "$l_infos" ]; then
        printf '    %b%s%b -i FUNC_NAME [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
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
    m_get_subcmd_infos
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
    #if ! command -v jq >/dev/null 2>&1; then
    #    printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "jq" "$g_color_reset"
    #    return 1
    #fi


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
    local l_scmd_id="${gA_subcmd_alias[${1}]:-}"

    # Validar si es un ID de subcomando valido
    if [ -z "$l_scmd_id" ]; then
        l_scmd_id="$1"
    fi

    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]:-}"

    if [ -z "$l_scmd_description" ]; then
        printf '[%bERROR%b] El subcomando ingresado "%b%s%b" no es valida\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$l_scmd_id" "$g_color_reset"
        m_usage_global
        return 3
    fi

    shift

    #5. Ejecutando el controlador principal del subcomando

    "controller_${l_scmd_id}" "$@"
    return 0

}



# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $_g_result
