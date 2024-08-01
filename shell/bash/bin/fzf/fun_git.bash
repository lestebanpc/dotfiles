#!/bin/bash


#------------------------------------------------------------------------------------------------------------------
#> Logica de inicialización {{{
#------------------------------------------------------------------------------------------------------------------
# Incluye variables globales constantes y variables globales que requieren ser calculados al iniciar el script.
#

#Variable cuyo valor esta CALCULADO por '_get_current_script_info':
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

        #printf 'Error al obtener la ruta absoluta del script "%s" actual.\n' "$l_script_path"
        return 1

    fi

    if [[ "$l_script_path" == */bash/bin/linuxsetup/* ]]; then
        g_shell_path="${l_script_path%/bash/bin/linuxsetup/*}"
    else
        #printf 'El script "%s" actual debe de estar en el folder padre ".../bash/bin/linuxsetup/".\n' "$l_script_path"
        return 1
    fi

    return 0

}

_get_current_script_info
_g_status=$?
if [ $_g_status -ne 0 ]; then
    exit 111
fi


#}}}



#------------------------------------------------------------------------------------------------------------------
#> Funciones usadas durante Instalación/Actualización {{{
#------------------------------------------------------------------------------------------------------------------
# 
# Incluye las variable globales usadas como parametro de entrada y salida de la funcion que no sea resuda por otras
# funciones, cuyo nombre inicia con '_g_'.
#


#Funciones generales
. ~/${g_shell_path}/bash/lib/mod_common.bash


# > Argumentos:
#   1> Tipo de objeto GIT
#      1 - Un commit: hash
#      2 - Branch (Local y Remoto): name
#      3 - Remote (Alias del repositorio remoto): name
#      4 - File: name
#      5 - Tag: name
#   2> Nombre del objeto GIT
_get_remote_url() {

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
    l_remote_url=$(get_http_url_of_gitrepo "$l_remote_url")
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
    local l_path=$(_get_remote_url $p_object_type "$l_object_name")

    echo "$l_path"
    if [ -z "$l_path" ]; then
        return 1
    fi

    #2. Determinar el SO
    get_os_type
    local l_os_type=$?

    if [ $l_os_type -eq 1 ]; then
        explorer.exe "$l_path"
    elif [ $l_os_type -eq 21 ]; then
        open "$l_path"
    else
        xdg-open "$l_path"
    fi
        
}

_branches() {
    git branch "$@" --sort=-committerdate --sort=-HEAD \
        --format=$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=always | column -ts$'\t'
}

_refs() {
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
            _branches
            ;;
        all-branches)
            echo $'CTRL-o (Open in browser)\n'
            _branches -a
            ;;
        refs)
            echo $'CTRL-o (Open in browser), CTRL-s (Git show branch), CTRL-d (Git diff branch), ALT-a (Show all refs)\n'
            _refs 'grep -v ^refs/remotes'
            ;;
        all-refs)
            echo $'CTRL-o (Open in browser), CTRL-s (Git show branch), CTRL-d (Git diff branch)\n'
            _refs 'cat'
            ;;
        nobeep)
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}


#Los parametros debe ser la funcion y los parametros
"$@"

