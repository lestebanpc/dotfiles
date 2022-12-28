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

    local p_overwrite_ln_flag=1
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_overwrite_ln_flag=$2
    fi

    local path_data=~/.local/share

    #Instalar los plugins
    echo "-------------------------------------------------------------------------------------------------"
    echo "- Configuración de NeoVIM"
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
    
    echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
    if [ ! -e ~/.config/nvim/lua ] || [ $p_overwrite_ln_flag -eq 0 ]; then
        echo "Creando el enlace de \"~/.config/nvim/lua\""
        mkdir -p ~/.config/nvim
        ln -snf ~/.files/nvim/lua ~/.config/nvim/lua
    fi

    if [ ! -e ~/.config/nvim/init.vim ] || [ $p_overwrite_ln_flag -eq 0 ]; then
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

# Repositorios GIT donde estan los plugins VIM
# Valores:
#   (1) Perfil Basic - Tema
#   (2) Perfil Basic - UI
#   (3) Perfil Developer - Typing
#   (4) Perfil Developer - IDE
declare -A gA_repositories=(
        ['tomasr/molokai']=1
        ['dracula/vim']=1
        ['vim-airline/vim-airline']=2
        ['vim-airline/vim-airline-themes']=2
        ['preservim/nerdtree']=2
        ['christoomey/vim-tmux-navigator']=2
        ['junegunn/fzf']=2
        ['junegunn/fzf.vim']=2
        ['tpope/vim-surround']=3
        ['mg979/vim-visual-multi']=3
        ['dense-analysis/ale']=4
        ['neoclide/coc.nvim']=4
        ['OmniSharp/omnisharp-vim']=4
        ['SirVer/ultisnips']=4
        ['honza/vim-snippets']=4
        ['nickspoons/vim-sharpenup']=4
        ['puremourning/vimspector']=4
    )

# Opciones:
#    0 - Se configura VIM en modo basico (por defecto)
#    1 - Se configura VIM en modo IDE
function m_setup_vim() {

    #1. Argumentos
    local p_opcion=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opcion=$1
    fi

    local p_overwrite_ln_flag=1
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        p_overwrite_ln_flag=$2
    fi
    
    #Instalar los plugins
    echo "-------------------------------------------------------------------------------------------------"
    echo "- Configuración de VIM-Enhanced"
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
    
    local l_base_path
    local l_repo_git
    local l_repo_name
    local l_repo_type=1
    local l_repo_url
    for l_repo_git in "${!gA_repositories[@]}"; do

        #Configurar el repositorio
        l_repo_type=${gA_repositories[$l_repo_git]}
        l_repo_name=${l_repo_git#*/}

        #Obtener la ruta base donde se clorara el paquete
        l_base_path=""
        case "$l_repo_type" in 
            1)
                l_base_path=~/.vim/pack/themes/opt
                ;;
            2)
                l_base_path=~/.vim/pack/ui/opt
                ;;
            3)
                l_base_path=~/.vim/pack/typing/opt
                ;;
            4)
                l_base_path=~/.vim/pack/ide/opt
                ;;
            *)
                
                #echo "...................................................."
                printf 'Paquete VIM (%s) "%s": No tiene tipo valido\n' "${l_repo_type}" "${l_repo_git}"
                continue
                ;;
        esac

        #Si es un repositorio para perfil developer no debe instalarse en el perfil basico
        if [ $p_opcion -eq 0 ] && [ $l_repo_type -eq 3 -o $l_repo_type -eq 4 ]; then
            continue
        fi

        #echo "${l_base_path}/${l_repo_name}/.git"

        #Validar si el paquete ya esta instalado
        if [ -d ${l_base_path}/${l_repo_name}/.git ]; then
             #echo "...................................................."
             printf 'Paquete VIM (%s) "%s": Ya esta instalado\n' "${l_repo_type}" "${l_repo_git}"
             continue
        fi

        #Instalando el paquete
        cd ${l_base_path}
        printf '\n'
        echo "...................................................."
        printf 'Paquete VIM (%s) "%s": Se esta instalando\n' "${l_repo_type}" "${l_repo_git}"
        echo "...................................................."
        case "$l_repo_git" in 

            "junegunn/fzf")
                git clone --depth 1 https://github.com/${l_repo_git}.git
                ;;

            "neoclide/coc.nvim")
                git clone --branch release --depth=1 https://github.com/${l_repo_git}.git
                ;;
            *)
                git clone https://github.com/${l_repo_git}.git
                ;;
        esac
        printf '\n'

    done;

    
    printf '\n'
    echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
    if [ $p_opcion -eq 1 ]; then

        #if [ ! -e ~/.vimrc ] || [ $p_overwrite_ln_flag -eq 0 ]; then
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
        #if [ ! -e ~/.vimrc ] || [ $p_overwrite_ln_flag -eq 0 ]; then
        echo "Creando el enlace de ~/.vimrc"
        ln -snf ~/.files/vim/vimrc_vm_linux_basic.vim ~/.vimrc
        #fi
        echo "Complete la configuracion de VIM como editor basico:"
        echo "  1> Instalar los plugins de VIM-Plug: \":PlugInstall\""
    fi

    return 0
}


# Opciones:
#   ( 0) Actualizar los paquetes del SO y actualizar los enlaces simbolicos (siempre se ejecutara)"
#   ( 1) Instalar VIM-Enhanced si no esta instalado"
#   ( 2) Instalar NeoVIM si no esta instalado"
#   ( 4) Configurar VIM-Enhanced como Developer"
#   ( 8) Configurar NeoVIM como Developer"
#   (16) Forzar el actualizado de los enlaces simbolicos del profile"
function m_setup() {

    #1. Argumentos
    local p_opciones=3
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #2. Validar si fue descarga el repositorio git correspondiente
    if [ ! -d ~/.files/.git ]; then
        echo "No existe los archivos necesarios, debera seguir los siguientes pasos:"
        echo "   1> Descargar los archivos del repositorio:"
        echo "      git clone https://github.com/lestebanpc/dotfiles.git ~/.files"
        echo "   2> Instalar comandos basicos:"
        echo "      chmod u+x ~/.files/setup/01_setup_commands.bash"
        echo "      ~/.files/setup/01_setup_commands.bash"
        echo "   3> Configurar el profile del usuario:"
        echo "      chmod u+x ~/.files/setup/02_setup_profile.bash"
        echo "      ~/.files/setup/02_setup_profile.bash"
        return 0
    fi
    
    #3. Solicitar credenciales de administrador y almacenarlas temporalmente
    if [ $g_is_root -ne 0 ]; then

        #echo "Se requiere alamcenar temporalmente su password"
        sudo -v

        if [ $? -ne 0 ]; then
            echo "ERROR(20): Se requiere \"sudo -v\" almacenar temporalmente su credenciales de root"
            return 20;
        fi
        printf '\n\n'
    fi
    
    #4. Actualizar los paquetes de los repositorios
    echo "-------------------------------------------------------------------------------------------------"
    echo "- Actualizar los paquetes de los repositorio del SO Linux"
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
   
    
    #5. Instalando VIM-Enhaced
    local l_version=""

    local l_option=1
    local l_flag=$(( $p_opciones & $l_option ))
    local l_vim_flag=1
    if [ $l_flag -eq $l_option ]; then l_vim_flag=0; fi

    if [ $l_vim_flag -eq 0 ]; then

        echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."

        if ! l_version=$(vim --version 2> /dev/null); then

            echo "- Instalación de VIM-Enhaced"
            echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
            echo "Se va instalar VIM-Enhaced"

            if [ $g_is_root -eq 0 ]; then
                dnf install vim-enhanced
            else
                sudo dnf install vim-enhanced
            fi
        else
            l_version=$(echo "$l_version" | head -n 1)
            echo "VIM-Enhaced \"${l_version}\" ya esta instalado"
        fi

        #5.1 Instalacion requerida para VIM-Enhaced como develeper
        #Instalar Node.JS
        l_option=4
        l_flag=$(( $p_opciones & $l_option ))

        if [ $l_flag -eq $l_option ]; then

            echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."

            if ! l_version=$(node -v 2> /dev/null); then

                echo "- Instalación de Node JS (VIM como IDE)"
                echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
                echo "Se va instalar Node JS version 19.x"

                if [ $g_is_root -eq 0 ]; then
                    curl -fsSL https://rpm.nodesource.com/setup_19.x | bash -
                    yum install -y nodejs
                else
                    curl -fsSL https://rpm.nodesource.com/setup_19.x | sudo bash -
                    sudo yum install -y nodejs
                fi

            else
                echo "Node.JS \"$l_version\" ya esta instalado"
            fi
        fi
    fi
    
    #6. Instalando NeoVIM
    l_option=2
    l_flag=$(( $p_opciones & $l_option ))
    local l_nvim_flag=1
    if [ $l_flag -eq $l_option ]; then l_nvim_flag=0; fi

    if [ $l_nvim_flag -eq 0 ]; then

        echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."

        if ! l_version=$(nvim --version 2> /dev/null); then

            echo "- Instalación de NeoVIM"
            echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
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
            echo "NeoVIM \"${l_version}\" ya esta instalado"
        fi
    fi

    #4 Configuracion: Crear enlaces simbolicos y folderes basicos
    echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
    #echo "- Creando los enlaces simbolicos y folderes basicos"
    #echo ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
    
    if [ ! -d /u01/userkeys/ssh ]; then

        echo "Permiso ejecucion de shell y los folderes basicos \"/u01/userkeys/ssh\""
        chmod u+x ~/.files/terminal/linux/tmux/*.bash
        chmod u+x ~/.files/terminal/linux/complete/*.bash
        chmod u+x ~/.files/terminal/linux/keybindings/*.bash
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
    fi

    #4.1 Creando enlaces simbolico dependiente de tipo de distribución Linux
    l_option=16
    l_flag=$(( $p_opciones & $l_option ))
    local l_overwrite_ln_flag=1
    if [ $l_flag -eq $l_option ]; then l_overwrite_ln_flag=0; fi
    
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

        if [ ! -e ~/.dircolors ] || [ $l_overwrite_ln_flag -eq 0 ]; then
           echo "Creando los enlaces simbolico de ~/.dircolors"
           ln -snf ~/.files/terminal/linux/profile/ubuntu_wls_dircolors.conf ~/.dircolors
        fi

        if [ ! -e ~/.gitconfig ] || [ $l_overwrite_ln_flag -eq 0 ]; then
           echo "Creando los enlaces simbolico de ~/.gitconfig"
           ln -snf ~/.files/git/wsl2_git.conf ~/.gitconfig
        fi

        if [ ! -e ~/.ssh/config ] || [ $l_overwrite_ln_flag -eq 0 ]; then
           echo "Creando los enlaces simbolico de ~/.ssh/config"
           ln -sfn ~/.files/ssh/wsl2_ssh.conf ~/.ssh/config
        fi

        #if [ ! -e ~/.bashrc ] || [ $l_overwrite_ln_option -eq $l_overwrite_ln_flag ]; then
        echo "Creando los enlaces simbolico de ~/.bashrc"
        ln -snf ~/.files/terminal/linux/profile/ubuntu_wls.bash ~/.bashrc
        #fi

    #Si es un Linux generico (NO WSL)
    else

        if [ ! -e ~/.gitconfig ] || [ $l_overwrite_ln_flag -eq 0 ]; then
           echo "Creando los enlaces simbolico de ~/.gitconfig"
           ln -snf ~/.files/git/vm_linux_git.conf ~/.gitconfig
        fi

        if [ ! -e ~/.ssh/config ] || [ $l_overwrite_ln_flag -eq 0 ]; then
           echo "Creando los enlaces simbolico de ~/.ssh/config"
           ln -snf ~/.files/ssh/vm_linux_ssh.conf ~/.ssh/config
        fi

        #if [ ! -e ~/.bashrc ] || [ $l_overwrite_ln_option -eq $l_overwrite_ln_flag ]; then
        echo "Creando los enlaces simbolico de ~/.bashrc"
        ln -snf ~/.files/terminal/linux/profile/fedora_vm.bash ~/.bashrc
        #fi
    fi

    #4.2 Creando enlaces simbolico independiente de tipo de Linux
    if [ ! -e ~/.tmux.conf ] || [ $l_overwrite_ln_flag -eq 0 ]; then
       echo "Creando los enlaces simbolico de ~/.tmux.conf"
       ln -snf ~/.files/terminal/linux/tmux/tmux.conf ~/.tmux.conf
    fi

    #5. Si se usa VIM como IDE
    if [ $l_vim_flag -eq 0 ]; then
        l_option=4
        l_flag=$(( $p_opciones & $l_option ))
        if [ $l_flag -eq $l_option ]; then

            if [ ! -e ~/.vim/coc-settings.json ] || [ $l_overwrite_ln_flag -eq 0 ]; then
                echo "Creando los enlaces simbolico de ~/.vim/coc-settings.json"
                ln -sfn ~/.files/vim/coc/coc-settings.json ~/.vim/coc-settings.json
            fi
            m_setup_vim 1 $l_overwrite_ln_flag

        else
            m_setup_vim 0 $l_overwrite_ln_flag
        fi
    fi

    #6. Si se usa Neo-VIM como IDE
    if [ $l_nvim_flag -eq 0 ]; then
        l_option=8
        l_flag=$(( $p_opciones & $l_option ))
        if [ $l_flag -eq $l_option ]; then
            m_setup_neovim 1 $l_overwrite_ln_flag
        else
            m_setup_neovim 0 $l_overwrite_ln_flag
        fi
    fi
    
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
    echo " (b) Configurar el profile basico (VIM como editor basico, ...)"
    echo " (d) Configurar el profile como developer (VIM como IDE, ...)"
    echo " ( ) Configurar segun una o mas opciones especificas. Ingrese la suma de las opciones que desea configurar:"
    echo "     ( 0) Actualizar los paquetes del SO y crear los enlaces simbolicos si no existen (siempre se ejecutara)"
    echo "     ( 1) Instalar VIM-Enhanced si no esta instalado"
    echo "     ( 2) Instalar NeoVIM si no esta instalado"
    echo "     ( 4) Configurar VIM-Enhanced como Developer"
    echo "     ( 8) Configurar NeoVIM como Developer"
    echo "     (16) Crear y/o Forzar la actualizacion de los enlaces simbolicos del profile"
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
    local l_opciones=""
    while [ $l_flag_continue -eq 0 ]; do

        m_show_menu_core
        read l_opciones

        case "$l_opciones" in
            b)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                m_setup 3
                ;;

            d)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                m_setup 15
                ;;

            q)
                l_flag_continue=1
                echo "#################################################################################################"$'\n'
                ;;

            [1-9]*)
                if [[ "$l_opciones" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    echo "#################################################################################################"$'\n'
                    m_setup $l_opciones
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



