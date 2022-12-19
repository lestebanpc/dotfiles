#!/bin/bash

#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/setup/basic_functions.bash

#Variable global pero solo se usar localmente en las funciones
t_tmp=""

#Determinar la clase del SO
m_get_os_type
declare -r g_os_type=$?

#Deteriminar el tipo de distribución Linux
if [ $g_os_type -le 10 ]; then
    t_tmp=$(m_get_linux_type_id)
    declare -r g_os_subtype_id=$?
    declare -r g_os_subtype_name="$t_tmp"
    t_tmp=$(m_get_linux_type_version)
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
    

    #3. Solicitar credenciales de administrador y almacenarlas temporalmente
    if [ $g_is_root -ne 0 ]; then

        #echo "Se requiere alamcenar temporalmente su password"
        sudo -v

        if [ $? -ne 0 ]; then
            echo "ERROR(20): Se requiere \"sudo -v\" almacene temporalmente su credenciales de root"
            return 20;
        fi
    fi
    
    #4. Instalacion
    echo "-------------------------------------------------------------------------------------------------"
    echo "- Actualizar los paquetes del Repositorio del Linux"
    echo "-------------------------------------------------------------------------------------------------"
    
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

    #5 Actualizar los comandos basicos
    ~/.files/setup/02_setup_commands.bash $p_opcion 1

    #6 Actualizar paquetes de VIM
    m_update_vim_package


    #7. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 ]; then
        echo $'\n'"Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}


function m_show_menu_core() {

    echo "                                  Escoger la opción"
    echo "-------------------------------------------------------------------------------------------------"
    echo " (q) Salir del menu"
    echo " (0) Instalar solo los repositorios obligatorios"
    echo " ( ) Instalar los repositorios obligatorios y uno o mas repositorios opcionales."
    echo "     Ingrese la suma de las siguientes opciones asociados a los repositorios opcionales:"
    echo "       (1) Repositorio k0s"
    echo "-------------------------------------------------------------------------------------------------"
    printf "Opción : "

}

function m_main() {

    echo "OS Type            : (${g_os_type})"
    echo "OS Subtype (Distro): (${g_os_subtype_id}) ${g_os_subtype_name} - ${g_os_subtype_version}"$'\n'
    
    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        echo "ERROR (21): El sistema operativo debe ser Linux"
        return 21;
    fi

    
    echo "#################################################################################################"

    local l_flag_continue=0
    local l_opcion=""
    while [ $l_flag_continue -eq 0 ]; do
        m_show_menu_core
        read l_opcion

        case "$l_opcion" in
            0)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                m_update_all
                ;;

            q)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                ;;

            [1-9]*)
                if [[ "$l_opcion" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    echo "#################################################################################################"$'\n'
                    m_update_all $l_opcion
                else
                    l_flag_continue=0
                    echo "Opción incorrecta"
                    echo "-------------------------------------------------------------------------------------------------"
                fi
                ;;

            *)
                l_flag_continue=0
                echo "Opción incorrecta"
                echo "-------------------------------------------------------------------------------------------------"
                ;;
        esac
        
    done

}

m_main



