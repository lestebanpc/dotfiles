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
    echo "OS Subtype - ID      : ${g_os_subtype}"
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
    if [ $g_is_root -eq 0 ]; then
        dnf upgrade
    else
        sudo dnf upgrade
    fi
    
    
    echo "-------------------------------------------------------------------------------------------------"
    echo "- Configuración basica: archivos y folderes basicos, VIM-Enhaced, NeoVIM"
    echo "-------------------------------------------------------------------------------------------------"
    echo "Permiso a archivos basicos y folderes basicos"
    chmod u+x ~/.files/terminal/linux/tmux/oh-my-tmux.bash
    chmod u+x ~/.files/terminal/linux/complete/fzf.bash
    chmod u+x ~/.files/terminal/linux/keybindings/fzf.bash
    chmod u+x ~/.files/setup/*.bash
    
    
    if [ ! -d /u01/userkeys/ssh ]; then
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

m_setup $1

