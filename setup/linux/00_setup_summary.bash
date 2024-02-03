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

fi


#Funciones de utilidad
. ~/.files/setup/linux/_common_utility.bash


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


#}}}




#Funciones principales y el menú {{{



#
#Parametros de entrada (Argumentos):
#  1 > Opciones relacionados con los repositorios que se se instalaran (entero que es suma de opciones de tipo 2^n).
#
function g_install_options() {
    
    #1. Argumentos 
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    if [ $p_input_options -le 0 ]; then
        echo "ERROR: Argumento de opciones \"${p_input_options}\" es incorrecta"
        return 99
    fi

    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    #Flag '0' cuando no se realizo ninguna instalacion de paquetes (si se instala un paquete del SO, se obligará a actualizar el gestor de paquetes).
    local l_flag_packages_nonupgraded=0

    #2. Opción> Paquetes basicos: Curl, OpenSSL y Tmux
    local l_option=4
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Instalando '%bCurl%b', '%bOpenSSL%b' y '%bTmux%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 2/4 (ejecución sin menu, para instalar/actualizar un grupo paquetes)
            # 2> Paquetes a instalar 
            # 3> El estado de la credencial almacenada para el sudo
            # 4> Actualizar los paquetes del SO antes. Por defecto es 1 (false).
            if [ $l_is_noninteractive -eq 1 ]; then
                ~/.files/setup/linux/03_setup_packages.bash 2 'curl,openssl,tmux' $g_status_crendential_storage $l_flag_packages_nonupgraded
                l_status=$?
            else
                ~/.files/setup/linux/03_setup_packages.bash 4 'curl,openssl,tmux' $g_status_crendential_storage $l_flag_packages_nonupgraded
                l_status=$?
            fi

            if [ $l_flag_packages_nonupgraded -eq 0 ]; then
                l_flag_packages_nonupgraded=1
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
                g_status_crendential_storage=0
            fi

        fi

    fi

    #3. Opción> Programas basicos: Comandos basicos, VIM, NeoVIM, NodeJs y Python
    l_option=8
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Instalando '%bComandos basicos%b', '%bVIM/NeoVIM%b', '%bNodeJS%b' y '%bPython%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
                   "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Solo actualizar los paquetes del SO, si no se hizo antes
            local l_options=152
            if [ $l_flag_packages_nonupgraded -eq 0 ]; then
                l_options=153
                $l_flag_packages_nonupgraded=1
            fi

            #Parametros:
            # 1> Tipo de ejecución: 1/2 (ejecución sin menu, interactiva y no-interactiva)
            # 2> Paquetes a instalar: 8 (Python/NodeJS) + 16 (VIM) + 128 (NeoVIM)
            # 3> El estado de la credencial almacenada para el sudo
            # 4> Actualizar los paquetes del SO antes. Por defecto es 1 (false).
            if [ $l_is_noninteractive -eq 1 ]; then
                ~/.files/setup/linux/02_setup_profile.bash 1 $l_options $g_status_crendential_storage
                l_status=$?
            else
                ~/.files/setup/linux/02_setup_profile.bash 2 $l_options $g_status_crendential_storage
                l_status=$?
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
                g_status_crendential_storage=0
            fi

        fi

    fi

    #4. Opción> LSP/DAP de .NET : Omnisharp-Roslyn, NetCoreDbg
    l_option=16
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Instalando %bLSP/DAP de .NET%b: '%bOmnisharp-Roslyn%b' y '%bNetCoreDbg%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
                   "$g_color_cian1" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 2/4 (ejecución sin menu para instalar/actualizar un respositorio especifico)
            # 2> Repsositorio a instalar/acutalizar: 
            # 3> El estado de la credencial almacenada para el sudo
            # 4> Install only last version: por defecto es 1 (false). Solo si ingresa 0 es (true).
            # 5> Flag '0' para mostrar un titulo si se envia un repositorio en el parametro 2. Por defecto es '1' 
            if [ $l_is_noninteractive -eq 1 ]; then
                
                ~/.files/setup/linux/01_setup_commands.bash 2 "roslyn,netcoredbg" $g_status_crendential_storage            
                l_status=$?
            else
                ~/.files/setup/linux/01_setup_commands.bash 4 "roslyn,netcoredbg" $g_status_crendential_storage            
                l_status=$?
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
               g_status_crendential_storage=0
            fi

        fi

    fi

    #5. Opción> LSP/DAP de Java : Jdtls
    l_option=32
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Instalando %bLSP/DAP de Java%b: '%bJdtls%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
                   "$g_color_cian1" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 2/4 (ejecución sin menu para instalar/actualizar un respositorio especifico)
            # 2> Repsositorio a instalar/acutalizar: 
            # 3> El estado de la credencial almacenada para el sudo.
            # 4> Install only last version: por defecto es 1 (false). Solo si ingresa 0 es (true).
            # 5> Flag '0' para mostrar un titulo si se envia un repositorio en el parametro 2. Por defecto es '1' 
            if [ $l_is_noninteractive -eq 1 ]; then
                ~/.files/setup/linux/01_setup_commands.bash 2 "jdtls" $g_status_crendential_storage 0 0
                l_status=$?
            else
                ~/.files/setup/linux/01_setup_commands.bash 4 "jdtls" $g_status_crendential_storage 0 0
                l_status=$?
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
               g_status_crendential_storage=0
            fi

        fi

    fi


    #6. Opción> Configurar el profile del usuario y VIM/NeoVIM como Editor
    l_option=1
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Configurar el %bprofile del usuario%b, '%bVIM/NeoVIM%b' como %bEditor%b\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
                   "$g_color_cian1" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 1/2 (ejecución sin menu, interactiva y no-interactiva)
            # 2> Opciones a configurar: 2 (Profile) + 4 (Recrear enlaces simbolicos) + 32 (VIM como Editor) + 256 (NeoVIM como Editor)
            # 3> El estado de la credencial almacenada para el sudo
            # 4> Actualizar los paquetes del SO antes. Por defecto es 1 (false).
            if [ $l_is_noninteractive -eq 1 ]; then
                ~/.files/setup/linux/02_setup_profile.bash 1 294 $g_status_crendential_storage
                l_status=$?
            else
                ~/.files/setup/linux/02_setup_profile.bash 2 294 $g_status_crendential_storage
                l_status=$?
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
                g_status_crendential_storage=0
            fi

        fi

    fi

    #7. Opción> Configurar el profile del usuario y VIM/NeoVIM como Developer
    l_option=2
    if [ $(( $p_input_options & $l_option )) -eq $l_option ]; then

        #Solo soportado para los que tenga acceso a root
        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            #Mostrar el titulo de instalacion
            print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "> Configurar el %bprofile del usuario%b, '%bVIM/NeoVIM%b' como %bDeveloper%b\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
                   "$g_color_cian1" "$g_color_reset"
            print_line '─' $g_max_length_line "$g_color_blue1"

            #Parametros:
            # 1> Tipo de ejecución: 1/2 (ejecución sin menu, interactiva y no-interactiva)
            # 2> Opciones a configurar: 2 (Profile) + 4 (Recrear enlaces simbolicos) + 64 (VIM como IDE) + 512 (NeoVIM como IDE)
            # 3> El estado de la credencial almacenada para el sudo
            # 4> Actualizar los paquetes del SO antes. Por defecto es 1 (false).
            if [ $l_is_noninteractive -eq 1 ]; then
                ~/.files/setup/linux/02_setup_profile.bash 1 582 $g_status_crendential_storage
                l_status=$?
            else
                ~/.files/setup/linux/02_setup_profile.bash 2 582 $g_status_crendential_storage
                l_status=$?
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
                g_status_crendential_storage=0
            fi

        fi

    fi

    #7. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #   Si no se invoca usando el menú y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi


}    

function _show_menu_install_core() {

    print_text_in_center "Menu de Opciones (Install/Update)" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"

    local l_max_digits=2

    printf " ( ) Configuración personalizado para el usuario:\n"
    printf "     (%b%0${l_max_digits}d%b) Configurar el profile del usuario y VIM/NeoVIM como %bEditor%b\n" "$g_color_green1" "1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Configurar el profile del usuario y VIM/NeoVIM como %bDeveloper%b\n" "$g_color_green1" "2" "$g_color_reset" "$g_color_cian1" "$g_color_reset"

    printf " ( ) Programas requeridos a instalar %b(usualmente instalado como root)%b:\n" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Paquetes  basicos: %bCurl, OpenSSL y Tmux%b\n" "$g_color_green1" "4" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Programas basicos: %bComandos basicos, VIM, NeoVIM, NodeJs y Python%b\n" "$g_color_green1" "8" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) LSP/DAP de .NET  : %bOmnisharp-Roslyn, NetCoreDbg%b\n" "$g_color_green1" "16" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) LSP/DAP de .Java : %bJdtls%b\n" "$g_color_green1" "32" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

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
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -r l_options

        case "$l_options" in

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
                    g_install_options $l_options
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
    printf '    %b~/.files/setup/linux/00_setup_summary.bash 0\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '  > %bInstalar/Actualizar un grupo de opciones sin mostrar el menú%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/00_setup_summary.bash CALLING_TYPE MENU-OPTIONS SUDO-STORAGE-OPTIONS\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %bDonde:%b\n' "$g_color_gray1" "$g_color_reset"
    printf '    > %bCALLING_TYPE%b (para este escenario) es 1 si es interactivo y 2 si es no-interactivo.%b\n\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bSUDO-STORAGE-OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi es root por lo que no se requiere almacenar la credenciales, use 2. Caso contrario, use 0 si se almaceno la credencial y 1 si no se pudo almacenar las credenciales.%b\n\n' \
           "$g_color_gray1" "$g_color_reset"

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

    #Validar los requisitos (algunas opciones requiere root y otros no)
    fulfill_preconditions $g_os_subtype_id 0 0 1
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_install_main
    else
        _g_result=111
    fi

#2.2. Instalando los repositorios especificados por las opciones indicas en '$2'
#elif [ $gp_type_calling -eq 1 ] || [ $gp_type_calling -eq 2 ]; then
else

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

    #Validar los requisitos (algunas opciones requiere root y otros no)
    fulfill_preconditions $g_os_subtype_id 1 0 1
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then

        g_install_options $gp_opciones
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


fi
    

exit $_g_result


#}}}


