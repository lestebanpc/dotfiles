#!/bin/bash

#Funciones de utilidad de Inicialización {{{

#Determinar el tipo de SO. Devuelve:
#  00 - 10: Si es Linux
#           00 - Si es Linux genrico
#           01 - Si es WSL2
#  11 - 20: Si es Unix
#  21 - 30: si es MacOS
#  31 - 40: Si es Windows
function m_get_os_type() {
    local l_system=$(uname -s)

    local l_os_type=0
    local l_tmp=""
    case "$l_system" in
        Linux*)
            l_tmp=$(uname -r)
            if [[ "$l_tmp" == *WSL* ]]; then
                l_os_type=1
            else
                l_os_type=0
            fi
            ;;
        Darwin*)  l_os_type=21;;
        CYGWIN*)  l_os_type=31;;
        MINGW*)   l_os_type=32;;
        *)        l_os_type=99;;
    esac

    return $l_os_type

}


#Determinar el tipo de distribucion Linux. Devuelve:
#  1) Retorna en un entero el tipo de distribucion Linux
#     00 : Distribución de Linux desconocido
#     01 : Ubuntu
#     02 : Fedora
#  2) Muestra en el flujo de salida la version de la distribucion Linux
function m_get_linux_subtype() {

    local l_info_distro=""
    if ! l_info_distro=$(cat /etc/*-release 2> /dev/null); then
        return 0
    fi

    # Ubuntu:
    #   NAME="Ubuntu"
    #   VERSION="22.04.1 LTS (Jammy Jellyfish)"
    #
    # Fedora:
    #   NAME="Fedora Linux"
    #   VERSION="36 (Workstation Edition)"
    #
    local l_tag_distro_type="NAME"
    local l_distro_type=$(echo "$l_info_distro" | grep -e "^${l_tag_distro_type}=" | sed 's/'"$l_tag_distro_type"'="\(.*\)"/\1/')
    if [ -z "$l_distro_type" ]; then
        return 0
    fi

    local l_tag_distro_version="VERSION"
    local l_distro_version=$(echo "$l_info_distro" | grep -e "^${l_tag_distro_version}=" | sed 's/'"$l_tag_distro_version"'="\(.*\)"/\1/')
    echo $l_distro_version

    local l_type=0
    case "$l_distro_type" in
        Ubuntu*)
            l_type=1
            ;;
        Fedora*)
            l_type=2
            ;;
        *)
            l_type=0
            ;;
    esac

    return $l_type

}

#}}}

#Inicialización Global {{{

#Variable global pero solo se usar localmente en las funciones
t_tmp=""

#Variable global ruta de los binarios en Windows segun WSL2
declare -r g_path_win_commands='/mnt/d/Tools/Cmds/Common'

#Determinar la clase del SO
m_get_os_type
declare -r g_os_type=$?

#Deteriminar el tipo de distribución Linux
if [ $g_os_type -le 10 ]; then
    t_tmp=$(m_get_linux_subtype)
    declare -r g_os_subtype=$?
    declare -r g_os_subtype_version="$t_tmp"
fi


#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
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


# Argumentos:
# 1) Repositorios opcionales que se se instalaran (flag en binario. entero que es suma de 2^n).
#    Si es 0, no se instala ningun repositorio opcionales.
# 2) - 
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
    
    echo "OS Type              : ${g_os_type}"
    echo "OS Subtype - ID      : ${g_os_subtype}"
    echo "OS Subtype - Versión : ${g_os_subtype_version}"

    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        echo "ERROR (21): El sistema operativo debe ser Linux"
        return 21;
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
    
    #Segun el tipo de distribución de Linux
    case "$g_os_subtype" in
        1)
            #Distribución: Ubuntu
            if [ $g_is_root -eq 0 ]; then
                dnf upgrade
            else
                sudo dnf upgrade
            fi
            ;;
        2)
            #Distribución: Fedora
            if [ $g_is_root -eq 0 ]; then
                apt-get update
                apt-get upgrade
            else
                sudo apt-get update
                sudo apt-get upgrade
            fi
            ;;
        0)
            echo "ERROR (22): No se identificado el tipo de Distribución Linux"
            return 22;
            ;;
    esac

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



