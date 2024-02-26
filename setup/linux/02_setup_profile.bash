#!/bin/bash

#
#Devolverá la ruta base 'PATH_BASE' donde esta el repositorio '.files'.
#Nota: Los script de instalación tiene una ruta similar a 'PATH_BASE/REPO_NAME/setup/linux/SCRIPT.bash', donde 'REPO_NAME' siempre es '.files'.
#
#Parametros de entrada:
#  1> La ruta relativa (o absoluta) de un archivos del repositorio
#Parametros de salida: 
#  STDOUT> La ruta base donde esta el repositorio
function _get_current_path_base() {

    #Obteniendo la ruta absoluta del parametro ingresado
    local l_path=''
    l_path=$(realpath "$1" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        echo "$HOME"
        return 1
    fi

    #Obteniendo la ruta base
    l_path=${l_path%/.files/setup/linux/*}
    echo "$l_path"
    return 0
}

#Inicialización Global {{{

declare -r g_path_base=$(_get_current_path_base "${BASH_SOURCE[0]}")

#Si se ejecuta un usuario root y es diferente al usuario que pertenece este script de instalación (es decir donde esta el repositorio)
#UID del Usuario y GID del grupo (diferente al actual) que ejecuta el script actual
g_other_calling_user=''

#Funciones generales: determinar el tipo del SO, ...
. ${g_path_base}/.files/terminal/linux/functions/func_utility.bash

#Obtener informacion basica del SO
if [ -z "$g_os_type" ]; then

    #Determinar el tipo del SO con soporte a interprete shell POSIX
    get_os_type
    declare -r g_os_type=$?

    #Obtener informacion de la distribución Linux
    if [ $g_os_type -le 1 ]; then
        get_linux_type_info
    fi

fi


#Obtener informacion basica del usuario
if [ -z "$g_user_is_root" ]; then

    #Determinar si es root y el soporte de sudo
    set_user_options

fi


#Funciones de utilidad
. ${g_path_base}/.files/setup/linux/_common_utility.bash


#Tipo de ejecucion del script principal
gp_type_calling=0       #(0) Ejecución mostrando el menu del opciones (siempre es interactiva).
                        #(1) Ejecución sin el menu de opciones, interactivo    - configurar un conjunto de opciones del menú
                        #(2) Ejecución sin el menu de opciones, no-interactivo - configurar un conjunto de opciones del menú

#Estado del almacenado temporalmente de las credenciales para sudo
# -1 - No se solicito el almacenamiento de las credenciales
#  0 - No es root: se almaceno las credenciales
#  1 - No es root: no se pudo almacenar las credenciales.
#  2 - Es root: no requiere realizar sudo.
g_status_crendential_storage=-1

#Si la credenciales de sudo es abierto externamente.
#  1 - No se abrio externamente
#  0 - Se abrio externamente (solo se puede dar en una ejecución no-interactiva)
g_is_credential_storage_externally=1


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
        ['puremourning/vimspector']=4
        ['folke/tokyonight.nvim']=1
        ['kyazdani42/nvim-web-devicons']=2
        ['nvim-lualine/lualine.nvim']=2
        ['akinsho/bufferline.nvim']=2
        ['nvim-lua/plenary.nvim']=2
        ['nvim-telescope/telescope.nvim']=2
        ['nvim-tree/nvim-tree.lua']=2
        ['nvim-treesitter/nvim-treesitter']=4
        ['jose-elias-alvarez/null-ls.nvim']=4
        ['neovim/nvim-lspconfig']=4
        ['hrsh7th/nvim-cmp']=4
        ['ray-x/lsp_signature.nvim']=4
        ['hrsh7th/cmp-nvim-lsp']=4
        ['hrsh7th/cmp-buffer']=4
        ['hrsh7th/cmp-path']=4
        ['L3MON4D3/LuaSnip']=4
        ['rafamadriz/friendly-snippets']=4
        ['saadparwaiz1/cmp_luasnip']=4
        ['kosayoda/nvim-lightbulb']=4
        ['mfussenegger/nvim-dap']=4
        ['theHamsta/nvim-dap-virtual-text']=4
        ['rcarriga/nvim-dap-ui']=4
        ['nvim-telescope/telescope-dap.nvim']=4
    )

# Repositorios Git - para VIM/NeoVIM. Por defecto es 3 (para ambos)
#  1 - Para VIM
#  2 - Para NeoVIM
declare -A gA_repos_scope=(
        ['tomasr/molokai']=1
        ['dracula/vim']=1
        ['vim-airline/vim-airline']=1
        ['vim-airline/vim-airline-themes']=1
        ['ryanoasis/vim-devicons']=1
        ['preservim/nerdtree']=1
        ['puremourning/vimspector']=1
        ['folke/tokyonight.nvim']=2
        ['kyazdani42/nvim-web-devicons']=2
        ['nvim-lualine/lualine.nvim']=2
        ['akinsho/bufferline.nvim']=2
        ['nvim-lua/plenary.nvim']=2
        ['nvim-telescope/telescope.nvim']=2
        ['nvim-tree/nvim-tree.lua']=2
        ['nvim-treesitter/nvim-treesitter']=2
        ['jose-elias-alvarez/null-ls.nvim']=2
        ['neovim/nvim-lspconfig']=2
        ['hrsh7th/nvim-cmp']=2
        ['ray-x/lsp_signature.nvim']=2
        ['hrsh7th/cmp-nvim-lsp']=2
        ['hrsh7th/cmp-buffer']=2
        ['hrsh7th/cmp-path']=2
        ['L3MON4D3/LuaSnip']=2
        ['rafamadriz/friendly-snippets']=2
        ['saadparwaiz1/cmp_luasnip']=2
        ['kosayoda/nvim-lightbulb']=2
        ['mfussenegger/nvim-dap']=2
        ['theHamsta/nvim-dap-virtual-text']=2
        ['rcarriga/nvim-dap-ui']=2
        ['nvim-telescope/telescope-dap.nvim']=2
    )

# Repositorios Git - Branch donde esta el plugin no es el por defecto
declare -A gA_repos_branch=(
        ['neoclide/coc.nvim']='release'
    )

# Repositorios Git - Deep de la clonacion del repositorio que no es el por defecto
declare -A gA_repos_depth=(
        ['neoclide/coc.nvim']=1
        ['junegunn/fzf']=1
        ['dense-analysis/ale']=1
    )


#}}}


#Parametros de salida (SDTOUT): Version de compilador c/c++ instalando
#Parametros de salida (valores de retorno):
# 0 > Se obtuvo la version
# 1 > No se obtuvo la version
function _get_gcc_version() {

    #Obtener la version instalada
    l_version=$(gcc --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        return 1
    fi

    l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    echo "$l_version"
    return 0
}

function _create_file_link() {

    local p_source_path="$1"
    local p_source_filename="$2"
    local p_target_link="$3"
    local p_tag="$4"
    local p_override_target_link=1
    if [ "$5" = "0" ]; then
        p_override_target_link=0
    fi

    local l_target_base="${p_target_link%/*}"
    if [ ! -d "$l_target_base" ]; then
        mkdir -p "$l_target_base"
    fi

    local l_source_fullfilename="${p_source_path}/${p_source_filename}"
    local l_aux
    if [ -h "$p_target_link" ] && [ -f "$p_target_link" ]; then
        if [ $p_override_target_link -eq 0 ]; then
            mkdir -p "$p_source_path"
            ln -snf "$l_source_fullfilename" "$p_target_link"
            printf "%sEl enlace simbolico '%s' se ha re-creado %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_gray1" "$l_source_fullfilename" "$g_color_reset"
        else
            l_aux=$(readlink "$p_target_link")
            printf "%sEl enlace simbolico '%s' ya existe %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_gray1" "$l_aux" "$g_color_reset"
        fi
    else
        mkdir -p "$p_source_path"
        ln -snf "$l_source_fullfilename" "$p_target_link"
        printf "%sEl enlace simbolico '%s' se ha creado %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_gray1" "$l_source_fullfilename" "$g_color_reset"
    fi

}



function _create_folder_link() {

    local p_source_path="$1"
    local p_target_link="$2"
    local p_tag="$3"
    local p_override_target_link=1
    if [ "$4" = "0" ]; then
        p_override_target_link=0
    fi

    local l_target_base="${p_target_link%/*}"
    if [ ! -d "$l_target_base" ]; then
        mkdir -p "$l_target_base"
    fi

    local l_aux
    if [ -h "$p_target_link" ] && [ -d "$p_target_link" ]; then
        if [ $p_override_target_link -eq 0 ]; then
            mkdir -p "$p_source_path"
            ln -snf "${p_source_path}/" "$p_target_link"
            printf "%sEl enlace simbolico '%s' se ha re-creado %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_gray1" "$p_source_path" "$g_color_reset"
        else
            l_aux=$(readlink "$p_target_link")
            printf "%sEl enlace simbolico '%s' ya existe %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_gray1" "$l_aux" "$g_color_reset"
        fi
    else
        mkdir -p "$p_source_path"
        ln -snf "${p_source_path}/" "$p_target_link"
        printf "%sEl enlace simbolico '%s' se ha creado %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_gray1" "$p_source_path" "$g_color_reset"
    fi

}


# Parametros:
#  1> Flag '0' si es NeoVIM. Por defecto es 1.
function _index_doc_of_vim_packages() {

    #1. Argumentos
    local p_is_neovim=1
    local l_tag="VIM"
    if [ "$1" = "0" ]; then
        p_is_neovim=0
        l_tag="NeoVIM"
    fi

    #2. Ruta base donde se instala el plugins/paquete
    local l_base_plugins_path="${g_path_base}/.vim/pack"
    if [ $p_is_neovim -eq 0  ]; then
        l_base_plugins_path="${g_path_base}/.local/share/nvim/site/pack"
    fi

    #Validar si existe directorio
    if [ ! -d "$l_base_plugins_path" ]; then
        printf '%s > Folder "%s" not exists.\n' "$l_tag" "$l_base_plugins_path"
        return 9
    fi

    #3. Buscar los repositorios git existentes en la carpeta plugin y actualizarlos
    local l_folder
    local l_plugin_path
    local l_repo_type
    local l_repo_name
    local l_flag_title=1
    local l_i=0

    cd $l_base_plugins_path
    for l_folder  in $(find . -mindepth 4 -maxdepth 4 -type d -name .git); do

        l_plugin_path="${l_folder%/.git}"
        l_plugin_path="${l_plugin_path#./}"

        l_repo_name="${l_plugin_path##*/}"
        l_repo_type="${l_plugin_path%%/*}"

        l_plugin_path="${l_base_plugins_path}/${l_plugin_path}"

        #_update_repository $p_is_neovim "$l_folder" "$l_repo_name" "$l_repo_type"

        #Almacenando las ruta de documentacion a indexar 
        if [ -d "${l_plugin_path}/doc" ]; then

            #Mostrar el titulo si aun no ha mostrado
            if [ $l_flag_title -ne 0 ]; then

                printf '\n'
                print_line '-' $g_max_length_line  "$g_color_gray1"
                printf '%s > %bIndexar%b la documentacion de sus plugins existentes %b(en "%s")%b\n' "$l_tag" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" \
                       "$l_base_plugins_path" "$g_color_reset"
                print_line '-' $g_max_length_line  "$g_color_gray1"
                l_flag_title=0

            fi

            #Indexar la documentación
            l_i=$((l_i + 1))
            printf '(%s) Indexando la documentación del plugin %b%s%b en %s: "%bhelptags %s%b"\n' "$l_i" "$g_color_gray1" "$l_repo_name" \
                   "$g_color_reset" "$l_tag" "$g_color_gray1" "$l_plugin_path/doc" "$g_color_reset"
            if [ $p_is_neovim -eq 0  ]; then
                nvim --headless -c "helptags ${l_plugin_path}/doc" -c qa
            else
                vim -u NONE -esc "helptags ${l_plugin_path}/doc" -c qa
            fi

        fi

    done

    return 0

}



# Parametros:
#  1> Flag '0' si es NeoVIM. Por defecto es 1.
#  2> Flag configurar como Developer (si es '0'). Por defecto es 1.
#  3> Flag '0' si no se indexa la documentacion de VIM. Por defecto, es '1' (se indexa la documentacion)
function _download_vim_packages() {

    #1. Argumentos
    local l_tag="VIM"
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
        l_tag="NeoVIM"
    fi

    local l_mode="Editor"
    local p_flag_developer=1
    if [ "$2" = "0" ]; then
        p_flag_developer=0
        l_mode="IDE"
    fi

    local p_flag_non_index_doc=1
    if [ "$3" = "0" ]; then
        p_flag_non_index_doc=0
    fi

    #Precondiciones obligatorios: Se requiere tener Git instalado
    if ! git --version 1> /dev/null 2>&1; then

        #No esta instalado Git, No configurarlo
        printf '%s > %bGit NO esta instalado%b. Es requerido para descargar los plugins.\n' "$l_tag" "$g_color_red1" "$g_color_reset"
        return 111

    fi

    #2. Ruta base donde se instala el plugins/paquete
    local l_current_scope=1
    local l_base_plugins="${g_path_base}/.vim/pack"
    if [ $p_is_neovim -eq 0  ]; then
        l_base_plugins="${g_path_base}/.local/share/nvim/site/pack"
        l_current_scope=2
    fi

    #3. Crear las carpetas de basicas
    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf "%s > Descargando los %bplugins%b de modo %b%s%b %b(%s)%b\n" "$l_tag" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" \
           "$l_mode" "$g_color_reset" "$g_color_gray1" "$l_base_plugins" "$g_color_reset"
    print_line '-' $g_max_length_line  "$g_color_gray1"

    mkdir -p ${l_base_plugins}
    mkdir -p ${l_base_plugins}/themes/start
    mkdir -p ${l_base_plugins}/themes/opt
    mkdir -p ${l_base_plugins}/ui/start
    mkdir -p ${l_base_plugins}/ui/opt
    if [ $p_flag_developer -eq 0 ]; then
        mkdir -p ${l_base_plugins}/typing/start
        mkdir -p ${l_base_plugins}/typing/opt
        mkdir -p ${l_base_plugins}/ide/start
        mkdir -p ${l_base_plugins}/ide/opt
    fi
   
    
    #4. Instalar el plugins que se instalan manualmente
    local l_path_base
    local l_repo_git
    local l_repo_name
    local l_repo_type=1
    local l_repo_url
    local l_repo_branch
    local l_repo_depth
    local l_repo_scope
    local l_aux

    local la_doc_paths=()
    local la_doc_repos=()

    for l_repo_git in "${!gA_repos_type[@]}"; do

        #4.1 Configurar el repositorio
        l_repo_scope="${gA_repos_scope[${l_repo_git}]:-3}"
        l_repo_type=${gA_repos_type[$l_repo_git]}
        l_repo_name=${l_repo_git#*/}

        #Si el repositorio no esta habilitido para su scope, continuar con el siguiente
        if [ $((l_repo_scope & l_current_scope)) -ne $l_current_scope ]; then
            continue
        fi

        #4.2 Obtener la ruta base donde se clonara el paquete (todos los paquetes son opcionale, se inicia bajo configuración)
        l_path_base=""
        case "$l_repo_type" in 
            1)
                l_path_base=${l_base_plugins}/themes/opt
                ;;
            2)
                l_path_base=${l_base_plugins}/ui/opt
                ;;
            3)
                l_path_base=${l_base_plugins}/typing/opt
                ;;
            4)
                l_path_base=${l_base_plugins}/ide/opt
                ;;
            *)
                
                printf '%s > Paquete (%s) "%s": No tiene tipo valido\n' "$l_tag" "${l_repo_type}" "${l_repo_git}"
                continue
                ;;
        esac

        #Si es un repositorio para developer no debe instalarse en el perfil basico
        if [ $p_flag_developer -eq 1 ] && [ $l_repo_type -eq 3 -o $l_repo_type -eq 4 ]; then
            continue
        fi

        #echo "${l_path_base}/${l_repo_name}/.git"

        #4.3 Validar si el paquete ya esta instalando
        if [ -d ${l_path_base}/${l_repo_name}/.git ]; then
             printf '%s > Paquete (%s) "%b%s%b": Ya esta instalando\n' "$l_tag" "${l_repo_type}" "$g_color_gray1" "${l_repo_git}" "$g_color_reset"
             continue
        fi

        #4.5 Instalando el paquete
        cd ${l_path_base}
        printf '\n'
        print_line '.' $g_max_length_line  "$g_color_gray1"
        #print_line '- ' $((g_max_length_line/2)) "$g_color_gray1" 
        printf '%s > Plugin (%b%s%b) "%b%s%b": Se esta instalando\n' "$l_tag" "$g_color_cian1" "$l_repo_type" "$g_color_reset" "$g_color_cian1" "$l_repo_git" "$g_color_reset"
        #print_line '- ' $((g_max_length_line/2)) "$g_color_gray1" 
        print_line '.' $g_max_length_line  "$g_color_gray1"

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

        #4.6 Almacenando las ruta de documentacion a indexar 
        if [ $p_flag_non_index_doc -ne 0 ] && [ -d "${l_path_base}/${l_repo_name}/doc" ]; then

            #Indexar la documentación de plugins
            la_doc_paths+=("${l_path_base}/${l_repo_name}/doc")
            la_doc_repos+=("${l_repo_name}")

        fi

        #printf '\n'

    done;

    #5. Actualizar la documentación de VIM (Los plugins VIM que no tiene documentación, no requieren indexar)
    local l_doc_path
    local l_n=${#la_doc_paths[@]}
    local l_i

    if [ $p_flag_non_index_doc -ne 0 ] && [ $l_n -gt 0 ]; then

        printf '\n'
        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf '%s > %bIndexar%b la documentacion de sus plugins existentes %b(en "%s")%b\n' "$l_tag" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" \
               "$l_base_plugins" "$g_color_reset"
        print_line '-' $g_max_length_line  "$g_color_gray1"


        for ((l_i=0; l_i< ${l_n}; l_i++)); do
            
            l_doc_path="${la_doc_paths[${l_i}]}"
            l_repo_name="${la_doc_repos[${l_i}]}"
            printf '(%s/%s) Indexando la documentación del plugin %b%s%b en %s: "%bhelptags %s%b"\n' "$((l_i + 1))" "$l_n" "$g_color_gray1" "$l_repo_name" \
                   "$g_color_reset" "$l_tag" "$g_color_gray1" "$l_doc_path" "$g_color_reset"
            if [ $p_is_neovim -eq 0  ]; then
                nvim --headless -c "helptags ${l_doc_path}" -c qa
            else
                vim -u NONE -esc "helptags ${l_doc_path}" -c qa
            fi

        done

        printf '\n'

    fi

    return 0

}



# Parametros de entrada:
#  1> Flag '0' si es NeoVIM.
# Parametros de salida:
#  > Valores de retorno
#      00> Se instalo correctamente
#      01> No se inicio el proceso debido a que no esta instalado NodeJS.
#      02> No se inicio el proceso debido a que no esta instalado VIM/NeoVIM.
function _config_developer_vim() {

    #1. Argumentos
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
    fi

    #Solo para VIM/NeoVIM como desarrollador
    local l_tag="VIM"
    if [ $p_is_neovim -eq 0  ]; then
        l_tag="NeoVIM"
    fi

    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf '%s > Configurar/Inicializar los %bplugins%b de %bIDE%b de %b%s%b\n' "$l_tag" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" \
           "$l_tag" "$g_color_reset"
    print_line '-' $g_max_length_line  "$g_color_gray1"


    #Validar si esta instalado VIM/NeoVIM
    local l_status
    #local l_version
    #if [ $p_is_neovim -eq 0  ]; then

    #    check_neovim "${g_path_programs}" 1 1
    #    l_status=$?    #Retorna 3 si no esta instalado

    #    #Si no esta instalado NeoVIM
    #    if [ $l_status -eq 3 ]; then
    #        printf 'No esta instalado NeoVIM. El proceso termina.\n'
    #        return 2
    #    fi
    #else
    #    l_version=$(get_vim_version)

    #    #Si no esta instalado VIM
    #    if [ ! -z "$l_version" ]; then
    #        printf 'No esta instalado VIM. El proceso termina.\n'
    #        return 2
    #    fi
    #fi

    #Validar si NodeJS esta instalado y registrarlo en el PATH de programas del usuario.
    check_nodejs "${g_path_programs}" 1 1
    l_status=$?    #Retorna 3 si no esta instalado

    #Si no esta instalado NodeJS
    if [ $l_status -eq 3 ]; then

        printf 'Recomendaciones:\n'
        if [ $p_is_neovim -eq 0 ]; then
            printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 nvim%b"\n' "$g_color_cian1" "$g_color_reset"
            printf '    > NeoVIM como developer por defecto usa el adaptador LSP y autocompletado nativo. %bNo esta habilitado el uso de CoC%b\n' "$g_color_gray1" "$g_color_reset" 
        else
            printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 vim%b"\n' "$g_color_cian1" "$g_color_reset"
            printf '    > VIM esta como developer pero NO puede usar CoC  %b(requiere que NodeJS este instalando)%b\n' "$g_color_gray1" "$g_color_reset" 
        fi

        return 1

    fi
        

    printf 'Los plugins del IDE CoC de %s tiene componentes que requieren su inicialización para su uso.\n' "$l_tag"
    printf 'Inicializando dichas componentes del plugins...\n\n'

    #Instalando los parseadores de lenguaje de 'nvim-treesitter'
    if [ $p_is_neovim -eq 0  ]; then

        #Requiere un compilador C/C++ y NodeJS: https://tree-sitter.github.io/tree-sitter/creating-parsers#installation
        local l_version=$(_get_gcc_version)
        if [ ! -z "$l_version" ]; then
            printf '  Instalando "language parsers" de TreeSitter "%b:TSInstall html css javascript jq json yaml xml toml typescript proto make sql bash%b"\n' \
                   "$g_color_gray1" "$g_color_reset"
            nvim --headless -c 'TSInstall html css javascript jq json yaml xml toml typescript proto make sql bash' -c 'qa'

            printf '  Instalando "language parsers" de TreeSitter "%b:TSInstall java kotlin llvm lua rust swift c cpp go c_sharp%b"\n' \
                   "$g_color_gray1" "$g_color_reset"
            nvim --headless -c 'TSInstall java kotlin llvm lua rust swift c cpp go c_sharp' -c 'qa'
        fi
    fi

    #Instalando extensiones basicos de CoC: Adaptador de LSP server basicos JS, Json, HTLML, CSS, Python, Bash
    printf '  Instalando extensiones de CoC (Adaptador de LSP server basicos) "%b:CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh%b"\n' \
           "$g_color_gray1" "$g_color_reset"
    if [ $p_is_neovim -ne 0  ]; then
        vim -esc 'CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh' -c 'qa'
    else
        USE_COC=1 nvim --headless -c 'CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh' -c 'qa'
    fi

    #Instalando extensiones basicos de CoC: Motor de snippets 'UtilSnips'
    printf '  Instalando extensiones de CoC (Motor de snippets "UtilSnips") "%b:CocInstall coc-ultisnips%b" (%bno se esta usando el nativo de CoC%b)\n' \
           "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    if [ $p_is_neovim -ne 0  ]; then
        vim -esc 'CocInstall coc-ultisnips' -c 'qa'
    else
        USE_COC=1 nvim --headless -c 'CocInstall coc-ultisnips' -c 'qa'
    fi

    #Actualizar las extensiones de CoC
    printf '  Actualizando los extensiones existentes de CoC, ejecutando el comando "%b:CocUpdate%b"\n' "$g_color_gray1" "$g_color_reset"
    if [ $p_is_neovim -ne 0  ]; then
        vim -esc 'CocUpdate' -c 'qa'
    else
        USE_COC=1 nvim --headless -c 'CocUpdate' -c 'qa'
    fi

    #Actualizando los gadgets de 'VimSpector'
    if [ $p_is_neovim -ne 0  ]; then
        printf '  Actualizando los gadgets de "VimSpector", ejecutando el comando "%b:VimspectorUpdate%b"\n' "$g_color_gray1" "$g_color_reset"
        vim -esc 'VimspectorUpdate' -c 'qa'
    fi


    #Mostrar la Recomendaciones
    printf '\nRecomendaciones:\n'
    if [ $p_is_neovim -ne 0  ]; then

        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 vim%b"\n' "$g_color_cian1" "$g_color_reset"
        printf '    > Se recomienda que configure su IDE CoC segun su necesidad:\n'

    else

        printf '  > Por defecto, se ejecuta el IDE vinculado al LSP nativo de NeoVIM.\n'
        printf '    > Si desea usar CoC, use: "%bUSE_COC=1 nvim%b"\n' "$g_color_cian1" "$g_color_reset"
        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 nvim%b"\n' "$g_color_cian1" "$g_color_reset"

        printf '  > Si usar como Developer con IDE CoC, se recomienda que lo configura segun su necesidad:\n'

    fi

    echo "        1> Instalar extensiones de COC segun su necesidad (Listar existentes \":CocList extensions\")"
    echo "        2> Revisar la Configuracion de COC \":CocConfig\":"
    echo "          2.1> El diganostico se enviara ALE (no se usara el integrado de CoC), revisar:"
    echo "               { \"diagnostic.displayByAle\": true }"
    echo "          2.2> El formateador de codigo 'Prettier' sera proveido por ALE (no se usara la extension 'coc-prettier')"
    echo "               Si esta instalando esta extension, desintalarlo."

    return 0

}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
function _setup_nvim_files() {

    #1. Argumentos
    local l_mode="Editor"
    local p_flag_developer=1
    if [ "$1" = "0" ]; then
        p_flag_developer=0
        l_mode="IDE"
    fi

    local p_flag_overwrite_ln=1
    if [ "$2" = "0" ]; then
        p_flag_overwrite_ln=0
    fi

    #Sobrescribir los enlaces simbolicos
    printf '\n'
    print_line '-' $g_max_length_line "$g_color_gray1" 
    printf 'NeoVIM > Configuración %barchivos basicos%b de NeoVIM como %b%s%b\n' "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_mode" "$g_color_reset"
    print_line '-' $g_max_length_line "$g_color_gray1" 

    #Creando el folder "~/.config/nvim/"
    if [ ! -d "${g_path_base}/.config" ]; then
        mkdir -p ${g_path_base}/.config/nvim/
        if [ ! -z "$g_other_calling_user" ]; then
            chown $g_other_calling_user ${g_path_base}/.config/
            chown $g_other_calling_user ${g_path_base}/.config/nvim
        fi
    elif [ ! -d "${g_path_base}/.config/nvim" ]; then
        mkdir -p ${g_path_base}/.config/nvim/
        if [ ! -z "$g_other_calling_user" ]; then
            chown $g_other_calling_user ${g_path_base}/.config/nvim
        fi
    fi

    
    #2. Creando los enalces simbolicos
    local l_target_link
    local l_source_path
    local l_source_filename

    #Configurar NeoVIM como IDE (Developer)
    if [ $p_flag_developer -eq 0 ]; then


        l_target_link="${g_path_base}/.config/nvim/coc-settings.json"
        l_source_path="${g_path_base}/.files/nvim/ide_coc"
        if [ "$g_path_programs"="${g_path_base}/tools" ]; then
            l_source_filename='coc-settings_lnx_non_shared.json'
        else
            l_source_filename='coc-settings_lnx_shared.json'
        fi
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM > " $p_flag_overwrite_ln


        l_target_link="${g_path_base}/.config/nvim/init.vim"
        l_source_path="${g_path_base}/.files/nvim"
        if [ "$g_path_programs"="${g_path_base}/tools" ]; then
            l_source_filename='init_ide_linux_non_shared.vim'
        else
            l_source_filename='init_ide_linux_shared.vim'
        fi
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM > " $p_flag_overwrite_ln

        l_target_link="${g_path_base}/.config/nvim/lua"
        l_source_path="${g_path_base}/.files/nvim/lua"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_ln

        
        #El codigo open/close asociado a los 'file types'
        l_target_link="${g_path_base}/.config/nvim/ftplugin"
        l_source_path="${g_path_base}/.files/nvim/ide_commom/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_ln


        #Para el codigo open/close asociado a los 'file types' de CoC
        l_target_link="${g_path_base}/.config/nvim/runtime_coc/ftplugin"
        l_source_path="${g_path_base}/.files/nvim/ide_coc/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_ln


        #Para el codigo open/close asociado a los 'file types' que no sean CoC
        l_target_link="${g_path_base}/.config/nvim/runtime_nococ/ftplugin"
        l_source_path="${g_path_base}/.files/nvim/ide_nococ/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_ln

    #Configurar NeoVIM como Editor
    else

        l_target_link="${g_path_base}/.config/nvim/init.vim"
        l_source_path="${g_path_base}/.files/nvim"
        l_source_filename='init_basic_linux.vim'
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM > " $p_flag_overwrite_ln

        
        l_target_link="${g_path_base}/.config/nvim/lua"
        l_source_path="${g_path_base}/.files/nvim/lua"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_ln


        #El codigo open/close asociado a los 'file types' como Editor
        l_target_link="${g_path_base}/.config/nvim/ftplugin"
        l_source_path="${g_path_base}/.files/nvim/editor/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM > " $p_flag_overwrite_ln

    fi

    return 0

}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
function _setup_vim_files() {

    #1. Argumentos
    local l_mode="Editor"
    local p_flag_developer=1
    if [ "$1" = "0" ]; then
        p_flag_developer=0
        l_mode="IDE"
    fi

    local p_flag_overwrite_ln=1
    if [ "$2" = "0" ]; then
        p_flag_overwrite_ln=0
    fi

    #2. Crear el subtitulo
    printf '\n'
    print_line '-' $g_max_length_line "$g_color_gray1" 
    printf 'VIM > Configuración %barchivos basicos%b de VIM como %b%s%b\n' "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_mode" "$g_color_reset"
    print_line '-' $g_max_length_line "$g_color_gray1" 


    #Creando el folder "~/.vim/"
    if [ ! -d "${g_path_base}/.vim" ]; then
        mkdir -p ${g_path_base}/.vim/
        if [ ! -z "$g_other_calling_user" ]; then
            chown $g_other_calling_user ${g_path_base}/.vim
        fi
    fi


    #3. Crear los enlaces simbolicos de VIM
    local l_target_link
    local l_source_path
    local l_source_filename

    #Configurar VIM como IDE (Developer)
    if [ $p_flag_developer -eq 0 ]; then

        #Creando enlaces simbolicos
        l_target_link="${g_path_base}/.vim/coc-settings.json"
        l_source_path="${g_path_base}/.files/vim/ide_coc"
        if [ "$g_path_programs"="${g_path_base}/tools" ]; then
            l_source_filename='coc-settings_lnx_non_shared.json'
        else
            l_source_filename='coc-settings_lnx_shared.json'
        fi
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM > " $p_flag_overwrite_ln

        
        l_target_link="${g_path_base}/.vim/ftplugin"
        l_source_path="${g_path_base}/.files/vim/ide_coc/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "VIM > " $p_flag_overwrite_ln


        l_target_link="${g_path_base}/.vimrc"
        l_source_path="${g_path_base}/.files/vim"
        if [ "$g_path_programs"="${g_path_base}/tools" ]; then
            l_source_filename='vimrc_ide_linux_non_shared.vim'
        else
            l_source_filename='vimrc_ide_linux_shared.vim'
        fi

        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM > " $p_flag_overwrite_ln


    #Configurar VIM como Editor basico
    else

        l_target_link="${g_path_base}/.vimrc"
        l_source_path="${g_path_base}/.files/vim"
        l_source_filename='vimrc_basic_linux.vim'
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM > " $p_flag_overwrite_ln


        l_target_link="${g_path_base}/.vim/ftplugin"
        l_source_path="${g_path_base}/.files/vim/editor/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "VIM > " $p_flag_overwrite_ln


    fi

    return 0

}


#
#Instalar RTE Node.JS
#Si se usa NeoVIM en modo 'Developer', se instalara paquetes adicionales.
#
#Parametro de salida:
# > Valor de retorno:
#      00> Si NodeJS esta instalado o si se instaló correctamente.
#      01> Si NodeJS no se logro instalarse.
#     120> Si no se acepto almacenar la credencial para su instalación
_install_nodejs() {

    #0. Argumentos

    #Inicialización
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    #Instalando NodeJS
    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf 'NodeJS > Instalando %bNodeJS%b\n' "$g_color_cian1" "$g_color_reset" 
    print_line '-' $g_max_length_line  "$g_color_gray1"

    #Validar si 'node' esta en el PATH
    local l_status
    check_nodejs "${g_path_programs}" 0 0
    l_status=$?    #Retorna 3 si no esta instalado

    #Si ya esta instalado
    if [ $l_status -ne 3 ]; then
        return 0
    fi

    #Parametros del script usados hasta el momento:
    # 1> Tipo de llamado: 2/4 (sin menu interactivo/no-interactivo).
    # 2> Listado de ID del repositorios a instalar separados por coma.
    # 3> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado "/opt/tools" o "~/tools".
    # 4> Ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts").
    # 5> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    # 6> El estado de la credencial almacenada para el sudo.
    # 7> Install only last version: por defecto es 1 (false). Solo si ingresa 0, se cambia a 0 (true).
    # 8> Flag '0' para mostrar un titulo si se envia un repositorio en el parametro 2. Por defecto es '1' 
    # 9> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID".
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_path_base}/.files/setup/linux/01_setup_commands.bash 2 "nodejs" "$g_path_programs" "" "$g_path_temp" $g_status_crendential_storage 1 1 "$g_other_calling_user"
        l_status=$?
    else
        ${g_path_base}/.files/setup/linux/01_setup_commands.bash 4 "nodejs" "$g_path_programs" "" "$g_path_temp" $g_status_crendential_storage 1 1 "$g_other_calling_user"
        l_status=$?
    fi

    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #Si no se acepto almacenar credenciales
    elif [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    fi

    #Validar si 'node' esta en el PATH
    echo "$PATH" | grep "${g_path_programs}/nodejs/bin" &> /dev/null
    l_status=$?
    if [ $l_status -ne 0 ]; then
        export PATH=${g_path_programs}/nodejs/bin:$PATH
    fi

    #Si no se logro instalarlo
    if ! node --version 1> /dev/null 2>&1; then
        return 1
    fi

    return 0

}


#Instalar paquetes globales de NodeJS: 'Prettier', 'NeoVIM' y 'TreeSitter CLI'
_install_global_pckg_nodejs() {

    #Argumentos
    local p_flag_install_only_pckg_vim=1
    if [ "$1" = "0" ]; then
        p_flag_install_only_pckg_vim=0
    fi

    #Mostrar el titulo
    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    if [ $p_flag_install_only_pckg_vim -ne 0 ]; then
        printf 'NodeJS > Instalando los %bpaquetes globales%b: %b"Prettier", "NeoVIM" y "TreeSitter CLI"%b\n' \
               "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    else
        printf 'NodeJS > Instalando los %bpaquetes globales%b: "%bPrettier%b"\n' \
               "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    fi
    print_line '-' $g_max_length_line  "$g_color_gray1"




    #Validar si el gestor de paquetes esta configurado
    local l_temp
    l_temp=$(npm list -g --depth=0 2> /dev/null) 
    l_status=$?
    if [ $l_status -ne 0 ]; then           
        echo "NodeJS > ERROR: No se encuentra instalado el gestor de paquetes 'npm'. No se instalaran paquetes basicos..."
        return 2
    fi

    #1. Paquete 'Prettier' para formateo de archivos como json, yaml, js, ...

    #Obtener la version
    if [ -z "$l_temp" ]; then
        l_version="" 
    else
        l_version=$(echo "$l_temp" | grep prettier)
    fi

    #l_version=$(prettier --version 2> /dev/null)
    #l_status=$?
    #if [ $l_status -ne 0 ]; then
    if [ -z "$l_version" ]; then

        if [ $p_flag_install_only_pckg_vim -ne 0 ]; then
            print_line '.' $g_max_length_line "$g_color_gray1"
        fi
        echo "NodeJS > Instalando el comando 'prettier' para formatear archivos json, yaml, js, ..."

        #Se instalara a nivel glabal (puede ser usado por todos los usuarios) y para entornos de desarrallo
        npm install -g --save-dev prettier

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "NodeJS > Comando 'prettier' \"$l_version\" ya esta instalando"
        printf "%b         Si usa JS o TS, se recomienda instalar de manera local los paquetes Node.JS para Linter EsLint:\n" "$g_color_gray1"
        printf "              > npm install --save-dev eslint\n"
        printf "              > npm install --save-dev eslint-plugin-prettier%b\n" "$g_color_reset"
    fi

    if [ $p_flag_install_only_pckg_vim -ne 0 ]; then
        return 0
    fi

    #2. Paquete 'NeoVIM' que ofrece soporte a NeoVIM plugin creados en RTE Node.JS

    #Obtener la version
    if [ -z "$l_temp" ]; then
        l_version="" 
    else
        l_version=$(echo "$l_temp" | grep neovim)
    fi

    if [ -z "$l_version" ]; then

        print_line '.' $g_max_length_line "$g_color_gray1" 
        echo "NodeJS > Instalando el paquete 'neovim' de NodeJS para soporte de plugins en dicho RTE"

        npm install -g neovim

    else
        l_version=$(echo "$l_version" | head -n 1 )
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        echo "NodeJS > Paquete 'neovim' de NodeJS para soporte de plugins con NeoVIM, ya esta instalando: versión \"${l_version}\""
    fi

    #3. Paquete 'TreeSitter CLI' que ofrece soporte al 'Tree-sitter grammar'

    #Obtener la version
    if [ -z "$l_temp" ]; then
        l_version="" 
    else
        l_version=$(echo "$l_temp" | grep tree-sitter-cli)
    fi

    if [ -z "$l_version" ]; then

        print_line '.' $g_max_length_line "$g_color_gray1" 
        echo "NodeJS > Instalando el paquete 'tree-sitter-cli' de Node.JS para soporte de TreeSitter"

        npm install -g tree-sitter-cli

    else
        l_version=$(echo "$l_version" | head -n 1 )
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        echo "NodeJS > Paquete 'tree-sitter-cli' de NodeJS para soporte a TreeSitter, ya esta instalando: versión \"${l_version}\""
    fi

    return 0


}

#Instalar RTE Python3
# Parametro de salida:
# > Valor de retorno:
#      00> Si Python/Pip estan instalado o si se instaló correctamente.
#      01> Si Python esta instalado, pero no se puede instalar pip.
#      02> Si Python no se llego a instalar ni tampoco pip.
#     120> Si no se acepto almacenar la credencial para su instalación
_install_python() {

    #0. Argumentos

    #Inicializaciones
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    #Mostrar el titulo 
    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf 'Python > Instalando %bPython%b y %bPip%b\n' "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    print_line '-' $g_max_length_line  "$g_color_gray1"

    #Determinar si python esta instalado
    local l_packages_to_install=''
    local l_version_python
    local l_version_pip
    l_version_python=$(python3 --version 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ]; then
        l_version_python=''
    fi

    if [ -z "$l_version_python" ]; then
        l_packages_to_install='python,python-pip'
    else

        l_version_python=$(echo "$l_version_python" | sed "$g_regexp_sust_version1")
        printf 'Python > Python "%b%s%b" esta instalado.\n'  "$g_color_gray1" "$l_version_python" "$g_color_reset"

        #Determinar si el gestor de paquete de Python (Pip) esta instalado
        l_version_pip=$(pip3 --version 2> /dev/null)
        l_status=$?

        if [ $l_status -ne 0 ]; then
            l_version_pip=''
        fi

        if [ -z "$l_version_python" ]; then
            l_packages_to_install='python-pip'
        else
            l_version_pip=$(echo "$l_version_python" | sed "$g_regexp_sust_version1")
            printf 'Ptyhon > "Pip" (gestor de paquetes de Python) "%b%s%b" ya esta instalado.\n' "$g_color_gray1" "$l_version_pip" "$g_color_reset"
        fi
    fi

    #Si python y pip estan instalados
    if [ -z "$l_packages_to_install" ]; then
        return 0
    fi

    #Para instalar python, se requiere acceso de root
    if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
        printf 'Se requiere permisos de root para instalar Python/Pip\n'
        if [ ! -z "$l_version_pip" ]; then
            return 1
        fi
        return 2
    fi


    #Instalación de Python3 y/o el modulo 'pip' (gestor de paquetes)

    #Parametros:
    # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
    # 2> Repositorios a instalar/acutalizar: 16 (RTE Python y Pip. Tiene Offset=1)
    # 3> El estado de la credencial almacenada para el sudo
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_path_base}/.files/setup/linux/04_setup_packages.bash 2 "$l_packages_to_install" $g_status_crendential_storage
        l_status=$?
    else
        ${g_path_base}/.files/setup/linux/04_setup_packages.bash 4 "$l_packages_to_install" $g_status_crendential_storage
        l_status=$?
    fi

    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #Si no se acepto almacenar credenciales
    elif [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    fi


    #Si se logro instalarlo
    if pip3 --version 1> /dev/null 2>&1; then
        return 0
    fi

    #Si no se logro instalarlo
    if python3 --version 1> /dev/null 2>&1; then
        return 1
    fi

    return 2

}

#Instalar paquetes de usuario de Python: 'jtbl', 'compiledb', 'rope' y 'pynvim'
_install_user_pckg_python() {

    #Argumentos
    local p_flag_install_only_pckg_vim=1
    if [ "$1" = "0" ]; then
        p_flag_install_only_pckg_vim=0
    fi

    #Mostrar el titulo
    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    if [ $p_flag_install_only_pckg_vim -ne 0 ]; then
        printf 'Python > Instalando los %bpaquetes de usuario%b: %b"jtbl", "compiledb", "rope" y "pynvim"%b\n' \
               "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    else
        printf 'Python > Instalando los %bpaquetes de usuario%b: "%bjtbl%b"\n' \
               "$g_color_cian1" "$g_color_reset""$g_color_gray1" "$g_color_reset"
    fi
    print_line '-' $g_max_length_line  "$g_color_gray1"


    #2. Instalación de Herramienta para mostrar arreglo json al formato tabular
    l_version=$(pip3 list | grep jtbl 2> /dev/null)
    #l_version=$(jtbl -v 2> /dev/null)
    l_status=$?
    #if [ $l_status -ne 0 ]; then
    if [ -z "$l_version" ]; then

        if [ $p_flag_install_only_pckg_vim -ne 0 ]; then
            print_line '.' $g_max_length_line "$g_color_gray1" 
        fi
        echo "Python > Instalando el comando 'jtbl' (modulo python) para mostrar arreglos json en una consola en formato tabular."
        
        #Se instalar a nivel usuario
        pip3 install jtbl --break-system-packages

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "Python > Comando 'jtbl' (modulo python) \"$l_version\" ya esta instalando"
    fi

    if [ $p_flag_install_only_pckg_vim -eq 0 ]; then
        return 0
    fi

    #3. Instalación de Herramienta para generar la base de compilacion de Clang desde un make file
    l_version=$(pip3 list | grep compiledb 2> /dev/null)
    #l_version=$(compiledb -h 2> /dev/null)
    l_status=$?
    #if [ $l_status -ne 0 ] || [ -z "$l_version"]; then
    if [ -z "$l_version" ]; then

        print_line '.' $g_max_length_line "$g_color_gray1" 
        echo "Python > Instalando el comando 'compiledb' (modulo python) para generar una base de datos de compilacion Clang desde un make file."
        
        #Se instalar a nivel usuario
        pip3 install compiledb --break-system-packages

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "Ptyhon > Comando 'compiladb' (modulo python) \"$l_version\" ya esta instalando"
        #echo "Ptyhon > 'compiledb' ya esta instalando"
    fi

    #4. Instalación de la libreria de refactorización de Python (https://github.com/python-rope/rope)
    l_version=$(pip3 list | grep rope 2> /dev/null)
    l_status=$?
    if [ -z "$l_version" ]; then

        print_line '.' $g_max_length_line "$g_color_gray1" 
        echo "Python > Instalando la libreria python 'rope' para refactorización de Python (https://github.com/python-rope/rope)."
        
        #Se instalara a nivel usuario
        pip3 install rope --break-system-packages

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "Python > Libreria 'rope' (modulo python) \"$l_version\" ya esta instalando"
        #echo "Tools> 'compiledb' ya esta instalando"
    fi

    #5. Instalando paquete 'PyNVim' para crear plugins NeoVIM usando RTE Python
    l_version=$(pip3 list | grep pynvim 2> /dev/null)
    l_status=$?
    if [ -z "$l_version" ]; then

        print_line '.' $g_max_length_line "$g_color_gray1" 
        echo "Python > Instalando el paquete 'pynvim' de Python3 para soporte de plugins en dicho RTE"
        
        #Se instalara a nivel usuario
        pip3 install pynvim --break-system-packages

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "Python > Libreria 'pynvim' (modulo python) \"$l_version\" ya esta instalando"
        #echo "Python > 'pynvim' ya esta instalando"
    fi

    return 0

}


#
#Instalar VIM
#
#Parametros de salida:
# > Valor de retorno:
#      00> Si VIM esta instalado o si se instaló correctamente.
#      01> Si VIM no se logro instalarse.
#      99> Si no se solicito instalar VIM
#     120> Si no se acepto almacenar la credencial para su instalación
function _install_vim() {


    #Mostrar el titulo
    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf 'VIM > Instalando %bVIM%b\n' "$g_color_cian1" "$g_color_reset"
    print_line '-' $g_max_length_line  "$g_color_gray1"

    #Determinar si esta instalando VIM
    local l_status
    local l_version
    l_version=$(get_vim_version)
    l_status=$?

    if [ ! -z "$l_version" ]; then
        printf 'VIM > VIM "%b%s%b" ya esta instalado.\n' "$g_color_gray1" "$l_version" "$g_color_reset"
        return 0
    fi

    #Inicializar
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi
    
    #No instalar si no tiene acceso a sudo
    if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
        printf 'VIM > %bVIM puede ser instalado debido a que carece de accesos a root. Se recomienda su instalación%b.\n' "$g_color_red1" "$g_color_reset"
        return 1
    fi
    
    #Instalar VIM

    #Parametros:
    # 1> Tipo de ejecución: 2 (ejecución no-interactiva para instalar/actualizar un respositorio especifico)
    # 2> Packete a instalar/acutalizar.
    # 3> El estado de la credencial almacenada para el sudo
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_path_base}/.files/setup/linux/04_setup_packages.bash 2 'vim' $g_status_crendential_storage
        l_status=$?
    else
        ${g_path_base}/.files/setup/linux/04_setup_packages.bash 4 'vim' $g_status_crendential_storage
        l_status=$?
    fi

    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #Si no se acepto almacenar credenciales
    elif [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    fi

    #Si no se logro instalarlo
    if ! vim --version 1> /dev/null 2>&1; then
        return 1
    fi

    return 0

}


#
#Instalar NoeVIM
#
#Parametros de salida:
# > Valor de retorno:
#      00> Si VIM esta instalado o si se instaló correctamente.
#      01> Si VIM no se logro instalarse.
#      99> Si no se solicito instalar VIM
#     120> Si no se acepto almacenar la credencial para su instalación
function _install_nvim() {

    #Inicializando
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    #Mostrar el titulo    
    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf 'NeoVIM > Instalando %bNeoVIM%b\n' "$g_color_cian1" "$g_color_reset"
    print_line '-' $g_max_length_line  "$g_color_gray1"

    #Validar si 'nvim' esta en el PATH
    check_neovim "${g_path_programs}" 0 0 
    l_status=$?    #Retorna 3 si no esta instalado

    #Si esta instalado, terminar.
    if [ $l_status -ne 3 ]; then
        return 0
    fi

    #Los binarios para arm64 y alpine, se debera usar los repositorios de los SO
    if [ "$g_os_architecture_type" = "aarch64" ] || [ $g_os_subtype_id -eq 1 ]; then

        #Parametros:
        # 1> Tipo de ejecución: 2/4 (ejecución sin menu no-interactiva/interactiva para instalar/actualizar paquetes)
        # 2> Paquete a instalar/acutalizar.
        # 3> El estado de la credencial almacenada para el sudo
        if [ $l_is_noninteractive -eq 1 ]; then
            ${g_path_base}/.files/setup/linux/04_setup_packages.bash 2 "nvim" $g_status_crendential_storage
            l_status=$?
        else
            ${g_path_base}/.files/setup/linux/04_setup_packages.bash 4 "nvim" $g_status_crendential_storage
            l_status=$?
        fi

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
           g_status_crendential_storage=0
        fi

    #Actualmente (2023), en github solo existe binarios para x64 y no para arm64
    else

        #Parametros del script usados hasta el momento:
        # 1> Tipo de llamado: 2/4 (sin menu interactivo/no-interactivo).
        # 2> Listado de ID del repositorios a instalar separados por coma.
        # 3> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado "/opt/tools" o "~/tools".
        # 4> Ruta base donde se almacena los comandos ("CMD_PATH_BASE/bin"), archivos man1 ("CMD_PATH_BASE/man/man1") y fonts ("CMD_PATH_BASE/share/fonts").
        # 5> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
        # 6> El estado de la credencial almacenada para el sudo.
        # 7> Install only last version: por defecto es 1 (false). Solo si ingresa 0, se cambia a 0 (true).
        # 8> Flag '0' para mostrar un titulo si se envia un repositorio en el parametro 2. Por defecto es '1' 
        # 9> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID".
        if [ $l_is_noninteractive -eq 1 ]; then
            
            ${g_path_base}/.files/setup/linux/01_setup_commands.bash 2 "neovim" "$g_path_programs" "" "$g_path_temp" $g_status_crendential_storage 1 1 "$g_other_calling_user"
            l_status=$?
        else
            ${g_path_base}/.files/setup/linux/01_setup_commands.bash 4 "neovim" "$g_path_programs" "" "$g_path_temp" $g_status_crendential_storage 1 1 "$g_other_calling_user"
            l_status=$?
        fi

        #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            return 111
        #Si no se acepto almacenar credenciales
        elif [ $l_status -eq 120 ]; then
            return 120
        #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
        elif [ $l_status -eq 119 ]; then
           g_status_crendential_storage=0
        fi

        #Validar si 'nvim' esta en el PATH
        echo "$PATH" | grep "${g_path_programs}/neovim/bin" &> /dev/null
        l_status=$?
        if [ $l_status -ne 0 ]; then
            export PATH=${g_path_programs}/neovim/bin:$PATH
        fi

    fi

    #Si no se logro instalarlo
    if ! nvim --version 1> /dev/null 2>&1; then
        return 1
    fi

    return 0


}



# Parametros:
# > Opcion ingresada por el usuario.
function _sutup_support_x11_clipboard() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #2. Determinar si se requiere instalar VIM/NeoVIM
    local l_option=32768
    local l_flag_ssh_srv=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_ssh_srv=0
    fi
    
    l_option=16384
    local l_flag_ssh_clt_without_xsrv=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_ssh_clt_without_xsrv=0
    fi

    l_option=8192
    local l_flag_ssh_clt_with_xsrv=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_ssh_clt_with_xsrv=0
    fi

    #Si no se solicitar instalar VIM o NeoVIM no instalar ningun comando
    if [ $l_flag_ssh_srv -ne 0 ] && [ $l_flag_ssh_clt_with_xsrv -ne 0 ] && [ $l_flag_ssh_clt_without_xsrv -ne 0 ]; then
        return 99
    fi
   
    #3. Mostrar el titulo de instalacion

    #Obtener a quien aplica la configuración
    local l_tmp1=""
    if [ $l_flag_ssh_srv -eq 0 ]; then
        l_tmp1="SSH Server"
    fi

    if [ $l_flag_ssh_clt_with_xsrv -eq 0 ] || [ $l_flag_ssh_clt_without_xsrv -eq 0 ]; then
        if [ -z "$l_aux" ]; then
            l_tmp1="SSH Client"
        else
            l_tmp1="${l_aux}/Client"
        fi
    fi


    #Obtener lo que se va configurar/instalar
    local l_tmp2=""
    local l_pkg_options='xclip'
    printf -v l_tmp2 "instalar '%bxclip%b'" "$g_color_gray1" "$g_color_reset"

    if [ $l_flag_ssh_srv -eq 0 ]; then
        printf -v l_tmp2 "%s, '%bxorg-x11-xauth%b', configurar %bOpenSSH server%b" "$l_tmp" "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        l_pkg_options="${l_pkg_options},xauth"
    fi

    if [ $l_flag_ssh_clt_without_xsrv -eq 0 ]; then
        printf -v l_tmp2 "%s, X virtual server '%bXvfb%b'" "$l_tmp" "$g_color_gray1" "$g_color_reset"
        l_pkg_options="${l_pkg_options},xvfb"
    fi

    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_gray1"
    #print_line '─' $g_max_length_line  "$g_color_blue1"
    printf "%bX11 Forwarding%b > Sobre '%b%s%b': %s\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_tmp1" "$g_color_reset" "$l_tmp2"
    #print_line '─' $g_max_length_line "$g_color_blue1"
    print_line '-' $g_max_length_line  "$g_color_gray1"

    #2. Si no se tiene permisos para root, solo avisar
    if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then

        printf '%bNo tiene soporte para ejecutar en modo "root"%b. Para usar el clipbboard de su servidor remotos linux, usando el "%bX11 forwading for SSH%b".\n' \
               "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        printf 'Se recomienda usar la siguiente configuración:\n'

        printf ' > Instale el X cliente "XClip"\n'

        if [ $l_flag_ssh_srv -eq 0 ]; then

            printf ' > Configure el servidor SSH server %b(donde se ejecutará X client)%b\n' "$g_color_gray1" "$g_color_reset"
            printf '   > Configure el servidor OpenSSH server:\n'
            printf '     > Edite el archivo "%b%s%b" y modifique el campo  "%b%s%b" a "%b%sb".\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
                   "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "yes"
            printf '     > Reiniciar el servidor OpenSSH server: %b%s%b\n' "$g_color_gray1" "systemctl restart sshd.service" "$g_color_reset"
            printf '   > Validar si la componente "%bxorg-x11-xauth%b" de autorizacion de X11 esta instalando.\n' "$g_color_gray1" "$g_color_reset"

        fi

        if [ $l_flag_ssh_clt_without_xsrv -eq 0 ]; then
            printf ' > Configure el cliente SSH server en un "%bHeadless Server%b" %b(donde se ejecutará X server)%b\n' "$g_color_yellow1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
            printf '   > Instale el servidor X virtual "%bXvfb%b".\n' "$g_color_gray1" "$g_color_reset"
        fi

        return 1
    fi

    #3. Instalar los programas requeridos 
    local l_version
    local l_status
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi


    printf 'X forwarding> Iniciando %s...\n\n' "$l_tmp"

    #Parametros:
    # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
    # 2> Repositorios a instalar/acutalizar: 
    # 3> El estado de la credencial almacenada para el sudo
    if [ $l_is_noninteractive -eq 1 ]; then
        ${g_path_base}/.files/setup/linux/04_setup_packages.bash 2 "$l_pkg_options" $g_status_crendential_storage
        l_status=$?
    else
        ${g_path_base}/.files/setup/linux/04_setup_packages.bash 4 "$l_pkg_options" $g_status_crendential_storage
        l_status=$?
    fi

    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #Si no se acepto almacenar credenciales
    elif [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    fi


    #5. Configurar OpenSSH server para soportar el 'X11 forwading'
    local l_ssh_config_data=""
    if [ $l_flag_ssh_srv -eq 0 ]; then

        printf '\n'
        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf '%bX11 Forwarding%b > Configurando el servidor OpenSSH...\n' "$g_color_gray1" "$g_color_reset"
        print_line '-' $g_max_length_line "$g_color_gray1"

        #Obtener la data del SSH config del servidor OpenSSH
        if [ $g_user_sudo_support -eq 4 ]; then
            l_ssh_config_data=$(cat /etc/ssh/sshd_config 2> /dev/null)
            l_status=$?
        else
            l_ssh_config_data=$(sudo cat /etc/ssh/sshd_config 2> /dev/null)
            l_status=$?
        fi

        if [ $l_status -ne 0 ]; then
            printf 'No se obtuvo información del archivo "%b%s%b".\n' "$g_color_red1" "/etc/ssh/sshd_config" "$g_color_reset"
            return 1
        fi

    
        if ! echo "$l_ssh_config_data"  | grep '^X11Forwarding\s\+yes\s*$' &> /dev/null; then

            printf 'X forwarding> Modificando el archivo "%b%s%b": editanto el campo "%b%s%b" con el valor "%b%s%b".\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
                   "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "yes" "$g_color_reset"

            if [ $g_user_sudo_support -eq 4 ]; then
                echo "$l_ssh_config_data" | sed 's/^#X11Forwarding\s\+\(no\|yes\)\s*$/X11Forwarding yes/' | sed 's/^X11Forwarding\s\+no\s*$/X11Forwarding yes/' \
                    > /etc/ssh/sshd_config
            else
                echo "$l_ssh_config_data" | sed 's/^#X11Forwarding\s\+\(no\|yes\)\s*$/X11Forwarding yes/' | sed 's/^X11Forwarding\s\+no\s*$/X11Forwarding yes/' | \
                    sudo tee /etc/ssh/sshd_config > /dev/null
            fi

            if [ $g_user_sudo_support -eq 4 ]; then
                printf 'X forwarding> Reiniciando el servidor OpenSSH server: %b%s%b\n' "$g_color_gray1" "systemctl restart sshd.service" "$g_color_reset"
                systemctl restart sshd.service
            else
                printf 'X forwarding> Reiniciando el servidor OpenSSH server: %b%s%b\n' "$g_color_gray1" "sudo systemctl restart sshd.service" "$g_color_reset"
                sudo systemctl restart sshd.service
            fi

        else

            printf 'X forwarding> El archivo "%b%s%b" ya esta configurado (su campo "%b%s%b" tiene el valor "%b%s%b").\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
                   "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "yes" "$g_color_reset"

        fi

    fi


}


# Parametros:
# > Opcion ingresada por el usuario.
function _uninstall_support_x11_clipboard() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #2. Determinar si se requiere instalar VIM/NeoVIM
    local l_flag_ssh_srv=1

    local l_option=65536
    local l_flag=$(( $p_opciones & $l_option ))
    if [ $l_flag -eq $l_option ]; then l_flag_ssh_srv=0; fi
    
    #Si no se solicitar instalar VIM o NeoVIM no instalar ningun comando
    if [ $l_flag_ssh_srv -ne 0 ]; then
        return 99
    fi
   
    #3. Mostrar el titulo de instalacion
    local l_title

    #Obtener a quien aplica la configuración
    local l_tmp="SSH Server"
    #printf -v l_title '%s: %s' "$l_title" "$l_tmp"

    printf '\n'
    print_line '-' $g_max_length_line  "$g_color_blue1"
    printf "%bX11 Forwarding%b > Remover la configuración en '%b%s%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_tmp" "$g_color_reset"
    print_line '-' $g_max_length_line "$g_color_blue1"

    #2. Si no se tiene permisos para root, solo avisar
    if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then

        printf '%bNo tiene soporte para ejecutar en modo "root"%b. Para remover la configuración "%bX11 forwading%b" del OpenSSH Server.\n' \
               "$g_color_red1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        printf 'Se recomienda usar la siguiente configuración:\n'
        printf ' > Edite el archivo "%b%s%b" y modifique el campo  "%b%s%b" a "%b%sb".\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
               "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "no"

        return 1
    fi

    #3. Configurar OpenSSH server para soportar el 'X11 forwading'
    local l_ssh_config_data=""
    if [ $l_flag_ssh_srv -eq 0 ]; then

        printf '%bX forwarding%b> Configurando el servidor OpenSSH...\n' "$g_color_gray1" "$g_color_reset"

        #Obtener la data del SSH config del servidor OpenSSH
        if [ $g_user_sudo_support -eq 4 ]; then
            l_ssh_config_data=$(cat /etc/ssh/sshd_config 2> /dev/null)
            l_status=$?
        else
            l_ssh_config_data=$(sudo cat /etc/ssh/sshd_config 2> /dev/null)
            l_status=$?
        fi

        if [ $l_status -ne 0 ]; then
            printf 'No se obtuvo información del archivo "%b%s%b".\n' "$g_color_red1" "/etc/ssh/sshd_config" "$g_color_reset"
            return 1
        fi

    
        if ! echo "$l_ssh_config_data"  | grep '^X11Forwarding\s\+no\s*$' &> /dev/null; then

            printf 'X forwarding> Modificando el archivo "%b%s%b": editanto el campo "%b%s%b" con el valor "%b%s%b".\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
                   "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "no" "$g_color_reset"

            if [ $g_user_sudo_support -eq 4 ]; then
                echo "$l_ssh_config_data" | sed 's/^#X11Forwarding\s\+\(no\|yes\)\s*$/X11Forwarding no/' | sed 's/^X11Forwarding\s\+yes\s*$/X11Forwarding no/' \
                    > /etc/ssh/sshd_config
            else
                echo "$l_ssh_config_data" | sed 's/^#X11Forwarding\s\+\(no\|yes\)\s*$/X11Forwarding no/' | sed 's/^X11Forwarding\s\+yes\s*$/X11Forwarding no/' | \
                    sudo tee /etc/ssh/sshd_config > /dev/null
            fi

            if [ $g_user_sudo_support -eq 4 ]; then
                printf 'X forwarding> Reiniciando el servidor OpenSSH server: %b%s%b\n' "$g_color_gray1" "systemctl restart sshd.service" "$g_color_reset"
                systemctl restart sshd.service
            else
                printf 'X forwarding> Reiniciando el servidor OpenSSH server: %b%s%b\n' "$g_color_gray1" "sudo systemctl restart sshd.service" "$g_color_reset"
                sudo systemctl restart sshd.service
            fi

        else

            printf 'X forwarding> El archivo "%b%s%b" ya esta configurado (su campo "%b%s%b" tiene el valor "%b%s%b").\n' "$g_color_gray1" "/etc/ssh/sshd_config" "$g_color_reset" \
                   "$g_color_gray1" "X11Forwarding" "$g_color_reset" "$g_color_gray1" "no" "$g_color_reset"

        fi

    fi


}


# Parametros:
# > Opcion ingresada por el usuario.
function _setup_user_profile() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #¿Esta habilitado la creacion de enlaces simbolicos del perfil?
    local l_option=2
    if [ $(( $p_opciones & $l_option )) -ne $l_option ]; then
        return 99 
    fi

    #¿Se puede recrear los enlaces simbolicos en caso existir?
    l_option=4
    local l_flag_overwrite_ln=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_overwrite_ln=0
    fi


    #2. Mostrar el titulo 
    printf '\n'
    print_line '-' $g_max_length_line "$g_color_gray1"
    #print_line '─' $g_max_length_line  "$g_color_blue1"

    if [ $l_flag_overwrite_ln -eq 0 ]; then
        printf "OS > Creando los %benlaces simbolicos%b del perfil %b(sobrescribir lo existente)%b\n" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    else
        printf "OS > Creando los %benlaces simbolicos%b del perfil %b(solo crar si no existe)%b\n" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    fi

    #print_line '─' $g_max_length_line "$g_color_blue1"
    print_line '-' $g_max_length_line  "$g_color_gray1"

    

    #3. Creando enlaces simbolico dependientes del tipo de distribución Linux

    #Si es Linux WSL
    local l_target_link
    local l_source_path
    local l_source_filename

    #Archivo de colores de la terminal usado por comandos basicos
    if [ $g_os_type -eq 1 ]; then

        l_target_link="${g_path_base}/.dircolors"
        l_source_path="${g_path_base}/.files/terminal/linux/profile"
        l_source_filename='ubuntu_wls_dircolors.conf'
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln

    fi

    #Archivo de configuración de Git
    l_target_link="${g_path_base}/.gitconfig"
    l_source_path="${g_path_base}/.files/config/git"
    if [ $g_os_type -eq 1 ]; then
        l_source_filename='git_linux_usr1.toml'
    else
        l_source_filename='git_linux_usr2.toml'
    fi
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Archivo de configuración de SSH
    l_target_link="${g_path_base}/.ssh/config"
    l_source_path="${g_path_base}/.files/config/ssh"
    if [ $g_os_type -eq 1 ]; then
        l_source_filename='ssh_linux_01.conf'
    else
        l_source_filename='ssh_linux_02.conf'
    fi
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Archivos de configuración de PowerShell
    l_target_link="${g_path_base}/.config/powershell/Microsoft.PowerShell_profile.ps1"
    l_source_path="${g_path_base}/.files/terminal/powershell/profile"
    if [ "$g_path_programs"="${g_path_base}/tools" ]; then
        if [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                l_source_filename='debian_aarch64_local.ps1'
            else
                l_source_filename='debian_x64_local.ps1'
            fi
        else
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                l_source_filename='fedora_aarch64_local.ps1'
            else
                l_source_filename='fedora_x64_local.ps1'
            fi
        fi
    else
        if [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                l_source_filename='debian_aarch64_shared.ps1'
            else
                l_source_filename='debian_x64_shared.ps1'
            fi
        else
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                l_source_filename='fedora_aarch64_shared.ps1'
            else
                l_source_filename='fedora_x64_shared.ps1'
            fi
        fi
    fi
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln

    #Creando el profile del interprete shell
    l_target_link="${g_path_base}/.bashrc"
    l_source_path="${g_path_base}/.files/terminal/linux/profile"
    if [ "$g_path_programs"="${g_path_base}/tools" ]; then
        if [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                l_source_filename='debian_aarch64_local.bash'
            else
                l_source_filename='debian_x64_local.bash'
            fi
        else
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                l_source_filename='fedora_aarch64_local.bash'
            else
                l_source_filename='fedora_x64_local.bash'
            fi
        fi
    else
        if [ $g_os_subtype_id -ge 30 ] && [ $g_os_subtype_id -lt 50 ]; then
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                l_source_filename='debian_aarch64_shared.bash'
            else
                l_source_filename='debian_x64_shared.bash'
            fi
        else
            if [ "$g_os_architecture_type" = "aarch64" ]; then
                l_source_filename='fedora_aarch64_shared.bash'
            else
                l_source_filename='fedora_x64_shared.bash'
            fi
        fi
    fi
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #4. Creando enlaces simbolico independiente del tipo de distribución Linux

    #Crear el enlace de TMUX
    l_target_link="${g_path_base}/.tmux.conf"
    l_source_path="${g_path_base}/.files/terminal/linux/tmux"
    l_source_filename='tmux.conf'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln

    #Configuración de un CLI de alto nivel del 'Container Runtime' 'ContainerD': nerdctl
    l_target_link="${g_path_base}/.config/nerdctl/nerdctl.toml"
    l_source_path="${g_path_base}/.files/config/nerdctl"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Configuración principal de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless'): Podman
    l_target_link="${g_path_base}/.config/containers/containers.conf"
    l_source_path="${g_path_base}/.files/config/podman"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln

    #Configuración de los registros de imagenes de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless'): Podman
    l_target_link="${g_path_base}/.config/containers/registries.conf"
    l_source_path="${g_path_base}/.files/config/podman"
    l_source_filename='default_registries.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Configuración de un 'Container Runtime' 'ContainerD' (en modo 'rootless')
    l_target_link="${g_path_base}/.config/containerd/config.toml"
    l_source_path="${g_path_base}/.files/config/containerd"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Configuración del backend de compilacion de imagenes 'BuildKit' (en modo 'rootless')
    l_target_link="${g_path_base}/.config/buildkit/buildkitd.toml"
    l_source_path="${g_path_base}/.files/config/buildkit"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Configuracion por defecto para un Cluster de Kubernates
    l_target_link="${g_path_base}/.kube/config"
    l_source_path="${g_path_base}/.files/config/kubectl"
    l_source_filename='default_config.yaml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln

    return 0

}



# Remover el gestor de paquetes VIM-Plug en VIM/NeoVIM y Packer en NeoVIM
function _remove_vim_plugin_manager() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    local l_flag_title=1

    #Eliminar VIM-Plug en VIM
    local l_option=34359738368
    local l_flag_removed=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

        if [ $l_flag_title -eq 0 ]; then
            printf '\n'
            print_line '-' $g_max_length_line "$g_color_gray1"
            printf 'VIM > Removiendo gestor de Plugins\n'
            print_line '-' $g_max_length_line "$g_color_gray1"
            l_flag_title=1
        fi

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
            printf 'No esta instalando el gestor de paquetes "VIM-Plug" en VIM\n'
        fi

    fi


    #Eliminar VIM-Plug en NeoVIM
    l_option=68719476736
    l_flag_removed=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

        if [ $l_flag_title -eq 0 ]; then
            printf '\n'
            print_line '-' $g_max_length_line "$g_color_gray1"
            printf 'VIM > Removiendo gestor de Plugins\n'
            print_line '-' $g_max_length_line "$g_color_gray1"
            l_flag_title=1
        fi

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
            printf 'No esta instalando el gestor de paquetes "VIM-Plug" en NeoVIM\n'
        fi

    fi

    #Eliminar Packer en NeoVIM
    l_option=137438953472
    l_flag_removed=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

        if [ $l_flag_title -eq 0 ]; then
            printf '\n'
            print_line '-' $g_max_length_line "$g_color_gray1"
            printf 'VIM > Removiendo gestor de Plugins\n'
            print_line '-' $g_max_length_line "$g_color_gray1"
            l_flag_title=1
        fi

        #if [ -d ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]; then
        #    echo "Eliminado '~/.local/share/nvim/site/pack/packer/start/packer.nvim' ..."
        #    rm -rf ~/.local/share/nvim/site/pack/packer/start/packer.nvim
        #    l_flag_removed=0
        #fi

        if [ -d ~/.local/share/nvim/site/pack/packer/ ]; then
            echo "Eliminado el folder '~/.local/share/nvim/site/pack/packer/' ..."
            rm -rf ~/.local/share/nvim/site/pack/packer/
            l_flag_removed=0
        fi

        if [ $l_flag_removed -ne 0 ]; then
            printf 'No esta instalando el gestor de paquetes "Packer" en NeoVIM\n'
        fi

    fi

}

# Instalar Python, NodeJS, VIM/NeoVIM y luego configurarlo para que sea Editor/IDE (Crear archivos/folderes de configuración, 
# Descargar Plugin, Indexar la documentación de los plugin).
# Parametros de entrada:
#  1> Opción de menu a ejecutar
# Parametros de salida:
#  111> No se cumplio con requesitos obligatorios. Detener el proceso.
#  120> No se almaceno el password para sudo (solo cuando se requiere).
function _setup_vim_environment() {

    #00. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #01. Instalar Python y su gestor de paquetes Pip
    local l_status=0
    local l_is_python_installed=-1   #(-1) No determinado, (0) Instalado, (1) Solo instalado Python pero no Pip, (2) No instalado ni Python ni Pip

    local l_option=8
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

        #Instalar Python
        _install_python
        l_status=$?

        #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            return 111
        #Si no se acepto almacenar credenciales
        elif [ $l_status -eq 120 ]; then
            return 120
        elif [ $l_status -eq 0 ]; then
            l_is_python_installed=0
        elif [ $l_status -eq 1 ]; then
            l_is_python_installed=1
        else
            l_is_python_installed=2
        fi

    fi


    #02. Instalar los paquetes basicos de Python
    local l_flag_setup=2    #(0) Instalar solo basico, (1) Instalar todos los paquetes, (2) No instalar.
                            #'Instalar todos' tiene mayor prioridad respecto a 'Instalar solo lo basico'

    #¿Instalar todos los paquetes: 'jtbl', 'compiledb', 'rope' y 'pynvim'?
    l_option=32
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup=1
    fi

    #¿Instalar solo paquetes basicos: 'jtbl'?
    if [ $l_flag_setup -eq 2 ]; then
        l_option=131072
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_setup=0
        fi
    fi

    if [ $l_flag_setup -ne 2 ]; then

        #Se reqioere temer instalado Python y Pip
        #Si aun no se ha revisado si se ha instalado
        if [ $l_is_python_installed -eq -1 ]; then

            if python3 --version 1> /dev/null 2>&1; then
                if ! pip3 --version 1> /dev/null 2>&1; then
                    printf 'Python > %bEl gestor de paquetes de Python "Pip" NO esta instalado%b. Es requerido para instalar los paquetes:\n'  "$g_color_red1" "$g_color_reset"
                    l_is_python_installed=1
                    l_flag_setup=2
                else
                    l_is_python_installed=0
                fi
            else
                printf 'Python > %bPython3 NO esta instalado%b. Es requerido para instalar los paquetes:\n'  "$g_color_red1" "$g_color_reset"
                l_is_python_installed=2
                l_flag_setup=2
            fi
        #Si ya se reviso y se conoce que no esta instalado o solo esta instalado su gestor de paquetes Pip
        elif [ $l_is_python_installed -ne 0 ]; then
            l_flag_setup=2
        fi

        #Instalar paquetes
        if [ $l_flag_setup -ne 2 ]; then

            #Instalar sus paquetes basicos
            if [ $l_flag_setup -eq 0 ]; then
                _install_user_pckg_python 0
                l_status=$?
            else
                _install_user_pckg_python 1
                l_status=$?
            fi

            #No se cumplen las precondiciones obligatorios
            if [ $l_status -eq 111 ]; then
                return 111
            #Si no se acepto almacenar credenciales
            elif [ $l_status -eq 120 ]; then
                return 120
            fi

        #Si no estalado Python o Pip, mostrar info adicional
        else
            if [ $l_install_basic_packages -ne 0 ]; then
                printf '%b       > Comando jtbl      : "pip3 install jtbl --break-system-packages" (mostrar arreglos json en tablas en consola)\n' "$g_color_gray1"
                printf '         > Comando compiledb : "pip3 install compiledb --break-system-packages" (utilidad para generar make file para Clang)\n'
                printf '         > Comando rope      : "pip3 install rope --break-system-packages" (utilidad para refactorización de Python)\n'
                printf '         > Comando pynvim    : "pip3 install pynvim --break-system-packages" (soporte plugin en Python para NeovIM)%b\n' "$g_color_reset"
            else
                printf '%b       > Comando jtbl      : "pip3 install jtbl --break-system-packages" (mostrar arreglos json en tablas en consola)%b\n' "$g_color_gray1" "$g_color_reset"
            fi
        fi

    fi


    #03. Instalar NodeJS
    local l_is_nodejs_installed=-1   #(-1) No determinado, (0) Instalado, (1) No instalado

    l_option=16
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

        #Instalar NodeJS
        _install_nodejs
        l_status=$?

        #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            return 111
        #Si no se acepto almacenar credenciales
        elif [ $l_status -eq 120 ]; then
            return 120
        elif [ $l_status -eq 0 ]; then
            l_is_nodejs_installed=0
        else
            l_is_nodejs_installed=1
        fi

    fi


    #04. Instalar los paquetes basicos de NodeJS
    local l_flag_setup=2    #(0) Instalar solo basico, (1) Instalar todos los paquetes, (2) No instalar.
                            #'Instalar todos' tiene mayor prioridad respecto a 'Instalar solo lo basico'

    #¿Instalar todos los paquetes: 'Prettier', 'NeoVIM' y 'TreeSitter CLI'?
    l_option=64
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup=0
    fi

    #¿Instalar solo paquetes basicos: 'Prettier'?
    if [ $l_flag_setup -eq 2 ]; then
        l_option=262144
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_setup=1
        fi
    fi

    if [ $l_flag_setup -ne 2 ]; then

        #Se reqioere temer instalado NodeJS
        #Si aun no se ha revisado si se ha instalado
        if [ $l_is_python_installed -eq -1 ]; then

            #Validar si 'node' esta en el PATH
            check_nodejs "${g_path_programs}" 1 1 
            l_status=$?    #Retorna 3 si no esta instalado

            if [ $l_status -eq 3 ]; then
                printf 'NodeJS > %bNodeJS NO esta instalado%b. Es requerido para instalar sus paquetes.\n' "$g_color_red1" "$g_color_reset"
                l_is_nodejs_installed=1
                l_flag_setup=2
            else
                l_is_nodejs_installed=0
            fi

        #Si ya se reviso y se conoce que no esta instalado
        elif [ $l_is_python_installed -ne 0 ]; then
            printf 'NodeJS > %bNodeJS NO esta instalado%b. Es requerido para instalar sus paquetes.\n' "$g_color_red1" "$g_color_reset"
            l_flag_setup=2
        fi

        #Si esta instalado NodeJS, instalar paquetes
        if [ $l_flag_setup -ne 2 ]; then

            #Instalar sus paquetes basicos
            if [ $l_flag_setup -eq 0 ]; then
                _install_global_pckg_nodejs 0
                l_status=$?
            else
                _install_global_pckg_nodejs 1
                l_status=$?
            fi

            #No se cumplen las precondiciones obligatorios
            if [ $l_status -eq 111 ]; then
                return 111
            #Si no se acepto almacenar credenciales
            elif [ $l_status -eq 120 ]; then
                return 120
            fi

        fi

    fi

    
    #05. Instalando VIM
    local l_is_vim_installed=-1   #(-1) No determinado, (0) Instalado, (1) No instalado
    l_option=128
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

        _install_vim
        l_status=$?

         #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            return 111
        #Se requiere almacenar las credenciales para realizar cambiso con sudo.
        elif [ $l_status -eq 120 ]; then
            return 120
        elif [ $l_status -eq 0 ]; then
            l_is_vim_installed=0
        else
            l_is_vim_installed=1
        fi
    fi

    #06. Instalando NeoVIM
    local l_is_nvim_installed=-1   #(-1) No determinado, (0) Instalado, (1) No instalado
    l_option=1024
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

        _install_nvim
        l_status=$?

        #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            return 111
        #Se requiere almacenar las credenciales para realizar cambiso con sudo.
        elif [ $l_status -eq 120 ]; then
            return 120
        elif [ $l_status -eq 0 ]; then
            l_is_nvim_installed=0
        else
            l_is_nvim_installed=1
        fi
    fi

    #07. Incializacion general antes de la configuración de VIM o NeoVIM

    #VIM > ¿Configurar como IDE?
    local l_flag_setup_full_vim=-1    #(-1) No configurar, (0) Configurar como IDE, (1) Configurar como Editor.
    l_option=512
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_full_vim=0
    fi

    #VIM > ¿Configurar como Editor?
    if [ $l_flag_setup_full_vim -ne 0 ]; then
        l_option=256
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_setup_full_vim=1
        fi
    fi

    #NeoVIM > ¿Configurar como IDE?
    local l_flag_setup_full_nvim=-1    #(-1) No configurar, (0) Configurar como IDE, (1) Configurar como Editor.
    l_option=4096
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup_full_nvim=0
    fi

    #NeoVIM > ¿Configurar como Editor?
    if [ $l_flag_setup_full_nvim -ne 0 ]; then
        l_option=2048
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_setup_full_nvim=1
        fi
    fi

    #¿Sobrescribir los enlaces simbolicos o solo crearlos si no existe?
    local l_flag_overwrite_ln=1
    l_option=4
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_overwrite_ln=0
    fi


    #08. Configurando VIM> Crear los archivos/folderes de configuración
    l_flag_setup=$l_flag_setup_full_vim    #(-1) No configurar, (0) Configurar como IDE, (1) Configurar como Editor.

    if [ $l_flag_setup -ne 0 ]; then

        #¿Configurar como IDE?
        l_option=1048576
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_setup=0
        fi

        #¿Configurar como Editor?
        if [ $l_flag_setup -eq -1 ]; then
            l_option=524288
            if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
                l_flag_setup=1
            fi
        fi

    fi

    if [ $l_flag_setup -ne -1 ]; then

        #Crear los archivos/foldores de configuración
        _setup_vim_files $l_flag_setup $l_flag_overwrite_ln
        l_status=$?

    fi


    #09. Configurando VIM> Descargar los plugin y/o Indexar su documentación
    l_flag_setup=$l_flag_setup_full_vim    #(-1) No configurar, (0) Configurar como IDE, (1) Configurar como Editor.

    local l_flag_non_index_docs=0    #'Indexar' tiene mayor prioridad que 'no indexar'
    if [ $l_flag_setup -ne -1 ]; then
        l_flag_non_index_docs=1
    fi

    if [ $l_flag_setup -ne 0 ]; then

        #¿Configurar como IDE? (indexar la documentación)
        l_option=8388608
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_setup=0
            l_flag_non_index_docs=1
        fi

        #¿Configurar como IDE? (no indexar la documentación)
        if [ $l_flag_setup -ne 0 ]; then
            l_option=16777216
            if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
                l_flag_setup=0
                l_flag_non_index_docs=0
            fi
        fi

        #¿Configurar como Editor? (indexar la documentación)
        if [ $l_flag_setup -eq -1 ]; then
            l_option=2097152
            if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
                l_flag_setup=1
                l_flag_non_index_docs=1
            fi
        fi

        #¿Configurar como Editor? (no indexar la documentación)
        if [ $l_flag_setup -eq -1 ]; then
            l_option=4194304
            if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
                l_flag_setup=1
                l_flag_non_index_docs=0
            fi
        fi

    fi

    local l_version
    if [ $l_flag_setup -ne -1 ]; then

        #Si se indexa la documentación, requiere que VIM este instalado
        if [ $l_flag_non_index_docs -eq 1 ]; then
           
            #Si aun no se conoce si esta instalado
            if [ $l_is_vim_installed -eq -1 ]; then
                l_version=$(get_vim_version)
                if [ -z "$l_version" ]; then
                    l_is_vim_installed=1
                    #No esta instalado VIM, No configurarlo
                    l_flag_setup=-1
                    printf 'VIM > %bVIM NO esta instalado%b. Es requerido para indexar la documentación de los plugins.\n' "$g_color_red1" "$g_color_reset"

                    #Si no se comple lo requisitos obligatorios (tener VIM instalado): abortar todo el proceso.
                    #Si desea continuar con otro procesos, comentarlo
                    return 111

                else
                    l_is_vim_installed=0
                fi
            #Si ya se conoce que no esta instalado
            elif [ $l_is_vim_installed -eq 1 ]; then
                #No esta instalado VIM, No configurarlo
                l_flag_setup=-1
                printf 'VIM > %bVIM NO esta instalado%b. Es requerido para indexar la documentación de los plugins.\n' "$g_color_red1" "$g_color_reset"

                #Si no se comple lo requisitos obligatorios (tener VIM instalado): abortar todo el proceso.
                #Si desea continuar con otro procesos, comentarlo
                return 111

            fi

        fi

        #Instalando los paquetes de VIM e indexando la documentación
        if [ $l_flag_setup -ne -1 ]; then
            _download_vim_packages 1 $l_flag_setup $l_flag_non_index_docs
            l_status=$?

            #Si no se comple lo requisitos obligatorios (tener Git instalado): abortar todo el proceso.
            #Si desea continuar con otro procesos, comentarlo
            if [ $l_status -eq 111 ]; then
                return 111
            fi
        fi


    fi
    
    #11. Configurando VIM> Configurar los plugin del IDE (solo en modo IDE)
    l_flag_setup=$l_flag_setup_full_vim    #(-1) No configurar, (0) Configurar como IDE, (1) Configurar como Editor.
    
    #¿se configura los plugins del IDE?
    if [ $l_flag_setup -ne 0 ]; then

        l_option=67108864
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_setup=0
        fi

    fi

    #Configurar los plugins
    if [ $l_flag_setup -eq 0 ]; then

        #Requiere que VIM este instalado
        #Si aun no se conoce si esta instalado
        if [ $l_is_vim_installed -eq -1 ]; then
            l_version=$(get_vim_version)
            if [ -z "$l_version" ]; then
                l_is_vim_installed=1
                #No esta instalado VIM, No configurarlo
                l_flag_setup=-1
                printf 'VIM > %bVIM NO esta instalado%b. Es requerido para configurar los plugins del IDE.\n' "$g_color_red1" "$g_color_reset"
            else
                l_is_vim_installed=0
            fi
        #Si ya se conoce que no esta instalado
        elif [ $l_is_vim_installed -eq 1 ]; then
            #No esta instalado VIM, No configurarlo
            l_flag_setup=-1
            printf 'VIM > %bVIM NO esta instalado%b. Es requerido para configurar los plugins del IDE.\n' "$g_color_red1" "$g_color_reset"
        fi


        #Requiere que los archivos de configuración (profile) ya este creados como IDE
        if [ $l_flag_setup -eq 0 ]; then

            check_vim_profile 1
            l_status=$?

            if [ $l_status -eq 2 ]; then
                #No esta configura sus archivos, No configurarlo
                l_flag_setup=-1
                printf 'VIM > %bNO se han creado los archivos/carpetas de configuración de VIM%b. Estos son requeridos para configurar los plugins del IDE.\n' "$g_color_red1" "$g_color_reset"
            elif [ $l_status -eq 0 ]; then
                #Esta configura solo como Editor, No configurarlo
                l_flag_setup=-1
                printf 'VIM > %bLos archivos/carpetas de configuración de VIM son de un Editor%b. Se requiere que sean compatible a los plugins de modo IDE.\n' "$g_color_red1" "$g_color_reset"
            fi

        fi

        #Requiere uqe los plugin estan desacargados como IDE
        if [ $l_flag_setup -eq 0 ]; then

            check_vim_plugins 1
            l_status=$?

            if [ $l_status -eq 2 ]; then
                #No esta configura sus plugins, No configurarlo
                l_flag_setup=-1
                printf 'VIM > %bLos plugins de VIM no estan descargados%b. Se requiere para configurar los plugins de VIM como IDE.\n' "$g_color_red1" "$g_color_reset"
            elif [ $l_status -eq 0 ]; then
                #Esta configura solo como Editor, No configurarlo
                l_flag_setup=-1
                printf 'VIM > %bLos plugins de VIM descargados son de un editor%b. Se requiere plugins de IDE para VIM.\n' "$g_color_red1" "$g_color_reset"
            fi

        fi

        #Configurar los plugins
        if [ $l_flag_setup -eq 0 ]; then
            _config_developer_vim 1
            l_status=$?
        fi

    fi

    #12. Configurando VIM> Indexar la documentación de los plugin existentes
    l_flag_setup=1  #(1) No configurar, (0) Configurar.
    
    #¿se indexa la documentación de los plugins?
    l_option=33554432
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup=0
    fi
    
    #Indexar la documentación de los plugins
    if [ $l_flag_setup -eq 0 ]; then

        #Requiere que VIM este instalado
        #Si aun no se conoce si esta instalado
        if [ $l_is_vim_installed -eq -1 ]; then
            l_version=$(get_vim_version)
            if [ -z "$l_version" ]; then
                l_is_vim_installed=1
                #No esta instalado VIM, No configurarlo
                l_flag_setup=1
                printf 'VIM > %bVIM no esta instalado%b. Se requiere que VIM este instalado para indexar la documentación de los plugins.\n' "$g_color_red1" "$g_color_reset"
            else
                l_is_vim_installed=0
            fi
        #Si ya se conoce que no esta instalado
        elif [ $l_is_vim_installed -eq 1 ]; then
            #No esta instalado VIM, No configurarlo
            l_flag_setup=1
            printf 'VIM > %bVIM no esta instalado%b. Se requiere que VIM este instalado para indexar la documentación de los plugins.\n' "$g_color_red1" "$g_color_reset"
        fi

        #Indexar la documentación de los plugins
        if [ $l_flag_setup -eq 0 ]; then
            _index_doc_of_vim_packages 1
            l_status=$?
        fi

    fi


    #13. Configurando NeoVIM> Crear los archivos/folderes de configuración
    l_flag_setup=$l_flag_setup_full_nvim    #(-1) No configurar, (0) Configurar como IDE, (1) Configurar como Editor.

    if [ $l_flag_setup -ne 0 ]; then

        #¿Configurar como IDE?
        l_option=268435456
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_setup=0
        fi

        #¿Configurar como Editor?
        if [ $l_flag_setup -eq -1 ]; then
            l_option=134217728
            if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
                l_flag_setup=1
            fi
        fi

    fi

    if [ $l_flag_setup -ne -1 ]; then

        #Crear los archivos/foldores de configuración
        _setup_nvim_files $l_flag_setup $l_flag_overwrite_ln
        l_status=$?

    fi


    #14. Configurando NeoVIM> Descargar los plugin y/o Indexar su documentación
    l_flag_setup=$l_flag_setup_full_nvim    #(-1) No configurar, (0) Configurar como IDE, (1) Configurar como Editor.

    l_flag_non_index_docs=0    #'Indexar' tiene mayor prioridad que 'no indexar'
    if [ $l_flag_setup -ne -1 ]; then
        l_flag_non_index_docs=1
    fi

    if [ $l_flag_setup -ne 0 ]; then

        #¿Configurar como IDE? (indexar la documentación)
        l_option=2147483648
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_setup=0
            l_flag_non_index_docs=1
        fi

        #¿Configurar como IDE? (no indexar la documentación)
        if [ $l_flag_setup -ne 0 ]; then
            l_option=4294967296
            if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
                l_flag_setup=0
                l_flag_non_index_docs=0
            fi
        fi

        #¿Configurar como Editor? (indexar la documentación)
        if [ $l_flag_setup -eq -1 ]; then
            l_option=536870912
            if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
                l_flag_setup=1
                l_flag_non_index_docs=1
            fi
        fi

        #¿Configurar como Editor? (no indexar la documentación)
        if [ $l_flag_setup -eq -1 ]; then
            l_option=1073741824
            if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
                l_flag_setup=1
                l_flag_non_index_docs=0
            fi
        fi

    fi

    if [ $l_flag_setup -ne -1 ]; then

        #Si se indexa la documentación, requiere que NeoVIM este instalado
        if [ $l_flag_non_index_docs -eq 1 ]; then
           
            #Si aun no se conoce si esta instalado
            if [ $l_is_nvim_installed -eq -1 ]; then

                check_neovim "$g_path_programs" 1 1
                l_status=$?
                if [ $l_status -eq 3 ]; then
                    l_is_nvim_installed=1
                    #No esta instalado NeoVIM, No configurarlo
                    l_flag_setup=-1
                    printf 'NeoVIM > %bNeoVIM NO esta instalado%b. Es requerido para indexar la documentación de los plugins.\n' "$g_color_red1" "$g_color_reset"

                    #Si no se comple lo requisitos obligatorios (tener NeoVIM instalado): abortar todo el proceso.
                    #Si desea continuar con otro procesos, comentarlo
                    return 111

                else
                    l_is_nvim_installed=0
                fi

            #Si ya se conoce que no esta instalado
            elif [ $l_is_nvim_installed -eq 1 ]; then
                #No esta instalado NeoVIM, No configurarlo
                l_flag_setup=-1
                printf 'NeoVIM > %bNeoVIM NO esta instalado%b. Es requerido para indexar la documentación de los plugins.\n' "$g_color_red1" "$g_color_reset"

                #Si no se comple lo requisitos obligatorios (tener NeoVIM instalado): abortar todo el proceso.
                #Si desea continuar con otro procesos, comentarlo
                return 111

            fi

        fi

        #Instalando los paquetes de VIM e indexando la documentación
        if [ $l_flag_setup -ne -1 ]; then
            _download_vim_packages 0 $l_flag_setup $l_flag_non_index_docs
            l_status=$?

            #Si no se comple lo requisitos obligatorios (tener Git instalado): abortar todo el proceso.
            #Si desea continuar con otro procesos, comentarlo
            if [ $l_setup -eq 111 ]; then
                return 111
            fi
        fi

    fi
    
    #15. Configurando NeoVIM> Configurar los plugin del IDE (solo en modo IDE)
    l_flag_setup=$l_flag_setup_full_nvim    #(-1) No configurar, (0) Configurar como IDE, (1) Configurar como Editor.
    
    #¿se configura los plugins del IDE?
    if [ $l_flag_setup -ne 0 ]; then

        l_option=17179869184
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            l_flag_setup=0
        fi

    fi

    #Configurar los plugins
    if [ $l_flag_setup -eq 0 ]; then

        #Requiere que NeoVIM este instalado
        #Si aun no se conoce si esta instalado
        if [ $l_is_nvim_installed -eq -1 ]; then

            check_neovim "$g_path_programs" 1 1
            l_status=$?
            if [ $l_status -eq 3 ]; then
                l_is_nvim_installed=1
                #No esta instalado NeoVIM, No configurarlo
                l_flag_setup=-1
                printf 'NeoVIM > %bNeoVIM NO esta instalado%b. Es requerido para configurar los plugins del IDE.\n' "$g_color_red1" "$g_color_reset"
            else
                l_is_nvim_installed=0
            fi

        #Si ya se conoce que no esta instalado
        elif [ $l_is_nvim_installed -eq 1 ]; then
            #No esta instalado NeoVIM, No configurarlo
            l_flag_setup=-1
            printf 'NeoVIM > %bNeoVIM NO esta instalado%b. Es requerido para configurar los plugins del IDE.\n' "$g_color_red1" "$g_color_reset"
        fi


        #Requiere que los archivos de configuración (profile) ya este creados como IDE
        if [ $l_flag_setup -eq 0 ]; then

            check_vim_profile 0
            l_status=$?

            if [ $l_status -eq 2 ]; then
                #No esta configura sus archivos, No configurarlo
                l_flag_setup=-1
                printf 'NeoVIM > %bNO se han creado los archivos/carpetas de configuración de VIM%b. Estos son requeridos para configurar los plugins del IDE.\n' "$g_color_red1" "$g_color_reset"
            elif [ $l_status -eq 0 ]; then
                #Esta configura solo como Editor, No configurarlo
                l_flag_setup=-1
                printf 'NeoVIM > %bLos archivos/carpetas de configuración de VIM son de un Editor%b. Se requiere que sean compatible a los plugins de modo IDE.\n' "$g_color_red1" "$g_color_reset"
            fi

        fi

        #Requiere uqe los plugin estan desacargados como IDE
        if [ $l_flag_setup -eq 0 ]; then

            check_vim_plugins 0
            l_status=$?

            if [ $l_status -eq 2 ]; then
                #No esta configura sus plugins, No configurarlo
                l_flag_setup=-1
                printf 'NeoVIM > %bLos plugins de NeoVIM no estan descargados%b. Se requiere para configurar los plugins de NeoVIM como IDE.\n' "$g_color_red1" "$g_color_reset"
            elif [ $l_status -eq 0 ]; then
                #Esta configura solo como Editor, No configurarlo
                l_flag_setup=-1
                printf 'NeoVIM > %bLos plugins de NeoVIM descargados son de un editor%b. Se requiere plugins de IDE para NeoVIM.\n' "$g_color_red1" "$g_color_reset"
            fi

        fi

        #Configurar los plugins
        if [ $l_flag_setup -eq 0 ]; then
            _config_developer_vim 0
            l_status=$?
        fi

    fi

    #16. Configurando NeoVIM> Indexar la documentación de los plugin existentes
    l_flag_setup=1  #(1) No configurar, (0) Configurar.
    
    #¿se indexa la documentación de los plugins?
    l_option=8589934592
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_setup=0
    fi
    
    #Indexar la documentación de los plugins
    if [ $l_flag_setup -eq 0 ]; then

        #Requiere que NeoVIM este instalado
        #Si aun no se conoce si esta instalado
        if [ $l_is_nvim_installed -eq -1 ]; then

            check_neovim "$g_path_programs" 1 1
            l_status=$?
            if [ $l_status -eq 3 ]; then
                l_is_nvim_installed=1
                #No esta instalado NeoVIM, No configurarlo
                l_flag_setup=1
                printf 'NeoVIM > %bNeoVIM no esta instalado%b. Se requiere que NeoVIM este instalado para indexar la documentación de los plugins.\n' "$g_color_red1" "$g_color_reset"
            else
                l_is_nvim_installed=0
            fi

        #Si ya se conoce que no esta instalado
        elif [ $l_is_nvim_installed -eq 1 ]; then
            #No esta instalado NeoVIM, No configurarlo
            l_flag_setup=1
            printf 'NeoVIM > %bNeoVIM no esta instalado%b. Se requiere que NeoVIM este instalado para indexar la documentación de los plugins.\n' "$g_color_red1" "$g_color_reset"
        fi

        #Indexar la documentación de los plugins
        if [ $l_flag_setup -eq 0 ]; then
            _index_doc_of_vim_packages 0
            l_status=$?
        fi

    fi


    return 0

}


# Parametros de entrada:
#  1> Opción de menu a ejecutar
#
function _setup() {

    #01. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi
    
    #02. Actualizar los paquetes de los repositorios
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi
    
    g_status_crendential_storage=-1
    local l_option=1
    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

            #Solicitar credenciales de administrador y almacenarlas temporalmente
            if [ $g_status_crendential_storage -eq 0 ]; then
                storage_sudo_credencial
                g_status_crendential_storage=$?
                #Se requiere almacenar las credenciales para realizar cambio con sudo. 
                #  Si es 0 o 1: la instalación/configuración es completar
                #  Si es 2    : el usuario no acepto la instalación/configuración
                #  Si es 3 0 4: la instalacion/configuración es parcial (solo se instala/configura, lo que no requiere sudo)
                if [ $g_status_crendential_storage -eq 2 ]; then
                    return 120
                fi
            fi
            
            #Actualizar los paquetes de los repositorios
            printf '\n'
            #print_line '─' $g_max_length_line  "$g_color_blue1"
            print_line '-' $g_max_length_line  "$g_color_gray1"
            printf "SO > Actualizar los paquetes del SO '%b%s %s%b'\n" "$g_color_cian1" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
            print_line '-' $g_max_length_line "$g_color_gray1"
            #print_line '─' $g_max_length_line "$g_color_blue1"

            upgrade_os_packages $g_os_subtype_id $l_is_noninteractive 

        fi
    fi
    

    #02. La configuracion requerido para tener VIM/NeoVIM como Editor/IDE (incluyendo la instalación de Python, NodeJS y VIM/NeoVIM)
    _setup_vim_environment $p_opciones
    l_status=$?
    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #No se acepto almacenar las credenciales para usar sudo.
    elif [ $l_status -eq 120 ]; then
        return 120
    fi
    
    #03. Configuracion el SO: Crear enlaces simbolicos y folderes basicos
    _setup_user_profile $p_opciones
    l_status=$?
    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #No se acepto almacenar las credenciales para usar sudo.
    elif [ $l_status -eq 120 ]; then
        return 120
    fi
    
    #04. Eliminar el gestor 'VIM-Plug' y Packer
    _remove_vim_plugin_manager $p_opciones
    l_status=$?
    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #No se acepto almacenar las credenciales para usar sudo.
    elif [ $l_status -eq 120 ]; then
        return 120
    fi
    
    #05. Configurar para tener el soporte a 'X11 forwarding for SSH Server'
    _sutup_support_x11_clipboard $p_opciones
    l_status=$?
    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #No se acepto almacenar las credenciales para usar sudo.
    elif [ $l_status -eq 120 ]; then
        return 120
    fi

    #06. Configurar para tener el soporte a 'X11 forwarding for SSH Server'
    _uninstall_support_x11_clipboard $p_opciones
    l_status=$?
    #No se cumplen las precondiciones obligatorios
    if [ $l_status -eq 111 ]; then
        return 111
    #No se acepto almacenar las credenciales para usar sudo.
    elif [ $l_status -eq 120 ]; then
        return 120
    fi

    #07. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
    #   Si no se invoca usando el menú y se almaceno las credencial en este script, será el script caller el que sea el encargado de caducarlo
    if [ $g_status_crendential_storage -eq 0 ] && [ $gp_type_calling -eq 0 ]; then
    #if [ $g_status_crendential_storage -eq 0 ] && [ $g_is_credential_storage_externally -ne 0 ]; then
        clean_sudo_credencial
    fi

}


function _show_menu_core() {


    print_text_in_center "Menu de Opciones" $g_max_length_line "$g_color_green1"
    print_line '-' $g_max_length_line  "$g_color_gray1"
    printf " (%bq%b) Salir del menu\n" "$g_color_green1" "$g_color_reset"
    printf " (%ba%b) Instalación y configuración de %bVIM%b/%bNeoVIM%b como %beditor%b basico\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" \
           "$g_color_reset" "$g_color_cian1" "$g_color_reset" 
    printf " (%bb%b) Instalación y configuración de %bVIM%b/%bNeoVIM%b como %bIDE%b\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" 
    printf " (%bc%b) Instalación y configuración de %bVIM%b        como %beditor%b basico\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " (%bd%b) Instalación y configuración de %bVIM%b        como %bIDE%b\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " (%be%b) Instalación y configuración de %bNeoVIM%b     como %beditor%b basico\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " (%bf%b) Instalación y configuración de %bNeoVIM%b     como %bIDE%b\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " (%bg%b) Configurar todo el profile como %bbasico%b    %b(%bVIM%b/%bNeoVIM%b como editor basico)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf " (%bh%b) Configurar todo el profile como %bdeveloper%b %b(%bVIM%b/%bNeoVIM%b como IDE)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf " (%bi%b) Configurar todo el profile como %bbasico%b    %b(%bVIM%b/%bNeovIM%b como editor basico)%b y re-crear enlaces simbolicos\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf " (%bj%b) Configurar todo el profile como %bdeveloper%b %b(%bVIM%b/%bNeoVIM%b como IDE)%b y re-crear enlaces simbolicos\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf " (%bk%b) Configurar todo el profile como %bbasico%b    %b(Solo %bVIM%b como editor basico)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf " (%bl%b) Configurar todo el profile como %bdeveloper%b %b(Solo %bVIM%b como IDE)%b\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf " (%bm%b) Configurar todo el profile como %bbasico%b    %b(Solo %bVIM%b como editor basico)%b y re-crear enlaces simbolicos\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf " (%bn%b) Configurar todo el profile como %bdeveloper%b %b(Solo %bVIM%b como IDE)%b y re-crear enlaces simbolicos\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_cian1" "$g_color_gray1" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    local l_max_digits=12

    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
        printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes del SO\n" "$g_color_green1" "1" "$g_color_reset"
    fi
    printf "     (%b%0${l_max_digits}d%b) Crear los enlaces simbolicos del profile del usuario\n" "$g_color_green1" "2" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Flag para %bre-crear%b un enlaces simbolicos en caso de existir\n" "$g_color_green1" "4" "$g_color_reset" "$g_color_cian1" "$g_color_reset"

    printf "     (%b%0${l_max_digits}d%b) Instalar %bPython%b y el gestor de paquetes %bPip%b\n" "$g_color_green1" "8" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bNodeJS%b\n" "$g_color_green1" "16" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes%b de usuario de %bPython%b: %b'jtbl', 'compiledb', 'rope' y 'pynvim'%b\n" "$g_color_green1" "32" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes%b globales de %bNodeJS%b: %b'Prettier', 'NeoVIM' y 'TreeSitter CLI'%b\n" "$g_color_green1" "64" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Instalar el programa '%bvim%b'\n" "$g_color_green1" "128" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Configurar como %bEditor%b %b(archivos de configuración, plugins y su documentación)%b\n" "$g_color_green1" "256" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Configurar como %bIDE%b    %b(archivos de configuración, plugins y su documentación)%b\n" "$g_color_green1" "512" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"


    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Instalar el programa '%bnvim%b'\n" "$g_color_green1" "1024" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Configurar como %bEditor%b %b(archivos de configuración, plugins y su documentación)%b\n" "$g_color_green1" "2048" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Configurar como %bIDE%b    %b(archivos de configuración, plugins y su documentación)%b\n" "$g_color_green1" "4096" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

    printf "     (%b%0${l_max_digits}d%b) %bCliente  SSH%b> %bX11 forwading%b> server with %bX Server%b> Instalar 'xclip'\n" \
           "$g_color_green1" "8192" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bCliente  SSH%b> %bX11 forwading%b> %bHeadless Server%b> Instalar el servidor X virtual '%bXvfb%b' e instalar 'xclip'\n" \
           "$g_color_green1" "16384" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bServidor SSH%b> %bX11 forwading%b> Configurar OpenSSH server e instalar 'xclip', 'xorg-x11-xauth'\n" "$g_color_green1" \
           "32768" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bServidor SSH%b> Eliminar el %bX11 forwading%b del OpenSSH server\n" "$g_color_green1" "65536" "$g_color_reset" \
           "$g_color_gray1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

    #Adicionales
    printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes%b de usuario de %bPython%b: %b'jtbl'%b\n" "$g_color_green1" "131072" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes%b globales de %bNodeJS%b: %b'Prettier'%b\n" "$g_color_green1" "262144" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Crear los %barchivos de configuración%b como %bEditor%b\n" "$g_color_green1" "524288" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Crear los %barchivos de configuración%b como %bIDE%b\n" "$g_color_green1" "1048576" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Descargar los %bplugins%b de %bEditor%b e %bindexar%b su documentación\n" "$g_color_green1" "2097152" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Descargar los %bplugins%b de %bEditor%b %b(sin indexar la documentación)%b \n" "$g_color_green1" "4194304" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Descargar los %bplugins%b de %bIDE%b e %bindexar%b su documentación\n" "$g_color_green1" "8388608" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Descargar los %bplugins%b de %bIDE%b %b(sin indexar la documentación)%b \n" "$g_color_green1" "16777216" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > %bIndexar%b la documentación de los plugins existentes\n" "$g_color_green1" "33554432" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Configurar los %bplugins de IDE%b\n" "$g_color_green1" "67108864" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Crearlos %barchivos de configuración%b como %bEditor%b\n" "$g_color_green1" "134217728" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Crear los %barchivos de configuración%b como %bIDE%b\n" "$g_color_green1" "268435456" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Descargar los %bplugins%b de %bEditor%b e %bindexar%b su documentación\n" "$g_color_green1" "536870912" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Descargar los %bplugins%b de %bEditor%b %b(sin indexar la documentación)%b \n" "$g_color_green1" "1073741824" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Descargar los %bplugins%b de %bIDE%b e %bindexar%b su documentación\n" "$g_color_green1" "2147483648" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Descargar los %bplugins%b de %bIDE%b %b(sin indexar la documentación)%b \n" "$g_color_green1" "4294967296" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > %bIndexar%b la documentación de los plugins existentes\n" "$g_color_green1" "8589934592" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Configurar los %bplugins de IDE%b\n" "$g_color_green1" "17179869184" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"


    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Eliminar el gestor de plugins 'VIM-Plug'\n" "$g_color_green1" "34359738368" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Eliminar el gestor de plugins 'VIM-Plug'\n" "$g_color_green1" "68719476736" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Eliminar el gestor de plugins 'Packer'\n" "$g_color_green1" "137438953472" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

    print_line '-' $g_max_length_line "$g_color_gray1"

}

function g_main() {

    #1. Pre-requisitos
    
    #2. Mostrar el Menu
    print_line '─' $g_max_length_line "$g_color_green1" 
    _show_menu_core
    
    local l_flag_continue=0
    local l_options=""
    while [ $l_flag_continue -eq 0 ]; do

        printf "Ingrese la opción %b(no ingrese los ceros a la izquierda)%b: " "$g_color_gray1" "$g_color_reset"
        read -r l_options

        case "$l_options" in

            #Instalación y configuración de VIM/NeoVIM como editor
            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000128) VIM    > Instalar el programa 'vim'
                #(000000000256) VIM    > Configurar como Editor (configura '.vimrc', folderes y plugins)
                #(000000001024) NeoVIM > Instalar el programa 'nvim'
                #(000000002048) NeoVIM > Configurar como Editor (configura '.vimrc', folderes y plugins)
                _setup 3456
                ;;


            #Instalación y configuración de VIM/NeoVIM como IDE
            b)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000008) Instalar Python y el gestor de paquetes Pip
                #(000000000016) Instalar NodeJS
                #(000000000032) Instalar paquetes de usuario de Python: 'jtbl', 'compiledb', 'rope' y 'pynvim'
                #(000000000064) Instalar paquetes globales de NodeJS: 'Prettier', 'NeoVIM' y 'TreeSitter CLI'
                #(000000000128) VIM    > Instalar el programa 'vim'
                #(000000000512) VIM    > Configurar como IDE    (configura '.vimrc', folderes y plugins)
                #(000000001024) NeoVIM > Instalar el programa 'nvim'
                #(000000004096) NeoVIM > Configurar como IDE    (configura '.vimrc', folderes y plugins)
                _setup 5880
                ;;

            #Instalación y configuración de VIM como editor basico
            c)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000128) VIM    > Instalar el programa 'vim'
                #(000000000256) VIM    > Configurar como Editor (configura '.vimrc', folderes y plugins)
                _setup 384
                ;;

            #Instalación y configuración de VIM como IDE
            d)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000008) Instalar Python y el gestor de paquetes Pip
                #(000000000016) Instalar NodeJS
                #(000000000032) Instalar paquetes de usuario de Python: 'jtbl', 'compiledb', 'rope' y 'pynvim'
                #(000000000064) Instalar paquetes globales de NodeJS: 'Prettier', 'NeoVIM' y 'TreeSitter CLI'
                #(000000000128) VIM    > Instalar el programa 'vim'
                #(000000000512) VIM    > Configurar como IDE    (configura '.vimrc', folderes y plugins)
                _setup 760
                ;;


            #Instalación y configuración de NeoVIM como editor
            e)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000001024) NeoVIM > Instalar el programa 'nvim'
                #(000000002048) NeoVIM > Configurar como Editor (configura '.vimrc', folderes y plugins)
                _setup 3072
                ;;

            #Instalación y configuración de NeoVIM como IDE
            f)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000008) Instalar Python y el gestor de paquetes Pip
                #(000000000016) Instalar NodeJS
                #(000000000032) Instalar paquetes de usuario de Python: 'jtbl', 'compiledb', 'rope' y 'pynvim'
                #(000000000064) Instalar paquetes globales de NodeJS: 'Prettier', 'NeoVIM' y 'TreeSitter CLI'
                #(000000001024) NeoVIM > Instalar el programa 'nvim'
                #(000000004096) NeoVIM > Configurar como IDE    (configura '.vimrc', folderes y plugins)
                _setup 5240
                ;;

            #Configurar todo el profile como basico (VIM/NeoVIM como editor basico)
            g)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000002) Crear los enlaces simbolicos del profile
                #Opcion (a)
                _setup 3458
                ;;

            #Configurar todo el profile como developer (VIM/NeoVIM como IDE)
            h)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000002) Crear los enlaces simbolicos del profile
                #Opcion (b)
                _setup 5882
                ;;

            #Configurar todo el profile como basico (VIM/NeovIM como editor basico) y re-crear enlaces simbolicos
            i)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000004) Flag para re-crear un enlaces simbolicos en caso de existir
                #Opcion (g)
                _setup 3462
                ;;

            #Configurar todo el profile como developer (VIM/NeoVIM como IDE) y re-crear enlaces simbolicos
            j)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000004) Flag para re-crear un enlaces simbolicos en caso de existir
                #Opcion (h)
                _setup 5886
                ;;

            #Configurar todo el profile como basico (Solo VIM como editor basico)
            k)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000002) Crear los enlaces simbolicos del profile
                #Opcion (c)
                _setup 386
                ;;
            
            #Configurar todo el profile como developer (Solo VIM como IDE)
            l)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000002) Crear los enlaces simbolicos del profile
                #Opcion (d)
                _setup 762
                ;;
            
            #Configurar todo el profile como basico (Solo VIM como editor basico) y re-crear enlaces simbolicos
            m)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000004) Flag para re-crear un enlaces simbolicos en caso de existir
                #Opcion (k)
                _setup 390
                ;;

            #Configurar todo el profile como developer (Solo VIM como IDE) y re-crear enlaces simbolicos
            n)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                #(000000000004) Flag para re-crear un enlaces simbolicos en caso de existir
                #Opcion (l)
                _setup 766
                ;;

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_green1" 
                    _setup $l_options
                else
                    l_flag_continue=0
                    printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                    print_line '-' $g_max_length_line "$g_color_gray1" 
                fi
                ;;

            *)
                l_flag_continue=0
                printf '%bOpción incorrecta%b\n' "$g_color_gray1" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_gray1" 
                ;;
        esac
        
    done

}

g_usage() {

    printf 'Usage:\n'
    printf '  > %bConfigurando el profile del usuario/VIM/NeoVIM escogidos del menú de opciones (interactivo)%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/02_setup_profile.bash\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/02_setup_profile.bash 0 PRG_PATH CMD_BASE_PATH TEMP_PATH\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '  > %bConfigurando el profile del usuario/VIM/NeoVIM segun un grupo de opciones de menú indicados%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/02_setup_profile.bash CALLING_TYPE MENU-OPTIONS PRG_PATH CMD_BASE_PATH TEMP_PATH\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/02_setup_profile.bash CALLING_TYPE MENU-OPTIONS PRG_PATH CMD_BASE_PATH TEMP_PATH SUDO-STORAGE-OPTIONS OTHER-USERID\n\n%b' "$g_color_yellow1" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bPRG_PATH %bes la ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado "/opt/tools" o "~/tools".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bTEMP_PATH %bes la ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado "/tmp".%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bCALLING_TYPE%b Es 0 si se muestra un menu, caso contrario es 1 si es interactivo y 2 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bSUDO-STORAGE-OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi es root por lo que no se requiere almacenar la credenciales, use 2. Caso contrario, use 0 si se almaceno la credencial y 1 si no se pudo almacenar las credenciales.%b\n' \
           "$g_color_gray1" "$g_color_reset"
    printf '  > %bOTHER-USERID %bEl UID/GID del usuario al que es owner del script (el repositorio git) en formato "UID:GID". Solo si se ejecuta como root y este es diferente al onwer del script.%b\n\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"

}


#1. Logica principal del script (incluyendo los argumentos variables)

#Argumento 1: el modo de ejecución del script
if [ -z "$1" ]; then
    gp_type_calling=0
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    gp_type_calling=$1
else
    printf 'Argumentos invalidos.\n\n'
    g_usage
    exit 110
fi


_g_result=0
_g_status=0

#Aun no se ha solicitado almacenar temporalmente las credenciales para el sudo
g_status_crendential_storage=-1
#La credencial no se almaceno por un script externo.
g_is_credential_storage_externally=1

#1.1. Mostrar el menu para escoger lo que se va instalar
if [ $gp_type_calling -eq 0 ]; then

    #Parametros usados por el script:
    # 1> Tipo de configuración: 0 (instalación con un menu interactivo).
    # 2> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado "/opt/tools" o "~/tools".
    # 3> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.

    #Obtener los folderes de programas 'g_path_programs'
    _g_path=''
    if [ ! -z "$2" ] && [ "$2" != "EMPTY" ]; then
        _g_path="$2"
    fi

    _g_is_noninteractive=1
    set_program_path "$g_path_base" $_g_is_noninteractive "$_g_path" "$g_other_calling_user"

    #Obtener los folderes temporal 'g_path_temp'
    _g_path=''
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        _g_path="$3"
    fi

    set_temp_path "$_g_path"



    #Validar los requisitos (0 debido a que siempre se ejecuta de modo interactivo)
    #  1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info') 
    #  2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  3 > Flag '0' si se requere curl
    #  4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    #  5 > Path donde se encuentra el directorio donde esta el '.git'
    fulfill_preconditions $g_os_subtype_id 0 1 1 "$g_path_base"
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_main
    else
        _g_result=111
    fi

#1.2. No mostrar el menu, la opcion del menu a ejecutar se envia como parametro
else

    #Parametros usados por el script:
    # 1> Tipo de configuración: 1/2 (instalación sin un menu interactivo/no-interactivo).
    # 2> Opciones de menu a ejecutar: entero positivo.
    # 3> Ruta donde se descargaran los programas (de repositorios como github). Si se envia vacio o EMPTY se usara el directorio predeterminado "/opt/tools" o "~/tools".
    # 4> Ruta de archivos temporales. Si se envia vacio o EMPTY se usara el directorio predeterminado.
    # 5> El estado de la credencial almacenada para el sudo.
    # 6> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID".
    gp_menu_options=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        gp_menu_options=$2
    else
        echo "Parametro 2 \"$2\" debe ser una opción valida."
        exit 110
    fi

    if [ $gp_menu_options -le 0 ]; then
        echo "Parametro 2 \"$2\" debe ser un entero positivo."
        exit 110
    fi

    if [[ "$5" =~ ^[0-2]$ ]]; then
        g_status_crendential_storage=$5

        if [ $g_status_crendential_storage -eq 0 ]; then
            g_is_credential_storage_externally=0
        fi

    fi

    #Si se ejecuta un usuario root y es diferente al usuario que pertenece este script de instalación (es decir donde esta el repositorio)
    g_other_calling_user=''
    if [ $g_user_sudo_support -eq 4 ] && [ ! -z "$6" ] && [ "$6" != "EMPTY" ] && [ "$g_path_base" != "$HOME" ]; then
        if [[ "$6" =~ ^[0-9]+:[0-9]+$ ]]; then
            g_other_calling_user="$6"
        else
            echo "Parametro 6 \"$6\" debe ser tener el formado 'UID:GID'."
            exit 110
        fi
    fi

    #Obtener los folderes de programas 'g_path_programs'
    _g_path=''
    if [ ! -z "$3" ] && [ "$3" != "EMPTY" ]; then
        _g_path="$3"
    fi

    _g_is_noninteractive=0
    if [ $gp_type_calling -eq 1 ]; then
        _g_is_noninteractive=1
    fi
    set_program_path "$g_path_base" $_g_is_noninteractive "$_g_path" "$g_other_calling_user"

    #Obtener los folderes temporal 'g_path_temp'
    _g_path=''
    if [ ! -z "$4" ] && [ "$4" != "EMPTY" ]; then
        _g_path="$4"
    fi

    set_temp_path "$_g_path"


    #Validar los requisitos
    #  1 > El tipo de distribucion Linux (variable 'g_os_subtype_id' generado por 'get_linux_type_info') 
    #  2 > Flag '0' si de desea mostrar información adicional (solo mostrar cuando se muestra el menu)
    #  3 > Flag '0' si se requere curl
    #  4 > Flag '0' si requerir permisos de root para la instalación/configuración (sudo o ser root)
    #  5 > Path donde se encuentra el directorio donde esta el '.git'
    fulfill_preconditions $g_os_subtype_id 1 1 1 "$g_path_base" "$g_other_calling_user"
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then

        _setup $gp_menu_options
        _g_status=$?

        #No se cumplen las precondiciones obligatorios
        if [ $l_status -eq 111 ]; then
            _g_result=111
        #Informar si se nego almacenar las credencial cuando es requirido
        elif [ $_g_status -eq 120 ]; then
            _g_result=120
        #Si la credencial se almaceno en este script (localmente). avisar para que lo cierre el caller
        elif [ $g_is_credential_storage_externally -ne 0 ] && [ $g_status_crendential_storage -eq 0 ]; then
            _g_result=119
        fi
    else
        _g_result=111
    fi

fi


exit $_g_result



