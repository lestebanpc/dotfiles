#!/bin/bash


#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/terminal/linux/functions/func_utility.bash

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

    #Si el usuario no tiene permisos a sudo o el SO no implementa sudo,
    # - Se instala/configura los binarios a nivel usuario, las fuentes a nivel usuario.
    # - No se instala ningun paquete/programa que requiere permiso 'root' para su instalación
    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

        #Ruta donde se instalaran los programas CLI (tiene una estructura de folderes y generalmente incluye mas de 1 binario).
        g_path_programs='/opt/tools'

        #Rutas de binarios, archivos de help (man) y las fuentes
        g_path_bin='/usr/local/bin'

    else

        #Ruta donde se instalaran los programas CLI (tiene una estructura de folderes y generalmente incluye mas de 1 binario).
        g_path_programs=~/tools

        #Rutas de binarios, archivos de help (man) y las fuentes
        g_path_bin=~/.local/bin

    fi

fi


#Funciones de utilidad
. ~/.files/setup/linux/_common_utility.bash


#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución mostrando el menu del opciones (siempre es interactiva).
                        #(1) Ejecución sin el menu de opciones, interactivo - instalar/actualizar un conjunto de repositorios
                        #(2) Ejecución sin el menu de opciones, interactivo - instalar/actualizar un solo repositorio
                        #(3) Ejecución sin el menu de opciones, no interactivo - instalar/actualizar un conjunto de repositorios
                        #(4) Ejecución sin el menu de opciones, no interactivo - instalar/actualizar un solo repositorio

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


#Menu personalizado: Opciones iniciales y especiales del menu (no estan vinculado al menu dinamico):
# > Actualizar todos paquetes del sistema operativo (Opción 1 del arreglo del menu)
g_opt_update_installed_pckg=$((1 << 0))
# > Actualizar todos los repositorios instalados (Opción 2 del arreglo del menu)
g_opt_update_installed_repo=$((1 << 1))


#Menu dinamico: Offset (desface) del indice del menu dinamico respecto a menu personalizado.
#               Generalmente el menu dinamico no inicia desde la primera opcion personalizado del menú.
g_offset_option_index_menu_install=2
g_offset_option_index_menu_uninstall=0



#}}}




#Funciones principales y el menú {{{


function g_install_repository() {

    #1. Argumentos 
    local p_repo_id="$1"
    local p_repo_title_template="$2"

    local p_only_update_if_its_installed=1
    if [ "$3" = "0" ]; then
        p_only_update_if_its_installed=0
    fi

    #1. Inicializaciones
    local l_status=0
    local l_repo_name="${gA_packages[$p_repo_id]}"

}


#
#Parametros de entrada (Argumentos):
#  1 > Opciones relacionados con los repositorios que se se instalaran (entero que es suma de opciones de tipo 2^n).
#
function g_install_repositories() {
    
    #1. Argumentos 
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    if [ $p_input_options -le 0 ]; then
        echo "ERROR: Argumento de opciones \"${p_input_options}\" es incorrecta"
        return 99
    fi

}    

function _show_menu_install_core() {

    print_text_in_center "Menu de Opciones (Install/Update)" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"
    printf " (%ba%b) Actualizar los paquetes del SO existentes y los binarios/programas ya instalados\n" "$g_color_green1" "$g_color_reset"
    printf " (%bb%b) Instalar o actualizar: Binarios basicos, 'Nerd Fonts', NeoVim\n" "$g_color_green1" "$g_color_reset"
    printf " (%bc%b) Instalar o actualizar: Binarios basicos, 'Nerd Fonts', NeoVim, .NET SDK/LSP/DAP, PowerShell\n" "$g_color_green1" "$g_color_reset"
    printf " (%bd%b) Instalar o actualizar los runtime, SDK, LSP y DAP: .NET, Java, NodeJS, C/C++, Rust, Go\n" "$g_color_green1" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    get_length_menu_option $g_offset_option_index_menu_install
    local l_max_digits=$?

    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes existentes del sistema operativo\n" "$g_color_green1" "$g_opt_update_installed_pckg" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar solo los repositorios de programas ya instalados\n" "$g_color_green1" "$g_opt_update_installed_repo" "$g_color_reset"

    print_line '-' $g_max_length_line "$g_color_gray1"

}


function g_install_main() {

    #1. Pre-requisitos
   
    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_green1" 
    _show_menu_install_core

    #3. Mostar la ultima parte del menu y capturar la opcion elegida
    local l_flag_continue=0
    local l_options=""
    local l_value_option_a=$(($g_opt_update_installed_pckg + $g_opt_update_installed_repo))
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -r l_options

        case "$l_options" in

            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
                g_install_repositories $l_value_option_a 0
                ;;

            b)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
                #    4> Binarios basicos
                #   32> Fuente 'Nerd Fonts'
                #   64> Editor NeoVIM
                g_install_repositories 100 0
                ;;

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
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
                    printf '\n'
                    g_install_repositories $l_options 0
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

    printf '%bUsage:\n\n' "$g_color_gray1"
    printf '  > Instalar repositorios mostrando el menú de opciones (interactivo):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash\n%b' "$g_color_yellow1" "$g_color_gray1"
    printf '  > Instalar/Actualizar un grupo de repositorios sin mostrar el menú, pero interactivo:\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 1 MENU-OPTIONS\n%b' "$g_color_yellow1" "$g_color_gray1"
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 1 MENU-OPTIONS SUDO-STORAGE-OPTIONS\n%b' "$g_color_yellow1" "$g_color_gray1"
    printf '  > Instalar/Actualizar un repositorio sin mostrar el  menú, pero interactivo:\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 2 REPO-ID%b\n' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 2 REPO-ID SUDO-STORAGE-OPTIONS%b\n' "$g_color_yellow1" "$g_color_reset"
    printf '  > Instalar/Actualizar un grupo de repositorios sin mostrar el menú, pero no-interactivo:\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 3 MENU-OPTIONS\n%b' "$g_color_yellow1" "$g_color_gray1"
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 3 MENU-OPTIONS SUDO-STORAGE-OPTIONS\n%b' "$g_color_yellow1" "$g_color_gray1"
    printf '  > Instalar/Actualizar un repositorio sin mostrar el  menú, pero no-interactivo:\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 4 REPO-ID%b\n' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 4 REPO-ID SUDO-STORAGE-OPTIONS%b\n\n' "$g_color_yellow1" "$g_color_reset"

}


#1. Argumentos fijos del script


#Argumento 1: Si es "uninstall" se desintalar (siempre muestra el menu)
#             Caso contrario se se indica el tipo de configuración (instalación/actualización)
if [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
elif [ ! -z "$1" ]; then
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

    #Validar los requisitos
    fulfill_preconditions $g_os_subtype_id $gp_type_calling 0 1
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_install_main
    else
        _g_result=111
    fi

#2.2. Instalando los repositorios especificados por las opciones indicas en '$2'
elif [ $gp_type_calling -eq 1 ] || [ $gp_type_calling -eq 3 ]; then

    #Parametros del script usados hasta el momento:
    # 1> Tipo de configuración: 1 (instalación/actualización).
    # 2> Opciones de menu a ejecutar: entero positivo.
    # 3> El estado de la credencial almacenada para el sudo.
    gp_opciones=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        gp_opciones=$2
    else
        echo "Parametro 2 \"$2\" debe ser una opción valida."
        exit 110
    fi

    if [[ "$3" =~ ^[0-2]$ ]]; then
        g_status_crendential_storage=$3

        if [ $g_status_crendential_storage -eq 0 ]; then
            g_is_credential_storage_externally=0
        fi

    fi

    #Validar los requisitos
    fulfill_preconditions $g_os_subtype_id $gp_type_calling 0 1
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then

        g_install_repositories $gp_opciones
        _g_status=$?

        #Informar si se nego almacenar las credencial cuando es requirido
        if [ $_g_status -eq 120 ]; then
            _g_result=120
        #Si la credencial se almaceno en este script (localmente). avisar para que lo cierre el caller
        elif [ $g_is_credential_storage_externally -ne 0 ] && [ $g_status_crendential_storage -eq 0 ]; then
            _g_result=119
        fi

    else
        _g_result=111
    fi

#2.3. Instalando un solo repositorio del ID indicao por '$2'
else

    #Parametros del script usados hasta el momento:
    # 1> Tipo de configuración: 1 (instalación/actualización).
    # 2> ID del repositorio a instalar: identificado interno del respositorio
    # 3> El estado de la credencial almacenada para el sudo.
    gp_repo_id="$2"
    if [ -z "$gp_repo_id" ]; then
       echo "Parametro 2 \"$2\" debe ser un ID de repositorio valido"
       exit 110
    fi

    if [[ "$3" =~ ^[0-2]$ ]]; then
        g_status_crendential_storage=$3

        if [ $g_status_crendential_storage -eq 0 ]; then
            g_is_credential_storage_externally=0
        fi
    fi

    #Validar los requisitos
    fulfill_preconditions $g_os_subtype_id $gp_type_calling 0 1
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then

        g_install_repository "$gp_repo_id" "" 1
        _g_status=$?

        #Informar si se nego almacenar las credencial cuando es requirido
        if [ $_g_status -eq 0 ]; then

            if [ $_g_status -eq 120 ]; then
                _g_result=120
            #Si la credencial se almaceno en este script (localmente). avisar para que lo cierre el caller
            elif [ $g_is_credential_storage_externally -ne 0 ] && [ $g_status_crendential_storage -eq 0 ]; then
                _g_result=119
            fi

        fi

    else
        _g_result=111
    fi

fi
    

exit $_g_result


#}}}


