#!/bin/bash


#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/terminal/linux/functions/func_utility.bash

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
. ~/.files/setup/linux/_dynamic_commands_menu.bash



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
    vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    
    #case "$p_repo_name" in

    #    vim-visual-multi)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    vim-surround)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;


    #    vimspector)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    omnisharp-vim)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    ultisnips)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    ale)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    coc.nvim)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    vim-snippets)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;


    #    fzf)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    fzf.vim)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    vim-devicons)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    vim-tmux-navigator)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    vim-airline)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    vim-airline-themes)
    #        vim -u NONE -c "helptags ${p_repo_path}/doc" -c q
    #        ;;
    #    nerdtree)
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
        echo "No existe los archivos necesarios, debera seguir los siguientes pasos:"
        echo "   1> Descargar los archivos del repositorio:"
        echo "      git clone https://github.com/lestebanpc/dotfiles.git ~/.files"
        echo "   2> Instalar comandos basicos:"
        echo "      chmod u+x ~/.files/setup/linux/01_setup_commands.bash"
        echo "      ~/.files/setup/linux/01_setup_commands.bash"
        echo "   3> Configurar el profile del usuario:"
        echo "      chmod u+x ~/.files/setup/linux/02_setup_profile.bash"
        echo "      ~/.files/setup/linux/02_setup_profile.bash"
        return 0
    fi
    

    #3. Solicitar credenciales de administrador y almacenarlas temporalmente
    if [ $g_is_root -ne 0 ]; then

        #echo "Se requiere alamcenar temporalmente su password"
        sudo -v

        if [ $? -ne 0 ]; then
            echo "ERROR(20): Se requiere \"sudo -v\" almacene temporalmente su credenciales de root"
            return 20;
        fi
        printf '\n\n'
    fi
    
    #4. Actualizar los paquetes instalados desde los repositorios SO
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

    #5. Actualizar paquetes VIM instalados
    l_opcion=1
    l_flag=$(( $p_opciones & $l_opcion ))
    if [ $l_flag -eq $l_opcion ]; then
        _update_vim_package
    fi

    #6. Si es desarrallador: Actualizar los modulos Python
    

    #7. Si es desarrollador: Actualizar los paquetes globales Node.JS istalados

    #8. Actualizar los binarios de otros repositorios que no sean del SO (solo si la opcion ingresada es >= 2)
    #l_opcion=1
    #l_flag=$(( $p_opciones & $l_opcion ))
    if [ $p_opciones -ge 2 ]; then
        ~/.files/setup/linux/01_setup_commands.bash 1 $p_opciones
    fi            

    #9. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 ]; then
        echo $'\n'"Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}


function _show_menu_core() {


    print_text_in_center "Menu de Opciones" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_subtitle" "$g_color_reset"
    printf " (%ba%b) Actualizar los artefactos existentes: paquetes del SO y paquetes VIM\n" "$g_color_subtitle" "$g_color_reset"
    printf " (%bb%b) Actualizar los artefactos existentes: paquetes del SO, binarios de GIT y paquetes VIM\n" "$g_color_subtitle" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    _get_length_menu_option
    local l_max_digits=$?

    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes del SO existentes %b(siempre que escoga una opcion este se ejecutará)%b\n" "$g_color_subtitle" "0" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes VIM existentes\n" "$g_color_subtitle" "1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar solo los repositorios de programas instalados\n" "$g_color_subtitle" "2" "$g_color_reset"

    _show_dynamic_menu $l_max_digits
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
   
    print_line '#' $g_max_length_line "$g_color_title" 

    _show_menu_core

    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_opaque" "$g_color_reset"
        read -r l_options

        case "$l_options" in
            a)
                l_flag_continue=1
                print_line '#' $g_max_length_line "$g_color_title" 
                printf '\n'
                _update_all 1
                ;;

            b)
                l_flag_continue=1
                print_line '#' $g_max_length_line "$g_color_title" 
                printf '\n'
                _update_all 3
                ;;

            0)
                l_flag_continue=1
                print_line '#' $g_max_length_line "$g_color_title" 
                printf '\n'
                _update_all 0
                ;;

            q)
                l_flag_continue=1
                print_line '#' $g_max_length_line "$g_color_title" 
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



