#!/bin/bash

#Funciones de utilidad de Inicialización {{{

#Determinar el tipo de SO. Devuelve:
#  00 - 10: Si es Linux
#           00 - Si es Linux genrico
#           01 - Si es WSL2
#  11 - 20: Si es Unix
#  21 - 30: si es MacOS
#  31 - 40: Si es Windows
function m_get_os_type() {
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
function m_get_linux_type_id() {

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
function m_get_linux_type_version() {

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

#Compara 2 versiones y retorna:
#   0 si es =
#   1 si es >
#   2 si es <
function m_compare_version() {

    #1. Argumentos
    local p_operating_1="$1"
    local p_operating_2="$2"

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

function m_url_encode() {
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




