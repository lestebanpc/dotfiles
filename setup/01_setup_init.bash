#!/bin/bash

#Definiciones globales, Inicialización {{{

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
    echo "- Dar permiso a archivos basicos y folderes basicos"
    echo "-------------------------------------------------------------------------------------------------"
    chmod u+x ~/.files/terminal/linux/tmux/oh-my-tmux.sh
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
    fi
    
    #Validar si esta instalado VIM-Enhaced
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
        echo "Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}

m_setup $1

