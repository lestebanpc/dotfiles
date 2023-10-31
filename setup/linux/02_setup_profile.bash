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

#Expresion regular para extrear la versión de un programa
declare -r g_regexp_version1='s/[^0-9]*\([0-9]\+\.[0-9.]\+\).*/\1/'

#Variable global de la ruta donde se instalaran los programas CLI (mas complejos que un simple comando).
declare -r g_path_lnx_programs='/opt/tools'
#declare -r g_path_lnx_programs=~/tools


#Colores principales usados para presentar información (menu,...)
g_color_opaque="\x1b[90m"
g_color_reset="\x1b[0m"
g_color_title="\x1b[32m"
g_color_subtitle="\x1b[36m"
g_color_warning="\x1b[31m"

#Tamaño de la linea del menu
g_max_length_line=130

#Estado del almacenado temporalmente de las credenciales para sudo
# -1 - No se solicito el almacenamiento de las credenciales
#  0 - No es root: se almaceno las credenciales
#  1 - No es root: no se pudo almacenar las credenciales.
#  2 - Es root: no requiere realizar sudo.
g_status_crendential_storage=-1

#}}}

# Parametros:
# > Opcion:
#    0 - Se configura VIM en modo basico (por defecto)
#    1 - Se configura VIM en modo IDE
function _neovim_config_plugins() {

    #1. Argumentos
    local p_opcion=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opcion=$1
    fi

    local path_data=~/.local/share

    #2. Instalar el gestor de plugin/paquetes 'Vim-Plug' (no se usara este gestor)
    #echo "Instalar el gestor de paquetes Vim-Plug"
    #if [ ! -f ${path_data}/nvim/site/autoload/plug.vim ]; then
    #    mkdir -p ${path_data}/nvim/site/autoload
    #    curl -fLo ${path_data}/nvim/site/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    #fi
    
    #3. Instalar el gestor de paquetes 'Packer' (cambiarlo por lazy)
    local l_base_path="${path_data}/nvim/site/pack/packer/start"
    mkdir -p $l_base_path
    cd ${l_base_path}

    local l_repo_name="packer.nvim"
    local l_repo_git="wbthomason/${l_repo_name}"
    if [ ! -d ${l_base_path}/${l_repo_name}/.git ]; then
        #print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
        echo "Instalando el paquete NeoVim \"${l_repo_git}\""
        #print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
        git clone --depth 1 https://github.com/${l_repo_git}.git
    else
        #print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
        echo "Paquete VIM \"${l_repo_git}\" ya esta instalado"
    fi

    #3. Instalar el gestor de paquetes 'Lazy'

    #4. Actualizar los paquetes/plugin de NeoVim
    #echo 'Instalando los plugins "Vim-Plug" de NeoVIM, ejecutando el comando ":PlugInstall"'
    #nvim --headless -c 'PlugInstall' -c 'qa'

    echo 'Instalando los plugins "Packer" de NeoVIM, ejecutando el comando ":PackerInstall"'
    nvim --headless -c 'PackerInstall' -c 'qa'

    #echo 'Actualizando los plugins "Vim-Plug" de NeoVIM, ejecutando el comando ":PlugUpdate"'
    #nvim --headless -c 'PlugUpdate' -c 'qa'

    echo 'Actualizando los plugins "Packer" de NeoVIM, ejecutando el comando ":PackerUpdate"'
    nvim --headless -c 'PackerUpdate' -c 'qa'

    if [ $p_opcion -eq 1 ]; then


        printf '  Se ha instalado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "NeoVIM" "$g_color_reset" "$g_color_subtitle" "Developer" "$g_color_reset"
        printf 'Configurando los plugins usados para el IDE CoC ...\n' 

        #Instalando extensiones basicos de CoC: Adaptador de LSP server basicos JS, Json, HTLML, CSS, Python, Bash
        printf '  Instalando extensiones de CoC (Adaptador de LSP server basicos) ":CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh"\n'
        USE_COC=1 nvim --headless -c 'CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh' -c 'qa'

        #Instalando extensiones basicos de CoC: Motor de snippets 'UtilSnips'
        printf '  Instalando extensiones de CoC (Motor de snippets "UtilSnips") ":CocInstall coc-ultisnips" (no se esta usando el nativo de CoC)\n'
        USE_COC=1 nvim --headless -c 'CocInstall coc-update' -c 'qa'

        #Instalando los gadgets basicos de 'VimSpector'
        #printf '  Actualizando los gadgets de "VimSpector", ejecutando el comando ":VimspectorUpdate"\n'
        #USE_COC=1 nvim --headless -c 'VimspectorUpdate' -c 'qa'

        #Actualizar las extensiones de CoC
        printf '  Actualizando los extensiones existentes de CoC, ejecutando el comando ":CocUpdate"\n'
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

        printf '  Se ha instalado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "NeoVIM" "$g_color_reset" "$g_color_subtitle" "Editor" "$g_color_reset"
    fi

    return 0
}

# Parametros:
# > Opcion ingresada por el usuario.
function _neovim_setup() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #Sobrescribir los enlaces simbolicos
    local l_option=64
    local l_flag=$(( $p_opciones & $l_option ))
    local l_overwrite_ln_flag=1
    if [ $l_flag -eq $l_option ]; then l_overwrite_ln_flag=0; fi

    #2. Determinando la version actual de NeoVim
    local l_version=""
    l_version=$(/opt/tools/neovim/bin/nvim --version 2> /dev/null)
    local l_status=$?
    local l_nvim_flag=1
    if [ $l_status -eq 0 ]; then
        l_version=$(echo "$l_version" | head -n 1)
        l_version=$(echo "$l_version" | sed "$g_regexp_version1")
        l_nvim_flag=0
    else
        l_version=""
    fi

    local l_flag_title=1

    #3. Instalando NeoVim
    l_option=64
    l_flag=$(( $p_opciones & $l_option ))

    if [ $l_flag -eq $l_option ]; then

        if [ $l_flag_title -ne 0 ]; then
            print_line '-' $g_max_length_line "$g_color_opaque" 
            echo "> Configuración de NeoVIM"
            print_line '-' $g_max_length_line "$g_color_opaque" 
            l_flag_title=0
        fi

        #print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        if [ $l_nvim_flag -ne 0 ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            #echo "- Instalación de NeoVIM"
            echo "Se va instalar NeoVIM"

            #Parametros:
            # 1> Tipo de ejecución: 2 (ejecución no-interactiva para instalar/actualizar un respositorio especifico)
            # 2> Repsositorio a instalar/acutalizar: "neovim" (actualizar solo los comandos instalados)
            # 3> El estado de la credencial almacenada para el sudo
            ~/.files/setup/linux/01_setup_commands.bash 2 "neovim" $g_status_crendential_storage
            l_nvim_flag=0


        else
            echo "NeoVIM \"${l_version}\" esta instalado: "
            echo "   > Si desea actualizar a la ultima version, use: '~/.files/setup/linux/01_setup_commands.bash' o '~/.files/setup/linux/04_update_all.bash'"
        fi
    fi

    
    #5. Configurar NeoVim como IDE (Developer)
    local l_temp=""
    l_option=256
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then

        if [ $l_flag_title -ne 0 ]; then
            print_line '-' $g_max_length_line "$g_color_opaque" 
            echo "> Configuración de NeoVIM"
            print_line '-' $g_max_length_line "$g_color_opaque" 
            l_flag_title=0
        fi
        
        if [ $l_nvim_flag -ne 0 ]; then
            echo "Para configurar NeoVIM debera instalar primero NeoVIM"
            return 1
        fi

        #5.1 Instalando paquete requeridos para usar plugins de Node.JS
        l_temp=$(npm list -g --depth=0 2> /dev/null) 
        l_status=$?
        if [ $l_status -ne 0 ]; then           
           echo "ERROR: No esta instalado correctamente 'npm', se requiere que este configurado correctamente."
        else

            #Obtener la version
            if [ -z "$l_temp" ]; then
                l_version="" 
            else
                l_version=$(echo "$l_temp" | grep neovim)
            fi

            #Instalando si no se obtiene la versión
            if [ -z "$l_version" ]; then

               #Solicitar credenciales de administrador y almacenarlas temporalmente
               if [ $g_status_crendential_storage -eq -1 ]; then

                   storage_sudo_credencial
                   g_status_crendential_storage=$?

                   if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                       return 99
                   fi
               fi

                print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
                echo "Instalando el paquete 'neovim' de Node.JS para soporte de plugins en dicho RTE"

                if [ $g_is_root -eq 0 ]; then
                    npm install -g neovim
                else
                    #sudo npm install -g neovim
                    npm install -g neovim
                fi

            else
                l_version=$(echo "$l_version" | head -n 1 )
                l_version=$(echo "$l_version" | sed "$g_regexp_version1")
                echo "Paquete 'neovim' de Node.JS para soporte de plugins con NeoVIM, ya esta instalado: versión \"${l_version}\""
            fi
        fi

        #5.2 Instalando paquete requeridos para usar plugins de Python3
        l_temp=$(python3 -m pip list 2> /dev/null)
        l_status=$?
        if [ $l_status -ne 0 ]; then           
           echo "ERROR: No esta instalado correctamente 'pip', se requiere que este configurado correctamente."
        else
            
            #Obtener la version
            if [ -z "$l_temp" ]; then
                l_version="" 
            else
                l_version=$(echo "$l_temp" | grep pynvim)
            fi

            #Instalando si no se obtiene la versión
            if [ -z "$l_version" ]; then

                print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
                echo "Instalando el paquete 'pynvim' de Python3 para soporte de plugins en dicho RTE"

                if [ $g_is_root -eq 0 ]; then
                    python3 -m pip install pynvim
                else
                    #sudo python3 -m pip install pynvim
                    python3 -m pip install pynvim
                fi

            else
                l_version=$(echo "$l_version" | head -n 1 )
                l_version=$(echo "$l_version" | sed "$g_regexp_version1")
                echo "Paquete 'pynvim' de Python3 para soporte de plugins con NeoVIM, ya esta instalado: versión \"${l_version}\""
            fi
        fi

        #5.3 Creando enlaces simbolicos
        printf '\n'
        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 

        mkdir -p ~/.config/nvim/

        if [ ! -e ~/.config/nvim/coc-settings.json ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "IDE con CoC> Creando los enlaces simbolico del archivo de Configuración de CoC \"~/.config/nvim/coc-settings.json\""
            ln -sfn ~/.files/nvim/ide_coc/coc-settings_lnx.json ~/.config/nvim/coc-settings.json
        fi

        if [ ! -e ~/.config/nvim/init.vim ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "IDE (CoC y No-CoC)> Creando el enlace del script de inicio \"~/.config/nvim/init.vim\" para usarlos como IDE"
            ln -snf ~/.files/nvim/init_linux_ide.vim ~/.config/nvim/init.vim
        fi

        if [ ! -e ~/.config/nvim/lua ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "Editor o IDE> Creando el enlace de la carpeta \"~/.config/nvim/lua\" por defecto de scripts LUA del usuario"
            ln -snf ~/.files/nvim/lua ~/.config/nvim/lua
        fi

        if [ ! -e ~/.config/nvim/ftplugin ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "IDE (CoC y No-CoC)> Creando el enlace de \"~/.config/nvim/ftplugin\" para el codigo open/close asociado a los 'file types'"
            ln -snf ~/.files/nvim/ide_commom/ftplugin/ ~/.config/nvim/ftplugin
        fi

        if [ ! -d ~/.config/nvim/runtime_coc ]; then
            echo "IDE con CoC> Creando la carpeta \"~/.config/nvim/runtime_coc\" para colocar archivos/folderes especificos de un runtime para CoC"
            mkdir -p ~/.config/nvim/runtime_coc
        fi

        if [ ! -e ~/.config/nvim/runtime_coc/ftplugin ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "IDE con CoC> Creando el enlace de \"~/.config/nvim/runtime_coc/ftplugin\" para el codigo open/close asociado a los 'file types' de CoC"
            ln -snf ~/.files/vim/ide_coc/ftplugin/ ~/.config/nvim/runtime_coc/ftplugin
        fi

        if [ ! -d ~/.config/nvim/runtime_nococ ]; then
            echo "IDE No-CoC> Creando la carpeta \"~/.config/nvim/runtime_nococ\" para colocar archivos/folderes especificos de un runtime que no sean CoC"
            mkdir -p ~/.config/nvim/runtime_nococ
        fi

        if [ ! -e ~/.config/nvim/runtime_nococ/ftplugin ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "IDE No-CoC> Creando el enlace de \"~/.config/nvim/runtime_nococ/ftplugin\" para el codigo open/close asociado a los 'file types' que no sean CoC"
            ln -snf ~/.files/nvim/ide_nococ/ftplugin/ ~/.config/nvim/runtime_nococ/ftplugin
        fi

        #5.4 Instalando paquetes
        _neovim_config_plugins 1


    fi

    #6. Configurar NeoVim como Editor basico 
    l_option=128
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then

        if [ $l_flag_title -ne 0 ]; then
            print_line '-' $g_max_length_line "$g_color_opaque" 
            echo "> Configuración de NeoVIM"
            print_line '-' $g_max_length_line "$g_color_opaque" 
            l_flag_title=0
        fi
        
        if [ $l_nvim_flag -ne 0 ]; then
            echo "Para configurar NeoVIM debera instalar primero NeoVIM"
            return 1
        fi

        #6.1 Creando enlaces simbolicos
        printf '\n'
        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 

        mkdir -p ~/.config/nvim/

        if [ ! -e ~/.config/nvim/init.vim ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "Editor> Creando el enlace del script de inicio \"~/.config/nvim/init.vim\" para usarlo como editor basico"
            ln -snf ~/.files/nvim/init_linux_basic.vim ~/.config/nvim/init.vim
        fi
        
        if [ ! -e ~/.config/nvim/lua ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "Editor o IDE> Creando el enlace de la carpeta \"~/.config/nvim/lua\" por defecto de scripts LUA del usuario"
            ln -snf ~/.files/nvim/lua ~/.config/nvim/lua
        fi

        if [ ! -e ~/.config/nvim/ftplugin ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "Editor> Creando el enlace de \"~/.config/nvim/ftplugin\" para el codigo open/close asociado a los 'file types' como Editor"
            ln -snf ~/.files/nvim/editor/ftplugin/ ~/.config/nvim/ftplugin
        fi
        
        #6.2 Instalando paquetes
        _neovim_config_plugins 0


    fi


}

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


# Parametros:
# > Opcion:
#    0 - Se configura VIM en modo basico (por defecto)
#    1 - Se configura VIM en modo IDE
function _vim_config_plugins() {

    #1. Argumentos
    local p_opcion=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opcion=$1
    fi

    #2. Crear las carpetas de basicas
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

        #Si es un repositorio para perfil developer no debe instalarse en el perfil basico
        if [ $p_opcion -eq 0 ] && [ $l_repo_type -eq 3 -o $l_repo_type -eq 4 ]; then
            continue
        fi

        #echo "${l_base_path}/${l_repo_name}/.git"

        #4.3 Validar si el paquete ya esta instalado
        if [ -d ${l_base_path}/${l_repo_name}/.git ]; then
             #print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
             printf 'Paquete VIM (%s) "%s": Ya esta instalado\n' "${l_repo_type}" "${l_repo_git}"
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
        echo "Indexar la documentación del plugin \"${l_base_path}/${l_repo_name}/doc\""
        vim -u NONE -esc "helptags ${l_base_path}/${l_repo_name}/doc" -c qa    

        printf '\n'

    done;

    #5. Instalar los paquetes/plugin que se instana por comandos de Vim
    #echo 'Instalando los plugins "Vim-Plug" de VIM, ejecutando el comando ":PlugInstall"'
    #vim -esc 'PlugInstall' -c 'qa'

    #echo 'Actualizando los plugins "Vim-Plug" de VIM, ejecutando el comando ":PlugUpdate"'
    #vim -esc 'PlugUpdate' -c 'qa'

    if [ $p_opcion -eq 1 ]; then

        printf '  Se ha instalado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "VIM" "$g_color_reset" "$g_color_subtitle" "Developer" "$g_color_reset"
        printf 'Configurando los plugins usados para IDE ...\n' 

        #Instalando extensiones basicos de CoC: Adaptador de LSP server basicos JS, Json, HTLML, CSS, Python, Bash
        printf '  Instalando extensiones de CoC (Adaptador de LSP server basicos) ":CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh"\n'
        vim -esc 'CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh' -c 'qa'

        #Instalando extensiones basicos de CoC: Motor de snippets 'UtilSnips'
        printf '  Instalando extensiones de CoC (Motor de snippets "UtilSnips") ":CocInstall coc-ultisnips" (no se esta usando el nativo de CoC)\n'
        vim -esc 'CocInstall coc-update' -c 'qa'

        #Instalando los gadgets basicos de 'VimSpector'
        #printf '  Actualizando los gadgets de "VimSpector", ejecutando el comando ":VimspectorUpdate"\n'
        #vim -esc 'VimspectorUpdate' -c 'qa'

        #Actualizar las extensiones de CoC
        printf '  Actualizando los extensiones existentes de CoC, ejecutando el comando ":CocUpdate"\n'
        vim -esc 'CocUpdate' -c 'qa'

        #Actualizando los gadgets de 'VimSpector'
        printf '  Actualizando los gadgets de "VimSpector", ejecutando el comando ":VimspectorUpdate"\n'
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
        printf '  Se ha instalado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "VIM" "$g_color_reset" "$g_color_subtitle" "Editor" "$g_color_reset"
    fi
    return 0
}

# Parametros:
# > Opcion ingresada por el usuario.
function _vim_setup() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #Sobrescribir los enlaces simbolicos
    local l_option=64
    local l_flag=$(( $p_opciones & $l_option ))
    local l_overwrite_ln_flag=1
    if [ $l_flag -eq $l_option ]; then l_overwrite_ln_flag=0; fi

    #2. Determinando la version actual de VIM
    local l_version=""
    l_version=$(vim --version 2> /dev/null)
    local l_status=$?
    local l_vim_flag=1
    if [ $l_status -eq 0 ]; then
        l_version=$(echo "$l_version" | head -n 1)
        l_version=$(echo "$l_version" | sed "$g_regexp_version1")
        l_vim_flag=0
    else
        l_version=""
    fi

    #3, Instalando VIM-Enhaced
    local l_flag_title=1
    
    l_option=8
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then

        if [ $l_flag_title -ne 0 ]; then
            print_line '-' $g_max_length_line "$g_color_opaque" 
            echo "> Configuración de VIM-Enhanced"
            print_line '-' $g_max_length_line "$g_color_opaque" 
            l_flag_title=0
        fi

        #print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        if [ $l_vim_flag -ne 0 ]; then

            #Solicitar credenciales de administrador y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq -1 ]; then

                storage_sudo_credencial
                g_status_crendential_storage=$?

                if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                    return 99
                fi
            fi

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            #echo "- Instalación de VIM-Enhaced"
            echo "Se va instalar VIM-Enhaced"

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
            echo "VIM-Enhaced \"${l_version}\" ya esta instalado"
        fi

    fi

    #4. Configurar VIM

    #Configurar VIM como IDE (Developer)
    l_option=32
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then

        if [ $l_flag_title -ne 0 ]; then
            print_line '-' $g_max_length_line "$g_color_opaque" 
            echo "> Configuración de VIM-Enhanced"
            print_line '-' $g_max_length_line "$g_color_opaque" 
            l_flag_title=0
        fi
        
        if [ $l_vim_flag -ne 0 ]; then
            echo "Para configurar VIM debera instalar primero VIM"
            return 1
        fi

        #Creando enlaces simbolicos
        printf '\n'
        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        mkdir -p ~/.vim/

        if [ ! -e ~/.vim/coc-settings.json ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "IDE (CoC)> Creando los enlaces simbolico del archivo de Configuración de CoC \"~/.vim/coc-settings.json\""
            ln -sfn ~/.files/vim/ide_coc/coc-settings_lnx.json ~/.vim/coc-settings.json
        fi
        
        if [ ! -e ~/.vim/ftplugin ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "IDE (CoC)> Creando el enlace de \"~/.vim/ftplugin\" para el codigo open/close asociado a los 'file types'"
            ln -snf ~/.files/vim/ide_coc/ftplugin/ ~/.vim/ftplugin
        fi

        #if [ ! -e ~/.vimrc ] || [ $l_overwrite_ln_flag -eq 0 ]; then
        echo "IDE (CoC)> Creando el enlace del script de inicio \"~/.vimrc\" para usarlos como IDE"
        ln -snf ~/.files/vim/vimrc_linux_ide.vim ~/.vimrc
        #fi

        #Instalar los plugins
        _vim_config_plugins 1

    fi

    #Configurar VIM como Editor basico
    l_option=16
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then


        if [ $l_flag_title -ne 0 ]; then
            print_line '-' $g_max_length_line "$g_color_opaque" 
            echo "> Configuración de VIM-Enhanced"
            print_line '-' $g_max_length_line "$g_color_opaque" 
            l_flag_title=0
        fi
        
        if [ $l_vim_flag -ne 0 ]; then
            echo "Para configurar VIM debera instalar primero VIM"
            return 1
        fi
        
        #Creando enlaces simbolicos
        printf '\n'
        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        mkdir -p ~/.vim/

        #if [ ! -e ~/.vimrc ] || [ $l_overwrite_ln_flag -eq 0 ]; then
        echo "Editor> Creando el enlace del script de inicio \"~/.vimrc\" para usarlo como editor basico"
        ln -snf ~/.files/vim/vimrc_linux_basic.vim ~/.vimrc
        #fi

        if [ ! -e ~/.vim/ftplugin ] || [ $l_overwrite_ln_flag -eq 0 ]; then
            echo "Editor> Creando el enlace de \"~/.vim/ftplugin\" para el codigo open/close asociado a los 'file types' como Editor"
            ln -snf ~/.files/vim/editor/ftplugin/ ~/.vim/ftplugin
        fi

        echo "Complete la configuración de VIM como editor basico:"
        echo "  1> Instalar los plugins de VIM-Plug: \":PlugInstall\""

        #Instalar los plugins
        _vim_config_plugins 0
    fi

}

# Parametros:
# > Opcion ingresada por el usuario.
function _commands_setup() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #¿Se requiere instalar VIM/NVIM?
    local l_flag_install_vim=1
    local l_flag_install_nvim=1

    local l_option=8
    local l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_install_vim=0; fi
    
    l_option=64
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_install_nvim=0; fi

    #Si no se solicitar instalar VIM o NeoVIM no instalar ningun comando
    #Si requiere instalar algun comando especifico use el script de instalacion de paquetes de SO
    if [ $l_flag_install_vim -ne 0 ] && [ $l_flag_install_nvim -ne 0 ]; then
        return 1
    fi
    
    print_line '-' $g_max_length_line "$g_color_opaque" 
    echo "> Instalando los comandos/programas basicos requeridos ..."

    #2. Instalando XClip utilitarios para gestion de "clipbboard" (X11 Selection)
    #   Por algun motivo la version se muestra el flujo estandar de errores 
    local l_version=""
    l_version=$(xclip -version 2>&1 1> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then

        #Solicitar credenciales de administrador y almacenarlas temporalmente
        if [ $g_status_crendential_storage -eq -1 ]; then

            storage_sudo_credencial
            g_status_crendential_storage=$?

            if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                return 99
            fi
        fi

        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        #echo "- Instalación de XClip"
        echo "Se va instalar comando XClip"

        case "$g_os_subtype_id" in
            1)
               #Distribución: Ubuntu
               if [ $g_is_root -eq 0 ]; then

                  apt-get install xclip
               else
                  sudo apt-get install xclip
               fi
               ;;
            2)
               #Distribución: Fedora
               if [ $g_is_root -eq 0 ]; then
                  dnf install xclip
               else
                  sudo dnf install xclip
               fi
               ;;
        esac
    else
        l_version=$(echo "$l_version" | head -n 1 )
        l_version=$(echo "$l_version" | sed "$g_regexp_version1")
        echo "XClip \"${l_version}\" ya esta instalado"
    fi

    #3. Instalando XSel utilitarios para gestion de "clipbboard" (X11 Selection)
    l_version=$(xsel --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then

        #Solicitar credenciales de administrador y almacenarlas temporalmente
        if [ $g_status_crendential_storage -eq -1 ]; then

            storage_sudo_credencial
            g_status_crendential_storage=$?

            if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                return 99
            fi
        fi

        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        #echo "- Instalación de XSel"
        echo "Se va instalar comando XSel"

        case "$g_os_subtype_id" in
            1)
               #Distribución: Ubuntu
               if [ $g_is_root -eq 0 ]; then
                  apt-get install xsel
               else
                  sudo apt-get install xsel
               fi
               ;;
            2)
               #Distribución: Fedora
               if [ $g_is_root -eq 0 ]; then
                  dnf install xsel
               else
                  sudo dnf install xsel
               fi
               ;;
        esac
    else
        l_version=$(echo "$l_version" | head -n 1 )
        l_version=$(echo "$l_version" | sed "$g_regexp_version1")
        echo "XSel \"${l_version}\" ya esta instalado"
    fi

    #4. Instalación de comandos para el desarrollador: RTEs requerida para Vim (y/o NeoVim), Otros
    l_option=4
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -ne $l_option ]; then
        l_option=32
        l_flag=$(( $p_opciones & $l_option ))
    fi

    local l_temp=""
    if [ $l_flag -eq $l_option ]; then

        #4.1 Instalación de Node.JS (el gestor de paquetes npm esta incluido)

        #print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 

        #Obtener la version de Node.JS actual
        l_version=$(node -v 2> /dev/null)
        l_status=$?
        if [ $l_status -ne 0 ]; then

            #El RTE puede estar instado pero no estar en el PATH
            l_version=$(${g_path_lnx_programs}/nodejs/bin/node -v 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                printf '%bNode.JS %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en su profile\n' \
                    "$g_color_warning" "$l_version" "$g_color_reset"
                printf 'Adicionando a la sesion actual: PATH=%s/nodejs/bin:$PATH\n' "${g_path_lnx_programs}"
                export PATH=${g_path_lnx_programs}/nodejs/bin:$PATH
            else
                l_version=""
            fi
        fi

        #Si no esta instalado
        if [ -z "$l_version" ]; then

            #Solicitar credenciales de administrador y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq -1 ]; then

                storage_sudo_credencial
                g_status_crendential_storage=$?

                if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                    return 99
                fi
            fi

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "Soporte a CoC en Vim/NeoVim> Se va instalar el scripts NVM y con ello se instalar RTE Node.JS"

            #Instalando NodeJS

            #Parametros:
            # 1> Tipo de ejecución: 2 (ejecución no-interactiva para instalar/actualizar un respositorio especifico)
            # 2> Repositorio a instalar/acutalizar: "nodejs" (actualizar solo los comandos instalados)
            # 3> El estado de la credencial almacenada para el sudo
            ~/.files/setup/linux/01_setup_commands.bash 2 "nodejs" $g_status_crendential_storage
            export PATH=${g_path_lnx_programs}/nodejs/bin:$PATH

            l_version=$(node -v 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                printf 'Se instaló la Node.JS version %s\n' "$l_version"
            fi

        #Si esta instalado
        else
            l_version=$(echo "$l_version" | sed "$g_regexp_version1")
            echo "Node.JS \"$l_version\" ya esta instalado"
        fi

        #4.2 Instalación de Python3 y el modulo 'pip' (gestor de paquetes)
        l_version=$(python3 --version 2> /dev/null)
        l_status=$?
        if [ $l_status -ne 0 ]; then

            #Solicitar credenciales de administrador y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq -1 ]; then

                storage_sudo_credencial
                g_status_crendential_storage=$?

                if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                    return 99
                fi
            fi

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "Vim/NeoVim como IDE> Se va instalar RTE Python3"


            case "$g_os_subtype_id" in
                1)
                    #Distribución: Ubuntu

                    #A. Registrar el repositorio de paquetes si no lo esta (usar el por defecto o terceros como 'deadsnakes')
                    #if [ $g_is_root -eq 0 ]; then
                    #    add-apt-repository ppa:deadsnakes/ppa
                    #    apt-get update
                    #else
                    #    sudo add-apt-repository ppa:deadsnakes/ppa
                    #    sudo apt-get update
                    #fi

                    #B. Instalar el paquete
                    if [ $g_is_root -eq 0 ]; then
                        apt-get install python3
                    else
                        sudo apt-get install python3
                    fi
                    ;;

                2)
                    #Distribución: Fedora

                    #A. Registrar el repositorio de paquetes si no lo esta (usar el por defecto o terceros como 'deadsnakes')
                    #if [ $g_is_root -eq 0 ]; then
                    #    add-apt-repository ppa:deadsnakes/ppa
                    #    apt-get update
                    #else
                    #    sudo add-apt-repository ppa:deadsnakes/ppa
                    #    sudo apt-get update
                    #fi

                    #B. Instalar el paquete
                    if [ $g_is_root -eq 0 ]; then
                        dnf install python3
                    else
                        sudo dnf install python3
                    fi
                    ;;
            esac

        else
            l_version=$(echo "$l_version" | sed "$g_regexp_version1")
            echo "Python3 \"$l_version\" ya esta instalado"
        fi

        #4.3 Instalación del modulo Python3: 'pip' (gestor de paquetes)
        l_version=$(python3 -m pip --version 2> /dev/null)
        l_status=$?
        if [ $l_status -ne 0 ]; then

            #Solicitar credenciales de administrador y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq -1 ]; then

                storage_sudo_credencial
                g_status_crendential_storage=$?

                if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                    return 99
                fi
            fi

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "Instalando el comando 'pip' (modulo python) para  instalar paquetes python."

            case "$g_os_subtype_id" in
                1)
                    #Distribución: Ubuntu
                    if [ $g_is_root -eq 0 ]; then
                        apt-get install python3-pip
                    else
                        sudo apt-get install python3-pip
                    fi
                    ;;

                2)
                    #Distribución: Fedora
                    if [ $g_is_root -eq 0 ]; then
                        dnf install python3-pip
                    else
                        sudo dnf install python3-pip
                    fi
                    ;;
            esac

        else
            l_version=$(echo "$l_version" | sed "$g_regexp_version1")
            echo "Comando 'pip' (modulo python) \"$l_version\" ya esta instalado"
        fi

        #4.4 Instalación de Skopeo: Permite inspeccionar contenedores de registros remotos
        #                           sin requerir container engine y no hacer pull de ccontenedor
        l_version=$(skopeo -v 2> /dev/null)
        l_status=$?
        if [ $l_status -ne 0 ]; then

            #Solicitar credenciales de administrador y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq -1 ]; then

                storage_sudo_credencial
                g_status_crendential_storage=$?

                if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
                    return 99
                fi
            fi

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "Instalando el comando 'skopeo' para examinar, copiar, eliminar contenedores de registros remotos."

            case "$g_os_subtype_id" in
                1)
                    #Distribución: Ubuntu
                    if [ $g_is_root -eq 0 ]; then
                        apt-get install skopeo
                    else
                        sudo apt-get install skopeo
                    fi
                    ;;

                2)
                    #Distribución: Fedora
                    if [ $g_is_root -eq 0 ]; then
                        dnf install skopeo
                    else
                        sudo dnf install skopeo
                    fi
                    ;;
            esac

        else
            l_version=$(echo "$l_version" | sed "$g_regexp_version1")
            echo "Comando 'skopeo' \"$l_version\" ya esta instalado"
        fi

        #4.5 Instalación de Herramienta para mostrar arreglo json al formato tabular
        l_version=$(pip3 list | grep jtbl 2> /dev/null)
        #l_version=$(jtbl -v 2> /dev/null)
        l_status=$?
        #if [ $l_status -ne 0 ]; then
        if [ -z "$l_version" ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "Instalando el comando 'jtbl' (modulo python) para mostrar arreglos json en una consola en formato tabular."
            
            #Se instalar a nivel usuario
            pip3 install jtbl

        else
            l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_version1")
            echo "Comando 'jtbl' (modulo python) \"$l_version\" ya esta instalado"
        fi

        #4.6 Instalación de Herramienta para generar la base de compilacion de Clang desde un make file
        l_version=$(pip3 list | grep compiledb 2> /dev/null)
        #l_version=$(compiledb -h 2> /dev/null)
        l_status=$?
        #if [ $l_status -ne 0 ] || [ -z "$l_version"]; then
        if [ -z "$l_version" ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "Instalando el comando 'compiledb' (modulo python) para generar una base de datos de compilacion Clang desde un make file."
            
            #Se instalar a nivel usuario
            pip3 install compiledb

        else
            l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_version1")
            echo "Comando 'compiladb' (modulo python) \"$l_version\" ya esta instalado"
            #echo "Tools> 'compiledb' ya esta instalado"
        fi

        #4.7 Instalación de la libreria de refactorización de Python (https://github.com/python-rope/rope)
        l_version=$(pip3 list | grep rope 2> /dev/null)
        l_status=$?
        if [ -z "$l_version" ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "Instalando la libreria python 'rope' para refactorización de Python (https://github.com/python-rope/rope)."
            
            #Se instalara a nivel usuario
            pip3 install rope

        else
            l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_version1")
            echo "Libreria 'rope' (modulo python) \"$l_version\" ya esta instalado"
            #echo "Tools> 'compiledb' ya esta instalado"
        fi

        #4.8 Instalación de Herramienta Prettier para formateo de archivos como json, yaml, js, ...
        l_version=$(prettier --version 2> /dev/null)
        l_status=$?
        if [ $l_status -ne 0 ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 

            echo "Instlando el comando 'prettier' (como paquete global Node.JS)  para formatear archivos json, yaml, js, ..."

            #Se instalara a nivel glabal (puede ser usado por todos los usuarios)
            npm install -g --save-dev prettier

        else
            l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_version1")
            echo "Comando 'prettier' (paquete global Node.JS) \"$l_version\" ya esta instalado"
            echo "    Si usa JS o TS, se recomienda instalar de manera local los paquetes Node.JS para Linter EsLint:"
            echo "    > npm install --save-dev eslint"
            echo "    > npm install --save-dev eslint-plugin-prettier"
        fi



    fi

}

# Parametros:
# > Opcion ingresada por el usuario.
function _profile_setup() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #Sobrescribir los enlaces simbolicos
    local l_option=4
    local l_flag=$(( $p_opciones & $l_option ))
    local l_overwrite_ln_flag=1
    if [ $l_flag -eq $l_option ]; then l_overwrite_ln_flag=0; fi

    l_option=2
    l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -ne $l_option ] && [ $l_overwrite_ln_flag -ne 0 ]; then
        return 1 
    fi

    print_line '-' $g_max_length_line "$g_color_opaque" 
    echo "> Creando los enlaces simbolicos y folderes del profile shell ..."
    #print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
    
    if [ ! -d /u01/userkeys/ssh ]; then

        echo "Permiso ejecucion de shell y los folderes basicos \"/u01/userkeys/ssh\""
        chmod u+x ~/.files/terminal/linux/tmux/*.bash
        chmod u+x ~/.files/terminal/linux/complete/*.bash
        chmod u+x ~/.files/terminal/linux/keybindings/*.bash
        chmod u+x ~/.files/setup/linux/0*.bash
    
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

    #8.1 Creando enlaces simbolico dependiente de tipo de distribución Linux
    
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
           ln -snf ~/.files/config/git/wsl2_git.toml ~/.gitconfig
        fi

        if [ ! -e ~/.ssh/config ] || [ $l_overwrite_ln_flag -eq 0 ]; then
           echo "Creando los enlaces simbolico de ~/.ssh/config"
           mkdir -p ~/.ssh
           ln -sfn ~/.files/config/ssh/wsl2_ssh.conf ~/.ssh/config
        fi

        if [ ! -e ~/.config/powershell/Microsoft.PowerShell_profile.ps1 ] || [ $l_overwrite_ln_flag -eq 0 ]; then
           echo "Creando los enlaces simbolico de ~/.config/powershell/Microsoft.PowerShell_profile.ps1"
           mkdir -p ~/.config/powershell/
           ln -sfn ~/.files/terminal/powershell/profile/ubuntu_wsl.ps1 ~/.config/powershell/Microsoft.PowerShell_profile.ps1
        fi

        #if [ ! -e ~/.bashrc ] || [ $l_overwrite_ln_option -eq $l_overwrite_ln_flag ]; then
        echo "Creando los enlaces simbolico de ~/.bashrc"
        ln -snf ~/.files/terminal/linux/profile/ubuntu_wls.bash ~/.bashrc
        #fi

    #Si es un Linux generico (NO WSL)
    else

        if [ ! -e ~/.gitconfig ] || [ $l_overwrite_ln_flag -eq 0 ]; then
           echo "Creando los enlaces simbolico de ~/.gitconfig"
           ln -snf ~/.files/config/git/vm_linux_git.toml ~/.gitconfig
        fi

        if [ ! -e ~/.ssh/config ] || [ $l_overwrite_ln_flag -eq 0 ]; then
           echo "Creando los enlaces simbolico de ~/.ssh/config"
           ln -snf ~/.files/config/ssh/vm_linux_ssh.conf ~/.ssh/config
        fi

        if [ ! -e ~/.config/powershell/Microsoft.PowerShell_profile.ps1 ] || [ $l_overwrite_ln_flag -eq 0 ]; then
           echo "Creando los enlaces simbolico de ~/.config/powershell/Microsoft.PowerShell_profile.ps1"
           mkdir -p ~/.config/powershell/
           ln -sfn ~/.files/terminal/powershell/profile/fedora_vm.ps1 ~/.config/powershell/Microsoft.PowerShell_profile.ps1
        fi

        #if [ ! -e ~/.bashrc ] || [ $l_overwrite_ln_option -eq $l_overwrite_ln_flag ]; then
        echo "Creando los enlaces simbolico de ~/.bashrc"
        ln -snf ~/.files/terminal/linux/profile/fedora_vm.bash ~/.bashrc
        #fi
    fi

    #8.2 Creando enlaces simbolico independiente del tipo de distribución Linux
    if [ ! -e ~/.tmux.conf ] || [ $l_overwrite_ln_flag -eq 0 ]; then
       echo "Creando los enlaces simbolico de ~/.tmux.conf"
       ln -snf ~/.files/terminal/linux/tmux/tmux.conf ~/.tmux.conf
    fi

    #Configuración de un CLI de alto nivel del 'Container Runtime' 'ContainerD': nerdctl
    if [ ! -e ~/.config/nerdctl/nerdctl.toml ] || [ $l_overwrite_ln_flag -eq 0 ]; then
       echo "Creando los enlaces simbolico de ~/.config/nerdctl/nerdctl.toml"
       mkdir -p ~/.config/nerdctl/
       ln -snf ~/.files/config/nerdctl/default_config.toml ~/.config/nerdctl/nerdctl.toml
    fi

    #Configuración principal de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless'): Podman
    if [ ! -e ~/.config/containers/containers.conf ] || [ $l_overwrite_ln_flag -eq 0 ]; then
       echo "Creando los enlaces simbolico de ~/.config/containers/containers.conf"
       mkdir -p ~/.config/containers/
       ln -snf ~/.files/config/podman/default_config.toml ~/.config/containers/containers.conf
    fi

    #Configuración de los registros de imagenes de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless'): Podman
    if [ ! -e ~/.config/containers/registries.conf ] || [ $l_overwrite_ln_flag -eq 0 ]; then
       echo "Creando los enlaces simbolico de ~/.config/containers/registries.conf"
       mkdir -p ~/.config/containers/
       ln -snf ~/.files/config/podman/default_registries.toml ~/.config/containers/registries.conf
    fi

    #Configuración de un 'Container Runtime' 'ContainerD' (en modo 'rootless')
    if [ ! -e ~/.config/containerd/config.toml ] || [ $l_overwrite_ln_flag -eq 0 ]; then
       echo "Creando los enlaces simbolico de ~/.config/containerd/config.toml"
       mkdir -p ~/.config/containerd/
       ln -snf ~/.files/config/containerd/default_config.toml ~/.config/containerd/config.toml
    fi

    #Configuración del backend de compilacion de imagenes 'BuildKit' (en modo 'rootless')
    if [ ! -e ~/.config/buildkit/buildkitd.toml ] || [ $l_overwrite_ln_flag -eq 0 ]; then
       echo "Creando los enlaces simbolico de ~/.config/buildkit/buildkitd.toml"
       mkdir -p ~/.config/buildkit/
       ln -snf ~/.files/config/buildkit/default_config.toml ~/.config/buildkit/buildkitd.toml
    fi

    #Configuracion por defecto para un Cluster de Kubernates
    if [ ! -e ~/.kube/config ] || [ $l_overwrite_ln_flag -eq 0 ]; then
       echo "Creando los enlaces simbolico de ~/.kube/config"
       mkdir -p ~/.kube/
       ln -snf ~/.files/config/kubectl/default_config.yaml ~/.kube/config
    fi

    return 0
e

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

    #02. Validar si fue descarga el repositorio git correspondiente
    if [ ! -d ~/.files/.git ]; then
        show_message_nogitrepo
        return 10
    fi
    
    g_status_crendential_storage=-1
    local l_status

    #03. Actualizar los paquetes de los repositorios
    local l_option=1
    local l_flag=$(( $p_opciones & $l_option ))

    if [ $l_flag -eq $l_option ]; then

        #Solicitar credenciales de administrador y almacenarlas temporalmente
        storage_sudo_credencial
        g_status_crendential_storage=$?
        #Se requiere almacenar las credenciales para realizar cambiso con sudo.
        if [ $g_status_crendential_storage -ne 0 ] && [ $g_status_crendential_storage -ne 2 ]; then
            return 99
        fi
        
        #Actualizar los paquetes de los repositorios
        print_line '-' $g_max_length_line "$g_color_opaque" 
        echo "> Actualizar los paquetes de los repositorio del SO Linux"
        print_line '-' $g_max_length_line "$g_color_opaque" 
        
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

    fi   
    
    #05. Instalando comandos y programas basicos
    _commands_setup $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 99 ]; then
        return 99
    fi

    #06. Instalando VIM-Enhaced
    _vim_setup $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 99 ]; then
        return 99
    fi
    
    #07. Instalando NeoVim
    _neovim_setup $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 99 ]; then
        return 99
    fi

    #08. Configuracion el SO: Crear enlaces simbolicos y folderes basicos
    _profile_setup $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 99 ]; then
        return 99
    fi

    #09. Eliminar el gestor 'VIM-Plug'
    _remove_vim_plug $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 99 ]; then
        return 99
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
    printf "     (%b%0${l_max_digits}d%b) Re-crear (crear y/o actualizar) los enlaces simbolicos del profile\n" "$g_color_title" "4" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) VIM    - Instalar si no esta instalado\n" "$g_color_title" "8" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) VIM    - Configurar como %beditor%b (Basico)\n" "$g_color_title" "16" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) VIM    - Configurar como %bIDE%b (Developer)\n" "$g_color_title" "32" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Instalar si no esta instalado\n" "$g_color_title" "64" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Configurar como %beditor%b (Basico)\n" "$g_color_title" "128" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Configurar como %bIDE%b (Developer)\n" "$g_color_title" "256" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) VIM    - Eliminar el gestor de paquetes 'VIM-Plug'\n" "$g_color_title" "512" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Eliminar el gestor de paquetes 'VIM-Plug'\n" "$g_color_title" "1024" "$g_color_reset"

    print_line '-' $g_max_length_line "$g_color_opaque"

}

function i_main() {

    #1. Pre-requisitos
    printf '%bOS Type            : (%s)\n' "$g_color_opaque" "$g_os_type"
    printf 'OS Subtype (Distro): (%s) %s - %s%b\n' "${g_os_subtype_id}" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
    
    #Determinar el tipo de distribución Linux
    if [ $g_os_type -gt 10 ]; then
        printf '\nERROR: El sistema operativo debe ser Linux\n'
        return 21;
    fi

    #¿Esta 'curl' instalado?
    local l_status
    fulfill_preconditions1
    l_status=$?

    if [ $l_status -ne 0 ]; then
        return 22
    fi
   
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
                _setup 216
                ;;


            b)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                _setup 360
                ;;

            c)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                #1 + 2 + 8 + 16 + 64 + 128
                _setup 219
                ;;

            d)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                #1 + 2 + 8 + 32 + 64 + 256 
                _setup 363
                ;;

            e)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                #1 + 2 + 4 + 8 + 16 + 64 + 128
                _setup 223
                ;;

            f)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_title" 
                printf '\n'
                #1 + 2 + 4 + 8 + 32 + 64 + 256
                _setup 367
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

i_main



