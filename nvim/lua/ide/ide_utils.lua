
------------------------------------------------------------------------------------------------
-- IDE Utils> Libreria Plenary
------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------
-- IDE Utils> Nvim-treesitter (Resaltador de sintexis o semantica)
------------------------------------------------------------------------------------------------

local treesitter=require("nvim-treesitter.configs")

treesitter.setup({

    -- A list of parser names (the listed parsers MUST always be installed)
    ensure_installed = { 
        "html", "css", "javascript", "jq", "json", "yaml", "xml", 
        "toml", "typescript", "latex", "proto", "make", "sql", 
        "vim", "vimdoc", "markdown", "markdown_inline",
        "bash", "c", "cpp", "lua", "java", "kotlin", " rust",
        "swift", "go", "c_sharp"
    },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    highlight = { 
        enable = true 
    },
})

