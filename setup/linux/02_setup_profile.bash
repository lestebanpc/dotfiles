#!/bin/bash

#Inicialización Global {{{

#Funciones generales: determinar el tipo del SO, ...
. ~/.files/terminal/linux/functions/func_utility.bash

#Funciones de utlidad
. ~/.files/setup/linux/_common_utility.bash

#Variable global pero solo se usar localmente en las funciones
_g_tmp=""

#Determinar la clase del SO
get_os_type
declare -r g_os_type=$?

#Deteriminar el tipo de distribución Linux
if [ $g_os_type -le 10 ]; then
    _g_tmp=$(get_linux_type_id)
    declare -r g_os_subtype_id=$?
    declare -r g_os_subtype_name="$_g_tmp"
    _g_tmp=$(get_linux_type_version)
    declare -r g_os_subtype_version="$_g_tmp"
fi

#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
fi



#Estado del almacenado temporalmente de las credenciales para sudo
# -1 - No se solicito el almacenamiento de las credenciales
#  0 - No es root: se almaceno las credenciales
#  1 - No es root: no se pudo almacenar las credenciales.
#  2 - Es root: no requiere realizar sudo.
g_status_crendential_storage=-1

# Repositorios GIT donde estan los plugins VIM
# Valores:
#   (1) Perfil Basic - Tema
#   (2) Perfil Basic - UI
#   (3) Perfil Developer - Typing
#   (4) Perfil Developer - IDE
declare -A gA_repos_type=(
        ['tomasr/molokai']=1
        ['dracula/vim']=1
        ['vim-airline/vim-airline']=2
        ['vim-airline/vim-airline-themes']=2
        ['preservim/nerdtree']=2
        ['ryanoasis/vim-devicons']=2
        ['preservim/vimux']=2
        ['christoomey/vim-tmux-navigator']=2
        ['junegunn/fzf']=2
        ['junegunn/fzf.vim']=2
        ['tpope/vim-surround']=3
        ['mg979/vim-visual-multi']=3
        ['mattn/emmet-vim']=3
        ['dense-analysis/ale']=4
        ['neoclide/coc.nvim']=4
        ['OmniSharp/omnisharp-vim']=4
        ['SirVer/ultisnips']=4
        ['honza/vim-snippets']=4
        #['nickspoons/vim-sharpenup']=4
        ['puremourning/vimspector']=4
    )

# Repositorios Git - Branch donde esta el plugin no es el por defecto
declare -A gA_repos_branch=(
        ['neoclide/coc.nvim']='release'
    )


# Repositorios Git - Deep de la clonacion del repositorio que no es el por defecto
declare -A gA_repos_depth=(
        ['neoclide/coc.nvim']=1
        ['junegunn/fzf']=1
    )



#}}}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
function _neovim_config_plugins() {

    #1. Argumentos
    local p_flag_developer=1
    if [ "$1" = "0" ]; then
        p_flag_developer=0
    fi

    local p_flag_developer_vim=1
    if [ "$2" = "0" ]; then
        p_flag_developer_vim=0
    fi


    local path_data=~/.local/share

    #2. Instalar el gestor de plugin/paquetes 'Vim-Plug' (no se usara este gestor)
    #echo "Instalar el gestor de paquetes Vim-Plug"
    #if [ ! -f ${path_data}/nvim/site/autoload/plug.vim ]; then
    #    mkdir -p ${path_data}/nvim/site/autoload
    #    curl -fLo ${path_data}/nvim/site/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    #fi
    
    #2. Instalar el gestor de paquetes 'Packer' (cambiarlo por lazy)
    local l_base_path="${path_data}/nvim/site/pack/packer/start"
    mkdir -p $l_base_path
    cd ${l_base_path}

    local l_repo_name="packer.nvim"
    local l_repo_git="wbthomason/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        #print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
        printf 'Instalando el paquete NeoVim "%b%s%b"\n' "$g_color_opaque" "$l_repo_git" "$g_color_reset"
        #print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
        git clone --depth 1 https://github.com/${l_repo_git}.git
    else
        #print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
        printf 'Paquete VIM "%b%s%b" ya esta instalado\n' "$g_color_opaque" "$l_repo_git" "$g_color_reset"
    fi

    #3. Instalar el gestor de paquetes 'Lazy'

    #4. Actualizar los paquetes/plugin de NeoVim
    #echo 'Instalando los plugins "Vim-Plug" de NeoVIM, ejecutando el comando ":PlugInstall"'
    #nvim --headless -c 'PlugInstall' -c 'qa'

    printf 'Instalando los plugins "Packer" de NeoVIM, ejecutando el comando "%b:PackerInstall%b"\n' "$g_color_opaque" "$g_color_reset"
    nvim --headless -c 'PackerInstall' -c 'qa'

    #echo 'Actualizando los plugins "Vim-Plug" de NeoVIM, ejecutando el comando ":PlugUpdate"'
    #nvim --headless -c 'PlugUpdate' -c 'qa'

    printf 'Actualizando los plugins "Packer" de NeoVIM, ejecutando el comando "%b:PackerUpdate%b"\n' "$g_color_opaque" "$g_color_reset"
    nvim --headless -c 'PackerUpdate' -c 'qa'

    if [ $p_flag_developer -eq 0 ]; then


        printf 'Se ha instalado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "NeoVIM" "$g_color_reset" "$g_color_subtitle" "Developer" "$g_color_reset"


        if [ $p_flag_developer_vim -eq 0 ]; then

            printf '%bVIM esta como IDE y usa COC.%b Configurando a NeoVIM, para permitir usar CoC en NeoVIM:\n' "$g_color_opaque" "$g_color_reset"

            #Instalando extensiones basicos de CoC: Adaptador de LSP server basicos JS, Json, HTLML, CSS, Python, Bash
            printf '  Instalando extensiones de CoC (Adaptador de LSP server basicos) "%b:CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh%b"\n' \
                "$g_color_opaque" "$g_color_reset"
            USE_COC=1 nvim --headless -c 'CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh' -c 'qa'

            #Instalando extensiones basicos de CoC: Motor de snippets 'UtilSnips'
            printf '  Instalando extensiones de CoC (Motor de snippets "UtilSnips") "%b:CocInstall coc-ultisnips%b" (%bno se esta usando el nativo de CoC%b)\n' \
                "$g_color_opaque" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
            USE_COC=1 nvim --headless -c 'CocInstall coc-update' -c 'qa'

            #Instalando los gadgets basicos de 'VimSpector'
            #printf '  Actualizando los gadgets de "VimSpector", ejecutando el comando ":VimspectorUpdate"\n'
            #USE_COC=1 nvim --headless -c 'VimspectorUpdate' -c 'qa'

            #Actualizar las extensiones de CoC
            printf '  Actualizando los extensiones existentes de CoC, ejecutando el comando "%b:CocUpdate%b"\n' "$g_color_opaque" "$g_color_reset"
            USE_COC=1 nvim --headless -c 'CocUpdate' -c 'qa'

            #Actualizando los gadgets de 'VimSpector'
            #printf '  Actualizando los gadgets de "VimSpector", ejecutando el comando ":VimspectorUpdate"\n'
            #USE_COC=1 nvim --headless -c 'VimspectorUpdate' -c 'qa'

            #printf 'Configurando los plugins usados para el IDE vinculado al LSP nativo de NeoVIM ...\n' 

            printf '\nRecomendaciones:\n'
            printf '  > Por defecto, se ejecuta el IDE vinculado al LSP nativo de NeoVIM.\n'
            printf '    > Si desea usar CoC, use: "%bUSE_COC=1 nvim%b"\n' "$g_color_subtitle" "$g_color_reset"
            printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 nvim%b"\n' "$g_color_subtitle" "$g_color_reset"

            printf '  > Si usar como Developer con IDE CoC, se recomienda que lo configura segun su necesidad:\n'
            echo "        1> Instalar extensiones de COC segun su necesidad (Listar existentes \":CocList extensions\")"
            echo "        2> Revisar la Configuracion de COC \":CocConfig\":"
            echo "          2.1> El diganostico se enviara ALE (no se usara el integrado de CoC), revisar:"
            echo "               { \"diagnostic.displayByAle\": true }"
            echo "          2.2> El formateador de codigo 'Prettier' sera proveido por ALE (no se usara la extension 'coc-prettier')"
            echo "               Si esta instalado esta extension, desintalarlo."

        else

            printf '\nRecomendaciones:\n'
            printf '  > Por defecto, se ejecuta el IDE vinculado al LSP nativo de NeoVIM.\n'
            printf '  > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 nvim%b"\n' "$g_color_subtitle" "$g_color_reset"

        fi

    else

        printf 'Se ha instalado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "NeoVIM" "$g_color_reset" "$g_color_subtitle" "Editor" "$g_color_reset"
    fi

    return 0
}

# Parametros:
#  1> Flag configurar como Developer (si es '0')
function _config_nvim() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    local p_flag_developer=1
    if [ "$2" = "0" ]; then
        p_flag_developer=0
    fi

    local p_flag_developer_vim=1
    if [ "$3" = "0" ]; then
        p_flag_developer_vim=0
    fi


    #Sobrescribir los enlaces simbolicos
    local l_option=4
    local l_flag=$(( $p_opciones & $l_option ))
    local l_overwrite_ln_flag=1
    if [ $l_flag -eq $l_option ]; then l_overwrite_ln_flag=0; fi

    printf '\n'
    print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 

    mkdir -p ~/.config/nvim/
    
    #2. Creando los enalces simbolicos

    #Configurar NeoVIM como IDE (Developer)
    if [ $p_flag_developer -eq 0 ]; then


        l_link='/.config/nvim/coc-settings.json'
        l_object='/.files/nvim/ide_coc/coc-settings_lnx.json'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi



        l_link='/.config/nvim/init.vim'
        l_object='/.files/nvim/init_linux_ide.vim'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi

        l_link='/.config/nvim/lua'
        l_object='/.files/nvim/lua'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi

        
        #El codigo open/close asociado a los 'file types'
        l_link='/.config/nvim/ftplugin'
        l_object='/.files/nvim/ide_commom/ftplugin/'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi



        if [ ! -d ~/.config/nvim/runtime_coc ]; then
            mkdir -p ~/.config/nvim/runtime_coc
            printf "NeoVIM (IDE)> Se ha creado la carpeta '%s' para colocar archivos/folderes especificos de un runtime para CoC\n" "~/.config/nvim/runtime_coc"
        fi        

        #Para el codigo open/close asociado a los 'file types' de CoC
        l_link='/.config/nvim/runtime_coc/ftplugin'
        l_object='/.files/vim/ide_coc/ftplugin/'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi

        if [ ! -d ~/.config/nvim/runtime_nococ ]; then
            mkdir -p ~/.config/nvim/runtime_nococ
            printf "NeoVIM (IDE)> Se ha creado la carpeta '%s' para colocar archivos/folderes especificos de un runtime que no sean CoC\n" "~/.config/nvim/runtime_nococ"
        fi


        #Para el codigo open/close asociado a los 'file types' que no sean CoC
        l_link='/.config/nvim/runtime_nococ/ftplugin'
        l_object='/.files/nvim/ide_nococ/ftplugin'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi

    #Configurar NeoVIM como Editor
    else

        l_link='/.config/nvim/init.vim'
        l_object='/.files/nvim/init_linux_basic.vim'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi

        
        l_link='/.config/nvim/lua'
        l_object='/.files/nvim/lua'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


        #El codigo open/close asociado a los 'file types' como Editor
        l_link='/.config/nvim/ftplugin'
        l_object='/.files/nvim/editor/ftplugin/'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "NeoVIM (IDE)> El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "NeoVIM (IDE)> El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


    fi

    #6. Instalando paquetes
    _neovim_config_plugins $p_flag_developer $p_flag_developer_vim


}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
function _vim_config_plugins() {

    #1. Argumentos
    local p_flag_developer=1
    if [ "$1" = "0" ]; then
        p_flag_developer=0
    fi

    #2. Crear las carpetas de basicas
    echo "Instalar los paquetes usados por VIM"
    mkdir -p ~/.vim/pack/themes/start
    mkdir -p ~/.vim/pack/themes/opt
    mkdir -p ~/.vim/pack/ui/start
    mkdir -p ~/.vim/pack/ui/opt
    if [ $p_flag_developer -eq 0 ]; then
        mkdir -p ~/.vim/pack/typing/start
        mkdir -p ~/.vim/pack/typing/opt
        mkdir -p ~/.vim/pack/ide/start
        mkdir -p ~/.vim/pack/ide/opt
    fi
   
    #3. Instalar el gestor de paquetes (no se usara gestor de paquetes para VIM)
    #if [ ! -f ~/.vim/autoload/plug.vim ]; then
    #    echo "Instalar el gestor de paquetes Vim-Plug"
    #    mkdir -p ~/.vim/autoload
    #    curl -fLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    #fi
    
    #4. Instalar el plugins que se instalan manualmente
    local l_base_path
    local l_repo_git
    local l_repo_name
    local l_repo_type=1
    local l_repo_url
    local l_repo_branch
    local l_repo_depth
    local l_aux
    for l_repo_git in "${!gA_repos_type[@]}"; do

        #4.1 Configurar el repositorio
        l_repo_type=${gA_repos_type[$l_repo_git]}
        l_repo_name=${l_repo_git#*/}

        #4.2 Obtener la ruta base donde se clorara el paquete
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
                
                #print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
                printf 'Paquete VIM (%s) "%s": No tiene tipo valido\n' "${l_repo_type}" "${l_repo_git}"
                continue
                ;;
        esac

        #Si es un repositorio para developer no debe instalarse en el perfil basico
        if [ $p_flag_developer -eq 1 ] && [ $l_repo_type -eq 3 -o $l_repo_type -eq 4 ]; then
            continue
        fi

        #echo "${l_base_path}/${l_repo_name}/.git"

        #4.3 Validar si el paquete ya esta instalado
        if [ -d ${l_base_path}/${l_repo_name}/.git ]; then
             #print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
             printf 'Paquete VIM (%s) "%b%s%b": Ya esta instalado\n' "${l_repo_type}" "$g_color_opaque" "${l_repo_git}" "$g_color_reset"
             continue
        fi

        #4.5 Instalando el paquete
        cd ${l_base_path}
        printf '\n'
        print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
        printf 'Paquete VIM (%b%s%b) "%b%s%b": Se esta instalando\n' "$g_color_subtitle" "${l_repo_type}" "$g_color_reset" "$g_color_subtitle" "${l_repo_git}" "$g_color_reset"
        print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 

        l_aux=""

        l_repo_branch=${gA_repos_branch[$l_repo_git]}
        if [ ! -z "$l_repo_branch" ]; then
            l_aux="--branch ${l_repo_branch}"
        fi

        l_repo_depth=${gA_repos_depth[$l_repo_git]}
        if [ ! -z "$l_repo_depth" ]; then
            if [ -z "$l_aux" ]; then
                l_aux="--depth ${l_repo_depth}"
            else
                l_aux="${l_aux} --depth ${l_repo_depth}"
            fi
        fi

        if [ -z "$l_aux" ]; then
            printf 'Ejecutando "git clone https://github.com/%s.git"\n' "$l_repo_git"
            git clone https://github.com/${l_repo_git}.git
        else
            printf 'Ejecutando "git clone %s https://github.com/%s.git"\n' "$l_aux" "$l_repo_git"
            git clone ${l_aux} https://github.com/${l_repo_git}.git
        fi

        #4.6 Actualizar la documentación de VIM

        #Los plugins VIM que no tiene documentación, no requieren indexar
        if [ "$l_repo_name" = "molokai" ]; then
            printf '\n'
            continue
        fi
        
        #Indexar la documentación de plugins
        printf 'Indexar la documentación del plugin: "%bhelptags %s/%s/doc%b"\n' "$g_color_opaque" "${l_base_path}" "${l_repo_name}" "$g_color_reset"
        vim -u NONE -esc "helptags ${l_base_path}/${l_repo_name}/doc" -c qa    

        printf '\n'

    done;

    #5. Instalar los paquetes/plugin que se instana por comandos de Vim
    #echo 'Instalando los plugins "Vim-Plug" de VIM, ejecutando el comando ":PlugInstall"'
    #vim -esc 'PlugInstall' -c 'qa'

    #echo 'Actualizando los plugins "Vim-Plug" de VIM, ejecutando el comando ":PlugUpdate"'
    #vim -esc 'PlugUpdate' -c 'qa'

    if [ $p_flag_developer -eq 0 ]; then

        printf 'Se ha instalado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "VIM" "$g_color_reset" "$g_color_subtitle" "Developer" "$g_color_reset"
        printf 'Configurando los plugins usados para IDE ...\n' 


        #Instalando extensiones basicos de CoC: Adaptador de LSP server basicos JS, Json, HTLML, CSS, Python, Bash
        printf '  Instalando extensiones de CoC (Adaptador de LSP server basicos) "%b:CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh%b"\n' \
            "$g_color_opaque" "$g_color_reset"
        vim -esc 'CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh' -c 'qa'

        #Instalando extensiones basicos de CoC: Motor de snippets 'UtilSnips'
        printf '  Instalando extensiones de CoC (Motor de snippets "UtilSnips") "%b:CocInstall coc-ultisnips%b" (%bno se esta usando el nativo de CoC%b)\n' \
            "$g_color_opaque" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
        vim -esc 'CocInstall coc-update' -c 'qa'

        #Actualizar las extensiones de CoC
        printf '  Actualizando los extensiones existentes de CoC, ejecutando el comando "%b:CocUpdate%b"\n' "$g_color_opaque" "$g_color_reset"
        vim -esc 'CocUpdate' -c 'qa'

        #Actualizando los gadgets de 'VimSpector'
        printf '  Actualizando los gadgets de "VimSpector", ejecutando el comando "%b:VimspectorUpdate%b"\n' "$g_color_opaque" "$g_color_reset"
        vim -esc 'VimspectorUpdate' -c 'qa'



        printf '\nRecomendaciones:\n'
        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 vim%b"\n' "$g_color_subtitle" "$g_color_reset"
        printf '    > Se recomienda que configure su IDE CoC segun su necesidad:\n'
        echo "        1> Instalar extensiones de COC segun su necesidad (Listar existentes \":CocList extensions\")"
        echo "        2> Revisar la Configuracion de COC \":CocConfig\":"
        echo "          2.1> El diganostico se enviara ALE (no se usara el integrado de CoC), revisar:"
        echo "               { \"diagnostic.displayByAle\": true }"
        echo "          2.2> El formateador de codigo 'Prettier' sera proveido por ALE (no se usara la extension 'coc-prettier')"
        echo "               Si esta instalado esta extension, desintalarlo."
        l_repo_branch=${gA_repos_branch[$l_repo_git]}

    else
        printf 'Se ha instalado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "VIM" "$g_color_reset" "$g_color_subtitle" "Editor" "$g_color_reset"
    fi

    return 0

}

# Parametros:
#  1> Flag configurar como Developer (si es '0')
function _config_vim() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    local p_flag_developer=1
    if [ "$2" = "0" ]; then
        p_flag_developer=0
    fi

    #Sobrescribir los enlaces simbolicos
    local l_option=4
    local l_flag=$(( $p_opciones & $l_option ))
    local l_overwrite_ln_flag=1
    if [ $l_flag -eq $l_option ]; then l_overwrite_ln_flag=0; fi

    #2. Crear el subtitulo

    #print_line '-' $g_max_length_line "$g_color_opaque" 
    #echo "> Configuración de VIM-Enhanced"
    #print_line '-' $g_max_length_line "$g_color_opaque" 

    printf '\n'
    print_line '. ' $((g_max_length_line/2)) "$g_color_opaque"
    mkdir -p ~/.vim/

    #3. Crear los enlaces simbolicos de VIM

    #Configurar VIM como IDE (Developer)
    if [ $p_flag_developer -eq 0 ]; then

        #Creando enlaces simbolicos
        l_link='/.vim/coc-settings.json'
        l_object='/.files/vim/ide_coc/coc-settings_lnx.json'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "VIM (IDE)   > El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "VIM (IDE)   > El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "VIM (IDE)   > El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


        
        l_link='/.vim/ftplugin'
        l_object='/.files/vim/ide_coc/ftplugin/'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "VIM (IDE)   > El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "VIM (IDE)   > El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "VIM (IDE)   > El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi



        l_link='/.vimrc'
        l_object='/.files/vim/vimrc_linux_ide.vim'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "VIM (IDE)   > El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "VIM (IDE)   > El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "VIM (IDE)   > El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


    #Configurar VIM como Editor basico
    else

        l_link='/.vimrc'
        l_object='/.files/vim/vimrc_linux_basic.vim'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "VIM (IDE)   > El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "VIM (IDE)   > El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "VIM (IDE)   > El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


        l_link='/.vim/ftplugin'
        l_object='/.files/vim/editor/ftplugin/'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "VIM (IDE)   > El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "VIM (IDE)   > El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "VIM (IDE)   > El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


    fi

    #Instalar los plugins
    _vim_config_plugins $p_flag_developer

}


# Parametros:
#  1> Opcion ingresada por el usuario.
#  2> Flag para mostrar el titulo
function _config_vim_nvim() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    local p_flag_title=1
    if [ "$2" = "0"  ]; then
        p_flag_title=0
    fi

    #2. Determinar si se requiere instalar VIM/NeoVIM
    local l_flag_config_vim=1
    local l_flag_config_nvim=1

    local l_option=16
    local l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_config_vim=0; fi
    
    l_option=128
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_config_nvim=0; fi

    #Si no se solicitar instalar VIM o NeoVIM no instalar ningun comando
    if [ $l_flag_config_vim -ne 0 ] && [ $l_flag_config_nvim -ne 0 ]; then
        return 99
    fi
   
    #¿Se requiere instalar en modo developer?
    local l_flag_developer_vim=1
    local l_flag_developer_nvim=1

    local l_option=32
    local l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_developer_vim=0; fi
    
    l_option=256
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_developer_nvim=0; fi


    #3. Mostrar el titulo de instalacion
    local l_title
    local l_aux=""

    if [ $l_flag_title -ne 0 ]; then

        if [ $l_flag_config_vim -eq 0 ]; then
            if [ $l_flag_developer_vim -eq 0 ]; then
                printf -v l_aux "%sVIM%s %sdeveloper%s" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
            else
                printf -v l_aux "%sVIM%s %seditor%s" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
            fi
        fi

        if [ $l_flag_config_nvim -eq 0 ]; then
            if [ ! -z "$l_aux" ]; then
                l_aux="${l_aux} y "
            fi
            if [ $l_flag_developer_vim -eq 0 ]; then
                printf -v l_aux "%s%sNeoVIM%s %sdeveloper%s" "$l_aux" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
            else
                printf -v l_aux "%s%sNeoVIM%s %seditor%s" "$l_aux" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
            fi
        fi

        printf -v l_title "Instalando programas requeridos para %s" "$l_aux"


        print_line '─' $g_max_length_line  "$g_color_opaque"
        print_text_in_center2 "$l_title" $g_max_length_line 
        print_line '─' $g_max_length_line "$g_color_opaque"

    fi

    #4. Configurar VIM 
    if [ $l_flag_config_vim -eq 0 ]; then
        _config_vim $p_opciones $l_flag_developer_vim 
    fi

    #5. Configurar NeoVIM 
    if [ $l_flag_config_nvim -eq 0 ]; then
        _config_nvim $p_opciones $l_flag_developer_nvim $l_flag_developer_nvim
    fi

    return 0


}

#Instalar RTE Node.JS y sus paquetes requeridos para habilitar VIM en modo 'Developer'.
#Si se usa NeoVIM en modo 'Developer', se instalara paquetes adicionales.
#Parametros de entrada:
#  1> Flag para configurar NeoVIM como Developer (si es '0')
_install_nodejs() {

    #0. Argumentos
    local p_flag_developer_nvim=1
    if [ "$1" = "0" ]; then
        p_flag_developer_nvim=0
    fi

    #1. Instalación de Node.JS (el gestor de paquetes npm esta incluido)

    #Validar si 'node' esta en el PATH
    echo "$PATH" | grep "${g_path_programs_lnx}/nodejs/bin" &> /dev/null
    l_status=$?
    if [ $l_status -ne 0 ]; then
        printf '%bNode.JS %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
            "$g_color_warning" "$l_version" "$g_color_reset"
        printf 'Adicionando a la sesion actual: PATH=%s/nodejs/bin:$PATH\n' "${g_path_programs_lnx}"
        export PATH=${g_path_programs_lnx}/nodejs/bin:$PATH
    fi

    #Obtener la version de Node.JS actual
    local l_version=$(node -v 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        l_version=""
    fi

    #Si no esta instalado
    if [ -z "$l_version" ]; then

        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        echo "VIM (IDE)   > Se va instalar el scripts NVM y con ello se instalar RTE Node.JS"

        #Instalando NodeJS

        #Parametros:
        # 1> Tipo de ejecución: 2 (ejecución no-interactiva para instalar/actualizar un respositorio especifico)
        # 2> Repositorio a instalar/acutalizar: "nodejs" (actualizar solo los comandos instalados)
        # 3> El estado de la credencial almacenada para el sudo
        ~/.files/setup/linux/01_setup_commands.bash 2 "nodejs" $g_status_crendential_storage
        l_status=$?

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
           g_status_crendential_storage=0
        fi

        #Validar si 'node' esta en el PATH
        echo "$PATH" | grep "${g_path_programs_lnx}/nodejs/bin" &> /dev/null
        l_status=$?
        if [ $l_status -ne 0 ]; then
            export PATH=${g_path_programs_lnx}/nodejs/bin:$PATH
        fi

        #Obtener la version instalada
        l_version=$(node -v 2> /dev/null)
        l_status=$?
        if [ $l_status -eq 0 ]; then
            printf 'Se instaló la Node.JS version %s\n' "$l_version"
        else
            printf 'Ocurrio un error en la instalacion de Node.JS "%s"\n' "$l_version"
        fi

    #Si esta instalado
    else
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        echo "VIM (IDE)   > Node.JS \"$l_version\" ya esta instalado"
    fi

    #2. Instalación de Herramienta Prettier para formateo de archivos como json, yaml, js, ...
    l_version=$(prettier --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then

        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 

        echo "VIM (IDE)   > Instalando el comando 'prettier' (como paquete global Node.JS)  para formatear archivos json, yaml, js, ..."

        #Se instalara a nivel glabal (puede ser usado por todos los usuarios)
        npm install -g --save-dev prettier

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "VIM (IDE)   > Comando 'prettier' (paquete global Node.JS) \"$l_version\" ya esta instalado"
        echo "              Si usa JS o TS, se recomienda instalar de manera local los paquetes Node.JS para Linter EsLint:"
        echo "                 > npm install --save-dev eslint"
        echo "                 > npm install --save-dev eslint-plugin-prettier"
    fi



    #3. Node.JS> Instalando paquete requeridos por NeoVIM
    local l_temp
    if [ $p_flag_developer_nvim -eq 0 ]; then

        l_temp=$(npm list -g --depth=0 2> /dev/null) 
        l_status=$?
        if [ $l_status -ne 0 ]; then           
           echo "ERROR: No esta instalado correctamente NodeJS. No se encuentra el gestor de paquetes 'npm'."
        else

            #Obtener la version
            if [ -z "$l_temp" ]; then
                l_version="" 
            else
                l_version=$(echo "$l_temp" | grep neovim)
            fi

            #Paquete Node.JS (a nivel usuario)> Permitir NeoVIM soporte a NeoVIM plugin creados en RTE Node.JS
            if [ -z "$l_version" ]; then

                print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
                echo "NeoVIM (IDE)> Instalando el paquete 'neovim' de Node.JS para soporte de plugins en dicho RTE"

                npm install -g neovim

            else
                l_version=$(echo "$l_version" | head -n 1 )
                l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
                echo "NeoVIM (IDE)> Paquete 'neovim' de Node.JS para soporte de plugins con NeoVIM, ya esta instalado: versión \"${l_version}\""
            fi
        fi

    fi


}


#Instalar RTE Python3 y sus paquetes requeridos para habilitar VIM en modo 'Developer'.
#Si se usa NeoVIM en modo 'Developer', se instalara paquetes adicionales.
#Parametros de entrada:
#  1> Flag para configurar NeoVIM como Developer (si es '0')
_install_python() {

    #0. Argumentos
    local p_flag_developer_nvim=1
    if [ "$1" = "0" ]; then
        p_flag_developer_nvim=0
    fi


    #1. Instalación de Python3 y el modulo 'pip' (gestor de paquetes)
    l_version=$(python3 --version 2> /dev/null)
    l_status=$?

    l_version2=$(python3 -m pip --version 2> /dev/null)
    l_status2=$?

    if [ $l_status -ne 0 ] || [ $l_status2 -ne 0 ]; then

        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        echo "VIM (IDE)   > Se va instalar RTE Python3 y su gestor de paquetes Pip"


        #Parametros:
        # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
        # 2> Repositorios a instalar/acutalizar: 4 (RTE Python y Pip)
        # 3> El estado de la credencial almacenada para el sudo
        ~/.files/setup/linux/03_setup_packages.bash 1 4 $g_status_crendential_storage
        l_status=$?

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
           g_status_crendential_storage=0
        fi

    fi

    l_version=$(python3 --version 2> /dev/null)
    l_status=$?
    if [ $l_status -eq 0 ]; then
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        echo "VIM (IDE)   > Python3 \"$l_version\" esta instalado"
    fi

    l_version=$(python3 -m pip --version 2> /dev/null)
    l_status=$?
    if [ $l_status -eq 0 ]; then

        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        echo "VIM (IDE)   > Comando 'pip' (modulo python) \"$l_version\" ya esta instalado"
    fi


    #2. Instalación de Herramienta para mostrar arreglo json al formato tabular
    l_version=$(pip3 list | grep jtbl 2> /dev/null)
    #l_version=$(jtbl -v 2> /dev/null)
    l_status=$?
    #if [ $l_status -ne 0 ]; then
    if [ -z "$l_version" ]; then

        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        echo "General     > Instalando el comando 'jtbl' (modulo python) para mostrar arreglos json en una consola en formato tabular."
        
        #Se instalar a nivel usuario
        pip3 install jtbl

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "General     > Comando 'jtbl' (modulo python) \"$l_version\" ya esta instalado"
    fi

    #3. Instalación de Herramienta para generar la base de compilacion de Clang desde un make file
    l_version=$(pip3 list | grep compiledb 2> /dev/null)
    #l_version=$(compiledb -h 2> /dev/null)
    l_status=$?
    #if [ $l_status -ne 0 ] || [ -z "$l_version"]; then
    if [ -z "$l_version" ]; then

        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        echo "General     > Instalando el comando 'compiledb' (modulo python) para generar una base de datos de compilacion Clang desde un make file."
        
        #Se instalar a nivel usuario
        pip3 install compiledb

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "General     > Comando 'compiladb' (modulo python) \"$l_version\" ya esta instalado"
        #echo "Tools> 'compiledb' ya esta instalado"
    fi

    #4. Instalación de la libreria de refactorización de Python (https://github.com/python-rope/rope)
    l_version=$(pip3 list | grep rope 2> /dev/null)
    l_status=$?
    if [ -z "$l_version" ]; then

        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        echo "General     > Instalando la libreria python 'rope' para refactorización de Python (https://github.com/python-rope/rope)."
        
        #Se instalara a nivel usuario
        pip3 install rope

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "General     > Libreria 'rope' (modulo python) \"$l_version\" ya esta instalado"
        #echo "Tools> 'compiledb' ya esta instalado"
    fi

    #5. Instalando paquete requeridos por NeoVIM
    if [ $p_flag_developer_nvim -eq 0 ]; then

        #Paquete 'PyNVim' para crear plugins NeoVIM usando RTE Python
        l_version=$(pip3 list | grep pynvim 2> /dev/null)
        l_status=$?
        if [ -z "$l_version" ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "NeoVIM (IDE)> Instalando el paquete 'pynvim' de Python3 para soporte de plugins en dicho RTE"
            
            #Se instalara a nivel usuario
            pip3 install pynvim

        else
            l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
            echo "NeoVIM (IDE)> Libreria 'pynvim' (modulo python) \"$l_version\" ya esta instalado"
            #echo "Tools> 'pynvim' ya esta instalado"
        fi
    fi



}


# Parametros:
# > Opcion ingresada por el usuario.
function _install_vim_nvim_environment() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #2. Determinar si se requiere instalar VIM/NeoVIM
    local l_flag_install_vim=1
    local l_flag_install_nvim=1

    local l_option=8
    local l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_install_vim=0; fi
    
    l_option=64
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_install_nvim=0; fi

    #Si no se solicitar instalar VIM o NeoVIM no instalar ningun comando
    if [ $l_flag_install_vim -ne 0 ] && [ $l_flag_install_nvim -ne 0 ]; then
        return 99
    fi
   
    #¿Se requiere instalar en modo developer?
    local l_flag_developer_vim=1
    local l_flag_developer_nvim=1

    local l_option=32
    local l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_developer_vim=0; fi
    
    l_option=256
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_developer_nvim=0; fi


    #3. Mostrar el titulo de instalacion
    local l_title
    local l_aux=""

    if [ $l_flag_install_vim -eq 0 ]; then
        if [ $l_flag_developer_vim -eq 0 ]; then
            printf -v l_aux "%sVIM%s %sdeveloper%s" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
        else
            printf -v l_aux "%sVIM%s %seditor%s" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
        fi
    fi

    if [ $l_flag_install_nvim -eq 0 ]; then
        if [ ! -z "$l_aux" ]; then
            l_aux="${l_aux} y "
        fi
        if [ $l_flag_developer_vim -eq 0 ]; then
            printf -v l_aux "%s%sNeoVIM%s %sdeveloper%s" "$l_aux" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
        else
            printf -v l_aux "%s%sNeoVIM%s %seditor%s" "$l_aux" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
        fi
    fi

    printf -v l_title "Instalando programas requeridos para %s" "$l_aux"


    print_line '─' $g_max_length_line  "$g_color_opaque"
    print_text_in_center2 "$l_title" $g_max_length_line 
    print_line '─' $g_max_length_line "$g_color_opaque"


    #4. Para developer: Instalar utilitarios para gestion de "clipbboard" (X11 Selection): XClip, XSel
    local l_version
    local l_version2
    local l_status
    local l_status2

    if [ $l_flag_developer_vim -eq 0 ] || [ $l_flag_developer_nvim -eq 0 ]; then

        #echo "> Instalando los comandos/programas basicos requeridos ..."

        l_version=$(xclip -version 2>&1 1> /dev/null)
        l_status=$?
        
        l_version2=$(xsel --version 2> /dev/null)
        l_status2=$?

        if [ $l_status -ne 0 ] || [ $l_status2 -ne 0 ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "General     > Se va instalar comandos para gestion de X11 Clipboard: XClip, XSel"

            #Parametros:
            # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
            # 2> Repositorios a instalar/acutalizar: 4 (herramienta de X11 clipbboard)
            # 3> El estado de la credencial almacenada para el sudo
            ~/.files/setup/linux/03_setup_packages.bash 1 4 $g_status_crendential_storage
            l_status=$?

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
               g_status_crendential_storage=0
            fi

        fi

        l_version=$(xclip -version 2>&1 1> /dev/null)
        l_status=$?
        if [ $l_status -eq 0 ]; then
            l_version=$(echo "$l_version" | head -n 1 )
            l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
            echo "General     > XClip \"${l_version}\" esta instalado"
        fi

        l_version=$(xsel --version 2> /dev/null)
        l_status=$?
        if [ $l_status -eq 0 ]; then
            l_version=$(echo "$l_version" | head -n 1 )
            l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
            echo "General     > XSel \"${l_version}\" esta instalado"
        fi

    fi

    #5. Si se requiere VIM como IDE, usara CoC, por lo que requiere: Node.JS y Python
    if [ $l_flag_install_vim -eq 0 ] && [ $l_flag_developer_vim -eq 0 ]; then

        #5.1 Instalación de Node.JS (el gestor de paquetes npm esta incluido)
        _install_nodejs $l_flag_developer_nvim
        l_status=$?

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        fi

        #5.2 Instalación de Python3 y el modulo 'pip' (gestor de paquetes)
        _install_python $l_flag_developer_nvim
        l_status=$?

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        fi
    fi


    #6. Instalar VIM
    
    #Determinar si esta instalado VIM
    l_version=$(vim --version 2> /dev/null)
    l_status=$?
    if [ $l_status -eq 0 ]; then
        l_version=$(echo "$l_version" | head -n 1)
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    else
        l_version=""
    fi

    #Instalar
    if [ $l_flag_install_vim -eq 0 ]; then

        #print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        if [ -z "$l_version" ]; then

            #Solicitar credenciales de administrador y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq -1 ]; then

                storage_sudo_credencial
                g_status_crendential_storage=$?

                if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                    return 120
                fi
            fi

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            #echo "- Instalación de VIM-Enhaced"
            echo "VIM         > Se va instalar VIM-Enhaced"

            case "$g_os_subtype_id" in
                1)
                   #Distribución: Ubuntu
                   if [ $g_is_root -eq 0 ]; then
                      apt-get install vim
                   else
                      sudo apt-get install vim
                   fi
                   ;;
                2)
                   #Distribución: Fedora
                   if [ $g_is_root -eq 0 ]; then
                      dnf install vim-enhanced
                   else
                      sudo dnf install vim-enhanced
                   fi
                   ;;
            esac
            l_vim_flag=0
        else
            echo "VIM         > VIM-Enhaced \"${l_version}\" ya esta instalado"
        fi

    fi

    #7. Instalar NeoVIM

    #Validar si 'nvim' esta en el PATH
    echo "$PATH" | grep "${g_path_programs_lnx}/neovim/bin" &> /dev/null
    l_status=$?
    if [ $l_status -ne 0 ]; then
        printf '%bNode.JS %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
            "$g_color_warning" "$l_version" "$g_color_reset"
        printf 'Adicionando a la sesion actual: PATH=%s/neovim/bin:$PATH\n' "${g_path_programs_lnx}"
        export PATH=${g_path_programs_lnx}/neovim/bin:$PATH
    fi

    #Determinar si esta instalado VIM:
    l_version=$(nvim --version 2> /dev/null)
    l_status=$?
    if [ $l_status -eq 0 ]; then
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
    else
        l_version=""
    fi

    #Instalar
    if [ $l_flag_install_nvim -eq 0 ]; then

        if [ -z "$l_version" ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "NeoVIM      > Se va instalar NeoVIM"

            #Parametros:
            # 1> Tipo de ejecución: 2 (ejecución no-interactiva para instalar/actualizar un respositorio especifico)
            # 2> Repsositorio a instalar/acutalizar: "neovim" (actualizar solo los comandos instalados)
            # 3> El estado de la credencial almacenada para el sudo
            ~/.files/setup/linux/01_setup_commands.bash 2 "neovim" $g_status_crendential_storage            
            l_status=$?

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
               g_status_crendential_storage=0
            fi

            #Validar si 'nvim' esta en el PATH
            echo "$PATH" | grep "${g_path_programs_lnx}/neovim/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                export PATH=${g_path_programs_lnx}/neovim/bin:$PATH
            fi

            #Obtener la version instalada
            l_version=$(node -v 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                printf 'Se instaló la Node.JS version %s\n' "$l_version"
            else
                printf 'Ocurrio un error en la instalacion de Node.JS "%s"\n' "$l_version"
            fi

        else
            echo "NeoVIM      > NeoVIM '$l_version' esta instalado. Si desea actualizarlo a la ultima version, use:"
            echo "               > '~/.files/setup/linux/01_setup_commands.bash'"
            echo "               > '~/.files/setup/linux/04_update_all.bash'"
        fi
    fi

}


# Parametros:
# > Opcion ingresada por el usuario.
function _setup_profile() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #¿Esta habilitado la creacion de enlaces simbolicos del perfil?
    local l_option=2
    local l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -ne $l_option ]; then
        return 99 
    fi

    #¿Se puede recrear los enlaces simbolicos en caso existir?
    local l_option=4
    local l_flag=$(( $p_opciones & $l_option ))
    local l_overwrite_ln_flag=1
    if [ $l_flag -eq $l_option ]; then l_overwrite_ln_flag=0; fi


    #2. Mostrar el titulo 
    print_line '─' $g_max_length_line  "$g_color_opaque"

    if [ $l_overwrite_ln_flag -eq 0 ]; then
        printf -v l_title "Creando los %senlaces simbolicos%s del perfil %s(sobrescribir lo existente)%s" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    else
        printf -v l_title "Creando los %senlaces simbolicos%s del perfil %s(solo crar si no existe)%s" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    fi
    print_text_in_center2 "$l_title" $g_max_length_line 
    print_line '─' $g_max_length_line "$g_color_opaque"

    
     #if [ ! -d /u01/userkeys/ssh ]; then

     #    echo "Permiso ejecucion de shell y los folderes basicos \"/u01/userkeys/ssh\""
     #    chmod u+x ~/.files/terminal/linux/tmux/*.bash
     #    chmod u+x ~/.files/terminal/linux/complete/*.bash
     #    chmod u+x ~/.files/terminal/linux/keybindings/*.bash
     #    chmod u+x ~/.files/setup/linux/0*.bash
     #
     #    if [ $g_is_root -eq 0 ]; then
     #        mkdir -pm 755 /u01
     #        mkdir -pm 755 /u01/userkeys
     #        mkdir -pm 755 /u01/userkeys/ssh
     #        chown -R lucianoepc:lucianoepc /u01/userkeys
     #    else
     #        sudo mkdir -pm 755 /u01
     #        sudo mkdir -pm 755 /u01/userkeys
     #        sudo chown lucianoepc:lucianoepc /u01/userkeys
     #        mkdir -pm 755 /u01/userkeys/ssh
     #    fi
     #fi


    #Si es Linux WSL
    local l_link=""
    local l_object=""
    local l_aux
    if [ $g_os_type -eq 1 ]; then

        l_link='/.dircolors'
        l_object='/.files/terminal/linux/profile/ubuntu_wls_dircolors.conf'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi

        l_link='/.gitconfig'
        l_object='/.files/config/git/wsl2_git.toml'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


        l_link='/.ssh/config'
        l_object='/.files/config/ssh/wsl2_ssh.conf'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


        l_link='/.config/powershell/Microsoft.PowerShell_profile.ps1'
        l_object='/.files/terminal/powershell/profile/ubuntu_wsl.ps1'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                mkdir -p ~/.config/powershell/
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            mkdir -p ~/.config/powershell/
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


        l_link='/.bashrc'
        l_object='/.files/terminal/linux/profile/ubuntu_wls.bash'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


    #Si es un Linux generico (NO WSL)
    else

        l_link='/.gitconfig'
        l_object='/.files/config/git/vm_linux_git.toml'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


        l_link='/.ssh/config'
        l_object='/.files/config/ssh/vm_linux_ssh.conf'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


        l_link='/.config/powershell/Microsoft.PowerShell_profile.ps1'
        l_object='/.files/terminal/powershell/profile/fedora_vm.ps1'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                mkdir -p ~/.config/powershell/
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            mkdir -p ~/.config/powershell/
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi


        l_link='/.bashrc'
        l_object='/.files/terminal/linux/profile/fedora_vm.bash'
        if [ -e ${HOME}${l_link} ]; then
            if [ $l_overwrite_ln_flag -eq 0 ]; then
                ln -snf ${HOME}${l_object} ${HOME}${l_link}
                printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
            else
                l_aux=$(readlink ${HOME}${l_link})
                printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
            fi
        else
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        fi

    fi

    #8.2 Creando enlaces simbolico independiente del tipo de distribución Linux

    #Crear el enlace de TMUX
    l_link='/.tmux.conf'
    l_object='/.files/terminal/linux/tmux/tmux.conf'
    if [ -e ${HOME}${l_link} ]; then
        if [ $l_overwrite_ln_flag -eq 0 ]; then
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        else
            l_aux=$(readlink ${HOME}${l_link})
            printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
        fi
    else
        ln -snf ${HOME}${l_object} ${HOME}${l_link}
        printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
    fi

    #Configuración de un CLI de alto nivel del 'Container Runtime' 'ContainerD': nerdctl
    l_link='/.config/nerdctl/nerdctl.toml'
    l_object='/.files/config/nerdctl/default_config.toml'
    if [ -e ${HOME}${l_link} ]; then
        if [ $l_overwrite_ln_flag -eq 0 ]; then
            mkdir -p ~/.config/nerdctl/
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        else
            l_aux=$(readlink ${HOME}${l_link})
            printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
        fi
    else
        mkdir -p ~/.config/nerdctl/
        ln -snf ${HOME}${l_object} ${HOME}${l_link}
        printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
    fi


    #Configuración principal de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless'): Podman
    l_link='/.config/containers/containers.conf'
    l_object='/.files/config/podman/default_config.toml'
    if [ -e ${HOME}${l_link} ]; then
        if [ $l_overwrite_ln_flag -eq 0 ]; then
            mkdir -p ~/.config/containers/ 
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        else
            l_aux=$(readlink ${HOME}${l_link})
            printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
        fi
    else
        mkdir -p 
        ln -snf ${HOME}${l_object} ${HOME}${l_link}
        printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
    fi

    #Configuración de los registros de imagenes de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless'): Podman
    l_link='/.config/containers/registries.conf'
    l_object='/.files/config/podman/default_registries.toml'
    if [ -e ${HOME}${l_link} ]; then
        if [ $l_overwrite_ln_flag -eq 0 ]; then
            mkdir -p ~/.config/containers/ 
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        else
            l_aux=$(readlink ${HOME}${l_link})
            printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
        fi
    else
        mkdir -p ~/.config/containers/ 
        ln -snf ${HOME}${l_object} ${HOME}${l_link}
        printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
    fi


    #Configuración de un 'Container Runtime' 'ContainerD' (en modo 'rootless')
    l_link='/.config/containerd/config.toml'
    l_object='/.files/config/containerd/default_config.toml'
    if [ -e ${HOME}${l_link} ]; then
        if [ $l_overwrite_ln_flag -eq 0 ]; then
            mkdir -p ~/.config/containerd/
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        else
            l_aux=$(readlink ${HOME}${l_link})
            printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
        fi
    else
        mkdir -p ~/.config/containerd/
        ln -snf ${HOME}${l_object} ${HOME}${l_link}
        printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
    fi




    #Configuración del backend de compilacion de imagenes 'BuildKit' (en modo 'rootless')
    l_link='/.config/buildkit/buildkitd.toml'
    l_object='/.files/config/buildkit/default_config.toml'
    if [ -e ${HOME}${l_link} ]; then
        if [ $l_overwrite_ln_flag -eq 0 ]; then
            mkdir -p ~/.config/buildkit/
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        else
            l_aux=$(readlink ${HOME}${l_link})
            printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
        fi
    else
        mkdir -p ~/.config/buildkit/
        ln -snf ${HOME}${l_object} ${HOME}${l_link}
        printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
    fi


    #Configuracion por defecto para un Cluster de Kubernates
    l_link='/.kube/config'
    l_object='/.files/config/kubectl/default_config.yaml'
    if [ -e ${HOME}${l_link} ]; then
        if [ $l_overwrite_ln_flag -eq 0 ]; then
            mkdir -p ~/.kube/
            ln -snf ${HOME}${l_object} ${HOME}${l_link}
            printf "El enlace simbolico '~%s' se ha re-creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
        else
            l_aux=$(readlink ${HOME}${l_link})
            printf "El enlace simbolico '~%s' ya existe %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
        fi
    else
        mkdir -p ~/.kube/
        ln -snf ${HOME}${l_object} ${HOME}${l_link}
        printf "El enlace simbolico '~%s' se ha creado %b(ruta real '~%s')%b\n" "$l_link" "$g_color_opaque" "$l_object" "$g_color_reset"
    fi

    return 0

}



# Remover el gestor de paquetes VIM-Plug en VIM y NeoVIM
function _remove_vim_plug() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #Eliminar en VIM
    local l_option=512
    local l_flag=$(( $p_opciones & $l_option ))

    local l_flag_removed=1
    if [ $l_flag -eq $l_option ]; then

        #echo "> Eliminado el gestor 'VIM-Plug' de VIM..."
        if [ -f ~/.vim/autoload/plug.vim ]; then
            echo "Eliminado '~/.vim/autoload/plug.vim' ..."
            rm ~/.vim/autoload/plug.vim
            l_flag_removed=0
        fi

        if [ -d ~/.vim/plugged/ ]; then
            echo "Eliminado el folder '~/.vim/plugged/' ..."
            rm -rf ~/.vim/plugged/
            l_flag_removed=0
        fi

        if [ $l_flag_removed -ne 0 ]; then
            printf 'No esta instalado el gestor de paquetes "VIM-Plug" en VIM\n'
        fi

    fi


    #Eliminar en NeoVIM
    l_option=1024
    l_flag=$(( $p_opciones & $l_option ))

    l_flag_removed=1
    if [ $l_flag -eq $l_option ]; then

        #echo "> Eliminado el gestor 'VIM-Plug' de NeoVIM..."
        if [ -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
            echo "Eliminado '~/.local/share/nvim/site/autoload/plug.vim' ..."
            rm ~/.local/share/nvim/site/autoload/plug.vim
            l_flag_removed=0
        fi

        if [ -d ~/.local/share/nvim/plugged/ ]; then
            echo "Eliminado el folder '~/.local/share/nvim/plugged/' ..."
            rm -rf ~/.local/share/nvim/plugged/
            l_flag_removed=0
        fi

        if [ $l_flag_removed -ne 0 ]; then
            printf 'No esta instalado el gestor de paquetes "VIM-Plug" en NeoVIM\n'
        fi

    fi

}




# Opciones:
#   (  1) Actualizar los paquetes del SO 
#   (  2) Crear los enlaces simbolicos (siempre se ejecutara)
#   (  8) Forzar el actualizado de los enlaces simbolicos del profile
function _setup() {

    #01. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi
    
    g_status_crendential_storage=-1
    local l_status

    #03. Actualizar los paquetes de los repositorios
    local l_title
    local l_option=1
    local l_flag=$(( $p_opciones & $l_option ))

    if [ $l_flag -eq $l_option ]; then

        #Solicitar credenciales de administrador y almacenarlas temporalmente
        storage_sudo_credencial
        g_status_crendential_storage=$?
        #Se requiere almacenar las credenciales para realizar cambiso con sudo.
        if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
            return 120
        fi
        
        #Actualizar los paquetes de los repositorios
        print_line '─' $g_max_length_line  "$g_color_opaque"
        printf -v l_title "Actualizar los paquetes del SO '%s%s %s%s'" "$g_color_subtitle" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
        print_text_in_center2 "$l_title" $g_max_length_line 
        print_line '─' $g_max_length_line "$g_color_opaque"
       
        upgrade_os_packages $g_os_subtype_id 

    fi   
    
    #05. Instalando los programas requeridos para usar VIM/NeoVIM
    local l_flag_title=1
    _install_vim_nvim_environment $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    #Si se completo la precondiciones
    elif [ $l_status -ne 99 ]; then
        l_flag_title=0
    fi

    #echo "status ${l_status}, opciones ${p_opciones}"

    #06. Configurando VIM/NeoVIM 
    _config_vim_nvim $p_opciones $l_flag_title
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    fi

    #07. Configuracion el SO: Crear enlaces simbolicos y folderes basicos
    _setup_profile $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    fi

    #08. Eliminar el gestor 'VIM-Plug'
    _remove_vim_plug $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    fi

    #09. Caducar las credecinales de root almacenadas temporalmente
    if [ $g_status_crendential_storage -eq 0 ]; then
        clean_sudo_credencial
    fi

}


function _show_menu_core() {


    print_text_in_center "Menu de Opciones" $g_max_length_line "$g_color_title"
    print_line '-' $g_max_length_line  "$g_color_opaque"
    printf " (%bq%b) Salir del menu\n" "$g_color_title" "$g_color_reset"
    printf " (%ba%b) Instalación y configuración de VIM/NeoVIM como %beditor%b basico\n" "$g_color_title" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf " (%bb%b) Instalación y configuración de VIM/NeoVIM como %bIDE%b\n" "$g_color_title" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf " (%bc%b) Configurar todo el profile como %bbasico%b    (VIM/NeoVIM como editor basico)\n" "$g_color_title" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf " (%bd%b) Configurar todo el profile como %bdeveloper%b (VIM/NeoVIM como IDE)\n" "$g_color_title" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf " (%be%b) Configurar todo el profile como %bbasico%b    (VIM/NeovIM como editor basico) y re-crear enlaces simbolicos\n" "$g_color_title" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf " (%bf%b) Configurar todo el profile como %bdeveloper%b (VIM/NeoVIM como IDE) y re-crear enlaces simbolicos\n" "$g_color_title" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    local l_max_digits=4

    printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes del SO\n" "$g_color_title" "1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Crear los enlaces simbolicos del profile\n" "$g_color_title" "2" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Flag para %bre-crear%b un enlaces simbolicos en caso de existir\n" "$g_color_title" "4" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) VIM    - Instalar   %b(si desea un IDE use 'Flag habilitar como IDE')%b\n" "$g_color_title" "8" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) VIM    - Configurar %b(si desea un IDE use 'Flag habilitar como IDE')%b\n" "$g_color_title" "16" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) VIM    - Flag para habilitarlo como %bIDE%b\n" "$g_color_title" "32" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Instalar   %b(si desea un IDE use 'Flag habitilar como IDE')%b\n" "$g_color_title" "64" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Configurar %b(si desea un IDE use 'Flag habitilar como IDE')%b\n" "$g_color_title" "128" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Flag para habilitarlo como %bIDE%b\n" "$g_color_title" "256" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) VIM    - Eliminar el gestor de paquetes 'VIM-Plug'\n" "$g_color_title" "512" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Eliminar el gestor de paquetes 'VIM-Plug'\n" "$g_color_title" "1024" "$g_color_reset"

    print_line '-' $g_max_length_line "$g_color_opaque"

}

function g_main() {

    #1. Pre-requisitos
    
    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_title" 
    _show_menu_core
    
    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_opaque" "$g_color_reset"
        read -r l_options

        case "$l_options" in
            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                #8 + 16 + 64 + 128
                _setup 216
                ;;


            b)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                #8 + 16 + 32 + 64 + 128 + 256
                _setup 504
                ;;

            c)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                #8 + 16 + 64 + 128 + 2
                _setup 218
                ;;

            d)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                #8 + 16 + 32 + 64 + 128 + 256 + 2
                _setup 506
                ;;

            e)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                #8 + 16 + 64 + 128 + 2 + 4
                _setup 222
                ;;

            f)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                #8 + 16 + 32 + 64 + 128 + 256 + 2 + 4
                _setup 510
                ;;

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_title" 
                    printf '\n'
                    _setup $l_options
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_opaque" 
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_opaque" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_opaque" 
                ;;
        esac
        
    done

}


#1. Logica principal del script (incluyendo los argumentos variables)
_g_status=0

#Validar los requisitos (0 debido a que siempre se ejecuta de modo interactivo)
fulfill_preconditions1 $g_os_type 0
_g_status=$?

#Iniciar el procesamiento
if [ $_g_status -eq 0 ]; then
    g_main
fi




