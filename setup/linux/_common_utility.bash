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

declare -r g_path_temp='/tmp'

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

    #2. Validar el SO
    if [ -z "$g_os_type" ]; then
        printf 'No es definido el tipo de SO\n' "$p_os_subtype_id"
        return 1
    fi

    if [ -z "$p_os_subtype_id" ]; then
        printf 'No es definido el tipo de distribucion Linux\n' "$p_os_subtype_id"
        return 1
    fi

    if [ $g_os_type -ne 0 ] && [ $g_os_type -ne 1 ]; then
        printf 'No esta implementado para el tipo SO "%s"\n' "$p_os_subtype_id"
        return 1
    fi

    #Actualmente solo esta habilitado para distribucion de la familia Debian y Fedora.
    if [ $p_os_subtype_id -lt 10 ] || [ $p_os_subtype_id -ge 50 ]; then
        printf 'No esta implementado para SO Linux de tipo "%s"\n' "$p_os_subtype_id"
        return 1
    fi

    #3. Validar la arquitectura de procesador
    if [ ! "$g_os_architecture_type" = "x86_64" ] && [ ! "$g_os_architecture_type" = "aarch64"]; then
        printf 'No esta implementado para la arquitectura de procesador "%s"\n' "$g_os_architecture_type"
        return 1
    fi

    #4. Si se instala para todos los usuarios, validar si los folderes requeridos existen si no crearlos
    local l_status=0
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
        mkdir -p "$g_path_bin_win"
        mkdir -p "$g_path_man_win"
        mkdir -p "$g_path_etc_win"
        mkdir -p "$g_path_doc_win"
    fi

    #5. El programa instalados: ¿Esta 'curl' instalado?
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

    #6. Lo que se instalar requiere permisos de root.
    if [ $p_require_root -eq 0 ]; then
        if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
            printf 'ERROR: el usuario no tiene permisos para ejecutar sudo (o el SO no tiene implementa sudo y el usuario no es root).'
            return 1
        fi
    fi

    #7. Mostar información adicional (Solo mostrar info adicional si la ejecución es interactiva)
    if [ $p_type_calling -eq 0 ]; then
        printf '%bLinux distribution - Name   : (%s) %s\n' "$g_color_opaque" "${g_os_subtype_id}" "${g_os_subtype_name}"
        printf 'Linux distribution - Version: (%s) %s (%s)\n' "$g_os_subtype_id" "$g_os_subtype_version" "$g_os_subtype_version_pretty"
        printf 'Processor architecture type : %s\n' "$g_os_architecture_type"

        if [ ! -z "$g_path_programs" ]; then
            printf 'Default program path        : "%s" (temporary data path "%s")' "$g_path_programs" "$g_path_temp"
            if [ $g_os_type -eq 1 ] && [ ! -z "$g_path_programs_win" ]; then
                printf ' (Windows "%s")\n' "$g_path_programs_win"
            else
                printf '\n'
            fi
        fi

        if [ ! -z "$g_path_bin" ]; then
            printf 'Default command path        : "%s"' "$g_path_bin"
            if [ $g_os_type -eq 1 ] && [ ! -z "$g_path_bin_win" ]; then
                printf ' (Windows "%s/bin")\n' "$g_path_bin_win"
            else
                printf '\n'
            fi
        fi

        local l_aux='Root ('
        if [ $g_user_is_root -eq 0 ]; then
            l_aux="${l_aux}Yes)"
        else
            l_aux="${l_aux}No), Sudo Support ("
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

#Parametros de entrada
#  1> Ruta del origin donde esta el comprimido
#  2> Nombre de archivo comprimido
#  3> Ruta destino donde se descromprimira el archivo
#  4> El tipo de item de cada artefacto puede ser:
#     Comprimidos no tan pesados (se descomprimen y copian en el lugar deseado)
#       > 0 si es un .tar.gz
#       > 1 si es un .zip
#       > 2 si es un .gz
#       > 3 si es un .tgz
#       > 4 si es un .tar.xz
#Parametros de salida
#   > Valor de retorno: 0 si es exitoso
#   > Variable global 'g_filename_without_ext' con el nombre del archivo comprimido sin su extension
uncompress_program() {

    local p_path_source="$1"
    local p_compressed_filename="$2"
    local p_path_destination="$3"
    local p_compressed_filetype="$4"

    g_filename_without_ext=""

    # Si el tipo de item es 10 si es un comprimido '.tar.gz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    if [ $p_compressed_filetype -eq 0 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        tar -xf "${p_path_source}/${p_compressed_filename}" -C "${p_path_destination}"
        rm "${p_path_source}/${p_compressed_filename}"
        chmod u+rw ${p_path_destination}/*

        g_filename_without_ext="${p_compressed_filename%.tar.gz}"

    # Si el tipo de item es 11 si es un comprimido '.zip' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_compressed_filetype -eq 1 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        unzip -q "${p_path_source}/${p_compressed_filename}" -d "${p_path_destination}"
        rm "${p_path_source}/${p_compressed_filename}"
        chmod u+rw ${p_path_destination}/*

        g_filename_without_ext="${p_compressed_filename%.zip}"


    # Si el tipo de item es 12 si es un comprimido '.gz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_compressed_filetype -eq 2 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        cd "${p_path_destination}"
        gunzip -q "${p_path_source}/${p_compressed_filename}"
        #Elimina el comprimido cuando el comando termina en exito.
        #rm "${p_path_source}/${p_compressed_filename}"
        chmod u+rw ${p_path_destination}/*

        g_filename_without_ext="${p_compressed_filename%.gz}"


    # Si el tipo de item es 13 si es un comprimido '.tgz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_compressed_filetype -eq 3 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        tar -xf "${p_path_source}/${p_compressed_filename}" -C "${p_path_destination}"
        rm "${p_path_source}/${p_compressed_filename}"
        chmod u+rw ${p_path_destination}/*

        g_filename_without_ext="${p_compressed_filename%.tgz}"

    # Si el tipo de item es 14 si es un comprimido '.tar.xz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_compressed_filetype -eq 4 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        tar -xJf "${p_path_source}/${p_compressed_filename}" -C "${p_path_destination}"
        rm "${p_path_source}/${p_compressed_filename}"
        chmod u+rw ${p_path_destination}/*

        g_filename_without_ext="${p_compressed_filename%.tar.xz}"

    else
        return 1
    fi

    return 0
}

#Parametros de entrada
#  1> Nombre de archivo comprimido
#  2> El tipo de item de cada artefacto puede ser:
#     Comprimidos no tan pesados (se descomprimen y copian en el lugar deseado)
#       > 0 si es un .tar.gz
#       > 1 si es un .zip
#       > 2 si es un .gz
#       > 3 si es un .tgz
#       > 4 si es un .tar.xz
#Parametros de salida
#   > Valor de retorno: 0 si es exitoso
#   > STDOUT          : Nombre del archivo sin extension  
function compressed_program_name() {

    local p_compressed_filename="$1"
    local p_compressed_filetype="$2"

    local l_filename_without_ext=""


    # Si el tipo de item es 20, es un comprimido '.tar.gz' pesado por lo que se descomprimira directamente en el lugar deseado.
    if [ $p_compressed_filetype -eq 0 ]; then

        l_filename_without_ext="${p_compressed_filename%.tar.gz}"

    # Si el tipo de item es 21, es un comprimido '.zip' pesado por lo que se descomprimira directamente en el lugar deseado.
    elif [ $p_compressed_filetype -eq 1 ]; then

        l_filename_without_ext="${p_compressed_filename%.zip}"

    # Si el tipo de item es 22, es un comprimido '.gz' pesado por lo que se descomprimira directamente en el lugar deseado.
    elif [ $p_compressed_filetype -eq 2 ]; then

        l_filename_without_ext="${p_compressed_filename%.gz}"

    # Si el tipo de item es 23, es un comprimido '.tgz' pesado por lo que se descomprimira directamente en el lugar deseado.
    elif [ $p_compressed_filetype -eq 3 ]; then

        l_filename_without_ext="${p_compressed_filename%.tgz}"

    # Si el tipo de item es 24, es un comprimido '.tar.xz' pesado por lo que se descomprimira directamente en el lugar deseado.
    elif [ $p_compressed_filetype -eq 4 ]; then

        l_filename_without_ext="${p_compressed_filename%.tar.xz}"

    else
        return 1
    fi

    echo "$l_filename_without_ext"
    return 0
}


#Si la unidad servicio 'containerd' esta iniciado, solicitar su detención y deternerlo
#Parametros de entrada (argumentos y opciones):
#   1 > Nombre completo de la unidad de systemd
#Opcionales:
#   2 > Flag '0' si se usara para desintalar, caso contrario se usara para instalar/actualizar.
#   3 > ID del repositorio
#   4 > Indice del artefato del repositorio que se desea instalar
#Parametros de salida (valor de retorno):
#   0 > La unidad systemd NO esta instalado y NO esta iniciado
#   1 > La unidad systemd esta instalado pero NO esta iniciado (esta detenido)
#   2 > La unidad systemd esta iniciado pero NO se acepto deternerlo
#   3 > La unidad systemd iniciado se acepto detenerlo a nivel usuario
#   4 > La unidad systemd iniciado se acepto detenerlo a nivel system
function request_stop_systemd_unit() {

    #1. Argumentos
    local p_unit_name="$1"
    local p_is_uninstalling=1
    if [ "$2" = "0" ]; then
        p_is_uninstalling=0
    fi
    local p_repo_id="$3"
    local p_artifact_index=-1
    if [[ "$4" =~ ^[0-9]+$ ]]; then
        p_option_relative_idx=$4
    fi
    
    #2. Averigur el estado actual de la unidad systemd
    local l_option
    local l_status
    local l_is_user=0

    exist_systemd_unit "$p_unit_name" $l_is_user
    l_status=$?   #  1 > La unidad instalada pero aun no esta en cache (no ha sido ejecutada desde el inicio del SO)
                  #  2 > La unidad instalada, en cache, pero marcada para no iniciarse ('unmask', 'inactive').
                  #  3 > La unidad instalada, en cache, pero no iniciado ('loaded', 'inactive').
                  #  4 > La unidad instalada, en cache, iniciado y aun ejecutandose ('loaded', 'active'/'running').
                  #  5 > La unidad instalada, en cache, iniciado y esperando peticionese ('loaded', 'active'/'waiting').
                  #  6 > La unidad instalada, en cache, iniciado y terminado ('loaded', 'active'/'exited' or 'dead').
                  #  7 > La unidad instalada, en cache, iniciado pero se desconoce su subestado.
                  # 99 > La unidad instalada, en cache, pero no se puede leer su información.

    if [ $l_status -eq 0 ]; then

        #Averiguar si esta instalado a nivel system
        l_is_user=1
        exist_systemd_unit "$p_unit_name" $l_is_user
        l_status=$?

        if [ $l_status -eq 0 ]; then
            return 0
        fi
    fi

    #Si se no esta iniciado, salir
    if [ $l_status -lt 4 ] || [ $l_status -gt 7 ]; then
        return 1
    fi

    #3. Solicitar la detención del servicio
    printf "%bLa unidad systemd '%s' esta iniciado y requiere detenerse para " "$g_color_warning" "$p_unit_name"

    if [ $p_is_uninstalling -eq 0 ]; then
        printf 'desinstalar '
    else
        printf 'instalar '
    fi

    if [ $p_artifact_index -lt 0 ]; then
        printf 'un artefacto del '
    else
        printf 'el artefacto[%s] del ' "$p_artifact_index"
    fi

    if [ -z "$p_repo_id" ]; then
        printf 'resositorio.\n'
    else
        printf "repositorio '%s'.\n" "$p_repo_id"
    fi


    printf "¿Desea detener la unidad systemd?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_opaque" "$g_color_reset"
    read -rei 's' -p ': ' l_option
    if [ "$l_option" != "s" ]; then

        if [ $p_is_uninstalling -eq 0 ]; then
            printf '%bNo se desinstalará ' "$g_color_opaque"
        else
            printf '%bNo se instalará ' "$g_color_opaque"
        fi

        if [ $p_artifact_index -lt 0 ]; then
            printf 'un artefacto del '
        else
            printf 'el artefacto[%s] del ' "$p_artifact_index"
        fi

        if [ -z "$p_repo_id" ]; then
            printf "resositorio.\nDetenga el servicio '%s' y vuelva ejecutar el menú o acepte su detención para su " "$p_unit_name"
        else
            printf "repositorio '%s'.\nDetenga el servicio '%s' y vuelva ejecutar el menú o acepte su detención para su " "$p_repo_id" "$p_unit_name"
        fi

        if [ $p_is_uninstalling -eq 0 ]; then
            printf 'desinstalación.%b\n' "$g_color_reset"
        else
            printf 'instalación.%b\n' "$g_color_reset"
        fi

        return 2

    fi

    #4. Detener la unidad systemd

    #Si la unidad systemd esta a nivel usuario
    if [ $l_is_user -eq 0 ]; then
        printf 'Deteniendo la unidad "%s" a nivel usuario ...\n' "$p_unit_name"
        systemctl --user stop "$p_unit_name"
        return 3
    fi


    printf 'Deteniendo la unidad "%s" a nivel sistema ...\n' "$p_unit_name"
    if [ $g_user_is_root -eq 0 ]; then
        systemctl stop "$p_unit_name"
    else
        sudo systemctl stop "$p_unit_name"
    fi

    return 4

}



#Si un nodo k0s esta iniciado solicitar su detención y deternerlo.
#Parametros de entrada (argumentos y opciones):
#Opcionales:
#   1 > Flag '0' si se usara para desintalar, caso contrario se usara para instalar/actualizar.
#   2 > ID del repositorio
#   3 > Indice del artefato del repositorio que se desea instalar
#Parametros de salida (valor de retorno):
#   0 > El nodo no esta iniciado (no esta instalado o esta detenido).
#   1 > El nodo está iniciado pero NO se acepto deternerlo.
#   2 > El nodo esta iniciado y se acepto detenerlo.
function request_stop_k0s_node() {

    #1. Argumentos
    local p_is_uninstalling=1
    if [ "$1" = "0" ]; then
        p_is_uninstalling=0
    fi
    local p_repo_id="$2"
    local p_artifact_index=-1
    if [[ "$3" =~ ^[0-9]+$ ]]; then
        p_option_relative_idx=$3
    fi
    
    #2. Determinar el estado actual del demonio k0s
    local l_option
    local l_status
    local l_info

    #Si se no esta instalado o esta detenenido, salir
    l_info=$(sudo k0s status 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_info" ]; then
        return 0
    fi

    #Si esta detenido, salir
    local l_aux
    l_aux=$(echo "$l_info" | grep -e '^Process ID' 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ] || [ -z "$l_aux" ]; then
        return 0
    fi

    #Recuperar información adicional.
    local l_node_process_id=$(echo "$l_aux" | sed 's/.*: \(.*\)/\1/' 2> /dev/null)
    local l_nodo_type=$(echo "$l_info" | grep -e '^Role' | sed 's/.*: \(.*\)/\1/' 2> /dev/null)

    #3. Solicitar la detención del servicio
    printf "%bEl nodo k0s '%s' (PID: %s) esta iniciado y requiere detenerse para " "$g_color_warning" "$l_nodo_type" "$l_node_process_id"

    if [ $p_is_uninstalling -eq 0 ]; then
        printf 'desinstalar '
    else
        printf 'instalar '
    fi

    if [ $p_artifact_index -lt 0 ]; then
        printf 'un artefacto del '
    else
        printf 'el artefacto[%s] del ' "$p_artifact_index"
    fi

    if [ -z "$p_repo_id" ]; then
        printf 'resositorio.\n'
    else
        printf "repositorio '%s'.\n" "$p_repo_id"
    fi


    printf "¿Desea detener el nodo k0s?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_opaque" "$g_color_reset"
    read -rei 's' -p ': ' l_option
    if [ "$l_option" != "s" ]; then

        if [ $p_is_uninstalling -eq 0 ]; then
            printf '%bNo se desinstalará ' "$g_color_opaque"
        else
            printf '%bNo se instalará ' "$g_color_opaque"
        fi

        if [ $p_artifact_index -lt 0 ]; then
            printf 'un artefacto del '
        else
            printf 'el artefacto[%s] del ' "$p_artifact_index"
        fi

        if [ -z "$p_repo_id" ]; then
            printf "resositorio.\nDetenga el nodo k0s '%s' y vuelva ejecutar el menú o acepte su detención para su " "$l_nodo_type"
        else
            printf "repositorio '%s'.\nDetenga el nodo k0s '%s' y vuelva ejecutar el menú o acepte su detención para su " "$p_repo_id" "$l_nodo_type"
        fi

        if [ $p_is_uninstalling -eq 0 ]; then
            printf 'desinstalación.%b\n' "$g_color_reset"
        else
            printf 'instalación.%b\n' "$g_color_reset"
        fi

        return 1

    fi


    #4. Detener el nodo k0s
    printf 'Deteniendo el nodo k0s %s ...\n' "$l_nodo_type"
    if [ $g_user_is_root -eq 0 ]; then
        k0s stop
    else
        sudo k0s stop
    fi
    return 2
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


#Menu dinamico: Listado de repositorios que son instalados por las opcion de menu dinamicas
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

        printf "     (%b%0${p_max_digits}d%b) %s %b%b%b> " "$g_color_title" "$l_option_value" "$g_color_reset" \
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

