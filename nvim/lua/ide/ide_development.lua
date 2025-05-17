------------------------------------------------------------------------------------------------
-- IDE > Treesitter (ofrerce un AST)
------------------------------------------------------------------------------------------------
--
-- URL        : https://github.com/nvim-treesitter/nvim-treesitter
-- Submodulos :
--     https://github.com/nvim-treesitter/nvim-treesitter-textobjects
--     https://github.com/nvim-treesitter/nvim-treesitter-context
-- Treesitter como un analizador del arbol sinstanctico de codigo (AST) el cual permite:
--  - Resaltado de sintaxis de codigo (highlighting)
--  - Navegar y selecionar objetos del arbol AST.
--  - Indentación automática mejorada.
--  - Incremental selection (seleccionar nodos de sintaxis con combinaciones de teclas).
--  - Folding basado en estructura sintáctica.
--

local treesitter_cfg = require("nvim-treesitter.configs")

treesitter_cfg.setup({

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

    -- Enable syntax highlighting
    highlight = {
        enable = true
    },

    -- Enable indentation
    indent = {
        enable = true
    },

    -- Habilitar acciones para el 'Smart selection' de nodos del AST
    -- Se permite incremantar la selección ('Expand Selection') y reducir la selección ('Shrink Selection')
    incremental_selection = {
        enable = true,
        keymaps = {
            -- Accion de modo NORMAL :
            init_selection = "<C-space>",
            -- Acciones del modo VISUAL :
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
        },
    },

    -- Configuracion del modulo de navigacion de objetos de TreeSitter (submodulos 'nvim-treesitter-textobjects')
    -- > Listado de objetos soportados segun lenguajes:
    --   https://github.com/nvim-treesitter/nvim-treesitter-textobjects#built-in-textobjects
    textobjects = {

        -- Habilitar en la selección o operaciones de un rango de texto asociado a un nodo del AST.
        -- > Las acciones para seleccionar un rango de texto son del modo visual (v + keymap).
        -- > Las acciones como delete, change y yank del rango de texto son del submodo 'operator-pending' del modo normal:
        --   > Delete   : d + keymap
        --   > Change   : c + keymap
        --   > Yank     : y + keymap
        --
        select = {
            enable = true,

            -- Si no este dentro del objeto, busca el siguiente mas cercadno (similar to targets.vim)
            lookahead = true,

            keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ["a="] = { query = "@assignment.outer", desc = "Select outer part of an assignment" },
                ["i="] = { query = "@assignment.inner", desc = "Select inner part of an assignment" },
                ["l="] = { query = "@assignment.lhs", desc = "Select left hand side of an assignment" },
                ["r="] = { query = "@assignment.rhs", desc = "Select right hand side of an assignment" },

                ["aa"] = { query = "@parameter.outer", desc = "Select outer part of a parameter/argument" },
                ["ia"] = { query = "@parameter.inner", desc = "Select inner part of a parameter/argument" },

                ["ai"] = { query = "@conditional.outer", desc = "Select outer part of a conditional" },
                ["ii"] = { query = "@conditional.inner", desc = "Select inner part of a conditional" },

                ["al"] = { query = "@loop.outer", desc = "Select outer part of a loop" },
                ["il"] = { query = "@loop.inner", desc = "Select inner part of a loop" },

                ["af"] = { query = "@call.outer", desc = "Select outer part of a function call" },
                ["if"] = { query = "@call.inner", desc = "Select inner part of a function call" },

                ["am"] = { query = "@function.outer", desc = "Select outer part of a method/function definition" },
                ["im"] = { query = "@function.inner", desc = "Select inner part of a method/function definition" },

                ["ac"] = { query = "@class.outer", desc = "Select outer part of a class" },
                ["ic"] = { query = "@class.inner", desc = "Select inner part of a class" },
            },
        },

        -- Intercambiar la posición de nodos actual respecto al nodo anterior o siguiente nodo.
        -- Acciones del modo NORMAL.
        swap = {
            enable = true,
            swap_next = {
                -- swap parameters/argument with next
                ["<space>na"] = "@parameter.inner",
                -- swap function with next
                ["<space>nm"] = "@function.outer",
            },
            swap_previous = {
                -- swap parameters/argument with prev
                ["<space>pa"] = "@parameter.inner",
                -- swap function with previous
                ["<space>pm"] = "@function.outer",
            },
        },

        -- Navegar/Moverse entre nodos especiales del AST
        -- Acciones del modo NORMAL.
        move = {
            enable = true,

            -- Permite adicionar los jumps al jumplist de VIM. Ello permite avanzar y retroceder a través de ellos
            -- usuando con <C-o>(atrás) y <C-i> (adelante).
            set_jumps = true,

            goto_next_start = {
                ["]f"] = { query = "@call.outer", desc = "Next function call start" },
                ["]m"] = { query = "@function.outer", desc = "Next method/function def start" },
                ["]c"] = { query = "@class.outer", desc = "Next class start" },
                ["]i"] = { query = "@conditional.outer", desc = "Next conditional start" },
                ["]l"] = { query = "@loop.outer", desc = "Next loop start" },

                -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
                -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
                ["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
                ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
            },
            goto_next_end = {
                ["]F"] = { query = "@call.outer", desc = "Next function call end" },
                ["]M"] = { query = "@function.outer", desc = "Next method/function def end" },
                ["]C"] = { query = "@class.outer", desc = "Next class end" },
                ["]I"] = { query = "@conditional.outer", desc = "Next conditional end" },
                ["]L"] = { query = "@loop.outer", desc = "Next loop end" },
            },
            goto_previous_start = {
                ["[f"] = { query = "@call.outer", desc = "Prev function call start" },
                ["[m"] = { query = "@function.outer", desc = "Prev method/function def start" },
                ["[c"] = { query = "@class.outer", desc = "Prev class start" },
                ["[i"] = { query = "@conditional.outer", desc = "Prev conditional start" },
                ["[l"] = { query = "@loop.outer", desc = "Prev loop start" },
            },
            goto_previous_end = {
                ["[F"] = { query = "@call.outer", desc = "Prev function call end" },
                ["[M"] = { query = "@function.outer", desc = "Prev method/function def end" },
                ["[C"] = { query = "@class.outer", desc = "Prev class end" },
                ["[I"] = { query = "@conditional.outer", desc = "Prev conditional end" },
                ["[L"] = { query = "@loop.outer", desc = "Prev loop end" },
            },
        },
    },
})

-- Permitir repitir el ultimo moviento de objeto realizado
local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

vim.keymap.set({ "n", "x", "o" }, ';', ts_repeat_move.repeat_last_move_next)
vim.keymap.set({ "n", "x", "o" }, '\\', ts_repeat_move.repeat_last_move_previous)


-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
--vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
--vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
--vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
--vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })



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
    -- Completition y Popup de 'Signature Help'
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
