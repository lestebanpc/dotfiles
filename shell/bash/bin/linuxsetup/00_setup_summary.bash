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
. ${g_shell_path}/bash/bin/linuxsetup/lib/common_utility.bash


declare -r g_default_list_package_ids='curl,unzip,openssl,tmux'

#Opciones de '04_install_profile.bash' para configurar VIM/NeoVIM
#  0> Crear archivos de configuración como Editor
#  1> Crear archivos de configuración como IDE
#  2> Descargar plugins de Editor e indexarlos
#  3> Descargar plugins de Editor (sin indexarlos)
#  4> Descargar plugins de IDE e indexarlos
#  5> Descargar plugins de IDE (sin indexarlos)
#  6> Indexar la documentación (de plugins anteriormente descargados)
#  7> Inicializar los plugins de IDE
declare -ra ga_options_config_vim=(32768 65536 131072 262144 524288 1048576 2097152 4194304)
declare -ra ga_options_config_nvim=(8388608 16777216 33554432 67108864 134217728 268435456 536870912 1073741824)
declare -ra ga_title_config=(
    "Crear archivos de configuración como Editor"
    "Crear archivos de Configuración como IDE"
    "Descargar plugins de Editor e indexarlos"
    "Descargar plugins de Editor (sin indexarlos)"
    "Descargar plugins de IDE e indexarlos"
    "Descargar plugins de IDE (sin indexarlos)"
    "Indexar la documentación (de plugins anteriormente descargados)"
    "Inicializar los plugins de IDE")

#Opciones de '04_install_profile.bash'para instalar lo necesario para VIM/NeoVIM
#  0> Instalar Python
#  1> Instalar paquete de usuario de Python: 'jtbl'
#  2> Instalar paquete de usuario de Python: 'jtbl', 'compiledb', 'rope' y 'pynvim'
#  3> Instalar NodeJS
#  4> Instalar paquete globales de NodeJS: 'Prettier'
#  5> Instalar paquete globales de NodeJS: 'Prettier', 'NeoVIM' y 'TreeSitter CLI'
#  6> Instalar VIM
#  7> Instalar NeoVIM
declare -ra ga_options_install=(8 8192 32 16 16384 64 128 1024)
declare -ra ga_title_install=(
    "Python/Pip"
    "Paquetes de usuario de Python 'jtbl'"
    "Paquetes de usuario de Python 'jtbl', 'compiledb', 'rope' y 'pynvim'"
    "NodeJS"
    "Paquetes globales de Python 'Prettier'"
    "Paquetes globales de Python 'Prettier', 'NeoVIM' y 'TreeSitter CLI'"
    "VIM"
    "NeoVIM")

#Opciones de '04_install_profile.bash' generales
# 0> Actualizar los paquetes del SO
# 1> Crear los enlaces simbolicos del profile del usuario
# 2> Flag para re-crear un enlaces simbolicos en caso de existir
declare -ra ga_options_general=(1 2 4)
declare -ra ga_title_general=(
    "Actualizar los paquetes del SO"
    "Crear los enlaces simbolicos del profile del usuario"
    "Flag para re-crear un enlaces simbolicos en caso de existir")



#}}}



#------------------------------------------------------------------------------------------------------------------
#> Funciones usadas durante configuración del profile {{{
#------------------------------------------------------------------------------------------------------------------
# 
# Incluye las variable globales usadas como parametro de entrada y salida de la funcion que no sea resuda por otras
# funciones, cuyo nombre inicia con '_g_'.
#


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

    #if [ $p_input_options -le 0 ]; then
    #    echo "ERROR: Argumento de opciones \"${p_input_options}\" es incorrecta"
    #    return 99
    #fi

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

    local p_flag_upgrade_os_pkgs=1
    if [ "$5" = "0" ]; then
        p_flag_upgrade_os_pkgs=0
    fi

    #2.Inicialización
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    #Flag '0' cuando no se realizo ninguna instalacion de paquetes
    local l_exist_packages_installed=1

    #3. Instalar paquetes basicos del SO: Curl, OpenSSL y Tmux
    local l_status=0
    local l_option=1024
    if [ $p_input_options -gt 0 ] && [ $(( $p_input_options & $l_option )) -eq $l_option ] && [ ! -z "$p_list_pckg_ids" ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_runner_sudo_support -ne 2 ] && [ $g_runner_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            printf '\n'
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Instalando '%b%s%b'\n" "$g_color_cian1" "${p_list_pckg_ids//,/, }" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 2/4 (ejecución sin menu, para instalar/actualizar un grupo paquetes)
            # 2> Paquetes a instalar 
            # 3> El estado de la credencial almacenada para el sudo
            # 4> Actualizar los paquetes del SO antes. Por defecto es 1 (false).
            if [ $l_is_noninteractive -eq 1 ]; then
                ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 2 "$p_list_pckg_ids" $g_status_crendential_storage $p_flag_upgrade_os_pkgs
                l_status=$?
            else
                ${g_shell_path}/bash/bin/linuxsetup/03_setup_repo_os_pkgs.bash 4 "$p_list_pckg_ids" $g_status_crendential_storage $p_flag_upgrade_os_pkgs
                l_status=$?
            fi

            if [ $l_exist_packages_installed -ne 0 ]; then
                l_exist_packages_installed=0
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

        else
            printf '%bSe requiere acceso a root%b para instalar paquete.\n' "$g_color_red1" "$g_color_reset"
        fi

    fi

    #4. Descargar e configurar los comandos basicos (usar un grupo de comandos especifico)
    l_option=2048
    if [ $p_input_options -gt 0 ] && [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_runner_sudo_support -ne 2 ] && [ $g_runner_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            printf '\n'
            print_line '─' $g_max_length_line  "$g_color_blue1"
            if [ $g_os_subtype_id -eq 1 ]; then
                printf "> Instalando %bComandos Basicos%b: '%bbat, jq, yq, ripgrep, delta, oh-my-posh, fd, zoxide y eza%b.'\n" "$g_color_cian1" "$g_color_reset" \
                       "$g_color_cian1" "$g_color_reset"
            else
                printf "> Instalando %bComandos Basicos%b: '%bfzf, bat, jq, yq, ripgrep, delta, oh-my-posh, fd, zoxide y eza%b.'\n" "$g_color_cian1" "$g_color_reset" \
                       "$g_color_cian1" "$g_color_reset"
            fi
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros usados por el script:
            # 1> Tipo de llamado: 1/3 (sin menu interactivo/no-interactivo).
            # 2> Opciones de menu a ejecutar: entero positivo.
            # 3> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git.
            # 4> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
            # 5> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado
            #    "/var/opt/tools" o "~/tools".
            # 6> Ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts").
            # 7> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
            # 8> El estado de la credencial almacenada para el sudo.
            # 9> Install only last version: por defecto es 1 (representa a 'false'). Solo si su valor es 0 representa a 'true'.
            if [ $l_is_noninteractive -eq 1 ]; then
                ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 1 4 "$g_targethome_path" "$g_repo_name" "$g_programs_path" "$g_cmd_base_path" \
                    "$g_temp_path" $g_status_crendential_storage 0
                l_status=$?
            else
                ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 3 4 "$g_targethome_path" "$g_repo_name" "$g_programs_path" "$g_cmd_base_path" \
                    "$g_temp_path" $g_status_crendential_storage 0
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

        fi

    fi


    #5. Descargar y configurar una lista de repositorios de comandos adicionales a instalar (segun una lista de ID de repositorios)

    #¿Se adiciona repositorios adicionales?
    if [ $p_input_options -gt 0 ]; then

        #LSP/DAP de Java: jdtls
        l_option=4194304
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
        l_option=2097152
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

            if [[ ! $p_list_repo_ids =~ ,roslyn$ ]] && [[ ! $p_list_repo_ids =~ ,roslyn, ]] && [[ ! $p_list_repo_ids =~ ^roslyn, ]]; then
                if [ -z "$p_list_repo_ids" ]; then
                    p_list_repo_ids="roslyn"
                else
                    p_list_repo_ids="${p_list_repo_ids},roslyn"
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

    #Instalar los repositorios de comandos
    if [ ! -z "$p_list_repo_ids" ]; then

        #Mostrar el titulo de instalacion
        printf '\n'
        print_line '─' $g_max_length_line  "$g_color_blue1"
        printf "> Instalando repositorios %bcomandos/programas%b: '%b%s%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" \
               "${p_list_repo_ids//,/, }" "$g_color_reset"
        print_line '─' $g_max_length_line "$g_color_blue1"

        #Parametros del script usados hasta el momento:
        # 1> Tipo de llamado: 2/4 (sin menu interactivo/no-interactivo).
        # 2> Listado de ID del repositorios a instalar separados por coma.
        # 3> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git.
        # 4> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
        # 5> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado 
        #    "/var/opt/tools" o "~/tools".
        # 6> Ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts").
        # 7> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
        # 8> El estado de la credencial almacenada para el sudo.
        # 9> Install only last version: por defecto es 1 (false). Solo si ingresa 0, se cambia a 0 (true).
        #10> Flag '0' para mostrar un titulo si se envia un repositorio en el parametro 2. Por defecto es '1' 
        if [ $l_is_noninteractive -eq 1 ]; then
            
            ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 2 "$p_list_repo_ids" "$g_targethome_path" "$g_repo_name" "$g_programs_path" \
                "$g_cmd_base_path" "$g_temp_path" $g_status_crendential_storage 0 1
            l_status=$?
        else
            ${g_shell_path}/bash/bin/linuxsetup/01_setup_binaries.bash 4 "$p_list_repo_ids" "$g_targethome_path" "$g_repo_name" "$g_programs_path" \
                "$g_cmd_base_path" "$g_temp_path" $g_status_crendential_storage 0 1
            l_status=$?
        fi

        #Obligar a limpiar el cache: ¿algunos instalacion, instala paquetes?
        if [ $l_exist_packages_installed -ne 0 ]; then
            l_exist_packages_installed=0
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

    fi


    #6. Instalar y/o Configurar todo lo relacionado con VIM/NeoVIM: NodeJs (y sus paquetes globales), Python/Pip (y sus paquetes de usuario), VIM y NeoVIM

    #6.1. Determinar las opciones elegidas por el usuario
    local la_options_config_vim=()
    local la_options_config_nvim=()
    local la_options_install=()
    local la_options_general=()
    local l_i=0
    local l_info=''
    local l_prg_options=0

    if [ $p_input_options -gt 0 ]; then

        #6.1.1. Determinar las opciones elegidas

        #Opciones recomendados para ejecutar con root:
        # (0004096) Instalar NodeJS y Npm
        # (0008192) Instalar paquetes globales de NodeJS: 'Prettier'
        # (0016384) Instalar Python y Pip
        # (0032768) Instalar VIM
        # (0065536) Instalar NeoVIM
        # (0131072) Descargar Plugins de Editor de VIM
        # (0262144) Descargar Plugins de Editor de NeoVIM
        # (0524288) Descargar Plugins de IDE    de VIM
        # (1048576) Descargar Plugins de IDE    de NeoVIM


        #Solo actualizar los paquetes del SO, si no se hizo antes
        # 0> Actualizar los paquetes del SO
        if [ $p_flag_upgrade_os_pkgs -eq 0 ] && [ $l_exist_packages_installed -ne 0 ]; then
            la_options_general[0]=0
        fi

        # 3> Instalar NodeJS
        l_option=4096
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_install[3]=0
        fi

        # 4> Instalar paquete globales de NodeJS: 'Prettier'
        l_option=8192
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_install[4]=0
        fi

        # 5> Instalar paquete globales de NodeJS: 'Prettier', 'NeoVIM' y 'TreeSitter CLI'
        #l_option=xxxx
        #if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        #    la_options_install[5]=0
        #fi

        # 0> Instalar Python
        l_option=16384
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_install[0]=0
        fi

        # 6> Instalar VIM
        l_option=32768
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_install[6]=0
        fi

        # 7> Instalar NeoVIM
        l_option=65536
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_install[7]=0
        fi

        # 3> Descargar plugins de Editor (sin indexarlos)
        l_option=131072
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_vim[3]=0
        fi

        # 5> Descargar plugins de IDE (sin indexarlos)
        l_option=262144
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_nvim[5]=0
        fi

        # 3> Descargar plugins de Editor (sin indexarlos)
        l_option=524288
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_vim[3]=0
        fi

        # 5> Descargar plugins de IDE (sin indexarlos)
        l_option=1048576
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_nvim[5]=0
        fi


        #Opciones recomendados para ejecutar con el usuario:
        # (0000001) Configurar el profile del usuario
        # (0000002) Instalar paquetes usuario de Python: 'jtbl'
        # (0000004) VIM como Editor    > Crear archivos de configuración, Descargar plugins e indexarlos
        # (0000008) VIM como IDE       > Crear archivos de configuración, Descargar plugins e indexarlos, Inicializar los plugins
        # (0000016) NeoVIM como Editor > Crear archivos de configuración, Descargar plugins e indexarlos
        # (0000032) NeoVIM como IDE    > Crear archivos de configuración, Descargar plugins e indexarlos, Inicializar los plugins
        # (0000064) VIM como Editor    > Crear archivos de configuración, Indexar plugins
        # (0000128) VIM como IDE       > Crear archivos de configuración, Indexar plugins, Inicializar los plugins
        # (0000256) NeoVIM como Editor > Crear archivos de configuración, Indexar plugins
        # (0000512) NeoVIM como IDE    > Crear archivos de configuración, Indexar plugins, Inicializar los plugins


        # 1> Crear los enlaces simbolicos del profile del usuario
        l_option=1
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_general[1]=0
        fi

        #Siempre recrear los enlaces simbolicos si no existe
        # 2> Flag para re-crear un enlaces simbolicos en caso de existir
        la_options_general[2]=0

        # 1> Instalar paquete de usuario de Python: 'jtbl'
        l_option=2
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_install[1]=0
        fi

        # 2> Instalar paquete de usuario de Python: 'jtbl', 'compiledb', 'rope' y 'pynvim'
        #l_option=xxxx
        #if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
        #    la_options_install[1]=0
        #fi

        # 0> Crear archivos de configuración como Editor
        # 2> Descargar plugins de Editor e indexarlos
        l_option=4
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_vim[0]=0
            la_options_config_vim[2]=0
        fi

        # 1> Crear archivos de configuración como IDE
        # 4> Descargar plugins de IDE e indexarlos
        # 7> Inicializar los plugins de IDE
        l_option=8
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_vim[1]=0
            la_options_config_vim[4]=0
            la_options_config_vim[7]=0
        fi

        # 0> Crear archivos de configuración como Editor
        # 2> Descargar plugins de Editor e indexarlos
        l_option=16
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_nvim[0]=0
            la_options_config_nvim[2]=0
        fi

        # 1> Crear archivos de configuración como IDE
        # 4> Descargar plugins de IDE e indexarlos
        # 7> Inicializar los plugins de IDE
        l_option=32
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_nvim[1]=0
            la_options_config_nvim[4]=0
            la_options_config_nvim[7]=0
        fi

        # 0> Crear archivos de configuración como Editor
        # 6> Indexar la documentación (de plugins anteriormente descargados)
        l_option=64
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_vim[0]=0
            la_options_config_vim[6]=0
        fi

        # 1> Crear archivos de configuración como IDE
        # 6> Indexar la documentación (de plugins anteriormente descargados)
        # 7> Inicializar los plugins de IDE
        l_option=128
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_vim[1]=0
            la_options_config_vim[6]=0
            la_options_config_vim[7]=0
        fi

        # 0> Crear archivos de configuración como Editor
        # 6> Indexar la documentación (de plugins anteriormente descargados)
        l_option=256
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_nvim[0]=0
            la_options_config_nvim[6]=0
        fi

        # 1> Crear archivos de configuración como IDE
        # 6> Indexar la documentación (de plugins anteriormente descargados)
        # 7> Inicializar los plugins de IDE
        l_option=512
        if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then
            la_options_config_nvim[1]=0
            la_options_config_nvim[6]=0
            la_options_config_nvim[7]=0
        fi

        #6.1.1. Determinar el valor de estas las opciones elegidas
        l_prg_options=0
        l_info='Se realizara las siguientes instalaciones/configuraciones:'

        for (( l_i = 0; l_i < ${#ga_options_general[@]}; l_i++ )); do
            if [ "${la_options_general[${l_i}]}" = "0" ]; then
                ((l_prg_options= l_prg_options + ${ga_options_general[${l_i}]}))
                printf -v l_info '%s\n   > General > %b%s%b %b(opción de "02_install_profile": %s)%b' "$l_info" "$g_color_blue1" "${ga_title_general[${l_i}]}" \
                       "$g_color_reset" "$g_color_gray1" "${ga_options_general[${l_i}]}" "$g_color_reset"
            fi 
        done

        for (( l_i = 0; l_i < ${#ga_options_install[@]}; l_i++ )); do
            if [ "${la_options_install[${l_i}]}" = "0" ]; then
                ((l_prg_options= l_prg_options + ${ga_options_install[${l_i}]}))
                printf -v l_info '%s\n   > Instalar %b%s%b %b(opción de "02_install_profile": %s)%b' "$l_info" "$g_color_blue1" "${ga_title_install[${l_i}]}" \
                       "$g_color_reset" "$g_color_gray1" "${ga_options_install[${l_i}]}" "$g_color_reset"
            fi 
        done

        for (( l_i = 0; l_i < ${#ga_options_config_vim[@]}; l_i++ )); do
            if [ "${la_options_config_vim[${l_i}]}" = "0" ]; then
                ((l_prg_options= l_prg_options + ${ga_options_config_vim[${l_i}]}))
                printf -v l_info '%s\n   > Configuración VIM   > %b%s%b %b(opción de "02_install_profile": %s)%b' "$l_info" "$g_color_blue1" "${ga_title_config[${l_i}]}" \
                       "$g_color_reset" "$g_color_gray1" "${ga_options_config_vim[${l_i}]}" "$g_color_reset"
            fi 
        done

        for (( l_i = 0; l_i < ${#ga_options_config_nvim[@]}; l_i++ )); do
            if [ "${la_options_config_nvim[${l_i}]}" = "0" ]; then
                ((l_prg_options= l_prg_options + ${ga_options_config_nvim[${l_i}]}))
                printf -v l_info '%s\n   > Configuración NeoVIM > %b%s%b %b(opción de "02_install_profile": %s)%b' "$l_info" "$g_color_blue1" \
                    "${ga_title_config[${l_i}]}" "$g_color_reset" "$g_color_gray1" "${ga_options_config_nvim[${l_i}]}" "$g_color_reset"
            fi 
        done

    fi

    #6.3. Instalar/Configurar el profile
    if [ $l_prg_options -ne 0 ] && [ $l_prg_options -ne 4 ] && [ $l_prg_options -ne 5 ]; then

       #Mostrar el titulo de instalacion
       printf '\n'
       print_line '─' $g_max_length_line  "$g_color_blue1"
       printf "> Instalando/configurando para VIM/NeoVIM como Editor/IDE\n"
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

       #Considerar que siempre se instalan paquetes de SO, es decir se debe limpiar el cache de paquete descargados.
       if [ $l_exist_packages_installed -ne 0 ]; then
           l_exist_packages_installed=0
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

    fi


    #7. Limpiar el cache, si se instalo paquetes
    if [ $p_flag_clean_os_cache -eq 0 ] && [ $l_exist_packages_installed -eq 0 ]; then
        printf '\n%bClean packages cache%b...\n' "$g_color_gray1" "$g_color_reset"
        clean_os_cache $g_os_subtype_id $l_is_noninteractive
    fi

    #8. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #   Si no se invoca usando el menú y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi


}    

function _show_menu_install_core() {

    #0. Parametros
    local l_pckg_ids="${1//,/, }"

    #1. Menu
    print_text_in_center "Menu de Opciones (Install/Configuration)" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"

    local l_max_digits=7

    printf " ( ) Configuración personalizado para el usuario:\n"
    printf "     (%b%0${l_max_digits}d%b) Configurar el %bprofile del usuario%b\n" "$g_color_green1" "1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes usuario%b de %bPython%b: 'jtbl'\n" "$g_color_green1" "2" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b como %bEditor%b    > Crear archivos de configuración, Descargar plugins e indexarlos\n" "$g_color_green1" "4" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b como %bIDE%b       > Crear archivos de configuración, Descargar plugins e indexarlos, Inicializar los plugins\n" "$g_color_green1" "8" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b como %bEditor%b > Crear archivos de configuración, Descargar plugins e indexarlos\n" "$g_color_green1" "16" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b como %bIDE%b    > Crear archivos de configuración, Descargar plugins e indexarlos, Inicializar los plugins\n" "$g_color_green1" "32" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b como %bEditor%b    > Crear archivos de configuración, Indexar plugins\n" "$g_color_green1" "64" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b como %bIDE%b       > Crear archivos de configuración, Indexar plugins, Inicializar los plugins\n" "$g_color_green1" "128" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b como %bEditor%b > Crear archivos de configuración, Indexar plugins\n" "$g_color_green1" "256" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b como %bIDE%b    > Crear archivos de configuración, Indexar plugins, Inicializar los plugins\n" "$g_color_green1" "512" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"

    printf " ( ) Programas requeridos a instalar %b(usualmente instalado como root)%b:\n" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes basicos%b: %b%s%b\n" "$g_color_green1" "1024" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" \
           "$l_pckg_ids" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bcomandos basicos%b: %bfzf, bat, jq, yq, ripgrep, delta, oh-my-posh, fd, zoxide y eza.%b\n" "$g_color_green1" \
           "2048" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bNodeJS%b y %bNpm%b\n" "$g_color_green1" "4096" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes globales%b de %bNodeJS%b: %b'Prettier'%b\n" "$g_color_green1" "8192" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bPython%b y %bPip%b\n" "$g_color_green1" "16384" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bVIM%b\n" "$g_color_green1" "32768" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bNeoVIM%b\n" "$g_color_green1" "65536" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Descargar %bPlugins de Editor%b de %bVIM%b\n" "$g_color_green1" "131072" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Descargar %bPlugins de Editor%b de %bNeoVIM%b\n" "$g_color_green1" "262144" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Descargar %bPlugins de IDE%b    de %bVIM%b\n" "$g_color_green1" "524288" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Descargar %bPlugins de IDE%b    de %bNeoVIM%b\n" "$g_color_green1" "1048576" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) LSP/DAP de .NET : %bOmnisharp-Roslyn, NetCoreDbg%b\n" "$g_color_green1" "2097152" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) LSP/DAP de Java : %bJdtls%b\n" "$g_color_green1" "4194304" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

    print_line '-' $g_max_length_line "$g_color_gray1"

}


function g_install_main() {

    #0. Parametros
    local p_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$1" ]; then
        p_list_pckg_ids="$1"
    fi

    p_flag_clean_os_cache=1
    if [ "$2" = "0" ]; then
        p_flag_clean_os_cache=0
    fi

    #1. Pre-requisitos
   
    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_green1" 
    _show_menu_install_core "$p_list_pckg_ids"

    #3. Mostar la ultima parte del menu y capturar la opcion elegida
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


            0)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_gray1" 
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then

                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_green1" 

                    g_install_options $l_options "EMPTY" "$p_list_pckg_ids" $p_flag_clean_os_cache 0

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
    printf '  > %bDesintalar repositorios mostrando el menú de opciones%b:\n' "$g_color_cian1" "$g_color_reset" 
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash uninstall\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '  > %bInstalar repositorios mostrando el menú de opciones (interactivo)%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash 0 LIST-PCKG-IDS TARGET_HOME_PATH REPO_NAME PRG_PATH CMD_BASE_PATH TEMP_PATH CLEAN-OS-CACHE\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un grupo de opciones sin mostrar el menú%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS LIST-REPO-IDS LIST-PCKG-IDS TARGET_HOME_PATH REPO_NAME PRG_PATH CMD_BASE_PATH TEMP_PATH\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/shell/bash/bin/linuxsetup/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS LIST-REPO-IDS LIST-PCKG-IDS TARGET_HOME_PATH REPO_NAME PRG_PATH CMD_BASE_PATH TEMP_PATH SUDO-STORAGE-OPTIONS CLEAN-OS-CACHE UPGRADE-OS-PACKAGES\n\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bCALLING_TYPE%b es 1 si es interactivo y 2 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bMENU-OPTIONS%b Las opciones de menu a instalar. Si no desea especificar coloque 0.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bLIST-REPO-IDS %bID de los repositorios de comandos a configurar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bLIST-PCKG-IDS %b.ID de los paquetes del repositorio del SO, separados por coma, a instalar si elige la opcion de menu 1024. Si desea usar el los los paquetes por defecto envie "EMPTY".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bLos paquete basicos por defecto que son: Curl, UnZip, OpenSSL y Tmux.%b\n' "$g_color_gray1" "$g_color_reset"
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
    printf '  > %bPRG_PATH %bes la ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado "/var/opt/tools" o "~/tools".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bCMD_BASE_PATH %bes ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts"). Si se envia vacio o EMPTY se usara el directorio predeterminado:%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '      %b> Comandos      : "/usr/local/bin"      (para todos los usuarios) y "~/.local/bin"         (solo para el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '      %b> Archivos man1 : "/usr/local/man/man1" (para todos los usuarios) y "~/.local/man/man1"    (solo para el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '      %b> Archivo fuente: "/usr/share/fonts"    (para todos los usuarios) y "~/.local/share/fonts" (solo para el usuario actual)%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bTEMP_PATH %bes la ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado "/tmp".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bSUDO-STORAGE-OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi es root por lo que no se requiere almacenar la credenciales, use 2. Caso contrario, use 0 si se almaceno la credencial y 1 si no se pudo almacenar las credenciales.%b\n' \
           "$g_color_gray1" "$g_color_reset"
    printf '  > %bCLEAN-OS-CACHE%b es 0 si se limpia el cache de paquetes instalados. Por defecto es 1.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bUPGRADE-OS-PACKAGES%b Actualizar los paquetes del SO. Por defecto es 1 (false), si desea actualizar use 0.\n\n%b' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

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
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
else
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 110
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
# - El valor ingresado en el archivo de configuracion ".config.bash" (debe ser diferente de vacio)
# - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
# - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
g_targethome_path=''

#Nombre del repositorio git o la ruta relativa del repositorio git respecto al home de usuario OBJETIVO (al cual se desea configurar el profile del usuario).
#Este valor se obtendra segun orden prioridad:
# - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
# - El valor ingresado en el archivo de configuracion ".config.bash" (debe ser diferente de vacio)
# - Si ninguno de los anteriores se establece, se usara el valor '.files'.
g_repo_name=''

#Folder base donde se almacena los subfolderes de los programas.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es un valor valido, la funcion "get_program_path" asignara un sus posibles valores (segun orden de prioridad):
#     > "/var/opt/tools"
#     > "~/tools"
g_programs_path=''

#Folder base donde se almacena el comando y sus archivos afines.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura), dentro
#   de este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_cmd_base_path}/bin"         : subfolder donde se almacena los comandos.
#     > "${g_cmd_base_path}/man/man1"    : subfolder donde se almacena archivos de ayuda man1.
#     > "${g_cmd_base_path}/man/man5"    : subfolder donde se almacena archivos de ayuda man5.
#     > "${g_cmd_base_path}/man/man7"    : subfolder donde se almacena archivos de ayuda man7.
#     > "${g_cmd_base_path}/share/fonts" : subfolder donde se almacena las fuentes.
# - Si no es un valor valido, la funcion "get_command_path" asignara un sus posibles valores (segun orden de prioridad):
#     > Si tiene permisos administrativos, usara los folderes predeterminado para todos los usuarios:
#        - "/usr/local/bin"      : subfolder donde se almacena los comandos.
#        - "/usr/local/man/man1" : subfolder donde se almacena archivos de ayuda man1.
#        - "/usr/local/man/man5" : subfolder donde se almacena archivos de ayuda man5.
#        - "/usr/local/man/man7" : subfolder donde se almacena archivos de ayuda man7.
#        - "/usr/share/fonts"    : subfolder donde se almacena las fuentes.
#     > Caso contrario, se usara los folderes predeterminado para el usuario:
#        - "~/.local/bin"         : subfolder donde se almacena los comandos.
#        - "~/.local/man/man1"    : subfolder donde se almacena archivos de ayuda man1.
#        - "~/.local/man/man5"    : subfolder donde se almacena archivos de ayuda man5.
#        - "~/.local/man/man7"    : subfolder donde se almacena archivos de ayuda man7.
#        - "~/.local/share/fonts" : subfolder donde se almacena las fuentes.
# - Si el valor es vaciom se usara el los folderes predeterminado para todos los usuarios.
g_cmd_base_path=''

#Folder base donde se almacena data temporal que sera eliminado automaticamente despues completar la configuración.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es valido, la funcion "get_temp_path" asignara segun orden de prioridad a '/var/tmp' o '/tmp'.
# - Tener en cuenta que en muchas distribuciones el folder '/tmp' esta en la memoria y esta limitado a su tamaño.
g_temp_path=''


#Usado solo durante la instalación. Define si se instala solo la ultima version de un programa.
#Por defecto es 1 (considerado 'false'). Solo si su valor es '0', es considera 'true'.
g_setup_only_last_version=1


#Obtener los parametros del archivos de configuración
if [ -f "${g_shell_path}/bash/bin/linuxsetup/.config.bash" ]; then

    #Obtener los valores por defecto de las variables
    . ${g_shell_path}/bash/bin/linuxsetup/.config.bash

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
    # 2> ID de los paquetes del repositorio, separados por coma, que se mostrara en el menu para que pueda instalarse. Si desea usar el por defecto envie "EMPTY".
    #    Los paquete basicos, por defecto, que se muestran en el menu son: Curl,UnZip, OpenSSL y Tmux
    # 3> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git. Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion ".config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
    #    - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
    # 4> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    #    Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion ".config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se usara el valor '.files'.
    # 5> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado \
    #    "/var/opt/tools" o "~/tools".
    # 6> Ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts").
    #    Si se envia vacio o EMPTY se usara el directorio predeterminado.
    #       > Comandos      : "/usr/local/bin"      (para todos los usuarios) y "~/.local/bin"         (solo para el usuario actual)
    #       > Archivos man1 : "/usr/local/man/man1" (para todos los usuarios) y "~/.local/man/man1"    (solo para el usuario actual)
    #       > Archivo fuente: "/usr/share/fonts"    (para todos los usuarios) y "~/.local/share/fonts" (solo para el usuario actual)
    # 7> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    # 8> Flag '0' para limpiar el cache de paquetes del sistema operativo. Caso contrario, use 1.
    _gp_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        _gp_list_pckg_ids="$2"
    fi

    #Calcular el valor efectivo de 'g_repo_name'.
    if [ ! -z "$4" ] && [ "$4" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_repo_name="$4"
    fi

    if [ -z "$g_repo_name" ]; then
        g_repo_name='.files'
    fi

    #Obtener los valores efectivo de la variable 'g_targethome_path', 'g_repo_path', 'g_targethome_owner', 'g_targethome_group'
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_targethome_path="$3"
    fi

    get_targethome_info "$g_repo_name" "$g_targethome_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        exit 111
    fi


    #Obtener la ruta real del folder donde se alamacena los de programas 'g_programs_path'
    if [ ! -z "$5" ] && [ "$5" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_programs_path="$5"
    fi

    _g_is_noninteractive=1
    get_program_path $_g_is_noninteractive "$g_programs_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        printf 'No se pede establecer la ruta base donde se instalarán los programas.\n'
        exit 111
    fi



    #Obtener la ruta real del folder base de comandos 'g_cmd_base_path' 
    if [ ! -z "$6" ] && [ "$6" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_cmd_base_path="$6"
    fi

    get_command_path $_g_is_noninteractive "$g_cmd_base_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        printf 'No se pede establecer la ruta base donde se instalarán los comandos.\n'
        exit 111
    fi



    #Obtener la ruta rel del folder de los archivos temporales 'g_temp_path'
    if [ ! -z "$7" ] && [ "$7" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_temp_path="$7"
    fi
    get_temp_path "$g_temp_path"

    _gp_flag_clean_os_cache=1
    if [ "$8" = "0" ]; then
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
        g_install_main "$_gp_list_pckg_ids" $_gp_flag_clean_os_cache
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
    #    - El valor ingresado en el archivo de configuracion ".config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
    #    - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
    # 6> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    #    Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion ".config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se usara el valor '.files'.
    # 7> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado 
    #    "/var/opt/tools" o "~/tools".
    # 8> Ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts").
    #    Si se envia vacio o EMPTY se usara el directorio predeterminado.
    #       > Comandos      : "/usr/local/bin"      (para todos los usuarios) y "~/.local/bin"         (solo para el usuario actual)
    #       > Archivos man1 : "/usr/local/man/man1" (para todos los usuarios) y "~/.local/man/man1"    (solo para el usuario actual)
    #       > Archivo fuente: "/usr/share/fonts"    (para todos los usuarios) y "~/.local/share/fonts" (solo para el usuario actual)
    # 9> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    #10> El estado de la credencial almacenada para el sudo.
    #11> Flag '0' para limpiar el cache de paquetes del sistema operativo. Caso contrario, use 1.
    #12> Actualizar los paquetes del SO. Por defecto es 1 (false), si desea actualizar use 0.
    _gp_opciones=0
    if [ "$2" = "0" ]; then
        _gp_opciones=-1
    elif [[ "$2" =~ ^[0-9]+$ ]]; then
        _gp_opciones=$2
    else
        echo "Opciones de menu a instalar (parametro 2) \"$2\" no es valido."
        exit 110
    fi

    _gp_list_repo_ids=""
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        _gp_list_repo_ids="$3"
    fi

    if [ $_gp_opciones -lt 0 ] && [ -z "$_gp_list_repo_ids" ]; then
        printf 'Se debe ingresar un valor valido para el pametro 2 "%s" o el parametro 3 "%s". Ambos no pueden ser empty.\n' "$_gp_opciones" "$_gp_list_repo_ids"
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

    _gp_flag_upgrade_os_pkgs=1
    if [ "${12}" = "0" ]; then
        _gp_flag_upgrade_os_pkgs=0
    fi

    #Calcular el valor efectivo de 'g_repo_name'.
    if [ ! -z "$6" ] && [ "$6" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_repo_name="$6"
    fi

    if [ -z "$g_repo_name" ]; then
        g_repo_name='.files'
    fi

    #Obtener los valores efectivo de la variable 'g_targethome_path', 'g_repo_path', 'g_targethome_owner', 'g_targethome_group'
    if [ ! -z "$5" ] && [ "$5" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_targethome_path="$5"
    fi

    get_targethome_info "$g_repo_name" "$g_targethome_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        exit 111
    fi


    #Obtener la ruta real del folder donde se alamacena los de programas 'g_programs_path'
    if [ ! -z "$7" ] && [ "$7" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_programs_path="$7"
    fi

    _g_is_noninteractive=1
    get_program_path $_g_is_noninteractive "$g_programs_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        printf 'No se pede establecer la ruta base donde se instalarán los programas.\n'
        exit 111
    fi



    #Obtener la ruta real del folder base de comandos 'g_cmd_base_path' 
    if [ ! -z "$8" ] && [ "$8" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_cmd_base_path="$8"
    fi

    get_command_path $_g_is_noninteractive "$g_cmd_base_path"

    #Obtener los folderes temporal 'g_temp_path'
    if [ ! -z "$9" ] && [ "$9" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
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

        g_install_options $_gp_opciones "$_gp_list_repo_ids" "$_gp_list_pckg_ids" $_gp_flag_clean_os_cache $_gp_flag_upgrade_os_pkgs
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


