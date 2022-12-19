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
        echo "Complete la configuracion de VIM como editor basico:"
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
    
    case "$p_opcion" in
        0)
            echo "Configurando el profile basico: VIM en modo editor basico"
            ;;
        1)
            echo "Configurando el profile developer: VIM en modo IDE"
            ;;
        *)
            echo "ERROR(22): El tipo de profile \"${p_opcion}\" no esta permitido"
            return 22;
            ;;
    esac    

    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        echo "ERROR(21): El sistema operativo debe ser Linux"
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
    
    #4 Configuracion: Crear enlaces simbolicos basicos

    #echo "-------------------------------------------------------------------------------------------------"
    #echo "- Creando los enlaces simbolicos"
    #echo "-------------------------------------------------------------------------------------------------"

    #4.1 Creando enlaces simbolico dependiente de tipo de distribución Linux
    
    #case "$g_os_subtype_id" in
    #    1)
    #        #Distribución: Ubuntu
    #        ;;
    #    2)
    #        #Distribución: Fedora
    #        ;;
    #    0)
    #        echo "ERROR (22): No se identificado el tipo de Distribución Linux"
    #        return 22;
    #        ;;
    #esac

    #Si es Linux WSL
    if [ $g_os_type -eq 1 ]; then

        if [ ! -e ~/.dircolors ]; then
           echo "Creando los enlaces simbolico de ~/.dircolors"
           ln -snf ~/.files/terminal/linux/profile/ubuntu_wls_dircolors.conf ~/.dircolors
        fi

        if [ ! -e ~/.gitconfig ]; then
           echo "Creando los enlaces simbolico de ~/.gitconfig"
           ln -snf ~/.files/git/wsl2_git.conf ~/.gitconfig
        fi

        if [ ! -e ~/.ssh/config ]; then
           echo "Creando los enlaces simbolico de ~/.ssh/config"
           ln -sfn ~/.files/ssh/wsl2_ssh.conf ~/.ssh/config
        fi

        #if [ ! -e ~/.bashrc ]; then
        echo "Creando los enlaces simbolico de ~/.bashrc"
        ln -snf ~/.files/terminal/linux/profile/ubuntu_wls.bash ~/.bashrc
        #fi

    #Si es un Linux generico (NO WSL)
    else

        if [ ! -e ~/.gitconfig ]; then
           echo "Creando los enlaces simbolico de ~/.gitconfig"
           ln -snf ~/.files/git/vm_linux_git.conf ~/.gitconfig
        fi

        if [ ! -e ~/.ssh/config ]; then
           echo "Creando los enlaces simbolico de ~/.ssh/config"
           ln -snf ~/.files/ssh/vm_linux_ssh.conf ~/.ssh/config
        fi

        #if [ ! -e ~/.bashrc ]; then
        echo "Creando los enlaces simbolico de ~/.bashrc"
        ln -snf ~/.files/terminal/linux/profile/fedora_vm.bash ~/.bashrc
        #fi
    fi

    #4.2 Creando enlaces simbolico independiente de tipo de Linux

    if [ ! -e ~/.tmux.conf ]; then
       echo "Creando los enlaces simbolico de ~/.tmux.conf"
       ln -snf ~/.files/terminal/linux/tmux/tmux.conf ~/.tmux.conf
    fi

    #Si se usa VIM como IDE
    if [ $p_opcion -eq 1 ]; then

        if [ ! -e ~/.vim/coc-settings.json ]; then
            echo "Creando los enlaces simbolico de ~/.vim/coc-settings.json"
            ln -sfn ~/.files/vim/coc/coc-settings.json ~/.vim/coc-settings.json
        fi
    fi

    #5 Configuración: Instalar VIM
    m_setup_vim $p_opcion
    
    #6 Configuración: Instalar NeoVIM
    m_setup_neovim $p_opcion
      
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
    echo " (b) Configurar un profile basico         (VIM como editor basico, ..)"
    echo " (d) Configurar un profile como developer (VIM como IDE, ..)"
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
            b)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                m_setup 0
                ;;

            d)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                m_setup 1
                ;;

            q)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
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



