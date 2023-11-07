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
    declare -r g_os_subtype_version_pretty=$(echo "$g_os_subtype_version" | sed -e "$g_regexp_sust_version1")
fi

#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
fi


#Tamaño de la linea del menu
g_max_length_line=130

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

    #2. ¿Esta habilitado esta opción?
    local l_opcion=2
    local l_flag=$(( $p_opciones & $l_opcion ))
    if [ $l_flag -ne $l_opcion ]; then
        return 1
    fi


    #3. Si esta instalado VIM/NeoVIM, obtener la versión
    local l_status
    local l_vim_version=""
    l_vim_version=$(vim --version 2> /dev/null)
    l_status=$?
    if [ $l_status -eq 0 ]; then
        l_vim_version=$(echo "$l_vim_version" | head -n 1)
        l_vim_version=$(echo "$l_vim_version" | sed "$g_regexp_sust_version1")
    else
        l_vim_version=""
    fi

    local l_nvim_version=""
    l_nvim_version=$(nvim --version 2> /dev/null)
    l_status=$?
    if [ $l_status -eq 0 ]; then
        l_nvim_version=$(echo "$l_nvim_version" | head -n 1)
        l_nvim_version=$(echo "$l_nvim_version" | sed "$g_regexp_sust_version1")
    else
        l_nvim_version=""
    fi

    #Si no esta instalado VIM ni NeoVIM
    if [ -z "$l_vim_version" ] && [ -z "$l_nvim_version" ]; then
        return 2
    fi



    #4. Actualizar paquetes VIM/NeoVIM instalados
    local l_title
    local l_aux=""

    if [ ! -z "$l_vim_version" ]; then
        printf -v l_aux "%sVIM%s %s(%s)%s" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_vim_version" "$g_color_reset"
    fi

    if [ ! -z "$l_nvim_version" ]; then
        if [ ! -z "$l_aux" ]; then
            l_aux="${l_aux} y "
        fi
        printf -v l_aux "%s%sNeoVIM%s %s(%s)%s" "$l_aux" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_vim_version" "$g_color_reset"
    fi

    printf -v l_title "Actualizar los paquetes de  %s" "$l_aux"


    print_line '─' $g_max_length_line  "$g_color_opaque"
    print_text_in_center2 "$l_title" $g_max_length_line 
    print_line '─' $g_max_length_line "$g_color_opaque"


    local l_is_developer=1

    #5. Actualizaciones de VIM
    if [ ! -z "$l_vim_version" ]; then

        printf 'Se actualizará los paquetes/plugin del VIM "%s" ...\n' "${l_vim_version}"

        #5.1. Actualizar los package nativos de VIM 
        _update_vim_package

        #Otras actualizaciones para VIM (modo de inicio 'ex' y silencioso)
        #printf '\nActualizando los plugins "Vim-Plug" de VIM, ejecutando el comando ":PlugUpdate"\n'
        #vim -esc 'PlugUpdate' -c 'qa'


        #5.2. Verificar si esta instalado en modo developer/IDE
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

        #5.3. Actualizar en modo deleloper
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

    #6. Actualizaciones de NeoVIM
    if [ ! -z "$l_nvim_version" ]; then

        printf '\nSe actualizará los paquetes/plugin del NeoVIM "%s" ...\n\n' "${l_nvim_version}"

        #Otras actualizaciones de NVIM (modo de inicio 'ex' y silencioso)
        #echo 'Actualizando los plugins "Vim-Plug" de NeoVIM, ejecutando el comando ":PlugUpdate"'
        #nvim --headless -c 'PlugUpdate' -c 'qa'
        echo 'Actualizando los plugins "Packer" de NeoVIM, ejecutando el comando ":PackerUpdate"'
        nvim --headless -c 'PackerUpdate' -c 'qa'

        #Verificar si esta instalado en modo developer/IDE
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

        #Actualizar en modo developer
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

    printf '\n'
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
    
    #3. Actualizar los paquetes instalados desde los repositorios SO
    g_status_crendential_storage=-1
    local l_title
    local l_opcion=1
    local l_status
    local l_flag=$(( $p_opciones & $l_opcion ))
    if [ $l_flag -eq $l_opcion ]; then

    
        #Solicitar credenciales de administrador y almacenarlas temporalmente
        if [ $g_status_crendential_storage -eq -1 ]; then
            storage_sudo_credencial
            g_status_crendential_storage=$?
            #Se requiere almacenar las credenciales para realizar cambiso con sudo.
            if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                return 120
            fi
        fi

        print_line '─' $g_max_length_line  "$g_color_opaque"
        printf -v l_title "Actualizar los paquetes del SO '%s%s %s%s'" "$g_color_subtitle" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
        print_text_in_center2 "$l_title" $g_max_length_line 
        print_line '─' $g_max_length_line "$g_color_opaque"

        upgrade_os_packages $g_os_subtype_id     
        echo ""

    fi

    #4. Actualizar paquetes VIM/NeoVIM instalados
    _update_vim_nvim_packages $p_opciones

    #5. Actualizar los binarios instados de repositorios como Git
    l_opcion=4
    l_flag=$(( $p_opciones & $l_opcion ))
    if [ $l_flag -eq $l_opcion ]; then
    
        #Parametros:
        # 1> Tipo de ejecución: 1 (ejecución no-interactiva para actualizar un conjuentos de respositorios)
        # 2> Opciones de menu seleccionados para instalar/actualizar: 2 (instalar/actualizar solo los comandos instalados)
        # 3> El estado de la credencial almacenada para el sudo
        ~/.files/setup/linux/01_setup_commands.bash 1 2 $g_status_crendential_storage
        l_status=$?

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
           g_status_crendential_storage=0
        fi

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

    local l_max_digits=$?

    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes del SO existentes\n" "$g_color_title" "1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar los plugin de VIM/NeoVim existentes y configurarlos\n" "$g_color_title" "2" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar los binarios instalados de un repositorio de comandos como GitHub\n" "$g_color_title" "4" "$g_color_reset"

    print_line '-' $g_max_length_line "$g_color_opaque" 

}

function g_main() {

  
    #Mostar el menu principal 
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
                    print_line '─' $g_max_length_line "$g_color_title" 
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

#1. Logica principal del script (incluyendo los argumentos variables)
_g_status=0

#Validar los requisitos (0 debido a que siempre se ejecuta de modo interactivo)
fulfill_preconditions1 $g_os_subtype_id 0
_g_status=$?

#Iniciar el procesamiento
if [ $_g_status -eq 0 ]; then
    g_main
fi





