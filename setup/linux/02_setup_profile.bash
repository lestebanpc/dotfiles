#!/bin/bash

#Parametros de entrada:
#  1> La ruta relativa (o absoluta) de un archivos del repositorio
#Parametros de salida: 
#  STDOUT> La ruta base donde esta el repositorio
function _get_current_repo_path() {

    #Obteniendo la ruta absoluta del parametro ingresado
    local l_path=''
    l_path=$(realpath "$1" 2> /dev/null)
    local l_status=$?
    if [ $l_status -ne 0 ]; then
        echo "$HOME"
        return 1
    fi

    #Obteniendo la ruta base
    l_path=${l_path%/.files/*}
    echo "$l_path"
    return 0
}

#Inicialización Global {{{

declare -r g_repo_path=$(_get_current_repo_path "${BASH_SOURCE[0]}")

#Si lo ejecuta un usuario diferente al actual (al que pertenece el repositorio)
#UID del Usuario y GID del grupo (diferente al actual) que ejecuta el script actual
g_other_calling_user=''

#Funciones generales: determinar el tipo del SO, ...
. ${g_repo_path}/.files/terminal/linux/functions/func_utility.bash

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
    get_user_options

    #Si el usuario no tiene permisos a sudo o el SO no implementa sudo,
    # - Se instala/Configura los binarios a nivel usuario, las fuentes a nivel usuario.
    # - No se instala ningun paquete/programa que requiere permiso 'root' para su instalación
    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

        #Ruta donde se instalaran los programas CLI (tiene una estructura de folderes y generalmente incluye mas de 1 binario).
        g_path_programs='/opt/tools'

        #Rutas de binarios, archivos de help (man) y las fuentes
        #g_path_bin='/usr/local/bin'
        #g_path_man='/usr/local/man/man1'
        #g_path_fonts='/usr/share/fonts'

    else

        #Ruta donde se instalaran los programas CLI (tiene una estructura de folderes y generalmente incluye mas de 1 binario).
        g_path_programs=~/tools

        #Rutas de binarios, archivos de help (man) y las fuentes
        #g_path_bin=~/.local/bin
        #g_path_man=~/.local/man/man1
        #g_path_fonts=~/.local/share/fonts

    fi

fi

#Flag '0' indica que vim esta instalando (los plugins de vim se puede instalar sin tener el vim instalando)
g_is_vim_installed=0
g_is_nvim_installed=0
g_is_nodejs_installed=0
g_is_python_installed=0

#Funciones de utilidad
. ${g_repo_path}/.files/setup/linux/_common_utility.bash


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
#  1> Flag configurar como Developer (si es '0')
function _setup_vim_packages() {

    #1. Argumentos
    local p_is_neovim=1
    if [ "$1" = "0" ]; then
        p_is_neovim=0
    fi

    local p_flag_developer=1
    if [ "$2" = "0" ]; then
        p_flag_developer=0
    fi

    #2. Ruta base donde se instala el plugins/paquete
    local l_tag="VIM"
    local l_current_scope=1
    local l_base_plugins="${HOME}/.vim/pack"
    if [ $p_is_neovim -eq 0  ]; then
        l_base_plugins="${HOME}/.local/share/nvim/site/pack"
        l_current_scope=2
        l_tag="NeoVIM"
    fi


    #2. Crear las carpetas de basicas
    printf 'Instalando los paquetes usados por %s en %b%s%b...\n' "$l_tag" "$g_color_gray1" "$l_base_plugins" "$g_color_reset"

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
    local l_base_path
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
        l_base_path=""
        case "$l_repo_type" in 
            1)
                l_base_path=${l_base_plugins}/themes/opt
                ;;
            2)
                l_base_path=${l_base_plugins}/ui/opt
                ;;
            3)
                l_base_path=${l_base_plugins}/typing/opt
                ;;
            4)
                l_base_path=${l_base_plugins}/ide/opt
                ;;
            *)
                
                #print_line '- ' $((g_max_length_line/2)) "$g_color_gray1" 
                printf 'Paquete %s (%s) "%s": No tiene tipo valido\n' "$l_tag" "${l_repo_type}" "${l_repo_git}"
                continue
                ;;
        esac

        #Si es un repositorio para developer no debe instalarse en el perfil basico
        if [ $p_flag_developer -eq 1 ] && [ $l_repo_type -eq 3 -o $l_repo_type -eq 4 ]; then
            continue
        fi

        #echo "${l_base_path}/${l_repo_name}/.git"

        #4.3 Validar si el paquete ya esta instalando
        if [ -d ${l_base_path}/${l_repo_name}/.git ]; then
             #print_line '- ' $((g_max_length_line/2)) "$g_color_gray1" 
             printf 'Paquete %s (%s) "%b%s%b": Ya esta instalando\n' "$l_tag" "${l_repo_type}" "$g_color_gray1" "${l_repo_git}" "$g_color_reset"
             continue
        fi

        #4.5 Instalando el paquete
        cd ${l_base_path}
        printf '\n'
        print_line '- ' $((g_max_length_line/2)) "$g_color_gray1" 
        if [ $p_is_neovim -eq 0  ]; then
            printf 'NeoVIM> Plugin (%b%s%b) "%b%s%b": Se esta instalando\n' "$g_color_cian1" "${l_repo_type}" "$g_color_reset" "$g_color_cian1" "${l_repo_git}" "$g_color_reset"
        else
            printf 'VIM   > Plugin (%b%s%b) "%b%s%b": Se esta instalando\n' "$g_color_cian1" "${l_repo_type}" "$g_color_reset" "$g_color_cian1" "${l_repo_git}" "$g_color_reset"
        fi
        print_line '- ' $((g_max_length_line/2)) "$g_color_gray1" 

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
        if [ -d "${l_base_path}/${l_repo_name}/doc" ]; then

            #Indexar la documentación de plugins
            la_doc_paths+=("${l_base_path}/${l_repo_name}/doc")
            la_doc_repos+=("${l_repo_name}")

        fi

        printf '\n'

    done;

    #5. Actualizar la documentación de VIM (Los plugins VIM que no tiene documentación, no requieren indexar)
    local l_doc_path
    local l_n=${#la_doc_paths[@]}
    local l_i
    if [ $l_n -gt 0 ]; then

        printf '\n'
        print_line '- ' $((g_max_length_line/2)) "$g_color_gray1" 
        if [ $p_is_neovim -eq 0  ]; then
            printf 'NeoVIM> %bIndexando las documentación%b de los plugins en %s\n' "$g_color_cian1" "$g_color_reset"
        else
            printf 'VIM   > %bIndexando las documentación%b de los plugins en %s\n' "$g_color_cian1" "$g_color_reset"
        fi
        print_line '- ' $((g_max_length_line/2)) "$g_color_gray1" 

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

    #6. Inicializar los paquetes/plugin de VIM/NeoVIM que lo requieren.
    if [ $p_flag_developer -ne 0 ]; then
        printf 'Se ha instalando los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_cian1" "$l_tag" "$g_color_reset" "$g_color_cian1" "Editor" "$g_color_reset"
        return 0
    fi

    printf 'Se ha instalando los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_cian1" "$l_tag" "$g_color_reset" "$g_color_cian1" "Developer" "$g_color_reset"
    if [ $g_is_nodejs_installed -ne 0  ]; then

        printf 'Recomendaciones:\n'
        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 vim%b"\n' "$g_color_cian1" "$g_color_reset"
        if [ $p_is_neovim -eq 0  ]; then
            printf '    > NeoVIM como developer por defecto usa el adaptador LSP y autocompletado nativo. %bNo esta habilitado el uso de CoC%b\n' "$g_color_gray1" "$g_color_reset" 
        else
            printf '    > VIM esta como developer pero NO puede usar CoC  %b(requiere que NodeJS este instalando)%b\n' "$g_color_gray1" "$g_color_reset" 
        fi
        return 0

    fi
        
    printf 'Los plugins del IDE CoC de %s tiene componentes que requieren inicialización para su uso. Inicilizando dichas componentes del plugins...\n' "$l_tag"

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
function _config_nvim() {

    #1. Argumentos
    local p_flag_developer=1
    if [ "$1" = "0" ]; then
        p_flag_developer=0
    fi

    local p_flag_overwrite_ln=1
    if [ "$2" = "0" ]; then
        p_flag_overwrite_ln=0
    fi

    #Sobrescribir los enlaces simbolicos
    printf '\n'
    print_line '-' $g_max_length_line "$g_color_gray1" 
    printf "Configuración de NeoVIM\n"
    print_line '-' $g_max_length_line "$g_color_gray1" 

    mkdir -p ~/.config/nvim/
    
    #2. Creando los enalces simbolicos
    local l_target_link
    local l_source_path
    local l_source_filename

    #Configurar NeoVIM como IDE (Developer)
    if [ $p_flag_developer -eq 0 ]; then


        l_target_link="${HOME}/.config/nvim/coc-settings.json"
        l_source_path="${HOME}/.files/nvim/ide_coc"
        if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
            l_source_filename='coc-settings_lnx_non_shared.json'
        else
            l_source_filename='coc-settings_lnx_shared.json'
        fi
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM (IDE)> " $p_flag_overwrite_ln


        l_target_link="${HOME}/.config/nvim/init.vim"
        l_source_path="${HOME}/.files/nvim"
        if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
            l_source_filename='init_ide_linux_non_shared.vim'
        else
            l_source_filename='init_ide_linux_shared.vim'
        fi
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM (IDE)> " $p_flag_overwrite_ln

        l_target_link="${HOME}/.config/nvim/lua"
        l_source_path="${HOME}/.files/nvim/lua"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $p_flag_overwrite_ln

        
        #El codigo open/close asociado a los 'file types'
        l_target_link="${HOME}/.config/nvim/ftplugin"
        l_source_path="${HOME}/.files/nvim/ide_commom/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $p_flag_overwrite_ln


        #Para el codigo open/close asociado a los 'file types' de CoC
        l_target_link="${HOME}/.config/nvim/runtime_coc/ftplugin"
        l_source_path="${HOME}/.files/nvim/ide_coc/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $p_flag_overwrite_ln


        #Para el codigo open/close asociado a los 'file types' que no sean CoC
        l_target_link="${HOME}/.config/nvim/runtime_nococ/ftplugin"
        l_source_path="${HOME}/.files/nvim/ide_nococ/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $p_flag_overwrite_ln

    #Configurar NeoVIM como Editor
    else

        l_target_link="${HOME}/.config/nvim/init.vim"
        l_source_path="${HOME}/.files/nvim"
        l_source_filename='init_basic_linux.vim'
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM (Editor)> " $p_flag_overwrite_ln

        
        l_target_link="${HOME}/.config/nvim/lua"
        l_source_path="${HOME}/.files/nvim/lua"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (Editor)> " $p_flag_overwrite_ln


        #El codigo open/close asociado a los 'file types' como Editor
        l_target_link="${HOME}/.config/nvim/ftplugin"
        l_source_path="${HOME}/.files/nvim/editor/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (Editor)> " $p_flag_overwrite_ln


    fi

    #6. Instalando paquetes
    _setup_vim_packages 0 $p_flag_developer


}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
function _config_vim() {

    #1. Argumentos
    local p_flag_developer=1
    if [ "$1" = "0" ]; then
        p_flag_developer=0
    fi

    local p_flag_overwrite_ln=1
    if [ "$2" = "0" ]; then
        p_flag_overwrite_ln=0
    fi

    #2. Crear el subtitulo
    #printf '\n'
    print_line '-' $g_max_length_line "$g_color_gray1" 
    printf "Configuración de VIM-Enhanced\n"
    print_line '-' $g_max_length_line "$g_color_gray1" 

    mkdir -p ~/.vim/

    #3. Crear los enlaces simbolicos de VIM
    local l_target_link
    local l_source_path
    local l_source_filename


    #Configurar VIM como IDE (Developer)
    if [ $p_flag_developer -eq 0 ]; then

        #Creando enlaces simbolicos
        l_target_link="${HOME}/.vim/coc-settings.json"
        l_source_path="${HOME}/.files/vim/ide_coc"
        if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
            l_source_filename='coc-settings_lnx_non_shared.json'
        else
            l_source_filename='coc-settings_lnx_shared.json'
        fi
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM (IDE)> " $p_flag_overwrite_ln

        
        l_target_link="${HOME}/.vim/ftplugin"
        l_source_path="${HOME}/.files/vim/ide_coc/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "VIM (IDE)> " $p_flag_overwrite_ln


        l_target_link="${HOME}/.vimrc"
        l_source_path="${HOME}/.files/vim"
        if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
            l_source_filename='vimrc_ide_linux_non_shared.vim'
        else
            l_source_filename='vimrc_ide_linux_shared.vim'
        fi

        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM (IDE)> " $p_flag_overwrite_ln


    #Configurar VIM como Editor basico
    else

        l_target_link="${HOME}/.vimrc"
        l_source_path="${HOME}/.files/vim"
        l_source_filename='vimrc_basic_linux.vim'
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM (Editor)> " $p_flag_overwrite_ln


        l_target_link="${HOME}/.vim/ftplugin"
        l_source_path="${HOME}/.files/vim/editor/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "VIM (Editor)> " $p_flag_overwrite_ln


    fi

    #Instalar los plugins
    _setup_vim_packages 1 $p_flag_developer

}


# Parametros:
#  1> Opcion ingresada por el usuario.
#  2> Flag para mostrar el titulo
function _config_vim_profile() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #2. Determinar si se configurar VIM: (-1) No se configura, (0) Como IDE, (1) Como Editor
    local l_config_vim=-1
    local l_option=512
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        #Es IDE?
        l_config_vim=0
    fi

    if [ $l_config_vim -lt 0 ]; then
        l_option=256
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            #Es Editor?
            l_config_vim=1
        fi
    fi
    
    #3. Determinar si se configurar NeoVIM: (-1) No se configura, (0) Como IDE, (1) Como Editor
    local l_config_nvim=-1
    local l_option=4096
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        #Es IDE?
        l_config_nvim=0
    fi

    if [ $l_config_nvim -lt 0 ]; then
        l_option=2048
        if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
            #Es Editor?
            l_config_nvim=1
        fi
    fi

    #Si no se solicitar instalar VIM o NeoVIM no instalar ningun comando
    if [ $l_config_vim -lt 0 ] && [ $l_config_nvim -lt 0 ]; then
        return 99
    fi
   
    #4. Mostrar el titulo de instalacion
    local l_aux=""

    if [ $l_config_vim -eq 0 ]; then
        printf -v l_aux "%sVIM%s como %sIDE%s" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    elif [ $l_config_vim -eq 1 ]; then
        printf -v l_aux "%sVIM%s como %sEditor%s" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    fi

    if [ $l_config_nvim -ge 0 ]; then

        if [ ! -z "$l_aux" ]; then
            l_aux="${l_aux} y "
        fi

        if [ $l_config_nvim -eq 0 ]; then
            printf -v l_aux "%s%sNeoVIM%s como %sIDE%s" "$l_aux" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        else
            printf -v l_aux "%s%sNeoVIM%s como %sEditor%s" "$l_aux" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        fi
    fi

    if [ $gp_type_calling -eq 0 ]; then
        print_line '─' $g_max_length_line  "$g_color_blue1"
        printf "> Configurando %b\n" "$l_aux"
        print_line '─' $g_max_length_line "$g_color_blue1"
    else
        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf "%bGrupo>%b Configurando %b\n" "$g_color_gray1" "$g_color_reset" "$l_aux" 
        print_line '-' $g_max_length_line "$g_color_gray1"
    fi

    #Sobrescribir los enlaces simbolicos
    l_option=4
    local l_flag_overwrite_ln=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_overwrite_ln=0
    fi

    #¿El programa NodeJS esta en el PATH?: se requiere el comando 'node'
    local l_status
    if ! node --version 1> /dev/null 2>&1; then
        echo "$PATH" | grep "${g_path_programs}/nodejs/bin" &> /dev/null
        l_status=$?
        if [ $l_status -ne 0 ]; then
            export PATH=${g_path_programs}/nodejs/bin:$PATH
        fi
    fi

    #5. Configurar VIM 
    if [ $l_config_vim -ge 0 ]; then
        _config_vim $l_config_vim $l_flag_overwrite_ln
    fi

    #6. Configurar NeoVIM
    if [ $l_config_nvim -ge 0 ]; then
        
        #¿El programa NeoVIM esta en el path?: se requiere usar el comando 'nvim'
        if ! nvim --version 1> /dev/null 2>&1; then
            echo "$PATH" | grep "${g_path_programs}/neovim/bin" &> /dev/null
            l_status=$?
            if [ $l_status -ne 0 ]; then
                export PATH=${g_path_programs}/neovim/bin:$PATH
            fi
        fi

        _config_nvim $l_config_nvim $l_flag_overwrite_ln
    fi

    return 0


}

#Instalar RTE Node.JS y sus paquetes requeridos para habilitar VIM en modo 'Developer'.
#Si se usa NeoVIM en modo 'Developer', se instalara paquetes adicionales.
_install_nodejs() {

    #0. Argumentos

    #1. Instalación de Node.JS (el gestor de paquetes npm esta incluido)
    g_is_nodejs_installed=1

    #Validar si 'node' esta en el PATH
    echo "$PATH" | grep "${g_path_programs}/nodejs/bin" &> /dev/null
    local l_status=$?
    if [ $l_status -ne 0 ] && [ -f "${g_path_programs}/nodejs/bin/node" ]; then
        printf '%bNode.JS %s esta instalando pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
            "$g_color_red1" "$l_version" "$g_color_reset"
        printf 'Adicionando a la sesion actual: PATH=%s/nodejs/bin:$PATH\n' "${g_path_programs}"
        export PATH=${g_path_programs}/nodejs/bin:$PATH
    fi

    #Obtener la version de Node.JS actual
    local l_version
    l_version=$(node -v 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        l_version=""
    fi

    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi

    #Si no esta instalando
    if [ -z "$l_version" ]; then

        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf "NodeJS > Se va instalar el RTE NodeJS\n"
        print_line '-' $g_max_length_line  "$g_color_gray1"

        #Instalando NodeJS

        #Parametros:
        # 1> Tipo de ejecución: 2/4 (ejecución sin menu para instalar/actualizar un respositorio especifico)
        # 2> Repsositorio a instalar/acutalizar: 
        # 3> El estado de la credencial almacenada para el sudo
        # 4> Install only last version: por defecto es 1 (false). Solo si ingresa 0 es (true).
        # 5> Flag '0' para mostrar un titulo si se envia, como parametro 2, un solo repositorio a configurar. Por defecto es '1' 
        # 6> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
        if [ $l_is_noninteractive -eq 1 ]; then
            ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 2 "nodejs" $g_status_crendential_storage 1 1 "$g_other_calling_user"
            l_status=$?
        else
            ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 4 "nodejs" $g_status_crendential_storage 1 1 "$g_other_calling_user"
            l_status=$?
        fi

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
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

        #Obtener la version instalada
        l_version=$(node -v 2> /dev/null)
        l_status=$?
        if [ $l_status -eq 0 ]; then
            printf 'Se instaló la Node.JS version %s\n' "$l_version"
            g_is_nodejs_installed=0
        else
            printf 'Ocurrio un error en la instalacion de Node.JS "%s"\n' "$l_version"
            g_is_nodejs_installed=1
        fi

    #Si esta instalando
    else
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        printf 'NodeJS > %bNodeJS "%s" ya esta instalando%b\n' "$g_color_gray1" "$l_version" "$g_color_reset"
        g_is_nodejs_installed=0
    fi

    return $g_is_nodejs_installed

}


#Instalar paquetes globales de NodeJS: 'Prettier', 'NeoVIM' y 'TreeSitter CLI'
_install_global_pckg_nodejs() {

    #Validar si 'node' esta en el PATH
    local l_version
    echo "$PATH" | grep "${g_path_programs}/nodejs/bin" &> /dev/null
    local l_status=$?
    if [ $l_status -ne 0 ] && [ -f "${g_path_programs}/nodejs/bin/node" ]; then
        printf '%bNode.JS %s esta instalando pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
            "$g_color_red1" "$l_version" "$g_color_reset"
        printf 'Adicionando a la sesion actual: PATH=%s/nodejs/bin:$PATH\n' "${g_path_programs}"
        export PATH=${g_path_programs}/nodejs/bin:$PATH
    fi

    #Obtener la version de Node.JS actual
    local l_version
    l_version=$(node --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        printf 'NodeJS > %bNodeJS NO esta instalado%b\n' "$g_color_gray1" "$g_color_reset"
        return 1
    else
        printf 'NodeJS > %bNodeJS "%s" esta instalando%b. Instalando los paquetes globales: "Prettier", "NeoVIM" y "TreeSitter CLI"...\n' \
               "$g_color_gray1" "$l_version" "$g_color_reset"
    fi

    #2. Node.JS> Instalación paquetes requeridos para VIM/NeoVIM
    local l_temp
    l_temp=$(npm list -g --depth=0 2> /dev/null) 
    l_status=$?
    if [ $l_status -ne 0 ]; then           
        echo "ERROR: No esta instalando correctamente NodeJS (No se encuentra el gestor de paquetes 'npm'). No se instalaran paquetes basicos."
        return 1
    fi

    #2.1. Paquete 'Prettier' para formateo de archivos como json, yaml, js, ...

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

        print_line '.' $g_max_length_line "$g_color_gray1" 
        echo "NodeJS > Instalando el comando 'prettier' (como paquete global Node.JS)  para formatear archivos json, yaml, js, ..."

        #Se instalara a nivel glabal (puede ser usado por todos los usuarios) y para entornos de desarrallo
        npm install -g --save-dev prettier

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "NodeJS > Comando 'prettier' (paquete global Node.JS) \"$l_version\" ya esta instalando"
        printf "%b         Si usa JS o TS, se recomienda instalar de manera local los paquetes Node.JS para Linter EsLint:\n" "$g_color_gray1"
        printf "              > npm install --save-dev eslint\n"
        printf "              > npm install --save-dev eslint-plugin-prettier%b\n" "$g_color_reset"
    fi


    #2.2. Paquete 'NeoVIM' que ofrece soporte a NeoVIM plugin creados en RTE Node.JS

    #Obtener la version
    if [ -z "$l_temp" ]; then
        l_version="" 
    else
        l_version=$(echo "$l_temp" | grep neovim)
    fi

    if [ -z "$l_version" ]; then

        print_line '.' $g_max_length_line "$g_color_gray1" 
        echo "NodeJS > Instalando el paquete 'neovim' de Node.JS para soporte de plugins en dicho RTE"

        npm install -g neovim

    else
        l_version=$(echo "$l_version" | head -n 1 )
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        echo "NodeJS > Paquete 'neovim' de Node.JS para soporte de plugins con NeoVIM, ya esta instalando: versión \"${l_version}\""
    fi

    #2.3. Paquete 'TreeSitter CLI' que ofrece soporte al 'Tree-sitter grammar'

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
        echo "NodeJS > Paquete 'tree-sitter-cli' de Node.JS para soporte a TreeSitter, ya esta instalando: versión \"${l_version}\""
    fi

    return 0


}

#Instalar RTE Python3 y el paquetes global 'pip3' (gestor de paquetes).
_install_python() {

    #0. Argumentos


    #Validaciones iniciales
    g_is_python_installed=1

    local l_version
    l_version=$(python3 --version 2> /dev/null)
    local l_status=$?

    #l_version2=$(python3 -m pip --version 2> /dev/null)
    local l_version2
    l_version2=$(pip3 --version 2> /dev/null)
    local l_status2=$?

    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi
    
    #Instalación de Python3 y el modulo 'pip' (gestor de paquetes)
    if [ $l_status -ne 0 ] || [ $l_status2 -ne 0 ]; then

        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            print_line '-' $g_max_length_line  "$g_color_gray1"
            echo "Python > Se va instalar RTE Python3 y su gestor de paquetes Pip"
            print_line '-' $g_max_length_line  "$g_color_gray1"


            #Parametros:
            # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
            # 2> Repositorios a instalar/acutalizar: 16 (RTE Python y Pip. Tiene Offset=1)
            # 3> El estado de la credencial almacenada para el sudo
            if [ $l_is_noninteractive -eq 1 ]; then
                ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 2 'python,python-pip' $g_status_crendential_storage
                l_status=$?
            else
                ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 4 'python,python-pip' $g_status_crendential_storage
                l_status=$?
            fi

            #Si no se acepto almacenar credenciales
            if [ $l_status -eq 120 ]; then
                return 120
            #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
            elif [ $l_status -eq 119 ]; then
               g_status_crendential_storage=0
            fi

        fi

    fi

    l_version=$(python3 --version 2> /dev/null)
    l_status=$?
    if [ $l_status -eq 0 ]; then
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        printf 'Python > %bPython3 "%s" esta instalado%b\n'  "$g_color_gray1" "$l_version" "$g_color_reset"
        g_is_python_installed=0
    else
        printf 'Python > %bPython3 no esta instalando. Se recomienda instalarlo%b. Luego de ello, instale los paquetes de Python:\n' "$g_color_red1" "$g_color_reset"

        g_is_python_installed=1
        return $g_is_python_installed
    fi

    #l_version=$(python3 -m pip --version 2> /dev/null)
    l_version=$(pip3 --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        printf 'Python > Comando "%bpip%b" (modulo python) %bno se esta instalando%b. Corrija el error y vuelva configurar el profile.\n' \
            "$g_color_red1" "$g_color_reset" "$g_color_red1" "$g_color_reset"

        #Si no esta instalado el gestor de paquetes no se considerara un error (solo un warning)
        #return 1
        return $g_is_python_installed
    fi

    l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    echo "Ptyhon > Comando 'pip' (modulo python) \"$l_version\" ya esta instalando"

    return $g_is_python_installed


}

#Instalar paquetes de usuario de Python: 'jtbl', 'compiledb', 'rope' y 'pynvim'
_install_user_pckg_python() {

    #Validar si esta instalado python
    local l_version
    l_version=$(python3 --version 2> /dev/null)
    local l_status=$?

    if [ $l_status -ne 0 ]; then

        printf 'Python > %bPython3 NO esta instalado. Corrigaló y luego instale los paquetes:%b\n'  "$g_color_gray1" "$g_color_reset"
        printf '%b       > Comando jtbl      : "pip3 install jtbl --break-system-packages" (mostrar arreglos json en tablas en consola)\n' "$g_color_gray1"
        printf '         > Comando compiledb : "pip3 install compiledb --break-system-packages" (utilidad para generar make file para Clang)\n'
        printf '         > Comando rope      : "pip3 install rope --break-system-packages" (utilidad para refactorización de Python)\n'
        printf '         > Comando pynvim    : "pip3 install pynvim --break-system-packages" (soporte plugin en Python para NeovIM)%b\n' "$g_color_reset"
        return 1
    else
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    fi

    #Validar si esta instalado el gestor de paquetes de python
    local l_version2
    #l_version2=$(python3 -m pip --version 2> /dev/null)
    l_version2=$(pip3 --version 2> /dev/null)
    l_status=$?

    if [ $l_status -ne 0 ]; then

        printf 'Python > %bEl gestor de paquetes de Python "pip3" NO esta instalado. Corrigaló y luego instale los paquetes:%b\n'  "$g_color_gray1" "$g_color_reset"
        printf '%b       > Comando jtbl      : "pip3 install jtbl --break-system-packages" (mostrar arreglos json en tablas en consola)\n' "$g_color_gray1"
        printf '         > Comando compiledb : "pip3 install compiledb --break-system-packages" (utilidad para generar make file para Clang)\n'
        printf '         > Comando rope      : "pip3 install rope --break-system-packages" (utilidad para refactorización de Python)\n'
        printf '         > Comando pynvim    : "pip3 install pynvim --break-system-packages" (soporte plugin en Python para NeovIM)%b\n' "$g_color_reset"
        return 1
    else
        l_version2=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    fi

    printf 'Python > %bPython "%s" y Pip "%s" esta instalando%b. Instalando los paquetes de usuario: "jtbl", "compiledb", "rope" y "pynvim"...\n' \
           "$g_color_gray1" "$l_version" "$l_version2" "$g_color_reset"

    #2. Instalación de Herramienta para mostrar arreglo json al formato tabular
    l_version=$(pip3 list | grep jtbl 2> /dev/null)
    #l_version=$(jtbl -v 2> /dev/null)
    l_status=$?
    #if [ $l_status -ne 0 ]; then
    if [ -z "$l_version" ]; then

        print_line '.' $g_max_length_line "$g_color_gray1" 
        echo "Python > Instalando el comando 'jtbl' (modulo python) para mostrar arreglos json en una consola en formato tabular."
        
        #Se instalar a nivel usuario
        pip3 install jtbl --break-system-packages

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "Python > Comando 'jtbl' (modulo python) \"$l_version\" ya esta instalando"
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

# Parametros:
# > Opcion ingresada por el usuario.
function _install_requirements_ide_vim() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    local l_aux=''
    #2. Determinar si se instalar Python/Pip y su paquetes basicos: 
    #   (-1) No se instala nada 
    #   ( 0) Se instala solo sus paquetes basicos
    #   ( 1) Se instala Python/Pip, sin sus paquetes basicos 
    #   ( 2) Se instala Python/Pip, con sus paquetes basicos
    local l_setup_python=-1

    #¿Se instala los paquetes basicos?
    local l_option=32
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_setup_python=0
    fi

    #¿Se instala Ptyhon/Pip?
    l_option=8
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        if [ $l_setup_python -eq 0 ]; then
            l_setup_python=2
            printf -v l_aux '%bPython/Pip%b y sus %bpaquetes basicos%b' "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        else
            l_setup_python=1
            printf -v l_aux '%bPython/Pip%b' "$g_color_cian1" "$g_color_reset"
        fi
    else
        if [ $l_setup_python -eq 0 ]; then
            printf -v l_aux 'los %bpaquetes basicos de Python%b' "$g_color_cian1" "$g_color_reset"
        fi
    fi


    #2. Determinar si se instalar NodeJS y su paquetes basicos: 
    #   (-1) No se instala nada 
    #   ( 0) Se instala solo sus paquetes basicos
    #   ( 1) Se instala NodeJS, sin sus paquetes basicos 
    #   ( 2) Se instala NodeJS, con sus paquetes basicos
    local l_setup_nodejs=-1

    #¿Se instala los paquetes basicos?
    local l_option=64
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_setup_nodejs=0
    fi

    #¿Se instala NodeJS?
    l_option=16
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        if [ $l_setup_nodejs -eq 0 ]; then
            l_setup_nodejs=2
            if [ -z "$l_aux" ]; then
                printf -v l_aux "%bNodeJS%b y sus %bpaquetes basicos%b" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
            else
                printf -v l_aux "${l_aux}, %bNodeJS%b y sus %bpaquetes basicos%b" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
            fi
        else
            l_setup_nodejs=1
            if [ -z "$l_aux" ]; then
                printf -v l_aux "%bNodeJS%b" "$g_color_cian1" "$g_color_reset"
            else
                printf -v l_aux "${l_aux}, %bNodeJS%b" "$g_color_cian1" "$g_color_reset"
            fi
        fi
    else
        if [ $l_setup_nodejs -eq 0 ]; then
            if [ -z "$l_aux" ]; then
                printf -v l_aux "los %bpaquetes basicos de NodeJS%b" "$g_color_gray1" "$g_color_reset"
            else
                printf -v l_aux "${l_aux}, los %bpaquetes basicos de NodeJS%b" "$g_color_gray1" "$g_color_reset"
            fi
        fi
    fi


    #Si no se instala nada de lo anterior
    if [ $l_setup_python -lt 0 ] && [ $l_setup_nodejs -lt 0 ]; then
        return 99
    fi

    #3. Mostrar el titulo de instalacion
    if [ $gp_type_calling -eq 0 ]; then
        print_line '─' $g_max_length_line  "$g_color_blue1"
        printf "> Instalando ${l_aux}\n"
        print_line '─' $g_max_length_line "$g_color_blue1"
    else
        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf "%bGrupo>%b Instalando ${l_aux}\n" "$g_color_gray1" "$g_color_reset"
        print_line '-' $g_max_length_line "$g_color_gray1"
    fi

    #4. Instalación de Python3 y 'pip' (gestor de paquetes)
    local l_status=0
    if [ $l_setup_python -eq 1 ] || [ $l_setup_python -eq 2 ]; then

        #Instalar Python
        _install_python
        l_status=$?

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        fi

    fi

    if [ $l_setup_python -eq 0 ] || [ $l_setup_python -eq 2 ]; then

        #Instalar sus paquetes basicos
        _install_user_pckg_python
        l_status=$?

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        fi

    fi


    #5. Instalación de NodeJS
    l_status=0
    if [ $l_setup_nodejs -eq 1 ] || [ $l_setup_nodejs -eq 2 ]; then

        #Instalar NodeJS
        _install_nodejs
        l_status=$?

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        fi
    fi

    if [ $l_setup_nodejs -eq 0 ] || [ $l_setup_nodejs -eq 2 ]; then

        #Instalar sus paquetes basicos
        _install_global_pckg_nodejs
        l_status=$?

        #Si no se acepto almacenar credenciales
        if [ $l_status -eq 120 ]; then
            return 120
        fi

    fi

    return 0

}


# Parametros:
# > Opcion ingresada por el usuario.
function _install_vim_programs() {

    #1. Argumentos
    local p_opciones=0
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        p_opciones=$1
    fi

    #2. Determinar si se requiere instalar VIM/NeoVIM
    local l_option=128
    local l_flag_install_vim=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_install_vim=0
    fi
    
    l_option=1024
    local l_flag_install_nvim=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then
        l_flag_install_nvim=0
    fi

    #Si no se solicitar instalar VIM o NeoVIM no instalar ningun comando
    if [ $l_flag_install_vim -ne 0 ] && [ $l_flag_install_nvim -ne 0 ]; then
        return 99
    fi
   
    #3. Mostrar el titulo de instalacion
    local l_aux=""

    if [ $l_flag_install_vim -eq 0 ]; then
        printf -v l_aux "%sVIM%s" "$g_color_cian1" "$g_color_reset"
    fi

    if [ $l_flag_install_nvim -eq 0 ]; then
        if [ ! -z "$l_aux" ]; then
            l_aux="${l_aux} y "
        fi
        printf -v l_aux "%s%sNeoVIM%s" "$l_aux" "$g_color_cian1" "$g_color_reset"
    fi

    if [ $gp_type_calling -eq 0 ]; then
        print_line '─' $g_max_length_line  "$g_color_blue1"
        printf "> Instalando %b\n" "$l_aux"
        print_line '─' $g_max_length_line "$g_color_blue1"
    else
        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf "%bGrupo>%b Instalando %b\n" "$g_color_gray1" "$g_color_reset" "$l_aux"
        print_line '-' $g_max_length_line "$g_color_gray1"
    fi


    #6. Instalar VIM
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi
    
    #Determinar si esta instalando VIM
    l_version=$(vim --version 2> /dev/null)
    l_status=$?
    if [ $l_status -eq 0 ]; then
        l_version=$(echo "$l_version" | head -n 1)
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    else
        l_version=""
        g_is_vim_installed=1
    fi

    #Instalar
    if [ $l_flag_install_vim -eq 0 ]; then

        #print_line '. ' $((g_max_length_line/2)) "$g_color_gray1" 
        if [ -z "$l_version" ]; then

            if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
                
                print_line '-' $g_max_length_line  "$g_color_gray1"
                printf 'VIM > Se va instalar %bVIM-Enhaced%b\n' "$g_color_cian1" "$g_color_reset"
                print_line '-' $g_max_length_line  "$g_color_gray1"

                #Parametros:
                # 1> Tipo de ejecución: 2 (ejecución no-interactiva para instalar/actualizar un respositorio especifico)
                # 2> Packete a instalar/acutalizar.
                # 3> El estado de la credencial almacenada para el sudo
                if [ $l_is_noninteractive -eq 1 ]; then
                    ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 2 'vim' $g_status_crendential_storage
                    l_status=$?
                else
                    ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 4 'vim' $g_status_crendential_storage
                    l_status=$?
                fi

                #Si no se acepto almacenar credenciales
                if [ $l_status -eq 120 ]; then
                    return 120
                #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
                elif [ $l_status -eq 119 ]; then
                   g_status_crendential_storage=0
                fi

            else
                printf 'VIM > %bVIM-Enhaced no esta instalando, se recomienda su instalación%b.\n' "$g_color_red1" "$g_color_reset"
                g_is_vim_installed=1
            fi

        else
            printf 'VIM > VIM-Enhaced "%s" ya esta instalando\n' "$l_version"
        fi


    fi

    #7. Instalar NeoVIM

    #Validar si 'nvim' esta en el PATH
    if [ ! "$g_os_architecture_type" = "aarch64" ]; then
        echo "$PATH" | grep "${g_path_programs}/neovim/bin" &> /dev/null
        l_status=$?
        if [ $l_status -ne 0 ] && [ -f "${g_path_programs}/neovim/bin/nvim" ]; then
            printf '%bNeoVIM %s esta instalando pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                "$g_color_red1" "$l_version" "$g_color_reset"
            printf 'Adicionando a la sesion actual: PATH=%s/neovim/bin:$PATH\n' "${g_path_programs}"
            export PATH=${g_path_programs}/neovim/bin:$PATH
        fi
    fi

    #Determinar si esta instalando VIM:
    l_version=$(nvim --version 2> /dev/null)
    l_status=$?
    if [ $l_status -eq 0 ]; then
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        g_is_vim_installed=0
    else
        l_version=""
        g_is_vim_installed=1
    fi

    #Instalar
    if [ $l_flag_install_nvim -eq 0 ]; then

        if [ -z "$l_version" ]; then

            print_line '-' $g_max_length_line  "$g_color_gray1"
            printf 'NeoVIM > Se va instalar %bNeoVIM%b\n' "$g_color_cian1" "$g_color_reset"
            print_line '-' $g_max_length_line  "$g_color_gray1"

            #Los binarios para arm64 y alpine, se debera usar los repositorios de los SO
            if [ "$g_os_architecture_type" = "aarch64" ] || [ $g_os_subtype_id -eq 1 ]; then

                #Parametros:
                # 1> Tipo de ejecución: 2/4 (ejecución sin menu no-interactiva/interactiva para instalar/actualizar paquetes)
                # 2> Paquete a instalar/acutalizar.
                # 3> El estado de la credencial almacenada para el sudo
                if [ $l_is_noninteractive -eq 1 ]; then
                    ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 2 "nvim" $g_status_crendential_storage
                    l_status=$?
                else
                    ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 4 "nvim" $g_status_crendential_storage
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

                #Parametros:
                # 1> Tipo de ejecución: 2/4 (ejecución sin menu para instalar/actualizar un respositorio especifico)
                # 2> Repsositorio a instalar/acutalizar: 
                # 3> El estado de la credencial almacenada para el sudo
                # 4> Install only last version: por defecto es 1 (false). Solo si ingresa 0 es (true).
                # 5> Flag '0' para mostrar un titulo si se envia, como parametro 2, un solo repositorio a configurar. Por defecto es '1' 
                # 6> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID"
                if [ $l_is_noninteractive -eq 1 ]; then
                    
                    ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 2 "neovim" $g_status_crendential_storage 1 1 "$g_other_calling_user"
                    l_status=$?
                else
                    ${g_repo_path}/.files/setup/linux/01_setup_commands.bash 4 "neovim" $g_status_crendential_storage 1 1 "$g_other_calling_user"
                    l_status=$?
                fi

                #Si no se acepto almacenar credenciales
                if [ $l_status -eq 120 ]; then
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

            #Obtener la version instalada
            l_version=$(nvim --version 2> /dev/null)
            l_status=$?
            if [ $l_status -eq 0 ]; then
                l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
                printf 'Se instaló NeoVIM version "%s"\n' "$l_version"
            else
                printf 'NeoVIM > %bNeoVIM no esta instalando, se recomienda su instalación%b.\n' "$g_color_red1" "$g_color_reset"
                g_is_vim_installed=1
            fi

        else
            echo "NeoVIM > NeoVIM '$l_version' esta instalando. Si desea actualizarlo a la ultima version, use:"
            echo "            > '~/.files/setup/linux/01_setup_commands.bash'"
            echo "            > '~/.files/setup/linux/03_update_all.bash'"
        fi


    fi


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

    if [ $gp_type_calling -eq 0 ]; then
        print_line '─' $g_max_length_line  "$g_color_blue1"
        printf "> %bX11 forwarding%b sobre '%b%s%b': %s\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_tmp1" "$g_color_reset" "$l_tmp2"
        print_line '─' $g_max_length_line "$g_color_blue1"
    else
        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf "%bGrupo>%b %bX11 forwarding%b sobre '%b%s%b': %s\n" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" \
               "$l_tmp1" "$g_color_reset" "$l_tmp2"
        print_line '-' $g_max_length_line "$g_color_gray1"
    fi

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
        ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 2 "$l_pkg_options" $g_status_crendential_storage
        l_status=$?
    else
        ${g_repo_path}/.files/setup/linux/04_setup_packages.bash 4 "$l_pkg_options" $g_status_crendential_storage
        l_status=$?
    fi

    #Si no se acepto almacenar credenciales
    if [ $l_status -eq 120 ]; then
        return 120
    #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
    elif [ $l_status -eq 119 ]; then
       g_status_crendential_storage=0
    fi


    #5. Configurar OpenSSH server para soportar el 'X11 forwading'
    local l_ssh_config_data=""
    if [ $l_flag_ssh_srv -eq 0 ]; then

        print_line '-' $g_max_length_line  "$g_color_gray1"
        printf '%bX forwarding%b> Configurando el servidor OpenSSH...\n' "$g_color_gray1" "$g_color_reset"
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

    if [ $gp_type_calling -eq 0 ]; then
        print_line '─' $g_max_length_line  "$g_color_blue1"
        printf "> Remover la configuración del %bX11 forwarding%b en '%b%s%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_tmp" "$g_color_reset"
        print_line '─' $g_max_length_line "$g_color_blue1"
    else
        print_line '-' $g_max_length_line  "$g_color_blue1"
        printf "Remover la configuración del %bX11 forwarding%b en '%b%s%b'\n" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$l_tmp" "$g_color_reset"
        print_line '-' $g_max_length_line "$g_color_blue1"
    fi

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
    if [ $gp_type_calling -eq 0 ]; then
        print_line '─' $g_max_length_line  "$g_color_blue1"

        if [ $l_flag_overwrite_ln -eq 0 ]; then
            printf "> Creando los %benlaces simbolicos%b del perfil %b(sobrescribir lo existente)%b\n" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        else
            printf "> Creando los %benlaces simbolicos%b del perfil %b(solo crar si no existe)%b\n" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        fi

        print_line '─' $g_max_length_line "$g_color_blue1"
    else
        print_line '-' $g_max_length_line  "$g_color_gray1"

        if [ $l_flag_overwrite_ln -eq 0 ]; then
            printf "%bGrupo>%b Creando los %benlaces simbolicos%b del perfil %b(sobrescribir lo existente)%b\n" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
                   "$g_color_gray1" "$g_color_reset"
        else
            printf "%bGrupo>%b Creando los %benlaces simbolicos%b del perfil %b(solo crar si no existe)%b\n" "$g_color_gray1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" \
                   "$g_color_gray1" "$g_color_reset"
        fi

        print_line '-' $g_max_length_line "$g_color_gray1"
    fi

    

    #3. Creando enlaces simbolico dependientes del tipo de distribución Linux

    #Si es Linux WSL
    local l_target_link
    local l_source_path
    local l_source_filename

    #Archivo de colores de la terminal usado por comandos basicos
    if [ $g_os_type -eq 1 ]; then

        l_target_link="${HOME}/.dircolors"
        l_source_path="${HOME}/.files/terminal/linux/profile"
        l_source_filename='ubuntu_wls_dircolors.conf'
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln

    fi

    #Archivo de configuración de Git
    l_target_link="${HOME}/.gitconfig"
    l_source_path="${HOME}/.files/config/git"
    if [ $g_os_type -eq 1 ]; then
        l_source_filename='git_linux_usr1.toml'
    else
        l_source_filename='git_linux_usr2.toml'
    fi
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Archivo de configuración de SSH
    l_target_link="${HOME}/.ssh/config"
    l_source_path="${HOME}/.files/config/ssh"
    if [ $g_os_type -eq 1 ]; then
        l_source_filename='ssh_linux_01.conf'
    else
        l_source_filename='ssh_linux_02.conf'
    fi
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Archivos de configuración de PowerShell
    l_target_link="${HOME}/.config/powershell/Microsoft.PowerShell_profile.ps1"
    l_source_path="${HOME}/.files/terminal/powershell/profile"
    if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
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
    l_target_link="${HOME}/.bashrc"
    l_source_path="${HOME}/.files/terminal/linux/profile"
    if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
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
    l_target_link="${HOME}/.tmux.conf"
    l_source_path="${HOME}/.files/terminal/linux/tmux"
    l_source_filename='tmux.conf'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln

    #Configuración de un CLI de alto nivel del 'Container Runtime' 'ContainerD': nerdctl
    l_target_link="${HOME}/.config/nerdctl/nerdctl.toml"
    l_source_path="${HOME}/.files/config/nerdctl"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Configuración principal de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless'): Podman
    l_target_link="${HOME}/.config/containers/containers.conf"
    l_source_path="${HOME}/.files/config/podman"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln

    #Configuración de los registros de imagenes de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless'): Podman
    l_target_link="${HOME}/.config/containers/registries.conf"
    l_source_path="${HOME}/.files/config/podman"
    l_source_filename='default_registries.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Configuración de un 'Container Runtime' 'ContainerD' (en modo 'rootless')
    l_target_link="${HOME}/.config/containerd/config.toml"
    l_source_path="${HOME}/.files/config/containerd"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Configuración del backend de compilacion de imagenes 'BuildKit' (en modo 'rootless')
    l_target_link="${HOME}/.config/buildkit/buildkitd.toml"
    l_source_path="${HOME}/.files/config/buildkit"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "Profile > " $l_flag_overwrite_ln


    #Configuracion por defecto para un Cluster de Kubernates
    l_target_link="${HOME}/.kube/config"
    l_source_path="${HOME}/.files/config/kubectl"
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

    #Eliminar VIM-Plug en VIM
    local l_option=131072
    local l_flag_removed=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

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
    l_option=262144
    l_flag_removed=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

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
    l_option=524288
    l_flag_removed=1
    if [ $(( $p_opciones & $l_option )) -eq $l_option ]; then

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




# Opciones:
# 1> Opción de menu a ejecutar
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
    local l_is_noninteractive=1
    if [ $gp_type_calling -eq 2 ]; then
        l_is_noninteractive=0
    fi
    
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
            if [ $gp_type_calling -eq 0 ]; then
                print_line '─' $g_max_length_line  "$g_color_blue1"
                printf "> Actualizar los paquetes del SO '%b%s %s%b'\n" "$g_color_cian1" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
                print_line '─' $g_max_length_line "$g_color_blue1"
            else 
                print_line '-' $g_max_length_line  "$g_color_gray1"
                printf "Actualizar los paquetes del SO '%b%s %s%b'\n" "$g_color_cian1" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
                print_line '-' $g_max_length_line "$g_color_gray1"
            fi

            upgrade_os_packages $g_os_subtype_id $l_is_noninteractive 

        fi
    fi
    
    #05. Instalando los programas requeridos para usar VIM/NeoVIM
    _install_requirements_ide_vim $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    fi

    
    #06. Instalando los programas requeridos para usar VIM/NeoVIM
    _install_vim_programs $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    fi

    #echo "status ${l_status}, opciones ${p_opciones}"

    #07. Configurando VIM/NeoVIM 
    _config_vim_profile $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    fi

    #08. Configuracion el SO: Crear enlaces simbolicos y folderes basicos
    _setup_user_profile $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    fi

    #09. Eliminar el gestor 'VIM-Plug' y Packer
    _remove_vim_plugin_manager $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    fi

    #10. Configurar para tener el soporte a 'X11 forwarding for SSH Server'
    _sutup_support_x11_clipboard $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    fi

    #11. Configurar para tener el soporte a 'X11 forwarding for SSH Server'
    _uninstall_support_x11_clipboard $p_opciones
    l_status=$?
    #Se requiere almacenar las credenciales para realizar cambiso con sudo.
    if [ $l_status -eq 120 ]; then
        return 120
    fi

    #12. Si se invoco interactivamente y se almaceno las credenciales, caducarlo.
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
    printf " (%ba%b) Instalación y configuración de VIM/NeoVIM como %beditor%b basico\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " (%bb%b) Instalación y configuración de VIM/NeoVIM como %bIDE%b\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " (%bc%b) Configurar todo el profile como %bbasico%b    (VIM/NeoVIM como editor basico)\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " (%bd%b) Configurar todo el profile como %bdeveloper%b (VIM/NeoVIM como IDE)\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " (%be%b) Configurar todo el profile como %bbasico%b    (VIM/NeovIM como editor basico) y re-crear enlaces simbolicos\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " (%bf%b) Configurar todo el profile como %bdeveloper%b (VIM/NeoVIM como IDE) y re-crear enlaces simbolicos\n" "$g_color_green1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:\n"

    local l_max_digits=6

    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
        printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes del SO\n" "$g_color_green1" "1" "$g_color_reset"
    fi
    printf "     (%b%0${l_max_digits}d%b) Crear los enlaces simbolicos del profile del usuario\n" "$g_color_green1" "2" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Flag para %bre-crear%b un enlaces simbolicos en caso de existir\n" "$g_color_green1" "4" "$g_color_reset" "$g_color_cian1" "$g_color_reset"

    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
        printf "     (%b%0${l_max_digits}d%b) Instalar %bPython%b y el gestor de paquetes %bPip%b\n" "$g_color_green1" "8" "$g_color_reset" \
               "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
        printf "     (%b%0${l_max_digits}d%b) Instalar %bNodeJS%b\n" "$g_color_green1" "16" "$g_color_reset" \
               "$g_color_cian1" "$g_color_reset"
        printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes%b de usuario de %bPython%b: %b'jtbl', 'compiledb', 'rope' y 'pynvim'%b\n" "$g_color_green1" "32" "$g_color_reset" \
               "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
        printf "     (%b%0${l_max_digits}d%b) Instalar %bpaquetes%b globales de %bNodeJS%b: %b'Prettier', 'NeoVIM' y 'TreeSitter CLI'%b\n" "$g_color_green1" "64" "$g_color_reset" \
               "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    fi

    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Instalar el programa '%bvim%b'\n" "$g_color_green1" "128" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Configurar como %bEditor%b %b(configura '.vimrc', folderes y plugins)%b\n" "$g_color_green1" "256" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Configurar como %bIDE%b    %b(configura '.vimrc', folderes y plugins)%b\n" "$g_color_green1" "512" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"


    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Instalar el programa '%bnvim%b'\n" "$g_color_green1" "1024" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Configurar como %bEditor%b %b(configura '.vimrc', folderes y plugins)%b\n" "$g_color_green1" "2048" "$g_color_reset" \
           "$g_color_cian1" "$g_color_reset" "$g_color_cian1" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Configurar como %bIDE%b    %b(configura '.vimrc', folderes y plugins)%b\n" "$g_color_green1" "4096" "$g_color_reset" \
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
    printf "     (%b%0${l_max_digits}d%b) %bVIM%b    > Eliminar el gestor de paquetes 'VIM-Plug'\n" "$g_color_green1" "131072" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Eliminar el gestor de paquetes 'VIM-Plug'\n" "$g_color_green1" "262144" "$g_color_reset" "$g_color_gray1" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) %bNeoVIM%b > Eliminar el gestor de paquetes 'Packer'\n" "$g_color_green1" "524288" "$g_color_reset" "$g_color_gray1" "$g_color_reset"

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
            a)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
                #(000128) VIM    > Instalar el programa 'vim'
                #(000256) VIM    > Configurar como Editor (configura '.vimrc', folderes y plugins)
                #(001024) NeoVIM > Instalar el programa 'nvim'
                #(002048) NeoVIM > Configurar como Editor (configura '.vimrc', folderes y plugins)
                _setup 3456
                ;;


            b)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
                #(000008) Instalar Python y el gestor de paquetes Pip
                #(000016) Instalar NodeJS
                #(000032) Instalar paquetes de usuario de Python: 'jtbl', 'compiledb', 'rope' y 'pynvim'
                #(000064) Instalar paquetes globales de NodeJS: 'Prettier', 'NeoVIM' y 'TreeSitter CLI'
                #(000128) VIM    > Instalar el programa 'vim'
                #(000512) VIM    > Configurar como IDE    (configura '.vimrc', folderes y plugins)
                #(001024) NeoVIM > Instalar el programa 'nvim'
                #(004096) NeoVIM > Configurar como IDE    (configura '.vimrc', folderes y plugins)
                _setup 5880
                ;;

            c)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
                #(000002) Crear los enlaces simbolicos del profile
                #Opcion (a)
                _setup 3458
                ;;

            d)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
                #(000002) Crear los enlaces simbolicos del profile
                #Opcion (b)
                _setup 5882
                ;;

            e)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
                #(000004) Flag para re-crear un enlaces simbolicos en caso de existir
                #Opcion (c)
                _setup 3462
                ;;

            f)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
                #(000004) Flag para re-crear un enlaces simbolicos en caso de existir
                #Opcion (d)
                _setup 5886
                ;;

            q)
                l_flag_continue=1
                print_line '─' $g_max_length_line "$g_color_green1" 
                printf '\n'
                ;;

            [1-9]*)
                if [[ "$l_options" =~ ^[0-9]+$ ]]; then
                    l_flag_continue=1
                    print_line '─' $g_max_length_line "$g_color_green1" 
                    printf '\n'
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
    printf '    %b~/.files/setup/linux/02_setup_profile.bash 0\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '  > %bConfigurando el profile del usuario/VIM/NeoVIM segun un grupo de opciones de menú indicados%b:\n' "$g_color_cian1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/02_setup_profile.bash CALLING_TYPE MENU-OPTIONS\n%b' "$g_color_yellow1" "$g_color_reset"
    printf '    %b~/.files/setup/linux/02_setup_profile.bash CALLING_TYPE MENU-OPTIONS SUDO-STORAGE-OPTIONS OTHER-USERID\n\n%b' "$g_color_yellow1" "$g_color_reset"
    printf 'Donde:\n'
    printf '  > %bCALLING_TYPE%b Es 0 si se muestra un menu, caso contrario es 1 si es interactivo y 2 si es no-interactivo.%b\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '  > %bSUDO-STORAGE-OPTIONS %bes el estado actual de la credencial almacenada para el sudo. Use -1 o un non-integer, si las credenciales aun no se han almacenado.%b\n' \
           "$g_color_green1" "$g_color_gray1" "$g_color_reset"
    printf '    %bSi es root por lo que no se requiere almacenar la credenciales, use 2. Caso contrario, use 0 si se almaceno la credencial y 1 si no se pudo almacenar las credenciales.%b\n' \
           "$g_color_gray1" "$g_color_reset"
    printf '  > %bOTHER-USERID %bEl GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID".%b\n\n' "$g_color_green1" "$g_color_gray1" "$g_color_reset"

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

    #Validar los requisitos (0 debido a que siempre se ejecuta de modo interactivo)
    _g_status=0
    fulfill_preconditions $g_os_subtype_id 0 0 1 "$g_repo_path"
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then
        g_main
    else
        _g_result=111
    fi

#1.2. No mostrar el menu, la opcion del menu a ejecutar se envia como parametro
else

    #Parametros del script usados hasta el momento:
    # 1> Tipo de configuración: 1 (instalación/actualización).
    # 2> Opciones de menu a ejecutar: entero positivo.
    # 3> El estado de la credencial almacenada para el sudo.
    # 4> El GID y UID del usuario que ejecuta el script, siempre que no se el owner de repositorio, en formato "UID:GID".
    gp_menu_options=0
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        gp_menu_options=$2
    else
        echo "Parametro 2 \"$2\" debe ser una opción valida."
        exit 110
    fi

    if [[ "$3" =~ ^[0-2]$ ]]; then
        g_status_crendential_storage=$3

        if [ $g_status_crendential_storage -eq 0 ]; then
            g_is_credential_storage_externally=0
        fi

    fi

    #Solo si el script e  ejecuta con un usuario diferente al actual (al que pertenece el repositorio)
    g_other_calling_user=''
    if [ "$g_repo_path" != "$HOME" ] && [ ! -z "$4" ]; then
        if [[ "$4" =~ ^[0-9]+:[0-9]+$ ]]; then
            g_other_calling_user="$4"
        else
            echo "Parametro 4 \"$4\" debe ser tener el formado 'UID:GID'."
            exit 110
        fi
    fi

    #Validar los requisitos
    fulfill_preconditions $g_os_subtype_id 1 0 1 "$g_repo_path"
    _g_status=$?

    #Iniciar el procesamiento
    if [ $_g_status -eq 0 ]; then

        _setup $gp_menu_options
        _g_status=$?

        #Informar si se nego almacenar las credencial cuando es requirido
        if [ $_g_status -eq 120 ]; then
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



