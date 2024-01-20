# Repositorios GIT donde estan los plugins VIM
# Valores:
#   (1) Perfil Basic - Tema
#   (2) Perfil Basic - UI
#   (3) Perfil Developer - Typing
#   (4) Perfil Developer - IDE
$gd_repos_type= @{
        'tomasr/molokai'= 1
        'dracula/vim'= 1
        'vim-airline/vim-airline'= 2
        'vim-airline/vim-airline-themes'= 2
        'preservim/nerdtree'= 2
        'ryanoasis/vim-devicons'= 2
        'preservim/vimux'= 2
        'christoomey/vim-tmux-navigator'= 2
        'junegunn/fzf'= 2
        'junegunn/fzf.vim'= 2
        'tpope/vim-surround'= 3
        'mg979/vim-visual-multi'= 3
        'mattn/emmet-vim'= 3
        'dense-analysis/ale'= 4
        'neoclide/coc.nvim'= 4
        'OmniSharp/omnisharp-vim'= 4
        'SirVer/ultisnips'= 4
        'honza/vim-snippets'= 4
        'puremourning/vimspector'= 4
        'folke/tokyonight.nvim'= 1
        'kyazdani42/nvim-web-devicons'= 2
        'nvim-lualine/lualine.nvim'= 2
        'akinsho/bufferline.nvim'= 2
        'nvim-lua/plenary.nvim'= 2
        'nvim-telescope/telescope.nvim'= 2
        'nvim-tree/nvim-tree.lua'= 2
        'nvim-treesitter/nvim-treesitter'= 4
        'jose-elias-alvarez/null-ls.nvim'= 4
        'neovim/nvim-lspconfig'= 4
        'hrsh7th/nvim-cmp'= 4
        'ray-x/lsp_signature.nvim'= 4
        'hrsh7th/cmp-nvim-lsp'= 4
        'hrsh7th/cmp-buffer'= 4
        'hrsh7th/cmp-path'= 4
        'L3MON4D3/LuaSnip'= 4
        'rafamadriz/friendly-snippets'= 4
        'saadparwaiz1/cmp_luasnip'= 4
        'kosayoda/nvim-lightbulb'= 4
        'mfussenegger/nvim-dap'= 4
        'theHamsta/nvim-dap-virtual-text'= 4
        'rcarriga/nvim-dap-ui'= 4
        'nvim-telescope/telescope-dap.nvim'= 4
	}

# Repositorios Git - para VIM/NeoVIM. Por defecto es 3 (para ambos)
#  1 - Para VIM
#  2 - Para NeoVIM
$gd_repos_scope= @{
        'tomasr/molokai'= 1
        'dracula/vim'= 1
        'vim-airline/vim-airline'= 1
        'vim-airline/vim-airline-themes'= 1
        'ryanoasis/vim-devicons'= 1
        'preservim/nerdtree'= 1
        'puremourning/vimspector'= 1
        'folke/tokyonight.nvim'= 2
        'kyazdani42/nvim-web-devicons'= 2
        'nvim-lualine/lualine.nvim'= 2
        'akinsho/bufferline.nvim'= 2
        'nvim-lua/plenary.nvim'= 2
        'nvim-telescope/telescope.nvim'= 2
        'nvim-tree/nvim-tree.lua'= 2
        'nvim-treesitter/nvim-treesitter'= 2
        'jose-elias-alvarez/null-ls.nvim'= 2
        'neovim/nvim-lspconfig'= 2
        'hrsh7th/nvim-cmp'= 2
        'ray-x/lsp_signature.nvim'= 2
        'hrsh7th/cmp-nvim-lsp'= 2
        'hrsh7th/cmp-buffer'= 2
        'hrsh7th/cmp-path'= 2
        'L3MON4D3/LuaSnip'= 2
        'rafamadriz/friendly-snippets'= 2
        'saadparwaiz1/cmp_luasnip'= 2
        'kosayoda/nvim-lightbulb'= 2
        'mfussenegger/nvim-dap'= 2
        'theHamsta/nvim-dap-virtual-text'= 2
        'rcarriga/nvim-dap-ui'= 2
        'nvim-telescope/telescope-dap.nvim'= 2
	}

# Repositorios Git - Branch donde esta el plugin no es el por defecto
$gd_repos_branch= @{
        'neoclide/coc.nvim'= 'release'
    }

# Repositorios Git - Deep de la clonacion del repositorio que no es el por defecto
$gd_repos_depth= @{
        'neoclide/coc.nvim'= 1
        'junegunn/fzf'= 1
	}



function m_setup_vim_packeges($p_is_neovim, $p_flag_developer)
{
	#1. Argumentos    

    #2. Ruta base donde se instala el plugins/paquete
    $l_tag="VIM"
    $l_current_scope=1
    $l_base_plugins="${env:USERPROFILE}/vimfiles/pack"
    if ($p_is_neovim)
	{
        $l_base_plugins="${env:LOCALAPPDATA}/nvim-data/site/pack"
        $l_current_scope=2
        $l_tag="NeoVIM"
    }

    #2. Crear las carpetas de basicas
    printf 'Instalando los paquetes usados por %s en %b%s%b...\n' "$l_tag" "$g_color_gray1" "$l_base_plugins" "$g_color_reset"

    mkdir -p ${l_base_plugins}
    mkdir -p ${l_base_plugins}/themes/start
    mkdir -p ${l_base_plugins}/themes/opt
    mkdir -p ${l_base_plugins}/ui/start
    mkdir -p ${l_base_plugins}/ui/opt
    if ($p_flag_developer)
	{
        mkdir -p ${l_base_plugins}/typing/start
        mkdir -p ${l_base_plugins}/typing/opt
        mkdir -p ${l_base_plugins}/ide/start
        mkdir -p ${l_base_plugins}/ide/opt
    }
   
    
    #4. Instalar el plugins que se instalan manualmente
    $l_base_path= ""
    $l_repo_git= ""
    $l_repo_name= ""
    $l_repo_type=1
    $l_repo_url= ""
    $l_repo_branch= ""
    $l_repo_depth= 1
    $l_repo_scope= ""
    $l_aux= ""
	
    $la_doc_paths= New-Object System.Collections.Generic.List[System.String]
    $la_doc_repos= New-Object System.Collections.Generic.List[System.String]
	
	$l_repo_path= ""
	$l_repo_name= ""

    for l_repo_git in "${!gA_repos_type[@]}" {

        #4.1 Configurar el repositorio
        l_repo_scope="${gA_repos_scope[${l_repo_git}]:-3}"
        l_repo_type=${gA_repos_type[$l_repo_git]}
        l_repo_name=${l_repo_git#*/}

        #Si el repositorio no esta habilitido para su scope, continuar con el siguiente
        if [ $((l_repo_scope & l_current_scope)) -ne $l_current_scope ]; then
            continue
        fi

        #4.2 Obtener la ruta base donde se clonara el paquete (todos los paquetes son opcionale, se inicia bajo configuraci├│n)
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

        #Almacenando las ruta de documentacion a indexar
		if(Test-Path "${l_base_path}/${l_repo_name}/doc") {
        
            #Indexar la documentaci├│n de plugins
            la_doc_paths.Add("${l_base_path}/${l_repo_name}/doc")
            la_doc_repos.Add("${l_repo_name}")

        }

        Write-Host ""

	}

    #4. Actualizar la documentación de VIM (Los plugins VIM que no tiene documentación, no requieren indexar)
	$l_n= $la_doc_paths.Count
	if( $l_n -gt 0 )
	{
		Write-Host ""
		Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
		if(${p_flag_nvim})
		{		
			Write-Host "- NeoVIM> Indexando la documentación de los plugin"
		}
		else
		{
			Write-Host "-    VIM> Indexando la documentación de los plugin"
		}
		Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
		
		$l_j
		for ($i=0; $i -lt $l_n; $i++) {
			$l_repo_path= $la_doc_paths[$i]
			$l_repo_name= $la_doc_repos[$i]
			$l_j= $i + 1
			Write-Host "(${l_j}/(l_n)) Indexando la documentación del plugin `"${l_repo_name}`" en `"${l_tag}`": `"helptags ${l_repo_path}`"\n"
			if(${p_flag_nvim})
			{
                nvim --headless -c "helptags ${l_repo_path}" -c qa
			}
			else
			{
                vim -u NONE -esc "helptags ${l_repo_path}" -c qa
			}

			
		}
	}
	

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
        
    printf 'Los plugins del IDE CoC de %s tiene componentes que requieren inicializaci├│n para su uso. Inicilizando dichas componentes del plugins...\n' "$l_tag"

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
function m_config_nvim($p_flag_developer, $p_overwrite_ln_flag ) {

    #1. Argumentos    
    

    #Sobrescribir los enlaces simbolicos
    local l_option=4
    local l_flag=$(( $p_opciones & $l_option ))
    local l_overwrite_ln_flag=1
    if [ $l_flag -eq $l_option ]; then l_overwrite_ln_flag=0; fi

    printf '\n'
    print_line '. ' $((g_max_length_line/2)) "$g_color_gray1" 

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
    m_setup_vim_packages 0 $p_flag_developer


}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
#  2> Sobrescribir los enlaces simbolicos
function m_config_vim($p_flag_developer, $p_overwrite_ln_flag) {

    #1. Argumentos    
    

    #2. Crear el subtitulo

    #print_line '-' $g_max_length_line "$g_color_gray1" 
    #echo "> Configuraci├│n de VIM-Enhanced"
    #print_line '-' $g_max_length_line "$g_color_gray1" 

    printf '\n'
    print_line '. ' $((g_max_length_line/2)) "$g_color_gray1"
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
    m_setup_vim_packages 1 $p_flag_developer

}




function m_setup($p_input_options)
{
	
	return 0
}

function m_show_menu_core() 
{
	Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Green
	Write-Host "                                                      Menu de Opciones" -ForegroundColor Green
	Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
	Write-Host " (q) Salir del menu";
	Write-Host " (a) Configurar VIM/NeoVIM como IDE y re-crear enlaces simbolicos"
	Write-Host "----------------------------------------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
}

function show_menu() 
{
	Write-Host ""
	m_show_menu_core
	
	$l_continue= $true
	$l_read_option= ""
	while($l_continue)
	{
			Write-Host "Ingrese la opción (" -NoNewline
			Write-Host "no ingrese los ceros a la izquierda" -NoNewline -ForegroundColor DarkGray
			$l_read_option= Read-Host ")"
			switch ($l_read_option)
			{
				'a' {
					$l_continue= $false
					Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Green
					Write-Host ""
					m_setup 1
				}
				
				
				'q' {
					$l_continue= $false
					Write-Host "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor Green
					Write-Host ""
				}
				
				default {
					$l_continue= $true
					Write-Host "opción incorrecta"
					Write-Host "----------------------------------------------------------------------------------------------------------------------------------"	 -ForegroundColor DarkGray
				}
				
			}	
		
	}
	
	
}
	

$g_fix_fzf=0
if($args.count -ge 1) {
    if($args[0] -eq "1") {
        $g_fix_fzf=1
    }
}

show_menu

