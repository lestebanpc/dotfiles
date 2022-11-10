--###################################################################################
-- Configuracion de basica antes de la carga automatica de paquetes Neovim
--###################################################################################

-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1


--###################################################################################
-- Packege Manager (Packer) : Registro de paquetes y Carga automacia de algunos de ellos
--###################################################################################

return require('packer').startup(function(use)
    
    --Package CORE> Packer can manage itself
    use 'wbthomason/packer.nvim'
    
    --Package UI> CORE> Tema 'Tokyo Night'
    use 'folke/tokyonight.nvim'

    --Package UI> CORE> Barra de estado
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons' }
    }

    --Package UI> CORE> Barra de buffer y pestañas
    use {
        'akinsho/bufferline.nvim',
        opt = true,
        tag = "v3.*", 
        requires = 'kyazdani42/nvim-web-devicons'
    }

    --Package UI> EXTENDED> Navegador simmilar a FZF
    use {
        'nvim-telescope/telescope.nvim',
        requires = { {'nvim-lua/plenary.nvim'} }
    }

    -- Package UI> CORE> Facilita la navegacion entre Split VIM y Paneles TMUX
    use {
        'christoomey/vim-tmux-navigator',
        opt = true
    }

    -- Package UI> EXTENDED> Explorer de archivos
    use {
        'nvim-tree/nvim-tree.lua',
        opt = true,
        requires = {
            'nvim-tree/nvim-web-devicons',
        },
        tag = 'nightly'
    }

    -- Package UI> IDE> TYPING> Vim-Surround (completar (), [], {})
    use {
        'tpope/vim-surround',
        opt = true
    }

    -- Package UI> IDE> CORE> Resaltador de sintaxis o semantica
    use {
        'nvim-treesitter/nvim-treesitter',
        opt = true,
        run = ':TSUpdate'
    }

    -- Package UI> IDE> CORE> CMP (Autocompletion framework)
    use {
        'mg979/vim-visual-multi',
        opt = true
    }

    -- Package UI> IDE> CORE> Modulo de configuracion del LSP cliente nativo de Noevim
    --    Permite LSP Client, Ligting, Fixing, ...
    use {
        'neovim/nvim-lspconfig',
        opt = true
    }
    
    -- Package UI> IDE> CORE> CMP (Autocompletion framework)
    use {
        'hrsh7th/nvim-cmp',
        opt = true
    }
    
    -- Package UI> IDE> CORE> CMP Source: LSP Client
    use {
        'hrsh7th/cmp-nvim-lsp',
        opt = true
    }

    -- Package UI> IDE> CORE> CMP Source: Buffer (Sugiere palabras que se encuentra en el archivo actual)
    use {
        'hrsh7th/cmp-buffer',
        opt = true
    }

    -- Package UI> IDE> CORE> CMP Source: Filesystem Path
    use {
        'hrsh7th/cmp-path',
        opt = true
    }

    -- Package UI> IDE> CORE> Motor/Framework de Snippets
    --   Muestra los snippets cargados. Si elegimos un snippet lo expande.
    use {
        'L3MON4D3/LuaSnip',
        opt = true,
        tag = "v<CurrentMajor>.*"
    }

    -- Package UI> IDE> CORE> Implementacion de Snippet para LuaSnip
    use {
        'rafamadriz/friendly-snippets',
        opt = true
    }

    -- Package UI> IDE> CORE> CMP Source: Snippet LuaSnip
    use {
        'saadparwaiz1/cmp_luasnip',
        opt = true
    }

end)

--###################################################################################
-- Configuracion de basica despues de la carga automatica de paquetes Neovim 
--   - Antes de establecer el 'Color Schema'
--###################################################################################

--https://github.com/folke/tokyonight.nvim#%EF%B8%8F-configuration
