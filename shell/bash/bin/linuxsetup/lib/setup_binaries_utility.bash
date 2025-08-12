#!/bin/bash


#Funciones de Utilidad {{{


g_usage() {

    printf 'Usage:\n'
    printf '  > %bDesintalar repositorios mostrando el menú de opciones%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash uninstall\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash uninstall TARGET_HOME_PATH REPO_NAME MY_TOOLS_PATH LNX_BASE_PATH TEMP_PATH\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '  > %bInstalar repositorios mostrando el menú de opciones (interactivo)%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash 0\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash 0 TARGET_HOME_PATH REPO_NAME MY_TOOLS_PATH LNX_BASE_PATH TEMP_PATH SETUP_ONLYLAST_VERSION\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un grupo de repositorios sin mostrar el menú y usando los ID del menu%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE MENU_OPTIONS\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE MENU_OPTIONS TARGET_HOME_PATH REPO_NAME MY_TOOLS_PATH LNX_BASE_PATH TEMP_PATH SUDO_STORAGE_OPTIONS\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE MENU_OPTIONS TARGET_HOME_PATH REPO_NAME MY_TOOLS_PATH LNX_BASE_PATH TEMP_PATH SUDO_STORAGE_OPTIONS SETUP_ONLYLAST_VERSION\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %bDonde:%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    > %bCALLING_TYPE%b (para este escenario) es 1 si es interactivo, 3 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un repositorio sin mostrar el  menú y usando los ID de los repositorios%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE LIST_REPO_ID%b\n' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE LIST_REPO_ID TARGET_HOME_PATH REPO_NAME MY_TOOLS_PATH LNX_BASE_PATH TEMP_PATH SUDO_STORAGE_OPTIONS%b\n' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/01_setup_binaries.bash CALLING_TYPE LIST_REPO_ID TARGET_HOME_PATH REPO_NAME MY_TOOLS_PATH LNX_BASE_PATH TEMP_PATH SUDO_STORAGE_OPTIONS SETUP_ONLYLAST_VERSION SHOW_TITLE_1REPO FLAG_FILTER_PRGS%b\n' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %bDonde:%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    > %bCALLING_TYPE%b (para este escenario) es 2 si es interactivo y 4 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    > %bLIST_REPO_ID%b lista de ID repositorios separados por coma. Si no %b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    > %bSHOW_TITLE_1REPO%b Es 0, si muestra el titulo cuando solo se instala 1 repositorio. Por defecto es 1.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    > %bFLAG_FILTER_PRGS%b indica el filtro de programas en LIST_REPO_ID. Si es 0 solo se considera programas de usuarios, Si es 1 considera todos excepto los programas del usuario, otro valor no se realiza filtro.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '\nDonde:\n'
    printf '  > %bTARGET_HOME_PATH %bRuta base donde el home del usuario OBJETIVO al cual se configurara su profile y donde esta el repositorio git. Este valor se obtendra segun orden prioridad:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio "g_repo_name".%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bREPO_NAME %bNombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario. Este valor se obtendra segun orden prioridad:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Si ninguno de los anteriores se establece, se usara el valor ".files".%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bMY_TOOLS_PATH %bes la ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY, se usara su valor se buscara segun orden prioridad en: lo indicado en el "./linuxsetup/.setup_config.bash", "/var/opt/tools" o "~/tools".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bLNX_BASE_PATH %bes ruta base donde se almacena los comandos ("LNX_BASE_PATH/bin"), archivos man1 ("LNX_BASE_PATH/man/man1") y fonts ("LNX_BASE_PATH/share/fonts"). Si se envia vacio o EMPTY se usara segun orden de prioridad:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %b> Lo indicado en el archivo de configuración: "./linuxsetup/.setup_config.bash"%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    %b> Rutas predeterminados:%b\n' "$g_color_gray1" "$g_color_reset"
    printf '      %b> Comandos      : "/usr/local/bin"            (todos los usuarios) y "~/.local/bin"            (solo el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '      %b> Archivos man1 : "/usr/local/share/man/man1" (todos los usuarios) y "~/.local/share/man/man1" (solo el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '      %b> Archivo fuente: "/usr/local/share/fonts"    (todos los usuarios) y "~/.local/share/fonts"    (solo el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bTEMP_PATH %bes la ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado "/tmp".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bSUDO_STORAGE_OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
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


#Devulve la version ingresada y 2 versiones menores a la ingresada separados por ' '
#Parametros de salida:
#  > Valor de retorno:
#    0 - OK
#    1 - No OK
#  > STDOUT: La version ingresada y 2 versiones menores encontradas, separadas por ' '
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
    local p_is_win_binary=1          #(0) Los binarios de los repositorios se estan instalando en el Windows asociado al WSL2
                                        #(1) Los binarios de los comandos se estan instalando en Linux
    if [ "$3" = "0" ]; then
        p_is_win_binary=0
    fi

    #Calcular la ruta de archivo/comando donde se obtiene la version
    local l_path_file=""
    if [ $p_is_win_binary -eq 0 ]; then
       l_path_file="${g_win_tools_path}/DotNet"
    else
       l_path_file="${g_tools_path}/dotnet"
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
    if [ $p_is_win_binary -eq 0 ]; then
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


#La funcion considerara la ruta de un folder como: "program_path/PATH_THAT_MUST_EXIST/PATH_THAT_MAYNOT_EXIST", donde
#  > 'PATH_THAT_MUST_EXIST' es parte de la ruta del folder que debe existir y tener permisos de escritura, si no lo esta, arroajara el error 2.
#  > 'PATH_THAT_MAYNOT_EXIST' es la parte de la ruta del folder que puede o no existir, por lo que requiere ser creada.
#  > No se altero el permiso de los folderes existentes, solo de los nuevos a crear.
#Parametros de entrada> Argumentos y opciones
#  1> Si es programa de window usar 1. Caso contrario es Linux (0)
#  2> Ruta 'PATH_THAT_MUST_EXIST', relativa al folder tools, que debera existir.
#  3> Ruta 'PATH_THAT_MAYNOT_EXIST', relativa al folder tools, que pueda que no exista por lo que se intentara crearlo.
#     Para establecer los permisos correctos, se recomienda que el folder padra existe con el permiso correcto.
#Parametros de entrada> Variables globales
# - 'g_tools_path', 'g_win_tools_path', 'g_runner_user', 'g_targethome_owner', 'g_targethome_group'
#Parametos de salida> Valor de retorno
#  0> Se creo todo o parte de los subfolderes de la ruta indicada con exito.
#  1> El folder ya existe y no se creo ningun folder.
#  2> NOOK: El folder que debe existir no existe o no se tiene permisos de escritura.
#  3> NOOK: Error en la creacion del folder.
function create_folderpath_on_tools() {

    local p_is_lnx_file=0  #Es linux
    if [ "$1" = "1" ]; then
        p_is_lnx_file=1 #Es windows
    fi

    local p_folderpath_must_exist="$2"
    local p_folderpath_maynot_exist="$3"

    #2. Inicializaciones

    #3. Validar que la ruta que debe existir existe y tener permisos de escritura
    local l_target_base_path="${g_tools_path}"
    if [ $p_is_lnx_file -ne 0 ]; then
        l_target_base_path="${g_win_tools_path}"
    fi


    if [ ! -z "$p_folderpath_must_exist" ]; then

        l_target_base_path="${l_target_base_path}/${p_folderpath_must_exist}"
        if [ ! -d "$l_target_base_path" ] || [ ! -w "$l_target_base_path" ]; then
            return 2
        fi
    fi

    if [ -z "$p_folderpath_maynot_exist" ]; then
        return 0
    fi

    #4. Creando los folderes del ruta que no puede existir
    local IFS='/'
    la_foldernames=($p_folderpath_maynot_exist)
    local l_n=${#la_foldernames[@]}

    local l_runner_is_tools_owner=1
    if [ $p_is_lnx_file -eq 0 ] && [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    local l_i=0
    local l_folder_created=0
    local l_foldername=""

    local l_folder_path="$l_target_base_path"
    for(( l_i=0; l_i < ${l_n}; l_i++ )); do

        #Obtener el folder
        l_foldername="${la_foldernames[${l_i}]}"
        if [ -z "$l_foldername" ]; then
            continue
        fi
        l_folder_path="${l_folder_path}/${l_foldername}"

        #Si el folder existe, no hacer nada continuar con el sigueinte de la ruta
        if [ -d "$l_folder_path" ]; then
            continue
        fi

        #Si no existe crearlo con los permisos deseados:
        l_folder_created=$((l_folder_created + 1))
        printf 'Creando la carpeta "%b%s%b"...\n' "$g_color_gray1" "${l_folder_path}" \
               "$g_color_reset"

        if [ $p_is_lnx_file -ne 0 ]; then
            mkdir -pm 755 "$l_folder_path"
        else

            # Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
            if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

                mkdir -pm 755 "$l_folder_path"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${l_folder_path}"
                fi

            # Si el usuario runner solo puede realizar la instalación usando sudo para root.
            else

                sudo mkdir -pm 755 "$l_folder_path"
                sudo chown "${g_targethome_owner}:${g_targethome_group}" "${l_folder_path}"

            fi
        fi

    done

    if [ $l_folder_created -eq 0 ]; then
        return 1
    fi
    return 0

}



#Crea folderes de programa si no existen y si existen puede limpiar el contenido de esos folderes
#Parametros de entrada> Argumentos:
#  1> Tipo de target.
#     0 - Si es un subfolder de programas esta en Linux (puede requerir permisos)
#     1 - Si es un subfolder de programas esta en Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#  2> Ruta relativo del subfolder de programa
#     No puede ser vacio (un programa siempre se almacena dentro de un subfolder dentro de la ruta base de programas)
#  3> Tipo de operacion de limpieza (si el subfolder existe). Valor por defecto es 0
#     0 - No realizar ninguna limpieza (no eliminar ningun contenido del subfolder)
#     1 - Eliminar todos los archivos existentes antes del copiado
#     2 - Eliminar todo el subfolder y crearlo nuevamente antes del copiado
#     3 - Renombrar la carpeta con el nombre indicado en el paremetro 5
#  4> Solo si el parametro 4 es 3. Sufijo adicionar a la nombre del subfolder existenten
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function create_or_clean_folder_on_tools()
{

    #1. Argumentos
    local p_is_lnx_file=0
    if [ "$1" = "1" ]; then
        p_is_lnx_file=1
    fi

    if [ -z "$2" ]; then
        printf 'Error: %bla ruta retativa del folder del programa a crear/limpiar debe especificarse%b.\n' "$g_color_red1" "$g_color_reset"
        return 1
    fi
    local p_program_subfolder="$2"


    local p_clean_type=0
    if [ "$3" = "1" ]; then
        p_clean_type=1
    elif [ "$3" = "2" ]; then
        p_clean_type=2
    elif [ "$3" = "3" ]; then
        p_clean_type=3
    fi

    local p_sufix_subfolder="$4"

    #2. Si no existe las folder crearlo
    local l_target_path=''
    local l_status=0

    if [ $p_is_lnx_file -eq 0 ]; then
        l_target_path="${g_tools_path}/${p_program_subfolder}"
    else
        l_target_path="${g_win_tools_path}/${p_program_subfolder}"
    fi

    if [ ! -d "$l_target_path" ]; then
        create_folderpath_on_tools $p_is_lnx_file "" "$p_program_subfolder"
        l_status=$?

        if [ $l_status -ne 0 ]; then
            printf 'Error: %bno se ha podido crear con exito la ruta retativa "%b%s%b" del folder del programa%b.\n' "$g_color_red1" \
                   "$g_color_gray1" "$p_program_subfolder" "$g_color_red1" "$g_color_reset"
            return 1
        fi
        return 0
    fi

    #3. Si existe el folder, limpiarlo (segun lo especificado)

    #3.1. Si son programas Windows
    if [ $p_is_lnx_file -eq 1 ]; then


        #Validar si se requiere realizar limpieza antes del copiado
        if [ $p_clean_type -eq 1 ]; then

            printf 'Eliminando el contenido del folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            rm -rf ${l_target_path}/*

        elif [ $p_clean_type -eq 2 ]; then

            printf 'Eliminado todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            rm -rf ${l_target_path}/
            mkdir -pm 755 "${l_target_path}"

        elif [ $p_clean_type -eq 3 ]; then

            if [ -d "${l_target_path}${p_sufix_subfolder}" ]; then

                #Si el folder existe se intentara mover la carpeta dentro de otro la cual no es el comportamiento deseado
                printf 'Error: %bse intenta renombrar el folder %b"%b%s%b"%b pero el folder %b"%b%s%b"%b ya existe%b.\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$l_target_path" "$g_color_reset" "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset" "$g_color_red1" "$g_color_reset"

                #return 1

                printf 'Eliminado todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                rm -rf ${l_target_path}/
                mkdir -pm 755 "${l_target_path}"

            else
                printf 'Renombrando el folder "%b%s%b" a "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset" \
                       "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset"
                mv "$l_target_path" "${l_target_path}${p_sufix_subfolder}"
            fi

        fi

        return 0

    fi


    #3.2 Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

        #Validar si se requiere realizar limpieza antes del copiado
        if [ $p_clean_type -eq 1 ]; then

            printf 'Eliminando el contenido del folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            rm -rf ${l_target_path}/*

        elif [ $p_clean_type -eq 2 ]; then

            printf 'Eliminado todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            rm -rf ${l_target_path}/
            mkdir -pm 755 "${l_target_path}"

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
            fi

        elif [ $p_clean_type -eq 3 ]; then

            if [ -d "${l_target_path}${p_sufix_subfolder}" ]; then

                #Si el folder existe se intentara mover la carpeta dentro de otro la cual no es el comportamiento deseado
                printf 'Error: %bse intenta renombrar el folder %b"%b%s%b"%b pero el folder %b"%b%s%b"%b ya existe%b.\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$l_target_path" "$g_color_reset" "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset" "$g_color_red1" "$g_color_reset"

                #return 1

                printf 'Eliminado todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                rm -rf ${l_target_path}/
                mkdir -pm 755 "${l_target_path}"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
                fi

            else
                printf 'Renombrando el folder "%b%s%b" a "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset" \
                       "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset"
                mv "$l_target_path" "${l_target_path}${p_sufix_subfolder}"
            fi

        fi

        return 0

    fi

    #3.3 Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.

    #Validar si se requiere realizar limpieza antes del copiado
    if [ $p_clean_type -eq 1 ]; then

        printf 'Eliminando el contenido del folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
        sudo rm -rf ${l_target_path}/*

    elif [ $p_clean_type -eq 2 ]; then

        printf 'Eliminando todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
        sudo rm -rf ${l_target_path}/
        sudo mkdir -pm 755 "${l_target_path}"

    elif [ $p_clean_type -eq 3 ]; then

        if [ -d "${l_target_path}${p_sufix_subfolder}" ]; then

            #Si el folder existe se intentara mover la carpeta dentro de otro la cual no es el comportamiento deseado
            printf 'Error: %bse intenta renombrar el folder %b"%b%s%b"%b pero el folder %b"%b%s%b"%b ya existe%b.\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$l_target_path" "$g_color_reset" "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset" "$g_color_red1" "$g_color_reset"

            #return 1

            printf 'Eliminado todo el folder "%b%s%b" y crearlo nuevamente y vacio...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            sudo rm -rf ${l_target_path}/
            sudo mkdir -pm 755 "${l_target_path}"

        else
            printf 'Renombrando el folder "%b%s%b" a "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset" \
                   "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset"
            sudo mv "$l_target_path" "${l_target_path}${p_sufix_subfolder}"
        fi


    fi

    return 0

}


#Elimina/limpia un subfolder de programa y opcionalmente puede crear la ruta donde esta este subfolder (pero sin crear el subfolder)
#Parametros de entrada> Argumentos:
#  1> Tipo de target.
#     0 - Si es un subfolder de programas esta en Linux (puede requerir permisos)
#     1 - Si es un subfolder de programas esta en Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#  2> Ruta base relativo al folder de programa donde esta el subfolder.
#     Puede ser vacio. Si no es vacio y no existe este ruta siempre se creara.
#  3> Nombre del subfolder de programa (no puede ser vacio)
#  4> Tipo de operacion de limpieza (si el subfolder existe). Valor por defecto es 0
#     0 - Eliminar todo el subfolder
#     1 - Renombrar la carpeta con el nombre indicado en el paremetro 5
#  5> Solo si el parametro 4 es 2. Sufijo adicionar a la nombre del subfolder existentente
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function clean_folder_on_tools()
{

    #1. Argumentos
    local p_is_lnx_file=0
    if [ "$1" = "1" ]; then
        p_is_lnx_file=1
    fi

    local p_relative_base_path="$2"

    if [ -z "$3" ]; then
        printf 'Error: %bdebe especificarse el nombre de subfolder del programa%b.\n' "$g_color_red1" "$g_color_reset"
        return 1
    fi
    local p_subfolder_name="$3"


    local p_clean_type=0
    if [ "$4" = "1" ]; then
        p_clean_type=1
    fi

    local p_sufix_subfolder="$5"

    #2. Crear toda la ruta donde se ubicara el subfolder, si no existe
    local l_target_path=''
    if [ $p_is_lnx_file -eq 0 ]; then
        l_target_path="${g_tools_path}"
    else
        l_target_path="${g_win_tools_path}"
    fi

    if [ ! -z "$p_relative_base_path" ]; then

        l_target_path="${l_target_path}/${p_relative_base_path}"

        #Si no existe la ruta donde esta el subfolder, crearlo
        if [ ! -d "$l_target_path" ]; then
            create_folderpath_on_tools $p_is_lnx_file "" "$p_relative_base_path"
            return 0
        fi

    fi

    #3. Si existe la ruta base del subfolder y no existe el subfolder, salir con exito
    l_target_path="${l_target_path}/${p_subfolder_name}"
    if [ ! -d "$l_target_path" ]; then
        return 0
    fi

    #4. Si existe la ruta base del subfolder pero existe el subfolder, limpiarlo

    #3.1. Si son programas Windows
    if [ $p_is_lnx_file -eq 1 ]; then


        #Validar si se requiere realizar limpieza antes del copiado
        if [ $p_clean_type -eq 0 ]; then

            printf 'Eliminado todo el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            rm -rf ${l_target_path}/

        elif [ $p_clean_type -eq 1 ]; then

            if [ -d "${l_target_path}${p_sufix_subfolder}" ]; then

                #Si el folder existe se intentara mover la carpeta dentro de otro la cual no es el comportamiento deseado
                printf 'Error: %bse intenta renombrar el folder %b"%b%s%b"%b pero el folder %b"%b%s%b"%b ya existe%b.\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$l_target_path" "$g_color_reset" "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset" "$g_color_red1" "$g_color_reset"

                #return 1

                printf 'Eliminado todo el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                rm -rf ${l_target_path}/

            else
                printf 'Renombrando el folder "%b%s%b" a "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset" \
                       "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset"
                mv "$l_target_path" "${l_target_path}${p_sufix_subfolder}"
            fi

        fi

        return 0

    fi


    #3.2 Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

        #Validar si se requiere realizar limpieza antes del copiado
        if [ $p_clean_type -eq 0 ]; then

            printf 'Eliminado todo el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            rm -rf ${l_target_path}/

        elif [ $p_clean_type -eq 1 ]; then

            if [ -d "${l_target_path}${p_sufix_subfolder}" ]; then

                #Si el folder existe se intentara mover la carpeta dentro de otro la cual no es el comportamiento deseado
                printf 'Error: %bse intenta renombrar el folder %b"%b%s%b"%b pero el folder %b"%b%s%b"%b ya existe%b.\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$l_target_path" "$g_color_reset" "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset" "$g_color_red1" "$g_color_reset"

                #return 1

                printf 'Eliminado todo el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
                rm -rf ${l_target_path}/

            else
                printf 'Renombrando el folder "%b%s%b" a "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset" \
                       "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset"
                mv "$l_target_path" "${l_target_path}${p_sufix_subfolder}"
            fi

        fi

        return 0

    fi

    #3.3 Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.

    #Validar si se requiere realizar limpieza antes del copiado
    if [ $p_clean_type -eq 0 ]; then

        printf 'Eliminando todo el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
        sudo rm -rf ${l_target_path}/
        sudo mkdir -pm 755 "${l_target_path}"

    elif [ $p_clean_type -eq 1 ]; then

        if [ -d "${l_target_path}${p_sufix_subfolder}" ]; then

            #Si el folder existe se intentara mover la carpeta dentro de otro la cual no es el comportamiento deseado
            printf 'Error: %bse intenta renombrar el folder %b"%b%s%b"%b pero el folder %b"%b%s%b"%b ya existe%b.\n' "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "$l_target_path" "$g_color_reset" "$g_color_red1" "$g_color_reset" \
                   "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset" "$g_color_red1" "$g_color_reset"

            #return 1

            printf 'Eliminado todo el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            sudo rm -rf ${l_target_path}/

        else
            printf 'Renombrando el folder "%b%s%b" a "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset" \
                   "$g_color_gray1" "${l_target_path}${p_sufix_subfolder}" "$g_color_reset"
            sudo mv "$l_target_path" "${l_target_path}${p_sufix_subfolder}"
        fi


    fi

    return 0

}


#Copia un archivo en la ruta de un programa con opcion de modificar su nombre.
#Parametros de entrada> Argumentos:
#  01> Source path, relativo al folder temporal, donde esta el archivo a copiar.
#  02> Source filename: representa el nombre del archivo binario a copiar.
#  03> Tipo de ruta target donde se movera el contenido:
#      0 - Si se mueven a folder de programas de Linux (puede requerir permisos)
#      1 - Si se mueven a folder de programas de Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#  04> Target path, relativo al folder base de los programa. Es el folder donde se copiara el binario.
#      No puede ser vacio.
#  05> Target filename: representa el nuevo nombre del archivo binario a copiar.
#      Si no se especifica o es vacio, se usara el nombre indicado en 'source file'.
#  06> Permisos a modificar (solo si el tipo de archivo es Linux)
#      0 - No modifica el permiso del archivo (valor por defecto).
#      1 - Establece permisos de ejecucion al archivo.
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function copy_file_on_tools()
{

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"
    local p_source_filename="$2"

    local p_is_lnx_file=0
    if [ "$3" = "1" ]; then
        p_is_lnx_file=1
    fi

    local p_target_path="${g_tools_path}/$4"
    if [ $p_is_lnx_file -eq 1 ]; then
        p_target_path="${g_win_tools_path}/$4"
    fi

    local p_target_filename="$5"
    if [ ! -z "$p_target_filename" ]; then
        p_target_path="${p_target_path}/${p_target_filename}"
    fi

    local p_set_permission_type=0
    if [ "$6" = "1" ]; then
        p_set_permission_type=1
    fi

    #2. Si son binarios Windows
    if [ $p_is_lnx_file -eq 1 ]; then

        #Copiar los archivos
        printf 'Copiando el archivo "%b%s%b" en "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"

        cp "${p_source_path}/${p_source_filename}" "${p_target_path}"

        return 0

    fi

    #3. Si son binarios Linux
    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    #A. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

        #Copiar los archivos
        printf 'Copiando el archivo "%b%s%b" en "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"

        cp "${p_source_path}/${p_source_filename}" "${p_target_path}"

        if [ $p_set_permission_type -eq 1 ]; then
            if [ -z "$p_target_filename" ]; then
                chmod +x "${p_target_path}/${p_source_filename}"
            else
                chmod +x "${p_target_path}"
            fi
        fi

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
            if [ -z "$p_target_filename" ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}/${p_source_filename}"
            else
                chown "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}"
            fi
        fi

        return 0

    fi

    #B. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.


    #Copiar los archivos
    printf 'Copiando el archivo "%b%s%b" en "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
           "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"

    sudo cp "${p_source_path}/${p_source_filename}" "${p_target_path}"

    if [ $p_set_permission_type -eq 1 ]; then
        if [ -z "$p_target_filename" ]; then
            chmod +x "${p_target_path}/${p_source_filename}"
        else
            chmod +x "${p_target_path}"
        fi
    fi

    return 0

}




#Copia un archivo o un conjunto de estos en la ruta de un programa conservando su nombre original.
#Parametros de entrada> Argumentos:
#  01> Source path, relativo al folder temporal, donde esta el archivo a copiar.
#  02> Source filename:
#      - Si parametro '05' es '1', representa el nombre del archivo a copiar.
#      - Si parametro '05' es '0', representa el prefijo del los archivo a copiar.
#        Si es vacio, se copiaran todos los archivos de la carpeta.
#  03> Tipo de ruta target donde se movera el contenido:
#      0 - Si se mueven a folder de programas de Linux (puede requerir permisos)
#      1 - Si se mueven a folder de programas de Windows (NO requiere permisos y solo aplica en el windows asociado al WSL)
#  04> Target path, relativo al folder base de los programa. Es el folder donde se copiara el binario.
#      No puede ser vacio.
#  05> Si es '1' (su valor por defecto), se copia solo un archivo y el indicado en el parametro 2.
#      Si es '0', se copia todos los archivos que inicien con lo indicado por el parametro 2.
#  06> Permisos a modificar (solo si el tipo de archivo es Linux)
#      0 - No modifica los permisos de los archivos (valor por defecto)
#      1 - Establece permisos de ejecucion al archivo
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function copy_files_on_tools()
{

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"
    local p_source_filename="$2"

    local p_is_lnx_file=0
    if [ "$3" = "1" ]; then
        p_is_lnx_file=1
    fi

    local p_target_path="${g_tools_path}/$4"
    if [ $p_is_lnx_file -eq 1 ]; then
        p_target_path="${g_win_tools_path}/$4"
    fi

    local p_use_pattern=1
    if [ "$5" = "0" ]; then
        p_use_pattern=0
    fi

    local p_set_permission_type=0
    if [ "$6" = "1" ]; then
        p_set_permission_type=1
    fi


    #2. Si son binarios Windows
    if [ $p_is_lnx_file -eq 1 ]; then

        #Copiar los archivos
        printf 'Copiando el archivo "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"

        if [ $p_use_pattern -eq 0 ]; then
            cp ${p_source_path}/${p_source_filename}* "${p_target_path}/"
        else
            cp "${p_source_path}/${p_source_filename}" "${p_target_path}/"
        fi

        return 0

    fi

    #3. Si son binarios Linux
    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    #A. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

        #Copiar los archivos
        printf 'Copiando el archivo "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"

        if [ $p_use_pattern -eq 0 ]; then
            cp ${p_source_path}/${p_source_filename}* "${p_target_path}/"
            if [ $p_set_permission_type -eq 1 ]; then
                chmod +x ${p_target_path}/${p_source_filename}*
            fi
        else
            cp "${p_source_path}/${p_source_filename}" "${p_target_path}/"
            if [ $p_set_permission_type -eq 1 ]; then
                chmod +x "${p_target_path}/${p_source_filename}"
            fi
        fi

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
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
           "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"

    if [ $p_use_pattern -eq 0 ]; then

        sudo cp ${p_source_path}/${p_source_filename}* "${p_target_path}/"
        if [ $p_set_permission_type -eq 1 ]; then
            sudo chmod +x ${p_target_path}/${p_source_filename}*
        fi

    else

        sudo cp "${p_source_path}/${p_source_filename}" "${p_target_path}/"
        if [ $p_set_permission_type -eq 1 ]; then
            sudo chmod +x "${p_target_path}/${p_source_filename}"
        fi

    fi


    return 0

}







#Copia archivos de ayuda desde la ruta de un programa.
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
    local l_target_path="${g_lnx_man_path}/man${p_man_type}"

    local l_runner_is_lnx_base_owner=1
    if [ $(( g_lnx_base_options & 1 )) -eq 1 ]; then
        l_runner_is_lnx_base_owner=0
    fi


    #3. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de comandos (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_lnx_base_owner -eq 0 ]; then

        #Si no existe las carpetas destino, crearlo
        if [ ! -d "$l_target_path" ]; then

            if [ ! -d "$g_lnx_man_path" ]; then

                printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$g_lnx_man_path" "$g_color_reset"
                mkdir -pm 755 "${g_lnx_man_path}"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${g_lnx_man_path}"
                fi

            fi

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            mkdir -pm 755 "${l_target_path}"

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
            fi

        fi

        #Copiar los archivos
        printf 'Copiando los archivos "%b%s/*.%s%b" y/o "%b%s/*.%s.gz%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "$p_source_path" \
               "$p_man_type" "$g_color_reset" "$g_color_gray1" "$p_source_path" "$p_man_type" "$g_color_reset" "$g_color_gray1" \
               "${l_target_path}/" "$g_color_reset"
               find "$p_source_path" -type f \( -name "*.${p_man_type}" -o -name "*.${p_man_type}.gz" \) -exec cp {} "$l_target_path/" \;

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
            find "$p_target_path" -type f \( -name "*.${p_man_type}" -o -name "*.${p_man_type}.gz" \) ! -user "$g_targethome_owner" \
                 -exec chown "${g_targethome_owner}:${g_targethome_group}" {} \:
        fi

        return 0

    fi

    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los comandos es root.


    #Si no existe las carpetas crearlo
    if [ ! -d "$l_target_path" ]; then

        if [ ! -d "$g_lnx_man_path" ]; then

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$g_lnx_man_path" "$g_color_reset"
            sudo mkdir -pm 755 "${g_lnx_man_path}"

        fi

        printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
        sudo mkdir -pm 755 "${l_target_path}"

    fi


    #Copiar los archivos
    printf 'Copiando los archivos "%b%s/*.%s%b" y/o "%b%s/*.%s.gz%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "$p_source_path" \
           "$p_man_type" "$g_color_reset" "$g_color_gray1" "$p_source_path" "$p_man_type" "$g_color_reset" "$g_color_gray1" \
           "${l_target_path}/" "$g_color_reset"
           sudo find "$p_source_path" -type f \( -name "*.${p_man_type}" -o -name "*.${p_man_type}.gz" \) -exec cp {} "$l_target_path/" \;

    return 0

}


#Copia una icono de una aplicaciones.
#Parametros de entrada> Argumentos:
#  01> Ruta de la imagen a copiar relativo a carpeta de temporales.
#  02> Tipo de icono a copiar
#      00 - Icono de resolucion escalable (usualmente un archivo de imagen vectorial '.svg')
#      01 - Icono de resolucion 16x16
#      02 - Icono de resolucion 22x22
#      03 - Icono de resolucion 24x24
#      04 - Icono de resolucion 32x32
#      05 - Icono de resolucion 36x36
#      06 - Icono de resolucion 48x48
#      07 - Icono de resolucion 64x64
#      08 - Icono de resolucion 72x72
#      09 - Icono de resolucion 96x96
#      10 - Icono de resolucion 128X128
#      11 - Icono de resolucion 256x256
#      12 - Icono de resolucion 480x480
#      13 - Icono de resolucion 512X512
#      14 - Icono de resolucion 720X720
#      15 - Icono de resolucion 1024x1024
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function copy_app_icon_file()
{

    #1. Argumentos
    local p_source_image_file="${g_temp_path}/$1"

    local p_icon_type=$2
    if [ $p_icon_type -lt 0 ] || [ $p_icon_type -gt 15 ]; then
        return 1
    fi

    #2. El folder asociado al tipo de icono.
    local la_folders=('scalable' '16x16' '22x22' '24x24' '32x32' '36x36' '48x48' '64x64' '72x72' '96x96' '128x128' '256x256' '480x480' '512x512' '720x720' '1024x1024')
    local l_folder="${la_folders[$p_icon_type]}"

    if [ -z "$l_folder" ]; then
        return 1
    fi

    #3. Inicializaciones
    local l_target_path="${g_lnx_icons_path}/hicolor/${l_folder}/apps"

    local l_runner_is_lnx_base_owner=1
    if [ $(( g_lnx_base_options & 1 )) -eq 1 ]; then
        l_runner_is_lnx_base_owner=0
    fi


    #4. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de comandos (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_lnx_base_owner -eq 0 ]; then

        #Si no existe las carpetas destino, crearlo
        if [ ! -d "$l_target_path" ]; then

            if [ ! -d "${g_lnx_icons_path}" ]; then

                printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$g_lnx_icons_path" "$g_color_reset"
                mkdir -pm 755 "${g_lnx_icons_path}"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${g_lnx_icons_path}"
                fi

            fi

            if [ ! -d "${g_lnx_icons_path}/hicolor" ]; then

                printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "${g_lnx_icons_path}/hicolor" "$g_color_reset"
                mkdir -pm 755 "${g_lnx_icons_path}/hicolor"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${g_lnx_icons_path}/hicolor"
                fi

            fi

            if [ ! -d "${g_lnx_icons_path}/hicolor/$l_folder" ]; then

                printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "${g_lnx_icons_path}/hicolor/${l_folder}" "$g_color_reset"
                mkdir -pm 755 "${g_lnx_icons_path}/hicolor/${l_folder}"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${g_lnx_icons_path}/hicolor/${l_folder}"
                fi

            fi

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            mkdir -pm 755 "${l_target_path}"

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
            fi

        fi

        #Copiar los archivos
        printf 'Copiando la imagen "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "$p_source_image_file" \
               "$g_color_reset" "$g_color_gray1" "${l_target_path}/" "$g_color_reset"
        cp "$p_source_image_file" "$l_target_path/"

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
            chown "${g_targethome_owner}:${g_targethome_group}" "$p_source_image_file"
        fi

        return 0

    fi


    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los comandos es root.

    #Si no existe las carpetas crearlo
    if [ ! -d "$l_target_path" ]; then

        if [ ! -d "${g_lnx_icons_path}" ]; then

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$g_lnx_icons_path" "$g_color_reset"
            sudo mkdir -pm 755 "${g_lnx_icons_path}"

        fi

        if [ ! -d "${g_lnx_icons_path}/hicolor" ]; then

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "${g_lnx_icons_path}/hicolor" "$g_color_reset"
            sudo mkdir -pm 755 "${g_lnx_icons_path}/hicolor"

        fi

        if [ ! -d "${g_lnx_icons_path}/hicolor/$l_folder" ]; then

            printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "${g_lnx_icons_path}/hicolor/${l_folder}" "$g_color_reset"
            sudo mkdir -pm 755 "${g_lnx_icons_path}/hicolor/${l_folder}"

        fi

        printf 'Creando el folder "%b%s%b"...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
        sudo mkdir -pm 755 "${l_target_path}"

    fi

    #Copiar los archivos
    printf 'Copiando la imagen "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "$p_source_image_file" \
           "$g_color_reset" "$g_color_gray1" "${l_target_path}/" "$g_color_reset"
    sudo cp "$p_source_image_file" "$l_target_path/"

    return 0


}



#Copia un grupo de icono de una aplicaciones.
#Parametros de entrada> Argumentos:
#  01> Source path: Folder realativo al folder temporal donde se buscaran los archivos indicados en el siguiente parametro.
#  02> Arreglo de la rutas (relativo al 'source path') de los iconos a copiar
#      00 - Icono de resolucion escalable (usualmente un archivo de imagen vectorial '.svg')
#      01 - Icono de resolucion 16x16
#      02 - Icono de resolucion 22x22
#      03 - Icono de resolucion 24x24
#      04 - Icono de resolucion 32x32
#      05 - Icono de resolucion 36x36
#      06 - Icono de resolucion 48x48
#      07 - Icono de resolucion 64x64
#      08 - Icono de resolucion 72x72
#      09 - Icono de resolucion 96x96
#      10 - Icono de resolucion 128X128
#      11 - Icono de resolucion 256x256
#      12 - Icono de resolucion 480x480
#      13 - Icono de resolucion 512X512
#      14 - Icono de resolucion 720X720
#      15 - Icono de resolucion 1024x1024
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function copy_app_icon_files() {

    # Argumentos
    local p_source_path="$1"

    if [ -z "$2" ]; then
        return 1
    fi
    declare -n ra_icons_app="$2"

    # Prevalidaciones
    local l_n=${#ra_icons_app[@]}
    if [ $l_n -le 0 ]; then
        return 1
    fi

    # Copiando cada icon file
    local l_i=0
    local l_icon_file=''
    local l_status=0

    for(( l_i=0; l_i < l_n; l_i++ )); do

        l_icon_file="${ra_icons_app[$l_i]}"

        if [ -z "$l_icon_file" ]; then
            continue
        fi

        if [ $l_i -gt 15 ]; then
            break
        fi

        if [ -z "$p_source_path" ]; then
            copy_app_icon_file "${l_icon_file}" $l_i
            l_status=$?
        else
            copy_app_icon_file "${p_source_path}/${l_icon_file}" $l_i
            l_status=$?
        fi

        if [ $l_status -ne 0 ]; then
            return 1
        fi

    done


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

    local p_is_lnx_file=0
    if [ "$2" = "1" ]; then
        p_is_lnx_file=1
    fi

    local l_target_path="${g_lnx_fonts_path}/$3"
    if [ $p_is_lnx_file -eq 1 ]; then
        l_target_path="${g_win_fonts_path}/$3"
    fi

    local p_flag_update_font_cache=1
    if [ "$4" = "0" ]; then
        p_flag_update_font_cache=0
    fi

    #2. Si son binarios Windows
    if [ $p_is_lnx_file -eq 1 ]; then

        #Si no existe las carpetas destino, crearlo
        if [ ! -d "$l_target_path" ]; then

            if [ ! -d "$g_lnx_fonts_path" ]; then

                printf 'Creando el folder "%b%s%b" para las fuentes...\n' "$g_color_gray1" "$g_lnx_fonts_path" "$g_color_reset"
                mkdir -pm 755 "${g_lnx_fonts_path}"

            fi

            printf 'Creando el folder "%b%s%b" para las fuentes...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            mkdir -pm 755 "${l_target_path}"

        fi

        #Copiar los archivos de fuentes
        printf 'Copiando los archivos de fuente "*.otf" y "*.ttf" desde "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
               "$g_color_reset" "$g_color_gray1" "$l_target_path" "$g_color_reset"

        #Copiar y/o sobrescribir archivos existente
        find "${p_source_path}" -maxdepth 1 -mindepth 1 \( -iname '*.otf' -o -iname '*.ttf' \) \
             -exec cp '{}' ${l_target_path} \;

        return 0

    fi

    #3. Si son binarios Linux
    local l_runner_is_lnx_base_owner=1
    if [ $(( g_lnx_base_options & 1 )) -eq 1 ]; then
        l_runner_is_lnx_base_owner=0
    fi


    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #     Solo se puede dar en estos 2 posibles escenarios:
    #     - Si el runner es root en modo de suplantacion del usuario objetivo.
    #     - Si el runner es el owner de la carpeta de comandos (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_lnx_base_owner -eq 0 ]; then

        #Si no existe las carpetas destino, crearlo
        if [ ! -d "$l_target_path" ]; then


            if [ ! -d "$g_lnx_fonts_path" ]; then

                printf 'Creando el folder "%b%s%b" para las fuentes...\n' "$g_color_gray1" "$g_lnx_fonts_path" "$g_color_reset"
                mkdir -pm 755 "${g_lnx_fonts_path}"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
                    chown "${g_targethome_owner}:${g_targethome_group}" "${g_lnx_fonts_path}"
                fi

            fi

            printf 'Creando el folder "%b%s%b" para las fuentes...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            mkdir -pm 755 "${l_target_path}"

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
            fi

        fi

        #Copiar los archivos de fuentes
        printf 'Copiando los archivos de fuente "*.otf" y "*.ttf" desde "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
               "$g_color_reset" "$g_color_gray1" "$l_target_path" "$g_color_reset"

        #Copiar y/o sobrescribir archivos existente
        find "${p_source_path}" -maxdepth 1 -mindepth 1 \( -iname '*.otf' -o -iname '*.ttf' \) \
             -exec cp '{}' ${l_target_path} \;
        chmod g+r,o+r ${l_target_path}/*


        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
            chown "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}"
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
    if [ ! -d "$l_target_path" ]; then

       if [ ! -d "$g_lnx_fonts_path" ]; then

           printf 'Creando el folder "%b%s%b" para las fuentes...\n' "$g_color_gray1" "$g_lnx_fonts_path" "$g_color_reset"
           sudo mkdir -pm 755 "${g_lnx_fonts_path}"

       fi

        printf 'Creando el folder "%b%s%b" para las fuentes...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
        sudo mkdir -pm 755 "${l_target_path}"

    fi

    #Copiar los archivos de fuentes
    printf 'Copiando los archivos de fuente "*.otf" y "*.ttf" desde "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
           "$g_color_reset" "$g_color_gray1" "$l_target_path" "$g_color_reset"

    #Copiar y/o sobrescribir archivos existente
    sudo find "${p_source_path}" -maxdepth 1 -mindepth 1 \( -iname '*.otf' -o -iname '*.ttf' \) \
         -exec cp '{}' ${l_target_path} \;
    sudo chmod g+r,o+r ${l_target_path}/*


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
function copy_binary_file()
{

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"
    local p_source_filename="$2"

    local p_is_lnx_file=0
    if [ "$3" = "1" ]; then
        p_is_lnx_file=1
    fi

    local p_use_pattern=1
    if [ "$4" = "0" ]; then
        p_use_pattern=0
    fi

    local l_target_path="${g_lnx_bin_path}"
    if [ $p_is_lnx_file -eq 1 ]; then
        l_target_path="${g_win_bin_path}"
    fi

    #2. Si son binarios Windows
    if [ $p_is_lnx_file -eq 1 ]; then

        #Si no existe las carpetas destino, crearlo
        if [ ! -d "$l_target_path" ]; then

            printf 'Creando el folder "%b%s%b" para las binarios...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            mkdir -p "${l_target_path}"

        fi

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
    local l_runner_is_lnx_base_owner=1
    if [ $(( g_lnx_base_options & 1 )) -eq 1 ]; then
        l_runner_is_lnx_base_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #     Solo se puede dar en estos 2 posibles escenarios:
    #     - Si el runner es root en modo de suplantacion del usuario objetivo.
    #     - Si el runner es el owner de la carpeta de comandos (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_lnx_base_owner -eq 0 ]; then

        #Si no existe las carpetas destino, crearlo
        if [ ! -d "$l_target_path" ]; then

            printf 'Creando el folder "%b%s%b" para las binarios...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            mkdir -pm 755 "${l_target_path}"

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" ${l_target_path}
            fi

        fi

        #Copiar los archivos
        printf 'Copiando el archivo "%b%s%b" a la carpeta "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${l_target_path}/" "$g_color_reset"

        if [ $p_use_pattern -eq 0 ]; then
            cp ${p_source_path}/${p_source_filename}* "${l_target_path}/"
            chmod +x ${g_lnx_bin_path}/${p_source_filename}*
        else
            cp "${p_source_path}/${p_source_filename}" "${l_target_path}/"
            chmod +x "${g_lnx_bin_path}/${p_source_filename}"
        fi

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
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

    #Si no existe las carpetas destino, crearlo
    if [ ! -d "$l_target_path" ]; then

        printf 'Creando el folder "%b%s%b" para las binarios...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
        sudo mkdir -pm 755 "${l_target_path}"

    fi

    if [ $p_use_pattern -eq 0 ]; then
        sudo cp ${p_source_path}/${p_source_filename}* "${l_target_path}/"
        sudo chmod +x ${l_target_path}/${p_source_filename}*
    else
        sudo cp "${p_source_path}/${p_source_filename}" "${l_target_path}/"
        sudo chmod +x "${l_target_path}/${p_source_filename}"
    fi

    return 0


}


#Crea el enlace simbolico, de un binario de un programa, en la carpeta de los binarios del sistema/usuario.
#Parametros de entrada> Argumentos:
#  01> Source path, relativo al folder de programas, donde esta el archivo binario donde ser creara el enalce simbolico.
#  02> Source filename: representa el nombre del archivo binario a crear su enlace simbolico.
#  03> Symbolic link name: representa el nombre del enlace simbolico creado.
#Parametros de salida > Valor de retorno:
#  0 - OK
#  1 - No OK
function create_link_binary_file()
{

    #1. Argumentos
    local p_source_path="${g_tools_path}/$1"
    local p_source_filename="$2"

    local l_target_path="${g_lnx_bin_path}"
    local p_target_filename="$3"

    #2. Inicializaciones

    #Precondicion: Debe existir el binario del programa
    if [ ! -f "${p_source_path}/${p_source_filename}" ]; then
        printf '%bNo existe el archivo "%b%s%b", en la carpeta "%b%s%b"%b, al cual se va a crear el enlace simbolico.\n' "$g_color_red1" \
               "$g_color_gray1" "${p_source_filename}" "$g_color_red1" "$g_color_gray1" "$p_source_path" "$g_color_red1" "$g_color_reset".
        return 1
    fi

    local l_runner_is_lnx_base_owner=1
    if [ $(( g_lnx_base_options & 1 )) -eq 1 ]; then
        l_runner_is_lnx_base_owner=0
    fi

    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    #3. Si el usuario runner tiene los permisos necesarios para la instalación de comandos (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #     - Si el runner es root en modo de suplantacion del usuario objetivo.
    #     - Si el runner es el owner de la carpeta de comandos (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_lnx_base_owner -eq 0 ]; then

        #Si no existe las carpetas destino, crearlo
        if [ ! -d "$l_target_path" ]; then

            printf 'Creando el folder "%b%s%b" para las binarios...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
            mkdir -pm 755 "${l_target_path}"

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
                chown "${g_targethome_owner}:${g_targethome_group}" ${l_target_path}
            fi

        fi

        #A. Dando permisos de ejecucion al binario del programa
        printf 'Estableciendo permisos de ejecucion al binario "%b%s%b" del programa ubicado en "%b%s%b" ...\n' "$g_color_gray1" "${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "$p_source_path" "$g_color_reset"
        if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then
            chmod +x "${p_source_path}/${p_source_filename}"
        else
            sudo chmod +x "${p_source_path}/${p_source_filename}"
        fi

        #B. Creando/recrenado el enlace simbolico
        printf 'Creando el enlace simbolico "%b%s%b" del binario del programa "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}/${p_source_filename}" \
               "$g_color_reset" "$g_color_gray1" "${l_target_path}/${p_target_filename}" "$g_color_reset"
        ln -snf "${p_source_path}/${p_source_filename}" "${l_target_path}/${p_target_filename}"

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_lnx_base_owner -eq 0 ]; then
            chown -h "${g_targethome_owner}:${g_targethome_group}" "${l_target_path}/${p_target_filename}"
        fi

        return 0

    fi

    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los comandos es root.

    #Si no existe las carpetas destino, crearlo
    if [ ! -d "$l_target_path" ]; then

        printf 'Creando el folder "%b%s%b" para las binarios...\n' "$g_color_gray1" "$l_target_path" "$g_color_reset"
        sudo mkdir -pm 755 "${l_target_path}"

    fi

    #A. Dando permisos de ejecucion al binario del programa
    printf 'Estableciendo permisos de ejecucion al binario "%b%s%b" del programa ubicado en "%b%s%b" ...\n' "$g_color_gray1" "${p_source_filename}" \
           "$g_color_reset" "$g_color_gray1" "$p_source_path" "$g_color_reset"
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then
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


#Crea un enlace simbolico blando dentro del folder de programas (solo para archivos de linux, no windows)
#Parametros en entraga> Argumentos y Opciones
# 1 > Ruta de folder origin (source) relativa al folder programas al cual se desea crear un enlace simbolico.
# 2 > Ruta del folder destino (target) relativa del folder de programas donde se creara el enlace simbolico.
# 3 > Nombre del enlace simbolico que se desea crear ubicado en el folder de programas.
# 4 > Flag '0' si se desea sobrescribir un enlace simbolico ya existente.
# 5 > Prefijo que se muestra al inicio de cada linea de texto que se escribe en el SDTOUT.
#Parametros de salida (valores de retorno):
# 0 > Ya existe el enlace simbolico y no se realizo ningun cambio.
# 1 > Ya existe el enlace simbolico pero se ha recreado en enlace simbolico.
# 2 > Se creo el enlace simbolico
function create_folderlink_on_tools() {

    #Argumentos
    local p_source_path="$1"
    local p_target_path="$2"
    local p_target_link="$3"

    local p_override_target_link=1
    if [ "$4" = "0" ]; then
        p_override_target_link=0
    fi
    local p_tag="$5"

    #2. Inicializaciones
    if [ -z "$p_source_path" ]; then
        p_source_path="${g_tools_path}"
    else
        p_source_path="${g_tools_path}/${p_source_path}"
        if [ ! -d "$p_source_path" ]; then
            printf "%s%bEl folder '%b%s%b' source del enlace simbolico no existe.%b\n" "$p_tag" "$g_color_red1" "$g_color_gray1" \
                   "$p_source_path" "$g_color_red1" "$g_color_reset"
        fi
    fi

    if [ -z "$p_target_path" ]; then
        p_target_path="${g_tools_path}"
    else
        p_target_path="${g_tools_path}/${p_target_path}"
        if [ ! -d "$p_target_path" ]; then
            printf "%s%bEl folder '%b%s%b' donde se crea el enlace simbolico no existe.%b\n" "$p_tag" "$g_color_red1" "$g_color_gray1" \
                   "$p_target_path" "$g_color_red1" "$g_color_reset"
        fi
    fi

    local l_target_fulllink="${p_target_path}/${p_target_link}"
    local l_status=0
    local l_aux

    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    if [ -h "$l_target_fulllink" ] && [ -d "$l_target_fulllink" ]; then

        if [ $p_override_target_link -eq 0 ]; then


            # Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
            if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

                ln -snf "${p_source_path}/" "$l_target_fulllink"

                #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
                if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
                    chown -h "${g_trgethome_owner}:${g_targethome_group}" "${l_target_fulllink}"
                fi

            # Si el usuario runner solo puede realizar la instalación usando sudo para root.
            else

                sudo ln -snf "${p_source_path}/" "$l_target_fulllink"
                sudo chown -h "${g_trgethome_owner}:${g_targethome_group}" "${l_target_fulllink}"

            fi

            printf "%sEl enlace simbolico '%s' se ha re-creado %b(ruta real '%s')%b\n" "$p_tag" "$l_target_fulllink" "$g_color_gray1" "$p_source_path" "$g_color_reset"
            l_status=1

        else
            l_aux=$(readlink "$l_target_fulllink")
            printf "%sEl enlace simbolico '%s' ya existe %b(ruta real '%s')%b\n" "$p_tag" "$l_target_fulllink" "$g_color_gray1" "$l_aux" "$g_color_reset"
            l_status=0
        fi

    else

        # Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
        if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

            ln -snf "${p_source_path}/" "$l_target_fulllink"

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
                chown -h "${g_targethome_owner}:${g_targethome_group}" "${l_target_fulllink}"
            fi

        # Si el usuario runner solo puede realizar la instalación usando sudo para root.
        else

            sudo ln -snf "${p_source_path}/" "$l_target_fulllink"
            sudo chown -h "${g_trgethome_owner}:${g_targethome_group}" "${l_target_fulllink}"

        fi

        printf "%sEl enlace simbolico '%s' se ha creado %b(ruta real '%s')%b\n" "$p_tag" "$l_target_fulllink" "$g_color_gray1" "$p_source_path" "$g_color_reset"
        l_status=2

    fi

    return $l_status

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
function save_prettyversion_on_tools()
{

    #1. Argumentos
    local p_is_lnx_file=0   #Es un binario linux
    if [ "$4" = "1" ]; then
        p_is_lnx_file=1     #Es un binario de Windows
    fi

    local p_target_path="${g_tools_path}"
    if [ $p_is_lnx_file -eq 1 ]; then
        p_target_path="${g_win_tools_path}"
    fi

    if [ ! -z "$1" ]; then
        p_target_path="${p_target_path}/$1"
    fi

    local p_target_filename="$2"
    local p_pretty_version="$3"



    #2. Si son binarios Windows
    if [ $p_is_lnx_file -eq 1 ]; then


        #Almacenando la info del programa/comando
        printf 'Almacenando la version "%b%s%b" instalada/actualizada en el archivo "%b%s%b" ...\n' "$g_color_gray1" "${p_pretty_version}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}/${p_target_filename}" "$g_color_reset"

        echo "${p_pretty_version}" > "${p_target_path}/${p_target_filename}"
        #chmod +r "${p_target_path}/${p_target_filename}"

        return 0

    fi

    #3. Si son binarios Linux
    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #     Solo se puede dar en estos 2 posibles escenarios:
    #     - Si el runner es root en modo de suplantacion del usuario objetivo.
    #     - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

        #Almacenando la info del programa/comando
        printf 'Almacenando la version "%b%s%b" instalada/actualizada en el archivo "%b%s%b" ...\n' "$g_color_gray1" "${p_pretty_version}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}/${p_target_filename}" "$g_color_reset"

        echo "${p_pretty_version}" > "${p_target_path}/${p_target_filename}"
        chmod +r "${p_target_path}/${p_target_filename}"

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
            chown "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}/${p_target_filename}"
        fi

        return 0
    fi

    #3.2. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #     - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.

    #Almacenando la info del programa/comando
    printf 'Almacenando la version "%b%s%b" instalada/actualizada en el archivo "%b%s%b" ...\n' "$g_color_gray1" "${p_pretty_version}" \
           "$g_color_reset" "$g_color_gray1" "${p_target_path}/${p_target_filename}" "$g_color_reset"

    sudo sh -c "echo ${p_pretty_version} > ${p_target_path}/${p_target_filename}"
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
function move_tempfoldercontent_on_tools()
{

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"
    local p_is_lnx_file=0
    if [ "$2" = "1" ]; then
        p_is_lnx_file=1
    fi

    local p_target_path="${g_tools_path}/$3"
    if [ $p_is_lnx_file -eq 1 ]; then
        p_target_path="${g_win_tools_path}/$3"
    fi
    local p_find_options="$4"

    #2. Si son programas Windows
    if [ $p_is_lnx_file -eq 1 ]; then

        #Mover todos objetos del cotenido del primer nivel
        printf 'Moviendo el contenido del source folder "%b%s%b" al target folder "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"
        find "${p_source_path}" -maxdepth 1 -mindepth 1 $p_find_options -exec mv '{}' ${p_target_path} \;
        return 0

    fi

    #3. Si son programas Linux
    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

        #Mover todos objetos del cotenido del primer nivel
        printf 'Moviendo el contenido del source folder "%b%s%b" al target folder "%b%s%b" ...\n' "$g_color_gray1" "${p_source_path}" \
               "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"

        find "${p_source_path}" -maxdepth 1 -mindepth 1 $p_find_options -exec mv '{}' ${p_target_path} \;

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
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
function move_tempfolder_on_tools()
{

    #1. Argumentos
    local p_source_path="${g_temp_path}/$1"
    local p_source_foldername="$2"

    local p_is_lnx_file=0
    if [ "$3" = "1" ]; then
        p_is_lnx_file=1
    fi

    local p_target_path="${g_tools_path}/$4"
    if [ $p_is_lnx_file -eq 1 ]; then
        p_target_path="${g_win_tools_path}/$4"
    fi

    #2. Si son programas Windows
    if [ $p_is_lnx_file -eq 1 ]; then

        #Mover el folder
        printf 'Moviendo el source folder "%b%s%b", ubicado en "%b%s%b", al target folder "%b%s%b" ...\n' "$g_color_gray1" "${p_source_foldername}" \
               "$g_color_reset" "$g_color_gray1" "${p_source_path}" "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"
        mv ${p_source_path}/${p_source_foldername}/ ${p_target_path}/
        return 0

    fi

    #3. Si son programas Linux
    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

        #Mover el folder
        printf 'Moviendo el source folder "%b%s%b", ubicado en "%b%s%b", al target folder "%b%s%b" ...\n' "$g_color_gray1" "${p_source_foldername}" \
               "$g_color_reset" "$g_color_gray1" "${p_source_path}" "$g_color_reset" "$g_color_gray1" "${p_target_path}" "$g_color_reset"
        mv ${p_source_path}/${p_source_foldername}/ ${p_target_path}/


        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
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
            gunzip -q "${p_source_path}/${p_source_filename}"
        else
            sudo gunzip -q "${p_source_path}/${p_source_filename}"
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
#  1> Target path type. Tipo de ruta base target donde se descomprime el archivo, puede ser:
#     0 - Un subfolder del programas de Linux
#     1 - Un subfolder del programas de Windows
#  2> Ruta source, relativa respecto al temporal donde estan los archivos comprimido.
#  3> Nombre del archivo source (archivos comprimido ubicado dentro de un folder ruta 1)
#  4> Source filetype. El tipo de formato de archivo de comprension
#       > 0 si es un .tar.gz
#       > 1 si es un .zip
#       > 2 si es un .gz
#       > 3 si es un .tgz
#       > 4 si es un .tar.xz
#  5> Ruta relativa al folder de programas (parametro 1), donde se descomprime el archivo
#     Puede o no incluir el nombre del subfolder del programa. Puede ser vacio.
#  6> El nombre del subfolder del programa
#     Solo es necesario cuando el comprimido genera un subfolder y se desea renombrarlo con este nombre.
#  7> Prefijo (parte inicial) del nombre de subfolder autogenerado por la descomprención y la cual se desea renombrar.
#     Solo es necesario cuando el comprimido genera un subfolder y se desea renombrarlo con este nombre.
#Parametros de salida
#   > Valor de retorno:
#      0 si es exitoso,
#      1 si hubo un erorr.
uncompress_on_folder() {

    #1. Argumentos
    local p_is_lnx_file=0  #es un binario de Linux
    if [ "$1" = "1" ]; then
        p_is_lnx_file=1    #es un binario de Windows
    fi


    local p_source_path="${g_temp_path}/$2"
    local p_source_filename="$3"
    local p_source_filetype=$4


    local p_target_path=""
    if [ $p_is_lnx_file -eq 1 ]; then
        p_target_path="${g_win_tools_path}"
    else
        p_target_path="${g_tools_path}"
    fi

    if [ ! -z "$5" ]; then
        p_target_path="${p_target_path}/$5"
    fi


    local p_foldername="$6"

    local p_foldername_searchprefix=""
    if [ -z "$p_foldername" ]; then
        p_foldername_searchprefix=''
        p_foldername=''
    else
        p_foldername_searchprefix="$7"
    fi


    #g_filename_without_ext=$(get_filename_withoutextension "$p_source_filename" $p_source_filetype)

    #Validar que existe el folder donde se descromprimira el archivo
    if [ ! -d "$p_target_path" ]; then

        printf 'Error: %bLa carpeta %b"%b%s%b"%b donde se descomprimira %b"%b%s%b"%b no existe%b.\n' \
               "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$p_target_path" "$g_color_reset" "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$p_source_filename" "$g_color_reset" "$g_color_red1" "$g_color_reset"
        return 1
    fi


    #2. Si el binario de Windows
    local l_current_fullfoldername=''
    if [ $p_is_lnx_file -eq 1 ]; then


        #A. Descomprimir
        _uncompress_file "$p_source_path" "$p_source_filename" $p_source_filetype "$p_target_path" 1

        #B. Si no requiere renombrar uns subfolder generado
        if [ -z "$p_foldername" ]; then
            return 0
        fi

        #C. Si no requiere renombrar uns subfolder generado

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
    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then


        #A. Descomprimir
        _uncompress_file "$p_source_path" "$p_source_filename" $p_source_filetype "$p_target_path" 1

        #B. Si no requiere renombrar uns subfolder generado
        if [ -z "$p_foldername" ]; then

            #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
            if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
                chown -R "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}"
            fi

            return 0

        fi

        #C. Si no requiere renombrar uns subfolder generado

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
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
            chown -R "${g_targethome_owner}:${g_targethome_group}" "${p_target_path}/${p_foldername}"
        fi

        return 0

    fi


    #4. Si el usuario runner solo puede realizar la instalación usando sudo para root.
    #   - Este escenario solo puede ser: el runner es el usuario objetivo y el owner del folder de los programas es root.


    #A. Descomprimir
    _uncompress_file "$p_source_path" "$p_source_filename" $p_source_filetype "$p_target_path" 0

    #B. Si no requiere renombrar uns subfolder generado
    if [ -z "$p_foldername" ]; then
        return 0
    fi

    #C. Si no requiere renombrar uns subfolder generado

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

    local p_is_lnx_file=0
    if [ "$2" = "1" ]; then
        p_is_lnx_file=1
    fi

    local p_target_path="${g_tools_path}/$3"
    if [ $p_is_lnx_file -eq 1 ]; then
        p_target_path="${g_win_tools_path}/$3"
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
    if [ $p_is_lnx_file -eq 1 ]; then

        #Sincronizar (copiar y remplazar los archivos modificados sin advertencia interactiva)
        printf 'Ejecutando "%brsync -a --stats %s/ %s%b"...\n' "$g_color_gray1" "$p_source_path" "$p_target_path" "$g_color_reset"
        printf '%b' "$g_color_gray1"
        rsync -a --stats "${p_source_path}/" "${p_target_path}"
        printf '%b' "$g_color_reset"

        return 0

    fi


    #3. Si el destino es el programa de Linux
    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

        printf 'Ejecutando "%brsync -a --stats %s/ %s%b"...\n' "$g_color_gray1" "$p_source_path" "$p_target_path" "$g_color_reset"
        printf '%b' "$g_color_gray1"
        rsync -a --stats "${p_source_path}/" "${p_target_path}"
        printf '%b' "$g_color_reset"

        #Si el runner es root en modo suplantacion del usuario objetivo y el owner de la carpeta es el usuario objetivo.
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
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
exec_script_on_tools() {

    #1. Argumentos
    local p_script_path="${g_temp_path}/$1"
    local p_script_name="$2"


    local p_target_path="${g_tools_path}/$3"
    local p_script_targetoption="$4"
    local p_script_otheroptions="$5"

    #3. Inicialización
    local l_runner_is_tools_owner=1
    if [ $(( g_tools_options & 1 )) -eq 1 ]; then
        l_runner_is_tools_owner=0
    fi

    #3.1. Si el usuario runner tiene los permisos necesarios para la instalación (sin requerir sudo)
    #   Solo se puede dar en estos 2 posibles escenarios:
    #   - Si el runner es root en modo de suplantacion del usuario objetivo.
    #   - Si el runner es el owner de la carpeta de programas (el cual a su vez, es usuario objetivo).
    local l_status=0
    if [ $g_runner_is_target_user -ne 0 ] || [ $l_runner_is_tools_owner -eq 0 ]; then

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
        if [ $g_runner_is_target_user -ne 0 ] && [ $l_runner_is_tools_owner -eq 0 ]; then
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
    local p_library_path="${g_tools_path}/$1"
    local p_config_filename=$2

    #2. Inicializaciones

    #Si no existe las carpetas de librerias
    if [ ! -d "$p_library_path" ]; then

        printf '%bNo existe folder "%b%s%b" de librerias dinamica a registar.%b\n' "$g_color_red1" "$g_color_gray1" "$p_library_path" \
               "$g_color_red1" "$g_color_reset"
        return 2

    fi

    #Si los programas estan dentro del home del usuario objetivo, solo se debe usar variables de entorno 'LD_LIBRARY_PATH'
    if [ $(( g_tools_options & 4 )) -eq 4 ]; then

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
