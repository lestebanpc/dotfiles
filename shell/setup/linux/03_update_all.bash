#!/bin/bash

#
#Devolverá la ruta base 'PATH_BASE' donde esta el repositorio '.files'.
#Nota: Los script de instalación tiene una ruta similar a 'PATH_BASE/REPO_NAME/shell/setup/linux/SCRIPT.bash', donde 'REPO_NAME' siempre es '.files'.
#
#Parametros de entrada:
#  1> La ruta relativa (o absoluta) de un archivos del repositorio
#Parametros de salida: 
#  STDOUT> La ruta base donde esta el repositorio
function _get_current_path_base() {

    #Obteniendo la ruta absoluta del parametro ingresado
    local l_path=''
    l_path=$(realpath "$1" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        echo "$HOME"
        return 1
    fi

    #Obteniendo la ruta base
    l_path=${l_path%/.files/shell/setup/linux/*}
    echo "$l_path"
    return 0
}


#Inicialización Global {{{

declare -r g_path_base=$(_get_current_path_base "${BASH_SOURCE[0]}")

#Si se ejecuta un usuario root y es diferente al usuario que pertenece este script de instalación (es decir donde esta el repositorio)
#UID del Usuario y GID del grupo (diferente al actual) que ejecuta el script actual
g_other_calling_user=''

#Funciones generales, determinar el tipo del SO y si es root
. ${g_path_base}/.files/shell/shared/func_utility.bash

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
    set_user_options

fi


#Funciones de utilidad
. ${g_path_base}/.files/shell/setup/linux/_common_utility.bash


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
    local l_tag="VIM"
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
        l_tag="NeoVIM"
    fi

    local p_repo_path="$2"
    local p_repo_name="$3"
    local p_repo_type="$4"


    #2. Mostando el titulo

    printf '\n'
    print_line '.' $g_max_length_line "$g_color_gray1" 
    printf '%s > Git repository "%b%s%b" %b(%s)%b\n' "$l_tag" "$g_color_cian1" "$p_repo_name" "$g_color_reset" "$g_color_gray1" "$p_repo_path" "$g_color_gray1"
    print_line '.' $g_max_length_line "$g_color_gray1" 

    #1. Validar si existe directorio
    if [ ! -d $p_repo_path ]; then
        echo "Folder \"${p_repo_path}\" not exists"
        return 9
    fi

    cd $p_repo_path

    #2. Validar si el directorio .git del repositorio es valido     
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        printf '%bInvalid git repository%b\n' "$g_color_red1" "$g_color_reset"
        return 9
    fi
    
    local l_local_branch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
    if [ "$l_local_branch" = "HEAD" ]; then
        printf '%bInvalid current branch of  repository%b\n' "$g_color_red1" "$g_color_reset"
        return 8
    fi

    local l_remote=$(git config branch.${l_local_branch}.remote)
    local l_remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
    local l_status

    #3. Actualizando la rama remota del repositorio local desde el repositorio remoto
    printf 'Fetching from remote repository "%b%s%b" to remote branch "%b%s%b"...\n' "$g_color_gray1" "$l_remote"  "$g_color_reset" "$g_color_gray1" \
           "$l_remote_branch" "$g_color_reset"
    git fetch ${l_remote}
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf '%bError (%s) on Fetching%b from remote repository "%b%s%b" to remote branch "%b%s%b"...\n' "$g_color_red1" "$l_status" "$g_color_reset" \
               "$g_color_gray1" "$l_remote" "$g_color_reset" "$g_color_gray1" "$l_remote_branch" "$g_color_reset"
        return 3
    fi 

    #4. Si la rama local es igual a la rama remota
    printf 'Updating local branch "%b%s%b" form remote branch "%b%s%b"...\n' "$g_color_gray1" "$l_local_branch"  "$g_color_reset" "$g_color_gray1" \
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
            printf '%bError (%s) on Merging%b from remote repository "%b%s%b" to remote branch "%b%s%b"...\n' "$g_color_red1" "$l_status" "$g_color_reset" \
                   "$g_color_gray1" "$l_remote" "$g_color_reset" "$g_color_gray1" "$l_remote_branch" "$g_color_reset"
            return 4
        fi

        return 1
    fi

    #Realizanfo 'rebasing'
    echo 'Fast-forward not possible. Rebasing...'
    git rebase --preserve-merges --stat ${l_remote_branch}

    l_status=$?
    if [ $l_status -ne 0 ]; then
        printf '%bError (%s) on Rebasing%b from remote repository "%b%s%b" to remote branch "%b%s%b"...\n' "$g_color_red1" "$l_status" "$g_color_reset" \
               "$g_color_gray1" "$l_remote" "$g_color_reset" "$g_color_gray1" "$l_remote_branch" "$g_color_reset"
        return 5
    fi

    return 2

}


function _copy_plugin_files() {

    #1. Argumentos
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
    fi

    local p_repo_name="$2"
    local p_repo_path="$3"
    local p_repo_type="$4"

    local l_result=0
    case "$p_repo_name" in

        fzf)

            #printf '%bCopiando archivos opcionales usados por comando fzf%b desde el repositorio "%bjunegunn/fzf%b"...\n' \
            #       "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

            ##Copiar los archivos de ayuda man para comando fzf y el script fzf-tmux
            #echo "Copiando los archivos de ayuda \"./man/man1/fzf.1\" y \"./man/man1/fzf-tmux.1\" en \"${g_path_man}/\" ..."
            #if [ $g_user_sudo_support -ne 0 ] && [ $g_user_sudo_support -ne 1 ]; then
            #    cp "${p_repo_path}/man/man1/fzf.1" "${g_path_man}/" 
            #    cp "${p_repo_path}/man/man1/fzf-tmux.1" "${g_path_man}/" 
            #else
            #    sudo cp "${p_repo_path}/man/man1/fzf.1" "${g_path_man}/" 
            #    sudo cp "${p_repo_path}/man/man1/fzf-tmux.1" "${g_path_man}/" 
            #fi
            #
            ##Copiar los script de completado
            #echo "Copiando el script \"./shell/completion.bash\" como \"~/.files/terminal/linux/complete/fzf.bash\" ..."
            #cp "${p_repo_path}/shell/completion.bash" "${g_path_base}/.files/terminal/linux/complete/fzf.bash"

            ##Copiar los script de keybindings
            #echo "Copiando el script \"./shell/key-bindings.bash\" como \"~/.files/terminal/linux/keybindings/fzf.bash\" ..."
            #cp "${p_repo_path}/shell/key-bindings.bash" "${g_path_base}/.files/terminal/linux/keybindings/fzf.bash"
            #
            ## Script que se usara como comando para abrir fzf en un panel popup tmux
            #echo "Copiando el script \"./bin/fzf-tmux\" como \"~/.files/shell/fzf/fzf-tmux.bash\" y crear un enlace el como comando \"~/.local/bin/fzf-tmux\"..."
            #cp "${p_repo_path}/bin/fzf-tmux" "${g_path_base}/.files/shell/fzf/fzf-tmux.bash"

            #if [ ! -d "${g_path_base}/.local" ]; then
            #    mkdir -p ${g_path_base}/.local/bin
            #    if [ ! -z "$g_other_calling_user" ]; then
            #        chown $g_other_calling_user ${g_path_base}/.local/
            #        chown $g_other_calling_user ${g_path_base}/.local/bin
            #    fi
            #elif [ ! -d "${g_path_base}/.local/bin" ]; then
            #    mkdir -p ${g_path_base}/.local/bin
            #    if [ ! -z "$g_other_calling_user" ]; then
            #        chown $g_other_calling_user ${g_path_base}/.local/bin
            #    fi
            #fi

            #ln -sfn ${g_path_base}/.files/shell/fzf/fzf-tmux.bash ${g_path_base}/.local/bin/fzf-tmux

            #if [ ! -z "$g_other_calling_user" ]; then
            #    chown $g_other_calling_user ${g_path_base}/.files/terminal/linux/complete/fzf.bash 
            #    chown $g_other_calling_user ${g_path_base}/.files/terminal/linux/keybindings/fzf.bash
            #    chown $g_other_calling_user ${g_path_base}/.files/terminal/linux/functions/fzf-tmux.bash
            #    chown -h $g_other_calling_user ${g_path_base}/.local/bin/fzf-tmux
            #fi
            l_result=0
            ;;

        #fzf.vim)
            #l_result=0
            #;;

    esac

    return $l_result

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

        #Si se llego a actualizar con existo... 
        if [ $l_status -eq 1 ] || [ $l_status -eq 2 ]; then

            #Si tiene documentación, indexar la ruta de documentación...
            if [ -d "${l_folder}/doc" ]; then
                la_doc_paths+=("${l_folder}/doc")
                la_doc_repos+=("${l_repo_name}")
            fi

            #Copiar algunos archivos del plugins a los archivos del usuario.
            _copy_plugin_files $p_is_neovim "$l_repo_name" "$l_folder" "$l_repo_type"
        fi

    done

    #4. Actualizar la documentación de VIM (Los plugins VIM que no tiene documentación, no requieren indexar)
    local l_doc_path
    local l_n=${#la_doc_paths[@]}
    local l_i
    if [ $l_n -gt 0 ]; then

        printf '\n'
        print_line '.' $g_max_length_line "$g_color_gray1" 
        printf '%s > %bIndexando las documentación%b de los plugins\n' "$l_tag" "$g_color_cian1" "$g_color_reset"
        print_line '.' $g_max_length_line "$g_color_gray1" 

        for ((l_i=0; l_i< ${l_n}; l_i++)); do
            
            l_doc_path="${la_doc_paths[${l_i}]}"
            l_repo_name="${la_doc_repos[${l_i}]}"
            printf '(%s/%s) Indexando la documentación del plugin %b%s%b en %s: "%bhelptags %s%b"\n' "$((l_i + 1))" "$l_n" "$g_color_gray1" "$l_repo_name" \
                   "$g_color_reset" "$l_tag" "$g_color_gray1" "$l_doc_path" "$g_color_reset"
            if [ $p_is_neovim -eq 0  ]; then
                nvim --headless -c "helptags ${l_doc_path}" -c qa
            else
                vim -u NONE -esc "helptags ${l_doc_path}" -c qa
            fi

        done

        printf '\n'

    fi

    #5. Actualizar los modulos de los  paquetes/plugin de VIM/NeoVIM que lo requieren.
    if [ $p_is_coc_installed -ne 0 ]; then
        printf 'Se ha actualizado los plugin/paquetes de %b%s%b.\n' "$g_color_cian1" "$l_tag" "$g_color_reset"
        return 0
    fi

    printf 'Se ha actualizado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_cian1" "$l_tag" "$g_color_reset" "$g_color_cian1" "Developer" "$g_color_reset"
    printf 'Los plugins del IDE CoC de %s tiene componentes que requieren actualizarlo. Actualizando dichas componentes del plugins...\n' "$l_tag"

    #Actualizando los parseadores de lenguaje de 'nvim-treesitter'
    if [ $p_is_neovim -eq 0  ]; then

        #Requiere un compilador C/C++ y NodeJS: https://tree-sitter.github.io/tree-sitter/creating-parsers#installation
        local l_version=$(_get_gcc_version)
        if [ ! -z "$l_version" ]; then
            printf '  Actualizando los "language parsers" de TreeSitter "%b:TSUpdate all%b"\n' \
                   "$g_color_gray1" "$g_color_reset"
            nvim --headless -c 'TSUpdate all' -c 'qa'
            printf '\n'
        fi
    fi

    #Actualizar las extensiones de CoC
    printf '  Actualizando los extensiones existentes de CoC, ejecutando el comando "%b:CocUpdate%b"\n' "$g_color_gray1" "$g_color_reset"
    if [ $p_is_neovim -ne 0  ]; then
        vim -esc 'CocUpdate' -c 'qa'
    else
        USE_COC=1 nvim --headless -c 'CocUpdate' -c 'qa'
    fi

    #Actualizando los gadgets de 'VimSpector'
    if [ $p_is_neovim -ne 0  ]; then
        printf '  Actualizando los gadgets de "VimSpector", ejecutando el comando "%b:VimspectorUpdate%b"\n' "$g_color_gray1" "$g_color_reset"
        vim -esc 'VimspectorUpdate' -c 'qa'
    fi


    printf '\nRecomendaciones:\n'
    if [ $p_is_neovim -ne 0  ]; then

        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 vim%b"\n' "$g_color_cian1" "$g_color_reset"
        printf '    > Se recomienda que configure su IDE CoC segun su necesidad:\n'

    else

        printf '  > Por defecto, se ejecuta el IDE vinculado al LSP nativo de NeoVIM.\n'
        printf '    > Si desea usar CoC, use: "%bUSE_COC=1 nvim%b"\n' "$g_color_cian1" "$g_color_reset"
        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 nvim%b"\n' "$g_color_cian1" "$g_color_reset"

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
    local l_flag_setup=0

    #Se requiere tener Git instalado
    if ! git --version 1> /dev/null 2>&1; then

        #No esta instalado Git, No configurarlo
        l_flag_setup=1
        printf '%s > Se requiere que Git este instalado para actualizar los plugins de %s.\n' "$l_tag" "$l_tag"

    fi

    if [ $l_flag_setup -eq 0 ]; then

        _update_vim_package $p_is_neovim $p_is_coc_installed

    fi

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
    local l_status
    local l_flag
    local l_opcion=1
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
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

            printf '\n'
            print_line '-' $g_max_length_line  "$g_color_gray1"
            #print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "OS > Actualizar los paquetes del SO '%b%s %s%b'\n" "$g_color_cian1" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
            print_line '-' $g_max_length_line "$g_color_gray1"
            #print_line '─' $g_max_length_line  "$g_color_blue1"

            upgrade_os_packages $g_os_subtype_id $l_is_noninteractive

        fi

    fi

    #3. Actualizar los binarios instados de repositorios como Git
    l_opcion=2
    l_flag=$(( $p_opciones & $l_opcion ))
    if [ $l_flag -eq $l_opcion ]; then

        #Parametros usados por el script:
        # 1> Tipo de llamado: 1/3 (sin menu interactivo/no-interactivo).
        # 2> Opciones de menu a ejecutar: entero positivo.
        # 3> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado "/var/opt/tools" o "~/tools".
        # 4> Ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts").
        # 5> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
        # 6> El estado de la credencial almacenada para el sudo.
        # 7> Install only last version: por defecto es 1 (false). Solo si ingresa 0, se cambia a 0 (true).
        # 8> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID".
        if [ $l_is_noninteractive -eq 1 ]; then
            ${g_path_base}/.files/shell/setup/linux/01_setup_commands.bash 1 2 "$g_path_programs" "" "$g_path_temp" $g_status_crendential_storage 1 "$g_other_calling_user"
            l_status=$?
        else
            ${g_path_base}/.files/shell/setup/linux/01_setup_commands.bash 3 2 "$g_path_programs" "" "$g_path_temp" $g_status_crendential_storage 1 "$g_other_calling_user"
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
    local l_nodejs_version=$(get_nodejs_version)

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
            printf -v l_aux "%bVIM%b %b(%s)%b" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$l_version" "$g_color_reset"

            printf '\n'
            print_line '-' $g_max_length_line  "$g_color_gray1"
            #print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "VIM > Actualizar los plugins de %b\n" "$l_aux"
            print_line '-' $g_max_length_line "$g_color_gray1"
            #print_line '─' $g_max_length_line  "$g_color_blue1"

            #Determinar si esta instalado en modo developer
            l_is_coc_installed=1
            check_vim_profile 1
            l_status=$?
            if [ $l_status -eq 1 ]; then
                if [ -z "$l_nodejs_version" ]; then
                    printf 'Se actualizará los paquetes/plugins de VIM %s %b(Modo developer, %bNodeJS no intalado%b)%b ...\n' "${l_version}" "$g_color_gray1" \
                           "$g_color_red1" "$g_color_gray1" "$g_color_reset"
                else
                    printf 'Se actualizará los paquetes/plugins de VIM %s %b(Modo developer, NodeJS "%s")%b ...\n' "${l_version}" "$g_color_gray1" \
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
            printf -v l_aux "%bNeoVIM%b %b(%s)%b" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$l_version" "$g_color_reset"

            printf '\n'
            print_line '-' $g_max_length_line  "$g_color_gray1"
            #print_line '─' $g_max_length_line  "$g_color_blue1"
            printf "NeoVIM > Actualizar los paquetes de %b\n" "$l_aux"
            #print_line '─' $g_max_length_line "$g_color_blue1"
            print_line '-' $g_max_length_line  "$g_color_gray1"

            #Determinar si esta instalado en modo developer
            l_is_coc_installed=1
            check_vim_profile 0
            l_status=$?
            if [ $l_status -eq 1 ]; then
                if [ -z "$l_nodejs_version" ]; then
                    printf 'Se actualizará los paquetes/plugins de NeoVIM %s %b(Modo developer, %bNodeJS no intalado%b)%b ...\n' "${l_version}" "$g_color_gray1" \
                           "$g_color_red1" "$g_color_gray1" "$g_color_reset"
                else
                    printf 'Se actualizará los paquetes/plugins de NeoVIM %s %b(Modo developer, NodeJS "%s")%b ...\n' "${l_version}" "$g_color_gray1" \
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


    print_text_in_center "Menu de Opciones" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"
    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
        printf " (%ba%b) Actualizar los artefactos existentes: Paquetes del SO y plugin VIM/NeoVIM\n" "$g_color_green1" "$g_color_reset"
        printf " (%bb%b) Actualizar los artefactos existentes: Paquetes del SO, binarios de GIT y plugins VIM/NeoVIM\n" "$g_color_green1" "$g_color_reset"
    else
        printf " (%ba%b) Actualizar los artefactos existentes: Plugins VIM/NeoVIM\n" "$g_color_green1" "$g_color_reset"
        printf " (%bb%b) Actualizar los artefactos existentes: Binarios de GIT y VIM/NeoVIM\n" "$g_color_green1" "$g_color_reset"
    fi
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    local l_max_digits=$?

    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
        printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes del SO existentes\n" "$g_color_green1" "1" "$g_color_reset"
    fi
    printf "     (%b%0${l_max_digits}d%b) Actualizar los comandos/programas descargados de repositorio como GitHub\n" "$g_color_green1" "2" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar los plugin de VIM    existentes e inicializarlos\n" "$g_color_green1" "4" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Actualizar los plugin de NeoVIM existentes e inicializarlos\n" "$g_color_green1" "8" "$g_color_reset"

    print_line '-' $g_max_length_line "$g_color_gray1" 

}

function g_main() {

  
    #Mostar el menu principal 
    print_line '─' $g_max_length_line "$g_color_green1" 
    _show_menu_core

    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -r l_options

        case "$l_options" in
            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 

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
                print_line '─' $g_max_length_line "$g_color_green1" 
                
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
                print_line '─' $g_max_length_line "$g_color_green1" 
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_green1" 
                    _update_all $l_options
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

g_usage() {

    printf 'Usage:\n'
    printf '  > %bActualizaciones usando el menú de opciones (interactivo)%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b~/.files/shell/setup/linux/03_update_all.bash\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/shell/setup/linux/03_update_all.bash 0 PRG_PATH CMD_BASE_PATH TEMP_PATH SETUP_ONLYLAST_VERSION\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '  > %bActualizaciones SIN usar un menú de opciones:%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b~/.files/shell/setup/linux/03_update_all.bash CALLING_TYPE MENU-OPTIONS PRG_PATH CMD_BASE_PATH TEMP_PATH\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/shell/setup/linux/03_update_all.bash CALLING_TYPE MENU-OPTIONS PRG_PATH CMD_BASE_PATH TEMP_PATH SUDO-STORAGE-OPTIONS SETUP_ONLYLAST_VERSION OTHER-USERID\n\n%b' "$g_color_yellow1" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bCALLING_TYPE%b Es 0 si se muestra un menu, caso contrario es 1 si es interactivo y 2 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
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
    printf '  > %bSETUP_ONLYLAST_VERSION %bpor defecto es 1 (false). Solo si ingresa 0 se instala/actualiza la ultima versión.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bOTHER-USERID %bEl UID/GID del usuario al que es owner del script (el repositorio git) en formato "UID:GID". Solo si se ejecuta como root y este es diferente al onwer del script.%b\n\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

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


_g_result=0
_g_status=0

#Aun no se ha solicitado almacenar temporalmente las credenciales para el sudo
g_status_crendential_storage=-1
#La credencial no se almaceno por un script externo.
g_is_credential_storage_externally=1

#Rutas usuadas (con valores por defecto) durante el setup, cuyos valores reales son calculados usando: 'set_program_path', 'set_command_path' y 'set_temp_path'
g_path_programs='/var/opt/tools'
g_path_cmd_base=''
g_path_bin='/usr/local/bin'
g_path_man='/usr/local/man/man1'
g_path_fonts='/usr/share/fonts'
g_path_temp='/tmp'


#1.1. Mostrar el menu para escoger lo que se va instalar
if [ $gp_type_calling -eq 0 ]; then

    #Parametros usados por el script:
    # 1> Tipo de llamado: 0 (usar un menu interactivo).
    # 2> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado "/var/opt/tools" o "~/tools".
    # 3> Ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts").
    #    Si se envia vacio o EMPTY se usara el directorio predeterminado.
    #       > Comandos      : "/usr/local/bin"      (para todos los usuarios) y "~/.local/bin"         (solo para el usuario actual)
    #       > Archivos man1 : "/usr/local/man/man1" (para todos los usuarios) y "~/.local/man/man1"    (solo para el usuario actual)
    #       > Archivo fuente: "/usr/share/fonts"    (para todos los usuarios) y "~/.local/share/fonts" (solo para el usuario actual)
    # 4> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    # 5> Install only last version: por defecto es 1 (false). Solo si ingresa 0, se cambia a 0 (true).

    #Obtener los folderes de programas 'g_path_programs'
    _g_path=''
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        _g_path="$2"
    fi

    _g_is_noninteractive=1
    set_program_path "$g_path_base" $_g_is_noninteractive "$_g_path" ""

    #Obtener los folderes de comandos 'g_path_bin', archivos de ayuda 'g_path_man' y fuentes de letras 'g_path_fonts' 
    _g_path=''
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        _g_path="$3"
    fi

    set_command_path "$g_path_base" $_g_is_noninteractive "$_g_path" ""

    #Obtener los folderes temporal 'g_path_temp'
    _g_path=''
    if [ ! -z "$4" ] && [ "$4" != "EMPTY" ]; then
        _g_path="$4"
    fi

    set_temp_path "$_g_path"

    #Parametros del script usados hasta el momento:
    # 1> Setup only last version: por defecto es 1 (false). Solo si ingresa 0, se cambia a 0 (true).
    g_setup_only_last_version=1        
    if [ "$5" = "0" ]; then
        g_setup_only_last_version=0
    fi

    #Validar los requisitos (0 debido a que siempre se ejecuta de modo interactivo)
    #  1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info') 
    #  2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  3 > Flag '0' si se requere curl
    #  4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    #  5 > Path donde se encuentra el directorio donde esta el '.git'
    fulfill_preconditions $g_os_subtype_id 0 0 1 "$g_path_base"
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_main
    else
        _g_result=111
    fi

#1.2. No mostrar el menu, la opcion del menu a ejecutar se envia como parametro
else

    #Parametros del script usados hasta el momento:
    # 1> Tipo de ejecución: 1/2 (sin menu interactivo/no-interactivo).
    # 2> Opciones de menu a ejecutar: entero positivo.
    # 3> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado "/var/opt/tools" o "~/tools".
    # 4> Ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts").
    #    Si se envia vacio o EMPTY se usara el directorio predeterminado.
    #       > Comandos      : "/usr/local/bin"      (para todos los usuarios) y "~/.local/bin"         (solo para el usuario actual)
    #       > Archivos man1 : "/usr/local/man/man1" (para todos los usuarios) y "~/.local/man/man1"    (solo para el usuario actual)
    #       > Archivo fuente: "/usr/share/fonts"    (para todos los usuarios) y "~/.local/share/fonts" (solo para el usuario actual)
    # 5> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    # 6> El estado de la credencial almacenada para el sudo.
    # 7> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
    gp_menu_options=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        gp_menu_options=$2
    else
        echo "Parametro 2 \"$2\" debe ser una opción valida."
        exit 110
    fi

    if [ $gp_menu_options -le 0 ]; then
        echo "Parametro 2 \"$2\" debe ser un entero positivo."
        exit 110
    fi

    if [[ "$6" =~ ^[0-2]$ ]]; then
        g_status_crendential_storage=$6

        if [ $g_status_crendential_storage -eq 0 ]; then
            g_is_credential_storage_externally=0
        fi

    fi

    #Si se ejecuta un usuario root y es diferente al usuario que pertenece este script de instalación (es decir donde esta el repositorio)
    g_other_calling_user=''
    if [ $g_user_sudo_support -eq 4 ] && [ ! -z "$7" ] && [ "$7" != "EMPTY" ] && [ "$g_path_base" != "$HOME" ]; then
        if [[ "$7" =~ ^[0-9]+:[0-9]+$ ]]; then
            g_other_calling_user="$7"
        else
            echo "Parametro 7 \"$7\" debe ser tener el formado 'UID:GID'."
            exit 110
        fi
    fi


    #Obtener los folderes de programas 'g_path_programs'
    _g_path=''
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        _g_path="$3"
    fi

    _g_is_noninteractive=0
    if [ $gp_type_calling -eq 1 ]; then
        _g_is_noninteractive=1
    fi
    set_program_path "$g_path_base" $_g_is_noninteractive "$_g_path" "$g_other_calling_user"

    #Obtener los folderes de comandos 'g_path_bin', archivos de ayuda 'g_path_man' y fuentes de letras 'g_path_fonts' 
    _g_path=''
    if [ ! -z "$4" ] && [ "$4" != "EMPTY" ]; then
        _g_path="$4"
    fi

    set_command_path "$g_path_base" $_g_is_noninteractive "$_g_path" "$g_other_calling_user"

    #Obtener los folderes temporal 'g_path_temp'
    _g_path=''
    if [ ! -z "$5" ] && [ "$5" != "EMPTY" ]; then
        _g_path="$5"
    fi

    set_temp_path "$_g_path"


    #Validar los requisitos
    # 1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info') 
    # 2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    # 3 > Flag '0' si se requere curl
    # 4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    # 5 > Path donde se encuentra el directorio donde esta el '.git'
    fulfill_preconditions $g_os_subtype_id 0 0 1 "$g_path_base" "$g_other_calling_user"
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then

        #Ejecutar las opciones de menu escogidas
        _update_all $gp_menu_options
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








