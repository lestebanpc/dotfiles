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
    if [[ ! "$1" =~ '^[0-9]+$' ]]; then
        p_opcion=$1
    fi

    #2. Validar si fue descarga el repositorio git correspondiente
    if [ -d ~/.files ]; then
        echo "Debe obtener los archivos basicos:"
        echo "   > git clone https://github.com/lestebanpc/dotfiles.git ~/.files"
        echo "   > chmod u+x ~/.files/setup/01_setup_init.bash"
        echo "   > . ~/.files/setup/01_setup_init.bash"
        echo "   > . ~/.files/setup/02_setup_commands.bash"
        echo "   > . ~/.files/setup/03_setup_profile_XXXX.bash"
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
    
    
    if [ $g_is_root -eq 0 ]; then
        mkdir -pm 755 /u01
        mkdir -pm 755 /u01/userkeys
        mkdir -pm 755 /u01/userkeys/ssh/
        chown -r lucianoepc:lucianoepc /u01/userkeys
    else
        sudo mkdir -pm 755 /u01
        sudo mkdir -pm 755 /u01/userkeys
        sudo chown lucianoepc:lucianoepc /u01/userkeys
        mkdir -pm 755 /u01/userkeys/ssh/
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
        echo "VIM-Enhaced instalado: $(echo $l_version | head -n 1)"
    fi
    
    #5. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 ]; then
        echo "Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}

m_setup $1

