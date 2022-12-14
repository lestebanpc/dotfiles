#!/bin/bash

#Definiciones globales, Inicialización {{{

#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
fi

#Determinar el tipo de SO. Devuelve:
#  00 - 10: Si es Linux
#           00 - Si es Linux genrico
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

#}}}

# Opciones:
#    0 - Se configura VIM en modo basico (por defecto)
#    1 - Se configura VIM en modo IDE
function m_setup_neovim() {

    #1. Argumentos
    local p_opcion=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opcion=$1
    fi

    local path_data=~/.local/share

    #Instalar los plugins
    echo "-------------------------------------------------------------------------------------------------"
    echo "- NeoVIM: Instalar plugins"
    echo "-------------------------------------------------------------------------------------------------"
    
    echo "Instalar el gestor de paquetes Vim-Plug"
    if [ ! -f ${path_data}/nvim/site/autoload/plug.vim ]; then
        mkdir -p ${path_data}/nvim/site/autoload
        curl -fLo ${path_data}/nvim/site/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    
    local l_base_path="${path_data}/nvim/site/pack/packer/start"
    mkdir -p $l_base_path
    cd ${l_base_path}

    local l_repo_name="packer.nvim"
    local l_repo_git="wbthomason/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        #echo "...................................................."
        echo "Instalando el paquete VIM \"${l_repo_git}\""
        #echo "...................................................."
        git clone --depth 1 https://github.com/${l_repo_git}.git
    else
        #echo "...................................................."
        echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
    fi
    
    echo "-------------------------------------------------------------------------------------------------"
    echo "- NeoVIM: Finalizando la configuración"
    echo "-------------------------------------------------------------------------------------------------"
    if [ ! -e ~/.config/nvim/lua ]; then
        echo "Creando el enlace de \"~/.config/nvim/lua\""
        mkdir -p ~/.config/nvim
        ln -snf ~/.files/nvim/lua ~/.config/nvim/lua
    fi

    if [ ! -e ~/.config/nvim/init.vim ]; then
        if [ $p_opcion -eq 1 ]; then
            echo "Creando el enlace de \"~/.config/nvim/init.vim\" para usarlo como IDE"
            ln -snf ~/.files/nvim/init_vm_linux_ide.vim ~/.config/nvim/init.vim
        else
            echo "Creando el enlace de \"~/.config/nvim/init.vim\" para usarlo como editor basico"
            ln -snf ~/.files/nvim/init_vm_linux_basic.vim ~/.config/nvim/init.vim
        fi
    fi

    echo "Complete la configuracion de los plugins en NeoVIM"
    echo "  1> Instalar los plugins de VIM-Plug: \":PlugInstall\""
    echo "  2> Instalar los plugins de VIM-Plug: \":PackerUpdate\""

    return 0
}


# Opciones:
#    0 - Se configura VIM en modo basico (por defecto)
#    1 - Se configura VIM en modo IDE
function m_setup_vim() {

    #1. Argumentos
    local p_opcion=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opcion=$1
    fi

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
    
    if [ ! -f ~/.vim/autoload/plug.vim ]; then
        echo "Instalar el gestor de paquetes Vim-Plug"
        mkdir -p ~/.vim/autoload
        curl -fLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    
    local l_base_path=~/.vim/pack/themes/opt
    cd ${l_base_path}

    local l_repo_name="molokai"
    local l_repo_git="tomasr/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        echo "...................................................."
        echo "Instalando el paquete VIM \"${l_repo_git}\""
        echo "...................................................."
        git clone https://github.com/${l_repo_git}.git
    else
        #echo "...................................................."
        echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
    fi

    l_repo_name="vim"
    l_repo_git="dracula/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        echo "...................................................."
        echo "Instalando el paquete VIM \"${l_repo_git}\""
        echo "...................................................."
        git clone https://github.com/${l_repo_git}.git
    else
        #echo "...................................................."
        echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
    fi

    l_base_path=~/.vim/pack/ui/opt
    cd ${l_base_path}
    
    l_repo_name="vim-airline"
    l_repo_git="vim-airline/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        echo "...................................................."
        echo "Instalando el paquete VIM \"${l_repo_git}\""
        echo "...................................................."
        git clone https://github.com/${l_repo_git}.git
    else
        #echo "...................................................."
        echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
    fi

    l_repo_name="vim-airline-themes"
    l_repo_git="vim-airline/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        echo "...................................................."
        echo "Instalando el paquete VIM \"${l_repo_git}\""
        echo "...................................................."
        git clone https://github.com/${l_repo_git}.git
    else
        #echo "...................................................."
        echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
    fi

    l_repo_name="nerdtree"
    l_repo_git="preservim/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        echo "...................................................."
        echo "Instalando el paquete VIM \"${l_repo_git}\""
        echo "...................................................."
        git clone https://github.com/${l_repo_git}.git
    else
        #echo "...................................................."
        echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
    fi

    l_repo_name="vim-tmux-navigator"
    l_repo_git="christoomey/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        echo "...................................................."
        echo "Instalando el paquete VIM \"${l_repo_git}\""
        echo "...................................................."
        git clone https://github.com/${l_repo_git}.git
    else
        #echo "...................................................."
        echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
    fi

    l_repo_name="fzf"
    l_repo_git="junegunn/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        echo "...................................................."
        echo "Instalando el paquete VIM \"${l_repo_git}\""
        echo "...................................................."
        git clone --depth 1 https://github.com/${l_repo_git}.git
    else
        #echo "...................................................."
        echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
    fi

    l_repo_name="fzf.vim"
    l_repo_git="junegunn/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        echo "...................................................."
        echo "Instalando el paquete VIM \"${l_repo_git}\""
        echo "...................................................."
        git clone https://github.com/${l_repo_git}.git
    else
        #echo "...................................................."
        echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
    fi

    if [ $p_opcion -eq 1 ]; then

        l_base_path=~/.vim/pack/typing/opt
        cd ${l_base_path}
        
        l_repo_name="vim-surround"
        l_repo_git="tpope/${l_repo_name}"
        if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
            echo "...................................................."
            echo "Instalando el paquete VIM \"${l_repo_git}\""
            echo "...................................................."
            git clone https://github.com/${l_repo_git}.git
        else
            #echo "...................................................."
            echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
        fi
    
        
        l_repo_name="vim-visual-multi"
        l_repo_git="mg979/${l_repo_name}"
        if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
            echo "Instalando el paquete VIM \"${l_repo_git}\""
            echo "...................................................."
            git clone https://github.com/${l_repo_git}.git
        else
            #echo "...................................................."
            echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
        fi


        l_base_path=~/.vim/pack/ide/opt
        cd ${l_base_path}
        
        l_repo_name="ale"
        l_repo_git="dense-analysis/${l_repo_name}"
        if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
            echo "...................................................."
            echo "Instalando el paquete VIM \"${l_repo_git}\""
            echo "...................................................."
            git clone https://github.com/${l_repo_git}.git
        else
            #echo "...................................................."
            echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
        fi
        
        l_repo_name="coc.nvim"
        l_repo_git="neoclide/${l_repo_name}"
        if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
            echo "...................................................."
            echo "Instalando el paquete VIM \"${l_repo_git}\""
            echo "...................................................."
            git clone --branch release --depth=1 https://github.com/${l_repo_git}.git
        else
            #echo "...................................................."
            echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
        fi
        
        l_repo_name="omnisharp-vim"
        l_repo_git="OmniSharp/${l_repo_name}"
        if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
            echo "...................................................."
            echo "Instalando el paquete VIM \"${l_repo_git}\""
            echo "...................................................."
            git clone https://github.com/${l_repo_git}.git
        else
            #echo "...................................................."
            echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
        fi

        l_repo_name="ultisnips"
        l_repo_git="SirVer/${l_repo_name}"
        if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
            echo "...................................................."
            echo "Instalando el paquete VIM \"${l_repo_git}\""
            echo "...................................................."
            git clone https://github.com/${l_repo_git}.git
        else
            #echo "...................................................."
            echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
        fi
        
        l_repo_name="vim-snippets"
        l_repo_git="honza/${l_repo_name}"
        if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
            echo "...................................................."
            echo "Instalando el paquete VIM \"${l_repo_git}\""
            echo "...................................................."
            git clone https://github.com/${l_repo_git}.git
        else
            #echo "...................................................."
            echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
        fi
        
        l_repo_name="vim-sharpenup"
        l_repo_git="nickspoons/${l_repo_name}"
        if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
            echo "...................................................."
            echo "Instalando el paquete VIM \"${l_repo_git}\""
            echo "...................................................."
            git clone https://github.com/${l_repo_git}.git
        else
            #echo "...................................................."
            echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
        fi
        
    fi
    
    echo "-------------------------------------------------------------------------------------------------"
    echo "- VIM: Finalizando la configuración"
    echo "-------------------------------------------------------------------------------------------------"
    if [ $p_opcion -eq 1 ]; then

        #if [ ! -e ~/.vimrc ]; then
        echo "Creando el enlace de ~/.vimrc"
        ln -snf ~/.files/vim/vimrc_vm_linux_ide.vim ~/.vimrc
        #fi
        echo "Complete la configuracion de VIM para IDE:"
        echo "  1> Instalar los plugins de VIM-Plug: \":PlugInstall\""
        echo "  2> Configurar COC:"
        echo "     2.1> Instalar lenguajes basicos JS, Json, HTLML y CSS: \":CocInstall coc-tsserver coc-json coc-html coc-css\""
        echo "     2.2> Instalar lenguajes basicos Python: \":CocInstall coc-pyrigh\""
        echo "     2.2> Instalar soporte al motor de snippets : \":CocInstall coc-ultisnips\""
        echo "  3> Usar ALE para liting y no el por defecto de COC: \":CocConfig\""
        echo "     { \"diagnostic.displayByAle\": true }"
    else
        #if [ ! -e ~/.vimrc ]; then
        echo "Creando el enlace de ~/.vimrc"
        ln -snf ~/.files/vim/vimrc_vm_linux_basic.vim ~/.vimrc
        #fi
        echo "Complete la configuracion de VIM para IDE:"
        echo "  1> Instalar los plugins de VIM-Plug: \":PlugInstall\""
    fi

    return 0
}


#TODO Mejorar, solo esta escrito para WSL que sea Ubuntu y no WSL que sea fedora
# Opciones:
#    0 - Se configura VIM en modo basico (por defecto)
#    1 - Se configura VIM en modo IDE
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
    
    echo "OS Type        : ${g_os}"
    #4 Configuracion: Crear enlaces simbolicos basicos
    echo "-------------------------------------------------------------------------------------------------"
    echo "- Creando los enlaces simbolicos"
    echo "-------------------------------------------------------------------------------------------------"

    #Si es WSL (Ubuntu)
    if [ $g_os -eq 1 ]; then

        if [ ! -e ~/.dircolors ]; then
           echo "Creando los enlaces simbolico de ~/.dircolors"
           ln -snf ~/.files/terminal/linux/profile/ubuntu_wls_dircolors.conf ~/.dircolors
        fi

        if [ ! -e ~/.tmux.conf ]; then
           echo "Creando los enlaces simbolico de ~/.tmux.conf"
           ln -snf ~/.files/terminal/linux/tmux/tmux.conf ~/.tmux.conf
        fi

        if [ ! -e ~/.gitconfig ]; then
           echo "Creando los enlaces simbolico de ~/.gitconfig"
           ln -snf ~/.files/git/wsl2_git.conf ~/.gitconfig
        fi

        if [ ! -e ~/.ssh/config ]; then
           echo "Creando los enlaces simbolico de ~/.ssh/config"
           ln -sfn ~/.files/ssh/wsl2_ssh.conf ~/.ssh/config
        fi

        if [ ! -e ~/.bashrc ]; then
           echo "Creando los enlaces simbolico de ~/.bashrc"
           ln -snf ~/.files/terminal/linux/profile/ubuntu_wls.bash ~/.bashrc
        fi

    else

        if [ ! -e ~/.tmux.conf ]; then
           echo "Creando los enlaces simbolico de ~/.tmux.conf"
           ln -snf ~/.files/terminal/linux/tmux/tmux.conf ~/.tmux.conf
        fi

        if [ ! -e ~/.gitconfig ]; then
           echo "Creando los enlaces simbolico de ~/.gitconfig"
           ln -snf ~/.files/git/vm_linux_git.conf ~/.gitconfig
        fi

        if [ ! -e ~/.ssh/config ]; then
           echo "Creando los enlaces simbolico de ~/.ssh/config"
           ln -snf ~/.files/ssh/vm_linux_ssh.conf ~/.ssh/config
        fi

        if [ ! -e ~/.bashrc ]; then
           echo "Creando los enlaces simbolico de ~/.bashrc"
           ln -snf ~/.files/terminal/linux/profile/fedora_vm.bash ~/.bashrc
        fi
    fi

    #5 Configuración: Instalar VIM
    m_setup_vim $p_opcion
    
    #6 Configuración: Instalar NeoVIM
    m_setup_neovim $p_opcion
      
    #7. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_is_root -ne 0 ]; then
        echo "Caducando el cache de temporal password de su 'sudo'"
        sudo -k
    fi

}

m_setup $1



