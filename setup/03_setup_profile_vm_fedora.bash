#!/bin/bash

#Definiciones globales, Inicialización {{{

#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
fi

#}}}

#TODO Mejorar, solo esta escrito para fedora
# Opciones:
#    0 - No se instala VIM en modo IDE
#    1 - Se instala VIM en modo IDE
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
        echo "   4> . ~/.files/setup/02_setup_commands.bash"
        echo "   6> . ~/.files/setup/03_setup_profile_XXXX.bash"
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
    echo "- Creando los enlaces simbolicos"
    echo "-------------------------------------------------------------------------------------------------"
    ln -snf ~/.files/terminal/linux/tmux/tmux.conf ~/.tmux.conf
    ln -snf ~/.files/git/vm_linux_git.conf ~/.gitconfig
    ln -snf ~/.files/ssh/vm_linux_ssh.conf ~/.ssh/config
    ln -snf ~/.files/terminal/linux/profile/fedora_vm.bash ~/.bashrc

    #Instalar Node.JS
    if [ $p_opcion -eq 1 ]; then
        echo "-------------------------------------------------------------------------------------------------"
        echo "- VIM como IDE: Instalar Node JS"
        echo "-------------------------------------------------------------------------------------------------"
        local l_version=""
        if ! l_version=$(node -v 2> /dev/null); then
            echo "Se va instalar Node JS version 19.x"
            if [ $g_is_root -eq 0 ]; then
                curl -fsSL https://rpm.nodesource.com/setup_19.x | bash -
                yum install -y nodejs
            else
                curl -fsSL https://rpm.nodesource.com/setup_19.x | sudo bash -
                sudo yum install -y nodejs
            fi
        else
            echo "Node.JS instalado: $l_version"
        fi
    fi

    
    
    #Instalar los plugins
    echo "-------------------------------------------------------------------------------------------------"
    echo "- VIM: Instalar plugins"
    echo "-------------------------------------------------------------------------------------------------"
    echo "Instalar los paquetes usados por VIM"
    mkdir -p ~/.vim/pack/themes/start
    mkdir -p ~/.vim/pack/themes/opt
    mkdir -p ~/.vim/pack/ui/start
    mkdir -p ~/.vim/pack/ui/opt
    if [ $p_opcion -eq 1 ]; then
        mkdir -p ~/.vim/pack/typing/start
        mkdir -p ~/.vim/pack/typing/opt
        mkdir -p ~/.vim/pack/ide/start
        mkdir -p ~/.vim/pack/ide/opt
    fi
    
    echo "Instalar el gestor de paquetes Vim-Plug"
    mkdir -p ~/.vim/autoload
    curl -fLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    
    local l_base_path=~/.vim/pack/themes/opt
    cd ${l_base_path}

    local l_repo_git="tomasr/molokai"
    if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
        echo "Instalar el paquete VIM \"${l_repo_id}\""
        git clone https://github.com/${l_repo_git}.git
    else
        echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
    fi

    l_repo_git="dracula/vim"
    if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
        echo "Instalar el paquete VIM \"${l_repo_id}\""
        git clone https://github.com/${l_repo_git}.git
    else
        echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
    fi
    
     
    l_base_path=~/.vim/pack/ui/opt
    cd ${l_base_path}
    
    l_repo_git="vim-airline/vim-airline"
    if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
        echo "Instalar el paquete VIM \"${l_repo_id}\""
        git clone https://github.com/${l_repo_git}.git
    else
        echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
    fi

    l_repo_git="vim-airline/vim-airline-themes"
    if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
        echo "Instalar el paquete VIM \"${l_repo_id}\""
        git clone https://github.com/${l_repo_git}.git
    else
        echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
    fi

    l_repo_git="preservim/nerdtree"
    if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
        echo "Instalar el paquete VIM \"${l_repo_id}\""
        git clone https://github.com/${l_repo_git}.git
    else
        echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
    fi

    l_repo_git="christoomey/vim-tmux-navigator"
    if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
        echo "Instalar el paquete VIM \"${l_repo_id}\""
        git clone https://github.com/${l_repo_git}.git
    else
        echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
    fi

    l_repo_git="junegunn/fzf"
    if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
        echo "Instalar el paquete VIM \"${l_repo_id}\""
        git clone --depth 1 https://github.com/${l_repo_git}.git
    else
        echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
    fi

    l_repo_git="junegunn/fzf.vim"
    if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
        echo "Instalar el paquete VIM \"${l_repo_id}\""
        git clone https://github.com/${l_repo_git}.git
    else
        echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
    fi
    
    if [ $p_opcion -eq 1 ]; then

        l_base_path=~/.vim/pack/typing/opt
        cd ${l_base_path}
        
        l_repo_git="tpope/vim-surround"
        if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
            echo "Instalar el paquete VIM \"${l_repo_id}\""
            git clone https://github.com/${l_repo_git}.git
        else
            echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
        fi
    
        
        l_repo_git="mg979/vim-visual-multi"
        if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
            echo "Instalar el paquete VIM \"${l_repo_id}\""
            git clone https://github.com/${l_repo_git}.git
        else
            echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
        fi


        l_base_path=~/.vim/pack/ide/opt
        cd ${l_base_path}
        
        l_repo_git="dense-analysis/ale"
        if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
            echo "Instalar el paquete VIM \"${l_repo_id}\""
            git clone https://github.com/${l_repo_git}.git
        else
            echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
        fi
        
        l_repo_git="neoclide/coc.nvim"
        if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
            echo "Instalar el paquete VIM \"${l_repo_id}\""
            git clone --branch release --depth=1 https://github.com/${l_repo_git}.git
        else
            echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
        fi
        
        l_repo_git="OmniSharp/omnisharp-vim"
        if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
            echo "Instalar el paquete VIM \"${l_repo_id}\""
            git clone https://github.com/${l_repo_git}.git
        else
            echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
        fi
        
        l_repo_git="SirVer/ultisnips"
        if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
            echo "Instalar el paquete VIM \"${l_repo_id}\""
            git clone https://github.com/${l_repo_git}.git
        else
            echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
        fi
        
        l_repo_git="honza/vim-snippets"
        if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
            echo "Instalar el paquete VIM \"${l_repo_id}\""
            git clone https://github.com/${l_repo_git}.git
        else
            echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
        fi
        
        l_repo_git="nickspoons/vim-sharpenup"
        if [ ! -d ${l_base_path}/${l_repo_git}/.git ]; then
            echo "Instalar el paquete VIM \"${l_repo_id}\""
            git clone https://github.com/${l_repo_git}.git
        else
            echo "Paquete VIM \"${l_repo_id}\" ya esta instalado"
        fi
        
    fi
    
    echo "-------------------------------------------------------------------------------------------------"
    echo "- VIM: Finalizando la configuración"
    echo "-------------------------------------------------------------------------------------------------"
    echo "Crear el enlace de ~/.vimrc"
    if [ $p_opcion -eq 1 ]; then
        ln -snf ~/.files/vim/vimrc_vm_linux_ide.vim ~/.vimrc
        echo "Complete la configuracion de VIM para IDE:"
        echo "  1> Instalar los plugins de VIM-Plug: \":PlugInstall\""
        echo "  2> Configurar COC:"
        echo "     2.1> Instalar lenguajes basicos JS, Json, HTLML y CSS: \":CocInstall coc-tsserver coc-json coc-html coc-css\""
        echo "     2.2> Instalar lenguajes basicos Python: \":CocInstall coc-pyrigh\""
        echo "     2.2> Instalar soporte al motor de snippets : \":CocInstall coc-ultisnips\""
        echo "  3> Usar ALE para liting y no el por defecto de COC: \":CocConfig\""
        echo "     { \"diagnostic.displayByAle\": true }"
    else
        ln -snf ~/.files/vim/vimrc_vm_linux_basic.vim ~/.vimrc
        echo "Complete la configuracion de VIM para IDE:"
        echo "  1> Instalar los plugins de VIM-Plug: \":PlugInstall\""
    fi
    
    #5. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 ]; then
        echo "Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}

m_setup $1



