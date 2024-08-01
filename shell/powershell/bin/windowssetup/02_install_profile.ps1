#------------------------------------------------------------------------------------------------
# Inicializacion
#------------------------------------------------------------------------------------------------

$g_max_length_line= 130

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
        'nvim-neotest/nvim-nio'=4
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
        'nvim-neotest/nvim-nio'= 2
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

$g_is_nodejs_installed= $true


#------------------------------------------------------------------------------------------------
# Funciones
#------------------------------------------------------------------------------------------------

function m_create_file_link($p_source_path, $p_source_filename, $p_target_link, $p_tag, $p_override_target_link) {

    
    $l_target_base = Split-Path -Parent $p_target_link
	$l_tmp= $null
	if(! (Test-Path "${l_target_base}")) {
		$l_tmp= New-Item -ItemType Directory -Force -Path "${l_target_base}"
    }
	
	#if(! (Test-Path "${p_source_path}")) {
    #    mkdir "$p_source_path"
    #}

    $l_source_fullfilename="${p_source_path}\${p_source_filename}"
	if(! (Test-Path "$p_target_link")) {
		cmd /c mklink "$p_target_link" "$l_source_fullfilename"
        Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha creado " -NoNewline
		Write-Host "(ruta real '${l_source_fullfilename}')" -ForegroundColor DarkGray
		return
	}
	
	$l_info= Get-Item "$p_target_link" | Select-Object LinkType, LinkTarget
	
    if ( $l_info.LinkType -eq "SymbolicLink" ) {
		if(! (Test-Path $l_info.LinkTarget)) {
			rm "$p_target_link"
			cmd /c mklink "$p_target_link" "$l_source_fullfilename"
			Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha re-creado debido a que el destino no existe " -NoNewline
			Write-Host "(ruta real '${l_source_fullfilename}')" -ForegroundColor DarkGray
		}
        else {
			if($p_override_target_link) {
				rm "$p_target_link"
				cmd /c mklink "$p_target_link" "$l_source_fullfilename"
				Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha re-creado " -NoNewline
				Write-Host "(ruta real '${l_source_fullfilename}')" -ForegroundColor DarkGray
			}
			else {				
				Write-Host "${p_tag}El enlace simbolico '${p_target_link}' ya existe " -NoNewline
				Write-Host "(ruta real '$($l_info.LinkTarget)')" -ForegroundColor DarkGray				
			}
		}
	}
    else {
        rm "$p_target_link"
		cmd /c mklink "$p_target_link" "$l_source_fullfilename"
        Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha creado " -NoNewline
		Write-Host "(ruta real '${l_source_fullfilename}')" -ForegroundColor DarkGray
    }

}



function m_create_folder_link($p_source_path, $p_target_link, $p_tag, $p_override_target_link) {

    
    $l_target_base = Split-Path -Parent $p_source_path
	$l_tmp= $null
    if(! (Test-Path "${l_target_base}")) {    
        $l_tmp= New-Item -ItemType Directory -Force -Path "${l_target_base}"
    }
	
	if(! (Test-Path "${p_target_link}")) {        
		cmd /c mklink /d "$p_target_link" "$p_source_path"
        Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha creado " -NoNewline
		Write-Host "(ruta real '${p_source_path}')" -ForegroundColor DarkGray
		return
    }

    $l_info= Get-Item "$p_target_link" | Select-Object LinkType, LinkTarget
	
	if ( $l_info.LinkType -eq "SymbolicLink" ) {
		if(! (Test-Path $l_info.LinkTarget)) {
			rmdir "$p_target_link"
			cmd /c mklink /d "$p_target_link" "$p_source_path"
			Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha re-creado debido a que el destino no existe " -NoNewline
			Write-Host "(ruta real '${l_source_fullfilename}')" -ForegroundColor DarkGray
		}
        else {
			if($p_override_target_link) {
				rmdir "$p_target_link"
				cmd /c mklink /d "$p_target_link" "$p_source_path"
				Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha re-creado " -NoNewline
				Write-Host "(ruta real '${p_source_path}')" -ForegroundColor DarkGray
			}
			else {				
				Write-Host "${p_tag}El enlace simbolico '${p_target_link}' ya existe " -NoNewline
				Write-Host "(ruta real '$($l_info.LinkTarget)')" -ForegroundColor DarkGray				
			}
		}
	}
    else {
        rmdir "$p_target_link"
		cmd /c mklink /d "$p_target_link" "$p_source_path"
        Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha creado " -NoNewline
		Write-Host "(ruta real '${p_source_path}')" -ForegroundColor DarkGray
    }

}



function m_setup_vim_packages($p_is_neovim, $p_flag_developer) {
	#1. Argumentos    

    #2. Ruta base donde se instala el plugins/paquete
    $l_tag="VIM"
    $l_current_scope=1
    $l_base_plugins="${env:USERPROFILE}\vimfiles\pack"
    if ($p_is_neovim)
	{
        $l_base_plugins="${env:LOCALAPPDATA}\nvim-data\site\pack"
        $l_current_scope=2
        $l_tag="NeoVIM"
    }

    #2. Crear las carpetas de basicas
    Write-Host "Instalando los paquetes usados por ${l_tag} en `"${l_base_plugins}`"..."

    $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}"
    $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}\themes\start"
    $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}\themes\opt"
    $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}\ui\start"
    $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}\ui\opt"
    if ($p_flag_developer)
	{
        $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}\typing\start"
        $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}\typing\opt"
        $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}\ide\start"
        $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}\ide\opt"
    }
   
    
    #4. Instalar el plugins que se instalan manualmente
    $l_base_path= ""
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

    foreach ($l_repo_git in $gd_repos_type.keys) {

        #4.1 Configurar el repositorio
        $l_repo_type= $gd_repos_type.Item("${l_repo_git}")
		$l_repo_scope= $gd_repos_scope.Item("${l_repo_git}")
		if(!$l_repo_scope) {
			$l_repo_scope= 3
		}
		
		$l_repo_name = Split-Path "$l_repo_git" -Leaf
		
		#Write-Host "Repo-Name '${l_repo_name}', Repo-Scope '${l_repo_scope}', Repo-Git '${l_repo_git}', Current-Scope '${l_current_scope}'"

        #Si el repositorio no esta habilitido para su scope, continuar con el siguiente
        if( $($l_repo_scope -band $l_current_scope) -ne $l_current_scope ) {
			#Write-Host "Repo-Name '${l_repo_name}', Repo-Scope '${l_repo_scope}', Repo-Git '${l_repo_git}', Current-Scope '${l_current_scope}'"
            continue
        }

        #4.2 Obtener la ruta base donde se clonara el paquete (todos los paquetes son opcionale, se inicia bajo configuraci├│n)
        $l_base_path=""
        switch ($l_repo_type) {
            1 {
                $l_base_path="${l_base_plugins}\themes\opt"
            }
            2 {
                $l_base_path="${l_base_plugins}\ui\opt"
            }
            3 {
                $l_base_path="${l_base_plugins}\typing\opt"
            }
            4 {
                $l_base_path="${l_base_plugins}\ide\opt"
            }
            default {
                                
                Write-Host "Paquete ${l_tag} (${l_repo_type}) `"${l_repo_git}`": No tiene tipo valido."
                continue
            }
        }

        #Si es un repositorio para developer no debe instalarse en el perfil basico
        if (!$p_flag_developer) {
			if( $l_repo_type -eq 3 || $l_repo_type -eq 4 ) {
				#Write-Host "Repo-Name '${l_repo_name}', Repo-Scope '${l_repo_scope}', Repo-Git '${l_repo_git}', Current-Scope '${l_current_scope}', Developer '${p_flag_developer}', Base-Path '${l_base_path}'"
				continue
			}
        }	
		
		#Write-Host "Repo-Name '${l_repo_name}', Repo-Scope '${l_repo_scope}', Repo-Git '${l_repo_git}', Current-Scope '${l_current_scope}', Developer '${p_flag_developer}', Base-Path '${l_base_path}'"
		
        #4.3 Validar si el paquete ya esta instalando
		if(Test-Path "${l_base_path}\${l_repo_name}\.git") {
             Write-Host "Paquete ${l_tag} (${l_repo_type}) `"${l_repo_git}`": Ya esta instalando"
             continue
        }

        #4.5 Instalando el paquete
        cd "${l_base_path}"
        Write-Host ""
	    Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
        if ($p_is_neovim) {
            Write-Host "NeoVIM> Plugin (${l_repo_type}) `"${l_repo_git}`": Se esta instalando"
        }
		else {
			Write-Host "   VIM> Plugin (${l_repo_type}) `"${l_repo_git}`": Se esta instalando"            
        }
	    Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray

        $l_aux=""
        $l_repo_branch= $gd_repos_branch.Item("${l_repo_git}")
		if (${l_repo_branch}) {
		    $l_aux= "--branch ${l_repo_branch}"
        }

        $l_repo_depth= $gd_repos_depth.Item("${l_repo_git}")
        if (${l_repo_depth}) {
            if (!${l_aux}) {
                $l_aux="--depth ${l_repo_depth}"
            }
			else {
                $l_aux="${l_aux} --depth ${l_repo_depth}"
            }
        }
		
		#Write-Host "Repo-Name '${l_repo_name}', Repo-Scope '${l_repo_scope}', Repo-Git '${l_repo_git}', Repo-Branch: '${l_repo_branch}', Repo-Depth: '${l_repo_depth}', Current-Scope '${l_current_scope}', Developer '${p_flag_developer}', Base-Path '${l_base_path}'"		

        if (${l_aux}) {
            Write-Host "Ejecutando `"git clone ${l_aux} https://github.com/${l_repo_git}.git`""
            Invoke-Expression "git clone ${l_aux} https://github.com/${l_repo_git}.git"
        }
		else {            
			Write-Host "Ejecutando `"git clone https://github.com/${l_repo_git}.git`""
            git clone https://github.com/${l_repo_git}.git
		}

        #Almacenando las ruta de documentacion a indexar
		if(Test-Path "${l_base_path}\${l_repo_name}\doc") {
        
            #Indexar la documentacion de plugins
            $la_doc_paths.Add("${l_base_path}\${l_repo_name}\doc")
            $la_doc_repos.Add("${l_repo_name}")

        }

        Write-Host ""

	}
	
	
    #4. Actualizar la documentación de VIM (Los plugins VIM que no tiene documentación, no requieren indexar)
	$l_n= $la_doc_paths.Count
	if( $l_n -gt 0 )
	{
		Write-Host ""
	    Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
		if(${p_is_neovim})
		{		
			Write-Host "- NeoVIM> Indexando la documentación de los plugin"
		}
		else
		{
			Write-Host "-    VIM> Indexando la documentación de los plugin"
		}
	    Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
		
		$l_j= 0
		for ($i=0; $i -lt $l_n; $i++) {
			
			$l_repo_path= $la_doc_paths[$i]
			$l_repo_name= $la_doc_repos[$i]
			$l_j= $i + 1
			
			Write-Host "(${l_j}/${l_n}) Indexando la documentación del plugin `"${l_repo_name}`" en `"${l_tag}`": `"helptags ${l_repo_path}`"\n"
			if(${p_is_neovim}) {
                nvim --headless -c "helptags ${l_repo_path}" -c qa
			}
			else {
                vim -u NONE -esc "helptags ${l_repo_path}" -c qa
			}

			
		}
	}
	

    #6. Inicializar los paquetes/plugin de VIM/NeoVIM que lo requieren.
    if (!$p_flag_developer) {
        Write-Host "Se ha instalando los plugin/paquetes de ${l_tag} como Editor."
        return 0
    }

    Write-Host "Se ha instalando los plugin/paquetes de ${l_tag} como Developer."
    if (!$g_is_nodejs_installed)  {

        Write-Host "Recomendaciones:"
        Write-Host "    > Si desea usar como editor (no cargar plugins de IDE), use: `"USE_EDITOR=1 vim`""
        if ($p_is_neovim -eq 0) {
            Write-Host "    > NeoVIM como developer por defecto usa el adaptador LSP y autocompletado nativo. No esta habilitado el uso de CoC"
        }
		else {
            Write-Host "    > VIM esta como developer pero NO puede usar CoC  (requiere que NodeJS este instalando)"
        }
        return 0

	}
        
    Write-Host "Los plugins del IDE CoC de ${l_tag} tiene componentes que requieren inicialización para su uso. Inicializando dichas componentes del plugins..."	

    #Instalando los parseadores de lenguaje de 'nvim-treesitter'
    if ($p_is_neovim) {

        #Requiere un compilador C/C++ y NodeJS: https://tree-sitter.github.io/tree-sitter/creating-parsers#installation
		#TODO Obtener la version del compilador C/C++
        $l_version="xxxx"
        if(! $l_version ) {
            Write-Host "  Instalando `"language parsers`" de TreeSitter `":TSInstall html css javascript jq json yaml xml toml typescript proto make sql bash`""
            nvim --headless -c  "TSInstall html css javascript jq json yaml xml toml typescript proto make sql bash" -c "qa"

            Write-Host "  Instalando `"language parsers`" de TreeSitter `":TSInstall java kotlin llvm lua rust swift c cpp go c_sharp`""
            nvim --headless -c "TSInstall java kotlin llvm lua rust swift c cpp go c_sharp" -c "qa"
        }
	}

    #Instalando extensiones basicos de CoC: Adaptador de LSP server basicos JS, Json, HTLML, CSS, Python, Bash
    Write-Host "  Instalando extensiones de CoC (Adaptador de LSP server basicos) `":CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh`""
    if ($p_is_neovim) {       
		${env:USE_COC}=1
		nvim --headless -c "CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh" -c "qa"
	}
    else {
        vim -esc "CocInstall coc-tsserver coc-json coc-html coc-css coc-pyrigh coc-sh" -c "qa"
    }

    #Instalando extensiones basicos de CoC: Motor de snippets 'UtilSnips'
    Write-Host "  Instalando extensiones de CoC (Motor de snippets `"UtilSnips`") `":CocInstall coc-ultisnips`" (no se esta usando el nativo de CoC)"
    if ($p_is_neovim) {        
		nvim --headless -c "CocInstall coc-ultisnips" -c "qa"
	}
    else {
        vim -esc "CocInstall coc-ultisnips" -c "qa"
    }

    #Actualizar las extensiones de CoC
    Write-Host "  Actualizando los extensiones existentes de CoC, ejecutando el comando `":CocUpdate`""
    if ($p_is_neovim) {
        nvim --headless -c "CocUpdate" -c "qa"
		${env:USE_COC}=0
	}
    else {        
		vim -esc "CocUpdate" -c "qa"
    }

    #Actualizando los gadgets de 'VimSpector'
    if (!$p_is_neovim) {
        Write-Host "  Actualizando los gadgets de `"VimSpector`", ejecutando el comando `":VimspectorUpdate`""
        vim -esc "VimspectorUpdate" -c "qa"
    }
	
	Write-Host ""
    Write-Host "Recomendaciones:"
    if (!$p_is_neovim) {

        Write-Host "    > Si desea usar como editor (no cargar plugins de IDE), use: `"`${env:USE_EDITOR}=1`" y luego `"vim`""
        Write-Host "    > Se recomienda que configure su IDE CoC segun su necesidad:"
	}
    else {

        Write-Host "  > Por defecto, se ejecuta el IDE vinculado al LSP nativo de NeoVIM."
        Write-Host "    > Si desea usar CoC, use: `"`${env:USE_COC}=1`" y luego `"nvim`""
        Write-Host "    > Si desea usar como editor (no cargar plugins de IDE), use: `"`${env:USE_EDITOR}=1`" y luego `"nvim`""

        Write-Host "  > Si usar como Developer con IDE CoC, se recomienda que lo configura segun su necesidad:"

    }

    Write-Host "        1> Instalar extensiones de COC segun su necesidad (Listar existentes `":CocList extensions`")"
    Write-Host "        2> Revisar la Configuracion de COC `":CocConfig`":"
    Write-Host "          2.1> El diganostico se enviara ALE (no se usara el integrado de CoC), revisar:"
    Write-Host "               { `"diagnostic.displayByAle`": true }"
    Write-Host "          2.2> El formateador de codigo 'Prettier' sera proveido por ALE (no se usara la extension 'coc-prettier')"
    Write-Host "               Si esta instalando esta extension, desintalarlo."


    return 0

}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
function m_config_nvim($p_flag_developer, $p_overwrite_ln_flag ) {

    #1. Argumentos    
    

    #2. Crear el subtitulo
    $l_title= ">> Configurando NeoVIM ("
    if($p_flag_developer) {
        $l_title= "${l_title} Modo developer"
    }
    else {
        $l_title= "${l_title} Modo editor"
    }

    if($p_overwrite_ln_flag) {
        $l_title= "${l_title}, Sobrescribiendo los enlaces simbolicos)"
    }
    else {
        $l_title= "${l_title}, Solo crando enlaces simbolicos si no existen)"
    }
    
    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue
    Write-Host "$l_title" -ForegroundColor Blue
    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue

    #Creando el directorio hijos si no existen	
	$l_tmp= New-Item -ItemType Directory -Force -Path "${env:LOCALAPPDATA}\nvim"	
    
    #2. Creando los enalces simbolicos
    $l_target_link= ""
    $l_source_path= ""
    $l_source_filename= ""

    #Configurar NeoVIM como IDE (Developer)
    if ($p_flag_developer) {


        $l_target_link="${env:LOCALAPPDATA}\nvim\init.vim"
        $l_source_path="${env:USERPROFILE}\.files\nvim"
        $l_source_filename="init_ide_windows.vim"
        m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

        $l_target_link="${env:LOCALAPPDATA}\nvim\coc-settings.json"
        $l_source_path="${env:USERPROFILE}\.files\nvim"
        $l_source_filename="coc-settings_windows.json"
        m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

        $l_target_link="${env:LOCALAPPDATA}\nvim\setting"
        $l_source_path="${env:USERPROFILE}\.files\vim\setting"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

        $l_target_link="${env:LOCALAPPDATA}\nvim\lua"
        $l_source_path="${env:USERPROFILE}\.files\nvim\lua"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

        
        #El codigo open\close asociado a los 'file types'
        $l_target_link="${env:LOCALAPPDATA}\nvim\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\nvim\ftplugin\commonide"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


        #Para el codigo open/close asociado a los 'file types' de CoC
        $l_target_link="${env:LOCALAPPDATA}\nvim\rte_cocide\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\nvim\ftplugin\cocide"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


        #Para el codigo open/close asociado a los 'file types' que no sean CoC
        $l_target_link="${env:LOCALAPPDATA}\nvim\rte_nativeide\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\nvim\ftplugin\nativeide"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag
		
	}
    #Configurar NeoVIM como Editor
    else {

        $l_target_link="${env:LOCALAPPDATA}\nvim\init.vim"
        $l_source_path="${env:USERPROFILE}\.files\nvim"
        $l_source_filename="init_basic_windows.vim"
        m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

        $l_target_link="${env:LOCALAPPDATA}\nvim\setting"
        $l_source_path="${env:USERPROFILE}\.files\vim\setting"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

        
        $l_target_link="${env:LOCALAPPDATA}\nvim\lua"
        $l_source_path="${env:USERPROFILE}\.files\nvim\lua"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


        #El codigo open\close asociado a los 'file types' como Editor
        $l_target_link="${env:LOCALAPPDATA}\nvim\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\nvim\ftplugin\editor"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


    }

    #6. Instalando paquetes
    $l_status= m_setup_vim_packages $true $p_flag_developer


}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
#  2> Sobrescribir los enlaces simbolicos
function m_config_vim($p_flag_developer, $p_overwrite_ln_flag) {

    #1. Argumentos    
    

    #2. Crear el subtitulo
    $l_title= ">> Configurando VIM ("
    if($p_flag_developer) {
        $l_title= "${l_title} Modo developer"
    }
    else {
        $l_title= "${l_title} Modo editor"
    }

    if($p_overwrite_ln_flag) {
        $l_title= "${l_title}, Sobrescribiendo los enlaces simbolicos)"
    }
    else {
        $l_title= "${l_title}, Solo crando enlaces simbolicos si no existen)"
    }
    
    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue
    Write-Host "$l_title" -ForegroundColor Blue
    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue

    #Creando el directorio hijos si no existen	
	$l_tmp= New-Item -ItemType Directory -Force -Path "${env:USERPROFILE}\vimfiles"	

    #3. Crear los enlaces simbolicos de VIM
    $l_target_link= ""
    $l_source_path= ""
    $l_source_filename= ""


    #Configurar VIM como IDE (Developer)
    if ($p_flag_developer) {

        #Creando enlaces simbolicos
        $l_target_link="${env:USERPROFILE}\.vimrc"
        $l_source_path="${env:USERPROFILE}\.files\vim"
        $l_source_filename="vimrc_ide_windows.vim"
        m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag
		
        $l_target_link="${env:USERPROFILE}\vimfiles\coc-settings.json"
        $l_source_path="${env:USERPROFILE}\.files\vim"
        $l_source_filename="coc-settings_windows.json"
        m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag

        $l_target_link="${env:USERPROFILE}\vimfiles\setting"
        $l_source_path="${env:USERPROFILE}\.files\vim\setting"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag

        
        $l_target_link="${env:USERPROFILE}\vimfiles\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\vim\ftplugin\cocide"
        m_create_folder_link "$l_source_path" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag


	}
    #Configurar VIM como Editor basico
    else {

        $l_target_link="${env:USERPROFILE}\.vimrc"
        $l_source_path="${env:USERPROFILE}\.files\vim"
        $l_source_filename="vimrc_basic_windows.vim"
        m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag

        $l_target_link="${env:USERPROFILE}\vimfiles\setting"
        $l_source_path="${env:USERPROFILE}\.files\vim\setting"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


        $l_target_link="${env:USERPROFILE}\vimfiles\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\vim\ftplugin\editor"
        m_create_folder_link "$l_source_path" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag


    }

    #Instalar los plugins
    $l_status= m_setup_vim_packages $false $p_flag_developer

}


# Parametros:
# > Opcion ingresada por el usuario.
function m_setup_profile($l_overwrite_ln_flag) {
	
    #1. Argumentos
    
    #Esta habilitado la creacion de enlaces simbolicos del perfil?    
    #Se puede recrear los enlaces simbolicos en caso existir?
    

    #2. Mostrar el titulo 
    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue
	$l_title=""
    if ($l_overwrite_ln_flag) {
        $l_title= ">> Creando los senlaces simbolicos del perfil (sobrescribir lo existente)"
	}
    else {
        $l_title= ">> Creando los enlaces simbolicos del perfil (solo crar si no existe)"
    }
	Write-Host "$l_title" -ForegroundColor Blue
    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue

    

    #3. Creando enlaces simbolico dependientes del tipo de distribución Linux

    #Si es Linux WSL
    $l_target_link= ""
    $l_source_path= ""
    $l_source_filename= ""

    #Archivo de colores de la terminal usado por comandos basicos
    #$l_target_link="${HOME}\.dircolors"
    #$l_source_path="${HOME}\.files\etc\dircolors"
    #$l_source_filename='dircolors_wls_debian1.conf'
    #m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Archivo de configuracion de Git
    $l_target_link="${env:USERPROFILE}\.gitconfig"
    $l_source_path="${env:USERPROFILE}\.files\etc\git"
	$l_source_filename='root_gitconfig_windows.toml'
    m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

	if(! (Test-Path "${env:USERPROFILE}\.config\git")) {
		New-Item -ItemType Directory -Force -Path "${env:USERPROFILE}\.config\git"
    }
	
    if(! (Test-Path "${env:USERPROFILE}\.config\git\main.toml" )) {
		Write-Host "            > Creando el archivo '~\.config\git\main.toml' ..."
        Copy-Item -Path "${env:USERPROFILE}\.files\etc\git\template_main_gitconfig_windows.toml" -Destination "${env:USERPROFILE}\.config\git\main.toml"
        Write-Host "            > Creando el archivo '~\.config\git\work_uc.toml' ..."
        Copy-Item -Path "${env:USERPROFILE}\.files\etc\git\template_work_gitconfig_windows.toml" -Destination "${env:USERPROFILE}\.config\git\work_uc.toml"
        
        Write-Host "            > Edite '~\.config\git\main.toml' y '~\.config\git\work_uc.toml' si desea crear modificar las opciones de '~/.gitignore'."
	}
    else {
        Write-Host "            > Edite '~\.config\git\main.toml' y '~\.config\git\work_uc.toml' si desea crear modificar las opciones de '~/.gitignore'."
    }

    #Archivo de configuracion de SSH
    $l_target_link="${env:USERPROFILE}\.ssh\config"
    $l_source_path="${env:USERPROFILE}\.files\etc\ssh\template_windows.conf"
	
	$l_info= Get-Item "$l_target_link" | Select-Object LinkType, LinkTarget 2> $null
    
    if(! (Test-Path "$l_profile_path")) {
		if ( $l_info -and ($l_info.LinkType -eq "SymbolicLink") ) {
            Write-Host "General     > Remplazado el enlace simbolico '~\.ssh\config' por un archivo ..."
			Remove-Item -Path "$l_target_link"
            Copy-Item -Path "$l_source_path" -Destination "$l_target_link"
        }
        else {
            Write-Host "General     > Creando el archivo '~\.ssh\config' ..."
            Copy-Item -Path "$l_source_path" -Destination "$l_target_link"
		}
	}
    else {
	    if ( $l_info -and ($l_info.LinkType -eq "SymbolicLink") ) {
            Write-Host "General     > Remplazado el enlace simbolico '~\.ssh\config' por un archivo ..."
			Remove-Item -Path "$l_target_link"
            Copy-Item -Path "$l_source_path" -Destination "$l_target_link"
        }
        else {
            Write-Host "General     > El archivo de configuración '~\.ssh\config' ya existe ..."
        }
    }


    #Archivos de configuracion de PowerShell
	$document_path= [Environment]::GetFolderPath("mydocuments")
    $l_target_link="${document_path}\PowerShell\Microsoft.PowerShell_profile.ps1"
    $l_source_path="${env:USERPROFILE}\.files\shell\powershell\login\windowsprofile"
	$l_source_filename='windows_x64.ps1'
    m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag
	

	$l_target_link="${document_path}\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    $l_source_path="${env:USERPROFILE}\.files\shell\powershell\login\windowsprofile"
	$l_source_filename='legacy_x64.ps1'
    m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

    #Creando archivo de configuracion para Wezterm
    $l_target_link="${env:USERPROFILE}\.config\wezterm\wezterm.lua"
    $l_source_path="${env:USERPROFILE}\.files\wezterm"
	$l_source_filename='wezterm_windows1.lua'
    m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Creando el profile del interprete shell
    #$l_target_link="${HOME}\.bashrc"
    #$l_source_path="${HOME}\.files\shell\bash\profile"
	#$l_source_filename='debian_aarch64_local.bash'    
    #m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #4. Creando enlaces simbolico independiente del tipo de distribución Linux

    #Crear el enlace de TMUX
    #$l_target_link="${HOME}\.tmux.conf"
    #$l_source_path="${HOME}\.files\tmux"
    #$l_source_filename='tmux.conf'
    #m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

    #Configuracion de un CLI de alto nivel del 'Container Runtime' 'ContainerD': nerdctl
    #$l_target_link="${HOME}\.config\nerdctl\nerdctl.toml"
    #$l_source_path="${HOME}\.files\config\nerdctl"
    #$l_source_filename='default_config.toml'
    #m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Configuracion principal de un 'Container Runtime'\CLI de alto nivel (en modo 'rootless'): Podman
    #$l_target_link="${HOME}\.config\containers\containers.conf"
    #$l_source_path="${HOME}\.files\config\podman"
    #$l_source_filename='default_config.toml'
    #m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

    #Configuracion de los registros de imagenes de un 'Container Runtime'\CLI de alto nivel (en modo 'rootless'): Podman
    #$l_target_link="${HOME}\.config\containers\registries.conf"
    #$l_source_path="${HOME}\.files\config\podman"
    #$l_source_filename='default_registries.toml'
    #m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Configuracion de un 'Container Runtime' 'ContainerD' (en modo 'rootless')
    #$l_target_link="${HOME}\.config\containerd\config.toml"
    #$l_source_path="${HOME}\.files\config\containerd"
    #$l_source_filename='default_config.toml'
    #m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Configuracion del backend de compilacion de imagenes 'BuildKit' (en modo 'rootless')
    #$l_target_link="${HOME}\.config\buildkit\buildkitd.toml"
    #$l_source_path="${HOME}\.files\config\buildkit"
    #$l_source_filename='default_config.toml'
    #m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Configuracion por defecto para un Cluster de Kubernates
    #$l_target_link="${HOME}\.kube\config"
    #$l_source_path="${HOME}\.files\config\kubectl"
    #$l_source_filename='default_config.yaml'
    #m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

    #5. Instalar el modulo PSFzf

    #Buscar si el modulo esta instado
    Write-Host ""
    $mod= Get-InstalledModule PSFzf 2> $null
    if($mod) {
        Write-Host "El modulo 'PSFzf' $($mod.Version) esta instalado."
        Write-Host "Intentando actualizar el modulo 'PSFzf' ..."
        Update-Module -Name PSFzf
    }
    else {
        Write-Host "Instalando el modulo 'PSFzf' ..."
        Install-Module -Name PSFzf
    }

}



function m_setup($p_input_options) {
	
	$l_overwrite_ln_flag= $p_input_options
	
	#Instalar VIM como Developer
	m_config_vim $true $l_overwrite_ln_flag	
	Write-Host ""
	
	#Instalar NeoVIM como Developer
	m_config_nvim $true $l_overwrite_ln_flag
	Write-Host ""
	
	#Configurar el profile
	m_setup_profile $l_overwrite_ln_flag	
	
}

function m_show_menu_core() {
	
	Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
	Write-Host "                                                      Menu de Opciones" -ForegroundColor Green
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
	Write-Host " (q) Salir del menu";
	Write-Host " (a) Configurar VIM/NeoVIM como IDE y crear enlaces simbolicos si no existen"
	Write-Host " (b) Configurar VIM/NeoVIM como IDE y re-crear enlaces simbolicos (aun si existe)"
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
}

function show_menu() {
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
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $false
				}
				
				'b' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $true
				}
				
				
				'q' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
				}
				
				default {
					$l_continue= $true
					Write-Host "opción incorrecta"
	                Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
				}
				
			}	
		
	}
	
	
}



#------------------------------------------------------------------------------------------------
# Main Code
#------------------------------------------------------------------------------------------------

#Procesar los argumentos
$g_fix_fzf=0
if($args.count -ge 1) {
    if($args[0] -eq "1") {
        $g_fix_fzf=1
    }
}


# Folder base donde se almacena el programas, comando y afines usados por Windows.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es un valor valido, se asignara "C:\cli"
# - En este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_win_base_path}/prgs"     : subfolder donde se almacena los subfolder de los programas.
#     > "${g_win_base_path}/cmds/bin" : subfolder donde se almacena los comandos.
#     > "${g_win_base_path}/cmds/man" : subfolder donde se almacena los archivos de ayuda man1 del comando.
#     > "${g_win_base_path}/cmds/doc" : subfolder donde se almacena documentacion del comando.
#     > "${g_win_base_path}/cmds/etc" : subfolder donde se almacena archivos adicionales del comando.
#     > "${g_win_base_path}/fonts" : subfolder donde se almacena los archivos de fuentes tipograficas.
$g_win_base_path=''

# Folder base donde se almacena data temporal que sera eliminado automaticamente despues completar la configuración.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es valido, la funcion "get_temp_path" asignara segun orden de prioridad a '$env:TEMP'.
$g_temp_path=''

# Usado solo durante la instalación. Define si se instala solo la ultima version de un programa.
#Por defecto es 1 (considerado 'false'). Solo si su valor es '0', es considera 'true'.
$g_setup_only_last_version=1

# Cargar la información:
if(Test-Path "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/config.ps1") {

    . "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/config.ps1"

    #Fix the bad entry values
    if( "$g_setup_only_last_version" -eq "0" ) {
        $g_setup_only_last_version=0
    }
    else {
        $g_setup_only_last_version=1
    }

}

# Valor por defecto del folder base de  programas, comando y afines usados por Windows.
if((-not ${g_win_base_path}) -and (Test-Path "$g_win_base_path")) {
    $g_win_base_path='C:\cli'
}

# Ruta del folder base donde estan los subfolderes del los programas (1 o mas comandos y otros archivos).
if((-not ${g_temp_path}) -and (Test-Path "$g_temp_path")) {
    $g_temp_path= 'C:\Windows\Temp'
}


show_menu

