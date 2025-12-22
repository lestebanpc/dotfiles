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
#Representa la ruta base donde estan todos los script, incluyendo los script instalación:
#  > 'g_shell_path' tiene la estructura de subfolderes:
#     ./bash/
#         ./bin/
#             ./linuxsetup/
#                 ./00_setup_summary.bash
#                 ./01_setup_binaries.bash
#                 ./04_install_profile.bash
#                 ./05_update_profile.bash
#                 ./03_setup_repo_os_pkgs.bash
#                 ........................
#                 ........................
#                 ........................
#         ./lib/
#             ./mod_common.bash
#             ........................
#             ........................
#     ./sh/
#         ........................
#         ........................
#     ........................
#     ........................
#  > 'g_shell_path' usualmente es '$HOME/.file/shell'.
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

    if [[ "$l_script_path" == */bash/bin/linuxsetup/* ]]; then
        g_shell_path="${l_script_path%/bash/bin/linuxsetup/*}"
    else
        printf 'El script "%s" actual debe de estar en el folder padre ".../bash/bin/linuxsetup/".\n' "$l_script_path"
        return 1
    fi


    return 0

}

_get_current_script_info
_g_status=$?
if [ $_g_status -ne 0 ]; then
    exit 111
fi



#Funciones generales, determinar el tipo del SO y si es root
# shellcheck source=/home/lucianoepc/.files/shell/bash/lib/mod_common.bash
. ${g_shell_path}/bash/lib/mod_common.bash

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
    #    > 50 - 59 : Familia Arch
    #           50 : Arch Linux
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
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        printf 'No se pueden obtener la información del usuario actual de ejecución del script: Name="%s", UID="%s".\n' "$g_runner_user" "$g_runner_id"
        exit 111
    fi

fi

if [ $g_runner_id -lt 0 ] || [ -z "$g_runner_user" ]; then
    printf 'No se pueden obtener la información del usuario actual de ejecución del script: Name="%s", UID="%s".\n' "$g_runner_user" "$g_runner_id"
    exit 111
fi


#Funciones de utilidad generalees para los instaladores:
# shellcheck source=/home/lucianoepc/.files/shell/bash/bin/linuxsetup/lib/common_utility.bash
. ${g_shell_path}/bash/bin/linuxsetup/lib/common_utility.bash


declare -r g_default_list_package_ids='curl,unzip,openssl,tmux'

#Opciones de '04_install_profile.bash' para configurar VIM/NeoVIM
#  (0) Flag para configurar el modo developer
#  (1) Configuración: Crear los archivos de configuración
#  (2) Configuración: Descargar los plugins e indexar su documentación
#  (3) Configuración: Descargar los plugins sin indexar su documentación
#  (4) Indexar la documentación de los plugins existentes
declare -ra ga_options_vim=(16 32 64 128 256)
declare -ra ga_options_nvim=(1024 2048 4096 8192 16384)
declare -ra ga_title_config=(
    "Flag para configurar el modo developer"
    "Configuración: Crear los archivos de configuración"
    "Configuración: Descargar los plugins e indexar su documentación"
    "Configuración: Descargar los plugins sin indexar su documentación"
    "Indexar la documentación de los plugins existentes"
    )

#Opciones de '04_install_profile.bash'para instalar lo necesario para VIM/NeoVIM
#  (0) Configurar archivos del profile del usuario actual
#  (1) Flag para overwrite symbolic link en caso de existir
#  (2) Flag para overwrite file en caso de existir
#  (3) Python > Instalar paquetes de usuario basicos
#  (4) Python > Instalar paquetes de usuario sobre LSP/DAP
#  (5) Python > Instalar paquetes de usuario otros
#  (6) NodeJS > Instalar paquetes globales basicos:
#  (7) NodeJS > Instalar paquetes globales sobre LSP/DAP:
#  (8) NodeJS > Instalar paquetes globales otros:
declare -ra ga_options_others=(1 2 4 1048576 2097152 4194304 65536 131072 262144)
declare -ra ga_title_others=(
    "General > ${g_color_blue1}Configurar archivos del profile del usuario actual"
    "General > ${g_color_blue1}Flag para overwrite symbolic link en caso de existir"
    "General > ${g_color_blue1}Flag para overwrite file en caso de existir"
    "Python  > ${g_color_blue1}Instalar paquetes de usuario basicos"
    "Python  > ${g_color_blue1}Instalar paquetes de usuario sobre LSP/DAP"
    "Python  > ${g_color_blue1}Instalar paquetes de usuario otros"
    "NodeJS  > ${g_color_blue1}Instalar paquetes globales basicos"
    "NodeJS  > ${g_color_blue1}Instalar paquetes globales sobre LSP/DAP:"
    "NodeJS  > ${g_color_blue1}Instalar paquetes globales otros"
    )

#}}}






#------------------------------------------------------------------------------------------------------------------
#> Funciones usadas durante configuración del profile {{{
#------------------------------------------------------------------------------------------------------------------
#
# Incluye las variable globales usadas como parametro de entrada y salida de la funcion que no sea resuda por otras
# funciones, cuyo nombre inicia con '_g_'.
#


# Instalar programas del sistema usando paquetes del sistema
# > Parametros de entrada
# > Parametros de salida
#    0> Se instala el programam
#    1> No se instala ningun programa (no se cumple las precondiciones)
function _setup_os_package() {

    #1. Argumentos
    local p_input_options=$1

    local p_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$2" ]; then
        p_list_pckg_ids="$2"
    fi


    #2. Validar si se puede instalar
    if [ $p_input_options -le 0 ]; then
        return 1
    fi

    local l_flag_packages=1
    local l_flag_upgrade_os=1

    # Validar si la opcion esta habilitada
    local l_option=2
    if [ $(( $p_input_options & $l_option )) -eq $l_option ] && [ ! -z "$p_list_pckg_ids" ]; then
        l_flag_packages=0
    fi

    l_option=1
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        l_flag_upgrade_os=0
    fi

    # Si ninguna de las opciones se ha habilitado
    if [ $l_flag_packages -ne 0 ] && [ $l_flag_upgrade_os -ne 0 ]; then
        return 1
    fi

    # Solo lo puede instalar root
    if [ $g_runner_sudo_support -eq 2 ] || [ $g_runner_sudo_support -eq 3 ]; then

        printf '%bSe requiere acceso a root%b para instalar paquete del SO "%b%s%b".\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" \
               "$g_default_list_package_ids" "$g_color_reset"
        return 1

    fi

    #3. Instalar
    local l_status
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    # Mostrar el titulo de instalacion
    printf '\n'
    print_line '─' $g_max_length_line  "$g_color_blue1"
    printf "> %bSystem Programs >%b Instalando '%b%s%b'\n" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "${p_list_pckg_ids//,/, }" "$g_color_reset"
    print_line '─' $g_max_length_line "$g_color_blue1"


    # Parametros:
    # 1> Tipo de ejecución: 2/4 (ejecución sin menu, para instalar/actualizar un grupo paquetes).
    # 2> Paquetes a instalar.
    # 3> El estado de la credencial almacenada para el sudo.
    # 4> Actualizar los paquetes del SO antes. Por defecto es 1 (false).
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 2 "$p_list_pckg_ids" $g_status_crendential_storage $l_flag_upgrade_os
        l_status=$?
    else
        ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 4 "$p_list_pckg_ids" $g_status_crendential_storage $l_flag_upgrade_os
        l_status=$?
    fi

    # Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
        g_status_crendential_storage=0
    # Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi

    return 0

}



# Instalar programas del sistema basicos (comandos del sistema) usando respositorios donde se desacargan estos.
# > Parametros de entrada
# > Parametros de salida
#    0> Se instala el programam
#    1> No se instala ningun programa (no se cumple las precondiciones)
function _setup_basic_system_cmd() {

    #1. Argumentos
    local p_input_options=$1


    #2. Validar si se puede instalar
    if [ $p_input_options -le 0 ]; then
        return 1
    fi

    # Validar si la opcion esta habilitada
    local l_option=4
    if [ $(( $p_input_options & $l_option )) -ne $l_option ]; then
        return 1
    fi


    # Solo lo puede instalar root
    if [ $g_runner_sudo_support -eq 2 ] || [ $g_runner_sudo_support -eq 3 ]; then

        printf '%bSe requiere acceso a root%b para instalar "%bcomandos basicos%b" en el SO.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" \
               "$g_color_reset"
        return 1

    fi

    #3. Descargar e configurar los comandos basicos (usar un grupo de comandos especifico)
    local l_status
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    # Mostrar el titulo de instalacion
    printf '\n'
    print_line '─' $g_max_length_line  "$g_color_blue1"
    if [ $g_os_subtype_id -eq 1 ]; then
        printf "> %bSystem Programs >%b Instalando %bcomandos%b: '%bbat, jq, yq, ripgrep, delta, oh-my-posh, fd, zoxide y eza%b.'\n" "$g_color_gray1" "$g_color_reset" \
                "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    else
        printf "> %bSystem Programs >%b Instalando %bcomandos%b: '%bfzf, bat, jq, yq, ripgrep, delta, oh-my-posh, fd, zoxide y eza%b.'\n" "$g_color_gray1" "$g_color_reset" \
               "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    fi
    print_line '─' $g_max_length_line "$g_color_blue1"

    # Parametros usados por el script:
    #  1> Tipo de llamado: 1/3 (sin menu interactivo/no-interactivo).
    #  2> Opciones de menu a ejecutar: entero positivo.
    #  3> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git.
    #  4> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    #  5> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado
    #     "/var/opt/tools" o "~/tools".
    #  6> Ruta base donde se almacena los comandos ("LNX_BASE_PATH/bin"), archivos man1 ("LNX_BASE_PATH/man/man1") y fonts ("LNX_BASE_PATH/share/fonts").
    #  7> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    #  8> El estado de la credencial almacenada para el sudo.
    #  9> Install only last version: por defecto es 1 (representa a 'false'). Solo si su valor es 0 representa a 'true'.
    # 11> Flag para filtrar el listado de repositorios segun el tipo de progrmas. '0' solo programas del usuario, '1' solo programas que no son de usuario.
    #     Otro valor, no hay filtro. Valor por defecto es '2'.
    # 12> Flag '0' si desea almacenar la ruta de programas elegido en '/tmp/prgpath.txt'. Por defecto es '1'.
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 1 4 "$g_targethome_path" "$g_repo_name" "$g_tools_path" "$g_lnx_base_path" \
            "$g_temp_path" $g_status_crendential_storage 0
        l_status=$?
    else
        ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 3 4 "$g_targethome_path" "$g_repo_name" "$g_tools_path" "$g_lnx_base_path" \
            "$g_temp_path" $g_status_crendential_storage 0
        l_status=$?
    fi

    # Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    # Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi

    return 0

}


# Instalar programas del sistema/usuario descargando archivos de repositorios externos.
#   > Los programas de sistema se instalan en rutas reservadas del sistema y el owner siempre es root.
#   > Los programas de usuario NO se instalan en rutas reservadas del sistema y el owner puede ser root u otro usuario.
# > Parametros de entrada
#    1> Flag '0' si es un programa de usuario y '1' si no es un programa del usuario (programa de sistema, system font, os package, custom).
#    3> Lista de opciones de ID del programa a instalar.
#    2> Opcionalmente la opciones de instalacion (solo usuado si se instala programas de usuario)
# > Parametros de salida
#    0> Se instala el programam
#    1> No se instala ningun programa (no se cumple las precondiciones)
function _setup_programs() {

    #1. Argumentos
    local p_flag_user_prgs=1
    if [ "$1" = "0" ]; then
        p_flag_user_prgs=0
    fi

    local p_list_repo_ids=""
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        p_list_repo_ids="$2"
    fi

    local p_input_options=0
    if [ ! -z "$3" ]; then
        p_input_options=$3
    fi


    #2. Adicionar programas de usuario adicionales
    if [ $p_flag_user_prgs -eq 0 ] && [ $p_input_options -gt 0 ]; then

        #LSP/DAP de Java: jdtls
        local l_option=1024
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

            if [[ ! $p_list_repo_ids =~ ,jdtls$ ]] && [[ ! $p_list_repo_ids =~ ,jdtls, ]] && [[ ! $p_list_repo_ids =~ ^jdtls, ]]; then
                if [ -z "$p_list_repo_ids" ]; then
                    p_list_repo_ids="jdtls"
                else
                    p_list_repo_ids="${p_list_repo_ids},jdtls"
                fi
            fi

        fi

        #LSP/DAP de .NET : roslyn,netcoredbg
        l_option=512
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

            if [[ ! $p_list_repo_ids =~ ,omnisharp-ls$ ]] && [[ ! $p_list_repo_ids =~ ,omnisharp-ls, ]] && [[ ! $p_list_repo_ids =~ ^omnisharp-ls, ]]; then
                if [ -z "$p_list_repo_ids" ]; then
                    p_list_repo_ids="omnisharp-ls"
                else
                    p_list_repo_ids="${p_list_repo_ids},omnisharp-ls"
                fi
            fi

            if [[ ! $p_list_repo_ids =~ ,netcoredbg$ ]] && [[ ! $p_list_repo_ids =~ ,netcoredbg, ]] && [[ ! $p_list_repo_ids =~ ^netcoredbg, ]]; then
                if [ -z "$p_list_repo_ids" ]; then
                    p_list_repo_ids="netcoredbg"
                else
                    p_list_repo_ids="${p_list_repo_ids},netcoredbg"
                fi
            fi

        fi

    fi

    #3. Validaciones
    if [ -z "$p_list_repo_ids" ]; then
        return 1
    fi

    # Si se instala programas del sistema (fuente, paquete de SO y custom), requiere se root
    if [ $p_flag_user_prgs -ne 0 ]; then

        # Solo lo puede instalar root
        if [ $g_runner_sudo_support -eq 2 ] || [ $g_runner_sudo_support -eq 3 ]; then

            printf '%bSe requiere acceso a root%b para instalar paquete del SO "%b%s%b".\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" \
                   "$g_default_list_package_ids" "$g_color_reset"
            return 1

        fi

    fi

    # Si se instala programas del usuario
    # No validar?


    #4. Descargar y configurar una lista de repositorios de comandos adicionales a instalar (segun una lista de ID de repositorios)
    local l_is_noninteractive=1
    local l_status
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    #Mostrar el titulo de instalacion
    printf '\n'
    print_line '─' $g_max_length_line  "$g_color_blue1"

    if [ $p_flag_user_prgs -ne 0 ]; then
        printf "> %bSystem Programs >%b Instalando %bprogramas%b de: '%b%s%b'\n" "$g_color_gray1" "$g_color_reset" \
               "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "${p_list_repo_ids//,/, }" "$g_color_reset"
    else
        printf "> %bUser Programs >%b Instalando %bprogramas%b de: '%b%s%b'\n" "$g_color_gray1" "$g_color_reset" \
               "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "${p_list_repo_ids//,/, }" "$g_color_reset"
    fi

    print_line '─' $g_max_length_line "$g_color_blue1"

    #Parametros del script usados hasta el momento:
    # 1> Tipo de llamado: 2/4 (sin menu interactivo/no-interactivo).
    # 2> Listado de ID del repositorios a instalar separados por coma.
    # 3> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git.
    # 4> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    # 5> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado
    #    "/var/opt/tools" o "~/tools".
    # 6> Ruta base donde se almacena los comandos ("LNX_BASE_PATH/bin"), archivos man1 ("LNX_BASE_PATH/share/man/man1") y fonts ("LNX_BASE_PATH/share/fonts").
    # 7> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    # 8> El estado de la credencial almacenada para el sudo.
    # 9> Install only last version: por defecto es 1 (false). Solo si ingresa 0, se cambia a 0 (true).
    #10> Flag '0' para mostrar un titulo si se envia un repositorio en el parametro 2. Por defecto es '1'
    #11> Flag para filtrar el listado de repositorios segun el tipo de progrmas. '0' solo programas del usuario, '1' solo programas que no son de usuario.
    #    Otro valor, no hay filtro. Valor por defecto es '2'.
    #12> Flag '0' si desea almacenar la ruta de programas elegido en '/tmp/prgpath.txt'. Por defecto es '1'.
    if [ $l_is_noninteractive -eq 1 ]; then

        ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 2 "$p_list_repo_ids" "$g_targethome_path" "$g_repo_name" "$g_tools_path" \
            "$g_lnx_base_path" "$g_temp_path" $g_status_crendential_storage 0 1 $p_flag_user_prgs
        l_status=$?
    else
        ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 4 "$p_list_repo_ids" "$g_targethome_path" "$g_repo_name" "$g_tools_path" \
            "$g_lnx_base_path" "$g_temp_path" $g_status_crendential_storage 0 1 $p_flag_user_prgs
        l_status=$?
    fi

    #Si se omitido la instalacion de todos los repositorios
    if [ $l_status -eq 118 ]; then
        return 1
    #Si no se acepto almacenar credenciales
    elif [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    #Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi

    return 0

}




function _setup_system_tools() {

    #1. Argumentos
    local p_options=$1

    if [ $p_options -le 0 ]; then
        return 1
    fi


    #2. Determinar opciones validas
    local l_flag_setup_vim=1
    local l_flag_setup_python=1

    local l_option=8
    if [ $(( $p_options & $l_option )) -eq $l_option ]; then
        l_flag_setup_vim=0
    fi

    l_option=16
    if [ $(( $p_options & $l_option )) -eq $l_option ]; then
        l_flag_setup_python=0
    fi

    #echo "p_options=${p_options}"

    # Si no se tiene opocion para instalar
    if [ $l_flag_setup_vim -ne 0 ] && [ $l_flag_setup_python -ne 0 ]; then
        return 1
    fi

    # Solo lo puede instalar root
    if [ $g_runner_sudo_support -eq 2 ] || [ $g_runner_sudo_support -eq 3 ]; then

        printf '%bSe requiere acceso a root%b para instalar paquete del SO "%b%s%b".\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" \
               "$g_default_list_package_ids" "$g_color_reset"
        return 1

    fi

    #3. Instalar programas de sistemas: ptyhon, vim
    local l_aux=''

    # Etiqueta para el titulo
    if [ $l_flag_setup_python -eq 0 ]; then

        if [ -z "$l_aux" ]; then
            printf -v l_aux '%b%s%b, %b%s%b, %b%s%b' "$g_color_blue1" "python" "$g_color_reset" "$g_color_blue1" "pip" "$g_color_reset" \
                   "$g_color_blue1" "pipx" "$g_color_reset"

        else
            printf -v l_aux '%b, %b%s%b, %b%s%b, %b%s%b' "$l_aux" "$g_color_blue1" "python" "$g_color_reset" "$g_color_blue1" "pip" "$g_color_reset" \
                   "$g_color_blue1" "pipx" "$g_color_reset"
        fi

    fi

    if [ $l_flag_setup_vim -eq 0 ]; then

        if [ -z "$l_aux" ]; then
            printf -v l_aux '%b%s%b' "$g_color_blue1" "vim" "$g_color_reset"
        else
            printf -v l_aux '%b, %b%s%b' "$l_aux" "$g_color_blue1" "vim" "$g_color_reset"
        fi

    fi

    # Mostrar el titulo
    if [ ! -z "$l_aux" ]; then

        #Mostrar el titulo de instalacion
        printf '\n'
        print_line '─' $g_max_length_line  "$g_color_blue1"

        printf "> %bSystem Programs >%b Instalando %btools%b: %b\n" "$g_color_gray1" "$g_color_reset" \
               "$g_color_cian1" "$g_color_reset" "$l_aux"

        print_line '─' $g_max_length_line "$g_color_blue1"

    fi

    # Instalar programnas del sistema: Python y sus gestores de paquetes Pip/Pix
    local l_status
    if [ $l_flag_setup_python -eq 0 ]; then

        install_python 1
        l_status=$?

        # Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
            g_status_crendential_storage=0
        # Si no se paso las precondiciones iniciales
        elif [ $l_status -eq 111 ]; then
            return $l_status
        fi

    fi

    # Instalar programnas del sistema: VIM
    if [ $l_flag_setup_vim -eq 0 ]; then

        install_vim 1
        l_status=$?

        # Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
            g_status_crendential_storage=0
        # Si no se paso las precondiciones iniciales
        elif [ $l_status -eq 111 ]; then
            return $l_status
        fi

    fi


    return 0

}





function _setup_user_tools() {

    #1. Argumentos
    local p_options=$1

    if [ $p_options -le 0 ]; then
        return 1
    fi

    #2. Determinar opciones validas
    local l_flag_setup_nvim=1
    local l_flag_setup_nodejs=1
    local l_flag_setup_basic_pcks=1
    local l_flag_setup_extra_pcks=1

    local l_option=32
    if [ $(( $p_options & $l_option )) -eq $l_option ]; then
        l_flag_setup_nvim=0
    fi

    l_option=64
    if [ $(( $p_options & $l_option )) -eq $l_option ]; then
        l_flag_setup_nodejs=0
    fi

    l_option=128
    if [ $(( $p_options & $l_option )) -eq $l_option ]; then
        l_flag_setup_basic_pcks=0
    fi

    l_option=256
    if [ $(( $p_options & $l_option )) -eq $l_option ]; then
        l_flag_setup_extra_pcks=0
    fi


    # Si no se tiene opocion para instalar
    if [ $l_flag_setup_nvim -ne 0 ] && [ $l_flag_setup_nodejs -ne 0 ] && [ $l_flag_setup_basic_pcks -ne 0 ] && [ $l_flag_setup_extra_pcks -ne 0 ]; then
        return 1
    fi


    #3. Instalar programas de usuarios: nodejs, nvim
    local l_aux=''

    # Etiqueta para el titulo
    if [ $l_flag_setup_nodejs -eq 0 ]; then

        if [ -z "$l_aux" ]; then
            printf -v l_aux '%b%s%b' "$g_color_blue1" "nodejs" "$g_color_reset"
        else
            printf -v l_aux '%b, %b%s%b' "$l_aux" "$g_color_blue1" "nodejs" "$g_color_reset"
        fi

    fi


    if [ $l_flag_setup_nvim -eq 0 ]; then

        if [ -z "$l_aux" ]; then
            printf -v l_aux '%b%s%b' "$g_color_blue1" "neovim" "$g_color_reset"
        else
            printf -v l_aux '%b, %b%s%b' "$l_aux" "$g_color_blue1" "neovim" "$g_color_reset"
        fi

    fi


    # Validar y mostrar el titulo
    if [ ! -z "$l_aux" ]; then

        # Solo lo puede instalar ...
        #if [ $g_runner_sudo_support -eq 2 ] || [ $g_runner_sudo_support -eq 3 ]; then

        #    printf '%bSe requiere acceso a root%b para instalar paquete del SO "%b%s%b".\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" \
        #           "$g_default_list_package_ids" "$g_color_reset"
        #    return 1

        #fi

        #Considerar que se instalan paquetes de SO, ello permitirá limpiar el cache de paquete descargados.
        if [ $l_exist_packages_installed -ne 0 ]; then
            l_exist_packages_installed=0
        fi

        #Mostrar el titulo de instalacion
        printf '\n'
        print_line '─' $g_max_length_line  "$g_color_blue1"

        printf "> %bUser Programs >%b Instalando %btools%b: %b\n" "$g_color_gray1" "$g_color_reset" \
               "$g_color_cian1" "$g_color_reset" "$l_aux"

        print_line '─' $g_max_length_line "$g_color_blue1"

    fi

    # Instalar programnas del Usuario: NodeJS
    local l_is_nodejs_installed=-1   #(-1) No determinado, (0) Instalado, (1) No instalado
    local l_status
    if [ $l_flag_setup_nodejs -eq 0 ]; then

        install_nodejs 1 "$g_tools_path"
        l_status=$?

        # Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
            g_status_crendential_storage=0
        # Si no se paso las precondiciones iniciales
        elif [ $l_status -eq 111 ]; then
            return $l_status
        fi

        if [ $l_status -eq 0 ]; then
            l_is_nodejs_installed=0
        else
            l_is_nodejs_installed=1
        fi
    fi



    # Instalar programnas del Usuario: NoeVIM
    if [ $l_flag_setup_nvim -eq 0 ]; then

        install_neovim 1 "$g_tools_path"
        l_status=$?

        # Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
            g_status_crendential_storage=0
        # Si no se paso las precondiciones iniciales
        elif [ $l_status -eq 111 ]; then
            return $l_status
        fi

    fi


    #3. Instalar programas de usuarios: paquetes globales de nodejs

    # Si no se tiene opciones a instalar
    if [ $l_flag_setup_basic_pcks -ne 0 ] && [ $l_flag_setup_extra_pcks -ne 0 ]; then
        return 0
    fi

    # Si aun se desconoce si nodejs, determinar si nodejs esta instalado
    local l_version
    if [ $l_is_nodejs_installed -eq -1 ]; then

        #Validar si 'node' esta instalado (puede no esta en el PATH)
        l_version=$(get_nodejs_version "$g_tools_path")
        l_status=$?

        if [ $l_status -eq 3 ]; then
            l_is_nodejs_installed=1
        else
            l_is_nodejs_installed=0
        fi

    fi

    # Validar si nodejs esta instalado
    if [ $l_is_nodejs_installed -eq 1 ]; then
        printf 'NodeJS > %bNodeJS%b NO esta instalado o NO esta el PATH del usuario. Ello es requerido para instalar los paquetes.\n' \
               "$g_color_red1" "$g_color_reset"
        return 1
    fi

    # Validar que el runner es root el modo suplantacion del usuario objetivo
    if [ $g_runner_is_target_user -ne 0 ]; then

        printf 'NodeJS > La instalación de paquetes de NodeJS globales lo tiene que ejecutar con el usuario "%b%s%b".\n' \
               "$g_color_gray1" "$g_targethome_owner" "$g_color_yellow1"

        return 1
    fi

    # Validar que el owner del folder de nodejs puede instalar paquetes globales para no generar problemas en los permisos.
    local l_owner_nodejs
    l_owner_nodejs=$(get_owner_of_nodejs "$g_tools_path")
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf 'NodeJS > No se pueden obtener el owner del folder de "%bNodeJS%b".\n' "$g_color_gray1" "$g_color_reset"
        return 1
    fi

    if [ "$g_runner_user" != "$l_owner_nodejs" ]; then
        printf 'NodeJS > No se debe instalar paquetes globales en "%b%s%b" usando como usuario "%b%s%b". Lo debe realizar el owner "%b%s%b".\n' \
               "$g_color_gray1" "$l_nodejs_bin_path" "$g_color_reset" "$g_color_gray1" "$g_runner_user" "$g_color_reset" \
               "$g_color_gray1" "$l_owner_nodejs" "$g_color_reset"
        return 1
    fi


    # Etiqueta para el titulo
    #  (6) NodeJS > Instalar paquetes globales basicos:
    #  (7) NodeJS > Instalar paquetes globales sobre LSP/DAP:
    #  (8) NodeJS > Instalar paquetes globales otros:
    local l_prg_options=0
    l_aux=''

    if [ $l_flag_setup_basic_pcks -eq 0 ]; then

        ((l_prg_options = l_prg_options + ${ga_options_others[6]}))
        if [ -z "$l_aux" ]; then
            printf -v l_aux '%b%s%b node package' "$g_color_blue1" "basic" "$g_color_reset"
        else
            printf -v l_aux '%b, %b%s%b node package' "$l_aux" "$g_color_blue1" "basic" "$g_color_reset"
        fi

    fi

    if [ $l_flag_setup_extra_pcks -eq 0 ]; then

        ((l_prg_options = l_prg_options + ${ga_options_others[7]} + ${ga_options_others[8]}))
        if [ -z "$l_aux" ]; then
            printf -v l_aux '%b%s%b node package' "$g_color_blue1" "extra" "$g_color_reset"
        else
            printf -v l_aux '%b, %b%s%b node package' "$l_aux" "$g_color_blue1" "extra" "$g_color_reset"
        fi

    fi

    # Mostrar el titulo de instalacion
    printf '\n'
    print_line '─' $g_max_length_line  "$g_color_blue1"

    printf "> %bUser Programs >%b Instalando %bNodeJS packages%b: %b\n" "$g_color_gray1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$l_aux"

    print_line '─' $g_max_length_line "$g_color_blue1"


    # Instalar paquetes de NodeJS
    l_status=0
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    #Parametros usados por el script:
    # 1> Tipo de configuración: 1/2 (instalación sin un menu interactivo/no-interactivo).
    # 2> Opciones de menu a ejecutar: entero positivo.
    # 3> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git.
    # 4> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    # 5> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git.
    # 6> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    # 7> El estado de la credencial almacenada para el sudo.
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_shell_path}/bash/bin/linuxsetup/04_install_profile.bash 1 $l_prg_options "$g_targethome_path" "$g_repo_name" \
            $g_status_crendential_storage
        l_status=$?
    else
        ${g_shell_path}/bash/bin/linuxsetup/04_install_profile.bash 2 $l_prg_options "$g_targethome_path" "$g_repo_name" \
            $g_status_crendential_storage
        l_status=$?
    fi


    #Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
        g_status_crendential_storage=0
    #Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi

    return 0

}




# Configurar archivos del home del usuario
# > Parametros de entrada
# > Parametros de salida
#    0> Se instala el programam
#    1> No se instala ningun programa (no se cumple las precondiciones)
function _setup_user_profile() {

    #1. Argumentos
    local p_input_options=$1


    #2. Validaciones
    if [ $p_input_options -le 0 ]; then
        return 1
    fi

    #3. Determinar las opciones elegidas por el usuario

    # Opciones generales usando 'ga_options_others'
    #     (0) Configurar archivos del profile del usuario actual
    #     (1) Flag para overwrite symbolic link en caso de existir
    #     (2) Flag para overwrite file en caso de existir
    #     (3) Python > Instalar paquetes de usuario basicos
    #     (4) Python > Instalar paquetes de usuario sobre LSP/DAP
    #     (5) Python > Instalar paquetes de usuario otros
    local -a la_options_others=(1 1 1 1 1 1)

    # > Crear archivos del profile del usuario
    l_option=2048
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_others[0]=0
    fi

    # > Flag overwrite symbolic link en caso de existir
    l_option=4096
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_others[1]=0
    fi

    # > Flag overwrite file en caso de existir
    l_option=8192
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_others[2]=0
    fi

    # > Instalar paquetes del usuario basicos
    l_option=4194304
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_others[3]=0
    fi

    # > Instalar paquetes del usuario adicionales
    l_option=8388608
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_others[4]=0
        la_options_others[5]=0
    fi


    # Opciones para configurar VIM/NeoVIM usando 'ga_options_vim' y 'ga_options_nvim'
    #     (0) Flag para configurar el modo developer
    #     (1) Configuración: Crear los archivos de configuración
    #     (2) Configuración: Descargar los plugins e indexar su documentación
    #     (3) Configuración: Descargar los plugins sin indexar su documentación
    #     (4) Indexar la documentación de los plugins existentes
    local -a la_options_vim=(1 1 1 1 1)
    local -a la_options_nvim=(1 1 1 1 1)

    # > VIM > Flag para configurar el modo developer
    l_option=16384
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_vim[0]=0
    fi

    # > VIM > Descargar plugins
    l_option=32768
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_vim[3]=0
    fi

    # > VIM > Crear config files e indexar plugins existentes
    l_option=65536
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_vim[1]=0
        la_options_vim[4]=0
    fi

    # > VIM > Crear config files, Descargar plugins e indexarlos
    l_option=131072
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_vim[1]=0
        la_options_vim[2]=0
    fi


    # > NeoVIM > Flag para configurar el modo developer
    l_option=262144
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_vim[0]=0
    fi

    # > NeoVIM > Descargar plugins
    l_option=524288
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_vim[3]=0
    fi

    # > NeoVIM > Crear config files e indexar plugins existentes
    l_option=1048576
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_vim[1]=0
        la_options_vim[4]=0
    fi

    # > NeoVIM > Crear config files, Descargar plugins e indexarlos
    l_option=2097152
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        la_options_vim[1]=0
        la_options_vim[2]=0
    fi




    #4. Determinar el valor de estas las opciones elegidas
    local l_i=0
    local l_prg_options=0
    local l_info='Se realizara las siguientes configuraciones en el profile:'

    for (( l_i = 0; l_i < 6; l_i++ )); do

        if [ ${la_options_others[${l_i}]} -ne 0 ]; then
            continue
        fi

        ((l_prg_options= l_prg_options + ${ga_options_others[${l_i}]}))
        printf -v l_info '%s\n   > %b%b%b %b(opción de "04_install_profile": %s)%b' "$l_info" "$g_color_gray1" "${ga_title_others[${l_i}]}" \
               "$g_color_reset" "$g_color_gray1" "${ga_options_others[${l_i}]}" "$g_color_reset"

    done

    for (( l_i = 0; l_i < ${#ga_options_vim[@]}; l_i++ )); do

        if [ ${la_options_vim[${l_i}]} -ne 0 ]; then
            continue
        fi

        ((l_prg_options= l_prg_options + ${ga_options_vim[${l_i}]}))
        printf -v l_info '%s\n   > %bVIM     >%b %b%s%b %b(opción de "04_install_profile": %s)%b' "$l_info" "$g_color_gray1" "$g_color_reset" \
               "$g_color_blue1" "${ga_title_config[${l_i}]}" "$g_color_reset" "$g_color_gray1" "${ga_options_vim[${l_i}]}" "$g_color_reset"

    done

    for (( l_i = 0; l_i < ${#ga_options_nvim[@]}; l_i++ )); do

        if [ ${la_options_nvim[${l_i}]} -ne 0 ]; then
            continue
        fi

        ((l_prg_options= l_prg_options + ${ga_options_nvim[${l_i}]}))
        printf -v l_info '%s\n   > %bNeoVIM  >%b %b%s%b %b(opción de "04_install_profile": %s)%b' "$l_info" "$g_color_gray1" "$g_color_reset" \
            "$g_color_blue1" "${ga_title_config[${l_i}]}" "$g_color_reset" "$g_color_gray1" "${ga_options_nvim[${l_i}]}" "$g_color_reset"

    done


    # Validar si tiene opciones a configurar
    if [ $l_prg_options -le 0 ]; then
        return 1
    fi

    #5. Instalar/Configurar el profile
    local l_status
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi


    #Mostrar el titulo de instalacion
    printf '\n'
    print_line '─' $g_max_length_line  "$g_color_blue1"
    printf "> Configurando el profile del usuario\n"
    print_line '─' $g_max_length_line "$g_color_blue1"
    printf '%b\n' "$l_info"

    #Parametros usados por el script:
    # 1> Tipo de configuración: 1/2 (instalación sin un menu interactivo/no-interactivo).
    # 2> Opciones de menu a ejecutar: entero positivo.
    # 3> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git.
    # 4> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    # 5> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git.
    # 6> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    # 7> El estado de la credencial almacenada para el sudo.
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_shell_path}/bash/bin/linuxsetup/04_install_profile.bash 1 $l_prg_options "$g_targethome_path" "$g_repo_name" \
            $g_status_crendential_storage
        l_status=$?
    else
        ${g_shell_path}/bash/bin/linuxsetup/04_install_profile.bash 2 $l_prg_options "$g_targethome_path" "$g_repo_name" \
            $g_status_crendential_storage
        l_status=$?
    fi


    #Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
        g_status_crendential_storage=0
    #Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi

    return 0

}



#
#Parametros de entrada (Argumentos):
# 1> Opciones de menu a ejecutar: entero positivo.
# 2> ID de los repositorios de comandos a configurar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".
# 3> ID de los paquetes del repositorio del SO a instalar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".
#    Si envia "DEFAULT" se instalará paquete basicos por defecto que son: Curl, UnZip, OpenSSL y Tmux.
# 4> Flag '0' para limpiar el cache de paquetes del sistema operativo. Caso contrario, use 1.
# 5> Actualizar los paquetes del SO. Por defecto es 1 (false), si desea actualizar use 0.
function g_install_options() {

    #1. Argumentos
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    local p_list_repo_ids=""
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        p_list_repo_ids="$2"
    fi

    local p_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$3" ]; then
        p_list_pckg_ids="$3"
    fi

    local p_flag_clean_os_cache=1
    if [ "$4" = "0" ]; then
        p_flag_clean_os_cache=0
    fi


    #2.Inicialización
    local l_status

    # Flag '0' cuando no se realizo ninguna instalacion de paquetes
    local l_exist_packages_installed=1



    #3. Instalar paquetes del SO
    _setup_os_package $p_input_options "$p_list_pckg_ids"
    l_status=$?

    # Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
        g_status_crendential_storage=0
    # Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi

    if [ "$l_status" -ne 1 ]; then
        l_exist_packages_installed=0
    fi



    #4. Instalar programnas del sistema: comandos basicos
    _setup_basic_system_cmd $p_input_options
    l_status=$?

    # Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
        g_status_crendential_storage=0
    # Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi



    #5. Instalar programnas del sistema, fuentes, paquetes OS y custom
    _setup_programs 1 "$p_list_repo_ids"
    l_status=$?

    # Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
        g_status_crendential_storage=0
    # Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi



    #6. Instalar programnas del usuario
    _setup_programs 0 "$p_list_repo_ids" $p_input_options
    l_status=$?

    # Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
        g_status_crendential_storage=0
    # Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi



    #6. Instalar tools: Python, Vim
    _setup_system_tools $p_input_options
    l_status=$?

    # Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
        g_status_crendential_storage=0
    # Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi



    #6. Instalar tools: NodeJS, NeoVIM
    _setup_user_tools $p_input_options
    l_status=$?

    # Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
        g_status_crendential_storage=0
    # Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi



    #7. Configurar el profile del usuario
    _setup_user_profile $p_input_options
    l_status=$?

    # Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    # Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
        g_status_crendential_storage=0
    # Si no se paso las precondiciones iniciales
    elif [ $l_status -eq 111 ]; then
        return $l_status
    fi



    #8. Limpiar el cache, si se instalo paquetes
    if [ $p_flag_clean_os_cache -eq 0 ] && [ $l_exist_packages_installed -eq 0 ]; then
        printf '\n%bClean packages cache%b...\n' "$g_color_gray1" "$g_color_reset"
        clean_os_cache $g_os_subtype_id $l_is_noninteractive
    fi



    #9. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #   Si no se invoca usando el menú y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi

    return 0

}



function _show_menu_install_core() {

    #0. Parametros
    local l_repo_ids="$1"
    if [ ! -z "$l_repo_ids" ]; then
        l_repo_ids="${1//,/, }"
    fi

    local l_pckg_ids="${2//,/, }"

    #1. Menu
    print_text_in_center "Menu de Opciones (Install/Configuration)" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"

    local l_max_digits=8


    printf " ( ) Programas del sistema %b(fuera del home del usuario y el owner es root)%b:\n" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > Actualizar %bpaquetes existes%b del SO\n" "$g_color_green1" "1" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > Instalar %bpaquetes basicos%b: %b%s (modificado segun parametro)%b\n" "$g_color_green1" "2" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$l_pckg_ids" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > Instalar %bcomandos basicos%b %b(opcion 4 de 01_setup_binaries.bash)%b\n" "$g_color_green1" \
           "4" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > %bVIM%b    > Instalar VIM\n" "$g_color_green1" "8" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bDeveloper%b > %bPython%b > Instalar Python y sus gestores pip y pipx\n" "$g_color_green1" "16" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"



    printf " ( ) Programas global del usuario %b(fuera de home del usuario, owner puede ser root)%b:\n" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > %bNeoVIM%b > Instalar NeoVIM\n" "$g_color_green1" "32" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bDeveloper%b > %bNodeJS%b > Instalar NodeJS\n" "$g_color_green1" "64" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bDeveloper%b > %bNodeJS%b > Instalar paquetes globales basicos\n" "$g_color_green1" "128" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bDeveloper%b > %bNodeJS%b > Instalar paquetes globales adicionales\n" "$g_color_green1" "256" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bDeveloper%b > %bOtros%b  > LSP/DAP de .NET: %bOmnisharp-Roslyn, NetCoreDbg%b\n" "$g_color_green1" "512" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bDeveloper%b > %bOtros%b  > LSP/DAP de Java: %bEclipse JDT LS%b\n" "$g_color_green1" "1024" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"


    printf " ( ) Setup a nivel usuario %b(siempre estan en el home del usuario)%b:\n" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > Crear %barchivos del profile%b del usuario\n" "$g_color_green1" "2048" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > Flag %boverwrite symbolic link%b en caso de existir\n" "$g_color_green1" "4096" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > Flag %boverwrite file%b en caso de existir\n" "$g_color_green1" "8192" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"

    printf "     (%b%${l_max_digits}d%b) %bDeveloper%b > %bVIM%b    > Flag para configurar el modo developer\n" "$g_color_green1" "16384" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > %bVIM%b    > Descargar plugins\n" "$g_color_green1" "32768" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > %bVIM%b    > Crear config files e indexar plugins existentes\n" "$g_color_green1" "65536" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > %bVIM%b    > Crear config files, Descargar plugins e indexarlos\n" "$g_color_green1" "131072" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bDeveloper%b > %bNeoVIM%b > Flag para configurar el modo developer\n" "$g_color_green1" "262144" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > %bNeoVIM%b > Descargar plugins\n" "$g_color_green1" "524288" "$g_color_reset" "$g_color_gray1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > %bNeoVIM%b > Crear config files e indexar plugins existentes\n" "$g_color_green1" "1048576" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > %bNeoVIM%b > Crear config files, Descargar plugins e indexarlos\n" "$g_color_green1" "2097152" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"


    printf "     (%b%${l_max_digits}d%b) %bDeveloper%b > %bPython%b > Instalar paquetes del usuario basicos\n" "$g_color_green1" "4194304" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) %bDeveloper%b > %bPython%b > Instalar paquetes del usuario adicionales\n" "$g_color_green1" "8388608" \
           "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"


    printf " (0) Programas adicionales de %busuario%b/%bsistema%b que siempre se instalarán:\n" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

    if [ -z "$l_repo_ids" ]; then
        printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > %bNingun%b programa adicional se instalará\n" "$g_color_green1" "0" \
               "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    else
        printf "     (%b%${l_max_digits}d%b) %bGeneral%b   > Programas: %b%s%b\n" "$g_color_green1" "0" \
               "$g_color_reset" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$l_repo_ids"  "$g_color_reset"
    fi

    print_line '-' $g_max_length_line "$g_color_gray1"

}


function g_install_main() {

    #0. Parametros
    local p_list_repo_ids="$1"

    local p_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$2" ]; then
        p_list_pckg_ids="$2"
    fi

    p_flag_clean_os_cache=1
    if [ "$3" = "0" ]; then
        p_flag_clean_os_cache=0
    fi

    #1. Pre-requisitos

    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_green1"
    _show_menu_install_core "$p_list_repo_ids" "$p_list_pckg_ids"

    #3. Mostar la ultima parte del menu y capturar la opcion elegida
    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -er l_options

        case "$l_options" in

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1"
                ;;


            0)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_gray1"
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then

                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_green1"

                    g_install_options $l_options "$p_list_repo_ids" "$p_list_pckg_ids" $p_flag_clean_os_cache

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





#Codigo Global {{{

g_usage() {

    printf 'Usage:\n'
    printf '  > %bInstalar repositorios mostrando el menú de opciones (interactivo)%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash 0 LIST_REPO_IDS LIST_PCKG_IDS TARGET_HOME_PATH REPO_NAME MY_TOOLS_PATH LNX_BASE_PATH TEMP_PATH CLEAN-OS-CACHE\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un grupo de opciones sin mostrar el menú%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash CALLING_TYPE MENU_OPTIONS\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash CALLING_TYPE MENU_OPTIONS LIST_REPO_IDS LIST_PCKG_IDS TARGET_HOME_PATH REPO_NAME MY_TOOLS_PATH LNX_BASE_PATH TEMP_PATH\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash CALLING_TYPE MENU_OPTIONS LIST_REPO_IDS LIST_PCKG_IDS TARGET_HOME_PATH REPO_NAME MY_TOOLS_PATH LNX_BASE_PATH TEMP_PATH SUDO_STORAGE_OPTIONS CLEAN-OS-CACHE\n\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bCALLING_TYPE%b es 1 si es interactivo y 2 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bMENU_OPTIONS%b Las opciones de menu a instalar. Si no desea especificar coloque 0.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bLIST_REPO_IDS %bID de los repositorios de comandos a configurar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bLIST_PCKG_IDS %b.ID de los paquetes del repositorio del SO, separados por coma, a instalar si elige la opcion de menu 1024. Si desea usar el los los paquetes por defecto envie "EMPTY".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bLos paquete basicos por defecto que son: Curl, UnZip, OpenSSL y Tmux.%b\n' "$g_color_gray1" "$g_color_reset"
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
    printf '  > %bMY_TOOLS_PATH %bes la ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado "/var/opt/tools" o "~/tools".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bLNX_BASE_PATH %bes ruta base donde se almacena los comandos ("LNX_BASE_PATH/bin"), archivos man1 ("LNX_BASE_PATH/man/man1") y fonts ("LNX_BASE_PATH/share/fonts"). Si se envia vacio o EMPTY se usara el directorio predeterminado:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '      %b> Comandos      : "/usr/local/bin"            (para todos los usuarios) y "~/.local/bin"         (solo para el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '      %b> Archivos man1 : "/usr/local/share/man/man1" (para todos los usuarios) y "~/.local/share/man/man1"    (solo para el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '      %b> Archivo fuente: "/usr/local/share/fonts"    (para todos los usuarios) y "~/.local/share/fonts" (solo para el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bTEMP_PATH %bes la ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado "/tmp".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bSUDO_STORAGE_OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi es root por lo que no se requiere almacenar la credenciales, use 2. Caso contrario, use 0 si se almaceno la credencial y 1 si no se pudo almacenar las credenciales.%b\n' \
           "$g_color_gray1" "$g_color_reset"
    printf '  > %bCLEAN-OS-CACHE%b es 0 si se limpia el cache de paquetes instalados. Por defecto es 1.%b\n\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}




#}}}



#------------------------------------------------------------------------------------------------------------------
#> Logica principal del script {{{
#------------------------------------------------------------------------------------------------------------------

#1. Variables de los argumentos del script

#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución mostrando el menu del opciones (siempre es interactiva).
                        #(1) Ejecución sin el menu de opciones, interactivo - instalar/actualizar un conjunto de repositorios
                        #(2) Ejecución sin el menu de opciones, no interactivo - instalar/actualizar un conjunto de repositorios

#Argumento 1: Indica el tipo de invocación
if [ -z "$1" ]; then
    gp_type_calling=0
else
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        g_usage
        exit 0
    elif [[ "$1" =~ ^[0-9]+$ ]]; then
        gp_type_calling=$1
    else
        printf 'Argumentos invalidos.\n\n'
        g_usage
        exit 110
    fi
fi

if [ $gp_type_calling -lt 0 ] || [ $gp_type_calling -gt 2 ]; then
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 110
fi


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

#Ruta del home del usuario OBJETIVO al cual se configurara su profile y donde esta el repositorio git.
#Este valor se obtendra segun orden prioridad:
# - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
# - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
# - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
# - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
g_targethome_path=''

#Nombre del repositorio git o la ruta relativa del repositorio git respecto al home de usuario OBJETIVO (al cual se desea configurar el profile del usuario).
#Este valor se obtendra segun orden prioridad:
# - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
# - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
# - Si ninguno de los anteriores se establece, se usara el valor '.files'.
g_repo_name=''

#Folder base donde se almacena los subfolderes de los programas.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es un valor valido, la funcion "get_tools_path" asignara un sus posibles valores (segun orden de prioridad):
#     > "/var/opt/tools"
#     > "~/tools"
g_tools_path=''

#Folder base donde se almacena el comando y sus archivos afines.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura), dentro
#   de este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_lnx_base_path}/bin"            : subfolder donde se almacena los comandos.
#     > "${g_lnx_base_path}/share/man/man1" : subfolder donde se almacena archivos de ayuda man1.
#     > "${g_lnx_base_path}/share/man/man5" : subfolder donde se almacena archivos de ayuda man5.
#     > "${g_lnx_base_path}/share/man/man7" : subfolder donde se almacena archivos de ayuda man7.
#     > "${g_lnx_base_path}/share/fonts"    : subfolder donde se almacena las fuentes.
# - Si no es un valor valido, la funcion "g_lnx_paths" asignara un sus posibles valores (segun orden de prioridad):
#     > Si tiene permisos administrativos, usara los folderes predeterminado para todos los usuarios:
#        - "/usr/local/bin"            : subfolder donde se almacena los comandos.
#        - "/usr/local/share/man/man1" : subfolder donde se almacena archivos de ayuda man1.
#        - "/usr/local/share/man/man5" : subfolder donde se almacena archivos de ayuda man5.
#        - "/usr/local/share/man/man7" : subfolder donde se almacena archivos de ayuda man7.
#        - "/usr/local/share/fonts"    : subfolder donde se almacena las fuentes.
#     > Caso contrario, se usara los folderes predeterminado para el usuario:
#        - "~/.local/bin"             : subfolder donde se almacena los comandos.
#        - "~/.local/share/man/man1"  : subfolder donde se almacena archivos de ayuda man1.
#        - "~/.local/share/man/man5"  : subfolder donde se almacena archivos de ayuda man5.
#        - "~/.local/share/man/man7"  : subfolder donde se almacena archivos de ayuda man7.
#        - "~/.local/share/fonts"     : subfolder donde se almacena las fuentes.
# - Si el valor es vaciom se usara el los folderes predeterminado para todos los usuarios.
g_lnx_base_path=''

#Folder base donde se almacena data temporal que sera eliminado automaticamente despues completar la configuración.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es valido, la funcion "get_temp_path" asignara segun orden de prioridad a '/var/tmp' o '/tmp'.
# - Tener en cuenta que en muchas distribuciones el folder '/tmp' esta en la memoria y esta limitado a su tamaño.
g_temp_path=''


#Usado solo durante la instalación. Define si se instala solo la ultima version de un programa.
#Por defecto es 1 (considerado 'false'). Solo si su valor es '0', es considera 'true'.
g_setup_only_last_version=1


#Obtener los parametros del archivos de configuración
if [ -f "${g_shell_path}/bash/bin/linuxsetup/.setup_config.bash" ]; then

    #Obtener los valores por defecto de las variables
    . ${g_shell_path}/bash/bin/linuxsetup/.setup_config.bash

    #Corregir algunos valores
    if [ "$g_setup_only_last_version" = "0" ]; then
        g_setup_only_last_version=0
    else
        g_setup_only_last_version=1
    fi
fi



#3. Variables globales cuyos valor son AUTOGENERADOS internamente por el script

#Usuario OBJETIVO al cual se desa configurar su profile. Su valor es calcuado por 'get_targethome_info'.
g_targethome_owner=''

#Grupo de acceso que tiene el home del usuario OBJETIVO (al cual se desea configurar su profile). Su valor es calcuado por 'get_targethome_info'.
g_targethome_group=''

#Ruta base del respositorio git del usuario donde se instalar el profile del usuario. Su valor es calculado por 'get_targethome_info'.
g_repo_path=''

#Flag que determina si el usuario runner (el usuario que ejecuta este script de instalación) es el usuario objetivo o no.
#Su valor es calculado por 'get_targethome_info'.
# - Si es '0', el runner es el usuario objetivo (onwer del "target home").
# - Si no es '0', el runner es NO es usario objetivo, SOLO puede ser el usuario root.
#   Este caso, el root realizará la configuracion requerida para el usuario objetivo (usando sudo), nunca realizara configuración para el propio usuario root.
g_runner_is_target_user=0


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


#4. LOGICA: Instalar y actualizar los artefactos de un repositorio
_g_result=0
_g_status=0

#4.1. Por defecto, mostrar el menu para escoger lo que se va instalar
if [ $gp_type_calling -eq 0 ]; then

    #Parametros usados por el script:
    # 1> Tipo de invocación: 0 (usando un menu interactivo)
    # 2> ID de los repositorios de comandos a configurar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".
    # 3> ID de los paquetes del repositorio, separados por coma, que se mostrara en el menu para que pueda instalarse. Si desea usar el por defecto envie "EMPTY".
    #    Los paquete basicos, por defecto, que se muestran en el menu son: Curl,UnZip, OpenSSL y Tmux
    # 4> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git. Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
    #    - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
    # 5> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    #    Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se usara el valor '.files'.
    # 6> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado \
    #    "/var/opt/tools" o "~/tools".
    # 7> Ruta base donde se almacena los comandos ("LNX_BASE_PATH/bin"), archivos man1 ("LNX_BASE_PATH/man/man1") y fonts ("LNX_BASE_PATH/share/fonts").
    #    Si se envia vacio o EMPTY se usara el directorio predeterminado.
    #       > Comandos      : "/usr/local/bin"            (para todos los usuarios) y "~/.local/bin"            (solo para el usuario actual)
    #       > Archivos man1 : "/usr/local/share/man/man1" (para todos los usuarios) y "~/.local/share/man/man1" (solo para el usuario actual)
    #       > Archivo fuente: "/usr/local/share/fonts"    (para todos los usuarios) y "~/.local/share/fonts"    (solo para el usuario actual)
    # 8> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    # 9> Flag '0' para limpiar el cache de paquetes del sistema operativo. Caso contrario, use 1.
    _gp_list_repo_ids=""
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        _gp_list_repo_ids="$2"
    fi

    _gp_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        _gp_list_pckg_ids="$4"
    fi

    #Calcular el valor efectivo de 'g_repo_name'.
    if [ ! -z "$5" ] && [ "$5" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_repo_name="$5"
    fi

    if [ -z "$g_repo_name" ]; then
        g_repo_name='.files'
    fi

    #Obtener los valores efectivo de la variable 'g_targethome_path', 'g_repo_path', 'g_targethome_owner', 'g_targethome_group'
    if [ ! -z "$4" ] && [ "$4" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_targethome_path="$4"
    fi

    get_targethome_info "$g_repo_name" "$g_targethome_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        exit 111
    fi


    #Obtener la ruta real del folder donde se alamacena los de programas 'g_tools_path'
    if [ ! -z "$6" ] && [ "$6" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_tools_path="$6"
    fi

    _g_is_noninteractive=1
    get_tools_path $_g_is_noninteractive "$g_tools_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        printf 'No se pede establecer la ruta base donde se instalarán los programas.\n'
        exit 111
    fi



    #Obtener la ruta real del folder base de comandos 'g_lnx_base_path'
    if [ ! -z "$7" ] && [ "$7" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_lnx_base_path="$7"
    fi

    g_lnx_paths $_g_is_noninteractive "$g_lnx_base_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        printf 'No se pede establecer la ruta base donde se instalarán los comandos.\n'
        exit 111
    fi



    #Obtener la ruta rel del folder de los archivos temporales 'g_temp_path'
    if [ ! -z "$8" ] && [ "$8" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_temp_path="$8"
    fi
    get_temp_path "$g_temp_path"

    _gp_flag_clean_os_cache=1
    if [ "$9" = "0" ]; then
        _gp_flag_clean_os_cache=0
    fi

    #Validar los requisitos (algunas opciones requiere root y otros no)
    #  1 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  2 > Flag '0' si se requere curl
    #  3 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    fulfill_preconditions 0 1 1
    _g_status=$?


    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_install_main "$_gp_list_repo_ids" "$_gp_list_pckg_ids" $_gp_flag_clean_os_cache
    else
        _g_result=111
    fi

#4.2. Instalando los repositorios especificados por las opciones indicas en '$2'
#elif [ $gp_type_calling -eq 1 ] || [ $gp_type_calling -eq 2 ]; then
else

    #Parametros usados por el script:
    # 1> Tipo de invocación (sin menu): 1/2 (sin usar un menu interactivo/no-interactivo)
    # 2> Opciones de menu a ejecutar: entero positivo.
    # 3> ID de los repositorios de comandos a configurar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".
    # 4> ID de los paquetes del repositorio del SO, separados por coma, a instalar si elige la opcion de menu 32. Si desea usar el los los paquetes por defecto
    #    envie "EMPTY".
    #    Los paquetes por defecto que son: Curl, UnZip, OpenSSL y Tmux.
    # 5> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git. Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
    #    - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
    # 6> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    #    Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion "./linuxsetup/.setup_config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se usara el valor '.files'.
    # 7> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado
    #    "/var/opt/tools" o "~/tools".
    # 8> Ruta base donde se almacena los comandos ("LNX_BASE_PATH/bin"), archivos man1 ("LNX_BASE_PATH/man/man1") y fonts ("LNX_BASE_PATH/share/fonts").
    #    Si se envia vacio o EMPTY se usara el directorio predeterminado.
    #       > Comandos      : "/usr/local/bin"            (para todos los usuarios) y "~/.local/bin"         (solo para el usuario actual)
    #       > Archivos man1 : "/usr/local/share/man/man1" (para todos los usuarios) y "~/.local/share/man/man1"    (solo para el usuario actual)
    #       > Archivo fuente: "/usr/local/share/fonts"    (para todos los usuarios) y "~/.local/share/fonts" (solo para el usuario actual)
    # 9> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    #10> El estado de la credencial almacenada para el sudo.
    #11> Flag '0' para limpiar el cache de paquetes del sistema operativo. Caso contrario, use 1.
    _gp_options=0
    if [ "$2" = "0" ]; then
        _gp_options=-1
    elif [[ "$2" =~ ^[0-9]+$ ]]; then
        _gp_options=$2
    else
        echo "Opciones de menu a instalar (parametro 2) \"$2\" no es valido."
        exit 110
    fi

    _gp_list_repo_ids=""
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        _gp_list_repo_ids="$3"
    fi

    if [ $_gp_options -lt 0 ] && [ -z "$_gp_list_repo_ids" ]; then
        printf 'Se debe ingresar un valor valido para el pametro 2 "%s" o el parametro 3 "%s". Ambos no pueden ser empty.\n' "$_gp_options" "$_gp_list_repo_ids"
        return 110
    fi

    _gp_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$4" ] && [ "$4" != "EMPTY" ]; then
        _gp_list_pckg_ids="$4"
    fi

    if [[ "${10}" =~ ^[0-2]$ ]]; then
        g_status_crendential_storage=${10}

        if [ $g_status_crendential_storage -eq 0 ]; then
            g_is_credential_storage_externally=0
        fi

    fi

    _gp_flag_clean_os_cache=1
    if [ "${11}" = "0" ]; then
        _gp_flag_clean_os_cache=0
    fi

    #Calcular el valor efectivo de 'g_repo_name'.
    if [ ! -z "$6" ] && [ "$6" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_repo_name="$6"
    fi

    if [ -z "$g_repo_name" ]; then
        g_repo_name='.files'
    fi

    #Obtener los valores efectivo de la variable 'g_targethome_path', 'g_repo_path', 'g_targethome_owner', 'g_targethome_group'
    if [ ! -z "$5" ] && [ "$5" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_targethome_path="$5"
    fi

    get_targethome_info "$g_repo_name" "$g_targethome_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        exit 111
    fi


    #Obtener la ruta real del folder donde se alamacena los de programas 'g_tools_path'
    if [ ! -z "$7" ] && [ "$7" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_tools_path="$7"
    fi

    _g_is_noninteractive=1
    get_tools_path $_g_is_noninteractive "$g_tools_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        printf 'No se pede establecer la ruta base donde se instalarán los programas.\n'
        exit 111
    fi



    #Obtener la ruta real del folder base de comandos 'g_lnx_base_path'
    if [ ! -z "$8" ] && [ "$8" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_lnx_base_path="$8"
    fi

    g_lnx_paths $_g_is_noninteractive "$g_lnx_base_path"

    #Obtener los folderes temporal 'g_temp_path'
    if [ ! -z "$9" ] && [ "$9" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración './linuxsetup/.setup_config.bash'
        g_temp_path="$9"
    fi
    get_temp_path "$g_temp_path"


    #Validar los requisitos (algunas opciones requiere root y otros no)
    #  1 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  2 > Flag '0' si se requere curl
    #  3 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    fulfill_preconditions 1 1 1
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then

        g_install_options $_gp_options "$_gp_list_repo_ids" "$_gp_list_pckg_ids" $_gp_flag_clean_os_cache
        _g_status=$?

        #Informar si se nego almacenar las credencial cuando es requirido
        if [ $_g_status -eq 120 ]; then
            _g_result=120
        #Si la credencial se almaceno en este script (localmente). avisar para que lo cierre el caller
        elif [ $g_is_credential_storage_externally -ne 0 ] && [ $g_status_crendential_storage -eq 0 ]; then
            _g_result=119
        #Si no se paso las precondiciones iniciales
        elif [ $_g_status -eq 111 ]; then
            _g_result=111
        fi

    else
        _g_result=111
    fi


fi


exit $_g_result


#}}}
