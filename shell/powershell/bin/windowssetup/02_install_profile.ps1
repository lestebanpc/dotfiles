#------------------------------------------------------------------------------------------------
# Inicializacion
#------------------------------------------------------------------------------------------------

$g_max_length_line= 130

$g_use_sudo= $false

# Grupo de plugins de VIM/NeoVIM :
# (00) Grupo Basic > Themes             - Temas
# (01) Grupo Basic > Core               - StatusLine, TabLine, FZF, TMUX utilities, Files Tree
# (02) Grupo Basic > Extended           - Highlighting Sintax, Autocompletion para linea de comandos.
# (03) Grupo IDE > Utils                - Libreries, Typing utilities.
# (04) Grupo IDE > Development > Common - Plugin comunes de soporte independiente de tipo LSP usado (nativa o CoC).
# (05) Grupo IDE > Development > Native - LSP, Snippets, Compeletion  ... usando la implementacion nativa.
# (06) Grupo IDE > Development > CoC    - LSP, Snippets, Completion ... usando CoC.
# (07) Grupo IDE > Testing              - Unit Testing y Debugging.
# (08) Grupo IDE > Extended > Common    - Plugin de tools independiente del tipo de LSP usado (nativa o CoC).
# (09) Grupo IDE > Extended > Native    - Tools: Git, Rest Client, AI Completion/Chatbot, AI Agent, etc.
# (10) Grupo IDE > Extended > CoC       - Tools: Git, Rest Client, AI Completin/Chatbot, AI Agent, etc.
$gd_repos_type= @{
        'morhetz/gruvbox' = 0
        'joshdick/onedark.vim' = 0
        'vim-airline/vim-airline' = 1
        'vim-airline/vim-airline-themes' = 1
        'preservim/nerdtree' = 1
        'ryanoasis/vim-devicons' = 1
        'preservim/vimux' = 1
        'christoomey/vim-tmux-navigator' = 1
        'junegunn/fzf' = 1
        'junegunn/fzf.vim' = 1
        'ibhagwan/fzf-lua' = 1
        'girishji/vimsuggest' = 2
        'tpope/vim-surround' = 3
        'mg979/vim-visual-multi' = 3
        'mattn/emmet-vim' = 3
        'dense-analysis/ale' = 4
        'liuchengxu/vista.vim' = 4
        'neoclide/coc.nvim' = 6
        'antoinemadec/coc-fzf' = 6
        'SirVer/ultisnips' = 6
        'OmniSharp/omnisharp-vim' = 6
        'honza/vim-snippets' = 6
        'puremourning/vimspector' = 7
        'folke/tokyonight.nvim' = 0
        'catppuccin/nvim' = 0
        'kyazdani42/nvim-web-devicons' = 1
        'nvim-lualine/lualine.nvim' = 1
        'akinsho/bufferline.nvim' = 1
        'nvim-tree/nvim-tree.lua' = 1
        'nvim-treesitter/nvim-treesitter' = 2
        'nvim-treesitter/nvim-treesitter-textobjects' = 2
        'hrsh7th/nvim-cmp' = 2
        'hrsh7th/cmp-buffer' = 2
        'hrsh7th/cmp-path' = 2
        'hrsh7th/cmp-cmdline' = 2
        'nvim-lua/plenary.nvim' = 3
        'nvim-treesitter/nvim-treesitter-context' = 4
        'stevearc/aerial.nvim' = 4
        'neovim/nvim-lspconfig' = 5
        'ray-x/lsp_signature.nvim' = 5
        'hrsh7th/cmp-nvim-lsp' = 5
        'L3MON4D3/LuaSnip' = 5
        'rafamadriz/friendly-snippets' = 5
        'saadparwaiz1/cmp_luasnip' = 5
        'b0o/SchemaStore.nvim' = 5
        'kosayoda/nvim-lightbulb' = 5
        'doxnit/cmp-luasnip-choice' = 5
        'mfussenegger/nvim-jdtls' = 5
        'mfussenegger/nvim-dap' = 7
        'rcarriga/nvim-dap-ui' = 7
        'theHamsta/nvim-dap-virtual-text' = 7
        'nvim-neotest/nvim-nio' = 7
        'vim-test/vim-test' = 7
        'mistweaverco/kulala.nvim' = 8
        'lewis6991/gitsigns.nvim' = 8
        'sindrets/diffview.nvim' = 8
        'zbirenbaum/copilot.lua' = 9
        'zbirenbaum/copilot-cmp' = 9
        'stevearc/dressing.nvim' = 9
        'MunifTanjim/nui.nvim' = 9
        'MeanderingProgrammer/render-markdown.nvim' = 9
        'HakonHarnes/img-clip.nvim' = 9
        'yetone/avante.nvim' = 9
        'github/copilot.vim' = 10
    }

# Repositorios Git - para VIM/NeoVIM. Por defecto es 3 (para ambos)
#  1 - Para VIM
#  2 - Para NeoVIM
$gd_repos_scope= @{
        'morhetz/gruvbox' = 1
        'joshdick/onedark.vim' = 1
        'vim-airline/vim-airline' = 1
        'vim-airline/vim-airline-themes' = 1
        'ryanoasis/vim-devicons' = 1
        'preservim/nerdtree' = 1
        'girishji/vimsuggest' = 1
        'liuchengxu/vista.vim' = 1
        'puremourning/vimspector' = 1
        'folke/tokyonight.nvim' = 2
        'catppuccin/nvim' = 2
        'kyazdani42/nvim-web-devicons' = 2
        'ibhagwan/fzf-lua' = 2
        'nvim-lualine/lualine.nvim' = 2
        'akinsho/bufferline.nvim' = 2
        'nvim-lua/plenary.nvim' = 2
        'nvim-tree/nvim-tree.lua' = 2
        'stevearc/aerial.nvim' = 2
        'nvim-treesitter/nvim-treesitter' = 2
        'nvim-treesitter/nvim-treesitter-textobjects' = 2
        'nvim-treesitter/nvim-treesitter-context' = 2
        'mistweaverco/kulala.nvim' = 2
        'sindrets/diffview.nvim' = 2
        'lewis6991/gitsigns.nvim' = 2
        'neovim/nvim-lspconfig' = 2
        'hrsh7th/nvim-cmp' = 2
        'hrsh7th/cmp-nvim-lsp' = 2
        'hrsh7th/cmp-buffer' = 2
        'hrsh7th/cmp-path' = 2
        'hrsh7th/cmp-cmdline' = 2
        'ray-x/lsp_signature.nvim' = 2
        'L3MON4D3/LuaSnip' = 2
        'rafamadriz/friendly-snippets' = 2
        'saadparwaiz1/cmp_luasnip' = 2
        'doxnit/cmp-luasnip-choice' = 2
        'b0o/SchemaStore.nvim' = 2
        'kosayoda/nvim-lightbulb' = 2
        'mfussenegger/nvim-dap' = 2
        'theHamsta/nvim-dap-virtual-text' = 2
        'rcarriga/nvim-dap-ui' = 2
        'nvim-neotest/nvim-nio' = 2
        'mfussenegger/nvim-jdtls' = 2
        'zbirenbaum/copilot.lua' = 2
        'zbirenbaum/copilot-cmp' = 2
        'stevearc/dressing.nvim' = 2
        'MunifTanjim/nui.nvim' = 2
        'MeanderingProgrammer/render-markdown.nvim' = 2
        'HakonHarnes/img-clip.nvim' = 2
        'yetone/avante.nvim' = 2
    }


# Repositorios Git - Branch donde esta el plugin no es el por defecto
$gd_repos_branch= @{
        'neoclide/coc.nvim' = 'release'
    }


# Repositorios Git que tiene submodulos y requieren obtener/actualizar en conjunto al modulo principal
# > Por defecto no se tiene submodulos (valor 0)
# > Valores :
#   (0) El repositorio solo tiene un modulo principal y no tiene submodulos.
#   (1) El repositorio tiene un modulo principal y submodulos de 1er nivel.
#   (2) El repositorio tiene un modulo principal y submodulos de varios niveles.
$gd_repos_with_submmodules= @{
        'mistweaverco/kulala.nvim' = 1
    }


# Permite definir el nombre del folder donde se guardaran los plugins segun el grupo al que pertenecen.
$ga_group_plugin_folder= @(
    "basic_themes"
    "basic_core"
    "basic_extended"
    "ide_utils"
    "ide_dev_common"
    "ide_dev_native"
    "ide_dev_coc"
    "ide_testing"
    "ide_ext_common"
    "ide_ext_native"
    "ide_ext_coc"
    )


# Importando funciones de utilidad
. "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/lib/setup_profile_utility.ps1"


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

        if ($g_use_sudo) {
		    sudo cmd /c mklink "$p_target_link" "$l_source_fullfilename"
        }
        else {
		    cmd /c mklink "$p_target_link" "$l_source_fullfilename"
        }

        Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha creado " -NoNewline
		Write-Host "(ruta real '${l_source_fullfilename}')" -ForegroundColor DarkGray
		return

	}

	$l_info= Get-Item "$p_target_link" | Select-Object LinkType, LinkTarget

    if ( $l_info.LinkType -eq "SymbolicLink" ) {
		if(! (Test-Path $l_info.LinkTarget)) {

			rm "$p_target_link"
            if ($g_use_sudo) {
			    sudo cmd /c mklink "$p_target_link" "$l_source_fullfilename"
            }
            else {
			    cmd /c mklink "$p_target_link" "$l_source_fullfilename"
            }

			Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha re-creado debido a que el destino no existe " -NoNewline
			Write-Host "(ruta real '${l_source_fullfilename}')" -ForegroundColor DarkGray

		}
        else {
			if($p_override_target_link) {

				rm "$p_target_link"
                if ($g_use_sudo) {
				    sudo cmd /c mklink "$p_target_link" "$l_source_fullfilename"
                }
                else {
				    cmd /c mklink "$p_target_link" "$l_source_fullfilename"
                }
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
        if ($g_use_sudo) {
		    sudo cmd /c mklink "$p_target_link" "$l_source_fullfilename"
        }
        else {
		    cmd /c mklink "$p_target_link" "$l_source_fullfilename"
        }
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

        if ($g_use_sudo) {
		    sudo cmd /c mklink /d "$p_target_link" "$p_source_path"
        }
        else {
		    cmd /c mklink /d "$p_target_link" "$p_source_path"
        }

        Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha creado " -NoNewline
		Write-Host "(ruta real '${p_source_path}')" -ForegroundColor DarkGray
		return

    }

    $l_info= Get-Item "$p_target_link" | Select-Object LinkType, LinkTarget

	if ( $l_info.LinkType -eq "SymbolicLink" ) {
		if(! (Test-Path $l_info.LinkTarget)) {

			rmdir "$p_target_link"
            if ($g_use_sudo) {
			    sudo cmd /c mklink /d "$p_target_link" "$p_source_path"
            }
            else {
			    cmd /c mklink /d "$p_target_link" "$p_source_path"
            }

			Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha re-creado debido a que el destino no existe " -NoNewline
			Write-Host "(ruta real '${l_source_fullfilename}')" -ForegroundColor DarkGray

		}
        else {

			if($p_override_target_link) {
				rmdir "$p_target_link"
                if ($g_use_sudo) {
				    sudo cmd /c mklink /d "$p_target_link" "$p_source_path"
                }
                else {
				    cmd /c mklink /d "$p_target_link" "$p_source_path"
                }

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
        if ($g_use_sudo) {
		    sudo cmd /c mklink /d "$p_target_link" "$p_source_path"
        }
        else {
		    cmd /c mklink /d "$p_target_link" "$p_source_path"
        }

        Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha creado " -NoNewline
		Write-Host "(ruta real '${p_source_path}')" -ForegroundColor DarkGray

    }

}



function m_setup_vim_packages($p_is_neovim, $p_flag_developer, $p_index_documentation) {

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

    #3. Crear las carpetas de basicas
    Write-Host "Instalando los paquetes usados por ${l_tag} en `"${l_base_plugins}`"..."

    $l_tmp= $null
    $l_group_folder = $null
    for ($i=0; $i -lt $ga_group_plugin_folder.Count; $i++) {

        $l_group_folder= $ga_group_plugin_folder[$i]
        if (-not $l_group_folder) {
            continue
        }

        if (-not $p_flag_developer -and $i -ge 3) {
            #Si no es developer, no se crean los grupos de plugins de IDE
            break
        }

        # Crear la carpeta base del grupo de plugins
	    if(! (Test-Path "${l_base_plugins}\${l_group_folder}\opt")) {
            Write-Host "Creando el folder '${l_base_plugins}\${l_group_folder}\opt'."
            $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}\${l_group_folder}\opt"
        }

	    if(! (Test-Path "${l_base_plugins}\${l_group_folder}\start")) {
            Write-Host "Creando el folder '${l_base_plugins}\${l_group_folder}\start'."
            $l_tmp= New-Item -ItemType Directory -Force -Path "${l_base_plugins}\${l_group_folder}\start"
        }
    }


    #4. Instalar el plugins que se instalan manualmente
    $l_base_path= ""
    $l_repo_name= ""
    $l_repo_type=1
    $l_repo_branch= ""
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


        #4.2 Obtener la ruta base donde se clonara el paquete (todos los paquetes son opcionale, se inicia bajo configuracion)
        $l_group_folder= $null
        if ($l_repo_type -ge 0 -and $l_repo_type -lt $ga_group_plugin_folder.Count) {
            $l_group_folder=$ga_group_plugin_folder[$l_repo_type]
        }

        if($null -eq $l_group_folder) {
            Write-Host "Paquete ${l_tag} (${l_repo_type}) `"${l_repo_git}`": No tiene tipo valido."
            continue
        }

        $l_base_path= "${l_base_plugins}\${l_group_folder}\opt"

        #Si es un repositorio para developer no debe instalarse en el perfil basico
        if (-not $p_flag_developer -and $l_repo_type -ge 3) {
			#Write-Host "Repo-Name '${l_repo_name}', Repo-Scope '${l_repo_scope}', Repo-Git '${l_repo_git}', Current-Scope '${l_current_scope}', Developer '${p_flag_developer}', Base-Path '${l_base_path}'"
			continue
        }
		#Write-Host "Repo-Name '${l_repo_name}', Repo-Scope '${l_repo_scope}', Repo-Git '${l_repo_git}', Current-Scope '${l_current_scope}', Developer '${p_flag_developer}', Base-Path '${l_base_path}'"


        #4.3 Validar si el paquete ya esta instalando
		if(Test-Path "${l_base_path}\${l_repo_name}\.git") {
             Write-Host "Paquete ${l_tag} (${l_repo_type}) `"${l_repo_git}`": Ya esta instalando"
             continue
        }


        #4.5 Instalando el paquete
        Set-Location "${l_base_path}"

        Write-Host ""
	    Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
        if ($p_is_neovim) {
            Write-Host "NeoVIM> Plugin (${l_repo_type}) `"${l_repo_git}`": Se esta instalando"
        }
		else {
			Write-Host "   VIM> Plugin (${l_repo_type}) `"${l_repo_git}`": Se esta instalando"
        }
	    Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray


        #Siempre realizar una clonacion superficial (obtener solo el ultimo commit)
        $l_aux="--depth 1"

        #Si el repositorio tiene submodulos, se debe clonar con los submodulos
        $l_repo_with_submodules= $gd_repos_with_submmodules.Item("${l_repo_git}")
        if($null -ne $l_repo_with_submodules -and ($l_repo_with_submodules -eq 1 -or $l_repo_with_submodules -eq 2)) {

            # Clona los submodulos definidos en '.gitmodules' y lo hace de manera superficial
            $l_aux="${l_aux} --recurse-submodules --shallow-submodules"

        }

        # La rama a clonar
        $l_repo_branch= $gd_repos_branch.Item("${l_repo_git}")
		if ($null -ne ${l_repo_branch}) {
		    $l_aux= "${l_aux} --branch ${l_repo_branch}"
        }


        # Clonar la rama
		#Write-Host "Repo-Name '${l_repo_name}', Repo-Scope '${l_repo_scope}', Repo-Git '${l_repo_git}', Repo-Branch: '${l_repo_branch}', Repo-Depth: '${l_repo_depth}', Current-Scope '${l_current_scope}', Developer '${p_flag_developer}', Base-Path '${l_base_path}'"

        Write-Host "Ejecutando `"git clone ${l_aux} https://github.com/${l_repo_git}.git`""
        Invoke-Expression "git clone ${l_aux} https://github.com/${l_repo_git}.git"
        #git clone https://github.com/${l_repo_git}.git

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
	if( $l_n -gt 0 -and $p_index_documentation )
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


    if (!$p_flag_developer) {
        Write-Host "Se ha instalado los plugin/paquetes de ${l_tag} como Editor."
        return 0
    }

    Write-Host "Se ha instalado los plugin/paquetes de ${l_tag} como Developer."

    #6. Mostrar la informacion de lo instalado
    show_vim_config_report $p_is_neovim $p_flag_developer

    return 0

}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
function m_config_nvim($p_flag_developer, $p_overwrite_ln_flag, $p_index_documentation) {

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
        $l_source_filename="init_ide.vim"
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


        #Creando la carpeta base para los metadata de los proyecto usados por el LSP JDTLS
    	if(! (Test-Path "${env:APPDATA}\eclipse\jdtls")) {
	    	New-Item -ItemType Directory -Force -Path "${env:APPDATA}\eclipse\jdtls"
        }



	}
    #Configurar NeoVIM como Editor
    else {

        $l_target_link="${env:LOCALAPPDATA}\nvim\init.vim"
        $l_source_path="${env:USERPROFILE}\.files\nvim"
        $l_source_filename="init_editor.vim"
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
    $l_status= m_setup_vim_packages $true $p_flag_developer $p_index_documentation


}


# Parametros:
#  1> Flag configurar como Developer (si es '0')
#  2> Sobrescribir los enlaces simbolicos
function m_config_vim($p_flag_developer, $p_overwrite_ln_flag, $p_index_documentation) {

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
        $l_source_filename="vimrc_ide.vim"
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
        $l_source_filename="vimrc_editor.vim"
        m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag

        $l_target_link="${env:USERPROFILE}\vimfiles\setting"
        $l_source_path="${env:USERPROFILE}\.files\vim\setting"
        m_create_folder_link "$l_source_path" "$l_target_link" "NeoVIM (IDE)> " $l_overwrite_ln_flag


        $l_target_link="${env:USERPROFILE}\vimfiles\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\vim\ftplugin\editor"
        m_create_folder_link "$l_source_path" "$l_target_link" "VIM    (IDE)> " $l_overwrite_ln_flag


    }

    #Instalar los plugins
    $l_status= m_setup_vim_packages $false $p_flag_developer $p_index_documentation

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

    #TODO this variable is null
    #$g_win_base_path='C:\apps'

    #Si es Linux WSL
    $l_target_link= ""
    $l_source_path= ""
    $l_source_filename= ""


    #Archivo de configuracion de Git
    $l_target_link="${env:USERPROFILE}\.gitconfig"
    $l_source_path="${env:USERPROFILE}\.files\etc\git"
	$l_source_filename='gitconfig_win.toml'
    m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

	if(! (Test-Path "${env:USERPROFILE}\.config\git")) {
		New-Item -ItemType Directory -Force -Path "${env:USERPROFILE}\.config\git"
    }

    if(! (Test-Path "${env:USERPROFILE}\.config\git\main.toml" )) {
		Write-Host "            > Creando el archivo '~\.config\git\user_main.toml' ..."
        Copy-Item -Path "${env:USERPROFILE}\.files\etc\git\user_main_template_win.toml" -Destination "${env:USERPROFILE}\.config\git\user_main.toml"
        Write-Host "            > Creando el archivo '~\.config\git\user_mywork.toml' ..."
        Copy-Item -Path "${env:USERPROFILE}\.files\etc\git\user_work_template_win.toml" -Destination "${env:USERPROFILE}\.config\git\user_mywork.toml"

        Write-Host "            > Edite '~\.config\git\user_main.toml' y '~\.config\git\user_mywork.toml' si desea crear modificar las opciones de '~/.gitignore'."
	}
    else {
        Write-Host "            > Edite '~\.config\git\user_main.toml' y '~\.config\git\user_mywork.toml' si desea crear modificar las opciones de '~/.gitignore'."
    }

    #Archivo de configuracion de SSH
    $l_target_link="${env:USERPROFILE}\.ssh\config"
    $l_source_path="${env:USERPROFILE}\.files\etc\ssh\template_windows_withpublickey.conf"

	if(! (Test-Path "${env:USERPROFILE}\.ssh")) {
		New-Item -ItemType Directory -Force -Path "${env:USERPROFILE}\.ssh"
    }

	$l_info= Get-Item "$l_target_link" | Select-Object LinkType, LinkTarget 2> $null

    if(! (Test-Path "$l_target_link")) {
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


    # Configuracion de 'oh-my-posh'
    if(! (Test-Path "${env:USERPROFILE}\.files\etc\default_settings.json" )) {
		Write-Host "            > Creando el archivo '${env:USERPROFILE}\.files\etc\default_settings.json' ..."
        Copy-Item -Path "${env:USERPROFILE}\.files\etc\lepc-montys-cyan1.json" "${env:USERPROFILE}\.files\etc\default_settings.json"

        Write-Host "            > Edite '${env:USERPROFILE}\.files\etc\default_settings.json' si desea modificar las opciones Wezterm."
	}
    else {
        Write-Host "            > Edite '${env:USERPROFILE}\.files\etc\default_settings.json' si desea modificar las opciones Wezterm."
    }


    # Configuracion de wezterm
    $l_target_link="${env:USERPROFILE}\.config\wezterm\wezterm.lua"
    $l_source_path="${env:USERPROFILE}\.files\wezterm\local"
	$l_source_filename='wezterm.lua'
    m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    $l_target_link="${env:USERPROFILE}\.config\wezterm\utils"
    $l_source_path="${env:USERPROFILE}\.files\wezterm\local\utils"
    m_create_folder_link "$l_source_path" "$l_target_link" "            > " $l_overwrite_ln_flag


	#if(! (Test-Path "${g_win_base_path}\prgs\wezterm\wezterm_modules")) {
	#	New-Item -ItemType Directory -Force -Path "${g_win_base_path}\prgs\wezterm\wezterm_modules"
    #}

    if(! (Test-Path "${env:USERPROFILE}\.config\wezterm\custom_config.lua" )) {
		Write-Host "            > Creando el archivo '${env:USERPROFILE}\.config\wezterm\custom_config.lua' ..."
        Copy-Item -Path "${env:USERPROFILE}\.files\wezterm\local\custom_config_template_win.lua" -Destination "${env:USERPROFILE}\.config\wezterm\custom_config.lua"

        Write-Host "            > Edite '${env:USERPROFILE}\.config\wezterm\custom_config.lua' si desea modificar las opciones Wezterm."
	}
    else {
        Write-Host "            > Edite '${env:USERPROFILE}\.config\wezterm\custom_config.lua' si desea modificar las opciones Wezterm."
    }


    #Configuracion por Lazygit
    $l_target_link="${env:LOCALAPPDATA}\lazygit\config.yml"
    $l_source_path="${env:USERPROFILE}\.files\lazygit"
    $l_source_filename='config_default.yaml'

	if(! (Test-Path "${env:LOCALAPPDATA}\lazygit")) {
		New-Item -ItemType Directory -Force -Path "${env:LOCALAPPDATA}\lazygit"
    }
    m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


    #Configuracion por Yazi
    $l_target_link="${env:APPDATA}\yazi\config\yazi.toml"
    $l_source_path="${env:USERPROFILE}\.files\etc\yazi"
    $l_source_filename='yazi_default.toml'

	if(! (Test-Path "${env:APPDATA}\yazi\config")) {
		New-Item -ItemType Directory -Force -Path "${env:APPDATA}\yazi\config"
    }
    m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

    $l_target_link="${env:APPDATA}\yazi\config\keymap.toml"
    $l_source_path="${env:USERPROFILE}\.files\etc\yazi"
    $l_source_filename='keymap_default.toml'
    m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag

    $l_target_link="${env:APPDATA}\yazi\config\theme.toml"
    $l_source_path="${env:USERPROFILE}\.files\etc\yazi"
    $l_source_filename='theme_default.toml'
    m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $l_overwrite_ln_flag


	if(! (Test-Path "${env:APPDATA}\yazi\config\flavors\catppuccin-mocha.yazi")) {
		New-Item -ItemType Directory -Force -Path "${env:APPDATA}\yazi\config\flavors\catppuccin-mocha.yazi"
    }

    $l_target_link="${env:APPDATA}\yazi\config\flavors\catppuccin-mocha.yazi\flavor.toml"
    $l_source_path="${env:USERPROFILE}\.files\etc\yazi\catppuccin-mocha\flavor.toml"
    Copy-Item -Path "$l_source_path" -Destination "$l_target_link"

    $l_target_link="${env:APPDATA}\yazi\config\flavors\catppuccin-mocha.yazi\tmtheme.xml"
    $l_source_path="${env:USERPROFILE}\.files\etc\yazi\catppuccin-mocha\tmtheme.xml"
    Copy-Item -Path "$l_source_path" -Destination "$l_target_link"





}


function m_install_pws_module() {

    Write-Host ""

    #i. Instalar el modulo PSFzf

    #Buscar si el modulo esta instado
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


function m_create_basic_folders($p_flag_developer) {

    $document_path= [Environment]::GetFolderPath("mydocuments")

    $l_folders = @(
        "${env:USERPROFILE}\vimfiles"
        "${env:LOCALAPPDATA}\nvim"
        "${env:LOCALAPPDATA}\nvim\rte_cocide"
        "${env:LOCALAPPDATA}\nvim\rte_nativeide"
        "${env:APPDATA}\eclipse\jdtls"
        "${document_path}\PowerShell"
        "${document_path}\WindowsPowerShell"
        "${env:USERPROFILE}\.config"
        "${env:LOCALAPPDATA}\lazygit"
        "${env:APPDATA}\yazi"
        "${env:APPDATA}\yazi\config"
    )

    $l_folder_path = $null
    $l_is_first = $true
    for ($i=0; $i -lt $l_folders.Count; $i++) {

        $l_folder_path= $l_folders[$i]
        if (!$l_folder_path) {
            continue
        }

	    if(! (Test-Path "$l_folder_path")) {
            if ($l_is_first) {
                Write-Host "New folders > Creando el folder '${l_folder_path}'."
            }
            else {
                $l_is_first = $false
                Write-Host "            > Creando el folder '${l_folder_path}'."
            }
		    New-Item -ItemType Directory -Force -Path "$l_folder_path"
        }

    }

}


function m_create_all_links($p_overwrite_ln_flag) {

    $document_path= [Environment]::GetFolderPath("mydocuments")

    $l_folder_links = @(
        [PSCustomObject]@{
            target_link     = "${env:LOCALAPPDATA}\nvim\setting"
            source_path     = "${env:USERPROFILE}\.files\vim\setting"
        },
        [PSCustomObject]@{
            target_link     = "${env:LOCALAPPDATA}\nvim\lua"
            source_path     = "${env:USERPROFILE}\.files\nvim\lua"
        },
        [PSCustomObject]@{
            target_link     = "${env:LOCALAPPDATA}\nvim\ftplugin"
            source_path     = "${env:USERPROFILE}\.files\nvim\ftplugin\commonide"
        },
        [PSCustomObject]@{
            target_link     = "${env:LOCALAPPDATA}\nvim\rte_cocide\ftplugin"
            source_path     = "${env:USERPROFILE}\.files\nvim\ftplugin\cocide"
        },
        [PSCustomObject]@{
            target_link     = "${env:LOCALAPPDATA}\nvim\rte_nativeide\ftplugin"
            source_path     = "${env:USERPROFILE}\.files\nvim\ftplugin\nativeide"
        },
        [PSCustomObject]@{
            target_link     = "${env:USERPROFILE}\vimfiles\setting"
            source_path     = "${env:USERPROFILE}\.files\vim\setting"
        },
        [PSCustomObject]@{
            target_link     = "${env:USERPROFILE}\vimfiles\ftplugin"
            source_path     = "${env:USERPROFILE}\.files\vim\ftplugin\cocide"
        },
        [PSCustomObject]@{
            target_link     = "${env:USERPROFILE}\.config\wezterm\utils"
            source_path     = "${env:USERPROFILE}\.files\wezterm\local\utils"
        }
    )

    $l_item = $null
    $l_tag = "Folder link > "
    for ($i=0; $i -lt $l_folder_links.Count; $i++) {

        $l_item= $l_folder_links[$i]
        if (!$l_item) {
            continue
        }

        if($i -ne 0) {
            $l_tag = "            > "
        }

        m_create_folder_link $l_item.source_path $l_item.target_link $l_tag $p_overwrite_ln_flag

    }


    $l_file_links = @(
        [PSCustomObject]@{
            target_link     = "${env:LOCALAPPDATA}\nvim\init.vim"
            source_path     = "${env:USERPROFILE}\.files\nvim"
            source_filename = "init_ide.vim"
        },
        [PSCustomObject]@{
            target_link     = "${env:LOCALAPPDATA}\nvim\coc-settings.json"
            source_path     = "${env:USERPROFILE}\.files\nvim"
            source_filename = "coc-settings_windows.json"
        },
        [PSCustomObject]@{
            source_filename = ""
        },
        [PSCustomObject]@{
            target_link     = "${env:USERPROFILE}\.vimrc"
            source_path     = "${env:USERPROFILE}\.files\vim"
            source_filename = "vimrc_ide.vim"
        },
        [PSCustomObject]@{
            target_link     = "${env:USERPROFILE}\vimfiles\coc-settings.json"
            source_path     = "${env:USERPROFILE}\.files\vim"
            source_filename = "coc-settings_windows.json"
        },
        [PSCustomObject]@{
            target_link     = "${env:USERPROFILE}\.gitconfig"
            source_path     = "${env:USERPROFILE}\.files\etc\git"
            source_filename = "gitconfig_win.toml"
        },
        [PSCustomObject]@{
            target_link     = "${document_path}\PowerShell\Microsoft.PowerShell_profile.ps1"
            source_path     = "${env:USERPROFILE}\.files\shell\powershell\login\windowsprofile"
            source_filename = "windows_x64.ps1"
        },
        [PSCustomObject]@{
            target_link     = "${document_path}\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
            source_path     = "${env:USERPROFILE}\.files\shell\powershell\login\windowsprofile"
            source_filename = "legacy_x64.ps1"
        },
        [PSCustomObject]@{
            target_link     = "${env:USERPROFILE}\.config\wezterm\wezterm.lua"
            source_path     = "${env:USERPROFILE}\.files\wezterm\local"
            source_filename = "wezterm.lua"
        },
        [PSCustomObject]@{
            target_link     = "${env:LOCALAPPDATA}\lazygit\config.yml"
            source_path     = "${env:USERPROFILE}\.files\lazygit"
            source_filename = "config_default.yaml"
        },
        [PSCustomObject]@{
            target_link     = "${env:APPDATA}\yazi\config\yazi.toml"
            source_path     = "${env:USERPROFILE}\.files\etc\yazi"
            source_filename = "yazi_default.toml"
        },
        [PSCustomObject]@{
            target_link     = "${env:APPDATA}\yazi\config\keymap.toml"
            source_path     = "${env:USERPROFILE}\.files\etc\yazi"
            source_filename = "keymap_default.toml"
        },
        [PSCustomObject]@{
            target_link     = "${env:APPDATA}\yazi\config\theme.toml"
            source_path     = "${env:USERPROFILE}\.files\etc\yazi"
            source_filename = "theme_default.toml"
        }
    )

    $l_item = $null
    $l_tag = "File link   > "
    for ($i=0; $i -lt $l_file_links.Count; $i++) {

        $l_item= $l_file_links[$i]
        if (!$l_item) {
            continue
        }

        if($i -ne 0) {
            $l_tag = "            > "
        }

        m_create_file_link $l_item.source_path $l_item.source_filename $l_item.target_link $l_tag $p_overwrite_ln_flag

    }



}


function m_setup($p_input_options) {


    if($p_input_options -eq "a") {

        m_create_basic_folders
        return
    }


    if($p_input_options -eq "b") {

        m_create_all_links $false
        m_install_pws_module
        return
    }


    if($p_input_options -eq "c") {

        m_create_all_links $true
        m_install_pws_module
        return
    }


    if($p_input_options -eq "d") {

        $l_overwrite_ln_flag = $true

	    #Instalar VIM como Developer
	    m_config_vim $true $l_overwrite_ln_flag $true
	    Write-Host ""
        return
    }


    if($p_input_options -eq "e") {

        $l_overwrite_ln_flag = $false

	    #Instalar NeoVIM como Developer
	    m_config_nvim $true $l_overwrite_ln_flag $true
	    Write-Host ""

        return
    }


    if($p_input_options -eq "f") {

        $l_overwrite_ln_flag = $false

	    #Configurar el profile
	    m_setup_profile $l_overwrite_ln_flag
        return
    }

    if($p_input_options -eq "g") {

        $l_overwrite_ln_flag = $false

	    #Instalar VIM como Developer
	    m_config_vim $true $l_overwrite_ln_flag $true
	    Write-Host ""

	    #Instalar NeoVIM como Developer
	    m_config_nvim $true $l_overwrite_ln_flag $true
	    Write-Host ""

	    #Configurar el profile
	    m_setup_profile $l_overwrite_ln_flag
        return
    }


    if($p_input_options -eq "h") {

        $l_overwrite_ln_flag = $true

	    #Instalar VIM como Developer
	    m_config_vim $true $l_overwrite_ln_flag $true
	    Write-Host ""

	    #Instalar NeoVIM como Developer
	    m_config_nvim $true $l_overwrite_ln_flag $true
	    Write-Host ""

	    #Configurar el profile
	    m_setup_profile $l_overwrite_ln_flag
        return
    }


    if($p_input_options -eq "i") {

        $l_overwrite_ln_flag = $false

	    #Instalar VIM como Developer
	    m_config_vim $true $l_overwrite_ln_flag $false
	    Write-Host ""

	    #Instalar NeoVIM como Developer
	    m_config_nvim $true $l_overwrite_ln_flag $false
	    Write-Host ""

	    #Configurar el profile
	    m_setup_profile $l_overwrite_ln_flag
        return
    }


    if($p_input_options -eq "j") {

        $l_overwrite_ln_flag = $true

	    #Instalar VIM como Developer
	    m_config_vim $true $l_overwrite_ln_flag $false
	    Write-Host ""

	    #Instalar NeoVIM como Developer
	    m_config_nvim $true $l_overwrite_ln_flag $false
	    Write-Host ""

	    #Configurar el profile
	    m_setup_profile $l_overwrite_ln_flag
        return
    }


}

function m_show_menu_core() {

	Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
	Write-Host "                                                      Menu de Opciones" -ForegroundColor Green
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
	Write-Host " (q) Salir del menu";
	Write-Host " (a) Crear folder requeridos"
	Write-Host " (b) Crear   enlaces simbolicos e instalar plugin PSFzf (usar administrador)"
	Write-Host " (c) Recrear enlaces simbolicos e instalar plugin PSFzf (usar administrador)"
	Write-Host " (d) Configurar VIM como developer"
	Write-Host " (e) Configurar NeoVIM como developer"
	Write-Host " (f) Configurar Profile como developer"
	Write-Host " (g) Setup VIM/NeoVIM y Profile como developer"
	Write-Host " (h) Setup VIM/NeoVIM y Profile como developer (re-crear enlaces simbolicos si existen)"
	Write-Host " (i) Setup VIM/NeoVIM (sin indexar documentación) y Profile como developer"
	Write-Host " (j) Setup VIM/NeoVIM (sin indexar documentación) y Profile como developer (re-crear enlaces)"
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
					m_setup $l_read_option
				}

				'b' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $l_read_option
				}

				'c' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $l_read_option
				}

				'd' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $l_read_option
				}

				'e' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $l_read_option
				}

				'f' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $l_read_option
				}

				'g' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $l_read_option
				}

				'h' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $l_read_option
				}

				'i' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $l_read_option
				}

				'j' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""
					m_setup $l_read_option
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
#$g_fix_fzf=0
#if($args.count -ge 1) {
#    if($args[0] -eq "1") {
#        $g_fix_fzf=1
#    }
#}


# Folder base donde se almacena el programas, comando y afines usados por Windows.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es un valor valido, se asignara "C:\apps"
# - En este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_win_base_path}/tools"    : subfolder donde se almacena los subfolder de los programas.
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
if(Test-Path "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1") {

    . "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1"

    #Fix the bad entry values
    if( "$g_setup_only_last_version" -eq "0" ) {
        $g_setup_only_last_version=0
    }
    else {
        $g_setup_only_last_version=1
    }

}

# Valor por defecto del folder base de  programas, comando y afines usados por Windows.
if((-not ${g_win_base_path}) -and -not (Test-Path "$g_win_base_path")) {
    $g_win_base_path='C:\apps'
}

# Ruta del folder base donde estan los subfolderes del los programas (1 o mas comandos y otros archivos).
if((-not ${g_temp_path}) -and -not (Test-Path "$g_temp_path")) {
    $g_temp_path= 'C:\Windows\Temp'
}


show_menu
