#!/bin/bash


#Definiciones globales, Inicialización {{{

#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
fi

#Determinar el tipo de SO. Devuelve:
#  00 - 10: Si es Linux
#           00 - Si es Linux genericos
#           01 - Si es WSL2
#  11 - 20: Si es Unix
#  21 - 30: si es MacOS
#  31 - 40: Si es Windows
function m_get_os() {
    local l_system=$(uname -s)

    local l_os=0
    local l_tmp=""
    case "$l_system" in
        Linux*)
            l_tmp=$(uname -r)
            if [[ "$l_tmp" == *WSL* ]]; then
                l_os=1
            else
                l_os=0
            fi

            ;;
        Darwin*)  l_os=21;;
        CYGWIN*)  l_os=31;;
        MINGW*)   l_os=32;;
        *)        l_os=99;;
    esac

    return $l_os

}
m_get_os
declare -r g_os=$?

l_os_type=0
l_tmp=$(cat /etc/lsb-release 2> /dev/null | grep 'DISTRIB_DESCRIPTION' | sed 's/DISTRIB_DESCRIPTION="\(.*\)"/\1/')
if [[ "$l_tmp" == *Ubuntu* ]]; then
    l_os_type=1
fi

#}}}

function m_update_repository() {

    #1. Argumentos
    local l_path="$1"

    #Validar si existe directorio
    if [ ! -d $l_path ]; then
        echo "Folder \"${l_path}\" not exists"
        return 9
    else
        echo "-------------------------------------------------------------------------------------------------"
        echo "- Repository: \"${l_path}\""
        echo "-------------------------------------------------------------------------------------------------"
    fi

    cd $l_path

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
            return 0
        else
            echo 'Fast-forward not possible. Rebasing...'
            git rebase --preserve-merges --stat ${l_remote_branch}
            return 2
        fi
    fi
}

function m_update_vim_package() {

    #
    local l_base_path=~/.vim/pack
    
    #Validar si existe directorio
    if [ ! -d $l_base_path ]; then
        echo "Folder \"${l_base_path}\" not exists"
        return 9
    fi

    cd $l_base_path
    local l_folder
    for l_folder  in $(find . -type d -name .git); do
        l_folder="${l_folder%/.git}"
        l_folder="${l_folder#./}"
        l_folder="${l_base_path}/${l_folder}"
        m_update_repository "$l_folder"
    done
    return 0

}


# Argunentos:
# - Repositorios opcionales que se se instalaran (flag en binario. entero que es suma de 2^n).
#   Si es 0, no se instala ningun repositorio opcionales.
# - 
function m_update_all() {

    #1. Argumentos
    local p_opcion=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opcion=$1
    fi

    #2. Validar si fue descarga el repositorio git correspondiente
    if [ ! -d ~/.files/.git ]; then
        echo "Debe obtener los archivos basicos:"
        echo "   1> git clone https://github.com/lestebanpc/dotfiles.git ~/.files"
        echo "   2> chmod u+x ~/.files/setup/01_setup_init.bash"
        echo "   3> . ~/.files/setup/01_setup_init.bash"
        echo "   4> . ~/.files/setup/02_setup_commands.bash (instala y actuliza comandos)"
        echo "   5> . ~/.files/setup/03_setup_profile.bash"
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
    fi
    
    #4 Instalacion
    echo "-------------------------------------------------------------------------------------------------"
    echo "- Actualizar los paquetes del Repositorio del Linux"
    echo "-------------------------------------------------------------------------------------------------"

    #De Ubuntu
    if [ $l_os_type -eq 1 ]; then
        if [ $g_is_root -eq 0 ]; then
            apt-get update
            apt-get upgrade
        else
            sudo apt-get update
            sudo apt-get upgrade
        fi
    else
        if [ $g_is_root -eq 0 ]; then
            dnf upgrade
        else
            sudo dnf upgrade
        fi
    fi

    #5 Actualizar los comandos basicos
    ~/.files/setup/02_setup_commands.bash $p_opcion 1

    #6 Actualizar paquetes de VIM
    m_update_vim_package


    #5. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 ]; then
        echo $'\n'"Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}

m_update_all $1



