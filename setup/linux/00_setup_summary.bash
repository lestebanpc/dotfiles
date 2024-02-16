#!/bin/bash

#Parametros de entrada:
#  1> La ruta relativa (o absoluta) de un archivos del repositorio
#Parametros de salida: 
#  STDOUT> La ruta base donde esta el repositorio
function _get_current_repo_path() {

    #Obteniendo la ruta absoluta del parametro ingresado
    local l_path=''
    l_path=$(realpath "$1" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        echo "$HOME"
        return 1
    fi

    #Obteniendo la ruta base
    l_path=${l_path%/.files/*}
    echo "$l_path"
    return 0
}

#Inicialización Global {{{

declare -r g_repo_path=$(_get_current_repo_path "${BASH_SOURCE[0]}")

#Si lo ejecuta un usuario diferente al actual (al que pertenece el repositorio)
#UID del Usuario y GID del grupo (diferente al actual) que ejecuta el script actual
g_other_calling_user=''


#Funciones generales, determinar el tipo del SO y si es root
. ${g_repo_path}/.files/terminal/linux/functions/func_utility.bash

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
if [ -z "$g_user_is_root" ]; then

    #Determinar si es root y el soporte de sudo
    # > 'g_user_is_root'                : 0 si es root. Caso contrario no es root.
    # > 'g_user_sudo_support'           : Si el so y el usuario soportan el comando 'sudo'
    #    > 0 : se soporta el comando sudo con password
    #    > 1 : se soporta el comando sudo sin password
    #    > 2 : El SO no implementa el comando sudo
    #    > 3 : El usuario no tiene permisos para ejecutar sudo
    #    > 4 : El usuario es root (no requiere sudo)
    get_user_options

fi


#Funciones de utilidad
. ${g_repo_path}/.files/setup/linux/_common_utility.bash


#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución mostrando el menu del opciones (siempre es interactiva).
                        #(1) Ejecución sin el menu de opciones, interactivo - instalar/actualizar un conjunto de repositorios
                        #(2) Ejecución sin el menu de opciones, no interactivo - instalar/actualizar un conjunto de repositorios

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


declare -r g_default_list_package_ids='curl,unzip,openssl,tmux'

#Opciones de '02_setup_profile.bash' para configurar VIM/NeoVIM
#  0> Crear archivos de configuración como Editor
#  1> Crear archivos de configuración como IDE
#  2> Descargar plugins de Editor e indexarlos
#  3> Descargar plugins de Editor (sin indexarlos)
#  4> Descargar plugins de IDE e indexarlos
#  5> Descargar plugins de IDE (sin indexarlos)
#  6> Indexar la documentación (de plugins anteriormente descargados)
#  7> Inicializar los plugins de IDE
declare -ra ga_options_config_vim=(524288 1048576 209715 4194304 8388608 16777216 33554432 67108864)
declare -ra ga_options_config_nvim=(134217728 268435456 536870912 1073741824 2147483648 4294967296 8589934592 17179869184)
declare -ra ga_title_config=(
    "Crear archivos de configuración como Editor"
    "Crear archivos de Configuración como IDE"
    "Descargar plugins de Editor e indexarlos"
    "Descargar plugins de Editor (sin indexarlos)"
    "Descargar plugins de IDE e indexarlos"
    "Descargar plugins de IDE (sin indexarlos)"
    "Indexar la documentación (de plugins anteriormente descargados)"
    "Inicializar los plugins de IDE")

#Opciones de '02_setup_profile.bash'para instalar lo necesario para VIM/NeoVIM
#  0> Instalar Python
#  1> Instalar paquete de usuario de Python: 'jtbl'
#  2> Instalar paquete de usuario de Python: 'jtbl', 'compiledb', 'rope' y 'pynvim'
#  3> Instalar NodeJS
#  4> Instalar paquete globales de NodeJS: 'Prettier'
#  5> Instalar paquete globales de NodeJS: 'Prettier', 'NeoVIM' y 'TreeSitter CLI'
#  6> Instalar VIM
#  7> Instalar NeoVIM
declare -ra ga_options_install=(8 131072 32 16 262144 64 128 1024)
declare -ra ga_title_install=(
    "Python/Pip"
    "Paquetes de usuario de Python 'jtbl'"
    "Paquetes de usuario de Python 'jtbl', 'compiledb', 'rope' y 'pynvim'"
    "NodeJS"
    "Paquetes globales de Python 'Prettier'"
    "Paquetes globales de Python 'Prettier', 'NeoVIM' y 'TreeSitter CLI'"
    "VIM"
    "NeoVIM")

#Opciones de '02_setup_profile.bash' generales
# 0> Actualizar los paquetes del SO
# 1> Crear los enlaces simbolicos del profile del usuario
# 2> Flag para re-crear un enlaces simbolicos en caso de existir
declare -ra ga_options_general=(1 2 4)
declare -ra ga_title_general=(
    "Actualizar los paquetes del SO"
    "Crear los enlaces simbolicos del profile del usuario"
    "Flag para re-crear un enlaces simbolicos en caso de existir")


#}}}




#Funciones principales y el menú {{{


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
    local l_option=32
    if [ $p_input_options -gt 0 ] && [ $(( $p_input_options & $l_option )) -eq $l_option ] && [ ! -z "$p_list_pckg_ids" ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

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
                ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 2 "$p_list_pckg_ids" $g_status_crendential_storage $p_flag_upgrade_os_pkgs
                l_status=$?
            else
                ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 4 "$p_list_pckg_ids" $g_status_crendential_storage $p_flag_upgrade_os_pkgs
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

        fi

    fi

    #4. Instalar comandos basicos (usar un grupo de comandos especifico)
    l_option=64
    if [ $p_input_options -gt 0 ] && [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            printf '\n'
            print_line '─' $g_max_length_line  "$g_color_blue1"
            if [ $g_os_subtype_id -eq 1 ]; then
                printf "> Instalando %bComandos Basicos%b: '%bbat, jq, yq, ripgrep, delta, oh-my-posh, fd y xsv%b.'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            else
                printf "> Instalando %bComandos Basicos%b: '%bfzf, bat, jq, yq, ripgrep, delta, oh-my-posh, fd y xsv%b.'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            fi
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 1/3 (ejecución sin menu para instalar/actualizar un respositorio especifico)
            # 2> Opciones de menu de Repositorio a instalar/acutalizar: 
            # 3> El estado de la credencial almacenada para el sudo.
            # 4> Install only last version: por defecto es 1 (false). Solo si ingresa 0 es (true).
            # 5> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
            if [ $l_is_noninteractive -eq 1 ]; then
                ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 1 4 $g_status_crendential_storage 0 "$g_other_calling_user"
                l_status=$?
            else
                ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 3 4 $g_status_crendential_storage 0 "$g_other_calling_user"
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

    #5. Instalar y/o Configurar todo lo relacionado con VIM/NeoVIM: NodeJs (y sus paquetes globales), Python/Pip (y sus paquetes de usuario), VIM y NeoVIM

    #5.1. Determinar las opciones elegidas por el usuario
    local la_options_config_vim=()
    local la_options_config_nvim=()
    local la_options_install=()
    local la_options_general=()
    local l_i=0
    local l_info=''
    local l_prg_options=0

    if [ $p_input_options -gt 0 ]; then

        #5.1.1. Determinar las opciones elegidas

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
            la_options_config_vim[1]=0
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

        #5.1.1. Determinar el valor de estas las opciones elegidas
        l_prg_options=0
        l_info='Se realizara las siguientes instalaciones/configuraciones:'

        for (( l_i = 0; l_i < ${#ga_options_general[@]}; l_i++ )); do
            if [ "${la_options_general[${l_i}]}" = "0" ]; then
                ((l_prg_options= l_prg_options + ${ga_options_general[${l_i}]}))
                printf -v l_info '%s\n   > General > %b%s%b' "$l_info" "$g_color_gray1" "${ga_title_general[${l_i}]}" "$g_color_reset"
            fi 
        done

        for (( l_i = 0; l_i < ${#ga_options_install[@]}; l_i++ )); do
            if [ "${la_options_install[${l_i}]}" = "0" ]; then
                ((l_prg_options= l_prg_options + ${ga_options_install[${l_i}]}))
                printf -v l_info '%s\n   > Instalar %b%s%b' "$l_info" "$g_color_gray1" "${ga_title_install[${l_i}]}" "$g_color_reset"
            fi 
        done

        for (( l_i = 0; l_i < ${#ga_options_config_vim[@]}; l_i++ )); do
            if [ "${la_options_config_vim[${l_i}]}" = "0" ]; then
                ((l_prg_options= l_prg_options + ${ga_options_config_vim[${l_i}]}))
                printf -v l_info '%s\n   > Configuración VIM   > %b%s%b' "$l_info" "$g_color_gray1" "${ga_title_config[${l_i}]}" "$g_color_reset"
            fi 
        done

        for (( l_i = 0; l_i < ${#ga_options_config_nvim[@]}; l_i++ )); do
            if [ "${la_options_config_nvim[${l_i}]}" = "0" ]; then
                ((l_prg_options= l_prg_options + ${ga_options_config_nvim[${l_i}]}))
                printf -v l_info '%s\n   > Configuración NeoVIM > %b%s%b' "$l_info" "$g_color_gray1" "${ga_title_config[${l_i}]}" "$g_color_reset"
            fi 
        done

    fi

    #5.3. Instalar/Configurar el profile
    if [ $l_prg_options -ne 0 ] && [ $l_prg_options -ne 4 ] && [ $l_prg_options -ne 5 ]; then

       #Solo soportado para los que tenga acceso a root
       if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

           #Mostrar el titulo de instalacion
           printf '\n'
           print_line '─' $g_max_length_line  "$g_color_blue1"
           printf "> Instalando/configurando para VIM/NeoVIM como Editor/IDE\n"
           print_line '─' $g_max_length_line "$g_color_blue1"
           printf '%b\n' "$l_info"

           #Parametros:
           # 1> Tipo de ejecución: 1/2 (ejecución sin menu, interactiva y no-interactiva)
           # 2> Paquetes a instalar: 40 (Python y sus paquetes) + 80 (NodeJS y sus paquetes) + 128 (VIM) + 1024 (NeoVIM)
           # 3> El estado de la credencial almacenada para el sudo
           # 4> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
           if [ $l_is_noninteractive -eq 1 ]; then
               ${g_repo_path}/.files/setup/linux/02_setup_profile.bash 1 $l_prg_options $g_status_crendential_storage "$g_other_calling_user"
               l_status=$?
           else
               ${g_repo_path}/.files/setup/linux/02_setup_profile.bash 2 $l_prg_options $g_status_crendential_storage "$g_other_calling_user"
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

    fi

    #8. Opción> Lista de repositorios de comandos adicionales a instalar (segun una lista de ID de repositorios)

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

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            printf '\n'
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Instalando repositorios %bcomandos/programas%b: '%b%s%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "${p_list_repo_ids/,/, }" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 2/4 (ejecución sin menu para instalar/actualizar un respositorio especifico)
            # 2> Repsositorio a instalar/acutalizar: 
            # 3> El estado de la credencial almacenada para el sudo
            # 4> Install only last version: por defecto es 1 (false). Solo si ingresa 0 es (true).
            # 5> Flag '0' para mostrar un titulo si se envia, como parametro 2, un solo repositorio a configurar. Por defecto es '1' 
            # 6> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
            if [ $l_is_noninteractive -eq 1 ]; then
                
                ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 2 "$p_list_repo_ids" $g_status_crendential_storage 0 1 "$g_other_calling_user"
                l_status=$?
            else
                ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 4 "$p_list_repo_ids" $g_status_crendential_storage 0 1 "$g_other_calling_user" 
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

    fi



    if [ $p_flag_clean_os_cache -eq 0 ] && [ $l_exist_packages_installed -eq 0 ]; then
        printf 'Clean packages cache...\n'
        clean_os_cache $g_os_subtype_id $l_is_noninteractive
    fi

    #10. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
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
    printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes  basicos%b: %b%s%b\n" "$g_color_green1" "1024" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" \
           "$l_pckg_ids" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bcomandos  basicos%b: %bfzf, bat, jq, yq, ripgrep, delta, oh-my-posh, fd y xsv.%b\n" "$g_color_green1" "2048" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bNodeJS%b y %bNpm%b\n" "$g_color_green1" "4096" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes globales%b de %bNodeJS%b: %b'Prettier'%b\n" "$g_color_green1" "8192" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bPython%b y %bPip%b\n" "$g_color_green1" "16384" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bVIM%b\n" "$g_color_green1" "32768" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bNeoVIM%b\n" "$g_color_green1" "65536" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Descargar %bPlugins de Editor%b de %bVIM%b\n" "$g_color_green1" "131072" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Descargar %bPlugins de Editor%b de %bNeoVIM%b\n" "$g_color_green1" "262144" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Descargar %bPlugins de IDE%b    de %bVIM%b\n" "$g_color_green1" "524288" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Descargar %bPlugins de IDE%b    de %bNeoVIM%b\n" "$g_color_green1" "1048576" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
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
    printf '    %b~/.files/setup/linux/00_setup_summary.bash uninstall\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '  > %bInstalar repositorios mostrando el menú de opciones (interactivo)%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash 0 LIST-PCKG-IDS CLEAN-OS-CACHE\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un grupo de opciones sin mostrar el menú%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS LIST-REPO-IDS\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS LIST-REPO-IDS LIST-PCKG-IDS SUDO-STORAGE-OPTIONS CLEAN-OS-CACHE UPGRADE-OS-PACKAGES OTHER-USERID\n\n%b' \
           "$g_color_yellow1" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bCALLING_TYPE%b es 1 si es interactivo y 2 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bMENU-OPTIONS%b Las opciones de menu a instalar. Si no desea especificar coloque 0.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bLIST-REPO-IDS %bID de los repositorios de comandos a configurar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bLIST-PCKG-IDS %b.ID de los paquetes del repositorio del SO, separados por coma, a instalar si elige la opcion de menu 32. Si desea usar el los los paquetes por defecto envie "EMPTY".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bLos paquete basicos por defecto que son: Curl, UnZip, OpenSSL y Tmux.%b\n' "$g_color_gray1" "$g_color_reset"
    printf '  > %bSUDO-STORAGE-OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi es root por lo que no se requiere almacenar la credenciales, use 2. Caso contrario, use 0 si se almaceno la credencial y 1 si no se pudo almacenar las credenciales.%b\n' \
           "$g_color_gray1" "$g_color_reset"
    printf '  > %bCLEAN-OS-CACHE%b es 0 si se limpia el cache de paquetes instalados. Por defecto es 1.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bUPGRADE-OS-PACKAGES%b Actualizar los paquetes del SO. Por defecto es 1 (false), si desea actualizar use 0.\n%b' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bOTHER-USERID %bEl GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID".%b\n\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


#1. Argumentos fijos del script

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


#2. Logica principal del script (incluyendo los argumentos variables)
_g_result=0
_g_status=0

#Aun no se ha solicitado almacenar temporalmente las credenciales para el sudo
g_status_crendential_storage=-1
#La credencial no se almaceno por un script externo.
g_is_credential_storage_externally=1


#Instalar y actualizar los artefactos de un repositorio

#2.1. Por defecto, mostrar el menu para escoger lo que se va instalar
if [ $gp_type_calling -eq 0 ]; then

    #Parametros del script usados hasta el momento:
    # 1> Tipo de invocación (sin menu): 1/2
    # 2> ID de los paquetes del repositorio, separados por coma, que se mostrara en el menu para que pueda instalarse. Si desea usar el por defecto envie "EMPTY".
    #    Los paquete basicos, por defecto, que se muestran en el menu son: Curl,UnZip, OpenSSL y Tmux
    # 3> Flag '0' para limpiar el cache de paquetes del sistema operativo. Caso contrario, use 1.
    _gp_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        _gp_list_pckg_ids="$2"
    fi

    _gp_flag_clean_os_cache=1
    if [ "$3" = "0" ]; then
        _gp_flag_clean_os_cache=0
    fi

    #Validar los requisitos (algunas opciones requiere root y otros no)
    #  1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info') 
    #  2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  3 > Flag '0' si se requere curl
    #  4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    #  5 > Path donde se encuentra el directorio donde esta el '.git'
    fulfill_preconditions $g_os_subtype_id 0 1 1 "$g_repo_path"
    _g_status=$?


    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_install_main "$_gp_list_pckg_ids" $_gp_flag_clean_os_cache
    else
        _g_result=111
    fi

#2.2. Instalando los repositorios especificados por las opciones indicas en '$2'
#elif [ $gp_type_calling -eq 1 ] || [ $gp_type_calling -eq 2 ]; then
else

    #Parametros del script usados hasta el momento:
    # 1> Tipo de invocación (sin menu): 1/2
    # 2> Opciones de menu a ejecutar: entero positivo.
    # 3> ID de los repositorios de comandos a configurar, separados por coma. Si no desea configurarse ninguno envie "EMPTY".
    # 4> ID de los paquetes del repositorio del SO, separados por coma, a instalar si elige la opcion de menu 32. Si desea usar el los los paquetes por defecto envie "EMPTY".
    #    Los paquetes por defecto que son: Curl, UnZip, OpenSSL y Tmux.
    # 5> El estado de la credencial almacenada para el sudo.
    # 6> Flag '0' para limpiar el cache de paquetes del sistema operativo. Caso contrario, use 1.
    # 7> Actualizar los paquetes del SO. Por defecto es 1 (false), si desea actualizar use 0.
    # 8> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
    _gp_opciones=0
    if [ "$2" = "0" ]; then
        _gp_opciones=-1
    elif [[ "$2" =~ ^[0-9]+$ ]]; then
        _gp_opciones=$2
    else
        echo "Opciones de menu a instalar (parametro 2) \"$2\" no es valido."
        exit 110
    fi

    _gp_list_repo_ids="EMPTY"
    if [ ! -z "$3" ]; then
        _gp_list_repo_ids="$3"
    fi

    _gp_list_pckg_ids="$g_default_list_package_ids"
    if [ ! -z "$4" ] && [ "$4" != "EMPTY" ]; then
        _gp_list_pckg_ids="$4"
    fi

    if [[ "$5" =~ ^[0-2]$ ]]; then
        g_status_crendential_storage=$5

        if [ $g_status_crendential_storage -eq 0 ]; then
            g_is_credential_storage_externally=0
        fi

    fi

    _gp_flag_clean_os_cache=1
    if [ "$6" = "0" ]; then
        _gp_flag_clean_os_cache=0
    fi

    _gp_flag_upgrade_os_pkgs=1
    if [ "$7" = "0" ]; then
        _gp_flag_upgrade_os_pkgs=0
    fi

    #Solo si el script e  ejecuta con un usuario diferente al actual (al que pertenece el repositorio)
    g_other_calling_user=''
    if [ "$g_repo_path" != "$HOME" ] && [ ! -z "$8" ]; then
        if [[ "$8" =~ ^[0-9]+:[0-9]+$ ]]; then
            g_other_calling_user="$8"
        else
            echo "Parametro 8 \"$8\" debe ser tener el formado 'UID:GID'."
            exit 110
        fi
    fi

    #Validar los requisitos (algunas opciones requiere root y otros no)
    #  1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info') 
    #  2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  3 > Flag '0' si se requere curl
    #  4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    #  5 > Path donde se encuentra el directorio donde esta el '.git'
    fulfill_preconditions $g_os_subtype_id 1 1 1 "$g_repo_path"
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


