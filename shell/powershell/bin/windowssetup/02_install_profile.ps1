#------------------------------------------------------------------------------------------------
# Inicializacion
#------------------------------------------------------------------------------------------------

$g_max_length_line= 120

# Grupo de plugins de VIM/NeoVIM :
# (00) Grupo Basic > Themes              - Temas
# (01) Grupo Basic > Core                - StatusLine, TabLine, FZF, TMUX utilities, Files Tree
# (02) Grupo Basic > Extended (Headless) - Highlighting Sintax, Autocompletion para linea de comandos, Markdown render.
# (03) Grupo Basic > Extended (Desktop)  - Integracion con imagenes externas, Previsualidor en browser.
# (04) Grupo IDE > Utils                 - Libreries, Typing utilities.
# (05) Grupo IDE > Development > Common  - Plugin comunes de soporte independiente de tipo LSP usado (nativa o CoC).
# (06) Grupo IDE > Development > Native  - LSP, Snippets, Compeletion  ... usando la implementacion nativa.
# (07) Grupo IDE > Development > CoC     - LSP, Snippets, Completion ... usando CoC.
# (08) Grupo IDE > Testing               - Unit Testing y Debugging.
# (09) Grupo IDE > Basic Tools > Common  - Plugin de tools independiente del tipo de LSP usado (nativa o CoC).
# (10) Grupo IDE > Basic Tools > Native  - Tools: Git, Rest Client, etc.
# (11) Grupo IDE > Basic Tools > CoC     - Tools: Git, Rest Client, etc.
# (12) Grupo IDE > AI Tools    > Native  - Tools: AI Completion
# (13) Grupo IDE > AI Tools    > Native  - Tools: AI Chatbot y AI Agent interno del IDE
# (14) Grupo IDE > AI Tools    > Native  - Tools: AI Chatbot y AI Agent externo al IDE (Solo se integra CLI externo como OpenCode-CLI, Gemini-CLI, etc).
# (15) Grupo IDE > AI Tools    > CoC     - Tools: AI Completion
# (16) Grupo IDE > AI Tools    > CoC     - Tools: AI Chatbot y AI Agent interno del IDE
# (17) Grupo IDE > AI Tools    > CoC     - Tools: AI Chatbot y AI Agent externo al IDE (Solo se integra CLI externo como OpenCode-CLI, Gemini-CLI, etc).
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
        'tpope/vim-surround' = 4
        'mg979/vim-visual-multi' = 4
        'mattn/emmet-vim' = 4
        'dense-analysis/ale' = 5
        'liuchengxu/vista.vim' = 5
        'neoclide/coc.nvim' = 7
        'antoinemadec/coc-fzf' = 7
        'SirVer/ultisnips' = 7
        'OmniSharp/omnisharp-vim' = 7
        'honza/vim-snippets' = 7
        'puremourning/vimspector' = 8
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
        'MeanderingProgrammer/render-markdown.nvim' = 2
        'HakonHarnes/img-clip.nvim' = 3
        'iamcco/markdown-preview.nvim' = 3
        'obsidian-nvim/obsidian.nvim' = 3
        'nvim-lua/plenary.nvim' = 4
        'nvim-treesitter/nvim-treesitter-context' = 5
        'stevearc/aerial.nvim' = 5
        'neovim/nvim-lspconfig' = 6
        'ray-x/lsp_signature.nvim' = 6
        'hrsh7th/cmp-nvim-lsp' = 6
        'L3MON4D3/LuaSnip' = 6
        'rafamadriz/friendly-snippets' = 6
        'saadparwaiz1/cmp_luasnip' = 6
        'b0o/SchemaStore.nvim' = 6
        'kosayoda/nvim-lightbulb' = 6
        'doxnit/cmp-luasnip-choice' = 6
        'mfussenegger/nvim-jdtls' = 6
        'mfussenegger/nvim-dap' = 8
        'rcarriga/nvim-dap-ui' = 8
        'theHamsta/nvim-dap-virtual-text' = 8
        'nvim-neotest/nvim-nio' = 8
        'vim-test/vim-test' = 8
        'mistweaverco/kulala.nvim' = 9
        'lewis6991/gitsigns.nvim' = 9
        'sindrets/diffview.nvim' = 9
        'zbirenbaum/copilot.lua' = 12
        'zbirenbaum/copilot-cmp' = 12
        'milanglacier/minuet-ai.nvim' = 12
        'stevearc/dressing.nvim' = 13
        'MunifTanjim/nui.nvim' = 13
        'yetone/avante.nvim' = 13
        'NickvanDyke/opencode.nvim' = 14
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
        'MeanderingProgrammer/render-markdown.nvim' = 2
        'HakonHarnes/img-clip.nvim' = 2
        'iamcco/markdown-preview.nvim' = 2
        'obsidian-nvim/obsidian.nvim' = 2
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
        'milanglacier/minuet-ai.nvim' = 2
        'stevearc/dressing.nvim' = 2
        'MunifTanjim/nui.nvim' = 2
        'yetone/avante.nvim' = 2
        'NickvanDyke/opencode.nvim' = 2
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
    "basic_desktop"
    "ide_utils"
    "ide_dev_common"
    "ide_dev_native"
    "ide_dev_coc"
    "ide_testing"
    "ide_ext_common"
    "ide_ext_native"
    "ide_ext_coc"
    "ide_ai_native"
    "ide_ai_native"
    "ide_ai_native"
    "ide_ai_coc"
    "ide_ai_coc"
    "ide_ai_coc"
    )


# Usado para escribir logs
$g_tag_empty= "            > "


# Importando funciones de utilidad
. "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/lib/setup_profile_utility.ps1"



#------------------------------------------------------------------------------------------------
# Funciones de cracion de folderes y/o enlaces simbolicos
#------------------------------------------------------------------------------------------------

function m_create_folder($p_existing_base_path, $p_relative_folder_path_to_validate, $p_tag) {

    # Si la ruta base no existe, salirr
    $l_tmp= $null
	if(! (Test-Path "${p_existing_base_path}")) {
        Write-Host "${p_tag}El folder '${p_existing_base_path}' no existe."
        return 2
    }

    # Crear el directorio padre del target
    $l_folder_path = "${p_existing_base_path}\${p_relative_folder_path_to_validate}"

    # Si no existe el target, copiarlo
	if(! (Test-Path "$l_folder_path")) {

		$l_tmp= New-Item -ItemType Directory -Force -Path "${l_folder_path}"
        Write-Host "${p_tag}Se ha creado el folder '${l_folder_path}'."
		return 1

	}
    return 0

}


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

        if ($g_setup_access_type -eq 2) {
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
            if ($g_setup_access_type -eq 2) {
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
                if ($g_setup_access_type -eq 2) {
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
        if ($g_setup_access_type -eq 2) {
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

        if ($g_setup_access_type -eq 2) {
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
            if ($g_setup_access_type -eq 2) {
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
                if ($g_setup_access_type -eq 2) {
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
        if ($g_setup_access_type -eq 2) {
		    sudo cmd /c mklink /d "$p_target_link" "$p_source_path"
        }
        else {
		    cmd /c mklink /d "$p_target_link" "$p_source_path"
        }

        Write-Host "${p_tag}El enlace simbolico '${p_target_link}' se ha creado " -NoNewline
		Write-Host "(ruta real '${p_source_path}')" -ForegroundColor DarkGray

    }

}


function m_copy_file($p_source_path, $p_source_filename, $p_target_file, $p_tag, $p_override_file) {


    # Creear el directorio padre del target
    $l_target_base = Split-Path -Parent $p_target_file
    $l_tmp= $null
	if(! (Test-Path "${l_target_base}")) {
		$l_tmp= New-Item -ItemType Directory -Force -Path "${l_target_base}"
    }

    # Si no existe el target, copiarlo
    $l_source_fullfilename="${p_source_path}\${p_source_filename}"
	if(! (Test-Path "$p_target_file")) {

        Copy-Item -Path "${l_source_fullfilename}" -Destination "${p_target_file}"

        Write-Host "${p_tag}Se ha creado el archivo '${p_target_file}' " -NoNewline
		Write-Host "(copiado de '${l_source_fullfilename}')" -ForegroundColor DarkGray
		return

	}

    # Si existe el target
	$l_info= Get-Item "$p_target_file" | Select-Object LinkType, LinkTarget


    # Si existe el target y es un anlace simbolico eliminar el enlace simbolico y copiar el archivo.
    if ( $l_info.LinkType -eq "SymbolicLink" ) {

        rm "$p_target_file"
        Copy-Item -Path "${l_source_fullfilename}" -Destination "${p_target_file}"

        Write-Host "${p_tag}Se ha creado el archivo '${p_target_file}' eliminando el enlace simbolico " -NoNewline
		Write-Host "(copiado de '${l_source_fullfilename}')" -ForegroundColor DarkGray
        return

	}

    # Si existe el target y es un archivo, solo copiarlo si indica sobreescribir.
    if ( $p_override_file ) {

        rm "$p_target_file"
        Copy-Item -Path "${l_source_fullfilename}" -Destination "${p_target_file}"

        Write-Host "${p_tag}Se ha re-creado el archivo '${p_target_file}' " -NoNewline
		Write-Host "(copiado de '${l_source_fullfilename}')" -ForegroundColor DarkGray

    }

}


# Sera muy comun sobrescribir el folder, debido a que es muy costoso comparar si existe todos los
# hijos de dicho folder.
function m_copy_folder($p_source_path, $p_target_folder, $p_tag, $p_override_folder) {


    # Creear el directorio padre del target
    $l_target_base = Split-Path -Parent $p_source_path
	$l_tmp= $null
    if(! (Test-Path "${l_target_base}")) {
        $l_tmp= New-Item -ItemType Directory -Force -Path "${l_target_base}"
    }

    # Si no existe el target, copiarlo
	if(! (Test-Path "${p_target_folder}") ) {

        Copy-Item -Path "${p_source_path}" -Destination "${p_target_folder}" -Recurse

        Write-Host "${p_tag}Se copiado a '${p_target_folder}' y todo su contenido " -NoNewline
		Write-Host "(desde '${p_source_path}')" -ForegroundColor DarkGray
		return

    }

    # Si existe el target
    $l_info= Get-Item "$p_target_folder" | Select-Object LinkType, LinkTarget

    # Si existe el target y es un anlace simbolico eliminar el enlace simbolico y copiar el archivo.
	if ( $l_info.LinkType -eq "SymbolicLink" ) {

        rm "$p_target_folder"
        Copy-Item -Path "${p_source_path}" -Destination "${p_target_folder}" -Recurse

        Write-Host "${p_tag}Se copiado a '${p_target_folder}' y todo su contenido, eliminado el SymbolicLink " -NoNewline
		Write-Host "(desde '${p_source_path}')" -ForegroundColor DarkGray
        return
	}


    # Si existe el target y es un archivo, solo copiarlo si indica sobreescribir.
    if ( $p_override_folder ) {

        Remove-Item "${p_target_folder}" -Recurse -Force
        Copy-Item -Path "${p_source_path}" -Destination "${p_target_folder}" -Recurse

        Write-Host "${p_tag}Se eliminado y copiando a '${p_target_folder}' " -NoNewline
		Write-Host "(desde '${p_source_path}')" -ForegroundColor DarkGray
    }

}



#------------------------------------------------------------------------------------------------
# Funciones de cracion de enlaces simbolicos requeridos y modulos
#------------------------------------------------------------------------------------------------

function m_create_folders_for_symboliclinks($p_flag_developer) {

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
        "${env:APPDATA}\yazi\config\plugins"
        "${env:APPDATA}\yazi\config\flavors"
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


function m_create_all_symboliclinks($p_flag_overwrites_ln) {

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
            target_link     = "${env:APPDATA}\yazi\config\plugins\fzf-fd.yazi"
            source_path     = "${env:USERPROFILE}\.files\yazi\plugins\fzf-fd.yazi"
        },
        [PSCustomObject]@{
            target_link     = "${env:APPDATA}\yazi\config\plugins\fzf-rg.yazi"
            source_path     = "${env:USERPROFILE}\.files\yazi\plugins\fzf-rg.yazi"
        },
        [PSCustomObject]@{
            target_link     = "${env:APPDATA}\yazi\config\plugins\go-fs.yazi"
            source_path     = "${env:USERPROFILE}\.files\yazi\plugins\go-fs.yazi"
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

        m_create_folder_link $l_item.source_path $l_item.target_link $l_tag $p_flag_overwrites_ln

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
            source_path     = "${env:USERPROFILE}\.files\yazi"
            source_filename = "yazi_desktop.toml"
        },
        [PSCustomObject]@{
            target_link     = "${env:APPDATA}\yazi\config\theme.toml"
            source_path     = "${env:USERPROFILE}\.files\yazi"
            source_filename = "theme.toml"
        }
    )

    Write-Host ""
	Write-Host ""
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

        m_create_file_link $l_item.source_path $l_item.source_filename $l_item.target_link $l_tag $p_flag_overwrites_ln

    }

}


function m_install_pws_module($p_module_name, $p_flag_user_scope) {

    Write-Host ""

    #i. Instalar el modulo PSFzf

    #Buscar si el modulo esta instado
    $mod= Get-InstalledModule $p_module_name 2> $null
    if($mod) {
        Write-Host "El modulo '${p_module_name}' $($mod.Version) esta instalado."
        Write-Host "Intentando actualizar el modulo '${p_module_name}' ..."

        if ($p_flag_user_scope) {
            Update-Module -Name $p_module_name -Scope CurrentUser
        }
        else {
            Update-Module -Name $p_module_name -Scope AllUser
        }

    }
    else {
        Write-Host "Instalando el modulo '${p_module_name}' ..."

        if ($p_flag_user_scope) {
            Install-Module -Name $p_module_name -Scope CurrentUser
        }
        else {
            Install-Module -Name $p_module_name -Scope AllUser
        }
    }

}


#------------------------------------------------------------------------------------------------
# Funciones de configuracion de VIM o NeoVIM
#------------------------------------------------------------------------------------------------

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
    $l_enable_ai_plugin= 1

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
        if (-not $p_flag_developer -and $l_repo_type -ge 4) {
			#Write-Host "Repo-Name '${l_repo_name}', Repo-Scope '${l_repo_scope}', Repo-Git '${l_repo_git}', Current-Scope '${l_current_scope}', Developer '${p_flag_developer}', Base-Path '${l_base_path}'"
			continue
        }
		#Write-Host "Repo-Name '${l_repo_name}', Repo-Scope '${l_repo_scope}', Repo-Git '${l_repo_git}', Current-Scope '${l_current_scope}', Developer '${p_flag_developer}', Base-Path '${l_base_path}'"

        #4.3 Si es un plugin de AI
        if ($l_repo_type -ge 11 -and $l_repo_type -le 16) {

            # Si se excluye todos los plugin de AI
            if ($g_setup_vim_ai_plugins -eq 0) {
                Write-Host "Paquete ${l_tag} (${l_repo_type}) `"${l_repo_git}`":  Ha sigo excluido para su descarga (g_setup_vim_ai_plugins es ${g_setup_vim_ai_plugins})"
                continue
            }

            $l_enable_ai_plugin=1

            # Validar si se excluye los plugins de AI completion
            if ( ($g_setup_vim_ai_plugins -band 1) -eq 1 ) {
                if ( $l_repo_type -eq 11 -or $l_repo_type -eq 14 ) {
                    $l_enable_ai_plugin = 0
                }
            }

            # Validar si se excluye los plugins de AI Chatbot y AI Agent internos
            if ( ($g_setup_vim_ai_plugins -band 2) -eq 2 ) {
                if ( $l_repo_type -eq 12 -or $l_repo_type -eq 15 ) {
                    $l_enable_ai_plugin = 0
                }
            }

            # Validar si se excluye los plugins de integracion con AI Chatbot y AI Agent externos (OpenCode CLI, Gemini CLI, etc)
            if ( ($g_setup_vim_ai_plugins -band 4) -eq 4 ) {
                if ( $l_repo_type -eq 13 -or $l_repo_type -eq 16 ) {
                    $l_enable_ai_plugin = 0
                }
            }

            # Si se excluye
            if ($l_enable_ai_plugin -eq 1) {
                Write-Host "Paquete ${l_tag} (${l_repo_type}) `"${l_repo_git}`":  Ha sigo excluido para su descarga (g_setup_vim_ai_plugins es ${g_setup_vim_ai_plugins})"
                continue
            }

        }

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

			Write-Host "(${l_j}/${l_n}) Indexando la documentación del plugin `"${l_repo_name}`" en `"${l_tag}`": `"helptags ${l_repo_path}`""
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

    return 0

}


function m_setup_nvim_files($p_flag_developer, $p_flag_overwrites_file_notmodifiable) {

    # Si el modo de acceso permite crear enlaces simbolicos pero solo usando una pseudo-terminal con accesos administivos
    if ($g_setup_access_type -eq 1 -and -not $g_shell_with_admin_privileges) {
        Write-Host "Para crear enlaces SymbolicLink debe usar una terminal con accesos administrativos (g_setup_access_type: ${g_setup_access_type})."
        return 0
    }

    # Creando los enlaces simbolicos
    $l_target_link= ""
    $l_source_path= ""
    $l_source_filename= ""
    $l_tag= "NeoVIM (IDE)> "

    # Configurar NeoVIM como IDE (Developer)
    if ($p_flag_developer) {

        $l_status= m_create_folder "${env:LOCALAPPDATA}" "nvim" $l_tag

        $l_target_link="${env:LOCALAPPDATA}\nvim\init.vim"
        $l_source_path="${env:USERPROFILE}\.files\nvim"
        $l_source_filename="init_ide.vim"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }

        $l_target_link="${env:LOCALAPPDATA}\nvim\coc-settings.json"
        $l_source_path="${env:USERPROFILE}\.files\nvim"
        $l_source_filename="coc-settings_windows.json"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }


        $l_target_link="${env:LOCALAPPDATA}\nvim\setting"
        $l_source_path="${env:USERPROFILE}\.files\vim\setting"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }

        $l_target_link="${env:LOCALAPPDATA}\nvim\lua"
        $l_source_path="${env:USERPROFILE}\.files\nvim\lua"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }

        #El codigo open\close asociado a los 'file types'
        $l_target_link="${env:LOCALAPPDATA}\nvim\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\nvim\ftplugin\commonide"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }

        #Para el codigo open/close asociado a los 'file types' de CoC
        $l_status= m_create_folder "${env:LOCALAPPDATA}" "nvim\rte_cocide" $l_tag

        $l_target_link="${env:LOCALAPPDATA}\nvim\rte_cocide\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\nvim\ftplugin\cocide"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }


        #Para el codigo open/close asociado a los 'file types' que no sean CoC
        $l_status= m_create_folder "${env:LOCALAPPDATA}" "nvim\rte_nativeide" $l_tag

        $l_target_link="${env:LOCALAPPDATA}\nvim\rte_nativeide\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\nvim\ftplugin\nativeide"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }


        #Creando la carpeta base para los metadata de los proyecto usados por el LSP JDTLS
    	if(! (Test-Path "${env:APPDATA}\eclipse\jdtls")) {
	    	New-Item -ItemType Directory -Force -Path "${env:APPDATA}\eclipse\jdtls"
        }



	}
    # Configurar NeoVIM como Editor
    else {

        $l_status= m_create_folder "${env:LOCALAPPDATA}" "nvim" $l_tag

        $l_target_link="${env:LOCALAPPDATA}\nvim\init.vim"
        $l_source_path="${env:USERPROFILE}\.files\nvim"
        $l_source_filename="init_editor.vim"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }

        $l_target_link="${env:LOCALAPPDATA}\nvim\setting"
        $l_source_path="${env:USERPROFILE}\.files\vim\setting"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }


        $l_target_link="${env:LOCALAPPDATA}\nvim\lua"
        $l_source_path="${env:USERPROFILE}\.files\nvim\lua"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }


        #El codigo open\close asociado a los 'file types' como Editor
        $l_target_link="${env:LOCALAPPDATA}\nvim\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\nvim\ftplugin\editor"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }


    }

    return 0

}



# Parametros:
#  1> Flag configurar como Developer (si es '0')
function m_config_nvim($p_input_options, $p_flag_developer, $p_flag_overwrites_file_notmodifiable, $p_flag_overwrites_file_modifiable) {

    #1. Argumentos
    if ($p_input_options -le 0) {
        return
    }


	# (1024) NeoVIM > Descargar plugins de NeoVIM sin indexar su documentación
	# (2048) NeoVIM > Descargar plugins de NeoVIM indexando su documentación
	# (4096) NoeVIM > Crear los archivos de configuración de NeoVIM
    $l_flag_download_plugins_without_indexing= $false
    $l_flag_download_plugins_with_indexing= $false
    $l_flag_create_config_files= $false

    $l_option = 1024
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_download_plugins_without_indexing= $true
    }

    # Instalando paquetes
    $l_option = 2048
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_download_plugins_with_indexing= $true
    }

    # Creando los archivos y folderes requeridos por NeoVIM
    $l_option = 4096
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_create_config_files= $true
    }

    if ( -not $l_flag_download_plugins_without_indexing -and -not $l_flag_download_plugins_with_indexing -and -not $l_flag_create_config_files ) {
        return 1
    }


    #2. Crear el subtitulo
    Write-Host ""

    $l_title= ">> Configurando NeoVIM"
    if($p_flag_developer) {
        $l_title= "${l_title} (Modo developer)"
    }
    else {
        $l_title= "${l_title} (Modo editor)"
    }


    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue
    Write-Host "$l_title" -ForegroundColor Blue
    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue

    #3. Creando el directorio hijos si no existen
	$l_tmp= New-Item -ItemType Directory -Force -Path "${env:LOCALAPPDATA}\nvim"


	# (1024) NeoVIM > Descargar plugins de NeoVIM sin indexar su documentación
	# (2048) NeoVIM > Descargar plugins de NeoVIM indexando su documentación
	# (4096) NoeVIM > Crear los archivos de configuración de NeoVIM

    # Instalando paquetes
    $l_status = 0
    $l_flag_index_documentation = $false

    if ( $l_flag_download_plugins_without_indexing ) {
        $l_status= m_setup_vim_packages $true $p_flag_developer $l_flag_index_documentation
    }

    # Instalando paquetes
    if ( $l_flag_download_plugins_with_indexing ) {

        $l_flag_index_documentation = $true
        $l_status= m_setup_vim_packages $true $p_flag_developer $l_flag_index_documentation

    }

    # Creando los archivos y folderes requeridos por NeoVIM
    if ( $l_flag_create_config_files ) {
        $l_status= m_setup_nvim_files $p_flag_developer $p_flag_overwrites_file_notmodifiable
    }

    #6. Mostrar la informacion de lo instalado
    $l_status= show_vim_config_report $true $p_flag_developer

}


function m_setup_vim_files($p_flag_developer, $p_flag_overwrites_file_notmodifiable) {

    # Si el modo de acceso permite crear enlaces simbolicos pero solo usando una pseudo-terminal con accesos administivos
    if ($g_setup_access_type -eq 1 -and -not $g_shell_with_admin_privileges) {
        Write-Host "Para crear enlaces SymbolicLink debe usar una terminal con accesos administrativos (g_setup_access_type: ${g_setup_access_type})."
        return 0
    }

    # Creando los enlaces simbolicos
    $l_target_link= ""
    $l_source_path= ""
    $l_source_filename= ""
    $l_tag= "VIM    (IDE)> "


    # Configurar VIM como IDE (Developer)
    if ($p_flag_developer) {

        #Creando enlaces simbolicos
        $l_target_link="${env:USERPROFILE}\.vimrc"
        $l_source_path="${env:USERPROFILE}\.files\vim"
        $l_source_filename="vimrc_ide.vim"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }

        $l_status= m_create_folder "${env:USERPROFILE}" "vimfiles" $l_tag

        $l_target_link="${env:USERPROFILE}\vimfiles\coc-settings.json"
        $l_source_path="${env:USERPROFILE}\.files\vim"
        $l_source_filename="coc-settings_windows.json"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }

        $l_target_link="${env:USERPROFILE}\vimfiles\setting"
        $l_source_path="${env:USERPROFILE}\.files\vim\setting"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }

        $l_target_link="${env:USERPROFILE}\vimfiles\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\vim\ftplugin\cocide"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
        }


	}
    # Configurar VIM como Editor basico
    else {

        $l_target_link="${env:USERPROFILE}\.vimrc"
        $l_source_path="${env:USERPROFILE}\.files\vim"
        $l_source_filename="vimrc_editor.vim"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "VIM    (IDE)> " $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "VIM    (IDE)> " $p_flag_overwrites_file_notmodifiable
        }

        $l_status= m_create_folder "${env:USERPROFILE}" "vimfiles" $l_tag

        $l_target_link="${env:USERPROFILE}\vimfiles\setting"
        $l_source_path="${env:USERPROFILE}\.files\vim\setting"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "VIM    (IDE)> " $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "VIM    (IDE)> " $p_flag_overwrites_file_notmodifiable
        }


        $l_target_link="${env:USERPROFILE}\vimfiles\ftplugin"
        $l_source_path="${env:USERPROFILE}\.files\vim\ftplugin\editor"
        if ($g_setup_access_type -eq 0) {
            $l_status= m_copy_folder "$l_source_path" "$l_target_link" "VIM    (IDE)> " $p_flag_overwrites_file_notmodifiable
        }
        else {
            $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "VIM    (IDE)> " $p_flag_overwrites_file_notmodifiable
        }


    }

}



# Parametros:
#  1> Flag configurar como Developer (si es '0')
#  2> Sobrescribir los enlaces simbolicos
function m_config_vim($p_input_options, $p_flag_developer, $p_flag_overwrites_file_notmodifiable, $p_flag_overwrites_file_modifiable) {

    #1. Argumentos
    if ($p_input_options -le 0) {
        return 1
    }

	# ( 128) VIM    > Descargar plugins de VIM sin indexar su documentación
	# ( 256) VIM    > Descargar plugins de VIM indexando su documentación
	# ( 512) VIM    > Crear los archivos de configuración de VIM
    $l_flag_download_plugins_without_indexing= $false
    $l_flag_download_plugins_with_indexing= $false
    $l_flag_create_config_files= $false

    $l_option = 128
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_download_plugins_without_indexing= $true
    }

    # Instalando paquetes
    $l_option = 256
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_download_plugins_with_indexing= $true
    }

    # Creando los archivos y folderes requeridos por NeoVIM
    $l_option = 512
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_create_config_files= $true
    }

    if ( -not $l_flag_download_plugins_without_indexing -and -not $l_flag_download_plugins_with_indexing -and -not $l_flag_create_config_files ) {
        return 1
    }


    #2. Crear el subtitulo
    Write-Host ""

    $l_title= ">> Configurando VIM"
    if($p_flag_developer) {
        $l_title= "${l_title} (Modo developer)"
    }
    else {
        $l_title= "${l_title} (Modo editor)"
    }


    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue
    Write-Host "$l_title" -ForegroundColor Blue
    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue

    #3. Creando el directorio hijos si no existen
	$l_tmp= New-Item -ItemType Directory -Force -Path "${env:USERPROFILE}\vimfiles"

	# ( 128) VIM    > Descargar plugins de VIM sin indexar su documentación
	# ( 256) VIM    > Descargar plugins de VIM indexando su documentación
	# ( 512) VIM    > Crear los archivos de configuración de VIM

    # Instalando paquetes
    $l_flag_index_documentation = $false

    if ( $l_flag_download_plugins_without_indexing ) {
        $l_status= m_setup_vim_packages $false $p_flag_developer $l_flag_index_documentation
    }

    # Instalando paquetes
    if ( $l_flag_download_plugins_with_indexing ) {

        $l_flag_index_documentation = $true
        $l_status= m_setup_vim_packages $false $p_flag_developer $l_flag_index_documentation

    }

    # Creando los archivos y folderes requeridos por NeoVIM
    if ( $l_flag_create_config_files ) {
        $l_status= m_setup_vim_files $p_flag_developer $p_flag_overwrites_file_notmodifiable
    }

    #6. Mostrar la informacion de lo instalado
    $l_status= show_vim_config_report $false $p_flag_developer

    return 0

}


#------------------------------------------------------------------------------------------------
# Funciones de configuracion del Profile
#------------------------------------------------------------------------------------------------

function m_setup_profile_files($p_flag_developer, $p_flag_overwrites_file_notmodifiable, $p_flag_overwrites_file_modifiable) {

    #1. Si el modo de acceso permite crear enlaces simbolicos pero solo usando una pseudo-terminal con accesos administivos
    if ($g_setup_access_type -eq 1 -and -not $g_shell_with_admin_privileges) {
        Write-Host "Para crear enlaces SymbolicLink debe usar una terminal con accesos administrativos (g_setup_access_type: ${g_setup_access_type})."
        return 0
    }


    #3. Creando enlaces simbolico dependientes del tipo de distribución Linux
    $l_target_link= ""
    $l_source_path= ""
    $l_source_filename= ""
    $l_tag= "General     > "
    $l_status= 0


    #Archivo de configuracion de Git
    $l_target_link="${env:USERPROFILE}\.gitconfig"
    $l_source_path="${env:USERPROFILE}\.files\etc\git"
	$l_source_filename='gitconfig_win.toml'
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }

    $l_status= m_create_folder "${env:USERPROFILE}" ".config\git" $l_tag

    $l_target_link="${env:USERPROFILE}\.config\git\user_main.toml"
    $l_source_path="${env:USERPROFILE}\.files\etc\git"
    $l_source_filename="user_main_template_win.toml"
    $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_modifiable

    $l_target_link="${env:USERPROFILE}\.config\git\user_mywork.toml"
    $l_source_path="${env:USERPROFILE}\.files\etc\git"
    $l_source_filename="user_work_template_win.toml"
    $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_modifiable
    Write-Host "${g_tag_empty}Edite '~\.config\git\user_main.toml' y '~\.config\git\user_mywork.toml' si desea crear modificar las opciones de '~/.gitignore'."


    #Archivo de configuracion de SSH
    $l_status= m_create_folder "${env:USERPROFILE}" ".ssh" $l_tag

    $l_target_link="${env:USERPROFILE}\.ssh\config"
    $l_source_path="${env:USERPROFILE}\.files\etc\ssh\template_windows_withpublickey.conf"
    $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_modifiable


    #Archivos de configuracion de PowerShell
	$document_path= [Environment]::GetFolderPath("mydocuments")
    $l_status= m_create_folder "${document_path}" "PowerShell" $l_tag
    $l_status= m_create_folder "${document_path}" "WindowsPowerShell" $l_tag


    $l_target_link="${document_path}\PowerShell\Microsoft.PowerShell_profile.ps1"
    $l_source_path="${env:USERPROFILE}\.files\shell\powershell\login\windowsprofile"
	$l_source_filename='windows_x64.ps1'
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }


	$l_target_link="${document_path}\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    $l_source_path="${env:USERPROFILE}\.files\shell\powershell\login\windowsprofile"
	$l_source_filename='legacy_x64.ps1'
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }


    # Configuracion de 'oh-my-posh'
    $l_target_link="${env:USERPROFILE}\.files\etc\oh-my-posh\default_settings.json"
    $l_source_path="${env:USERPROFILE}\.files\etc\oh-my-posh\lepc-montys-cyan1.json"
    $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "General     > " $p_flag_overwrites_file_modifiable
    Write-Host "            > Edite '${env:USERPROFILE}\.files\etc\oh-my-posh\default_settings.json' si desea modificar las opciones Wezterm."


    # Configuracion de wezterm
    $l_status= m_create_folder "${env:USERPROFILE}" ".config\wezterm" $l_tag

    $l_target_link="${env:USERPROFILE}\.config\wezterm\wezterm.lua"
    $l_source_path="${env:USERPROFILE}\.files\wezterm\local"
	$l_source_filename='wezterm.lua'
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }

    $l_target_link="${env:USERPROFILE}\.config\wezterm\utils"
    $l_source_path="${env:USERPROFILE}\.files\wezterm\local\utils"
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }

    $l_target_link="${env:USERPROFILE}\.config\wezterm\custom_config.lua"
    $l_source_path="${env:USERPROFILE}\.files\wezterm\local\custom_config_template_win.lua"
    $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_modifiable


    #Configuracion por Lazygit
    $l_status= m_create_folder "${env:LOCALAPPDATA}" "lazygit" $l_tag

    $l_target_link="${env:LOCALAPPDATA}\lazygit\config.yml"
    $l_source_path="${env:USERPROFILE}\.files\etc\lazygit"
    $l_source_filename='config_default.yaml'
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }


    #Configuracion por Yazi
    $l_status= m_create_folder "${env:APPDATA}" "yazi\config" $l_tag
    $l_status= m_create_folder "${env:APPDATA}\yazi\config" "flavors" $l_tag
    $l_status= m_create_folder "${env:APPDATA}\yazi\config" "plugins" $l_tag

    $l_target_link="${env:APPDATA}\yazi\config\yazi.toml"
    $l_source_path="${env:USERPROFILE}\.files\yazi"
    $l_source_filename='yazi_desktop.toml'
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }


    $l_target_link="${env:APPDATA}\yazi\config\theme.toml"
    $l_source_path="${env:USERPROFILE}\.files\yazi"
    $l_source_filename='theme.toml'
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }

    $l_target_link="${env:APPDATA}\yazi\config\keymap.toml"
    $l_source_path="${env:USERPROFILE}\.files\yazi\keymap_win.toml"
    $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_modifiable
    Write-Host "            > Edite '${env:APPDATA}\yazi\config\keymap.toml' si desea modificar las opciones Wezterm."


    $l_target_link="${env:APPDATA}\yazi\config\init.lua"
    $l_source_path="${env:USERPROFILE}\.files\yazi"
    $l_source_filename='init.lua'
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_file_link "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    Write-Host "            > Edite '${env:APPDATA}\yazi\config\init.lua' si desea modificar las opciones Wezterm."

    $l_target_link="${env:APPDATA}\yazi\config\flavors\catppuccin-mocha.yazi\flavor.toml"
    $l_source_path="${env:USERPROFILE}\.files\yazi\flavors\catppuccin-mocha.yazi"
    $l_source_filename='flavor.toml'
    $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable

    $l_target_link="${env:APPDATA}\yazi\config\flavors\catppuccin-mocha.yazi\tmtheme.xml"
    $l_source_path="${env:USERPROFILE}\.files\yazi\flavors\catppuccin-mocha.yazi"
    $l_source_filename='tmtheme.xml'
    $l_status= m_copy_file "$l_source_path" "$l_source_filename" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable


    $l_target_link="${env:APPDATA}\.config\yazi\plugins\fzf-fd.yazi"
    $l_source_path="${env:USERPROFILE}\.files\yazi\plugins\fzf-fd.yazi"
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }

    $l_target_link="${env:APPDATA}\.config\yazi\plugins\fzf-rg.yazi"
    $l_source_path="${env:USERPROFILE}\.files\yazi\plugins\fzf-rg.yazi"
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }

    $l_target_link="${env:APPDATA}\.config\yazi\plugins\go-fs.yazi"
    $l_source_path="${env:USERPROFILE}\.files\yazi\plugins\go-fs.yazi"
    if ($g_setup_access_type -eq 0) {
        $l_status= m_copy_folder "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }
    else {
        $l_status= m_create_folder_link "$l_source_path" "$l_target_link" "$l_tag" $p_flag_overwrites_file_notmodifiable
    }

}


function m_setup_profile($p_input_options, $p_flag_developer, $p_flag_overwrites_file_notmodifiable, $p_flag_overwrites_file_modifiable) {

    if ($p_input_options -le 0) {
        return 1
    }

    $l_flag_create_folder_for_symboliclinks= $false
    $l_flag_crate_all_symboliclinks= $false
    $l_flag_install_psfzf_global= $false
    $l_flag_install_psfzf_user= $false
    $l_flag_setup_profile_files= $false

	# (   4) Crear todos los folder requeridos para crear enlaces simbolicos
    $l_option = 4
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_create_folder_for_symboliclinks= $true
    }

    # (   8) Crear todos los enlaces simbolicos requeridos (se debe ejecutar con administrador)
    $l_option = 8
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_crate_all_symboliclinks= $true
    }

	# (  16) Instalar y/o actualizar PSFzf a nivel global  (se debe ejecutar con administrador)
    $l_option = 16
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_install_psfzf_global= $true
    }

	# (  32) Instalar y/o actualizar PSFzf a nivel usuario
    $l_option = 32
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_install_psfzf_user= $true
    }

	# (  64) Setup Profile como developer
    $l_option = 64
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_setup_profile_files= $true
    }

    if ( -not $l_flag_create_folder_for_symboliclinks -and -not $l_flag_crate_all_symboliclinks -and -not $l_flag_install_psfzf_global -and -not $l_flag_install_psfzf_user -and -not $l_flag_setup_profile_files ) {
        return 1
    }



    # Mostrar el titulo
    Write-Host ""

    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue
	$l_title=">> Configurando el Profile del Usuario"
	Write-Host "$l_title" -ForegroundColor Blue
    Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Blue


	# (   4) Crear todos los folder requeridos para crear enlaces simbolicos
    if ( $l_flag_create_folder_for_symboliclinks ) {
        $l_status= m_create_folders_for_symboliclinks $p_flag_developer
    }

    # (   8) Crear todos los enlaces simbolicos requeridos (se debe ejecutar con administrador)
    if ( $l_flag_crate_all_symboliclinks ) {
        $l_status= m_create_all_symboliclinks $p_flag_developer
    }

	# (  16) Instalar y/o actualizar PSFzf a nivel global  (se debe ejecutar con administrador)
    if ( $l_flag_install_psfzf_global ) {
        $l_status= m_install_pws_module 'PSFzf' $false
    }

	# (  32) Instalar y/o actualizar PSFzf a nivel usuario
    if ( $l_flag_install_psfzf_user ) {
        $l_status= m_install_pws_module 'PSFzf' $true
    }

	# (  64) Setup Profile como developer
    if ( $l_flag_setup_profile_files ) {
        $l_status= m_setup_profile_files $p_flag_developer $l_flag_overwrites_file_notmodifiable $l_flag_overwrites_file_modifiable
    }

    return 0

}


#------------------------------------------------------------------------------------------------
# Funciones principales
#------------------------------------------------------------------------------------------------

function m_setup($p_input_options) {

    if ($p_input_options -le 0) {
        return
    }

    $l_flag_developer = $true

	# (   1) Sobrescribir enlaces simbolicos y archivos no-modificables por el usuario
	# (   2) Sobrescribir archivos modificables por el usuario
    $l_flag_overwrites_file_notmodifiable = $false
    $l_option = 1
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_overwrites_file_notmodifiable = $true
    }

    $l_flag_overwrites_file_modifiable = $false
    $l_option = 2
    if ( ($p_input_options -band $l_option) -eq $l_option ) {
        $l_flag_overwrites_file_modifiable = $true
    }

    # (   8) Crear todos los enlaces simbolicos requeridos (se debe ejecutar con administrador)
	# (  16) Instalar y/o actualizar PSFzf a nivel global  (se debe ejecutar con administrador)
	# (  32) Instalar y/o actualizar PSFzf a nivel usuario
	# (  64) Setup Profile como developer
    $l_status= m_setup_profile $p_input_options $l_flag_developer $l_flag_overwrites_file_notmodifiable $l_flag_overwrites_file_modifiable

	# ( 128) VIM    > Descargar plugins de VIM sin indexar su documentación
	# ( 256) VIM    > Descargar plugins de VIM indexando su documentación
	# ( 512) VIM    > Crear los archivos de configuración de VIM
	$l_status= m_config_vim $p_input_options $l_flag_developer $l_flag_overwrites_file_notmodifiable $l_flag_overwrites_file_modifiable

	# (1024) NeoVIM > Descargar plugins de NeoVIM sin indexar su documentación
	# (2048) NeoVIM > Descargar plugins de NeoVIM indexando su documentación
	# (4096) NoeVIM > Crear los archivos de configuración de NeoVIM
	$l_status= m_config_nvim $p_input_options $l_flag_developer $l_flag_overwrites_file_notmodifiable $l_flag_overwrites_file_modifiable

    return 0

}



function m_show_menu_core() {

	Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
	Write-Host "                                                      Menu de Opciones" -ForegroundColor Green
	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray

    $l_options= 0
    Write-Host " (q) Salir del menu"

    if ($g_setup_access_type -eq 1 -and -not $g_shell_with_admin_privileges) {

        $l_options = 4
	    Write-Host " (a) Crear todos los folder requeridos para crear los SymbolicLink " -NoNewline
		Write-Host "(opcion ${l_options})" -ForegroundColor DarkGray

        $l_options = 8 + 16
	    Write-Host " (b) Crear todos los SymbolicLink e instalar PSFzf globalmente " -NoNewline
        if (-not $g_shell_with_admin_privileges) {
            Write-Host " (ejecutar como administrador) " -NoNewline -ForegroundColor Red
        }
		Write-Host "(opcion ${l_options})" -ForegroundColor DarkGray

        $l_options = 8 + 16 + 1
	    Write-Host " (c) Recrear todos los SymbolicLink e instalar PSFzf globalmente " -NoNewline
        if (-not $g_shell_with_admin_privileges) {
            Write-Host " (ejecutar como administrador) " -NoNewline -ForegroundColor Red
        }
		Write-Host "(opcion ${l_options})" -ForegroundColor DarkGray

    }

	Write-Host " ( ) Estas opciones siempre sobrescriben los SymbolicLink/Files no-modificables:"

    $l_options = 64 + 1
	Write-Host " (d) Setup Profile como developer " -NoNewline
    Write-Host "(opcion ${l_options})" -ForegroundColor DarkGray

    $l_options = 256 + 512 + 1
	Write-Host " (e) Setup VIM como developer " -NoNewline
    Write-Host "(opcion ${l_options})" -ForegroundColor DarkGray

    $l_options = 2048 + 4096 + 1
	Write-Host " (f) Setup NeoVIM como developer " -NoNewline
    Write-Host "(opcion ${l_options})" -ForegroundColor DarkGray

    $l_options = 64 + 256 + 512 + 2048 + 4096 + 1
	Write-Host " (g) Setup VIM/NeoVIM y Profile como developer " -NoNewline
    Write-Host "(opcion ${l_options})" -ForegroundColor DarkGray

    $l_options = 64 + 128 + 512 + 1024 + 4096 + 1
	Write-Host " (h) Setup VIM/NeoVIM (sin indexar documentación) y Profile como developer " -NoNewline
    Write-Host "(opcion ${l_options})" -ForegroundColor DarkGray

	Write-Host " ( ) Configuración personalizado. Ingrese la suma de las opciones que desea configurar:"
	Write-Host "    (   1) Sobrescribir enlaces simbolicos y archivos no-modificables por el usuario"
	Write-Host "    (   2) Sobrescribir archivos modificables por el usuario"

    if ($g_setup_access_type -eq 1 -and -not $g_shell_with_admin_privileges) {
	    Write-Host "    (   4) Crear todos los folder requeridos para crear enlaces simbolicos"
        Write-Host "    (   8) Crear todos los enlaces simbolicos requeridos (se debe ejecutar con administrador)"
	    Write-Host "    (  16) Instalar y/o actualizar PSFzf a nivel global  (se debe ejecutar con administrador)"
    }

	Write-Host "    (  32) Instalar y/o actualizar PSFzf a nivel usuario"
	Write-Host "    (  64) Setup Profile como developer"
	Write-Host "    ( 128) VIM    > Descargar plugins de VIM sin indexar su documentación"
	Write-Host "    ( 256) VIM    > Descargar plugins de VIM indexando su documentación"
	Write-Host "    ( 512) VIM    > Crear los archivos de configuración de VIM"
	Write-Host "    (1024) NeoVIM > Descargar plugins de NeoVIM sin indexar su documentación"
	Write-Host "    (2048) NeoVIM > Descargar plugins de NeoVIM indexando su documentación"
	Write-Host "    (4096) NoeVIM > Crear los archivos de configuración de NeoVIM"

	Write-Host ([string]::new('-', $g_max_length_line)) -ForegroundColor DarkGray
}


function show_menu() {

	Write-Host ""
	m_show_menu_core

	$l_continue= $true
	$l_read_option= ""
    $l_options=0
    $l_status=0

	while($l_continue)
	{
			Write-Host "Ingrese la opción (" -NoNewline
			Write-Host "no ingrese los ceros a la izquierda" -NoNewline -ForegroundColor DarkGray
			$l_read_option= Read-Host ")"

			switch -Regex ($l_read_option)
			{

	            # (   1) Sobrescribir enlaces simbolicos y archivos no-modificables por el usuario
	            # (   2) Sobrescribir archivos modificables por el usuario
	            # (   4) Crear todos los folder requeridos para crear enlaces simbolicos
                # (   8) Crear todos los enlaces simbolicos requeridos (se debe ejecutar con administrador)
	            # (  16) Instalar y/o actualizar PSFzf a nivel global  (se debe ejecutar con administrador)
	            # (  32) Instalar y/o actualizar PSFzf a nivel usuario
	            # (  64) Setup Profile como developer
	            # ( 128) VIM    > Descargar plugins de VIM sin indexar su documentación
	            # ( 256) VIM    > Descargar plugins de VIM indexando su documentación
	            # ( 512) VIM    > Crear los archivos de configuración de VIM
	            # (1024) NeoVIM > Descargar plugins de NeoVIM sin indexar su documentación
	            # (2048) NeoVIM > Descargar plugins de NeoVIM indexando su documentación
	            # (4096) NoeVIM > Crear los archivos de configuración de NeoVIM

				'^a$' {
					$l_continue= $true
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""

                    if ($g_setup_access_type -eq 1 -and -not $g_shell_with_admin_privileges) {

					    $l_continue= $false
                        $l_options = 4
					    $l_status= m_setup $l_options

                    }
				}

				'^b$' {
					$l_continue= $true
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""

                    if ($g_setup_access_type -eq 1 -and -not $g_shell_with_admin_privileges) {

					    $l_continue= $false
                        $l_options = 8 + 16
					    $l_status= m_setup $l_options

                    }
				}

				'^c$' {
					$l_continue= $true
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""

                    if ($g_setup_access_type -eq 1 -and -not $g_shell_with_admin_privileges) {

					    $l_continue= $false
                        $l_options = 8 + 16 + 1
					    $l_status= m_setup $l_options

                    }
				}

	            # (d) Setup Profile como developer
				'^d$' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""

	                # (  64) Setup Profile como developer
	                # (   1) Sobrescribir enlaces simbolicos y archivos no-modificables por el usuario
                    $l_options = 64 + 1
					$l_status= m_setup $l_options
				}

	            # (e) Setup VIM como developer
				'^e$' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""

	                # ( 256) VIM    > Descargar plugins de VIM indexando su documentación
	                # ( 512) VIM    > Crear los archivos de configuración de VIM
	                # (   1) Sobrescribir enlaces simbolicos y archivos no-modificables por el usuario
                    $l_options = 256 + 512 + 1
					$l_status= m_setup $l_options
				}

	            # (f) Setup NeoVIM como developer
				'^f$' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""

	                # (2048) NeoVIM > Descargar plugins de NeoVIM indexando su documentación
	                # (4096) NoeVIM > Crear los archivos de configuración de NeoVIM
	                # (   1) Sobrescribir enlaces simbolicos y archivos no-modificables por el usuario
                    $l_options = 2048 + 4096 + 1
					$l_status= m_setup $l_options
				}

	            # (g) Setup VIM/NeoVIM y Profile como developer
				'^g$' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""

	                # (  64) Setup Profile como developer
	                # ( 256) VIM    > Descargar plugins de VIM indexando su documentación
	                # ( 512) VIM    > Crear los archivos de configuración de VIM
	                # (2048) NeoVIM > Descargar plugins de NeoVIM indexando su documentación
	                # (4096) NoeVIM > Crear los archivos de configuración de NeoVIM
	                # (   1) Sobrescribir enlaces simbolicos y archivos no-modificables por el usuario
                    $l_options = 64 + 256 + 512 + 2048 + 4096 + 1
					$l_status= m_setup $l_options
				}

	            # (h) Setup VIM/NeoVIM (sin indexar documentación) y Profile como developer
				'^h$' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""

	                # (  64) Setup Profile como developer
	                # ( 128) VIM    > Descargar plugins de VIM sin indexar su documentación
	                # ( 512) VIM    > Crear los archivos de configuración de VIM
	                # (1024) NeoVIM > Descargar plugins de NeoVIM sin indexar su documentación
	                # (4096) NoeVIM > Crear los archivos de configuración de NeoVIM
	                # (   1) Sobrescribir enlaces simbolicos y archivos no-modificables por el usuario
                    $l_options = 64 + 128 + 512 + 1024 + 4096 + 1
					$l_status= m_setup $l_options
				}

				'^\d+$' {
					$l_continue= $false
	                Write-Host ([string]::new('─', $g_max_length_line)) -ForegroundColor Green
					Write-Host ""

                    $l_options = [int]$l_read_option
					$l_status= m_setup $l_options
				}


				'^q$' {
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


# Cargar la parametros globales modificables por el usuario
if(Test-Path "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1") {

    . "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1"
    Write-Host "Config File                    : ${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1" -ForegroundColor DarkGray

    #Fix the bad entry values

}

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
#
# Valor por defecto del folder base de  programas, comando y afines usados por Windows.
if(-not ${g_win_base_path} -or -not (Test-Path "$g_win_base_path")) {
    $g_win_base_path='C:\apps'
}
Write-Host "Base Folder Path               : ${g_win_base_path}" -ForegroundColor DarkGray

# Folder base donde se almacena data temporal que sera eliminado automaticamente despues completar la configuración.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es valido, la funcion "get_temp_path" asignara segun orden de prioridad a '$env:TEMP'.
#
# Ruta del folder base donde estan los subfolderes del los programas (1 o mas comandos y otros archivos).
if((-not ${g_temp_path}) -or -not (Test-Path "$g_temp_path")) {
    $g_temp_path= 'C:\Windows\Temp'
}
Write-Host "Temporary Path                 : ${g_temp_path}" -ForegroundColor DarkGray

# Usado solo durante la instalación. Define si se instala solo la ultima version de un programa.
#Por defecto es considerado 'false'.
if(-not (Get-Variable g_setup_only_last_version -ErrorAction SilentlyContinue) ) {
    $g_setup_only_last_version= $false
}

# Definir si se descarga y configuracion plugins de AI (AI Completion, AI Chatbot, AI Agent, etc.).
# Sus valores puede ser:
# > 0 No instala ningun plugin de AI.
# > Puede ser la suma de los siguientes valores:
#   > 1 Instala plugin de AI Completion.
#   > 2 Instala plugin de AI Chatbot y AI Agent interno (por ejemplo Avante)
#   > 4 Instala plugin de integracion de AI Chatbot y AI Agent externo (por ejemplo integracion con OpenCode-CLI o Gemini-CLI)
# Si no se define el valor por defecto es '0' (no se instala ningun plugin de AI).
if(-not (Get-Variable g_setup_vim_ai_plugins -ErrorAction SilentlyContinue) ) {
    $g_setup_vim_ai_plugins=0
}
Write-Host "Setup AI VIM Plugins           : ${g_setup_vim_ai_plugins} (1= AI Completion, 2= AI Chatbot/Agent interno, 3= AI Chatbot/Agent externo)" -ForegroundColor DarkGray

# Modo de instalacion segun los acceso que se tiene para crear enlaces simbolicos
# Sus valores pueden ser:
# > 0 Si no se tiene acceso para crear a enlaces simbolicos (debe tener un usuario que puede ejecutar en en modo privilegiado
#     o poder ejecutar 'sudo').
#     > Usualmente se realiza una copia (y/o elimina versiones anteriores) de los archivos no-modificables por el usuario.
#     > Existe algunos archivos que usuario puede modificarlos. Estos archivos solo se puede reescribir si se flag de reescritura
#       para evitar perdidas de configuraciones de usuario.
# > 1 Se puede crear enlaces simbolicos pero desde una instancia de una pseudo-terminal con acceso privilegiado.
# > 2 Se puede crear enlaces simbolicos en la misma pseudo-terminal usando el comando 'sudo' (Solo en Windows que no son Core
#     y cuya version >= 24H2)
# > Si no se especifica su valor por defecto es 1.
if(-not (Get-Variable g_setup_access_type -ErrorAction SilentlyContinue) ) {
    $g_setup_access_type=1
}
Write-Host "Setup (SymbolicLink creation)  : ${g_setup_access_type} (0= Solo copiar, 1= Usando administrador, 2= Usando sudo)" -ForegroundColor DarkGray

# Determinar si se esta ejecutando la terminal con privilegios administratrivos
$g_shell_with_admin_privileges = $false

$t_principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($t_principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $g_shell_with_admin_privileges = $true
    Write-Host "Administrator Privileges       : ${g_shell_with_admin_privileges}" -ForegroundColor DarkGray
}
else {
    Write-Host "Administrator Privileges       : ${g_shell_with_admin_privileges}" -ForegroundColor DarkGray
}

show_menu
