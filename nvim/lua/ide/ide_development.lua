------------------------------------------------------------------------------------------------
-- IDE > Treesitter > Show Context
------------------------------------------------------------------------------------------------
--
-- URL : https://github.com/nvim-treesitter/nvim-treesitter-context
--


local treesitter_ctx = require("treesitter-context")

treesitter_ctx.setup({

    -- Enable this plugin (Can be enabled/disabled later via commands)
    enable = true,

    -- Enable multiwindow support.
    --multiwindow = false,

    -- How many lines the window should span. Values <= 0 mean no limit.
    --max_lines = 0,

    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
    --min_window_height = 0,

    --line_numbers = true,

    -- Maximum number of lines to show for a single context
    --multiline_threshold = 20,

    -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    --trim_scope = 'outer',

    -- Line used to calculate context. Choices: 'cursor', 'topline'
    --mode = 'cursor',

    -- Separator between context and content. Should be a single character string, like '-'.
    -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
    --separator = nil,

    -- The Z-index of the context window
    --zindex = 20,

    -- Callback de tipo 'fun(buf: integer): boolean'. Si retorna false para desabilitar el attaching.
    --on_attach = nil,
})

-- Moverse al inicio del contexto
--vim.keymap.set("n", "[c", function()
--    require("treesitter-context").go_to_context(vim.v.count1)
--end, { silent = true })




--Si se no usas COC
if vim.g.use_coc == false then

    -----------------------------------------------------------------------------------------------
    -- Configuracion inicial del LSP Client nativo (Keymapping y otros)
    -----------------------------------------------------------------------------------------------

    require('ide.native_lsp')


    -----------------------------------------------------------------------------------------------
    -- Completion y Popup de 'Signature Help'
    -----------------------------------------------------------------------------------------------

    require('ide.completion')


    -----------------------------------------------------------------------------------------------
    -- Diagnostic (incluyendo un Lightbulb)
    -----------------------------------------------------------------------------------------------

    require('ide.diagnostic')


    -----------------------------------------------------------------------------------------------
    -- Adaptadores LSP
    -----------------------------------------------------------------------------------------------

    -- Configuraciones del cliente LSP usando adapatadores de 'lspconfig' o custom
    require('ide.adapters.lsp_basics')

    -- Configuraciones del cliente LSP usando adaptadores creados por un plugin
    require('ide.adapters.lsp_plugins')


end



--------------------------------------------------------------------------------------------------
-- UI> Aerial (Code Outline)
--------------------------------------------------------------------------------------------------
--
-- URL: https://github.com/stevearc/aerial.nvim
--

-- 01. Configuracion
require("aerial").setup({

    -- Priority list of preferred backends for aerial.
    -- This can be a filetype map (see :help aerial-filetype-map)
    backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },

    -- Jump to symbol in source window when the cursor moves
    autojump = false,

     -- When true, aerial will automatically close after jumping to a symbol
    close_on_select = false,

    -- The autocmds that trigger symbols update (not used for LSP backend)
    --update_events = "TextChanged,InsertLeave",

    -- Use symbol tree for folding. Set to true or false to enable/disable
    -- Set to "auto" to manage folds if your previous foldmethod was 'manual'
    -- This can be a filetype map (see :help aerial-filetype-map)
    --manage_folds = false,

    -- When you fold code with za, zo, or zc, update the aerial tree as well.
    -- Only works when manage_folds = true
    --link_folds_to_tree = false,

    -- Fold code when you open/collapse symbols in the tree.
    -- Only works when manage_folds = true
    --link_tree_to_folds = true,

    -- Automatically open aerial when entering supported buffers.
    -- This can be a function (see :help aerial-open-automatic)
    --open_automatic = false,

    -- Run this command after jumping to a symbol (false will disable)
    --post_jump_cmd = "normal! zz",


    -- Set default symbol icons to use patched font icons (see https://www.nerdfonts.com/)
    -- "auto" will set it to true if nvim-web-devicons or lspkind-nvim is installed.
    nerd_font = "auto",

    -- Define symbol icons. You can also specify "<Symbol>Collapsed" to change the
    -- icon when the tree is collapsed at that symbol, or "Collapsed" to specify a
    -- default collapsed icon. The default icon set is determined by the
    -- "nerd_font" option below.
    -- If you have lspkind-nvim installed, it will be the default icon set.
    -- This can be a filetype map (see :help aerial-filetype-map)
    --icons = {},

    -- Show box drawing characters for the tree hierarchy
    --show_guides = false,

    -- Customize the characters used when show_guides = true
    --guides = {
    --    -- When the child item has a sibling below it
    --    mid_item = "├─",
    --    -- When the child item is the last in the list
    --    last_item = "└─",
    --    -- When there are nested child guides to the right
    --    nested_top = "│ ",
    --    -- Raw indentation
    --    whitespace = "  ",
    --},

    -- Call this function when aerial attaches to a buffer.
    --on_attach = function(bufnr)
    --    --
    --    -- Buffer Keymappings
    --    --
    --    -- Jump forwards/backwards with '{' and '}'
    --    vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
    --    vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
    --    vim.keymap.set("n", "g", "<cmd>AerialGo<CR>", { buffer = bufnr })
    --end,

})

-- 02. Keymappings globales

-- Mostrar/cerrar el 'Code Outline' (esquema de codigo) del buffer actual.
vim.keymap.set("n", "<space>co", "<cmd>AerialToggle!<CR>", { noremap=true, silent=true, desc = "Toggle Code Outline" })

-- Navegacion en los  simbolo del buffer actual e ir a este.
vim.keymap.set("n", "<space>s2", "<cmd>AerialNavToggle<CR>", { noremap=true, silent=true, desc = "Toggle Code Navigator" })
