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



#Cuando no se puede determinar la version actual (siempre se instalara)
declare -r g_version_none='0.0.0'

#Funciones de utilidad generalees para los instaladores:
. ${g_shell_path}/bash/bin/linuxsetup/lib/common_utility.bash

#Funciones de utilidad usados cuando se configura el profile:
. ${g_shell_path}/bash/bin/linuxsetup/lib/setup_profile_utility.bash


#}}}



# Repositorios Git que tiene submodulos y requieren obtener/actualizar en conjunto al modulo principal
# > Por defecto no se tiene submodulos (valor 0)
# > Valores :
#   (0) El repositorio solo tiene un modulo principal y no tiene submodulos.
#   (1) El repositorio tiene un modulo principal y submodulos de 1er nivel.
#   (2) El repositorio tiene un modulo principal y submodulos de varios niveles.
declare -A gA_repos_with_submmodules=(
        ['kulala.nvim']=1
    )



#------------------------------------------------------------------------------------------------------------------
#> Funciones usadas durante la Actualización {{{
#------------------------------------------------------------------------------------------------------------------
#
# Incluye las variable globales usadas como parametro de entrada y salida de la funcion que no sea resuda por otras
# funciones, cuyo nombre inicia con '_g_'.
#


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

#Realiza una actualización superficial del repositorios
#Parametros de salida (valores de retorno):
#   0 > El repositorio ya esta actualizado
#   1 > El repositorio se actualizo con exito
#   3 > Error en la actualización: No se puede realizar el 'fetching' (actualizar la rama remota del repositorio local)
#   8 > Error en la actualización: No se puede obtener información del repositorio local
#   9 > Error en la actualización: El folder del repositorio es invalido o no existe
function _update_repository2() {

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

    # Ejemplo : 'main'
    local l_local_branch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
    if [ "$l_local_branch" = "HEAD" ]; then
        printf '%bInvalid current branch of  repository%b\n' "$g_color_red1" "$g_color_reset"
        return 8
    fi

    # Ejemplo : 'origin'
    local l_remote=$(git config branch.${l_local_branch}.remote)
    # Ejemplo : 'origin/main'
    local l_remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
    local l_status
    local l_submodules_types=${gA_repos_with_submmodules[${p_repo_name}]:-0}

    #3. Actualizando la rama remota del repositorio local desde el repositorio remoto
    printf 'Fetching from remote repository "%b%s%b" to remote branch "%b%s%b" (%bgit fetch --depth=1 %s %s%b)...\n' "$g_color_gray1" "$l_remote"  "$g_color_reset" "$g_color_gray1" \
           "$l_remote_branch" "$g_color_reset" "$g_color_green1" "$l_remote" "$l_local_branch" "$g_color_reset"

    printf '%b' "$g_color_gray1"
    git fetch --depth=1 ${l_remote} ${l_local_branch}
    l_status=$?
    printf '%b' "$g_color_reset"

    if [ $l_status -ne 0 ]; then
        printf '%bError (%s) on Fetching%b from remote repository "%b%s%b" to remote branch "%b%s%b"...\n' "$g_color_red1" "$l_status" "$g_color_reset" \
               "$g_color_gray1" "$l_remote" "$g_color_reset" "$g_color_gray1" "$l_remote_branch" "$g_color_reset"
        return 3
    fi


    #4. Verificar si esta actualizado las ramas local y la de sigimiento
    local l_hash_head=$(git rev-parse HEAD)
    local l_hash_remote=$(git rev-parse FETCH_HEAD)

    if [ "$l_hash_head" = "$l_hash_remote" ]; then

        # Actualiza los submoduos
        if [ $l_submodules_types -eq 1 ] || [ $l_submodules_types -eq 2 ]; then

            printf '%bMain module is already up-to-date%b.\n' "$g_color_green1" "$g_color_reset"

            # Actualizar los submodulos definidos en '.gitmodules' y lo hace de manera superficial
            printf 'Updating submodule of repository "%b%s%b" (%bgit submodule update --remote --recursive --depth 1 --force%b)...\n' "$g_color_gray1" "$p_repo_name" \
                   "$g_color_reset" "$g_color_green1" "$g_color_reset"

            printf '%b' "$g_color_gray1"
            if [ $l_submodules_types -eq 1 ]; then
                git submodule update --remote --depth 1 --force
                l_status=$?
            else
                git submodule update --remote --recursive --depth 1 --force
                l_status=$?
            fi
            printf '%b' "$g_color_reset"

            if [ $l_status -ne 0 ]; then
                printf '%bError (%s) on updating submodules%b from repository "%b%s%b"...\n' "$g_color_red1" "$l_status" "$g_color_reset" \
                       "$g_color_gray1" "$p_repo_name" "$g_color_reset"
                return 3
            fi

            printf '%bSubmodules was uptodated%b.\n' "$g_color_green1" "$g_color_reset"

        else
            printf '%bAlready up-to-date%b.\n' "$g_color_green1" "$g_color_reset"
        fi

        return 0
    fi

    #5. Si la rama local es diferente al rama remota

    #4. Realizando una actualizacion destructiva y para quedar solo con el ultimo nodo de la rama remota
    printf 'Updating local branch "%b%s%b" form remote branch "%b%s%b" (%bgit reset --hard %s/HEAD%b)...\n' "$g_color_gray1" "$l_local_branch" \
           "$g_color_reset" "$g_color_gray1" "$l_remote_branch" "$g_color_reset" "$g_color_green1" "$l_remote" "$g_color_reset"

    printf '%b' "$g_color_gray1"
    git reset --hard ${l_remote}/HEAD
    l_status=$?
    printf '%b' "$g_color_reset"

    if [ $l_status -ne 0 ]; then

        printf '%bError (%s) on Updating%b from remote branch "%b%s%b"...\n' "$g_color_red1" "$l_status" "$g_color_reset" \
               "$g_color_gray1" "$l_remote_branch" "$g_color_reset"
        return 3

    fi

    # Actualiza los submoduos
    if [ $l_submodules_types -eq 1 ] || [ $l_submodules_types -eq 2 ]; then

        printf '%bMain module is already up-to-date%b.\n' "$g_color_green1" "$g_color_reset"

        # Actualizar los submodulos definidos en '.gitmodules' y lo hace de manera superficial
        printf 'Updating submodule of repository "%b%s%b" (%bgit submodule update --remote --recursive --depth 1 --force%b)...\n' "$g_color_gray1" "$p_repo_name" \
               "$g_color_reset" "$g_color_green1" "$g_color_reset"

        printf '%b' "$g_color_gray1"
        if [ $l_submodules_types -eq 1 ]; then
            git submodule update --remote --depth 1 --force
            l_status=$?
        else
            git submodule update --remote --recursive --depth 1 --force
            l_status=$?
        fi
        printf '%b' "$g_color_reset"

        if [ $l_status -ne 0 ]; then
            printf '%bError (%s) on updating submodules%b from repository "%b%s%b"...\n' "$g_color_red1" "$l_status" "$g_color_reset" \
                   "$g_color_gray1" "$p_repo_name" "$g_color_reset"
            return 3
        fi

        printf '%bSubmodules was updated%b.\n' "$g_color_green1" "$g_color_reset"

    else
        printf '%bRepository was updated%b.\n' "$g_color_green1" "$g_color_reset"
    fi

    return 0

}




#Actualizar el repositorios
#Parametros de salida (valores de retorno):
#   0 > El repositorio ya esta actualizado
#   1 > El repositorio se actualizo con exito (merge)
#   2 > El repositorio se actualizo con exito (rebase)
#   3 > Error en la actualización: No se puede realizar el 'fetching' (actualizar la rama remota del repositorio local)
#   4 > Error en la actualización: No se puede realizar el 'merging'  (actualizar la rama local usando la rama remota )
#   5 > Error en la actualización: No se puede realizar el 'rebasing' (actualizar la rama local usando la rama remota )
#   8 > Error en la actualización: No se puede obtener información del repositorio local
#   9 > Error en la actualización: El folder del repositorio es invalido o no existe
function _update_repository1() {

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

    # Ejemplo : 'main'
    local l_local_branch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
    if [ "$l_local_branch" = "HEAD" ]; then
        printf '%bInvalid current branch of  repository%b\n' "$g_color_red1" "$g_color_reset"
        return 8
    fi

    # Ejemplo : 'origin'
    local l_remote=$(git config branch.${l_local_branch}.remote)
    # Ejemplo : 'origin/main'
    local l_remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
    local l_status


    #3. Actualizando la rama remota del repositorio local desde el repositorio remoto
    printf 'Fetching from remote repository "%b%s%b" to remote branch "%b%s%b" (%bgit fetch %s %s%b)...\n' "$g_color_gray1" "$l_remote"  "$g_color_reset" "$g_color_gray1" \
           "$l_remote_branch" "$g_color_reset" "$g_color_gray1" "$l_remote" "$l_local_branch" "$g_color_reset"
    git fetch ${l_remote} ${l_local_branch}
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

    # Si la rama main es una subrama de la subrama de la rama local de seguimiento remoto
    # Es posible realizar 'merge' de tipo 'Fast-forward'
    if git merge-base --is-ancestor HEAD ${l_remote_branch}; then

        echo 'Fast-forward Merging ...'
        git merge --ff-only --stat ${l_remote_branch}

        l_status=$?
        if [ $l_status -ne 0 ]; then
            printf '%bError (%s) on Merging%b from remote repository "%b%s%b" to remote branch "%b%s%b"...\n' "$g_color_red1" "$l_status" "$g_color_reset" \
                   "$g_color_gray1" "$l_remote" "$g_color_reset" "$g_color_gray1" "$l_remote_branch" "$g_color_reset"
            return 4
        fi

        return 1
    fi

    # Si no es una subrama, intentar de mover la solo la subrama
    echo 'Fast-forward merging not possible. Rebasing...'
    git rebase --rebase-merges --stat ${l_remote_branch}

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

        _update_repository2 $p_is_neovim "$l_folder" "$l_repo_name" "$l_repo_type"
        #_update_repository1 $p_is_neovim "$l_folder" "$l_repo_name" "$l_repo_type"
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


    return 0

}

function _update_vim() {

    #1. Argumentos
    local p_opciones=$1
    local p_is_neovim=1
    if [ "$2" = "0" ]; then
        p_is_neovim=0
    fi

    local l_tag="VIM"
    if [ $p_is_neovim -eq 0  ]; then
        l_tag="NeoVIM"
    fi


    #2. Validar si se debe actualizar VIM/NeoVIM
    local l_flag_setup=1
    local l_option=1
    if [ $p_is_vim -ne 0 ]; then
        l_option=2
    fi

    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_install=0
    fi

    # Si no se debe actualizar
    if [ $l_flag_setup -ne 0 ]; then
        return 1
    fi

    # Se requiere tener Git instalado
    if ! git --version 1> /dev/null 2>&1; then

        #No esta instalado Git, No configurarlo
        printf '%s > Se requiere que Git este instalado para actualizar los plugins de %s.\n' "$l_tag" "$l_tag"
        return 1

    fi

    # Validar si VIM/NeoVIM esta instalado
    local l_status
    local l_version=''

    if [ $p_is_neovim -eq 0 ]; then

        l_version=$(get_neovim_version "")
        l_status=$?    #Retorna 3 si no esta instalado

    else

        l_version=$(get_vim_version)
        l_status=$?    #Retorna 3 si no esta instalado

    fi

    if [ -z "$l_version" ]; then
        printf '%s > %s %bNO esta instalado%b.\n' "$l_tag" "$l_tag" "$g_color_gray1" "$g_color_reset"
        return 1
    fi


    # No permitir, si root esta instalando el profile de otro usuario (debe ejecutar el script con el usuario owner del home)
    if [ $g_runner_is_target_user -ne 0 ]; then

        printf '%s > La actualización de paquetes de %s solo lo puede ejecutar el usuario "%b%s%b" owner\n' \
               "$l_tag" "$l_tag" "$g_color_gray1" "$g_targethome_owner" "$g_color_reset"
        return 1
    fi

    #3. Actualizar los plugins de VIM/NeoVIM

    print_line '-' $g_max_length_line  "$g_color_gray1"
    #print_line '─' $g_max_length_line  "$g_color_blue1"
    printf "%s > Actualizar los plugins de %b%s%b %b(%s)%b\n" "$l_tag" "$g_color_cian1" "$l_tag" "$g_color_reset" "$g_color_gray1" "$l_version" "$g_color_reset"
    print_line '-' $g_max_length_line "$g_color_gray1"
    #print_line '─' $g_max_length_line  "$g_color_blue1"

    _update_vim_package $p_is_neovim

    #4. Mostrar informacion y recomendaciones de la configuracion de VIM/NeoVIM
    show_vim_config_report $p_is_neovim -1
    l_status=$?

    return 0

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

    #2. Inicialización
    g_status_crendential_storage=-1
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi


    #3. Actualizar plugins de VIM
    local l_status

    _update_vim $p_opciones 1
    l_status=$?
    if [ $l_status -eq 111 ]; then
        #No se cumplen las precondiciones obligatorios
        return 111
    elif [ $l_status -eq 120 ]; then
        #No se acepto almacenar las credenciales para usar sudo.
        return 120
    fi

    #4. Actualizar plugins de NeoVIM
    _update_vim $p_opciones 0
    l_status=$?
    if [ $l_status -eq 111 ]; then
        #No se cumplen las precondiciones obligatorios
        return 111
    elif [ $l_status -eq 120 ]; then
        #No se acepto almacenar las credenciales para usar sudo.
        return 120
    fi


    #5. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_status_crendential_storage -eq 0 ]; then
        clean_sudo_credencial
    fi

}


function _show_menu_core() {


    print_text_in_center "Menu de Opciones" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"
    printf " (%ba%b) Actualizar los artefactos existentes: Plugins VIM/NeoVIM\n" "$g_color_green1" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    local l_max_digits=$?

    printf "     (%b%${l_max_digits}d%b) Actualizar los plugin de VIM    existentes e inicializarlos\n" "$g_color_green1" "1" "$g_color_reset"
    printf "     (%b%${l_max_digits}d%b) Actualizar los plugin de NeoVIM existentes e inicializarlos\n" "$g_color_green1" "2" "$g_color_reset"

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

                #1 + 2
                _update_all 3
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
    printf '    %b%s/bash/bin/linuxsetup/05_update_profile.bash\n%b' "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/05_update_profile.bash 0 TARGET_HOME_PATH REPO_NAME\n%b' "$g_color_yellow1" \
           "$g_shell_path" "$g_color_reset"
    printf '  > %bActualizaciones SIN usar un menú de opciones%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/05_update_profile.bash CALLING_TYPE MENU-OPTIONS TARGET_HOME_PATH REPO_NAME\n%b' "$g_color_yellow1" \
           "$g_shell_path" "$g_color_reset"
    printf '    %b%s/bash/bin/linuxsetup/05_update_profile.bash CALLING_TYPE MENU-OPTIONS TARGET_HOME_PATH REPO_NAME SUDO-STORAGE-OPTIONS\n\n%b' \
           "$g_color_yellow1" "$g_shell_path" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bCALLING_TYPE%b Es 0 si se muestra un menu, caso contrario es 1 si es interactivo y 2 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
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
    printf '  > %bSUDO-STORAGE-OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi es root por lo que no se requiere almacenar la credenciales, use 2. Caso contrario, use 0 si se almaceno la credencial y 1 si no se pudo almacenar las credenciales.%b\n\n' \
           "$g_color_gray1" "$g_color_reset"


}




#}}}



#------------------------------------------------------------------------------------------------------------------
#> Logica principal del script {{{
#------------------------------------------------------------------------------------------------------------------

#1. Variables de los argumentos del script

#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución mostrando el menu del opciones (siempre es interactiva).
                        #(1) Ejecución sin el menu de opciones, interactivo    - configurar un conjunto de opciones del menú
                        #(2) Ejecución sin el menu de opciones, no-interactivo - configurar un conjunto de opciones del menú


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


#Obtener los parametros del archivos de configuración
if [ -f "${g_shell_path}/bash/bin/linuxsetup/.config.bash" ]; then

    #Obtener los valores por defecto de las variables
    . ${g_shell_path}/bash/bin/linuxsetup/.config.bash

    #Corregir algunos valaores
    #...
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

#La credencial no se almaceno por un script externo.
g_is_credential_storage_externally=1



#4. LOGICA: Realizar actualizaciones de un repositorio
_g_result=0
_g_status=0

#4.1. Mostrar el menu para escoger lo que se va instalar
if [ $gp_type_calling -eq 0 ]; then

    #Parametros usados por el script:
    # 1> Tipo de llamado: 0 (usar un menu interactivo).
    # 2> Ruta base del home del usuario al cual se configurara su profile y donde esta el repositorio git. Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion ".config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se la ruta sera calculado en base de la ruta del script de instalación y el nombre del repositorio 'g_repo_name'.
    #    - Si no se puede cacluar este valor, se detendra el proceso de instalación/actualización
    # 3> Nombre del repositorio git o la ruta relativa del repositorio git respecto al home al cual se desea configurar el profile del usuario.
    #    Este valor se obtendra segun orden prioridad:
    #    - El valor especificado como argumento del script de instalación (debe ser diferente de vacio o "EMPTY")
    #    - El valor ingresado en el archivo de configuracion ".config.bash" (debe ser diferente de vacio)
    #    - Si ninguno de los anteriores se establece, se usara el valor '.files'.


    #Calcular el valor efectivo de 'g_repo_name'.
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_repo_name="$3"
    fi

    if [ -z "$g_repo_name" ]; then
        g_repo_name='.files'
    fi

    #Obtener los valores efectivo de la variable 'g_targethome_path', 'g_repo_path', 'g_targethome_owner', 'g_targethome_group'
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        #La prioridad siempre es el valor enviado como argumento, luego el valor del archivo de configuración '.config.bash'
        g_targethome_path="$2"
    fi

    get_targethome_info "$g_repo_name" "$g_targethome_path"
    _g_status=$?
    if [ $_g_status -ne 0 ]; then
        exit 111
    fi

    #Validar los requisitos (0 debido a que siempre se ejecuta de modo interactivo)
    #  1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info')
    #  2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  3 > Flag '0' si se requere curl
    #  4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    fulfill_preconditions 0 0 1
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_main
    else
        _g_result=111
    fi

#4.2. No mostrar el menu, la opcion del menu a ejecutar se envia como parametro
else

    #Parametros del script usados hasta el momento:
    # 1> Tipo de ejecución: 1/2 (sin menu interactivo/no-interactivo).
    # 2> Opciones de menu a ejecutar: entero positivo.
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
    # 5> El estado de la credencial almacenada para el sudo.
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

    if [[ "$5" =~ ^[0-2]$ ]]; then
        g_status_crendential_storage=$5

        if [ $g_status_crendential_storage -eq 0 ]; then
            g_is_credential_storage_externally=0
        fi

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

    _g_is_noninteractive=0
    if [ $gp_type_calling -eq 1 ]; then
        _g_is_noninteractive=1
    fi


    #Validar los requisitos
    # 1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info')
    # 2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    # 3 > Flag '0' si se requere curl
    # 4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    fulfill_preconditions 0 0 1
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



#}}}
