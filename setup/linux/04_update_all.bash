#!/bin/bash


#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/terminal/linux/functions/func_utility.bash

#Funciones de utlidad
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


#Variables y funciones para mostrar las opciones dinamicas del menu.
#. ~/.files/setup/linux/_dynamic_commands_menu.bash


#Expresion regular para extrear la versión de un programa
declare -r g_regexp_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'

#Tamaño de la linea del menu
g_max_length_line=130


#Menu dinamico: Offset del indice donde inicia el menu dinamico.
#               Generalmente el menu dinamico no inicia desde la primera opcion personalizado del menú.
#g_offset_option_index_menu_install=2

#Estado del almacenado temporalmente de las credenciales para sudo
# -1 - No se solicito el almacenamiento de las credenciales
#  0 - No es root: se almaceno las credenciales
#  1 - No es root: no se pudo almacenar las credenciales.
#  2 - Es root: no requiere realizar sudo.
g_status_crendential_storage=-1


#}}}



function _after_update_repository() {

    #1. Argumentos
    local p_repo_path="$1"
    local p_repo_type="$2"
    local p_repo_name="$3"

    #Los plugins VIM que no tiene documentación, no requieren indexar
    if [ "$p_repo_name" = "molokai" ]; then return 0; fi

    #Indexar la documentación de plugins
    echo "Indexar la documentación del plugin \"${p_repo_path}/doc\""
    vim -u NONE -Esc "helptags ${p_repo_path}/doc" -c qa
    
    #case "$p_repo_name" in

    #    vim-visual-multi)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    vim-surround)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;

    #esac
    
    return 0


}

function _update_repository() {

    #1. Argumentos
    local p_repo_path="$1"
    local p_repo_type="$2"
    local p_repo_name="$3"

    #Validar si existe directorio
    if [ ! -d $p_repo_path ]; then
        echo "Folder \"${p_repo_path}\" not exists"
        return 9
    else
        printf '\n'
        print_line '-' $g_max_length_line "$g_color_opaque" 
        printf '> Repository Git para VIM "%b%s%b"\n' "$g_color_subtitle" "${p_repo_path}" "$g_color_reset"
        print_line '-' $g_max_length_line "$g_color_opaque" 
    fi

    cd $p_repo_path

    #Obtener el directorio .git pero no imprimir su valor ni los errores. Si no es un repositorio valido salir     
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo 'Invalid git repository'
        return 9
    fi
    
    #
    local l_local_branch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
    local l_remote=$(git config branch.${l_local_branch}.remote)
    local l_remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})

    echo "Fetching from remote repository \"${l_remote}\"..."
    git fetch $l_remote

    echo "Updating local branch \"${l_local_branch}\"..."
    if git merge-base --is-ancestor ${l_remote_branch} HEAD; then
        echo 'Already up-to-date'
        return 1
    else
        if git merge-base --is-ancestor HEAD ${l_remote_branch}; then
            echo 'Fast-forward possible. Merging...'
            git merge --ff-only --stat ${l_remote_branch}

            #Realizando algunas operaciones adicionales
            _after_update_repository "$p_repo_path" "$p_repo_type" "$p_repo_name"
            return 0
        else
            echo 'Fast-forward not possible. Rebasing...'
            git rebase --preserve-merges --stat ${l_remote_branch}
            return 2
        fi
    fi
}

function _update_vim_package() {

    #
    local l_base_path=~/.vim/pack
    
    #Validar si existe directorio
    if [ ! -d $l_base_path ]; then
        echo "Folder \"${l_base_path}\" not exists"
        return 9
    fi

    cd $l_base_path
    local l_folder
    local l_repo_type
    local l_repo_name
    for l_folder  in $(find . -mindepth 4 -maxdepth 4 -type d -name .git); do
        l_folder="${l_folder%/.git}"
        l_folder="${l_folder#./}"
        l_repo_name="${l_folder##*/}"
        l_repo_type="${l_folder%%/*}"
        l_folder="${l_base_path}/${l_folder}"
        _update_repository "$l_folder" "$l_repo_name" "$l_repo_type"
    done
    return 0

}

function _update_vim_nvim_packages() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #Actualizar paquetes VIM/NeoVIM instalados
    local l_version=""
    local l_status=0
    local l_vim_flag=1
    local l_nvim_flag=1
    local l_aux=""
    local l_is_developer=1

    local l_opcion=2
    local l_flag=$(( $p_opciones & $l_opcion ))
    if [ $l_flag -eq $l_opcion ]; then

        #5.1. Si esta instalado VIM, obtener la versión
        l_version=$(vim --version 2> /dev/null)
        l_status=$?
        if [ $l_status -eq 0 ]; then
            l_version=$(echo "$l_version" | head -n 1)
            l_version=$(echo "$l_version" | sed "$g_regexp_version1")
            l_vim_flag=0
        else
            l_version=""
        fi

        #5.2. Actualizaciones de VIM
        if [ $l_vim_flag -eq 0 ]; then

            printf 'Se actualizará los paquetes/plugin del VIM "%s" ...\n' "${l_version}"

            #5.2.1. Atualizaciones generales

            #Actualizar los package nativos de VIM 
            _update_vim_package

            #Otras actualizaciones para VIM (modo de inicio 'ex' y silencioso)
            #printf '\nActualizando los plugins "Vim-Plug" de VIM, ejecutando el comando ":PlugUpdate"\n'
            #vim -esc 'PlugUpdate' -c 'qa'


            #5.2.2. Verificar si esta instalado en modo developer/IDE
            l_is_developer=1
            l_aux=$(readlink ~/.vimrc 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_aux="${l_aux##*/}"
                if [ "$l_aux" = "vimrc_linux_ide.vim" ]; then
                    l_is_developer=0
                    printf '\nSe ha detectado que %s esta instalado en modo developer (usa el arhivo de inicialización "%s")\n' "VIM" "$l_aux"
                fi
            fi

            #5.2.3. Actualizar en modo deleloper
            if [ $l_is_developer -eq 0 ]; then

                #Actualizar las extensiones de CoC
                printf 'Actualizando las extensiones existentes de CoC, ejecutando el comando ":CocUpdate"\n'
                vim -esc 'CocUpdate' -c 'qa'

                #Actualizando los gadgets de 'VimSpector'
                printf 'Actualizando los gadgets de "VimSpector", ejecutando el comando ":VimspectorUpdate"\n'
                vim -esc 'VimspectorUpdate' -c 'qa'

                printf '\nRecomendaciones:\n'
                printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 vim%b"\n' "$g_color_subtitle" "$g_color_reset"
                printf '    > Se recomienda que configure su IDE CoC segun su necesidad:\n'
                echo "        1> Instalar extensiones de COC segun su necesidad (Listar existentes \":CocList extensions\")"
                echo "        2> Revisar la Configuracion de COC \":CocConfig\":"
                echo "          2.1> El diganostico se enviara ALE (no se usara el integrado de CoC), revisar:"
                echo "               { \"diagnostic.displayByAle\": true }"
                echo "          2.2> El formateador de codigo 'Prettier' sera proveido por ALE (no se usara la extension 'coc-prettier')"
                echo "               Si esta instalado esta extension, desintalarlo."

            fi
            

        fi

        #5.3. Si esta instalado NeoVIM, obtener la versión
        l_version=$(nvim --version 2> /dev/null)
        l_status=$?
        if [ $l_status -eq 0 ]; then
            l_version=$(echo "$l_version" | head -n 1)
            l_version=$(echo "$l_version" | sed "$g_regexp_version1")
            l_nvim_flag=0
        else
            l_version=""
        fi

        #5.4. Actualizaciones de NeoVIM
        if [ $l_vim_flag -eq 0 ]; then

            printf '\nSe actualizará los paquetes/plugin del NeoVIM "%s" ...\n\n' "${l_version}"

            #Otras actualizaciones de NVIM (modo de inicio 'ex' y silencioso)
            #echo 'Actualizando los plugins "Vim-Plug" de NeoVIM, ejecutando el comando ":PlugUpdate"'
            #nvim --headless -c 'PlugUpdate' -c 'qa'
            echo 'Actualizando los plugins "Packer" de NeoVIM, ejecutando el comando ":PackerUpdate"'
            nvim --headless -c 'PackerUpdate' -c 'qa'

            #5.4.1. Verificar si esta instalado en modo developer/IDE
            l_is_developer=1
            l_aux=$(readlink ~/.config/nvim/init.vim 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_aux="${l_aux##*/}"
                if [ "$l_aux" = "init_linux_ide.vim" ]; then
                    l_is_developer=0
                    printf 'Se ha detectado que %s esta instalado en modo developer (usa el arhivo de inicialización "%s")\n' "NeoVIM" "$l_aux"
                fi
            fi

            #5.4.2. Actualizar en modo developer
            if [ $l_is_developer -eq 0 ]; then

                #Actualizar las extensiones de CoC
                printf 'Actualizando los extensiones existentes de CoC, ejecutando el comando ":CocUpdate"\n'
                USE_COC=1 nvim --headless -c 'CocUpdate' -c 'qa'

                #Actualizando los gadgets de 'VimSpector'
                #printf 'Actualizando los gadgets de "VimSpector", ejecutando el comando ":VimspectorUpdate"\n'
                #USE_COC=1 nvim --headless -c 'VimspectorUpdate' -c 'qa'

                printf '\nRecomendaciones:\n'
                printf '  > Por defecto, se ejecuta el IDE vinculado al LSP nativo de NeoVIM.\n'
                printf '    > Si desea usar CoC, use: "%bUSE_COC=1 nvim%b"\n' "$g_color_subtitle" "$g_color_reset"
                printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 nvim%b"\n' "$g_color_subtitle" "$g_color_reset"

                printf '  > Si usar como Developer con IDE CoC, se recomienda que lo configura segun su necesidad:\n'
                echo "        1> Instalar extensiones de COC segun su necesidad (Listar existentes \":CocList extensions\")"
                echo "        2> Revisar la Configuracion de COC \":CocConfig\":"
                echo "          2.1> El diganostico se enviara ALE (no se usara el integrado de CoC), revisar:"
                echo "               { \"diagnostic.displayByAle\": true }"
                echo "          2.2> El formateador de codigo 'Prettier' sera proveido por ALE (no se usara la extension 'coc-prettier')"
                echo "               Si esta instalado esta extension, desintalarlo."

            fi
        fi

    fi

    #Si es desarrallador: Actualizar los modulos Python
    

    #Si es desarrollador: Actualizar los paquetes globales Node.JS istalados

}

#
# Argumentos:
# 1) Repositorios que se se instalaran basicos y opcionales (flag en binario. entero que es suma de 2^n).
# 2) -
#
function _update_all() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #2. Validar si fue descarga el repositorio git correspondiente
    if [ ! -d ~/.files/.git ]; then
        show_message_nogitrepo
        return 10
    fi
    
    #3. Actualizar los paquetes instalados desde los repositorios SO
    g_status_crendential_storage=-1
    local l_opcion=1
    local l_flag=$(( $p_opciones & $l_opcion ))
    if [ $l_flag -eq $l_opcion ]; then

    
        #Solicitar credenciales de administrador y almacenarlas temporalmente
        if [ $g_status_crendential_storage -eq -1 ]; then
            storage_sudo_credencial
            g_status_crendential_storage=$?
            #Se requiere almacenar las credenciales para realizar cambiso con sudo.
            if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                return 99
            fi
        fi

        print_line '-' $g_max_length_line "$g_color_opaque" 
        printf '> Actualizar los paquetes de los repositorios del SO Linux\n'
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
                echo "ERROR (22): No se identificado el tipo de Distribución Linux"
                return 22;
                ;;
        esac
        echo ""

    fi

    #4. Actualizar paquetes VIM/NeoVIM instalados
    _update_vim_nvim_packages $p_opciones

    #5. Actualizar los binarios instados de repositorios como Git
    l_opcion=4
    l_flag=$(( $p_opciones & $l_opcion ))
    if [ $l_flag -eq $l_opcion ]; then
    
        #Solicitar credenciales de administrador y almacenarlas temporalmente
        if [ $g_status_crendential_storage -eq -1 ]; then
            storage_sudo_credencial
            g_status_crendential_storage=$?
            #Se requiere almacenar las credenciales para realizar cambiso con sudo.
            if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                return 99
            fi
        fi

        #2 es la opcion de actulizar solo los comandos instalados
        ~/.files/setup/linux/01_setup_commands.bash 1 2
    fi            

    #6. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_status_crendential_storage -eq 0 ]; then
        clean_sudo_credencial
    fi

}


function _show_menu_core() {


    print_text_in_center "Menu de Opciones" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_title" "$g_color_reset"
    printf " (%ba%b) Actualizar los artefactos existentes: paquetes del SO y VIM/NeoVIM (update & config plugins) \n" "$g_color_title" "$g_color_reset"
    printf " (%bb%b) Actualizar los artefactos existentes: paquetes del SO, binarios de GIT y VIM/NeoVIM (update & config plugins)\n" "$g_color_title" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    #_get_length_menu_option $g_offset_option_index_menu_install
    local l_max_digits=$?

    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes del SO existentes\n" "$g_color_title" "1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar los plugin de VIM/NeoVim existentes y configurarlos\n" "$g_color_title" "2" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar los binarios instalados de un repositorio de comandos como GitHub\n" "$g_color_title" "4" "$g_color_reset"

    #_show_dynamic_menu 'Instalar o actualizar' $g_offset_option_index_menu_install $l_max_digits
    print_line '-' $g_max_length_line "$g_color_opaque" 

}

function i_main() {


    printf '%bOS Type            : (%s)\n' "$g_color_opaque" "$g_os_type"
    printf 'OS Subtype (Distro): (%s) %s - %s%b\n\n' "${g_os_subtype_id}" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
    
    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        echo "ERROR(21): El sistema operativo debe ser Linux"
        return 21;
    fi
   
    #¿Esta 'curl' instalado?
    local l_status
    fulfill_preconditions1
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 22
    fi
   
    print_line '─' $g_max_length_line "$g_color_title" 

    _show_menu_core

    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_opaque" "$g_color_reset"
        read -r l_options

        case "$l_options" in
            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                _update_all 3
                ;;

            b)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                _update_all 7
                ;;

            #0)
            #    l_flag_continue=1
            #    print_line '─' $g_max_length_line "$g_color_title" 
            #    printf '\n'
            #    _update_all 0
            #    ;;

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '#' $g_max_length_line "$g_color_title" 
                    printf '\n'
                    _update_all $l_options
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

i_main



