#!/bin/bash


#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/terminal/linux/functions/func_utility.bash

#Funciones de utilidad
. ~/.files/setup/linux/_common_utility.bash

#Variable global pero solo se usar localmente en las funciones
_g_tmp=""

#Determinar la clase del SO
get_os_type
declare -r g_os_type=$?

#Deteriminar el tipo de distribución Linux
if [ $g_os_type -le 10 ]; then
    _g_tmp=$(get_linux_type_id)
    declare -r g_os_subtype_id=$?
    declare -r g_os_subtype_name="$_g_tmp"
    _g_tmp=$(get_linux_type_version)
    declare -r g_os_subtype_version="$_g_tmp"
fi

#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
fi


#Expresion regular para extrear la versión de un programa
declare -r g_regexp_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'

#Tamaño de la linea del menu
g_max_length_line=130


#Parametros (argumentos) basicos del script
gp_uninstall=1          #(0) Para instalar/actualizar
                        #(1) Para desintalar

gp_type_calling=0       #(0) Ejecución interactiva del script (muestra el menu).
                        #(1) Ejecución no-interactiva del script para instalar/actualizar un conjunto de respositorios
                        #(2) Ejecución no-interactiva del script para instalar/actualizar un solo repositorio

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

#Personalización: Funciones modificables para el instalador.
. ~/.files/setup/linux/_setup_packages_custom.bash



#}}}



#Funcionalidad interna {{{





#}}}



#Funcionalidad principales interna {{{

#
#Permite instalar un repositorio en Linux (incluyendo a Windows vinculado a un Linux WSL)
#Un repositorio o se configura en Linux o Windows del WSL o ambos.
#'i_install_repository' nunca se muestra con el titulo del repositorio cuando retorna 99 y 2. 
#'i_install_repository' solo se puede mostrar el titulo del repositorio cuando retorno [0, 1] y ninguno de los estados de '_g_install_repo_status' es [0, 2].
#
#Parametros de entrada (argumentos de entrada son):
#  1 > ID del repositorio.
#  2 > La plantilla del titulo (si tiene un '%s', sera remplazado por "se instalará", "se actualizará" o "se configurará")
#      Si se envia una cadena vacia o no se especifica, no se mostrara el titulo.
#      Se usa "se configurará" si no se puede determinar si se instala o configura pero es necesario que se continue.
#  3 > Flag '0' si la unica configuración que puede realizarse es actualizarse (no instalarse) y siempre en cuando el repositorio esta esta instalado.
#
#Parametros de salida (El valor de retorno). Sus valores pueder ser
#   0 > Se inicio la configuración (en por lo menos uno de los 2 SO Linux o Windows).
#       Para ver detalle del estado ver '_g_install_repo_status'.
#   1 > No se inicio la configuración del artefacto (en ninguno de los 2 SO Linux o Windows) debido a que no se cumple la precondiciones requeridas para su configuración en cada SO.
#       Para ver detalle del estado ver '_g_install_repo_status'.
#   2 > No se puede obtener correctamente la ultima versión del repositorio.
#  99 > Argumentos ingresados son invalidos.
#
#Parametros de salida (variables globales):
#    > '_g_install_repo_status' retona indicadores que indican el estado de la configuración (instalación/actualización) realizada.
#           
function i_install_repository() {

    #1. Argumentos 
    local p_repo_id="$1"
    local p_repo_title_template="$2"

    local p_only_update_if_its_installed=1
    if [ "$3" = "0" ]; then
        p_only_update_if_its_installed=0
    fi

    #1. Inicializaciones
    local l_status=0
    local l_repo_name="${gA_repositories[$p_repo_id]}"


    #2. Obtener la ultima version del repositorio
    declare -a la_repo_versions
    #Estado de instalación del respositorio
    _g_install_repo_status=(0 0)

    _get_repo_latest_version "$p_repo_id" "$l_repo_name" la_repo_versions _ga_artifact_subversions
    l_status=$?

    #Si ocurrio un error al obtener la versión
    if [ $l_status -ne 0 ]; then

        if [ $l_status -ne 1 ]; then
            echo "ERROR: Primero debe tener a 'jq' en el PATH del usuario para obtener la ultima version del repositorio \"$p_repo_id\""
        else
            echo "ERROR: Ocurrio un error al obtener la ultima version del repositorio \"$p_repo_id\""
        fi
        return 2
    fi

    #si el arreglo de menos de 2 elementos
    local l_n=${#la_repo_versions[@]}
    if [ $l_n -lt 2 ]; then
        echo "ERROR: La configuración actual, no obtuvo las 2 formatos de la ultima versiones del repositorio \"${p_repo_id}\""
        return 2
    fi

    #Version usada para descargar la version (por ejemplo 'v3.4.6', 'latest', ...)
    local l_repo_last_version="${la_repo_versions[0]}"

    #Si la ultima version no tiene un formato correcto (no inicia con un numero, por ejemplo '3.4.6', '0.8.3', ...)
    local l_repo_last_version_pretty="${la_repo_versions[1]}"
    if [[ ! "$l_repo_last_version_pretty" =~ ^[0-9] ]]; then
        l_repo_last_version_pretty=""
    fi
       
    if [ -z "$l_repo_last_version" ]; then
        echo "ERROR: La ultima versión del repositorio \"$p_repo_id\" no puede ser vacia"
        return 2
    fi
   

    local l_artifact_subversions_nbr=${#_ga_artifact_subversions[@]} 
    
    #4. Iniciar la configuración en Linux: 

    #Caducar las credencinales de root almacenadas temporalmente si: se hiceron internamente y fue no-interactiva de un solo ID del repositorio
    if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ] && [ $gp_type_calling -eq 2 ]; then
        clean_sudo_credencial
    fi

    return 0

}

#
#Parametros de entrada (Argumentos):
#  1 > Opciones relacionados con los repositorios que se se instalaran (entero que es suma de opciones de tipo 2^n).
#
#Parametros de entrada (Globales):
#    > 'gp_type_calling' es el flag '0' si es invocado directamente, caso contrario es invocado desde otro script.
#
function i_install_repositories() {
    
    #1. Argumentos 
    local p_input_options=-1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_input_options=$1
    fi

    if [ $p_input_options -le 0 ]; then
        echo "ERROR: Argumento de opciones \"${p_input_options}\" es incorrecta"
        return 99
    fi

    #2. Validar si fue descarga el repositorio git correspondiente
    if [ ! -d ~/.files/.git ]; then
        show_message_nogitrepo
        return 10
    fi
    
    #   Si la configuración de un repositorio de la opción de menú falla, se deteniene la configuración de la opción.
    #3. Inicializaciones cuando se invoca directamente el script
    local l_flag=0
    if [ $gp_type_calling -eq 0 ]; then


        #Instalacion de paquetes del SO
        l_flag=$(( $p_input_options & $g_opt_update_installed_pckg ))
        if [ $g_opt_update_installed_pckg -eq $l_flag ]; then

            #Solicitar credenciales para sudo y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq -1 ]; then
                storage_sudo_credencial
                g_status_crendential_storage=$?
                #Se requiere almacenar las credenciales para realizar cambiso con sudo.
                if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                    return 120
                fi
            fi

            print_line '-' $g_max_length_line "$g_color_opaque" 
            echo "- Actualizar los paquetes de los repositorio del SO Linux"
            print_line '-' $g_max_length_line "$g_color_opaque" 
            
            #Segun el tipo de distribución de Linux
            case "$g_os_subtype_id" in
                1)
                    #Distribución: Ubuntu
                    if [ $g_is_root -eq 0 ]; then
                        apt-get update
                        apt-get upgrade
                    else
                        sudo apt-get update
                        sudo apt-get upgrade
                    fi
                    ;;
                2)
                    #Distribución: Fedora
                    if [ $g_is_root -eq 0 ]; then
                        dnf upgrade
                    else
                        sudo dnf upgrade
                    fi
                    ;;
                0)
                    echo "ERROR: No se identificado el tipo de Distribución Linux"
                    return 22;
                    ;;
            esac

        fi
    fi

    #5. Configurar (instalar/actualizar) los paquetes selecionados por las opciones de menú dinamico.

    #local l_i=0
    #local l_status
    ##Limpiar el arreglo asociativo
    #_gA_processed_repo=()

    #for((l_i=0; l_i < ${#ga_menu_options_repos[@]}; l_i++)); do
    #    
    #    _install_menu_options $p_input_options $l_i
    #    l_status=$?

    #    #Se requiere almacenar las credenciales para realizar cambios con sudo.
    #    if [ $l_status -eq 120 ]; then
    #        return 120
    #    fi

    #done


    #6. Caducar las credencinales de root almacenadas temporalmente si se hiceron internamente
    if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi

}


#La instalación/desintalación de Skopeo (eliminar del profile)
#La instalación/desintalación de Python
#La instalación/desintalación de NVM y Node.JS
#La instalacion/desintalación VIM-enhanced


function i_main_install() {

    #1. Pre-requisitos
    printf '%bOS Type            : (%s)\n' "$g_color_opaque" "$g_os_type"
    printf 'OS Subtype (Distro): (%s) %s - %s%b\n' "${g_os_subtype_id}" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
    
    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        printf '\nERROR: El sistema operativo debe ser Linux\n'
        return 21;
    fi

    #¿Esta 'curl' instalado?
    local l_status
    fulfill_preconditions1
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 22
    fi

   
    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_title" 
    print_text_in_center "Menu de Opciones (Install/Update)" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_title" "$g_color_reset"
    printf " (%ba%b) Actualizar los paquetes existentes del SO y los binarios de los repositorios existentes\n" "$g_color_title" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    _get_length_menu_option $g_offset_option_index_menu_install
    local l_max_digits=$?

    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes existentes del sistema operativo\n" "$g_color_title" "$g_opt_update_installed_pckg" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar solo los repositorios de programas ya instalados\n" "$g_color_title" "$g_opt_update_installed_repo" "$g_color_reset"

    _show_dynamic_menu 'Instalar o actualizar' $g_offset_option_index_menu_install $l_max_digits
    print_line '-' $g_max_length_line "$g_color_opaque"

    #3. Mostrar la ultima parte del menu y capturar la opcion elegida
    local l_flag_continue=0
    local l_options=""
    local l_value_option_a=$(($g_opt_update_installed_pckg + $g_opt_update_installed_repo))
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_opaque" "$g_color_reset"
        read -r l_options

        case "$l_options" in
            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                i_setup_repositories $l_value_option_a 0
                ;;

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                ;;


            0)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_title" 
                    printf '\n'
                    i_install_repositories $l_options 0
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_opaque" 
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;
        esac
        
    done

}


function i_main_uninstall() {

    printf '%bOS Type            : (%s)\n' "$g_color_opaque" "$g_os_type"
    printf 'OS Subtype (Distro): (%s) %s - %s%b\n\n' "${g_os_subtype_id}" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
    
    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        echo "ERROR: El sistema operativo debe ser Linux"
        return 21;
    fi
   
    print_line '─' $g_max_length_line "$g_color_title" 

    print_text_in_center "Menu de Opciones (Uninstall)" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_title" "$g_color_reset"
    printf " ( ) Para desintalar ingrese un opción o la suma de las opciones que desea configurar:\n"

    _get_length_menu_option $g_offset_option_index_menu_uninstall
    local l_max_digits=$?

    _show_dynamic_menu 'Desinstalar' $g_offset_option_index_menu_uninstall $l_max_digits
    print_line '-' $g_max_length_line "$g_color_opaque"


    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_opaque" "$g_color_reset"
        read -r l_options

        case "$l_options" in

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                ;;


            0)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;


            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_title" 
                    printf '\n'
                    i_uninstall_repositories $l_options 0
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_opaque" 
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;
        esac
        
    done

}


_usage() {

    printf '%bUsage:\n\n' "$g_color_opaque"
    printf '  > Desintalar repositorios de manera interactiva (muestra el menú):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash uninstall\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar repositorios de manera interactiva (muestra el menú):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar/Actualizar uno o mas repositorios en forma no interactiva (sin menú):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 1 MENU-OPTIONS\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Instalar/Actualizar un repositorio en forma no interactiva (sin menú):\n'
    printf '    %b~/.files/setup/linux/01_setup_commands.bash 1 REPO-ID%b\n\n' "$g_color_info" "$g_color_reset"

}


#}}}

#1. Argumentos fijos del script


#Argumento 1: ¿instalar/actualizar o desintalar?
if [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
elif [ "$1" = "uninstall" ]; then
    gp_uninstall=0
elif [ ! -z "$1" ]; then
    printf 'Argumentos invalidos.\n\n'
    _usage
    exit 80
fi


#2. Logica principal del script (incluyendo los argumentos variables)

#Aun no se ha solicitado almacenar temporalmente las credenciales para el sudo
g_status_crendential_storage=-1
#La credencial no se almaceno por un script externo.
g_is_credential_storage_externally=1

#2.1. Desintalar los artefactos de un repoistorio
if [ $gp_uninstall -eq 0 ]; then

    i_main_uninstall

#2.2. Instalar y actualizar los artefactos de un repositorio
else

    #2.2.1. Por defecto, mostrar el menu para escoger lo que se va instalar
    if [ $gp_type_calling -eq 0 ]; then
    
        i_main_install
    
    #2.2.2. Instalando los repositorios especificados por las opciones indicas en '$2'
    elif [ $gp_type_calling -eq 1 ]; then
    
        #Parametros del script usados hasta el momento:
        # 1> Tipo de configuración: 1 (instalación/actualización).
        # 2> Opciones de menu a ejecutar: entero positivo.
        # 3> El estado de la credencial almacenada para el sudo.
        gp_opciones=0
        if [[ "$2" =~ ^[0-9]+$ ]]; then
            gp_opciones=$2
        else
            exit 88
        fi

        if [[ "$3" =~ ^[0-2]$ ]]; then
            g_status_crendential_storage=$3

            if [ $g_status_crendential_storage -eq 0 ]; then
                g_is_credential_storage_externally=0
            fi

        fi

        i_install_repositories $gp_opciones 1
    
    #2.2.3. Instalando un solo repostorio del ID indicao por '$2'
    else
    
        #Parametros del script usados hasta el momento:
        # 1> Tipo de configuración: 1 (instalación/actualización).
        # 2> ID del repositorio a instalar: identificado interno del respositorio
        # 3> El estado de la credencial almacenada para el sudo.
        gp_repo_id="$2"
        if [ -z "$gp_repo_id" ]; then
           echo "Parametro 2 \"$2\" debe ser un ID de repositorio valido"
           exit 89
        fi

        if [[ "$3" =~ ^[0-2]$ ]]; then
            g_status_crendential_storage=$3

            if [ $g_status_crendential_storage -eq 0 ]; then
                g_is_credential_storage_externally=0
            fi
        fi
    
        i_install_repository "$gp_repo_id" "" 1
    
    fi
    
fi



