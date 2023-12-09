#!/bin/bash

#Expresiones regulares de sustitucion mas usuadas para las versiones
if [ -z "$g_regexp_sust_version1" ]; then
    #La version 'x.y.z' esta la inicio o despues de caracteres no numericos
    declare -r g_regexp_sust_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'
    #La version 'x.y.z' o 'x-y-z' esta la inicio o despues de caracteres no numericos
    declare -r g_regexp_sust_version2='s/[^0-9]*\([0-9]\+\.[0-9.-]\+\).*/\1/'
    #La version '.y.z' esta la inicio o despues de caracteres no numericos
    declare -r g_regexp_sust_version3='s/[^0-9]*\([0-9.]\+\).*/\1/'
    #La version 'xyz' (solo un entero sin puntos)  esta la inicio o despues de caracteres no numericos
    declare -r g_regexp_sust_version4='s/[^0-9]*\([0-9]\+\).*/\1/'
    #La version 'x.y.z' esta despues de un caracter vacio
    declare -r g_regexp_sust_version5='s/.*\s\+\([0-9]\+\.[0-9.]\+\).*/\1/'
fi

#Funciones de utilidad de Inicialización {{{

#Determinar el tipo de SO compatible con interprete shell POSIX.
#Devuelve:
#  00 > Si es Linux no-WSL
#  01 > Si es Linux WSL2 (Kernel de Linux nativo sobre Windows)
#  02 > Si es Unix
#  03 > Si es MacOS
#  04 > Compatible en Linux en Windows: CYGWIN
#  05 > Compatible en Linux en Windows: MINGW
#  09 > No identificado
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
        Darwin*)  l_os_type=3;;
        CYGWIN*)  l_os_type=4;;
        MINGW*)   l_os_type=5;;
        *)        l_os_type=9;;
    esac

    return $l_os_type

}


#Determinar el tipo de distribucion Linux. Devuelve:
# 1) Retorna 0 si se encontro informacion de la distribucion Linux, caso contrario retorna 1.
# 2) En el flujo de salida, en variales globales:
#    > 'g_os_subtype_id'             : Tipo de distribucion Linux
#       > 0000000 : Distribución de Linux desconocidos
#       > 10 - 29 : Familia Fedora
#              10 : Fedora
#              11 : CoreOS Stream
#              12 : Red Hat Enterprise Linux
#              19 : Amazon Linux
#       > 30 - 49 : Familia Debian
#              30 : Debian
#              31 : Ubuntu
#    > 'g_os_subtype_name'           : Nombre de distribucion Linux
#    > 'g_os_subtype_version'        : Version extendida de la distribucion Linux
#    > 'g_os_subtype_version_pretty' : Version corta de la distribucion Linux
function get_linux_type_info() {

    local l_info_distro
    if ! l_info_distro=$(cat /etc/*-release 2> /dev/null); then
        return 1
    fi

    #Determinar el tipo de distribucion Linux
    # Ubuntu:
    #   NAME="Ubuntu"
    # Fedora:
    #   NAME="Fedora Linux"
    # Amazon Linux 2023
    #   NAME="Amazon Linux"
    #
    local l_tag="NAME"
    local l_distro_type=$(echo "$l_info_distro" | grep -e "^${l_tag}=" | sed 's/'"$l_tag"'="\(.*\)"/\1/')
    if [ -z "$l_distro_type" ]; then
        return 1
    fi

    g_os_subtype_name="$l_distro_type"
    local l_value
    case "$l_distro_type" in
        Ubuntu*)
            l_value=31
            ;;
        Fedora*)
            l_value=10
            ;;
        Amazon*)
            l_value=19
            ;;
        *)
            l_value=0
            ;;
    esac

    g_os_subtype_id=$l_value
    #if [ $l_value -eq 0 ]; then
    #    return 1
    #fi

    #Determinar la version de un distribucion Linux 
    # Ubuntu:
    #   VERSION="22.04.1 LTS (Jammy Jellyfish)"
    # Fedora:
    #   VERSION="36 (Workstation Edition)"
    # Amazon Linux 2023
    #   VERSION="2023"
    #
    l_tag="VERSION"
    local l_distro_version=$(echo "$l_info_distro" | grep -e "^${l_tag}=" | sed 's/'"$l_tag"'="\(.*\)"/\1/')

    if [ -z "$l_distro_version" ]; then
        g_os_subtype_version=""
        g_os_subtype_version_pretty=""
    else
        g_os_subtype_version="$l_distro_version"
        g_os_subtype_version_pretty=$(echo "$l_distro_version" | sed -e "$g_regexp_sust_version1")
    fi

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

#El usuario solo ingresa el texto y la funcion se encarga de darle colores
#Parametros de entrada:
#  1 > Texto a colocar el en centro
#  2 > Tamaño de caracteres la linea
#  3 > Color del texto
print_text_in_center() {

    #Aplicar colores al texto
    local l_n=${#1}

    if [ $l_n -lt $2 ]; then
        local l_m=$(((${2} - ${l_n})/2))
        printf " %.0s" $(seq ${l_m})
    fi
    printf "%b${1}%b\n" "$3" "$g_color_reset"

}

#El usuario de la funcion es el responsable de dar colores al texto
#Parametros de entrada:
#  1 > Texto a colocar el en centro (¿tiene el color pero con el formato '\x1b[**m'?)
#      Acutalmente funciona cuando se usan almacena la variable usando 'prinft -v "%b"'
#  2 > Tamaño de caracteres la linea
print_text_in_center2() {

    #Tamaño del texto sin caracteres de color
    #local l_text_without_colors=$(echo "$1" | sed -r "s/\x1b\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g")
    local l_text_without_colors=$(echo "$1" | sed -r "s/\x1b\[[0-9]\+m//g")
    local l_n=${#l_text_without_colors}

    if [ $l_n -lt $2 ]; then
        local l_m=$(((${2} - ${l_n})/2))
        printf " %.0s" $(seq ${l_m})
    fi
    printf "${1}\n"

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
#  2 > El tipo de distribucion Linux (variable global 'g_os_subtype_id' generado por la funcion 'get_linux_type_info') 
#  3 > Use '1' si es una busqueda exacta de nombre del paquete. Por defecto, su valor es '0', se busca el(los) paquete(s)
#      que contiene la cadena ingresada en el parametro 1.
#Parametros de salida - Valor de retorno:
#  0 > El paquete esta instalado
#  1 > El paquete no esta instalado
#  9 > No se puede determinar 
is_package_installed() {

    #Parametros
    local p_package_name_part="$1"
    if [ "$3" = "1" ]; then
        p_package_name_part="${1} "
    fi

    local p_os_subtype_id=$2

    #Buscar el paquete
    local l_status
    local l_aux

    #Si es un distribucion de la familia Debian
    if [ $p_os_subtype_id -ge 30 ] && [ $p_os_subtype_id -lt 50 ]; then
        
        #Si es Ubuntu
        l_aux=$(dpkg -l | grep "$p_package_name_part" 2> /dev/null)
        l_status=$?
        
        if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
            return 1
        fi

    #Si es un distribucion de la familia Fedora
    elif [ $p_os_subtype_id -ge 10 ] && [ $p_os_subtype_id -lt 30 ]; then
        
        #Si es Fedora
        l_aux=$(dnf list installed | grep "$p_package_name_part" 2> /dev/null)
        l_status=$?

        #Ejemplo:
        #containerd.io.x86_64                                 1.6.20-3.1.fc36                     @docker-ce-stable
        
        if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
            return 1
        fi
    else
        return 9
    fi

    return 0 

}



#Actualizar los paquete del SO
#Parametros de entrada - Agumentos y opciones:
#  1 > El tipo de distribucion Linux (variable global 'g_os_subtype_id' generado por la funcion 'get_linux_type_info') 
#Parametros de salida :
#  Valor de retorno :
#    0 > OK
#    1 > No OK
#    9 > Parametros de entrada invalido
upgrade_os_packages() {

    local p_os_subtype_id=$1
    local l_status=0

    #Si es un distribucion de la familia Debian
    if [ $p_os_subtype_id -ge 30 ] && [ $p_os_subtype_id -lt 50 ]; then

        #Distribución: Ubuntu
        if [ $g_is_root -eq 0 ]; then
            apt-get update
            apt-get upgrade
        else
            sudo apt-get update
            sudo apt-get upgrade
        fi
        l_status=$?

    #Si es un distribucion de la familia Fedora
    elif [ $p_os_subtype_id -ge 10 ] && [ $p_os_subtype_id -lt 30 ]; then

        #Distribución: Fedora
        if [ $g_is_root -eq 0 ]; then
            dnf upgrade
        else
            sudo dnf upgrade
        fi
        l_status=$?

    else
        printf 'La actualización de paquetes del SO (tipo "%s") aun no esta implementado\n' "$p_os_type"
        l_status=9
    fi


    if [ $l_status -eq 9 ]; then
        return 9
    elif [ $l_status -ne 0 ]; then
        return 1
    fi

    return 0 

}


#Instalacion de un paquete del SO
#Parametros de entrada - Agumentos y opciones:
#  1 > Nombre del paquete o un listado de paquetes separados por espacios 
#  2 > El tipo de distribucion Linux (valor de retorno devuelto por get_linux_type_id) 
#      00 : Distribución de Linux desconocido
#      01 : Ubuntu
#      02 : Fedora
#Parametros de salida :
#  Valor de retorno :
#    0 > OK
#    1 > No OK
#    9 > Parametros de entrada invalido
install_os_package() {

    local p_package_name=$1
    local p_os_subtype_id=$2
    local l_status=0

    #Si es un distribucion de la familia Debian
    if [ $p_os_subtype_id -ge 30 ] && [ $p_os_subtype_id -lt 50 ]; then

        #Distribución: Ubuntu
        if [ $g_is_root -eq 0 ]; then
           apt-get install "$p_package_name"
        else
           sudo apt-get install "$p_package_name"
        fi
        l_status=$?

    #Si es un distribucion de la familia Fedora
    elif [ $p_os_subtype_id -ge 10 ] && [ $p_os_subtype_id -lt 30 ]; then

        #Distribución: Fedora
        if [ $g_is_root -eq 0 ]; then
           dnf install "$p_package_name"
        else
           sudo dnf install "$p_package_name"
        fi
        l_status=$?

    else

        printf 'La instalación del paquete "%s" en el SO (tipo "%s") aun no esta implementado\n' "$p_package_name" "$p_os_type"
        l_status=110
    fi


    if [ $l_status -eq 110 ]; then
        return 9
    elif [ $l_status -ne 0 ]; then
        return 1
    fi

    return 0 

}



#Desinstalacion de un paquete del SO
#Parametros de entrada - Agumentos y opciones:
#  1 > Nombre del paquete 
#  2 > El tipo de distribucion Linux (valor de retorno devuelto por get_linux_type_id) 
#      00 : Distribución de Linux desconocido
#      01 : Ubuntu
#      02 : Fedora
#Parametros de salida :
#  Valor de retorno :
#    0 > OK
#    1 > No OK
#    9 > Parametros de entrada invalido
uninstall_os_package() {

    local p_package_name=$1
    local p_os_subtype_id=$2
    local l_status=0


    #Si es un distribucion de la familia Debian
    if [ $p_os_subtype_id -ge 30 ] && [ $p_os_subtype_id -lt 50 ]; then

        #Distribución: Ubuntu
        if [ $g_is_root -eq 0 ]; then
           apt-get purge "$p_package_name"
           #apt-get autoremove
        else
           sudo apt-get purge "$p_package_name"
           #sudo apt-get autoremove
        fi
        l_status=$?

    #Si es un distribucion de la familia Fedora
    elif [ $p_os_subtype_id -ge 10 ] && [ $p_os_subtype_id -lt 30 ]; then

        #Distribución: Fedora
        if [ $g_is_root -eq 0 ]; then
           dnf erase "$p_package_name"
        else
           sudo dnf erase "$p_package_name"
        fi
        l_status=$?

    else
        printf 'La desinstalación del paquete "%s" en el SO (tipo "%s") aun no esta implementado\n' "$p_package_name" "$p_os_type"
        l_status=110
    fi


    if [ $l_status -eq 110 ]; then
        return 9
    elif [ $l_status -ne 0 ]; then
        return 1
    fi

    return 0 

}



