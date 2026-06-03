#!/bin/bash

# Obtenido y modificado de https://github.com/junegunn/fzf-git.sh

# Constantes
g_fzf_height='60%'
g_fzf_popup_height='80%'
g_fzf_popup_width='99%'

# Colores principales usados
g_color_reset="\x1b[0m"
g_color_green1="\x1b[32m"
g_color_gray1="\x1b[90m"
g_color_cian1="\x1b[36m"
g_color_yellow1="\x1b[33m"
g_color_red1="\x1b[31m"
g_color_blue1="\x1b[34m"

# Obtener la del script
g_script_path="${BASH_SOURCE[0]}"
#echo "$g_script_path"

g_cmd_name='gitu'
#g_cmd_name='git_utils'

declare -a ga_exported_functions=(
        "list_objects"
        "git_open_url"
    )

# Diccionario de sbucomandos. La key es 'id del subcomando' y value es 'la descripcion del subcomando'.
# > Segun el ID de subcomando, se debe tener 2 funciones bash cuyo nombre tiene dicho ID
#   > Funcion de ayuda del comando tiene el nombre 'm_usage_CMD-ID'.
#   > Funcion de controlador del comando tiene el nombre 'controller_CMD-ID'.
declare -A gA_subcmd_ids=(
        ['file']='Archivos gestionados por GIT'
        ['commit']='Commit o nodo de un arbol GIT'
        ['tag']='Tag de un determino commit'
        ['branch']='Rama local o remota de un repositorio remoto'
        ['remote']='Alias del repositorio remotos vinculado al repositorio local'
        ['eachref']='Usado para "git for-each-ref"'
        ['stash']='Stash de ...'
    )


# Diccionario de sbucomandos. La key es 'alias' y value es 'ID del subcomando'.
declare -A gA_subcmd_alias=(
        ['hash']='commit'
    )


_g_fzf_data1=''




# -------------------------------------------------------------------------------------
# General functions
# -------------------------------------------------------------------------------------

#Determinar el tipo de SO compatible con interprete shell POSIX.
#Devuelve:
#  00 > Si es Linux no-WSL
#  01 > Si es Linux WSL2 (Kernel de Linux nativo sobre Windows)
#  02 > Si es Unix
#  03 > Si es MacOS
#  04 > Emulador Bash CYGWIN para Windows
#  05 > Emulador Bash MINGW  para Windows
#  06 > Emulador Bash Termux para Linux Android
#  09 > No identificado
function m_get_os_type() {
    local l_system=$(uname -s)

    local l_os_type=0
    local l_tmp=""
    case "$l_system" in
        Linux*)
            l_tmp=$(uname -r)
            if [[ "$l_tmp" == *WSL* ]] && [ -f "/etc/wsl.conf" ]; then
                l_os_type=1
            else
                l_os_type=0
            fi
            ;;
        Darwin*)  l_os_type=3;;
        CYGWIN*)  l_os_type=4;;
        MINGW*)   l_os_type=5;;
        *)
            #Si se ejecuta en Termux
            if echo $PREFIX | grep -o "com.termux" 2> /dev/null; then
                l_os_type=6
            else
                l_os_type=9
            fi
            ;;
    esac

    return $l_os_type

}


# > Argumentos:
#   1> URL del del repositorio remoto
# > Valor de retorno
#    0 - Repositorio GitHub
#    1 - Repositorio GitLab
#   99 - Repositorio desconocido
m_get_http_url_of_gitrepo() {

    #Ejemplos de input:
    #Caso Github:
    # > HTTPS         : https://github.com/dense-analysis/ale.git
    # > SSH           : git@githuh.com:lestebanpc/dotfiles.git
    # > SSH con alias : ghub-writer:lestebanpc/dotfiles.git
    #Caso GitLab:
    # > HTTPS         : https://gitlab.com/uc-cau/orbital/usaproject/ctacorrientes.git
    # > SSH           : git@gitlab.com:uc-cau/orbital/usaproject/ctacorrientes.git
    # > SSH con alias : glab-lestebanpc:uc-cau/orbital/usaproject/ctacorrientes.git

    #Parametros
    local l_remote_url=$1


    #Obtener el host de la URL
    local l_status=0
    local l_tmp=${l_remote_url%.git}
    local l_host
    local l_path
    local l_host_alias

    #Si usa HTTPS
    if [[ $l_remote_url =~ ^http ]]; then

        l_tmp=${l_tmp#https://}
        l_host=${l_tmp%%/*}
        l_path=${l_tmp#*/}

    #Si usa SSH
    else

        #Si no usa SSH alias
        if [[ $l_remote_url =~ ^git@ ]]; then

            l_tmp=${l_tmp#git@}
            l_host=${l_tmp%:*}
            l_path=${l_tmp#*:}

        #Si usa un SSH alias
        else

            l_host_alias=${l_tmp%:*}
            l_path=${l_tmp#*:}

            l_host=$(ssh -G $l_host_alias | awk '$1 == "hostname" { print $2 }' 2> /dev/null)
            if [ $? -ne 0 ]; then
                l_status=99
                l_host="$l_host_alias"
            fi

        fi
    fi


    #Determinar el tipo de repositorio segun el host
    case "$l_host" in

        github*)
            l_status=0
            ;;

        gitlab*)
            l_status=1
            ;;

    esac

    #Mostar la URL HTTP
    echo "https://${l_host}/${l_path}"
    return $l_status
}



# Redefine this function to change the options
m_fzf_cmd() {


    # Si esta dentro de tmux >= 3.2, se usara 'tmux display-popup':
    # > Si se usa tmux >= 3.3 (se tiene soporte a bordes), se usara para ello 'fzf --tmux'
    # > Si se usa tmux >= 3.2 pero < 3,3, se usara el script 'fzf-tmux'.
    local l_fzf_cmd='fzf'
    local l_fzf_size_args="--height ${g_fzf_height}"
    if [ ! -z "$TMUX" ] && [ ! -z "$TMUX_VERSION" ]; then
        if [ "$TMUX_VERSION" -ge 330 ]; then
            l_fzf_size_args="--tmux center,${g_fzf_popup_width},${g_fzf_popup_height}"
        elif [ "$TMUX_VERSION" -ge 320 ]; then
            l_fzf_cmd='fzf-tmux'
            l_fzf_size_args="-p ${g_fzf_popup_width},${g_fzf_popup_height} --"
        fi
    fi

    $l_fzf_cmd $l_fzf_size_args \
        --layout=reverse --multi --min-height=20 --border \
        --color='header:italic:underline' \
        --preview-window='right,50%,border-left' \
        --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"

}



# -------------------------------------------------------------------------------------
# Exported functions
# -------------------------------------------------------------------------------------


# > Argumentos:
#   1> Tipo de objeto GIT
#      1 - Un commit: hash
#      2 - Branch (Local y Remoto): name
#      3 - Remote (Alias del repositorio remoto): name
#      4 - File: name
#      5 - Tag: name
#   2> Nombre del objeto GIT
m_get_remote_url() {

    #Argumentos
    local p_object_type="$1"
    local p_object_name="$2"

    #1. Obtener el nombre de la rama
    local l_current_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    if [ $l_current_branch = "HEAD" ]; then
        l_current_branch=$(git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)
    fi

    #2. Obtener el alias del repositorio remoto
    local l_remote

    case "$p_object_type" in
        1)
            #Usando el codigo hash ingresado
            l_remote=$(git config branch."${l_current_branch}".remote || echo 'origin')
            ;;
        2)
            #usando el nombre de la rama ingresado
            l_remote=$(git config branch."${p_object_name}".remote || echo 'origin')
            ;;
        3)
            #Usando el alias de repositorio remoto
            l_remote=$p_object_name
            ;;
        4)
            l_remote=$(git config branch."${l_current_branch}".remote || echo 'origin')
            ;;
        5)
            l_remote=$(git config branch."${l_current_branch}".remote || echo 'origin')
            ;;
        *)
            return 1
            ;;
    esac

    #3. Obtener la URL asociado al alias del repositorio remoto y el tipo de repositorio
    local l_remote_url
    l_remote_url=$(git remote get-url "$l_remote" 2> /dev/null)
    if [ $? -ne 0 ]; then
        return 2

    fi

    #Obtener URL http del repositorio remoto
    l_remote_url=$(m_get_http_url_of_gitrepo "$l_remote_url")
    local l_type_git=$?
    #if  [ $l_type_git -eq 99 ]; then
    #    return 3
    #fi

    #4. Obtener la ruta relativa  del objeto
    local l_path=""
    local l_tmp

    case "$p_object_type" in
        1)
            #Usando el codigo hash ingresado
            l_tmp="$p_object_name"

            #Si es GitLab
            if [ $l_type_git -eq 1 ]; then
                l_path="/-/commit/$l_tmp"

            #Si es GitHub
            else
                l_path="/commit/$l_tmp"
            fi
            ;;

        2)
            #usando el nombre de la rama ingresado
            l_tmp="${p_object_name#$l_remote/}"

            #Si es GitLab
            if [ $l_type_git -eq 1 ]; then
                l_path="/-/tree/$l_tmp"

            #Si es GitHub
            else
                l_path="/tree/$l_tmp"
            fi
            ;;

        3)
            #Usando el alias de repositorio remoto
            l_tmp="$l_current_branch"

            #Si es GitLab
            if [ $l_type_git -eq 1 ]; then
                l_path="/-/tree/$l_tmp"

            #Si es GitHub
            else
                l_path="/tree/$l_tmp"
            fi
            ;;

        4)
            l_tmp="$l_current_branch/$(git rev-parse --show-prefix)$p_object_name"

            #Si es GitLab
            if [ $l_type_git -eq 1 ]; then
                l_path="/-/blob/$l_tmp"

            #Si es GitHub
            else
                l_path="/blob/$l_tmp"
            fi
            ;;

        5)
            l_tmp="$p_object_name"

            #Si es GitLab
            if [ $l_type_git -eq 1 ]; then
                l_path="/-/releases/tag/$l_tmp"

            #Si es GitHub
            else
                l_path="/releases/tag/$l_tmp"
            fi
            ;;

        *)
            return 3
            ;;
    esac


    #5. Mostrar la ruta del objteto
    echo "${l_remote_url}${l_path}"
    return 0

}


git_open_url() {

    #1. Argumentos
    local p_object_type=$1
    local p_object_info="$2"

    #2. Obtener el nombre del objeto
    local l_object_name="$p_object_info"

    if [ $p_object_type -eq 1 ]; then
        #Si el objeto es un commit, obtener el hash del valor
        l_object_name=$(echo "$p_object_info" | grep -o "[a-f0-9]\{7,\}")
    elif [ $p_object_type -eq 2 ]; then
        #Si el objeto es un rama obtener la ...
        l_object_name=$(echo "$p_object_info" | sed 's/^[* ]*//' | cut -d' ' -f1)
    fi

    #3. Obtener la ruta del objeto
    local l_path=$(m_get_remote_url $p_object_type "$l_object_name")

    echo "$l_path"
    if [ -z "$l_path" ]; then
        return 1
    fi

    #2. Determinar el SO
    m_get_os_type
    local l_os_type=$?

    if [ $l_os_type -eq 1 ]; then
        explorer.exe "$l_path"
    elif [ $l_os_type -eq 21 ]; then
        open "$l_path"
    else
        xdg-open "$l_path"
    fi

}

m_branches_data() {
    git branch "$@" --sort=-committerdate --sort=-HEAD \
        --format=$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=always | column -ts$'\t'
}

m_refs_data() {
    git for-each-ref --sort=-creatordate --sort=-HEAD --color=always \
        --format=$'%(refname) %(color:green)(%(creatordate:relative))\t%(color:blue)%(subject)%(color:reset)' |
        eval "$1" |
        sed 's#^refs/remotes/#\x1b[95mremote-branch\t\x1b[33m#; s#^refs/heads/#\x1b[92mbranch\t\x1b[33m#; s#^refs/tags/#\x1b[96mtag\t\x1b[33m#; s#refs/stash#\x1b[91mstash\t\x1b[33mrefs/stash#' |
        column -ts$'\t'
}


list_objects() {

    case "$1" in
        branches)
            echo $'CTRL-o (Open in browser), ALT-a (Show all branches)\n'
            m_branches_data
            ;;
        all-branches)
            echo $'CTRL-o (Open in browser)\n'
            m_branches_data -a
            ;;
        refs)
            echo $'CTRL-o (Open in browser), CTRL-s (Git show branch), CTRL-d (Git diff branch), ALT-a (Show all refs)\n'
            m_refs_data 'grep -v ^refs/remotes'
            ;;
        all-refs)
            echo $'CTRL-o (Open in browser), CTRL-s (Git show branch), CTRL-d (Git diff branch)\n'
            m_refs_data 'cat'
            ;;
        nobeep)
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}



# -------------------------------------------------------------------------------------
# Subcomand Controller> File
# -------------------------------------------------------------------------------------

#for Files
m_usage_file() {

    local l_scmd_id='file'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [args]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}

m_files() {

    (git -c color.status=always status --short
    git ls-files | grep -vxFf <(git status -s | grep '^[^?]' | cut -c4-; echo :) | sed 's/^/   /') |
    m_fzf_cmd -m --ansi --nth 2..,.. \
        --prompt '📄 Files> ' \
        --header $'CTRL-o (open in browser) ╱ ALT-e (open in editor)\n\n' \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-o:execute-silent:bash \"${g_script_path}\" -i git_open_url 4 {-1}" \
        --bind "alt-e:execute:${EDITOR:-vim} {-1} > /dev/tty" \
        --preview-window "right,60%" \
        --preview "git diff --color=always -- {-1} | delta; bat --color=always --style=numbers,header-filename {-1}" "$@" |
    cut -c4- | sed 's/.* -> //'
}


controller_file() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_file
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_file
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_files "$@"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> Branch
# -------------------------------------------------------------------------------------

#for Branches (Local y Remoto)

m_usage_branch() {

    local l_scmd_id='branch'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [args]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}

m_branches() {

    list_objects branches |
    m_fzf_cmd --ansi \
        --prompt '🌲 Branches> ' \
        --header-lines 2 \
        --tiebreak begin \
        --preview-window down,border-top,40% \
        --color hl:underline,hl+:underline \
        --no-hscroll \
        --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
        --bind "ctrl-o:execute-silent:bash \"${g_script_path}\" -i git_open_url 2 {}" \
        --bind "alt-a:change-prompt(🌳 All branches> )+reload:bash \"${g_script_path}\" -i list_objects all-branches" \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' "$@" |
    sed 's/^..//' | cut -d' ' -f1
}


controller_branch() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_branch
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_branch
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_branches "$@"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> Tag
# -------------------------------------------------------------------------------------

#for Tags

m_usage_tag() {

    local l_scmd_id='tag'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [args]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}

m_tags() {

    git tag --sort -version:refname |
    m_fzf_cmd --preview-window right,70% \
        --prompt '📛 Tags> ' \
        --header $'CTRL-o (Open in browser)\n\n' \
        --bind "ctrl-o:execute-silent:bash \"${g_script_path}\" -i git_open_url 5 {}" \
        --preview-window "right,60%" \
        --preview 'git show --color=always {} | delta' "$@"
}


controller_tag() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_tag
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_tag
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_tags "$@"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> Commit
# -------------------------------------------------------------------------------------

#for commit Hashes

m_usage_commit() {

    local l_scmd_id='commit'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [FILE]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}

m_commits() {

    local p_file="$1"

    local l_status=1
    local l_result=''
    local l_prompt='🍡 Hashes> '
    _g_fzf_data1=''
    if [ -z "$p_file" ]; then
        l_result=$(git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always)
        l_status=$?
    else
        printf -v l_prompt '🍡 Hashes of %s> ' "$p_file"
        printf -v _g_fzf_data1 " -- '%s'" "$p_file"
        l_result=$(git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always -- "$p_file")
        l_status=$?
    fi


    #echo "data1: ${_g_fzf_data1}"


    if [ $l_status -ne 0 ]; then
        printf 'Ocurrio un error en obtener los commits: %b\n' "$l_result"
        return 1
    fi


    echo "$l_result" | m_fzf_cmd --ansi --no-sort --bind 'ctrl-s:toggle-sort' \
        --prompt "$l_prompt" \
        --header $'CTRL-o (Open in browser), CTRL-d (View Diff), CTRL-s (Toggle sort)\n\n' \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-o:execute-silent:bash \"${g_script_path}\" -i git_open_url 1 {}" \
        --bind "ctrl-d:execute:grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs -I%% git diff --color=always %% ${_g_fzf_data1} | delta > /dev/tty" \
        --color hl:underline,hl+:underline \
        --preview-window "right,60%" \
        --preview "grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs -I%% git show --color=always %% ${_g_fzf_data1} | delta" |
    awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'

    return 0
}


controller_commit() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_commit
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_commit
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_commits "$@"
    return 0

}



# -------------------------------------------------------------------------------------
# Subcomand Controller> Remote
# -------------------------------------------------------------------------------------

#for Remotes (Alias de los repositorios remotos)

m_usage_remote() {

    local l_scmd_id='remote'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [args]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}

m_remotes() {

    git remote -v | awk '{print $1 "\t" $2}' | uniq |
    m_fzf_cmd --tac \
        --prompt '📡 Remotes> ' \
        --header $'CTRL-o (Open in browser)\n\n' \
        --bind "shift-up:preview-page-up,shift-down:preview-page-down" \
        --bind "ctrl-o:execute-silent:bash \"${g_script_path}\" -i git_open_url 3 {1}" \
        --preview-window right,70% \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {1}/"$(git rev-parse --abbrev-ref HEAD)"' "$@" |
    cut -d$'\t' -f1

}


controller_remote() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_remote
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_remote
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_remotes "$@"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> Stash
# -------------------------------------------------------------------------------------

#for Stashes

m_usage_stash() {

    local l_scmd_id='stash'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [args]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}

m_stashes() {

    git stash list | m_fzf_cmd \
        --prompt '🥡 Stashes> ' \
        --header $'CTRL-x (Drop stash)\n\n' \
        --bind 'ctrl-x:execute-silent(git stash drop {1})+reload(git stash list)' \
        -d: --preview 'git show --color=always {1} | delta' "$@" |
    cut -d: -f1
}


controller_stash() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_stash
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_stash
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_stashes "$@"
    return 0

}




# -------------------------------------------------------------------------------------
# Subcomand Controller> Each Ref
# -------------------------------------------------------------------------------------

#for Each ref (git for-each-ref)

m_usage_aechref() {

    local l_scmd_id='eachref'
    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
    printf '%b%s%b\n\n' "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    printf 'Usage:\n'
    printf '    %b%s %s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"
    printf '    %b%s %s%b [args]%b\n\n' "$g_color_yellow1" "$g_cmd_name" "$l_scmd_id" "$g_color_gray1" "$g_color_reset"

    printf 'Las opciones usados son:\n'
    printf '  > %b-h|--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}

m_eachref() {

    list_objects refs | m_fzf_cmd --ansi \
        --nth 2,2.. \
        --tiebreak begin \
        --prompt '☘️  Each ref> ' \
        --header-lines 2 \
        --preview-window down,border-top,40% \
        --color hl:underline,hl+:underline \
        --no-hscroll \
        --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
        --bind "ctrl-o:execute-silent:bash \"${g_script_path}\" -i git_open_url 2 {2}" \
        --bind "ctrl-s:execute:git show {2} | delta > /dev/tty" \
        --bind "ctrl-d:execute:git diff {2} | delta > /dev/tty" \
        --bind "alt-a:change-prompt(🍀 Every ref> )+reload:bash \"${g_script_path}\" -i list_objects all-refs" \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {2}' "$@" |
    awk '{print $2}'
    #--bind "alt-e:execute:${EDITOR:-vim} <(git show {2}) > /dev/tty" \
}


controller_eachref() {

    #1. Validaciones previas

    #2. Procesar las opciones (siempre deben estar anstes de los argumentos)
    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help)
                m_usage_aechref
                return 0
                ;;

            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_aechref
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #4. Leer los argumentos restantes

    #5. Ejecutando el comando
    m_eachref "$@"
    return 0

}



# -------------------------------------------------------------------------------------
# Main code > Utilities
# -------------------------------------------------------------------------------------

m_get_exported_functions() {

    # Recorrer la lista de parametros identificados ....
    local l_infos=""
    local l_id

    for l_id in "${ga_exported_functions[@]}"; do

        if [ -z "$l_infos" ]; then
            printf -v l_infos "'%b%s%b'" "$g_color_yellow1" "$l_id" "$g_color_reset"
        else
            printf -v l_infos "%b, '%b%s%b'" "$l_infos" "$g_color_yellow1" "$l_id" "$g_color_reset"
        fi

    done

    echo "$l_infos"

}

m_is_function_exported() {

    local p_func_name="$1"

    if [ -z "$p_func_name" ]; then
        return 1
    fi

    local l_found=1
    local l_item

    for l_item in "${ga_exported_functions[@]}"; do

        if [[ "$l_item" == "$p_func_name" ]]; then
            l_found=0
            break
        fi

    done

    return $l_found

}


m_get_subcmd_infos() {

    local l_scmd_id
    local l_scmd_description
    local l_alias
    local l_alias_list
    local l_id

    for l_scmd_id in "${!gA_subcmd_ids[@]}"; do

        printf "%b  > %b%s%b\n" "$g_color_gray1" "$g_color_yellow1" "$l_scmd_id" "$g_color_reset"

        # Obtener los alias del comando
        l_alias_list=''

        for l_alias in "${!gA_subcmd_alias[@]}"; do

            l_id="${gA_subcmd_alias[${l_alias}]}"

            if [ "$l_id" = "$l_scmd_id" ]; then
                if [ -z "$l_alias_list" ]; then
                    printf -v l_alias_list "'%b%s%b'" "$g_color_yellow1" "$l_alias" "$g_color_reset"
                else
                    printf -v l_alias_list "%b, '%b%s%b'" "$l_alias_list" "$g_color_yellow1" "$l_alias" "$g_color_reset"
                fi
            fi

        done

        # Mostrar el alias
        if [ ! -z "$l_alias_list" ]; then
            printf '    Alias: %b\n' "$l_alias_list"
        fi

        # Mostrar la descripcion
        l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]}"
        printf "    %b%s%b\n" "$g_color_gray1" "$l_scmd_description" "$g_color_reset"

    done


}


m_usage_global() {

    local l_infos=""
    l_infos=$(m_get_exported_functions)

    printf 'Usage:\n'
    printf '  %b%s%b -h|--help%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    printf '  %b%s%b SUBCOMMAND%b [options] [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    if [ ! -z "$l_infos" ]; then
        printf '    %b%s%b -i FUNC_NAME [args]%b\n' "$g_color_yellow1" "$g_cmd_name" "$g_color_gray1" "$g_color_reset"
    fi

    printf '\nLas opciones globales usados son:\n'
    printf '%b  > %b-h%b o %b--help%b permite mostrar la ayuda del comando.%b\n' "$g_color_gray1" "$g_color_green1" "$g_color_gray1" \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

    if [ ! -z "$l_infos" ]; then
        printf '%b  > %b-i FUNC_NAME%b Especifica el nombre de la funcion interna del script a ejecutar (uso interno y/o debugging).%b\n' \
               "$g_color_gray1" "$g_color_green1" "$g_color_gray1" "$g_color_reset"
        printf '    %bFUNC_NAME puede ser:%b %b\n' "$g_color_gray1" "$g_color_reset" "$l_infos"
    fi

    printf '\nEl argumento principal es el nombre del subcomando %bSUBCOMMAND%b. Los cuales puede ser:\n' "$g_color_green1" "$g_color_reset"
    m_get_subcmd_infos
    printf '\n'

}


m_check_repo_git() {
    git rev-parse HEAD > /dev/null 2>&1 && return
    [[ -n $TMUX ]] && tmux display-message "Not in a git repository"
    return 1
}


# -------------------------------------------------------------------------------------
# Main code > Main Function
# -------------------------------------------------------------------------------------

# Funcion principal de entrada
# > Valores de retorno:
#   (0) OK
#   (1) No se tienen los comandos requeridos para ejecutar el script.
#   (3) Opciones ingresados son invalidos.
#   (4) No se han ingresado argumentos.
#
main() {

    #1. Validaciones previas

    # Validar comando requeridos
    if ! command -v fzf >/dev/null 2>&1; then
        printf '[%bERROR%b] Se debe tener el comando "%b%s%b" instalado.\n' "$g_color_red1" "$g_color_reset" "$g_color_gray1" "jq" "$g_color_reset"
        return 1
    fi

    if ! command -v git 2> /dev/null 1>&2; then
       printf 'El comando "%b%s%b" no esta instalado.\n' "$g_color_gray1" "git" "$g_color_reset"
       return 2
    fi


    #2. Procesar las opciones globales
    local l_func_name=""

    while [ $# -gt 0 ]; do

        case "$1" in

            -h|--help|help)
                m_usage_global
                return 0
                ;;

            -i)
                m_is_function_exported "$2"
                local l_found=$?
                if [ "$l_found" -ne 0 ]; then
                    printf '[%bERROR%b] Valor de la opción "%b%s%b" no es function exportada valida: %b%s%b\n\n' "$g_color_red1" "$g_color_reset" \
                           "$g_color_gray1" "-i" "$g_color_reset" "$g_color_gray1" "$2" "$g_color_reset"
                    m_usage_global
                    return 3
                fi

                l_func_name="$2"
                shift 2
                ;;


            -*)
                printf '[%bERROR%b] Opción "%b%s%b" no es es valido.\n\n' "$g_color_red1" "$g_color_reset" \
                       "$g_color_gray1" "$1" "$g_color_reset"
                m_usage_global
                return 3
                ;;

            *)
                #Si son argumentos, salir y continuar
                break
                ;;

        esac

    done


    #3. Si es una funcion exportada, invocarlo
    if [ ! -z "$l_func_name" ]; then
        "$l_func_name" "$@"
        return 0
    fi


    #4. Procesar el 1er argumentos (nombre del subcomando o alias)
    if [ -z "$1" ]; then
        printf '[%bERROR%b] Se debe especificarse un subcomando.\n\n' "$g_color_red1" "$g_color_reset"
        m_usage_global
        return 3
    fi

    # Identificar si es un alias
    local l_scmd_id="${gA_subcmd_alias[${1}]:-}"

    # Validar si es un ID de subcomando valido
    if [ -z "$l_scmd_id" ]; then
        l_scmd_id="$1"
    fi

    local l_scmd_description="${gA_subcmd_ids[${l_scmd_id}]:-}"

    if [ -z "$l_scmd_description" ]; then
        printf '[%bERROR%b] El subcomando ingresado "%b%s%b" no es valida\n\n' "$g_color_red1" "$g_color_reset" \
               "$g_color_gray1" "$l_scmd_id" "$g_color_reset"
        m_usage_global
        return 3
    fi

    shift

    #5. Validado si esta en un repositorio GIT
    local l_status=0
    m_check_repo_git
    l_status=$?

    if [ $l_status -ne 0 ]; then
        printf '[%bERROR%b] El directorio actual no es un repositorio GIT valido.\n\n' "$g_color_red1" "$g_color_reset"
        m_usage_global
        return 3
    fi


    #6. Ejecutando el controlador principal del subcomando

    "controller_${l_scmd_id}" "$@"
    return 0

}



# Ejecutar la funcion principal
main "$@"
_g_result=$?
exit $_g_result
