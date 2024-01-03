#!/bin/bash


#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/terminal/linux/functions/func_utility.bash

#Obtener informacion basica del SO
if [ -z "$g_os_type" ]; then

    #Determinar el tipo del SO con soporte a interprete shell POSIX
    get_os_type
    declare -r g_os_type=$?

    #Obtener informacion de la distribución Linux
    if [ $g_os_type -le 1 ]; then
        get_linux_type_info
    fi

fi

#Obtener informacion basica del usuario
if [ -z "$g_user_is_root" ]; then

    #Determinar si es root y el soporte de sudo
    get_user_options

fi


#Funciones de utilidad
. ~/.files/setup/linux/_common_utility.bash


#Tamaño de la linea del menu
g_max_length_line=130

#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución mostrando el menu del opciones (siempre es interactiva).
                        #(1) Ejecución sin el menu de opciones, interactivo    - configurar un conjunto de opciones del menú
                        #(2) Ejecución sin el menu de opciones, no-interactivo - configurar un conjunto de opciones del menú

#Estado del almacenado temporalmente de las credenciales para sudo
# -1 - No se solicito el almacenamiento de las credenciales
#  0 - No es root: se almaceno las credenciales
#  1 - No es root: no se pudo almacenar las credenciales.
#  2 - Es root: no requiere realizar sudo.
g_status_crendential_storage=-1


#}}}

#Parametros de salida (SDTOUT): Version de compilador c/c++ instalado
#Parametros de salida (valores de retorno):
# 0 > Se obtuvo la version
# 1 > No se obtuvo la version
function _get_gcc_version() {

    #Obtener la version instalada
    l_version=$(gcc --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        return 1
    fi

    l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    echo "$l_version"
    return 0
}

#Parametros de salida (SDTOUT): Version de NodeJS instalado
#Parametros de salida (valores de retorno):
# 0 > Se obtuvo la version
# 1 > No se obtuvo la version
function _get_nodejs_version() {

    #Obtener la version instalada
    l_version=$(node -v 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        return 1
    fi

    l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    echo "$l_version"
    return 0
}




#
#Parametros de salida (valores de retorno):
#  0 > Si es esta configurado en modo editor
#  1 > Si es esta configurado en modo developer
#  2 > Si NO esta configurado
function _is_developer_vim_profile() {

    #1. Argumentos
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
    fi


    #2. Ruta base donde se instala el plugins/paquete
    local l_real_path
    local l_profile_path="${HOME}/.vimrc"
    if [ $p_is_neovim -eq 0  ]; then
        l_profile_path="${HOME}/.config/nvim/init.vim"
    fi

    #'vimrc_ide_linux_xxxx.vim'
    #'vimrc_basic_linux.vim'
    #'init_ide_linux_xxxx.vim'
    #'init_basic_linux.vim'
    l_real_path=$(readlink "$l_profile_path" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        return 2
    fi

    l_real_path="${l_real_path##*/}"

    #Si es NeoVIM
    if [ $p_is_neovim -eq 0  ]; then
        if [[ "$l_real_path" == init_ide_* ]]; then
            return 1 
        fi
        return 0
    fi

    #Si es VIM
    if [[ "$l_real_path" =~ vimrc_ide_* ]]; then
        return 1 
    fi
    return 0

}

#Actualizar el repositorios
#Parametros de salida (valores de retorno):
#   0 > El repositorio ya esta actualizado
#   1 > El repositorio se actualizo con existo (merge)
#   2 > El repositorio se actualizo con existo (rebase)
#   3 > Error en la actualización: No se puede realizar el 'fetching' (actualizar la rama remota del repositorio local)
#   4 > Error en la actualización: No se puede realizar el 'merging'  (actualizar la rama local usando la rama remota )
#   5 > Error en la actualización: No se puede realizar el 'rebasing' (actualizar la rama local usando la rama remota )
#   9 > Error en la actualización: El folder del repositorio es invalido o no existe
function _update_repository() {

    #1. Argumentos
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
    fi

    local p_repo_path="$2"
    local p_repo_name="$3"
    local p_repo_type="$4"


    #2. Mostando el titulo

    printf '\n'
    print_line '-' $g_max_length_line "$g_color_opaque" 
    if [ $p_is_neovim -eq 0  ]; then
        printf 'NeoVIM> Git repository "%b%s%b" %b(%s)%b\n' "$g_color_subtitle" "$p_repo_name" "$g_color_reset" "$g_color_opaque" "$p_repo_path" "$g_color_opaque"
    else
        printf 'VIM   > Git repository "%b%s%b" %b(%s)%b\n' "$g_color_subtitle" "$p_repo_name" "$g_color_reset" "$g_color_opaque" "$p_repo_path" "$g_color_opaque"
    fi
    print_line '-' $g_max_length_line "$g_color_opaque" 

    #1. Validar si existe directorio
    if [ ! -d $p_repo_path ]; then
        echo "Folder \"${p_repo_path}\" not exists"
        return 9
    fi

    cd $p_repo_path

    #2. Validar si el directorio .git del repositorio es valido     
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo 'Invalid git repository'
        return 9
    fi
    
    local l_local_branch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
    local l_remote=$(git config branch.${l_local_branch}.remote)
    local l_remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
    local l_status

    #3. Actualizando la rama remota del repositorio local desde el repositorio remoto
    printf 'Fetching from remote repository "%b%s%b" to remote branch "%b%s%b"...\n' "$g_color_opaque" "$l_remote"  "$g_color_reset" "$g_color_opaque" \
           "$l_remote_branch" "$g_color_reset"
    git fetch ${l_remote}
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf '%bError (%s) on Fetching%b from remote repository "%b%s%b" to remote branch "%b%s%b"...\n' "$g_color_warning" "$l_status" "$g_color_reset" \
               "$g_color_opaque" "$l_remote" "$g_color_reset" "$g_color_opaque" "$l_remote_branch" "$g_color_reset"
        return 3
    fi 

    #4. Si la rama local es igual a la rama remota
    printf 'Updating local branch "%b%s%b" form remote branch "%b%s%b"...\n' "$g_color_opaque" "$l_local_branch"  "$g_color_reset" "$g_color_opaque" \
           "$l_remote_branch" "$g_color_reset"
    if git merge-base --is-ancestor ${l_remote_branch} HEAD; then
        echo 'Already up-to-date'
        return 0
    fi

    #5. Si la rama local es diferente al rama remota

    #¿Es posible realizar 'merging'?
    if git merge-base --is-ancestor HEAD ${l_remote_branch}; then

        echo 'Fast-forward possible. Merging...'
        git merge --ff-only --stat ${l_remote_branch}

        l_status=$?
        if [ $l_status -ne 0 ]; then
            printf '%bError (%s) on Merging%b from remote repository "%b%s%b" to remote branch "%b%s%b"...\n' "$g_color_warning" "$l_status" "$g_color_reset" \
                   "$g_color_opaque" "$l_remote" "$g_color_reset" "$g_color_opaque" "$l_remote_branch" "$g_color_reset"
            return 4
        fi

        return 1
    fi

    #Realizanfo 'rebasing'
    echo 'Fast-forward not possible. Rebasing...'
    git rebase --preserve-merges --stat ${l_remote_branch}

    l_status=$?
    if [ $l_status -ne 0 ]; then
        printf '%bError (%s) on Rebasing%b from remote repository "%b%s%b" to remote branch "%b%s%b"...\n' "$g_color_warning" "$l_status" "$g_color_reset" \
               "$g_color_opaque" "$l_remote" "$g_color_reset" "$g_color_opaque" "$l_remote_branch" "$g_color_reset"
        return 5
    fi

    return 2

}


function _update_vim_package() {

    #1. Argumentos
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
    fi

    local p_is_coc_installed=1
    if [ "$2" = "0" ]; then
        p_is_coc_installed=0
    fi

    #2. Ruta base donde se instala el plugins/paquete
    local l_tag="VIM"
    local l_base_plugins_path="${HOME}/.vim/pack"
    if [ $p_is_neovim -eq 0  ]; then
        l_base_plugins_path="${HOME}/.local/share/nvim/site/pack"
        l_tag="NeoVIM"
    fi
    
    #Validar si existe directorio
    if [ ! -d "$l_base_plugins_path" ]; then
        printf 'Folder "%s" not exists\n' "$l_base_plugins_path"
        return 9
    fi

    #3. Buscar los repositorios git existentes en la carpeta plugin y actualizarlos
    local l_folder
    local l_repo_type
    local l_repo_name
    local l_status

    local la_doc_paths=()
    local la_doc_repos=()

    cd $l_base_plugins_path
    for l_folder  in $(find . -mindepth 4 -maxdepth 4 -type d -name .git); do

        l_folder="${l_folder%/.git}"
        l_folder="${l_folder#./}"

        l_repo_name="${l_folder##*/}"
        l_repo_type="${l_folder%%/*}"

        l_folder="${l_base_plugins_path}/${l_folder}"

        _update_repository $p_is_neovim "$l_folder" "$l_repo_name" "$l_repo_type"
        l_status=$?

        #Si se actualizo con existo, indexar la ruta de documentacion a indexar 
        if [ $l_status -eq 1 ] || [ $l_status -eq 2 ]; then

            if [ -d "${l_folder}/doc" ]; then

                #Indexar la documentación de plugins
                la_doc_paths+=("${l_folder}/doc")
                la_doc_repos+=("${l_repo_name}")

            fi
        fi

    done

    #4. Actualizar la documentación de VIM (Los plugins VIM que no tiene documentación, no requieren indexar)
    local l_doc_path
    local l_n=${#la_doc_paths[@]}
    local l_i
    if [ $l_n -gt 0 ]; then

        printf '\n'
        print_line '-' $g_max_length_line "$g_color_opaque" 
        if [ $p_is_neovim -eq 0  ]; then
            printf 'NeoVIM> %bIndexando las documentación%b de los plugins\n' "$g_color_subtitle" "$g_color_reset"
        else
            printf 'VIM   > %bIndexando las documentación%b de los plugins\n' "$g_color_subtitle" "$g_color_reset"
        fi
        print_line '-' $g_max_length_line "$g_color_opaque" 

        for ((l_i=0; l_i< ${l_n}; l_i++)); do
            
            l_doc_path="${la_doc_paths[${l_i}]}"
            l_repo_name="${la_doc_repos[${l_i}]}"
            printf '(%s/%s) Indexando la documentación del plugin %b%s%b en %s: "%bhelptags %s%b"\n' "$((l_i + 1))" "$l_n" "$g_color_opaque" "$l_repo_name" \
                   "$g_color_reset" "$l_tag" "$g_color_opaque" "$l_doc_path" "$g_color_reset"
            if [ $p_is_neovim -eq 0  ]; then
                nvim --headless -c "helptags ${l_doc_path}" -c qa
            else
                vim -u NONE -esc "helptags ${l_doc_path}" -c qa
            fi

        done

        printf '\n'

    fi

    #5. Actauliar los modulos de los  paquetes/plugin de VIM/NeoVIM que lo requieren.
    if [ $p_is_coc_installed -ne 0 ]; then
        printf 'Se ha actualizado los plugin/paquetes de %b%s%b.\n' "$g_color_subtitle" "$l_tag" "$g_color_reset"
        return 0
    fi

    printf 'Se ha actualizado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "$l_tag" "$g_color_reset" "$g_color_subtitle" "Developer" "$g_color_reset"
    printf 'Los plugins del IDE CoC de %s tiene componentes que requieren actualizarlo. Actualizando dichas componentes del plugins...\n' "$l_tag"

    #Actualizando los parseadores de lenguaje de 'nvim-treesitter'
    if [ $p_is_neovim -eq 0  ]; then

        #Requiere un compilador C/C++ y NodeJS: https://tree-sitter.github.io/tree-sitter/creating-parsers#installation
        local l_version=$(_get_gcc_version)
        if [ ! -z "$l_version" ]; then
            printf '  Actualizando los "language parsers" de TreeSitter "%b:TSUpdate all%b"\n' \
                   "$g_color_opaque" "$g_color_reset"
            nvim --headless -c 'TSUpdate all' -c 'qa'
            printf '\n'
        fi
    fi

    #Actualizar las extensiones de CoC
    printf '  Actualizando los extensiones existentes de CoC, ejecutando el comando "%b:CocUpdate%b"\n' "$g_color_opaque" "$g_color_reset"
    if [ $p_is_neovim -ne 0  ]; then
        vim -esc 'CocUpdate' -c 'qa'
    else
        USE_COC=1 nvim --headless -c 'CocUpdate' -c 'qa'
    fi

    #Actualizando los gadgets de 'VimSpector'
    if [ $p_is_neovim -ne 0  ]; then
        printf '  Actualizando los gadgets de "VimSpector", ejecutando el comando "%b:VimspectorUpdate%b"\n' "$g_color_opaque" "$g_color_reset"
        vim -esc 'VimspectorUpdate' -c 'qa'
    fi


    printf '\nRecomendaciones:\n'
    if [ $p_is_neovim -ne 0  ]; then

        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 vim%b"\n' "$g_color_subtitle" "$g_color_reset"
        printf '    > Se recomienda que configure su IDE CoC segun su necesidad:\n'

    else

        printf '  > Por defecto, se ejecuta el IDE vinculado al LSP nativo de NeoVIM.\n'
        printf '    > Si desea usar CoC, use: "%bUSE_COC=1 nvim%b"\n' "$g_color_subtitle" "$g_color_reset"
        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 nvim%b"\n' "$g_color_subtitle" "$g_color_reset"

        printf '  > Si usar como Developer con IDE CoC, se recomienda que lo configura segun su necesidad:\n'

    fi

    echo "        1> Instalar extensiones de COC segun su necesidad (Listar existentes \":CocList extensions\")"
    echo "        2> Revisar la Configuracion de COC \":CocConfig\":"
    echo "          2.1> El diganostico se enviara ALE (no se usara el integrado de CoC), revisar:"
    echo "               { \"diagnostic.displayByAle\": true }"
    echo "          2.2> El formateador de codigo 'Prettier' sera proveido por ALE (no se usara la extension 'coc-prettier')"
    echo "               Si esta instalado esta extension, desintalarlo."


    return 0

}

function _update_vim() {

    #1. Argumentos
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
    fi

    local p_is_coc_installed=1
    if [ "$2" = "0" ]; then
        p_is_coc_installed=0
    fi

    local l_tag="VIM"
    if [ $p_is_neovim -eq 0  ]; then
        l_tag="NeoVIM"
    fi
    

    #2. Actualizar los plugins
    _update_vim_package $p_is_neovim $p_is_coc_installed

    #Si es desarrallador: Actualizar los modulos Python
    #Si es desarrollador: Actualizar los paquetes globales Node.JS istalados

}

#
# Argumentos:
#  1> Las opciones de menu elejidas. 
function _update_all() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi
    
    #2. Actualizar los paquetes instalados desde los repositorios SO
    g_status_crendential_storage=-1
    local l_title
    local l_status
    local l_flag
    local l_opcion=1
    local l_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_noninteractive=0
    fi

    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

        l_flag=$(( $p_opciones & $l_opcion ))
        if [ $l_flag -eq $l_opcion ]; then

        
            #Solicitar credenciales de administrador y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq 0 ]; then
                storage_sudo_credencial
                g_status_crendential_storage=$?
                #Se requiere almacenar las credenciales para realizar cambio con sudo. 
                #  Si es 0 o 1: la instalación/configuración es completar
                #  Si es 2    : el usuario no acepto la instalación/configuración
                #  Si es 3 0 4: la instalacion/configuración es parcial (solo se instala/configura, lo que no requiere sudo)
                if [ $g_status_crendential_storage -eq 2 ]; then
                    return 120
                fi
            fi

            print_line '─' $g_max_length_line  "$g_color_blue"
            printf -v l_title "Actualizar los paquetes del SO '%s%s %s%s'" "$g_color_subtitle" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
            print_text_in_center2 "$l_title" $g_max_length_line 
            print_line '─' $g_max_length_line "$g_color_blue"

            upgrade_os_packages $g_os_subtype_id $l_noninteractive
            echo ""

        fi

    fi

    #3. Actualizar los binarios instados de repositorios como Git
    l_opcion=2
    l_flag=$(( $p_opciones & $l_opcion ))
    if [ $l_flag -eq $l_opcion ]; then

        #Parametros:
        # 1> Tipo de ejecución: 1 (ejecución no-interactiva para actualizar un conjuentos de respositorios)
        # 2> Opciones de menu seleccionados para instalar/actualizar: 2 (instalar/actualizar solo los comandos instalados)
        # 3> El estado de la credencial almacenada para el sudo
        if [ $l_noninteractive -eq 1 ]; then
            ~/.files/setup/linux/01_setup_commands.bash 1 2 $g_status_crendential_storage
            l_status=$?
        else
            ~/.files/setup/linux/01_setup_commands.bash 3 2 $g_status_crendential_storage
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

    #Version de NodeJS instalado
    local l_nodejs_version=$(_get_nodejs_version)

    #4. Actualizar paquetes VIM instalados
    local l_version
    local l_aux=""
    local l_is_coc_installed=1

    l_opcion=4
    l_flag=$(( $p_opciones & $l_opcion ))

    if [ $l_flag -eq $l_opcion ]; then

        #Obtener la version actual de VIM
        l_version=$(vim --version 2> /dev/null)
        l_status=$?
        if [ $l_status -eq 0 ]; then
            l_version=$(echo "$l_version" | head -n 1)
            l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        else
            l_version=""
        fi

        #Solo actualizar si esta instalado
        if [ ! -z "$l_version" ]; then

            #Mostrar el titulo
            printf -v l_aux "%sVIM%s %s(%s)%s" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_version" "$g_color_reset"
            printf -v l_title "Actualizar los paquetes de %s" "$l_aux"

            print_line '─' $g_max_length_line  "$g_color_blue"
            print_text_in_center2 "$l_title" $g_max_length_line
            print_line '─' $g_max_length_line "$g_color_blue"

            #Determinar si esta instalado en modo developer
            l_is_coc_installed=1
            _is_developer_vim_profile 1
            l_status=$?
            if [ $l_status -eq 1 ]; then
                if [ -z "$l_nodejs_version" ]; then
                    printf 'Se actualizará los paquetes/plugins de VIM %s %b(Modo developer, %bNodeJS no intalado%b)%b ...\n' "${l_version}" "$g_color_opaque" \
                           "$g_color_warning" "$g_color_opaque" "$g_color_reset"
                else
                    printf 'Se actualizará los paquetes/plugins de VIM %s %b(Modo developer, NodeJS "%s")%b ...\n' "${l_version}" "$g_color_opaque" \
                           "$l_nodejs_version" "$g_color_reset"
                    l_is_coc_installed=0
                fi
            else
                printf 'Se actualizará los paquetes/plugins de VIM %s ...\n' "${l_version}"
            fi

            #Actualizar los plugins
            _update_vim 1 $l_is_coc_installed
        fi

    fi

    #5. Actualizar paquetes VIM/NeoVIM instalados
    l_opcion=8
    l_flag=$(( $p_opciones & $l_opcion ))

    if [ $l_flag -eq $l_opcion ]; then

        #Obtener la version actual de VIM
        l_version=$(nvim --version 2> /dev/null)
        l_status=$?
        if [ $l_status -eq 0 ]; then
            l_version=$(echo "$l_version" | head -n 1)
            l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        else
            l_version=""
        fi

        #Solo actualizar si esta instalado
        if [ ! -z "$l_version" ]; then

            #Mostrar el titulo
            printf -v l_aux "%sNeoVIM%s %s(%s)%s" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$l_version" "$g_color_reset"
            printf -v l_title "Actualizar los paquetes de %s" "$l_aux"

            print_line '─' $g_max_length_line  "$g_color_blue"
            print_text_in_center2 "$l_title" $g_max_length_line
            print_line '─' $g_max_length_line "$g_color_blue"

            #Determinar si esta instalado en modo developer
            l_is_coc_installed=1
            _is_developer_vim_profile 0
            l_status=$?
            if [ $l_status -eq 1 ]; then
                if [ -z "$l_nodejs_version" ]; then
                    printf 'Se actualizará los paquetes/plugins de NeoVIM %s %b(Modo developer, %bNodeJS no intalado%b)%b ...\n' "${l_version}" "$g_color_opaque" \
                           "$g_color_warning" "$g_color_opaque" "$g_color_reset"
                else
                    printf 'Se actualizará los paquetes/plugins de NeoVIM %s %b(Modo developer, NodeJS "%s")%b ...\n' "${l_version}" "$g_color_opaque" \
                           "$l_nodejs_version" "$g_color_reset"
                    l_is_coc_installed=0
                fi
            else
                printf 'Se actualizará los paquetes/plugins de NeoVIM %s ...\n' "${l_version}"
            fi

            #Actualizar los plugins
            _update_vim 0 $l_is_coc_installed

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
    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
        printf " (%ba%b) Actualizar los artefactos existentes: Paquetes del SO y plugin VIM/NeoVIM\n" "$g_color_title" "$g_color_reset"
        printf " (%bb%b) Actualizar los artefactos existentes: Paquetes del SO, binarios de GIT y plugins VIM/NeoVIM\n" "$g_color_title" "$g_color_reset"
    else
        printf " (%ba%b) Actualizar los artefactos existentes: Plugins VIM/NeoVIM\n" "$g_color_title" "$g_color_reset"
        printf " (%bb%b) Actualizar los artefactos existentes: Binarios de GIT y VIM/NeoVIM\n" "$g_color_title" "$g_color_reset"
    fi
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    local l_max_digits=$?

    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
        printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes del SO existentes\n" "$g_color_title" "1" "$g_color_reset"
    fi
    printf "     (%b%0${l_max_digits}d%b) Actualizar los comandos/programas descargdos de repositorio como GitHub\n" "$g_color_title" "2" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar los plugin de VIM    existentes e inicializarlos\n" "$g_color_title" "4" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar los plugin de NeoVIM existentes e inicializarlos\n" "$g_color_title" "8" "$g_color_reset"

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
                if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
                    #1 + 4 + 8
                    _update_all 13
                else
                    #4 + 8
                    _update_all 12
                fi
                ;;

            b)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                
                printf '\n'
                if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
                    #1 + 2 + 4 + 8
                    _update_all 15
                else
                    #2 + 4 + 8
                    _update_all 14
                fi
                ;;


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

g_usage() {

    printf '%bUsage:\n\n' "$g_color_opaque"
    printf '  > Configurar el profile mostrando el menú de opciones (interactivo):\n'
    printf '    %b~/.files/setup/linux/02_setup_profile.bash\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Configurar un grupo de opciones del menú sin mostrarlo pero en modo interactivo:\n'
    printf '    %b~/.files/setup/linux/02_setup_profile.bash 1 MENU-OPTIONS\n%b' "$g_color_info" "$g_color_opaque"
    printf '  > Configurar un grupo de opciones del menú sin mostrarlo pero en modo no-interactivo:\n'
    printf '    %b~/.files/setup/linux/02_setup_profile.bash 2 MENU-OPTIONS%b\n\n' "$g_color_info" "$g_color_reset"

}


#1. Logica principal del script (incluyendo los argumentos variables)

#Argumento 1: el modo de ejecución del script
if [ -z "$1" ]; then
    gp_type_calling=0
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
else
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 110
fi

#1.1. Mostrar el menu para escoger lo que se va instalar
if [ $gp_type_calling -eq 0 ]; then

    #Validar los requisitos (0 debido a que siempre se ejecuta de modo interactivo)
    _g_status=0
    fulfill_preconditions $g_os_subtype_id 0 0 1
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_main
    fi

#1.2. No mostrar el menu, la opcion del menu a ejecutar se envia como parametro
else

    #Argumento 2: las opcione de menu a ejecutar
    gp_menu_options=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        gp_menu_options=$2
    else
        echo "Parametro 2 \"$2\" debe ser una opción valida."
        exit 110
    fi

    #Ejecutar las opciones de menu escogidas
    _update_all $gp_menu_options

fi





