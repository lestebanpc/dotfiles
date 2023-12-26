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
    
    ---------------------------------------------------------------------------------
    --Editor: Mejora de la exeriencia de usuario (Exclusivo para Neovim)
    ---------------------------------------------------------------------------------
    
    --Package UI> CORE> Tema 'Tokyo Night'
    use 'folke/tokyonight.nvim'

    --Package UI> CORE> Iconos requeridos por barra de estado y pestañas/buffer
    use 'kyazdani42/nvim-web-devicons'

    --Package UI> CORE> Barra de estado
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons' }
    }

    --Package UI> CORE> Barra de buffer y pestañas
    use {
        'akinsho/bufferline.nvim',
        opt = true,
        tag = "*", 
        requires = 'kyazdani42/nvim-web-devicons'
    }

    --Package UI> EXTENDED> Navegador simmilar a FZF
    use {
        'nvim-telescope/telescope.nvim',
        requires = { {'nvim-lua/plenary.nvim'} }
    }

    -- Package UI> CORE> Crear paneles TMUX desde VIM (en Windows no existe TMUX) 
    use {
        'preservim/vimux',
        opt = true
    }

    -- Package UI> CORE> Facilita la navegacion entre Split VIM y Paneles TMUX
    use {
        'christoomey/vim-tmux-navigator',
        opt = true
    }


    -- Package UI> EXTENDED> FZF - Plugin de funciones basicas
    use {
        'junegunn/fzf',
        opt = true
    }

    -- Package UI> EXTENDED> FZF - Plugin que permite el uso FZF en VIM
    use {
        'junegunn/fzf.vim',
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

    ---------------------------------------------------------------------------------
    --IDE: Basico (Exclusivo para Neovim)
    ---------------------------------------------------------------------------------

    -- Package UI> IDE> TYPING> Vim-Surround (completar (), [], {})
    use {
        'tpope/vim-surround',
        opt = true
    }

    -- Package UI> IDE> TYPING> Crear elementos HTML por comandos  
    use {
        'mattn/emmet-vim',
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


    ---------------------------------------------------------------------------------
    --IDE: Ligting, Code Formatting por servidores NO-LSP  (Exclusivo para Neovim)
    ---------------------------------------------------------------------------------

    -- Package UI> IDE> Ligting, Code Formatting (incluyendo los 'Fixers') por servidores
    -- No-LSP (Ejemplo: EsLint, Prettier, ...). Genera wrappers de servidores No-LSP, para
    -- hacerlos pasar como servidores LSP, usando todos los objetos LSP proveido por Neovim.
    use {
        'jose-elias-alvarez/null-ls.nvim',
        opt = true
    }

    ---------------------------------------------------------------------------------
    --IDE: Soporte de configuración LSP Client (Exclusivo para Neovim)
    ---------------------------------------------------------------------------------

    -- Package UI> IDE> CORE> Modulo de configuracion del LSP cliente nativo de Noevim
    use {
        'neovim/nvim-lspconfig',
        opt = true
    }
    
    ---------------------------------------------------------------------------------
    --IDE: Completition (Exclusivo para Neovim)
    ---------------------------------------------------------------------------------

    -- Package UI> IDE> CORE> CMP (Autocompletion framework)
    use {
        'hrsh7th/nvim-cmp',
        opt = true
    }
    
    -- Package UI> IDE> CORE> Mejor soporte a popup 'signature-help' en el completado de un metodo
    use {
        'ray-x/lsp_signature.nvim',
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
    
    ---------------------------------------------------------------------------------
    --IDE: Snippets (Exclusivo para Neovim)
    ---------------------------------------------------------------------------------

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

    
    ---------------------------------------------------------------------------------
    --IDE: Wizard para instalar/configurar adaptadores LSP/DAP (Exclusivo para Neovim)
    ---------------------------------------------------------------------------------

    ---- Package UI> IDE> CORE> Wizard para instalar adaptadores LSP 
    --use {
    --    'williamboman/mason.nvim',
    --    opt = true
    --}

    ---- Package UI> IDE> CORE> Configurar adaptadores LSP usando ' nvim-lspconfig'
    --use {
    --    'williamboman/mason-lspconfig.nvim',
    --    opt = true
    --}

    ---- Package UI> IDE> CORE> Configurar adaptadores DAP usando ' nvim-dap'
    --use {
    --    'jay-babu/mason-nvim-dap.nvim',
    --    opt = true
    --}

    ---------------------------------------------------------------------------------
    --IDE: Otros (Exclusivo para Neovim)
    ---------------------------------------------------------------------------------

    -- Package UI> IDE> CORE> LightBulb para Code Actions
    use {
        'kosayoda/nvim-lightbulb',
        --Para corregir un error (solucionado en la versión ...)
        --requires = {
        --    'antoinemadec/FixCursorHold.nvim',
        --},
        opt = true
    }

    ---------------------------------------------------------------------------------
    --IDE: Completition, LSP Client, Snippets (Tambien lo usa Vim)
    ---------------------------------------------------------------------------------

    -- Package UI> IDE> CORE> Ligting (Diagnostico)
    use {
        'dense-analysis/ale',
        opt = true
    }

    -- Package UI> IDE> CORE> Motor/Framework de Snippets
    --   Muestra los snippets cargados. Si elegimos un snippet lo expande.
    use {
        'SirVer/ultisnips',
        opt = true
    }

    -- Package UI> IDE> CORE> Implementacion de Snippet para diferentes lenguajes de programación
    use {
        'honza/vim-snippets',
        opt = true
    }

    -- Package UI> IDE> CORE> Completado, LSP cliente, ..
    use {
        'neoclide/coc.nvim',
        opt = true,
        branch = 'release'
    }
    
    -- Package UI> IDE> CORE> C#> LSP Client, Adaptador para LSP Server 'OmniSharp Roslyn'
    -- Snippet para C#
    use {
        'OmniSharp/omnisharp-vim',
        opt = true
    }

    ---------------------------------------------------------------------------------
    --IDE: Debugger (Exclusivo para Noevim)
    ---------------------------------------------------------------------------------

    -- Package UI> IDE> CORE> Depurador (Cliente DAP y los adaptadores depuracion)  
    use {
        "mfussenegger/nvim-dap",
        opt = true,
    --    event = "BufReadPre",
    --    module = { "dap" }
    --    wants = { "nvim-dap-virtual-text", "DAPInstall.nvim", "nvim-dap-ui", "nvim-dap-python", "which-key.nvim" },
    --    requires = {
    --        "Pocco81/DAPInstall.nvim",
    --        "theHamsta/nvim-dap-virtual-text",
    --        "rcarriga/nvim-dap-ui",
    --        "mfussenegger/nvim-dap-python",
    --        "nvim-telescope/telescope-dap.nvim",
    --        { "leoluz/nvim-dap-go", module = "dap-go" },
    --        { "jbyuki/one-small-step-for-vimkind", module = "osv" },
    --    },
    --    config = function()
    --        require("config.dap").setup()
    --    end,
    }

    -- Package UI> IDE> CORE> DAP> Mejora de UI para nVim-DAP
    --  Texto que ayuda a ver los valores de las variables
    use {
        'theHamsta/nvim-dap-virtual-text',
        opt=true
    }

    -- Package UI> IDE> CORE> DAP> Mejora de UI para nVim-DAP
    --  Mejora algunos mejoras de iconos de nVim-DAP
    use {
        'rcarriga/nvim-dap-ui',
        opt=true,
        requires = { "mfussenegger/nvim-dap" }
    }

    -- Package UI> IDE> CORE> DAP> Mejora de UI para nVim-DAP
    --  Integra Telescope con nVim-DAP
    use {
        'nvim-telescope/telescope-dap.nvim',
        opt=true
    }


end)

--###################################################################################
-- Configuracion de basica despues de la carga automatica de paquetes Neovim 
--   - Antes de establecer el 'Color Schema'
--###################################################################################

--https://github.com/folke/tokyonight.nvim#%EF%B8%8F-configuration
