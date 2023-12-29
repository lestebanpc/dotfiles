#!/bin/bash

#Inicialización Global {{{

#Funciones generales: determinar el tipo del SO, ...
. ~/.files/terminal/linux/functions/func_utility.bash

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

#Flag '0' indica que vim esta instalado (los plugins de vim se puede instalar sin tener el vim instalado)
g_is_vim_installed=0
g_is_nvim_installed=0
g_is_nodejs_installed=0
g_is_python_installed=0

#Funciones de utilidad
. ~/.files/setup/linux/_common_utility.bash



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
    )


#}}}


#Parametros de salida (SDTOUT): Version de compilador c/c++ instalado
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
            printf "%sEl enlace simbolico '%s' se ha re-creado %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_opaque" "$l_source_fullfilename" "$g_color_reset"
        else
            l_aux=$(readlink "$p_target_link")
            printf "%sEl enlace simbolico '%s' ya existe %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
        fi
    else
        mkdir -p "$p_source_path"
        ln -snf "$l_source_fullfilename" "$p_target_link"
        printf "%sEl enlace simbolico '%s' se ha creado %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_opaque" "$l_source_fullfilename" "$g_color_reset"
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
            printf "%sEl enlace simbolico '%s' se ha re-creado %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_opaque" "$p_source_path" "$g_color_reset"
        else
            l_aux=$(readlink "$p_target_link")
            printf "%sEl enlace simbolico '%s' ya existe %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_opaque" "$l_aux" "$g_color_reset"
        fi
    else
        mkdir -p "$p_source_path"
        ln -snf "${p_source_path}/" "$p_target_link"
        printf "%sEl enlace simbolico '%s' se ha creado %b(ruta real '%s')%b\n" "$p_tag" "$p_target_link" "$g_color_opaque" "$p_source_path" "$g_color_reset"
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
    printf 'Instalando los paquetes usados por %s en %b%s%b...\n' "$l_tag" "$g_color_opaque" "$l_base_plugins" "$g_color_reset"

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
                
                #print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
                printf 'Paquete %s (%s) "%s": No tiene tipo valido\n' "$l_tag" "${l_repo_type}" "${l_repo_git}"
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
             printf 'Paquete %s (%s) "%b%s%b": Ya esta instalado\n' "$l_tag" "${l_repo_type}" "$g_color_opaque" "${l_repo_git}" "$g_color_reset"
             continue
        fi

        #4.5 Instalando el paquete
        cd ${l_base_path}
        printf '\n'
        print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
        if [ $p_is_neovim -eq 0  ]; then
            printf 'NeoVIM> Plugin (%b%s%b) "%b%s%b": Se esta instalando\n' "$g_color_subtitle" "${l_repo_type}" "$g_color_reset" "$g_color_subtitle" "${l_repo_git}" "$g_color_reset"
        else
            printf 'VIM   > Plugin (%b%s%b) "%b%s%b": Se esta instalando\n' "$g_color_subtitle" "${l_repo_type}" "$g_color_reset" "$g_color_subtitle" "${l_repo_git}" "$g_color_reset"
        fi
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
        print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 
        if [ $p_is_neovim -eq 0  ]; then
            printf 'NeoVIM> %bIndexando las documentación%b de los plugins en %s\n' "$g_color_subtitle" "$g_color_reset"
        else
            printf 'VIM   > %bIndexando las documentación%b de los plugins en %s\n' "$g_color_subtitle" "$g_color_reset"
        fi
        print_line '- ' $((g_max_length_line/2)) "$g_color_opaque" 

        for ((l_i=0; l_i< ${l_n}; l_i++)); do
            
            l_doc_path="${la_doc_paths[${l_i}]}"
            l_repo_name="${la_doc_repos[${l_i}]}"
            printf '(%s/%s) Indexando la documentación del plugin %b%s%b en %s: "%bhelptags %s%b"\n' "$((l_i + 1))" "$l_n" "$g_color_opaque" "$l_repo_name" \
                   "$g_color_reset" "$l_tag" "$g_color_opaque" "$l_doc_path" "$g_color_reset"
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
        printf 'Se ha instalado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "$l_tag" "$g_color_reset" "$g_color_subtitle" "Editor" "$g_color_reset"
        return 0
    fi

    printf 'Se ha instalado los plugin/paquetes de %b%s%b como %b%s%b.\n' "$g_color_subtitle" "$l_tag" "$g_color_reset" "$g_color_subtitle" "Developer" "$g_color_reset"
    if [ $g_is_nodejs_installed -ne 0  ]; then

        printf 'Recomendaciones:\n'
        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 vim%b"\n' "$g_color_subtitle" "$g_color_reset"
        if [ $p_is_neovim -eq 0  ]; then
            printf '    > NeoVIM como developer por defecto usa el adaptador LSP y autocompletado nativo. %bNo esta habilitado el uso de CoC%b\n' "$g_color_opaque" "$g_color_reset" 
        else
            printf '    > VIM esta como developer pero NO puede usar CoC  %b(requiere que NodeJS este instalado)%b\n' "$g_color_opaque" "$g_color_reset" 
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
                   "$g_color_opaque" "$g_color_reset"
            nvim --headless -c 'TSInstall html css javascript jq json yaml xml toml typescript proto make sql bash' -c 'qa'

            printf '  Instalando "language parsers" de TreeSitter "%b:TSInstall java kotlin llvm lua rust swift c cpp go c_sharp%b"\n' \
                   "$g_color_opaque" "$g_color_reset"
            nvim --headless -c 'TSInstall java kotlin llvm lua rust swift c cpp go c_sharp' -c 'qa'
        fi
    fi

    #Instalando extensiones basicos de CoC: Adaptador de LSP server basicos JS, Json, HTLML, CSS, Python, Bash
    printf '  Instalando extensiones de CoC (Adaptador de LSP server basicos) "%b:CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh%b"\n' \
           "$g_color_opaque" "$g_color_reset"
    if [ $p_is_neovim -ne 0  ]; then
        vim -esc 'CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh' -c 'qa'
    else
        USE_COC=1 nvim --headless -c 'CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh' -c 'qa'
    fi

    #Instalando extensiones basicos de CoC: Motor de snippets 'UtilSnips'
    printf '  Instalando extensiones de CoC (Motor de snippets "UtilSnips") "%b:CocInstall coc-ultisnips%b" (%bno se esta usando el nativo de CoC%b)\n' \
           "$g_color_opaque" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    if [ $p_is_neovim -ne 0  ]; then
        vim -esc 'CocInstall coc-ultisnips' -c 'qa'
    else
        USE_COC=1 nvim --headless -c 'CocInstall coc-ultisnips' -c 'qa'
    fi

    #Actualizar las extensiones de CoC
    printf '  Actualizando los extensiones existentes de CoC, ejecutando el comando "%b:CocUpdate%b"\n' "$g_color_opaque" "$g_color_reset"
    if [ $p_is_neovim -ne 0  ]; then
        vim -esc 'CocUpdate' -c 'qa'
    else
        USE_COC=1 nvim --headless -c 'CocUpdate' -c 'qa'
    fi

    #Actualizando los gadgets de 'VimSpector'
    if [ $p_is_neovim -ne 0  ]; then
        printf '  Actualizando los gadgets de "VimSpector", ejecutando el comando "%b:VimspectorUpdate%b"\n' "$g_color_opaque" "$g_color_reset"
        vim -esc 'VimspectorUpdate' -c 'qa'
    fi


    printf '\nRecomendaciones:\n'
    if [ $p_is_neovim -ne 0  ]; then

        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 vim%b"\n' "$g_color_subtitle" "$g_color_reset"
        printf '    > Se recomienda que configure su IDE CoC segun su necesidad:\n'

    else

        printf '  > Por defecto, se ejecuta el IDE vinculado al LSP nativo de NeoVIM.\n'
        printf '    > Si desea usar CoC, use: "%bUSE_COC=1 nvim%b"\n' "$g_color_subtitle" "$g_color_reset"
        printf '    > Si desea usar como editor (no cargar plugins de IDE), use: "%bUSE_EDITOR=1 nvim%b"\n' "$g_color_subtitle" "$g_color_reset"

        printf '  > Si usar como Developer con IDE CoC, se recomienda que lo configura segun su necesidad:\n'

    fi

    echo "        1> Instalar extensiones de COC segun su necesidad (Listar existentes \":CocList extensions\")"
    echo "        2> Revisar la Configuracion de COC \":CocConfig\":"
    echo "          2.1> El diganostico se enviara ALE (no se usara el integrado de CoC), revisar:"
    echo "               { \"diagnostic.displayByAle\": true }"
    echo "          2.2> El formateador de codigo 'Prettier' sera proveido por ALE (no se usara la extension 'coc-prettier')"
    echo "               Si esta instalado esta extension, desintalarlo."


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


    #Sobrescribir los enlaces simbolicos
    local l_option=4
    local l_flag=$(( $p_opciones & $l_option ))
    local l_overwrite_ln_flag=1
    if [ $l_flag -eq $l_option ]; then l_overwrite_ln_flag=0; fi

    printf '\n'
    print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 

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
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


        l_target_link="${HOME}/.config/nvim/init.vim"
        l_source_path="${HOME}/.files/nvim"
        if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
            l_source_filename='init_ide_linux_non_shared.vim'
        else
            l_source_filename='init_ide_linux_shared.vim'
        fi
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

        l_target_link="${HOME}/.config/nvim/lua"
        l_source_path="${HOME}/.files/nvim/lua"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

        
        #El codigo open/close asociado a los 'file types'
        l_target_link="${HOME}/.config/nvim/ftplugin"
        l_source_path="${HOME}/.files/nvim/ide_commom/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


        #Para el codigo open/close asociado a los 'file types' de CoC
        l_target_link="${HOME}/.config/nvim/runtime_coc/ftplugin"
        l_source_path="${HOME}/.files/nvim/ide_coc/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


        #Para el codigo open/close asociado a los 'file types' que no sean CoC
        l_target_link="${HOME}/.config/nvim/runtime_nococ/ftplugin"
        l_source_path="${HOME}/.files/nvim/ide_nococ/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

    #Configurar NeoVIM como Editor
    else

        l_target_link="${HOME}/.config/nvim/init.vim"
        l_source_path="${HOME}/.files/nvim"
        l_source_filename='init_basic_linux.vim'
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

        
        l_target_link="${HOME}/.config/nvim/lua"
        l_source_path="${HOME}/.files/nvim/lua"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


        #El codigo open/close asociado a los 'file types' como Editor
        l_target_link="${HOME}/.config/nvim/ftplugin"
        l_source_path="${HOME}/.files/nvim/editor/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


    fi

    #6. Instalando paquetes
    _setup_vim_packages 0 $p_flag_developer


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
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag

        
        l_target_link="${HOME}/.vim/ftplugin"
        l_source_path="${HOME}/.files/vim/ide_coc/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag


        l_target_link="${HOME}/.vimrc"
        l_source_path="${HOME}/.files/vim"
        if [ $g_user_sudo_support -eq 2 ] || [ $g_user_sudo_support -eq 3 ]; then
            l_source_filename='vimrc_ide_linux_non_shared.vim'
        else
            l_source_filename='vimrc_ide_linux_shared.vim'
        fi
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag


    #Configurar VIM como Editor basico
    else

        l_target_link="${HOME}/.vimrc"
        l_source_path="${HOME}/.files/vim"
        l_source_filename='vimrc_basic_linux.vim'
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag


        l_target_link="${HOME}/.vim/ftplugin"
        l_source_path="${HOME}/.files/vim/editor/ftplugin"
        _create_folder_link "$l_source_path" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag


    fi

    #Instalar los plugins
    _setup_vim_packages 1 $p_flag_developer

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
        _config_nvim $p_opciones $l_flag_developer_nvim
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
    g_is_nodejs_installed=1

    #Validar si 'node' esta en el PATH
    echo "$PATH" | grep "${g_path_programs}/nodejs/bin" &> /dev/null
    l_status=$?
    if [ $l_status -ne 0 ] && [ -f "${g_path_programs}/nodejs/bin/node" ]; then
        printf '%bNode.JS %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
            "$g_color_warning" "$l_version" "$g_color_reset"
        printf 'Adicionando a la sesion actual: PATH=%s/nodejs/bin:$PATH\n' "${g_path_programs}"
        export PATH=${g_path_programs}/nodejs/bin:$PATH
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

    #Si esta instalado
    else
        l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
        echo "VIM (IDE)   > Node.JS \"$l_version\" ya esta instalado"
        g_is_nodejs_installed=0
    fi

    #2. Node.JS> Instalación paquetes requeridos para VIM/NeoVIM
    local l_temp
    l_temp=$(npm list -g --depth=0 2> /dev/null) 
    l_status=$?
    if [ $l_status -ne 0 ]; then           
        echo "ERROR: No esta instalado correctamente NodeJS (No se encuentra el gestor de paquetes 'npm'). No se instalaran paquetes basicos."
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

        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        echo "VIM (IDE)   > Instalando el comando 'prettier' (como paquete global Node.JS)  para formatear archivos json, yaml, js, ..."

        #Se instalara a nivel glabal (puede ser usado por todos los usuarios) y para entornos de desarrallo
        npm install -g --save-dev prettier

    else
        l_version=$(echo "$l_version" | head -n 1 | sed "$g_regexp_sust_version1")
        echo "VIM (IDE)   > Comando 'prettier' (paquete global Node.JS) \"$l_version\" ya esta instalado"
        echo "              Si usa JS o TS, se recomienda instalar de manera local los paquetes Node.JS para Linter EsLint:"
        echo "                 > npm install --save-dev eslint"
        echo "                 > npm install --save-dev eslint-plugin-prettier"
    fi



    #3. Node.JS> Instalando paquete requeridos por NeoVIM
    if [ $p_flag_developer_nvim -eq 0 ]; then


        #3.1. Paquete 'NeoVIM' que ofrece soporte a NeoVIM plugin creados en RTE Node.JS

        #Obtener la version
        if [ -z "$l_temp" ]; then
            l_version="" 
        else
            l_version=$(echo "$l_temp" | grep neovim)
        fi

        if [ -z "$l_version" ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "NeoVIM (IDE)> Instalando el paquete 'neovim' de Node.JS para soporte de plugins en dicho RTE"

            npm install -g neovim

        else
            l_version=$(echo "$l_version" | head -n 1 )
            l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
            echo "NeoVIM (IDE)> Paquete 'neovim' de Node.JS para soporte de plugins con NeoVIM, ya esta instalado: versión \"${l_version}\""
        fi

        #3.1. Paquete 'TreeSitter CLI' que ofrece soporte al 'Tree-sitter grammar'

        #Obtener la version
        if [ -z "$l_temp" ]; then
            l_version="" 
        else
            l_version=$(echo "$l_temp" | grep tree-sitter-cli)
        fi

        if [ -z "$l_version" ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "NeoVIM (IDE)> Instalando el paquete 'tree-sitter-cli' de Node.JS para soporte de TreeSitter"

            npm install -g tree-sitter-cli

        else
            l_version=$(echo "$l_version" | head -n 1 )
            l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
            echo "NeoVIM (IDE)> Paquete 'tree-sitter-cli' de Node.JS para soporte a TreeSitter, ya esta instalado: versión \"${l_version}\""
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
    g_is_python_installed=1
    l_version=$(python3 --version 2> /dev/null)
    l_status=$?

    l_version2=$(python3 -m pip --version 2> /dev/null)
    l_status2=$?

    if [ $l_status -ne 0 ] || [ $l_status2 -ne 0 ]; then

        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "VIM (IDE)   > Se va instalar RTE Python3 y su gestor de paquetes Pip"


            #Parametros:
            # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
            # 2> Repositorios a instalar/acutalizar: 16 (RTE Python y Pip. Tiene Offset=1)
            # 3> El estado de la credencial almacenada para el sudo
            ~/.files/setup/linux/03_setup_packages.bash 1 16 $g_status_crendential_storage
            l_status=$?

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
        printf 'VIM (IDE)   > Python3 "%s" esta instalado\n' "$l_version"
        g_is_python_installed=0
    else
        printf 'VIM (IDE)   > %bPython3 no esta instalado. Se recomienda instalarlo%b. Luego de ello, instale los paquetes de Python:\n' "$g_color_warning" "$g_color_reset"
        printf '%b            > Comando jtbl      : "pip3 install jtbl" (mostrar arreglos json en tablas en consola)\n' "$g_color_opaque"
        printf '            > Comando compiledb : "pip3 install compiledb" (utilidad para generar make file para Clang)\n'
        printf '            > Comando rope      : "pip3 install rope" (utilidad para refactorización de Python)\n'
        printf '            > Comando pynvim    : "pip3 install pynvim" (soporte plugin en Python para NeovIM)%b\n' "$g_color_reset"

        g_is_python_installed=1
        #return 1
        return 0
    fi

    #l_version=$(python3 -m pip --version 2> /dev/null)
    l_version=$(pip3 --version 2> /dev/null)
    l_status=$?
    if [ $l_status -ne 0 ]; then
        printf 'VIM (IDE)   > Comando "%bpip%b" (modulo python) %bno se esta instalado%b. Corrija el error y vuelva configurar el profile.\n' \
            "$g_color_warning" "$g_color_reset" "$g_color_warning" "$g_color_reset"
        return 1
    fi

    l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
    echo "VIM (IDE)   > Comando 'pip' (modulo python) \"$l_version\" ya esta instalado"

    #2. Instalación de Herramienta para mostrar arreglo json al formato tabular
    l_version=$(pip3 list | grep jtbl 2> /dev/null)
    #l_version=$(jtbl -v 2> /dev/null)
    l_status=$?
    #if [ $l_status -ne 0 ]; then
    if [ -z "$l_version" ]; then

        print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        echo "General     > Instalando el comando 'jtbl' (modulo python) para mostrar arreglos json en una consola en formato tabular."
        
        #Se instalar a nivel usuario
        pip3 install jtbl --break-system-packages

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
        pip3 install compiledb --break-system-packages

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
        pip3 install rope --break-system-packages

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
            pip3 install pynvim --break-system-packages

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


    #4. Para developer: Instalar utilitarios para gestion de "clipbboard" (X11 Selection): XSel
    local l_version
    local l_status

    if [ $l_flag_developer_vim -eq 0 ] || [ $l_flag_developer_nvim -eq 0 ]; then

        if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
            
            l_version=$(xsel --version 2> /dev/null)
            l_status=$?

            #if [ $l_status -ne 0 ] || [ $l_status2 -ne 0 ]; then
            if [ $l_status -ne 0 ]; then

                print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
                echo "General     > Se va instalar un comando para gestion de X11 Clipboard: XSel"

                #Parametros:
                # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
                # 2> Repositorios a instalar/acutalizar: 4 (herramienta de X11 clipbboard 'XSel'. Tiene Offset=1)
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

        fi


        l_version=$(xsel --version 2> /dev/null)
        l_status=$?
        if [ $l_status -eq 0 ]; then
            l_version=$(echo "$l_version" | head -n 1 )
            l_version=$(echo "$l_version" | sed "$g_regexp_sust_version1")
            printf 'General     > XSel "%s" esta instalado\n' "$l_version"
        else
            printf 'General     > %bXSel no esta esta instalado, se recomienda instalarlo%b.\n' "$g_color_warning" "$g_color_reset"
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
        g_is_vim_installed=1
    fi

    #Instalar
    if [ $l_flag_install_vim -eq 0 ]; then

        #print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
        if [ -z "$l_version" ]; then

            if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
                
                print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
                echo "VIM         > Se va instalar VIM-Enhaced"

                #Parametros:
                # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
                # 2> Repositorios a instalar/acutalizar: 32 (editor VIM. Tiene Offset=1)
                # 3> El estado de la credencial almacenada para el sudo
                ~/.files/setup/linux/03_setup_packages.bash 1 32 $g_status_crendential_storage
                l_status=$?

                #Si no se acepto almacenar credenciales
                if [ $l_status -eq 120 ]; then
                    return 120
                #Si se almaceno las credenciales dentro del script invocado, el script caller (este script), es el responsable de caducarlo.
                elif [ $l_status -eq 119 ]; then
                   g_status_crendential_storage=0
                fi

            else
                printf 'VIM         > %bVIM-Enhaced no esta instalado, se recomienda su instalación%b.\n' "$g_color_warning" "$g_color_reset"
                g_is_vim_installed=1
            fi

        else
            printf 'VIM         > VIM-Enhaced "%s" ya esta instalado' "$l_version"
        fi


    fi

    #7. Instalar NeoVIM

    #Validar si 'nvim' esta en el PATH
    if [ ! "$g_os_architecture_type" = "aarch64" ]; then
        echo "$PATH" | grep "${g_path_programs}/neovim/bin" &> /dev/null
        l_status=$?
        if [ $l_status -ne 0 ] && [ -f "${g_path_programs}/neovim/bin/nvim" ]; then
            printf '%bNeoVIM %s esta instalado pero no esta en el $PATH del usuario%b. Se recomienda que se adicione en forma permamente en su profile\n' \
                "$g_color_warning" "$l_version" "$g_color_reset"
            printf 'Adicionando a la sesion actual: PATH=%s/neovim/bin:$PATH\n' "${g_path_programs}"
            export PATH=${g_path_programs}/neovim/bin:$PATH
        fi
    fi

    #Determinar si esta instalado VIM:
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

            print_line '. ' $((g_max_length_line/2)) "$g_color_opaque" 
            echo "NeoVIM      > Se va instalar NeoVIM"

            #Los binarios para arm64, se debera usar los repositorios de los SO
            if [ "$g_os_architecture_type" = "aarch64" ]; then

                #Parametros:
                # 1> Tipo de ejecución: 1 (ejecución no-interactiva para instalar/actualizar un grupo paquetes)
                # 2> Repositorios a instalar/acutalizar: 64 (editor NeoVIM. Tiene Offset=1)
                # 3> El estado de la credencial almacenada para el sudo
                ~/.files/setup/linux/03_setup_packages.bash 1 64 $g_status_crendential_storage
                l_status=$?

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
                printf 'NeoVIM      > %bNeoVIM no esta instalado, se recomienda su instalación%b.\n' "$g_color_warning" "$g_color_reset"
                g_is_vim_installed=1
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
        _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

    fi

    #Archivo de configuración de Git
    l_target_link="${HOME}/.gitconfig"
    l_source_path="${HOME}/.files/config/git"
    if [ $g_os_type -eq 1 ]; then
        l_source_filename='git_linux_usr1.toml'
    else
        l_source_filename='git_linux_usr2.toml'
    fi
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Archivo de configuración de SSH
    l_target_link="${HOME}/.ssh/config"
    l_source_path="${HOME}/.files/config/ssh"
    if [ $g_os_type -eq 1 ]; then
        l_source_filename='ssh_linux_01.conf'
    else
        l_source_filename='ssh_linux_02.conf'
    fi
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Archivos de configuración de PowerShell
    l_target_link="${HOME}/.config/powershell/Microsoft.PowerShell_profile.ps1"
    l_source_path="${HOME}/.files/terminal/powershell"
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
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

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
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #4. Creando enlaces simbolico independiente del tipo de distribución Linux

    #Crear el enlace de TMUX
    l_target_link="${HOME}/.tmux.conf"
    l_source_path="${HOME}/.files/terminal/linux/tmux"
    l_source_filename='tmux.conf'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

    #Configuración de un CLI de alto nivel del 'Container Runtime' 'ContainerD': nerdctl
    l_target_link="${HOME}/.config/nerdctl/nerdctl.toml"
    l_source_path="${HOME}/.files/config/nerdctl"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Configuración principal de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless'): Podman
    l_target_link="${HOME}/.config/containers/containers.conf"
    l_source_path="${HOME}/.files/config/podman"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

    #Configuración de los registros de imagenes de un 'Container Runtime'/CLI de alto nivel (en modo 'rootless'): Podman
    l_target_link="${HOME}/.config/containers/registries.conf"
    l_source_path="${HOME}/.files/config/podman"
    l_source_filename='default_registries.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Configuración de un 'Container Runtime' 'ContainerD' (en modo 'rootless')
    l_target_link="${HOME}/.config/containerd/config.toml"
    l_source_path="${HOME}/.files/config/containerd"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Configuración del backend de compilacion de imagenes 'BuildKit' (en modo 'rootless')
    l_target_link="${HOME}/.config/buildkit/buildkitd.toml"
    l_source_path="${HOME}/.files/config/buildkit"
    l_source_filename='default_config.toml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Configuracion por defecto para un Cluster de Kubernates
    l_target_link="${HOME}/.kube/config"
    l_source_path="${HOME}/.files/config/kubectl"
    l_source_filename='default_config.yaml'
    _create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

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


    #Eliminar VIM-Plug en NeoVIM
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

    #Eliminar Packer en NeoVIM
    l_option=2048
    l_flag=$(( $p_opciones & $l_option ))

    l_flag_removed=1
    if [ $l_flag -eq $l_option ]; then

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
            printf 'No esta instalado el gestor de paquetes "Packer" en NeoVIM\n'
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
    local l_flag
    
    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then

        l_flag=$(( $p_opciones & $l_option ))
        if [ $l_flag -eq $l_option ]; then

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
            print_line '─' $g_max_length_line  "$g_color_opaque"
            printf -v l_title "Actualizar los paquetes del SO '%s%s %s%s'" "$g_color_subtitle" "${g_os_subtype_name}" "${g_os_subtype_version}" "$g_color_reset"
            print_text_in_center2 "$l_title" $g_max_length_line 
            print_line '─' $g_max_length_line "$g_color_opaque"
           
            upgrade_os_packages $g_os_subtype_id 

        fi
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

    #08. Eliminar el gestor 'VIM-Plug' y Packer
    _remove_vim_plugin_manager $p_opciones
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

    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
        printf "     (%b%0${l_max_digits}d%b) Actualizar los paquetes del SO\n" "$g_color_title" "1" "$g_color_reset"
    fi
    printf "     (%b%0${l_max_digits}d%b) Crear los enlaces simbolicos del profile\n" "$g_color_title" "2" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) Flag para %bre-crear%b un enlaces simbolicos en caso de existir\n" "$g_color_title" "4" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) VIM    - Instalar el programa '%bvim%b'\n" "$g_color_title" "8" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) VIM    - Configurar lo basico %b(configura '.vimrc', folderes y plugins que habilitan el modo basico)%b\n" "$g_color_title" "16" \
           "$g_color_reset" "$g_color_opaque" "$g_color_reset"

    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
        printf "     (%b%0${l_max_digits}d%b) VIM    - Flag habilitar como %bIDE%b %b(instala 'xsel', 'python3', 'nodejs'/configura '.vimrc' y plugins para developers)%b\n" "$g_color_title" "32" \
               "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    else
        printf "     (%b%0${l_max_digits}d%b) VIM    - Flag habilitar como %bIDE%b %b(configura '.vimrc' y plugins para developers)%b\n" "$g_color_title" "32" \
               "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    fi

    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Instalar el programa '%bnvim%b'\n" "$g_color_title" "64" "$g_color_reset" "$g_color_subtitle" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Configurar lo basico %b(configura 'init.vim', folderes y plugins que habilitan el modo basico)%b\n" "$g_color_title" "128" \
           "$g_color_reset" "$g_color_opaque" "$g_color_reset"

    if [ $g_user_sudo_support -ne 2 ] && [ $g_user_sudo_support -ne 3 ]; then
        printf "     (%b%0${l_max_digits}d%b) NeoVIM - Flag habilitar como %bIDE%b %b(instala 'xsel', 'python3', 'nodejs'/configura 'init.vim' y plugins para developers)%b\n" "$g_color_title" "256" \
               "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    else
        printf "     (%b%0${l_max_digits}d%b) NeoVIM - Flag habilitar como %bIDE%b %b(configura 'init.vim' y plugins para developers)%b\n" "$g_color_title" "256" \
               "$g_color_reset" "$g_color_subtitle" "$g_color_reset" "$g_color_opaque" "$g_color_reset"
    fi
    printf "     (%b%0${l_max_digits}d%b) VIM    - Eliminar el gestor de paquetes 'VIM-Plug'\n" "$g_color_title" "512" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Eliminar el gestor de paquetes 'VIM-Plug'\n" "$g_color_title" "1024" "$g_color_reset"
    printf "     (%b%0${l_max_digits}d%b) NeoVIM - Eliminar el gestor de paquetes 'Packer'\n" "$g_color_title" "2048" "$g_color_reset"

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
fulfill_preconditions $g_os_subtype_id 0 0 1
_g_status=$?

#Iniciar el procesamiento
if [ $_g_status -eq 0 ]; then
    g_main
fi




