#!/bin/bash

#Inicialización Global {{{


#Colores principales usados para presentar información (menu,...)
g_color_opaque="\x1b[90m"
g_color_reset="\x1b[0m"
g_color_title="\x1b[32m"
g_color_subtitle="\x1b[36m"
g_color_info="\x1b[33m"
g_color_warning="\x1b[31m"

#Tamaño de la linea del menu
g_max_length_line=130

#}}}


#Parametros de entrada - Agumentos y opciones:
#  1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info') 
#  2 > El tipo de invocación/ejecución del script que invoca este metodo
#      (0) Ejecución interactiva del script (muestra el menu).
#      (1) Ejecución no-interactiva del script para instalar/actualizar un conjunto de respositorios
#      (2) Ejecución no-interactiva del script para instalar/actualizar un solo repositorio
#  3 > Flag '0' si se requere curl
#  4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
# Retorno:
#   0 - Se tiene los programas necesarios para iniciar la configuración
#   1 - No se tiene los programas necesarios para iniciar la configuración
function fulfill_preconditions() {

    #Argumentos
    local p_os_subtype_id="$1"

    local p_type_calling=$2
    if [ -z "$p_type_calling" ]; then
        p_type_calling=0
    fi 

    local p_require_curl=1
    if [ "$p_require_curl" = "0" ]; then
        p_require_curl=0
    fi
    local p_require_root=1
    if [ "$p_require_root" = "0" ]; then
        p_require_root=0
    fi

    #1. Validar si ejecuta dentro de un repostorio git
    if [ ! -d ~/.files/.git ]; then

        echo "No existe los archivos necesarios, debera seguir los siguientes pasos:"
        echo "   1> Descargar los archivos del repositorio:"
        echo "      git clone https://github.com/lestebanpc/dotfiles.git ~/.files"
        echo "   2> Instalar comandos basicos:"
        echo "      chmod u+x ~/.files/setup/01_setup_commands.bash"
        echo "      ~/.files/setup/01_setup_commands.bash"
        echo "   3> Configurar el profile del usuario:"
        echo "      chmod u+x ~/.files/setup/02_setup_profile.bash"
        echo "      ~/.files/setup/02_setup_profile.bash"

        return 1
    fi

    #1. Validar el SO
    local l_status=0

    if [ ! -z "$p_os_subtype_id" ]; then
        #Actualmente solo esta habilitado para distribucion de la familia Debian y Fedora.
        if [ $p_os_subtype_id -lt 10 ] || [ $p_os_subtype_id -ge 50 ]; then
            printf 'No esta implementado operaciones para SO Linux de tipo "%s"\n' "$p_os_subtype_id"
            return 1
        fi
    else
        printf 'No es definido el tipo de distribucion Linux\n' "$p_os_subtype_id"
        return 1
    fi

    #2. Si se instala para todos los usuarios, validar si los folderes requeridos existen si no crearlos
    local l_group_name
    if [ ! -z "$g_path_programs" ] && [ ! -d "$g_path_programs" ]; then

        printf 'La carpeta "%s" de programas no existe, se creará...\n' "$g_path_programs"
        
        if [ $g_user_sudo_support -eq 0 ] || [ $g_user_sudo_support -eq 1 ]; then
            sudo mkdir -pm 755 "$g_path_programs"
            l_status=$?

            #Obtener el grupo primario
            if ! l_group_name=$(id -gn 2> /dev/null); then
                sudo chown ${USER}:${l_group_name} "$g_path_programs"
            fi
        else 
            mkdir -pm 755 "$g_path_programs"
            l_status=$?
        fi

        if [ $l_status -ne 0 ]; then
            printf 'Se requiere que la carpeta "%s" de programas este creado y se tenga acceso de escritura.\n' "$g_path_programs"
            return 1
        fi

        #Creando subdirectorios opcionales
        mkdir -p "$g_path_programs/userkeys"
        mkdir -p "$g_path_programs/userkeys/tls"
        mkdir -p "$g_path_programs/userkeys/ssh"

    fi

    if [ $g_os_type -eq 1 ] && [ ! -z "$g_path_programs_win" ] && [ ! -d "$g_path_programs_win" ]; then
        mkdir -p "$g_path_programs_win"
        mkdir -p "$g_path_bin_base_win"
        mkdir -p "$g_path_bin_base_win/bin"
        mkdir -p "$g_path_bin_base_win/doc"
        mkdir -p "$g_path_bin_base_win/etc"
        mkdir -p "$g_path_bin_base_win/man"
    fi

    #3. El programa instalados: ¿Esta 'curl' instalado?
    local l_curl_version
    if [ $p_require_curl -eq 0 ]; then
        l_curl_version=$(curl --version 2> /dev/null)
        if [ -z "$l_curl_version" ]; then

            printf '\nERROR: CURL no esta instalado, debe instalarlo para descargar los artefactos a instalar/actualizar.\n'
            printf '%bBinarios: https://curl.se/download.html\n' "$g_color_opaque"
            printf 'Paquete Ubuntu/Debian:\n'
            printf '          apt-get install curl\n'
            printf 'Paquete CentOS/Fedora:\n'
            printf '          dnf install curl\n%b' "$g_color_reset"

            return 1
        fi
    fi

    #4. Lo que se instalar requiere permisos de root.
    if [ $p_require_root -eq 0 ]; then
        if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
            printf 'ERROR: el usuario no tiene permisos para ejecutar sudo (o el SO no tiene implementa sudo y el usuario no es root).'
            return 1
        fi
    fi

    #5. Mostar información adicional (Solo mostrar info adicional si la ejecución es interactiva)
    if [ $p_type_calling -eq 0 ]; then
        printf '%bLinux distribution - Name   : (%s) %s\n' "$g_color_opaque" "${g_os_subtype_id}" "${g_os_subtype_name}"
        printf 'Linux distribution - Version: (%s) %s (%s)\n' "$g_os_subtype_id" "$g_os_subtype_version" "$g_os_subtype_version_pretty"
        printf 'Processor architecture type : (%s) %s\n' "$g_os_subtype_id" "$g_os_architecture_type"

        if [ ! -z "$g_path_programs" ]; then
            printf 'Default program path        : "%s"' "$g_path_programs"
            if [ $g_os_type -eq 1 ] && [ ! -z "$g_path_programs_win" ]; then
                printf ' (Windows "%s")\n' "$g_path_programs_win"
            else
                printf '\n'
            fi
        fi

        if [ ! -z "$g_path_bin" ]; then
            printf 'Default command path        : "%s"' "$g_path_bin"
            if [ $g_os_type -eq 1 ] && [ ! -z "$g_path_bin_base_win" ]; then
                printf ' (Windows "%s/bin")\n' "$g_path_bin_base_win"
            else
                printf '\n'
            fi
        fi

        local l_aux='Root ('
        if [ $g_user_is_root -eq 0 ]; then
            l_aux="${l_aux}Yes), Sudo Support ("
        else
            l_aux="${l_aux}No), Sudo Support ("
        fi

        if [ $g_user_sudo_support -eq 0 ]; then
            l_aux="${l_aux}Sudo with password)"
        elif [ $g_user_sudo_support -eq 1 ]; then
            l_aux="${l_aux}Sudo without password)"
        elif [ $g_user_sudo_support -eq 2 ]; then
            l_aux="${l_aux}OS not support sudo)"
        elif [ $g_user_sudo_support -eq 3 ]; then
            l_aux="${l_aux}No access to run sudo)"
        else
            l_aux="${l_aux}User is root. Don't need sudo"
        fi
        printf 'User info                   : %s\n' "$l_aux"

        if [ $p_require_curl -eq 0 ]; then
            l_curl_version=$(echo "$l_curl_version" | head -n 1 | sed "$g_regexp_sust_version1")
            printf '%bCURL version                : %s%b\n' "$g_color_opaque" "$l_curl_version" "$g_color_reset"
        fi
    fi
    return 0

}

# Almacena temporalmente las credenciales del usuario para realizar sudo
# Retorno:
#   0 - Se requiere almacenar credenciales se almaceno las credenciales.
#   1 - NO se requiere almacenar credenciales (es root, el usuario no requiere ingresar las credenciales para sudo).
#   2 - Se requiere almacenar credenciales pero NO se pudo almacenar las credenciales.
#   3 - El usuario no tiene permisos para sudo.
#   4 - El sistema operativo no implementa sudo.
function storage_sudo_credencial() {

    #1. Los casos donde no se requiere almacenar el password

    # > 4 : El usuario es root (no requiere sudo)
    if [ $g_user_sudo_support -eq 4 ]; then
        return 2
    # > 1 : Soporta el comando sudo sin password
    elif [ $g_user_sudo_support -eq 1 ]; then
        return 2
    # > 3 : El usuario no tiene permisos para ejecutar sudo
    elif [ $g_user_sudo_support -eq 3 ]; then
        printf 'El usuario no tiene permiso para ejecutar sudo. %bSolo se va instalar/configurar paquetes/programas que no requieren acceso de "root"%b\n' \
               "$g_color_warning" "$g_color_reset"
        return 3
    # > 2 : El SO no implementa el comando sudo
    elif [ $g_user_sudo_support -eq 4 ]; then
        printf 'El SO no implementa el comando sudo. %bSolo se va instalar/configurar paquetes/programas que no requieren acceso de "root"%b\n' \
               "$g_color_warning" "$g_color_reset"
        return 4
    fi

    #2. Almacenar el password (si se soporta el comando sudo pero con password)
    sudo -v
    if [ $? -ne 0 ]; then
        printf 'ERROR: Se requiere alamcenar temporalmente su credencial para realizar sudo ("sudo -v")\n\n'
        return 1
    fi
    printf '\n'
    return 0
}


# Elimina (caduca) las credenciales del usuario para realizar sudo
# Retorno:
#   0 - Se elimino las credencial en el storage temporal
#   1 - NO se requiere almacenar las credenciales para sudo
function clean_sudo_credencial() {

    #1. Los casos donde no se requiere almacenar el password

    # > 4 : El usuario es root (no requiere sudo)
    if [ $g_user_sudo_support -eq 4 ]; then
        return 1
    # > 1 : Soporta el comando sudo sin password
    elif [ $g_user_sudo_support -eq 1 ]; then
        return 1
    # > 3 : El usuario no tiene permisos para ejecutar sudo
    elif [ $g_user_sudo_support -eq 3 ]; then
        return 1
    # > 2 : El SO no implementa el comando sudo
    elif [ $g_user_sudo_support -eq 4 ]; then
        return 1
    fi


    #3. Caducar las credecinales de root almacenadas temporalmente
    printf '\nCaducando el cache de temporal password de su "sudo"\n'
    sudo -k
    return 0
}




#Menu dinamico: Listado de repositorios que son instalados por las opcion de menu dinamicas
#  - Cada repositorio tiene un ID interno del un repositorios y un identifificador realizar: 
#    ['internal-id']='external-id'
#  - Por ejemplo para el repositorio GitHub 'stedolan/jq', el item se tendria:
#    ['jq']='stedolan/jq'
declare -A gA_packages=(
    )

#Menu dinamico: Titulos de las opciones del menú
#  - Cada entrada define un opcion de menú. Su valor define el titulo.
declare -a ga_menu_options_title=(
    )

#Menu dinamico: Repositorios de programas asociados asociados a una opciones del menu.
#  - Cada entrada define un opcion de menú. 
#  - Su valor es un cadena con ID de repositorios separados por comas.
declare -a ga_menu_options_packages=(
    )


#Parametros:
# 1 > Offset del indice donde inicia el menu dinamico (usualmente, el menu dinamico no inicia desde la primera opcion del dinamico menú).
get_length_menu_option() {
    
    local p_offset_option_index=$1

    local l_nbr_options=${#ga_menu_options_packages[@]}
    local l_max_digits_aux="$((1 << (p_offset_option_index + l_nbr_options)))"

    return ${#l_max_digits_aux}
}

#El menu dinamico muestra una opción de menú que es:
#   ([Correlativo]) [Etiquete del opción de menu] [Titulo de la opción de menu]: [Listado de los repositorio que se configurará]
#Parametros de entrada:
#  1> Etiqueta de la opción de menú. 
#     Texto que aparece al costado del opción ('Instalar o actualizar' o 'Desintalar')
#  2> Offset del indice donde inicia el menu dinamico (usualmente, el menu dinamico no inicia desde la primera opcion del dinamico menú).
#  3> Numero maximo de digitos de una opción del menu personalizado.
#Variables de entrada
#  ga_menu_options_title > Listado titulos de una opción de menú.
#  ga_menu_options_packages > Listado de ID de repositorios configurados por una opción de menú.
#  gA_packages       > Diccionario de identificadores de repositorios configurados por una opción de menú.  
show_dynamic_menu() {

    #Argumentos
    local p_option_tag=$1
    local p_offset_option_index=$2
    local p_max_digits=$3


#Menu dinamico: Listado de repositorios que son instalados por las opcion de menu dinamicas

    #Espacios vacios al inicio del menu
    local l_empty_space
    local l_aux=$((8 + p_max_digits))
    printf -v l_empty_space ' %.0s' $(seq $l_aux)

    #Recorreger las opciones dinamicas del menu personalizado
    local l_i=0
    local l_j=0
    local IFS=','
    local la_repos
    local l_option_value
    local l_n
    local l_repo_names
    local l_repo_id



    for((l_i=0; l_i < ${#ga_menu_options_packages[@]}; l_i++)); do

        #Si no tiene repositorios a instalar, omitirlos
        l_option_value=$((1 << (p_offset_option_index + l_i)))

        l_aux="${ga_menu_options_packages[$l_i]}"
        #if [ -z "$l_aux" ] || [ "$l_aux" = "-" ]; then
        #    printf "     (%b%0${p_max_digits}d%b) %s\n" "$g_color_title" "$l_option_value" "$g_color_reset" "${ga_menu_options_title[$l_i]}"
        #    continue
        #fi

        #Obtener los repositorios a configurar
        IFS=','
        la_repos=(${l_aux})
        IFS=$' \t\n'

        printf "     (%b%0${p_max_digits}d%b) %s \"%b%s%b\": " "$g_color_title" "$l_option_value" "$g_color_reset" \
               "$p_option_tag" "$g_color_title" "${ga_menu_options_title[$l_i]}" "$g_color_reset"

        l_n=${#la_repos[@]}
        if [ $l_n -gt 3 ]; then
            printf "\n${l_empty_space}"
        fi

        l_repo_names=''
        for((l_j=0; l_j < ${l_n}; l_j++)); do

            l_repo_id="${la_repos[${l_j}]}"
            l_aux="${gA_packages[${l_repo_id}]}"
            if [ -z "$l_aux" ]; then
                l_aux="$l_repo_id"
            fi

            if [ $l_j -eq 0 ]; then
                l_repo_names="'${g_color_opaque}${l_aux}${g_color_reset}'" 
            else
                if [ $l_j -eq 6 ]; then
                    l_repo_names="${l_repo_names},\n${l_empty_space}'${g_color_opaque}${l_aux}${g_color_reset}'"
                else
                    l_repo_names="${l_repo_names}, '${g_color_opaque}${l_aux}${g_color_reset}'"
                fi
            fi

        done

        printf '%b\n' "$l_repo_names"

    done


}

