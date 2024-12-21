#!/bin/bash


#Funciones de Utilidad {{{


g_usage() {

    printf 'Usage:\n'
    printf '  > %bDesintalar repositorios mostrando el menú de opciones%b:\n' "$g_color_cian1" "$g_color_reset" 
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash uninstall\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash uninstall TARGET_HOME_PATH REPO_NAME PRG_PATH CMD_BASE_PATH TEMP_PATH\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '  > %bInstalar repositorios mostrando el menú de opciones (interactivo)%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash 0\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash 0 TARGET_HOME_PATH REPO_NAME PRG_PATH CMD_BASE_PATH TEMP_PATH SETUP_ONLYLAST_VERSION\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un grupo de repositorios sin mostrar el menú y usando los ID del menu%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE MENU-OPTIONS\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE MENU-OPTIONS TARGET_HOME_PATH REPO_NAME PRG_PATH CMD_BASE_PATH TEMP_PATH SUDO-STORAGE-OPTIONS\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE MENU-OPTIONS TARGET_HOME_PATH REPO_NAME PRG_PATH CMD_BASE_PATH TEMP_PATH SUDO-STORAGE-OPTIONS SETUP_ONLYLAST_VERSION\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %bDonde:%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    > %bCALLING_TYPE%b (para este escenario) es 1 si es interactivo, 3 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un repositorio sin mostrar el  menú y usando los ID de los repositorios%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE LIST-REPO-ID%b\n' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE LIST-REPO-ID TARGET_HOME_PATH REPO_NAME PRG_PATH CMD_BASE_PATH TEMP_PATH SUDO-STORAGE-OPTIONS%b\n' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE LIST-REPO-ID TARGET_HOME_PATH REPO_NAME PRG_PATH CMD_BASE_PATH TEMP_PATH SUDO-STORAGE-OPTIONS SETUP_ONLYLAST_VERSION SHOW-TITLE-1REPO%b\n' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %bDonde:%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    > %bCALLING_TYPE%b (para este escenario) es 2 si es interactivo y 4 si es no-interactivo.%b\n\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    > %bLIST-REPO-ID%b lista de ID repositorios separados por coma. Si no %b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    > %bSHOW-TITLE-1REPO%b Es 0, si muestra el titulo cuando solo se instala 1 repositorio. Por defecto es 1.%b\n\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bTARGET_HOME_PATH %bRuta base donde el home del usuario OBJETIVO al cual se configurara su profile y donde esta el repositorio git. Este valor se obtendra segun orden prioridad:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor ingresado en el archivo de configuracion ".config.bash" (debe ser diferente de vacio)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio "g_repo_name".%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bREPO_NAME %bNombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario. Este valor se obtendra segun orden prioridad:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor ingresado en el archivo de configuracion ".config.bash" (debe ser diferente de vacio)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Si ninguno de los anteriores se establece, se usara el valor ".files".%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bPRG_PATH %bes la ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY, se usara su valor se buscara segun orden prioridad en: lo indicado en el ".config.bash", "/var/opt/tools" o "~/tools".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bCMD_BASE_PATH %bes ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts"). Si se envia vacio o EMPTY se usara segun orden de prioridad:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b> Lo indicado en el archivo de configuración: ".config.bash"%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Rutas predeterminados:%b\n' "$g_color_gray1" "$g_color_reset"
    printf '      %b> Comandos      : "/usr/local/bin"      (todos los usuarios) y "~/.local/bin"         (solo el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '      %b> Archivos man1 : "/usr/local/man/man1" (todos los usuarios) y "~/.local/man/man1"    (solo el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '      %b> Archivo fuente: "/usr/share/fonts"    (todos los usuarios) y "~/.local/share/fonts" (solo el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bTEMP_PATH %bes la ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado "/tmp".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bSUDO-STORAGE-OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi es root por lo que no se requiere almacenar la credenciales, use 2. Caso contrario, use 0 si se almaceno la credencial y 1 si no se pudo almacenar las credenciales.%b\n' \
           "$g_color_gray1" "$g_color_reset"
    printf '  > %bSETUP_ONLYLAST_VERSION %bpor defecto es 1 (false). Solo si ingresa 0 se instala/actualiza la ultima versión.%b\n\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


#Obtener el nombre del archivo comprimido sin su extensión
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
function get_filename_withoutextension() {

    local p_compressed_filename="$1"
    local p_compressed_filetype=$2

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


#Obtener 2 versiones menores a la actual
#Parametros de salida:
#  > Valor de retorno:
#    0 - OK
#    1 - No OK
#  > STDOUT: Las 2 versiones separadas por ' '
function _dotnet_get_subversions()
{
    local p_repo_name="$1"
    local p_version_pretty="$2"

    #Cortar y obtener 1er numero
    IFS='.'
    la_numbers=($p_version_pretty)
    unset IFS

    local l_n=${#la_numbers[@]}

    #Version enviada es incorrecta
    if [ $l_n -le 1 ]; then
        return 1
    fi

    local l_number=${la_numbers[0]}
    local l_status
    local l_aux
    local l_versions="$p_version_pretty"

    for ((l_i=1; l_i<=2; l_i++)); do

        l_aux=""
        ((l_n=${l_number} - ${l_i}))

        #El artefacto se obtiene del repositorio de Microsoft y usando una version especifica
        #No se usa la version LTS
        l_aux=$(curl -Ls "https://dotnetcli.azureedge.net/${p_repo_name}/${l_n}.0/latest.version")
        l_status=$?
        l_aux=$(echo "$l_aux" | sed -e "$g_regexp_sust_version1")

        if [ $l_status -eq 0 ] && [ ! -z "$l_aux" ]; then
            l_versions="${l_aux} ${l_versions}"
        fi

    done 

    if [ -z "$l_versions" ]; then
        return 1
    fi

    echo "$l_versions"
    return 0

}

#Validar si una version esta instalada
#Parametros de salida:
#  > Valor de retorno:
#    0 - Existe
#    1 - No existe
function _dotnet_exist_version()
{
    local p_repo_id="$1"
    local p_version="$2"
    local p_install_win_cmds=1          #(0) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                        #(1) Los binarios de los comandos se estan instalando en Linux
    if [ "$3" = "0" ]; then
        p_install_win_cmds=0
    fi

    #Calcular la ruta de archivo/comando donde se obtiene la version
    local l_path_file=""
    if [ $p_install_win_cmds -eq 0 ]; then
       l_path_file="${g_win_programs_path}/DotNet"
    else
       l_path_file="${g_programs_path}/dotnet"
    fi

    #Prefijo del nombre del artefacto
    local l_cmd_option=''
    if [ "$p_repo_id" = "net-sdk" ]; then
        l_cmd_option='--list-sdks'
    else
        l_cmd_option='--list-runtimes'
    fi

    #Obtener las versiones instaladas
    local l_info=""
    local l_status
    if [ $p_install_win_cmds -eq 0 ]; then
        l_info=$(${l_path_file}/dotnet.exe ${l_cmd_option} 2> /dev/null)
        l_status=$?
    else
        l_info=$(${l_path_file}/dotnet ${l_cmd_option} 2> /dev/null)
        l_status=$?
    fi

    #echo "RepoID: ${p_repo_id}, Version: ${p_version}"
    #echo "Info: ${l_info}"

    if [ $l_status -eq 0 ] && [ ! -z "$l_info" ]; then

        if [ "$p_repo_id" = "net-sdk" ]; then

            l_info=$(echo "$l_info" | grep "$p_version" | head -n 1)
            l_status=$?

        elif [ "$p_repo_id" = "net-rt-core" ]; then

            l_info=$(echo "$l_info" | grep 'Microsoft.NETCore.App' | grep "$p_version" | head -n 1)
            l_status=$?

        else
            l_info=$(echo "$l_info" | grep 'Microsoft.AspNetCore.App' | grep "$p_version" | head -n 1)
            l_status=$?

        fi

        if [ $l_status -ne 0 ]; then
            l_info=""
        fi

    else
        l_info=""
    fi

    #echo "Info: ${l_info}"

    #Resultados
    if [ -z "$l_info" ]; then
        return 1
    fi

    return 0

}


#Crea folderes de programa si no existen y si existen puede limpiar el contenido de esos folderes
#Parametros de entrada> Argumentos:
#  1> Nombre del folder base del programa que se creara si no existe
#     No puede tener un valor vacio (un programa siempre se almacena en un folder dentro del folder de programas)
#  2> Nombre del subfolder del programa que se creara y/o se realizara una limpieza.
#     Si esta vacio, la limpiza se realizara al folder base (argumento 1).
#  3> Tipo de ruta target donde se de programas a usar:
#     0 - Si se mueven a folder de programas de Linux (puede requerir permisos)
#     1 - Si se mueven a folder de programas de Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#  4> Si el folder existe, el tipo de limpieza que se realizara al contenido de este. Por defecto es 0.
#     0 - No realizar ninguna limpieza (no eliminar ningun contenido del subfolder)
#     1 - Eliminar todos los archivos existentes antes del copiado
#     2 - Eliminar todo el subfolder y crearlo nuevamente antes del copiado
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function create_or_clean_folder_on_program()
{

    #1. Argumentos
    local p_program_basefolder="$1"
    local p_program_subfolder="$2"

    local p_target_path_type=0
    if [ "$3" = "1" ]; then
        p_target_path_type=1
    fi

    local p_clean_type=0
    if [ "$4" = "1" ]; then
        p_clean_type=1
    elif [ "$4" = "2" ]; then
        p_clean_type=2
    fi

    #2. Si son programas Windows
    local l_target_path=''
    if [ $p_target_path_type -eq 1 ]; then

        l_target_path="${g_win_programs_path}/${p_program_basefolder}"
        if [ ! -z "$p_program_subfolder" ]; then
            l_target_path="${l_target_path}/${p_program_subfolder}"
        fi

        #A. Si no existe las folder base crearlo
        if [ ! -d "${g_win_programs_path}/${p_program_basefolder}" ]; then

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "${g_win_programs_path}/${p_program_basefolder}" "$g_color_reset"
            mkdir -pm 755 "${g_win_programs_path}/${p_program_basefolder}"


        #B. Si existe el folder base y no se define un subfolder, realizar la limpieza solicitada del folder base
        elif [ -z "$p_program_subfolder" ]; then

            #Validar si se requiere realizar limpieza antes del copiado
            if [ $p_clean_type -eq 1 ]; then

                printf 'Eliminando el contenido del folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                rm -rf ${l_target_path}/*

            elif [ $p_clean_type -eq 2 ]; then

                printf 'Eliminado todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                rm -rf ${l_target_path}/
                mkdir -pm 755 "${l_target_path}"

            fi

        fi

        #C. Si se indica un subfolder
        if [ ! -z "$p_program_subfolder" ]; then

            #C.1. Si no existe el subfolder, crearlo
            if [ ! -d "${l_target_path}" ]; then

                printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                mkdir -pm 755 "$l_target_path"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
                fi

            #C.2. Si existe el subfolder, realizar la limpieza
            else

                #Validar si se requiere realizar limpieza antes del copiado
                if [ $p_clean_type -eq 1 ]; then

                    printf 'Eliminando el contenido del folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                    rm -rf ${l_target_path}/*

                elif [ $p_clean_type -eq 2 ]; then

                    printf 'Eliminado todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                    rm -rf ${l_target_path}/
                    mkdir -pm 755 "${l_target_path}"

                fi

            fi

        fi

        return 0

    fi

    #2. Inicializaciones
    l_target_path="${g_programs_path}/${p_program_basefolder}"
    if [ ! -z "$p_program_subfolder" ]; then
        l_target_path="${l_target_path}/${p_program_subfolder}"
    fi

    local l_runner_is_program_owner=1
    if [ $(( g_prg_path_options & 1 )) -eq 1 ]; then
        l_runner_is_program_owner=0
    fi

    #3. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then

        #A. Si no existe las folder base crearlo
        if [ ! -d "${g_programs_path}/${p_program_basefolder}" ]; then

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "${g_programs_path}/${p_program_basefolder}" "$g_color_reset"
            mkdir -pm 755 "${g_programs_path}/${p_program_basefolder}"

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" "${g_programs_path}/${p_program_basefolder}"
            fi

        #B. Si existe el folder base y no se define un subfolder, realizar la limpieza solicitada del folder base
        elif [ -z "$p_program_subfolder" ]; then

            #Validar si se requiere realizar limpieza antes del copiado
            if [ $p_clean_type -eq 1 ]; then

                printf 'Eliminando el contenido del folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                rm -rf ${l_target_path}/*

            elif [ $p_clean_type -eq 2 ]; then

                printf 'Eliminado todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                rm -rf ${l_target_path}/
                mkdir -pm 755 "${l_target_path}"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
                fi
            fi

        fi

        #C. Si se indica un subfolder
        if [ ! -z "$p_program_subfolder" ]; then

            #C.1. Si no existe el subfolder, crearlo
            if [ ! -d "${l_target_path}" ]; then

                printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                mkdir -pm 755 "$l_target_path"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
                fi

            #C.2. Si existe el subfolder, realizar la limpieza
            else

                #Validar si se requiere realizar limpieza antes del copiado
                if [ $p_clean_type -eq 1 ]; then

                    printf 'Eliminando el contenido del folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                    rm -rf ${l_target_path}/*

                elif [ $p_clean_type -eq 2 ]; then

                    printf 'Eliminando todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                    rm -rf ${l_target_path}/
                    mkdir -pm 755 "${l_target_path}"

                    #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
                    if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
                        chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
                    fi

                fi

            fi

        fi
        
        return 0
    
    fi

    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.

    #A. Si no existe el folder, crearlo
    if [ ! -d "${g_programs_path}/${p_program_basefolder}" ]; then

        printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
        sudo mkdir -pm 755 "${g_programs_path}/${p_program_basefolder}"

    #B. Si existe y no esta definido el subfolder, limpiarlo
    elif [ -z "$p_program_subfolder" ]; then

        #Validar si se requiere realizar limpieza antes del copiado
        if [ $p_clean_type -eq 1 ]; then

            printf 'Eliminando el contenido del folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            sudo rm -rf ${l_target_path}/*

        elif [ $p_clean_type -eq 2 ]; then

            printf 'Eliminando todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            sudo rm -rf ${l_target_path}/
            sudo mkdir -pm 755 "${l_target_path}"

        fi

    fi

    #C. Si esta definido el subfolder
    if [ ! -z "$p_program_subfolder" ]; then

        #C.1. Si no existe el subfolder, crearlo
        if [ ! -d "${l_target_path}" ]; then

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            sudo mkdir -pm 755 "${l_target_path}"

        #C.2. Si existe el subfolder, limpiarlo
        else

            #Validar si se requiere realizar limpieza antes del copiado
            if [ $p_clean_type -eq 1 ]; then

                printf 'Eliminando el contenido del folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                sudo rm -rf ${l_target_path}/*

            elif [ $p_clean_type -eq 2 ]; then

                printf 'Eliminando todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                sudo rm -rf ${l_target_path}/
                sudo mkdir -pm 755 "${l_target_path}"

            fi

        fi
    fi
    

    return 0

}



#Copia un binario en la ruta de un programa.
#Parametros de entrada> Argumentos:
#  01> Source path, relativo al folder temporal, donde esta el archivo a copiar.
#  02> Source filename: 
#      - Si parametro '05' es '1', representa el nombre del archivo binario a copiar.
#      - Si parametro '05' es '0', representa el parte inical del los archivo binario a copiar.
#  03> Tipo de ruta target donde se movera el contenido:
#      0 - Si se mueven a folder de programas de Linux (puede requerir permisos)
#      1 - Si se mueven a folder de programas de Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#  04> Target path, relativo al folder base de los programa. Es el folder donde se copiara el binario.
#      No puede ser vacio.
#  05> Si es '1' (su valor por defecto), se copia solo un archivo y el indicado en el parametro 2.
#      Si es '0', se copia todos los archivos que inicien con lo indicado por el parametro 2.
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function copy_binary_on_program()
{

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"
    local p_source_filename="$2"

    local p_target_path_type=0
    if [ "$3" = "1" ]; then
        p_target_path_type=1
    fi

    local p_target_path="${g_programs_path}/$4"
    if [ $p_target_path_type -eq 1 ]; then
        p_target_path="${g_win_programs_path}/$4"
    fi

    local p_use_pattern=1
    if [ "$5" = "0" ]; then
        p_use_pattern=0
    fi

    #2. Si son binarios Windows
    if [ $p_target_path_type -eq 1 ]; then

        #Copiar los archivos
        printf 'Copiando el archivo "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}/" "$g_color_reset"

        if [ $p_use_pattern -eq 0 ]; then
            cp ${p_source_path}/${p_source_filename}* "${p_target_path}/"
        else
            cp "${p_source_path}/${p_source_filename}" "${p_target_path}/"
        fi

        return 0

    fi

    #3. Si son binarios Linux
    local l_runner_is_program_owner=1
    if [ $(( g_prg_path_options & 1 )) -eq 1 ]; then
        l_runner_is_program_owner=0
    fi

    #A. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then

        #Copiar los archivos
        printf 'Copiando el archivo "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}/" "$g_color_reset"

        if [ $p_use_pattern -eq 0 ]; then
            cp ${p_source_path}/${p_source_filename}* "${p_target_path}/"
            chmod +x ${p_target_path}/${p_source_filename}*
        else
            cp "${p_source_path}/${p_source_filename}" "${p_target_path}/"
            chmod +x "${p_target_path}/${p_source_filename}"
        fi

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
            if [ $p_use_pattern -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" ${p_target_path}/${p_source_filename}*
            else
                chown "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}/${p_source_filename}"
            fi
        fi

        return 0
    
    fi

    #B. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.

    
    #Copiar los archivos
    printf 'Copiando el archivo "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
           "$g_color_reset" "$g_color_gray1" "${p_target_path}/" "$g_color_reset"

    if [ $p_use_pattern -eq 0 ]; then
        sudo cp ${p_source_path}/${p_source_filename}* "${p_target_path}/"
        sudo chmod +x ${p_target_path}/${p_source_filename}*
    else
        sudo cp "${p_source_path}/${p_source_filename}" "${p_target_path}/"
        sudo chmod +x "${p_target_path}/${p_source_filename}"
    fi


    return 0

}



#Copia un binario en la ruta de un programa.
#Parametros de entrada> Argumentos:
#  01> Source path donde esta el archivo de ayuda a copiar.
#  02> Tipo de ayuda a copiar
#      1 - Para la ayuda man1 (archivos '*.1' o archivos '*.1.gz')
#      5 - Para la ayuda man5 (archivos '*.5' o archivos '*.5.gz')
#      7 - Para la ayuda man7 (archivos '*.7' o archivos '*.7.gz')
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function copy_man_files()
{

    #1. Argumentos
    local p_source_path="$1"
    local p_man_type=$2

    #2. Inicializaciones
    local l_target_path="${g_man_cmdpath}/man${p_man_type}"

    local l_runner_is_command_owner=1
    if [ $(( g_cmd_path_options & 1 )) -eq 1 ]; then
        l_runner_is_command_owner=0
    fi


    #3. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de comandos (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_command_owner -eq 0 ]; then

        #Si no existe las carpetas destino, crearlo
        if [ ! -d "$l_target_path" ]; then

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            mkdir -pm 755 "${l_target_path}"

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_command_owner -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
            fi

        fi

        #Copiar los archivos
        printf 'Copiando los archivos "%b%s/*.%s%b" y/o "%b%s/*.%s.gz%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "$p_source_path" \
               "$p_man_type" "$g_color_reset" "$g_color_gray1" "$p_source_path" "$p_man_type" "$g_color_reset" "$g_color_gray1" \
               "${l_target_path}/" "$g_color_reset"
               find "$p_source_path" \( -name "*.${p_man_type}" -o -name "*.${p_man_type}.gz" \) -exec cp {} "$l_target_path/" \;

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_command_owner -eq 0 ]; then
            find "$p_target_path" \( -name "*.${p_man_type}" -o -name "*.${p_man_type}.gz" \) ! -user "$g_targethome_owner" \
                 -exec chown "${g_targethome_owner}:${g_targethome_group}" {} \:
        fi

        return 0
    
    fi

    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los comandos es root.


    #Si no existe las carpetas crearlo
    if [ ! -d "$l_target_path" ]; then

        printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
        sudo mkdir -pm 755 "${l_target_path}"

    fi

    
    #Copiar los archivos
    printf 'Copiando los archivos "%b%s/*.%s%b" y/o "%b%s/*.%s.gz%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "$p_source_path" \
           "$p_man_type" "$g_color_reset" "$g_color_gray1" "$p_source_path" "$p_man_type" "$g_color_reset" "$g_color_gray1" \
           "${l_target_path}/" "$g_color_reset"
           sudo find "$p_source_path" \( -name "*.${p_man_type}" -o -name "*.${p_man_type}.gz" \) -exec cp {} "$l_target_path/" \;

    return 0

}


#Copia un fuentes en la ruta de fuentes
#Parametros de entrada> Argumentos:
#  01> Source path, relativo al folder temporal, donde estan los archivos '*.otf' y '*.ttf'.
#  02> Tipo de ruta target donde se movera el contenido:
#      0 - Si se mueven a folder de fuente de Linux (puede requerir permisos)
#      1 - Si se mueven a folder de fuente de Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#  03> Target folder, relativo al folder fuentes, donde se copiar los archivos de fuentes.
#      Si no existe, el folderes se creara
#  04> Flag '0' si se requiere actualizar el cache de fuentes del SO. Por defecto es '1' (false).
#      Solo aplica para fuentes en Linux.
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function copy_font_files()
{

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"

    local p_target_path_type=0
    if [ "$2" = "1" ]; then
        p_target_path_type=1
    fi

    local p_target_path="${g_fonts_cmdpath}/$3"
    if [ $p_target_path_type -eq 1 ]; then
        p_target_path="${g_win_font_path}/$3"
    fi

    local p_flag_update_font_cache=1
    if [ "$4" = "0" ]; then
        p_flag_update_font_cache=0
    fi

    #2. Si son binarios Windows
    if [ $p_target_path_type -eq 1 ]; then

        #Si no existe las carpetas destino, crearlo
        if [ ! -d "$p_target_path" ]; then

            printf 'Creando el folder "%b%s%b" para las fuentes...\n' "$g_color_gray1" "$p_target_path" "$g_color_reset"
            mkdir -pm 755 "${p_target_path}"

        fi

        #Copiar los archivos de fuentes
        printf 'Copiando los archivos de fuente "*.otf" y "*.ttf" desde "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
               "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset"

        #Copiar y/o sobrescribir archivos existente
        find "${p_source_path}" -maxdepth 1 -mindepth 1 \( -iname '*.otf' -o -iname '*.ttf' \) \
             -exec cp '{}' ${p_target_path} \;

        return 0

    fi

    #3. Si son binarios Linux
    local l_runner_is_command_owner=1
    if [ $(( g_cmd_path_options & 1 )) -eq 1 ]; then
        l_runner_is_command_owner=0
    fi


    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #     Solo se puede dar en estos 2 posibles escenarios:
    #     - Si el runner es root en modo de suplantacion del usuario objetivo.
    #     - Si el runner es el owner de la carpeta de comandos (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_command_owner -eq 0 ]; then

        #Si no existe las carpetas destino, crearlo
        if [ ! -d "$p_target_path" ]; then

            printf 'Creando el folder "%b%s%b" para las fuentes...\n' "$g_color_gray1" "$p_target_path" "$g_color_reset"
            mkdir -pm 755 "${p_target_path}"

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_command_owner -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}"
            fi

        fi

        #Copiar los archivos de fuentes
        printf 'Copiando los archivos de fuente "*.otf" y "*.ttf" desde "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
               "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset"

        #Copiar y/o sobrescribir archivos existente
        find "${p_source_path}" -maxdepth 1 -mindepth 1 \( -iname '*.otf' -o -iname '*.ttf' \) \
             -exec cp '{}' ${p_target_path} \;
        chmod g+r,o+r ${p_target_path}/*


        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_command_owner -eq 0 ]; then
            chown "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}"
        fi

        #Actualizar el cache de fuentes del SO
        if [ $p_flag_update_font_cache -eq 0 ]; then
            printf 'Actualizando el cache de fuentes del SO: "%bfc-cache -v%b"...\n' "$g_color_gray1" "$g_color_reset"
            fc-cache -v
        fi

        return 0
    
    fi

    #3.2. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #     - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los comandos es root.

    #Si no existe las carpetas destino, crearlo
    if [ ! -d "$p_target_path" ]; then

        printf 'Creando el folder "%b%s%b" para las fuentes...\n' "$g_color_gray1" "$p_target_path" "$g_color_reset"
        sudo mkdir -pm 755 "${p_target_path}"

    fi

    #Copiar los archivos de fuentes
    printf 'Copiando los archivos de fuente "*.otf" y "*.ttf" desde "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
           "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset"

    #Copiar y/o sobrescribir archivos existente
    sudo find "${p_source_path}" -maxdepth 1 -mindepth 1 \( -iname '*.otf' -o -iname '*.ttf' \) \
         -exec cp '{}' ${p_target_path} \;
    sudo chmod g+r,o+r ${p_target_path}/*


    #Actualizar el cache de fuentes del SO
    if [ $p_flag_update_font_cache -eq 0 ]; then
        printf 'Actualizando el cache de fuentes del SO: "%bsudo fc-cache -v%b"...\n' "$g_color_gray1" "$g_color_reset"
        sudo fc-cache -v
    fi

    return 0

}




#Copia un binario en la ruta de un comando linux.
#Parametros de entrada> Argumentos:
#  01> Source path, relativo al folder temporal, donde esta el archivo a copiar.
#  02> Source filename: 
#      - Si parametro '04' es '1', representa el nombre del archivo binario a copiar.
#      - Si parametro '04' es '0', representa el parte inical del los archivo binario a copiar.
#  03> Tipo de ruta target donde se movera el contenido (comandos):
#      0 - Si se mueven a folder de comandos de Linux (puede requerir permisos)
#      1 - Si se mueven a folder de comandos de Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#  04> Si es '1' (su valor por defecto), se copia solo un archivo y el indicado en el parametro 2.
#      Si es '0', se copia todos los archivos que inicien con lo indicado por el parametro 2.
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function copy_binary_on_command()
{

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"
    local p_source_filename="$2"

    local p_target_path_type=0
    if [ "$3" = "1" ]; then
        p_target_path_type=1
    fi

    local p_use_pattern=1
    if [ "$4" = "0" ]; then
        p_use_pattern=0
    fi

    local l_target_path="${g_bin_cmdpath}"
    if [ $p_target_path_type -eq 1 ]; then
        l_target_path="${g_win_bin_path}"
    fi

    #2. Si son binarios Windows
    if [ $p_target_path_type -eq 1 ]; then

        #Copiar los archivos
        printf 'Copiando el archivo "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${l_target_path}/" "$g_color_reset"

        if [ $p_use_pattern -eq 0 ]; then
            cp ${p_source_path}/${p_source_filename}* "${l_target_path}/"
        else
            cp "${p_source_path}/${p_source_filename}" "${l_target_path}/"
        fi

        return 0

    fi

    #3. Si son binarios Linux
    local l_runner_is_command_owner=1
    if [ $(( g_cmd_path_options & 1 )) -eq 1 ]; then
        l_runner_is_command_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #     Solo se puede dar en estos 2 posibles escenarios:
    #     - Si el runner es root en modo de suplantacion del usuario objetivo.
    #     - Si el runner es el owner de la carpeta de comandos (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_command_owner -eq 0 ]; then

        
        #Copiar los archivos
        printf 'Copiando el archivo "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${l_target_path}/" "$g_color_reset"

        if [ $p_use_pattern -eq 0 ]; then
            cp ${p_source_path}/${p_source_filename}* "${l_target_path}/"
            chmod +x ${g_bin_cmdpath}/${p_source_filename}*
        else
            cp "${p_source_path}/${p_source_filename}" "${l_target_path}/"
            chmod +x "${g_bin_cmdpath}/${p_source_filename}"
        fi

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ]; then
            if [ $p_use_pattern -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" ${l_target_path}/${p_source_filename}*
            else
                chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}/${p_source_filename}"
            fi
        fi

        return 0

    fi

    #3.1. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #     - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los comandos es root.

    #Copiar los archivos
    printf 'Copiando el archivo "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
           "$g_color_reset" "$g_color_gray1" "${l_target_path}/" "$g_color_reset"

    if [ $p_use_pattern -eq 0 ]; then
        sudo cp ${p_source_path}/${p_source_filename}* "${l_target_path}/"
        sudo chmod +x ${l_target_path}/${p_source_filename}*
    else
        sudo cp "${p_source_path}/${p_source_filename}" "${l_target_path}/"
        sudo chmod +x "${l_target_path}/${p_source_filename}"
    fi

    return 0


}


#Crea el enlace simbolico, de un binario de un programa, en la carpeta de los binarios de comandos
#Parametros de entrada> Argumentos:
#  01> Source path, relativo al folder de programas, donde esta el archivo binario donde ser creara el enalce simbolico.
#  02> Source filename: representa el nombre del archivo binario a crear su enlace simbolico.
#  03> Symbolic link name: representa el nombre del enlace simbolico creado.
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function create_binarylink_to_command()
{

    #1. Argumentos
    local p_source_path="${g_programs_path}/$1"
    local p_source_filename="$2"

    local l_target_path="${g_bin_cmdpath}"
    local p_target_filename="$3"

    #2. Inicializaciones

    #Precondicion: Debe existir el binario del programa
    if [ ! -f "${p_source_path}/${p_source_filename}" ]; then
        printf '%bNo existe el archivo "%b%s%b", en la carpeta "%b%s%b"%b, al cual se va a crear el enlace simbolico.\n' "$g_color_red1" \
               "$g_color_gray1" "${p_source_filename}" "$g_color_red1" "$g_color_gray1" "$p_source_path" "$g_color_red1" "$g_color_reset".
        return 1
    fi

    local l_runner_is_command_owner=1
    if [ $(( g_cmd_path_options & 1 )) -eq 1 ]; then
        l_runner_is_command_owner=0
    fi

    local l_runner_is_program_owner=1
    if [ $(( g_prg_path_options & 1 )) -eq 1 ]; then
        l_runner_is_program_owner=0
    fi

    #3. Si el usuario runner tiene los permisos necesarios para la instalación de comandos (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #     - Si el runner es root en modo de suplantacion del usuario objetivo.
    #     - Si el runner es el owner de la carpeta de comandos (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_command_owner -eq 0 ]; then

        #A. Dando permisos de ejecucion al binario del programa
        printf 'Estableciendo permisos de ejecucion al binario "%b%s%b" del programa ubicado en "%b%s%b" ...\n' "$g_color_gray1" "${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "$p_source_path" "$g_color_reset"
        if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then
            chmod +x "${p_source_path}/${p_source_filename}"
        else
            sudo chmod +x "${p_source_path}/${p_source_filename}"
        fi

        #B. Creando/recrenado el enlace simbolico
        printf 'Creando el enlace simbolico "%b%s%b" del binario del programa "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${l_target_path}/${p_target_filename}" "$g_color_reset"
        ln -snf "${p_source_path}/${p_source_filename}" "${l_target_path}/${p_target_filename}"

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ]; then
            chown -h "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}/${p_target_filename}"
        fi

        return 0

    fi

    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los comandos es root.

    #A. Dando permisos de ejecucion al binario del programa
    printf 'Estableciendo permisos de ejecucion al binario "%b%s%b" del programa ubicado en "%b%s%b" ...\n' "$g_color_gray1" "${p_source_filename}" \
           "$g_color_reset" "$g_color_gray1" "$p_source_path" "$g_color_reset"
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then
        chmod +x "${p_source_path}/${p_source_filename}"
    else
        sudo chmod +x "${p_source_path}/${p_source_filename}"
    fi

    #B. Creando/recrenado el enlace simbolico
    printf 'Creanado el enlace simbolico "%b%s%b" del binario del programa "%b%s%b" (sudo)...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
           "$g_color_reset" "$g_color_gray1" "${l_target_path}/${p_target_filename}" "$g_color_reset"
    sudo ln -snf "${p_source_path}/${p_source_filename}" "${l_target_path}/${p_target_filename}"

    #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
    if [ $g_runner_is_target_user -ne 0 ]; then
        sudo chown -h "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}/${p_target_filename}"
    fi

    return 0


}




#Alamacer la version del actual de un comando/programa instalado en un archivo dentro de programas.
#Parametros de entrada> Argumentos:
#  01> Target path, relativa al folder de programa, donde estara el archivo. Si es vacio se considera el folder programa.
#  02> Nombre del archivo a copiar (target filename)
#  03> Version amigable 'pretty version' de la version instalada o actualizada.
#  04> Tipo de ruta target donde se movera el contenido (comandos):
#      0 - Si se mueven a folder de comandos de Linux (puede requerir permisos)
#      1 - Si se mueven a folder de comandos de Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function save_prettyversion_on_program()
{

    #1. Argumentos
    local p_target_path_type=0
    if [ "$4" = "1" ]; then
        p_target_path_type=1
    fi

    local p_target_path="${g_programs_path}"
    if [ $p_target_path_type -eq 1 ]; then
        p_target_path="${g_win_programs_path}"
    fi

    if [ ! -z "$1" ]; then
        p_target_path="${p_target_path}/$1"
    fi

    local p_target_filename="$2"
    local p_pretty_version="$3"



    #2. Si son binarios Windows
    if [ $p_target_path_type -eq 1 ]; then


        #Almacenando la info del programa/comando
        printf 'Almacenando la version "%b%s%b" instalada/actualizada en el archivo "%b%s%b" ...\n' "$g_color_gray1" "${p_pretty_version}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}/${p_target_filename}" "$g_color_reset"
        
        echo "${p_pretty_version}" > "${p_target_path}/${p_target_filename}"
        #chmod +r "${p_target_path}/${p_target_filename}"

        return 0

    fi

    #3. Si son binarios Linux
    local l_runner_is_program_owner=1
    if [ $(( g_prg_path_options & 1 )) -eq 1 ]; then
        l_runner_is_program_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #     Solo se puede dar en estos 2 posibles escenarios:
    #     - Si el runner es root en modo de suplantacion del usuario objetivo.
    #     - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then

        #Almacenando la info del programa/comando
        printf 'Almacenando la version "%b%s%b" instalada/actualizada en el archivo "%b%s%b" ...\n' "$g_color_gray1" "${p_pretty_version}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}/${p_target_filename}" "$g_color_reset"
        
        echo "${p_pretty_version}" > "${p_target_path}/${p_target_filename}"
        chmod +r "${p_target_path}/${p_target_filename}"

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
            chown "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}/${p_target_filename}"
        fi

        return 0
    fi

    #3.2. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #     - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.

    #Almacenando la info del programa/comando
    printf 'Almacenando la version "%b%s%b" instalada/actualizada en el archivo "%b%s%b" ...\n' "$g_color_gray1" "${p_pretty_version}" \
           "$g_color_reset" "$g_color_gray1" "${p_target_path}/${p_target_filename}" "$g_color_reset"
    
    sudo echo "${p_pretty_version}" > "${p_target_path}/${p_target_filename}"
    sudo chmod +r "${p_target_path}/${p_target_filename}"

    return 0


}


#Mover el contenido (todo o parte) de un folder del temporal a una carpeta del folder de programas.
#Parametros de entrada> Argumentos:
#  1> Path source, relativa al folder temporal, donde esta en contenido que se movera.
#  2> Tipo de ruta target donde se movera el contenido:
#      0 - Si se mueven a folder de programas de Linux (puede requerir permisos)
#      1 - Si se mueven a folder de programas de Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#  3> Path destino/target, relativa al folder base del programa.
#     No puede tener un valor vacio (un programa siempre se almacena en un folder dentro del folder de programas).
#  4> Opciones adicionales del comando find que permite definir que parte de cotenido de un folder se mueve.
#     Para mover el contenido se usa el comando find usadno para buscar los elementos del primer nivel del la ruta source que se va a mover:
#      "find SOURCE -maxdepth 1 -mindepth 1 OPTIONS -exec mv '{}' TARGET \;"
#     Donde, OPTIONS representa la cadena ingresada en este parametro y por lo general se coloca criterios de exclusion de archivos o carpatas que no
#     se desea copiar
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function move_tempfoldercontent_on_program()
{

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"
    local p_target_path_type=0
    if [ "$2" = "1" ]; then
        p_target_path_type=1
    fi

    local p_target_path="${g_programs_path}/$3"
    if [ $p_target_path_type -eq 1 ]; then
        p_target_path="${g_win_programs_path}/$3"
    fi
    local p_find_options="$4"

    #2. Si son programas Windows
    if [ $p_target_path_type -eq 1 ]; then

        #Mover todos objetos del cotenido del primer nivel
        printf 'Moviendo el contenido del source folder "%b%s%b" al target folder "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"
        find "${p_source_path}" -maxdepth 1 -mindepth 1 $p_find_options -exec mv '{}' ${p_target_path} \;
        return 0

    fi

    #3. Si son programas Linux
    local l_runner_is_program_owner=1
    if [ $(( g_prg_path_options & 1 )) -eq 1 ]; then
        l_runner_is_program_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then
            
        #Mover todos objetos del cotenido del primer nivel
        printf 'Moviendo el contenido del source folder "%b%s%b" al target folder "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"

        find "${p_source_path}" -maxdepth 1 -mindepth 1 $p_find_options -exec mv '{}' ${p_target_path} \;

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
             chown -R "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}"
        fi

        return 0

    fi

 
    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.

        
    #Mover todos objetos del cotenido del primer nivel
    printf 'Moviendo el contenido del source folder "%b%s%b" al target folder "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
           "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"

    sudo find "${p_source_path}" -maxdepth 1 -mindepth 1 $p_find_options -exec mv '{}' ${p_target_path} \;


    return 0


}


#Mover el todo un folder del temporal a una carpeta del folder de programas.
#Parametros de entrada> Argumentos:
#  1> Path source, relativa al folder temporal, donde esta en folder que se movera.
#  2> Folder source, nombre del folder que se desea mover.
#  3> Tipo de ruta target donde se movera el contenido:
#      0 - Si se mueven a folder de programas de Linux (puede requerir permisos)
#      1 - Si se mueven a folder de programas de Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#  4> Path destino/target, relativa al folder base del programa, donde se almacenara el folder a mover.
#     No puede tener un valor vacio (un programa siempre se almacena en un folder dentro del folder de programas).
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function move_tempfolder_on_program()
{

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"
    local p_source_foldername="$2"

    local p_target_path_type=0
    if [ "$3" = "1" ]; then
        p_target_path_type=1
    fi

    local p_target_path="${g_programs_path}/$4"
    if [ $p_target_path_type -eq 1 ]; then
        p_target_path="${g_win_programs_path}/$4"
    fi

    #2. Si son programas Windows
    if [ $p_target_path_type -eq 1 ]; then

        #Mover el folder
        printf 'Moviendo el source folder "%b%s%b", ubicado en "%b%s%b", al target folder "%b%s%b" ...\n' "$g_color_gray1" "${p_source_foldername}" \
               "$g_color_reset" "$g_color_gray1" "${p_source_path}" "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"
        mv ${p_source_path}/${p_source_foldername}/ ${p_target_path}/
        return 0

    fi

    #3. Si son programas Linux
    local l_runner_is_program_owner=1
    if [ $(( g_prg_path_options & 1 )) -eq 1 ]; then
        l_runner_is_program_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then
            
        #Mover el folder
        printf 'Moviendo el source folder "%b%s%b", ubicado en "%b%s%b", al target folder "%b%s%b" ...\n' "$g_color_gray1" "${p_source_foldername}" \
               "$g_color_reset" "$g_color_gray1" "${p_source_path}" "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"
        mv ${p_source_path}/${p_source_foldername}/ ${p_target_path}/


        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
             chown -R "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}/${p_source_foldername}"
        fi

        return 0

    fi

 
    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.

        
    #Mover el folder
    printf 'Moviendo el source folder "%b%s%b", ubicado en "%b%s%b", al target folder "%b%s%b" ...\n' "$g_color_gray1" "${p_source_foldername}" \
           "$g_color_reset" "$g_color_gray1" "${p_source_path}" "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"
    sudo mv ${p_source_path}/${p_source_foldername}/ ${p_target_path}/

    return 0


}


#}}}




#Descargar un artefacto de un repositorio en el directorio temporal al cual siempre tiene acceso usuario runner.
#Parametros de entrada> Argumentos
# 1> URL del artefacto a dascargar
# 2> Ruta relativa a temp donde se almacenara el artefacto a descargar.
# 3> Nombre del artefacto con la que se almacenara el archivo a descargar.
# 4> Etiqueta del artefacto a descargar
download_artifact_on_temp() {

    #1. Argumentos
    local p_artifact_url=$1
    local p_target_path="${g_temp_path}/$2"
    local p_target_filename="$3"
    local p_artifact_tag="$4"


    local l_status=0

    printf '\nArtefacto "%b" a descargar - Name    : %s\n' "$p_artifact_tag" "${p_target_filename}"
    printf 'Artefacto "%b" a descargar - URL     : %s\n' "$p_artifact_tag" "${p_artifact_url}"

    
    #Descargar la artefacto
    mkdir -p "$p_target_path"

    printf "$g_color_gray1"
    curl -fLo "${p_target_path}/${p_target_filename}" "$p_artifact_url"
    l_status=$?
    printf "$g_color_reset"

    if [ $l_status -ne 0 ]; then
        printf 'Artefacto "%b" %bNO se descargó%b en    : "%s/%s" (ERROR %s)\n' "$p_artifact_tag" "$g_color_red1" \
               "$g_color_reset" "$p_target_path" "$p_target_filename" "$l_status"
        return $l_status
    fi

    printf 'Artefacto "%b" descargado en         : "%s/%s"\n' "$p_artifact_tag" "$p_target_path" "$p_target_filename"
    return 0
}

#Parametros de entrada:
# 1> Source path
# 2> Source filename (archivo comprimido)
# 3> Source filetype. El tipo de formato de archivo de comprension
#       > 0 si es un .tar.gz
#       > 1 si es un .zip
#       > 2 si es un .gz
#       > 3 si es un .tgz
#       > 4 si es un .tar.xz
# 4> Target path (ruta donde se desea descomprimir el archivo)
# 5> Flag '0' si se usa sudo. Por defecto es 1 (no se usa sudo) 
#Parametros de salida:
#   > Valor de retorno: 0 si es exitoso
_uncompress_file() {

    local p_source_path="$1"
    local p_source_filename="$2"
    local p_source_filetype=$3
    local p_target_path="$4"
    local p_using_sudo=1
    if [ "$5" = "0" ]; then
        p_using_sudo=0
    fi

    printf 'Descomprimiendo el archivo "%b%s%b" en "%b%s%b"...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" "$g_color_reset" \
           "$g_color_gray1" "$p_target_path" "$g_color_reset"

    # Si el tipo de item es 10 si es un comprimido '.tar.gz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    if [ $p_source_filetype -eq 0 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        printf 'tar -xf "%b%s%b" -C "%b%s%b"\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" "$g_color_reset" \
               "$g_color_gray1" "$p_target_path" "$g_color_reset"

        if [ $p_using_sudo -ne 0 ]; then
            tar -xf "${p_source_path}/${p_source_filename}" -C "$p_target_path"
        else
            sudo tar -xf "${p_source_path}/${p_source_filename}" -C "$p_target_path"
        fi

        rm "${p_source_path}/${p_source_filename}"


    # Si el tipo de item es 11 si es un comprimido '.zip' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_source_filetype -eq 1 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        printf 'unzip -q "%b%s%b" -d "%b%s%b"\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" "$g_color_reset" \
               "$g_color_gray1" "$p_target_path" "$g_color_reset"

        if [ $p_using_sudo -ne 0 ]; then

            unzip -q "${p_source_path}/${p_source_filename}" -d "${p_target_path}"
            rm "${p_source_path}/${p_source_filename}"

            #FIX: Los archivos de themas de 'Oh-my-posh' no tienen permisos para usuarios en WSL
            chmod u+rw ${p_target_path}/*
        else

            sudo unzip -q "${p_source_path}/${p_source_filename}" -d "${p_target_path}"
            rm "${p_source_path}/${p_source_filename}"

            #FIX: Los archivos de themas de 'Oh-my-posh' no tienen permisos para usuarios en WSL
            sudo chmod u+rw ${p_target_path}/*
        fi



    # Si el tipo de item es 12 si es un comprimido '.gz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_source_filetype -eq 2 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes), por defecto elimina el comprimido
        printf 'cd "%b%s%b"\n' "$g_color_gray1" "$p_target_path" "$g_color_reset"
        cd "${p_target_path}"

        printf 'gunzip -q "%b%s%b"\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" "$g_color_reset"

        if [ $p_using_sudo -ne 0 ]; then
            unzip -q "${p_source_path}/${p_source_filename}"
        else
            sudo unzip -q "${p_source_path}/${p_source_filename}"
        fi


    # Si el tipo de item es 13 si es un comprimido '.tgz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_source_filetype -eq 3 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        printf 'tar -xf "%b%s%b" -C "%b%s%b"\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" "$g_color_reset" \
               "$g_color_gray1" "$p_target_path" "$g_color_reset"

        if [ $p_using_sudo -ne 0 ]; then
            tar -xf "${p_source_path}/${p_source_filename}" -C "${p_target_path}"
        else
            sudo tar -xf "${p_source_path}/${p_source_filename}" -C "${p_target_path}"
        fi

        rm "${p_source_path}/${p_source_filename}"


    # Si el tipo de item es 14 si es un comprimido '.tar.xz' no muy pesado (se descomprime en una ruta local y luego se copia a su destino)
    elif [ $p_source_filetype -eq 4 ]; then

        #Descomprimir el archivo en el directorio creado (no crear sub-folderes)
        printf 'tar -xJf "%b%s%b" -C "%b%s%b"\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" "$g_color_reset" \
               "$g_color_gray1" "$p_target_path" "$g_color_reset"

        if [ $p_using_sudo -ne 0 ]; then
            tar -xJf "${p_source_path}/${p_source_filename}" -C "${p_target_path}"
        else
            sudo tar -xJf "${p_source_path}/${p_source_filename}" -C "${p_target_path}"
        fi

        rm "${p_source_path}/${p_source_filename}"


    else
        return 1
    fi

    return 0
}

#Implementa solo 2 modelos:
# - Modelo 1: El archivo comprimido solo contiene el contenido del programa. Esto se descomprime directamente en el subfolder de programa a configurar.
# - Modelo 2: El archivo comprimido contiene un folder y recien dentro de ese folder esta el cotenido del programa. Esto de descomprime el folder programa,
#             y luego si el folder no coindice con el nombre del subfolder del programa este se renombra a este programa.
#Parametros de entrada
#  1> Ruta source, relativa respecto a la temporal, donde esta el archivo comprimido.
#  2> Nombre del archivo source (archivos comprimido ubicado dentro de un folder ruta 1)
#  3> Source filetype. El tipo de formato de archivo de comprension
#       > 0 si es un .tar.gz
#       > 1 si es un .zip
#       > 2 si es un .gz
#       > 3 si es un .tgz
#       > 4 si es un .tar.xz
#  4> Target path type. Tipo de ruta base target donde se descomprime el archivo, puede ser:
#     0 - Un folder del temporal path (NO se requiere permisos adicionales)
#     1 - Un folder del programas de Linux (se requere permisos adicionales)
#     2 - Un folder del programas de Windows (NO se requere permisos adicionales)
#  5> Ruta target, relativa al folder del tipo ruta base target (indicado en parametro 4), donde se descomprime el archivo
#     Puede ser vacio.
#  6> Flag '0' para limpiar la carpeta destino antes descromprimir el contenido. Valor por defecto es '0'.
#  7> El nombre del subfolder del programa (solo es necesario especificarlo solo para el modelo 2).
#  8> Solo se especifica para el modelo 2 y cuando se desea renombrar el folder generado al descromprimir, el cual esta el contenido del programa.
#     Prefijo (parte inicial) del nombre de folder autogenerado por la descomprención y la cual se desea mofidicar.
#     Si es el modelo 2 y no se desea modificar el folder autogenerado enviar vacio.
#Parametros de salida
#   > Valor de retorno: 0 si es exitoso, 1 si hubo un erorr.
uncompress_on_folder() {

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"
    local p_source_filename="$2"
    local p_source_filetype=$3

    local p_target_path_type=0
    if [ "$4" = "1" ]; then
        p_target_path_type=1
    elif [ "$4" = "2" ]; then
        p_target_path_type=2
    fi

    local p_target_path=""
    if [ $p_target_path_type -eq 1 ]; then
        p_target_path="${g_programs_path}"
    elif [ $p_target_path_type -eq 2 ]; then
        p_target_path="${g_win_programs_path}"
    else
        p_target_path="${g_temp_path}"
    fi

    if [ ! -z "$5" ]; then
        p_target_path="${p_target_path}/$5"
    fi

    local p_flag_clean=0
    if [ "$6" = "1" ]; then
        p_flag_clean=1
    fi

    local p_foldername="$7"

    local p_foldername_searchprefix=""
    if [ -z "$p_foldername" ]; then
        p_foldername_searchprefix=''
        p_foldername=''
    else
        p_foldername_searchprefix="$8"
    fi

    #El modelo 1 tiene que descromprimirse en una subcarpete del directorio programas.
    if [ -z "$p_foldername" ] && [ -z "$5" ]; then
        return 2
    fi

    #g_filename_without_ext=$(get_filename_withoutextension "$p_source_filename" $p_source_filetype)

    #2. Si el destino es una carpeta del temporal o de programa de Windows (no verificar los permisos)
    local l_current_fullfoldername=''
    if [ $p_target_path_type -eq 0 ] || [ $p_target_path_type -eq 2 ]; then

        #A. Limpieza del contenido del programa si este existe

        #Si es modelo 1 (el contenido del programa esta directamente en el folder destino), eliminar el contenido del folder destino
        if [ -z "$p_foldername" ]; then

            #Si el comprimido esta en el mismo lugar que el folder a limpiar, no hacer limpieza
            if [ ! -z "$5" ] && [ -d "$p_target_path" ] && [ "$p_target_path" != "$p_source_path" ] && [ $p_flag_clean -eq 0 ]; then

                printf 'Eliminando el folder "%b%s%b" y todo su contenido ...\n' "$g_color_gray1" "$p_target_path" "$g_color_reset"
                rm -rf "${p_target_path}"

                printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$p_target_path" "$g_color_reset"
                mkdir -pm 755 "${p_target_path}"

            fi

        #Si el modelo 2 (el contenido del programa esta en un subfolder generado en la descomprención), eliminar el contenido del folder destino
        else

            #Si el comprimido esta en el mismo lugar que el folder a limpiar, no hacer limpieza
            if [ -d "${p_target_path}/${p_foldername}" ] && [ "${p_target_path}/${p_foldername}" != "$p_source_path" ] && [ $p_flag_clean -eq 0 ]; then

                printf 'Eliminando el subfolder "%b%s%b" y todo su contenido ...\n' "$g_color_gray1" "${p_target_path}/${p_foldername}" \
                       "$g_color_reset"
                rm -rf ${p_target_path}/${p_foldername}

            fi
        fi


        #B. Descomprimir
        _uncompress_file "$p_source_path" "$p_source_filename" $p_source_filetype "$p_target_path" 1

        #C. Si es modelo 1 (el contenido del programa esta directamente en el folder destino), salir.
        if [ -z "$p_foldername" ]; then
            return 0
        fi

        #D. Si el modelo 2 (el contenido del programa esta en un subfolder generado en la descomprención), renombrar el folder generado

        #Si se debe buscar y renombrar el folder autogenerado por la descomprención:
        if [ ! -z "$p_foldername_searchprefix" ]; then

            #Obteniendo el nombre de la carpeta que genero al descromprimir y coincide con el criterio indicado.
            l_current_fullfoldername=$(find "$p_target_path" -maxdepth 1 -mindepth 1 -type d -name "$p_foldername_searchprefix"'*' 2> /dev/null | head -n 1)
            if [ -z "$l_current_fullfoldername" ]; then

                printf 'El archivo "%b%s%b", descomprimido en "%b%s%b", %bNO genero la ninguna carpeta que inicie con "%b%s%b" en este folder.%b\n' \
                     "$g_color_gray1" "$p_source_filename" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" \
                     "$g_color_red1" "$g_color_gray1" "$p_foldername_searchprefix" "$g_color_red1" "$g_color_reset"

                return 1
            fi

            #Renombrando la carpeta obtenido
            if [ "$l_current_fullfoldername" != "${p_target_path}/${p_foldername}" ]; then

                printf 'El archivo "%b%s%b", descomprimido en "%b%s%b", genero el folder "%b%s%b" el cual se renombra a "%b%s%b"...\n' \
                       "$g_color_gray1" "$p_source_filename" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" \
                       "$g_color_gray1" "$l_current_fullfoldername" "$g_color_reset" "$g_color_gray1" "$p_foldername" "$g_color_reset"

                mv "$l_current_fullfoldername" "${p_target_path}/${p_foldername}"

            fi

        else

            #Deberia autogenerarse el subfolder durante la descomprención
            if [ ! -d "${p_target_path}/${p_foldername}" ]; then

                printf 'El archivo "%b%s%b", descomprimido en "%b%s%b", %bNO genero la ninguna subcarpeta "%b%s%b" en este folder.%b\n' \
                     "$g_color_gray1" "$p_source_filename" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" \
                     "$g_color_red1" "$g_color_gray1" "$p_foldername" "$g_color_red1" "$g_color_reset"

                return 1
            fi

        fi


        return 0

    fi


    #3. Si el destino es el programa de Linux 
    local l_runner_is_program_owner=1
    if [ $(( g_prg_path_options & 1 )) -eq 1 ]; then
        l_runner_is_program_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then
        

        #A. Limpieza del contenido del programa si este existe

        #Si es modelo 1 (el contenido del programa esta directamente en el folder destino), eliminar el contenido del folder destino
        if [ -z "$p_foldername" ]; then

            #Si el comprimido esta en el mismo lugar que el folder a limpiar, no hacer limpieza
            if [ ! -z "$5" ] && [ -d "$p_target_path" ] && [ "$p_target_path" != "$p_source_path" ] && [ $p_flag_clean -eq 0 ]; then

                printf 'Eliminando el folder "%b%s%b" y todo su contenido ...\n' "$g_color_gray1" "$p_target_path" "$g_color_reset"
                rm -rf "${p_target_path}"

                printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$p_target_path" "$g_color_reset"
                mkdir -pm 755 "${p_target_path}"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_command_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}"
                fi

            fi

        #Si el modelo 2 (el contenido del programa esta en un subfolder generado en la descomprención), eliminar el contenido del folder destino
        else

            #Si el comprimido esta en el mismo lugar que el folder a limpiar, no hacer limpieza
            if [ -d "${p_target_path}/${p_foldername}" ] && [ "${p_target_path}/${p_foldername}" != "$p_source_path" ] && [ $p_flag_clean -eq 0 ]; then

                printf 'Eliminando el subfolder "%b%s%b" y todo su contenido ...\n' "$g_color_gray1" "${p_target_path}/${p_foldername}" \
                       "$g_color_reset"
                rm -rf ${p_target_path}/${p_foldername}

            fi
        fi


        #B. Descomprimir
        _uncompress_file "$p_source_path" "$p_source_filename" $p_source_filetype "$p_target_path" 1

        #C. Si es modelo 1 (el contenido del programa esta directamente en el folder destino), establecer permisos en caso de requierlo
        if [ -z "$p_foldername" ]; then

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
                chown -R "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}"
            fi

            return 0

        fi

        #D. Si el modelo 2 (el contenido del programa esta en un subfolder generado en la descomprención), renombrar el folder generado y establecer los persmisos

        #Si se debe buscar y renombrar el folder autogenerado por la descomprención:
        if [ ! -z "$p_foldername_searchprefix" ]; then

            #Obteniendo el nombre de la carpeta que genero al descromprimir y coincide con el criterio indicado.
            l_current_fullfoldername=$(find "$p_target_path" -maxdepth 1 -mindepth 1 -type d -name "$p_foldername_searchprefix"'*' 2> /dev/null | head -n 1)
            if [ -z "$l_current_fullfoldername" ]; then

                printf 'El archivo "%b%s%b", descomprimido en "%b%s%b", %bNO genero la ninguna carpeta que inicie con "%b%s%b" en este folder.%b\n' \
                     "$g_color_gray1" "$p_source_filename" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" \
                     "$g_color_red1" "$g_color_gray1" "$p_foldername_searchprefix" "$g_color_red1" "$g_color_reset"

                return 1
            fi

            #Renombrando la carpeta obtenido
            if [ "$l_current_fullfoldername" != "${p_target_path}/${p_foldername}" ]; then

                printf 'El archivo "%b%s%b", descomprimido en "%b%s%b", genero el folder "%b%s%b" el cual se renombra a "%b%s%b"...\n' \
                       "$g_color_gray1" "$p_source_filename" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" \
                       "$g_color_gray1" "$l_current_fullfoldername" "$g_color_reset" "$g_color_gray1" "$p_foldername" "$g_color_reset"

                mv "$l_current_fullfoldername" "${p_target_path}/${p_foldername}"

            fi

        else

            #Deberia autogenerarse el subfolder durante la descomprención
            if [ ! -d "${p_target_path}/${p_foldername}" ]; then

                printf 'El archivo "%b%s%b", descomprimido en "%b%s%b", %bNO genero la ninguna subcarpeta "%b%s%b" en este folder.%b\n' \
                     "$g_color_gray1" "$p_source_filename" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" \
                     "$g_color_red1" "$g_color_gray1" "$p_foldername" "$g_color_red1" "$g_color_reset"

                return 1
            fi

        fi

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
            chown -R "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}/${p_foldername}"
        fi

        return 0

    fi

 
    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.


    #A. Limpieza del contenido del programa si este existe

    #Si es modelo 1 (el contenido del programa esta directamente en el folder destino), eliminar el contenido del folder destino
    if [ -z "$p_foldername" ]; then

        #Si el comprimido esta en el mismo lugar que el folder a limpiar, no hacer limpieza
        if [ ! -z "$5" ] && [ -d "$p_target_path" ] && [ "$p_target_path" != "$p_source_path" ] && [ $p_flag_clean -eq 0 ]; then

            printf 'Eliminando el folder "%b%s%b" y todo su contenido ...\n' "$g_color_gray1" "$p_target_path" "$g_color_reset"
            sudo rm -rf "${p_target_path}"

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$p_target_path" "$g_color_reset"
            sudo mkdir -pm 755 "${p_target_path}"

        fi

    #Si el modelo 2 (el contenido del programa esta en un subfolder generado en la descomprención), eliminar el contenido del folder destino
    else

        #Si el comprimido esta en el mismo lugar que el folder a limpiar, no hacer limpieza
        if [ -d "${p_target_path}/${p_foldername}" ] && [ "${p_target_path}/${p_foldername}" != "$p_source_path" ] && [ $p_flag_clean -eq 0 ]; then

            printf 'Eliminando el subfolder "%b%s%b" y todo su contenido ...\n' "$g_color_gray1" "${p_target_path}/${p_foldername}" \
                   "$g_color_reset"
            sudo rm -rf ${p_target_path}/${p_foldername}

        fi
    fi


    #B. Descomprimir
    _uncompress_file "$p_source_path" "$p_source_filename" $p_source_filetype "$p_target_path" 0

    #C. Si es modelo 1 (el contenido del programa esta directamente en el folder destino), salir 
    if [ -z "$p_foldername" ]; then
        return 0
    fi

    #D. Si el modelo 2 (el contenido del programa esta en un subfolder generado en la descomprención), renombrar el folder generado

    #Si se debe buscar y renombrar el folder autogenerado por la descomprención:
    if [ ! -z "$p_foldername_searchprefix" ]; then

        #Obteniendo el nombre de la carpeta que genero al descromprimir y coincide con el criterio indicado.
        l_current_fullfoldername=$(sudo find "$p_target_path" -maxdepth 1 -mindepth 1 -type d -name "$p_foldername_searchprefix"'*' 2> /dev/null | head -n 1)
        if [ -z "$l_current_fullfoldername" ]; then

            printf 'El archivo "%b%s%b", descomprimido en "%b%s%b", %bNO genero la ninguna carpeta que inicie con "%b%s%b" en este folder.%b\n' \
                 "$g_color_gray1" "$p_source_filename" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" \
                 "$g_color_red1" "$g_color_gray1" "$p_foldername_searchprefix" "$g_color_red1" "$g_color_reset"

            return 1
        fi

        #Renombrando la carpeta obtenido
        if [ "$l_current_fullfoldername" != "${p_target_path}/${p_foldername}" ]; then

            printf 'El archivo "%b%s%b", descomprimido en "%b%s%b", genero el folder "%b%s%b" el cual se renombra a "%b%s%b"...\n' \
                   "$g_color_gray1" "$p_source_filename" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" \
                   "$g_color_gray1" "$l_current_fullfoldername" "$g_color_reset" "$g_color_gray1" "$p_foldername" "$g_color_reset"

            sudo mv "$l_current_fullfoldername" "${p_target_path}/${p_foldername}"

        fi

    else

        #Deberia autogenerarse el subfolder durante la descomprención
        if [ ! -d "${p_target_path}/${p_foldername}" ]; then

            printf 'El archivo "%b%s%b", descomprimido en "%b%s%b", %bNO genero la ninguna subcarpeta "%b%s%b" en este folder.%b\n' \
                 "$g_color_gray1" "$p_source_filename" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" \
                 "$g_color_red1" "$g_color_gray1" "$p_foldername" "$g_color_red1" "$g_color_reset"

            return 1
        fi

    fi



    return 0

}


#Parametros de entrada
#  1> Ruta source, relativa respecto a la temporal, donde esta el archivo comprimido.
#  2> Target path type. Tipo de ruta base target donde se descomprime el archivo, puede ser:
#     0 - Un folder del programas de Linux (se requere permisos adicionales)
#     1 - Un folder del programas de Windows (NO se requere permisos adicionales)
#  3> Ruta target, relativa al folder del tipo ruta base target (indicado en parametro 3), donde se descomprime el archivo
#     No puede ser vacio.
#Parametros de salida
#   > Valor de retorno: 0 si es exitoso, 1 si hubo un erorr.
syncronize_folders() {

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"

    local p_target_path_type=0
    if [ "$2" = "1" ]; then
        p_target_path_type=1
    fi

    local p_target_path="${g_programs_path}/$3"
    if [ $p_target_path_type -eq 1 ]; then
        p_target_path="${g_win_programs_path}/$3"
    fi

    #Requiere que 'rsync' este instalado
    if ! rsync --version 2> /dev/null 1>&2; then
        printf 'El %bcomando "%brsync%b" no esta instalado%b. Este comando es requerido para la actualización instalación del repositorio.\n' \
               "$g_color_red1" "$g_color_reset" "$g_color_red1" "$g_color_reset" 
        return 1
    fi

    printf 'Sincronizar el source "%b%s%b" con el target "%b%s%b"...\n' \
           "$g_color_gray1" "$p_source_path" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" 

    #2. Si el destino es una caepeta del temporal o de programa de Windows (no verificar los permisos)
    local l_aux=''
    if [ $p_target_path_type -eq 1 ]; then

        #Sincronizar (copiar y remplazar los archivos modificados sin advertencia interactiva)
        printf 'Ejecutando "%brsync -a --stats %s/ %s%b"...\n' "$g_color_gray1" "$p_source_path" "$p_target_path" "$g_color_reset"
        printf '%b' "$g_color_gray1"
        rsync -a --stats "${p_source_path}/" "${p_target_path}"
        printf '%b' "$g_color_reset"

        return 0

    fi


    #3. Si el destino es el programa de Linux 
    local l_runner_is_program_owner=1
    if [ $(( g_prg_path_options & 1 )) -eq 1 ]; then
        l_runner_is_program_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then
            
        printf 'Ejecutando "%brsync -a --stats %s/ %s%b"...\n' "$g_color_gray1" "$p_source_path" "$p_target_path" "$g_color_reset"
        printf '%b' "$g_color_gray1"
        rsync -a --stats "${p_source_path}/" "${p_target_path}"
        printf '%b' "$g_color_reset"
                                         
        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
             chown -R "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}"
        fi

        return 0

    fi

 
    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.
            
    printf 'Ejecutando "%bsudo rsync -a --stats %s/ %s%b"...\n' "$g_color_gray1" "$p_source_path" "$p_target_path" "$g_color_reset"
    printf '%b' "$g_color_gray1"
    sudo rsync -a --stats "${p_source_path}/" "${p_target_path}"
    printf '%b' "$g_color_reset"
                                         
    return 0

}


#Usando un script del instalacion/actualizacion del folder de temporales, instala programas en Linux.
#Parametros de entrada
#  1> Ruta source, relativa respecto a la temporal, donde esta el archivo comprimido.
#  2> Nombre del script de instalacion/actualización (ubicado dentro del folder del parametro 1)
#  3> Ruta target, relativa al folder del programa, donde se descomprime el archivo. No puede ser vacio.
#  4> Nombre de la opcion que indica la ruta relativa con el '-' o '--'  al inicio y el '=' o ' ' al final. 
#     Si la ruta relativa se envia como argumento y no incluye una opcion, colocar vacio.
#     Ejemplo: '--path ', '--path=', ''
#  5> Argumentos y opciones adicionales del script
#Parametros de salida
#   > Valor de retorno: 0 si es exitoso, 1 si hubo un erorr.
exec_setupscript_to_program() {

    #1. Argumentos
    local p_script_path="${g_temp_path}/$1"
    local p_script_name="$2"


    local p_target_path="${g_programs_path}/$3"
    local p_script_targetoption="$4"
    local p_script_otheroptions="$5"

    #3. Inicialización 
    local l_runner_is_program_owner=1
    if [ $(( g_prg_path_options & 1 )) -eq 1 ]; then
        l_runner_is_program_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    local l_status=0
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_program_owner -eq 0 ]; then
    
        if [ ! -f "${p_script_path}/${p_script_name}" ]; then
            printf 'Error en la configuración. %bNo existe el script "%s%s%b" de setup para el programa.%b\n' \
                   "$g_color_red1" "$g_color_gray1" "${p_script_path}/${p_script_name}" "$g_color_red1" "$g_color_reset"
            return 1

        fi

        #Ejecutando el setup script
        printf 'Ejecutando el script '"'"'%b%s%b/%s %b%s"%s" %s%b'"'"'...\n' "$g_color_gray1" "$p_script_path" "$g_color_reset" "$p_script_name" \
               "$g_color_gray1" "$p_script_targetoption" "$p_target_path" "$p_script_otheroptions" "$g_color_reset" 
        chmod u+x "${p_script_path}/${p_script_name}"
        ${p_script_path}/${p_script_name} $p_script_targetoption"$p_target_path" $p_script_otheroptions
        l_status=$?

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo. 
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_program_owner -eq 0 ]; then
             chown -R "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}"
        fi

        if [ $l_status -ne 0 ]; then
            return 1
        fi
        return 0

    fi

 
    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.
            
    if [ ! -f "${p_script_path}/${p_script_name}" ]; then
        printf 'Error en la configuración. %bNo existe el script "%s%s%b" de setup para el programa.%b\n' \
               "$g_color_red1" "$g_color_gray1" "${p_script_path}/${p_script_name}" "$g_color_red1" "$g_color_reset"
        return 1

    fi

    #Ejecutando el setup script
    printf 'Ejecutando el script '"'"'sudo bash %b%s%b/%s %b%s"%s" %s%b'"'"'...\n' "$g_color_gray1" "$p_script_path" "$g_color_reset" "$p_script_name" \
           "$g_color_gray1" "$p_script_targetoption" "$p_target_path" "$p_script_otheroptions" "$g_color_reset" 
    chmod u+x "${p_script_path}/${p_script_name}"
    sudo bash ${p_script_path}/${p_script_name} $p_script_targetoption"$p_target_path" $p_script_otheroptions
    l_status=$?
                                         
    if [ $l_status -ne 0 ]; then
        return 1
    fi
    return 0

}



#Registrara la libreria de un programa a nivel sistema si este tiene permiso y los programas estan fuera
#del home del usuario objetivo. Caso contrario, solo mostrara una advertencia registre la ruta usando la 
#variable de entorno 'LD_LIBRARY_PATH'
#Parametros de entrada> Argumentos:
#  01> Ruta, relativa a los programas de Linux, donde esta librerias dinamicas que se desea registrar.
#  02> Nombre del archivo .config que se creara en "/etc/ld.so.conf.d/"
#Parametros de salida > Valor de retorno:
#  0 - Se registro a nivel sistema sin problemas.
#  1 - No puede registrar a nivel sistema, debe registrar a nivel usuario.
#  2 - Ocurrio un error al registrar la ruta de librerias.
function register_dynamiclibrary_to_system()
{

    #1. Argumentos
    local p_library_path="${g_programs_path}/$1"
    local p_config_filename=$2

    #2. Inicializaciones

    #Si no existe las carpetas de librerias
    if [ ! -d "$p_library_path" ]; then

        printf '%bNo existe folder "%b%s%b" de librerias dinamica a registar.%b\n' "$g_color_red1" "$g_color_gray1" "$p_library_path" \
               "$g_color_red1" "$g_color_reset" 
        return 2

    fi

    #Si los programas estan dentro del home del usuario objetivo, solo se debe usar variables de entorno 'LD_LIBRARY_PATH'
    if [ $(( g_prg_path_options & 4 )) -eq 4 ]; then

        printf 'No debe registrar su libreria dinamicas a nivel sistema, debe %bregistrarlo a nivel usuario usando la variable "%b%s%b" de entorno:%b\n' \
               "$g_color_yellow1" "$g_color_gray1" "LD_LIBRARY_PATH" "$g_color_yellow1" "$g_color_reset"
        printf "     %bexport LD_LIBRARY_PATH=\"%s:\${LD_LIBRARY_PATH}\"%b\n" "$g_color_gray1" "$p_library_path" "$g_color_reset"

        return 1

    fi


    #Registrando la liberias a nivel sistema: require uso de sudo o root:

    #Se rechazar el folder ingresado, si el usuario runner no tiene permisos para ejecutar como root
    # - El sistema operativo no soporte sudo y el usuario ejecutor no es root.
    # - El sistema operativo soporta sudo y el usario ejecutor no es root y no tiene permiso para sudo.
    if [ $g_runner_sudo_support -eq 3 ] || [ $g_runner_id -ne 0 -a  $g_runner_sudo_support -eq 2 ]; then
        printf '%bNo se tiene permisos para registrar sus liberias dinamicas "%b%s%b" a nivel sistema.%b\n' "$g_color_red1" "$g_color_gray1" \
               "$p_library_path" "$g_color_red1" "$g_color_reset" 
        return 2
    fi

    if [ ! -d "/etc/ld.so.conf.d/" ]; then
        printf '%bNo se encuentra el folder "%b%s%b" requerido para registrar sus librerias a nivel sistema.%b\n' "$g_color_red1" "$g_color_gray1" \
               "/etc/ld.so.conf.d/" "$g_color_red1" "$g_color_reset" 
        return 2

    fi

    #Registrar la ruta de librerias en forma permanente
    if [ $g_runner_id -eq 0 ]; then 

        printf 'Registrar sus librerias dinamicas en forma permanente: "%becho "%s" > /etc/ld.so.conf.d/%s.conf%b" ...\n' \
               "$g_color_gray1" "${p_library_path}" "$p_config_filename" "$g_color_reset"
        echo "$p_library_path}" > /etc/ld.so.conf.d/${p_config_filename}.conf

    else

        printf 'Registrar sus librerias dinamicas en forma permanente: "%bsudo bash -c "echo '"'"'%s'"'"'> /etc/ld.so.conf.d/%s.conf"%b" ...\n' \
               "$g_color_gray1" "${p_library_path}" "$p_config_filename" "$g_color_reset"
        sudo bash -c "echo '${p_library_path}' > /etc/ld.so.conf.d/${p_config_filename}.conf"

    fi

    #Actualizar el cache de librerias
    if [ $g_runner_id -eq 0 ]; then 
        printf 'Actualizar el cache de las librerias: "%bldconfig%b" ...\n' "$g_color_gray1" "$g_color_reset"
        ldconfig
    else
        printf 'Actualizar el cache de las librerias: "%bsudo ldconfig%b" ...\n' "$g_color_gray1" "$g_color_reset"
        sudo ldconfig
    fi

    return 0

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
    printf "%bEl nodo k0s '%s' (PID: %s) esta iniciado y requiere detenerse para " "$g_color_red1" "$l_nodo_type" "$l_node_process_id"

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


    printf "¿Desea detener el nodo k0s?%b (ingrese 's' para 'si' y 'n' para 'no')%b [s]" "$g_color_gray1" "$g_color_reset"
    read -rei 's' -p ': ' l_option
    if [ "$l_option" != "s" ]; then

        if [ $p_is_uninstalling -eq 0 ]; then
            printf '%bNo se desinstalará ' "$g_color_gray1"
        else
            printf '%bNo se instalará ' "$g_color_gray1"
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
    if [ $g_runner_id -eq 0 ]; then
        k0s stop
    else
        sudo k0s stop
    fi
    return 2
}


