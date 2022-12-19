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


#TODO Mejorar, solo esta escrito para fedora
function m_setup() {

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
    echo "OS Subtype - ID      : ${g_os_subtype_id}"
    echo "OS Subtype - Name    : ${g_os_subtype_name}"
    echo "OS Subtype - Versión : ${g_os_subtype_version}"

    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        echo "El sistema operativo debe ser Linux"
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
    
    if [ ! -d /u01/userkeys/ssh ]; then

        echo "-------------------------------------------------------------------------------------------------"
        echo "- Configuración basica: archivos y folderes basicos, VIM-Enhaced, NeoVIM"
        echo "-------------------------------------------------------------------------------------------------"
        echo "Permiso a archivos basicos y folderes basicos"
        chmod u+x ~/.files/terminal/linux/tmux/oh-my-tmux.bash
        chmod u+x ~/.files/terminal/linux/complete/fzf.bash
        chmod u+x ~/.files/terminal/linux/keybindings/fzf.bash
        chmod u+x ~/.files/setup/*.bash
    
        if [ $g_is_root -eq 0 ]; then
            mkdir -pm 755 /u01
            mkdir -pm 755 /u01/userkeys
            mkdir -pm 755 /u01/userkeys/ssh
            chown -R lucianoepc:lucianoepc /u01/userkeys
        else
            sudo mkdir -pm 755 /u01
            sudo mkdir -pm 755 /u01/userkeys
            sudo chown lucianoepc:lucianoepc /u01/userkeys
            mkdir -pm 755 /u01/userkeys/ssh
        fi
        echo "Folder \"/u01/userkeys/ssh\" se ha creado"
    fi
    
    #Validar si esta instalado VIM-Enhaced
    echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
    echo "- Instalación/Validación de VIM-Enhaced"
    echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
    local l_version=""
    if ! l_version=$(vim --version 2> /dev/null); then
        echo "Se va instalar VIM-Enhaced"
        if [ $g_is_root -eq 0 ]; then
            dnf install vim-enhanced
        else
            sudo dnf install vim-enhanced
        fi
    else
        l_version=$(echo "$l_version" | head -n 1)
        echo "VIM-Enhaced instalado: ${l_version}"
    fi
    
    #Validar si esta instalado NeoVIM
    echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
    echo "- Instalación/Validación de NeoVIM"
    echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
    if ! l_version=$(nvim --version 2> /dev/null); then
        echo "Se va instalar NeoVIM"
        if [ $g_is_root -eq 0 ]; then
            dnf install neovim
            dnf install python3-neovim
        else
            sudo dnf install neovim
            sudo dnf install python3-neovim
        fi
    else
        l_version=$(echo "$l_version" | head -n 1)
        echo "NeoVIM instalado: ${l_version}"
    fi

    #5. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 ]; then
        echo $'\n'"Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}

function m_show_menu_core() {

    echo "                                  Escoger la opción"
    echo "-------------------------------------------------------------------------------------------------"
    echo " (q) Salir del menu"
    echo " (a) Actualizar los binarios de los repositorios obligatorios"
    echo " ( ) Actualizar las opciones que desea. Ingrese la suma de las opciones que desea instalar:"
    echo "     (  0) Actualizar binarios de los repositorios obligatorios (siempre se realizara esta opción)"
    #echo "    (  1) Actualizar xxx"
    #echo "    (  2) Actualizar xxx"
    echo "     (  4) Actualizar binarios del    repositorio  opcionales \"k0s\""
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
                m_setup
                ;;

            q)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                ;;

            [1-9]*)
                if [[ "$l_opcion" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    echo "#################################################################################################"$'\n'
                    m_setup $l_opcion
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

m_setup $1

