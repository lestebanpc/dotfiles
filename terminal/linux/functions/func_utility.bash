#!/bin/bash

#Funciones de utilidad de Inicialización {{{

#Determinar el tipo de SO. Devuelve:
#  00 - 10: Si es Linux
#           00 - Si es Linux generico
#           01 - Si es WSL2
#  11 - 20: Si es Unix
#  21 - 30: si es MacOS
#  31 - 40: Si es Windows
function get_os_type() {
    local l_system=$(uname -s)

    local l_os_type=0
    local l_tmp=""
    case "$l_system" in
        Linux*)
            l_tmp=$(uname -r)
            if [[ "$l_tmp" == *WSL* ]]; then
                l_os_type=1
            else
                l_os_type=0
            fi
            ;;
        Darwin*)  l_os_type=21;;
        CYGWIN*)  l_os_type=31;;
        MINGW*)   l_os_type=32;;
        *)        l_os_type=99;;
    esac

    return $l_os_type

}


#Determinar el tipo de distribucion Linux. Devuelve:
#  1) Retorna en un entero el tipo de distribucion Linux
#     00 : Distribución de Linux desconocido
#     01 : Ubuntu
#     02 : Fedora
#  2) En el flujo de salida, se muestra la nombre de distribucion Linux
function get_linux_type_id() {

    if [ -z "$g_info_distro" ]; then
        if ! g_info_distro=$(cat /etc/*-release 2> /dev/null); then
            return 0
        fi
    fi

    # Ubuntu:
    #   NAME="Ubuntu"
    #   VERSION="22.04.1 LTS (Jammy Jellyfish)"
    #
    # Fedora:
    #   NAME="Fedora Linux"
    #   VERSION="36 (Workstation Edition)"
    #
    local l_tag_distro_type="NAME"
    local l_distro_type=$(echo "$g_info_distro" | grep -e "^${l_tag_distro_type}=" | sed 's/'"$l_tag_distro_type"'="\(.*\)"/\1/')
    if [ -z "$l_distro_type" ]; then
        return 0
    fi
    echo "$l_distro_type"

    local l_type=0
    case "$l_distro_type" in
        Ubuntu*)
            l_type=1
            ;;
        Fedora*)
            l_type=2
            ;;
        *)
            l_type=0
            ;;
    esac

    return $l_type

}

#Determinar la version de una disstribucion Linux. Devuelve:
#  1) Retorna si obtuvo una versionde distribucion: 0 si es ok, otro valor si no se pudo obtener la version
#  2) En el flujo de salida se muestra la version de la distribucion Linux
function get_linux_type_version() {

    if [ -z "$g_info_distro" ]; then
        if ! g_info_distro=$(cat /etc/*-release 2> /dev/null); then
            return 1
        fi
    fi

    # Ubuntu:
    #   NAME="Ubuntu"
    #   VERSION="22.04.1 LTS (Jammy Jellyfish)"
    #
    # Fedora:
    #   NAME="Fedora Linux"
    #   VERSION="36 (Workstation Edition)"
    #
    local l_tag_distro_version="VERSION"
    local l_distro_version=$(echo "$g_info_distro" | grep -e "^${l_tag_distro_version}=" | sed 's/'"$l_tag_distro_version"'="\(.*\)"/\1/')
    if [ -z "$l_distro_version" ]; then
        return 1
    fi

    echo "$l_distro_version"
    return 0
}

#}}}


#Funciones de utilidad genericas {{{

#Compara 2 versiones cuyo separador es '.' o '-'
#Retorna:
#   0 si es =
#   1 si es >
#   2 si es <
function compare_version() {

    #1. Argumentos
    #local p_operating_1="$1"
    #local p_operating_2="$2"
    local p_operating_1="${1//-/.}"
    local p_operating_2="${2//-/.}"

    #2. Si son textos iguales retornar 0
    if [[ "$p_operating_1" == "$p_operating_2" ]]; then
        return 0
    fi

    #3.Generar un arreglo de enteros de una cadena usando sepador de campo .
    local IFS=.
    local la_version_1=($p_operating_1)
    local la_version_2=($p_operating_2)
    
    #4. Si el array de la version 1 es de menor tamaño que la version 2, adicionar elemento con 0
    local i=0
    for ((i=${#la_version_1[@]}; i<${#la_version_2[@]}; i++)); do
        la_version_1[i]=0
    done
    
    #5. Comparar cada elemento de la version 1, comparar valores
    for ((i=0; i<${#la_version_1[@]}; i++)); do

        #Si elemento en version 2 no existe o esta vacio, su valor es 0 
        if [[ -z ${la_version_2[i]} ]]; then
            la_version_2[i]=0
        fi

        #Comparando los elementos
        if ((10#${la_version_1[i]} > 10#${la_version_2[i]})); then
            return 1
        fi
        if ((10#${la_version_1[i]} < 10#${la_version_2[i]})); then
            return 2
        fi
    done

    return 0
}


function url_encode() {
    #set -x
    local l_string="${1}"
    local l_n=${#l_string}
    local l_encoded=""
    local l_pos l_c l_o

    for (( l_pos=0 ; l_pos<$l_n ; l_pos++ )); do

        l_c=${l_string:$l_pos:1}
        case "$l_c" in
            [-_.~a-zA-Z0-9]) 
                l_o="${l_c}" ;;
            *)  
                printf -v l_o '%%%02x' "'$l_c";
        esac
        l_encoded+="${l_o}"
    done

    echo "${l_encoded}"
    #set +x
}

#}}}



# > Argumentos:
#   1> URL del del repositorio remoto
# > Valor de retorno
#    0 - Repositorio GitHub
#    1 - Repositorio GitLab
#   99 - Repositorio desconocido
get_http_url_of_gitrepo() {

    #Ejemplos de input:
    #Caso Github:
    # > HTTPS         : https://github.com/dense-analysis/ale.git
    # > SSH           : git@githuh.com:lestebanpc/dotfiles.git
    # > SSH con alias : ghub-writer:lestebanpc/dotfiles.git
    #Caso GitLab:
    # > HTTPS         : https://gitlab.com/uc-cau/orbital/usaproject/ctacorrientes.git
    # > SSH           : git@gitlab.com:uc-cau/orbital/usaproject/ctacorrientes.git
    # > SSH con alias : glab-lestebanpc:uc-cau/orbital/usaproject/ctacorrientes.git

    #Parametros
    local l_remote_url=$1


    #Obtener el host de la URL
    local l_status=0
    local l_tmp=${l_remote_url%.git}
    local l_host
    local l_path
    local l_host_alias

    #Si usa HTTPS
    if [[ $l_remote_url =~ ^http ]]; then

        l_tmp=${l_tmp#https://}
        l_host=${l_tmp%%/*}
        l_path=${l_tmp#*/}

    #Si usa SSH
    else

        #Si no usa SSH alias
        if [[ $l_remote_url =~ ^git@ ]]; then

            l_tmp=${l_tmp#git@}
            l_host=${l_tmp%:*}
            l_path=${l_tmp#*:}

        #Si usa un SSH alias
        else

            l_host_alias=${l_tmp%:*}
            l_path=${l_tmp#*:}

            l_host=$(ssh -G $l_host_alias | awk '$1 == "hostname" { print $2 }' 2> /dev/null)
            if [ $? -ne 0 ]; then
                l_status=99
                l_host="$l_host_alias"
            fi

        fi
    fi


    #Determinar el tipo de repositorio segun el host
    case "$l_host" in

        github*)
            l_status=0
            ;;

        gitlab*)
            l_status=1
            ;;

    esac

    #Mostar la URL HTTP
    echo "https://${l_host}/${l_path}"
    return $l_status
}



g_color_reset="\x1b[0m"

#Parametros de entrada:
#  1 > caracter de la cual esta formada la linea
#  2 > Tamaño de caracteres la linea
#  3 > Color de la linea
print_line() {

    printf '%b' "$3"
    #Usar -- para no se interprete como linea de comandos y puede crearse lienas con - (usado en opcion de un comando)
    printf -- "${1}%.0s" $(seq $2)
    printf '%b\n' "$g_color_reset" 

}

#Parametros de entrada:
#  1 > Texto a colocar el en centro
#  2 > Tamaño de caracteres la linea
#  3 > Color del texto
print_text_in_center() {

    local l_n=${#1}

    if [ $l_n -ge $2 ]; then
        printf '%b%s%b\n' "$3" "$1" "$g_color_reset"
    else
        local l_m=$(((${2} - ${l_n})/2))
        printf " %.0s" $(seq ${l_m})
        printf '%b%s%b\n' "$3" "$1" "$g_color_reset"
    fi

}

#Parametros de entrada - Agumentos y opciones:
#  1 > Nombre completo de la unidad (por ejemplo: 'containerd.service')
#  2 > Flag '0' para usar el nivel 'User', caso contrario usara el nivel 'System'
#Parametros de salida - Valor de retorno:
#  0 > La unidad no esta instalada (no tiene archivo de configuracion): 
#      'systemctl list-unit-files' no lo ubica o esta en cache pero como 'not-found'
#  1 > La unidad instalada pero aun no esta en cache (no ha sido ejecutada desde el inicio del SO)
#  2 > La unidad instalada, en cache, pero marcada para no iniciarse ('unmask', 'inactive').
#  3 > La unidad instalada, en cache, pero no iniciado ('loaded', 'inactive').
#  4 > La unidad instalada, en cache, iniciado y aun ejecutandose ('loaded', 'active'/'running').
#  5 > La unidad instalada, en cache, iniciado y esperando peticionese ('loaded', 'active'/'waiting').
#  6 > La unidad instalada, en cache, iniciado y terminado ('loaded', 'active'/'exited' or 'dead').
#  7 > La unidad instalada, en cache, iniciado pero se desconoce su subestado.
# 99 > La unidad instalada, en cache, pero no se puede leer su información.
exist_systemd_unit() {

    #1. Argumentos
    local l_unit_name="$1"
    local l_level='--system'
    if [ "$2" = "0" ]; then
        l_level='--user'
    fi

    #2. Validar si la unidad esta instalada
    local l_result=$(systemctl "$l_level" --no-pager list-unit-files | grep "$l_unit_name" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_result" ]; then
        return 0
    fi

    #3. Validar el estado del servicio segun el cache del systemd
    l_result=$(systemctl "$l_level" --all --no-pager list-units | grep "$l_unit_name" 2> /dev/null)
    #  UNIT                                   LOAD      ACTIVE   SUB     DESCRIPTION
    #● accounts-daemon.service                masked    inactive dead    accounts-daemon.service

    local l_status=$?

    #Si no esta en el cache
    if [ $l_status -ne 0 ] || [ -z "$l_result" ]; then
        return 1
    fi

    #Quitar los 2 caracteres se marcas iniciales y obtener los campos
    l_result="${l_result:2}"
    local l_values=($l_result)
    local l_n=${#l_values[@]}

    if [ $l_n -lt 4 ]; then
        return 99
    fi

    #Si esta en cache pero marcada para no iniciarse
    if [ "${l_values[1]}" = 'not-found' ]; then
        return 0
    fi

    #Si esta en cache pero marcada para no iniciarse
    if [ "${l_values[1]}" = 'masked' ]; then
        return 2
    fi

    #Si esta tiene otro estado que no sea cargado en el cache
    if [ ! "${l_values[1]}" = 'loaded' ]; then
        return 99
    fi

    #Si el estado en cache cargado, pero no esta ejecutandose
    if [ "${l_values[2]}" = 'inactive' ]; then
        return 3
    fi

    #Si el estado en cache cargado e iniciado
    if [ "${l_values[2]}" = 'active' ]; then

        #Si esta ejecutandose
        if [ "${l_values[3]}" = 'running' ]; then
            return 4
        elif [ "${l_values[3]}" = 'waiting' ]; then
            return 5
        elif [ "${l_values[3]}" = 'exited' ] || [ "${l_values[3]}" = 'dead' ]; then
            return 6
        else
            return 7
        fi
    fi


    return 99
}


#Parametros de entrada - Agumentos y opciones:
#  1 > Nombre del paquete (no requiere especificar la plataforma del paquete)
#  2 > El tipo de distribucion Linux (valor de retorno devulto por get_linux_type_id) 
#      00 : Distribución de Linux desconocido
#      01 : Ubuntu
#      02 : Fedora
#Parametros de salida - Valor de retorno:
#  0 > El paquete esta instalado
#  1 > El paquete no esta instalado
#  9 > No se puede determinar 
is_package_installed() {

    local l_status
    local l_aux

    case "$2" in

        1)
            #Si es Ubuntu
            l_aux=$(dpkg -l | grep "$1" 2> /dev/null)
            l_status=$?
            
            if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
                return 1
            fi
            ;;

        2) 
            #Si es Fedora
            l_aux=$(dnf list installed | grep "$1" 2> /dev/null)
            l_status=$?

            #Ejemplo:
            #containerd.io.x86_64                                 1.6.20-3.1.fc36                     @docker-ce-stable
            
            if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
                return 1
            fi
            ;;

        *)
            return 9
            ;;
    esac

    return 0 


}


