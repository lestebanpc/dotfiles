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



--------------------------------------------------------------------------------------------------
-- Tool> REST Client 'Kulala'
--------------------------------------------------------------------------------------------------
--
-- > URL: https://github.com/mistweaverco/kulala.nvim
--        https://neovim.getkulala.net/docs/getting-started
-- > Si se usa CoC, no funcionara el autocomletado si no se configura un cio para su cliente LSP
--


-- 01. Asociando el filtetype al una extension
--     Similar al siuguiente autocomando vim
--        augroup kulala_filetype_detect
--          autocmd!
--          autocmd BufRead,BufNewFile *.http set filetype=http
--          autocmd BufRead,BufNewFile *.rest set filetype=rest
--        augroup END

vim.filetype.add({
  extension = {
    ['http'] = 'http',
    --['rest'] = 'rest',
  },
})


-- 02. Configuracion (https://neovim.getkulala.net/docs/getting-started/configuration-options)
local kulala_mod = require("kulala")

kulala_mod.setup({

    -- Keymapping global y del filetype 'http' y 'rest'
    -- Vease: https://github.com/mistweaverco/kulala.nvim/blob/main/lua/kulala/config/keymaps.lua
    global_keymaps_prefix = "<leader>r",

    global_keymaps = true,
    --global_keymaps = {

    --    -- Keymapping global
    --    ["Open scratchpad"] = {
    --      "b", function() kulala_mod.scratchpad()  end,
    --    },

    --    ["Open kulala"] = {
    --      "o", function() kulala_mod.open() end,
    --    },

    --    ["Send request"] = {
    --      "s", function() kulala_mod.run() end, mode = { "n", "v" },
    --    },

    --    ["Send all requests"] = {
    --      "a", function() kulala_mod.run_all() end, mode = { "n", "v" },
    --    },

    --    ["Replay the last request"] = {
    --      "r", function() kulala_mod.replay() end,
    --    },

    --    -- Keymapping asociado al filetype 'http' y 'rest'
    --    ["Close window"] = {
    --      "q", function() kulala_mod.close() end, ft = { "http", "rest" },
    --    },

    --    ["Copy as cURL"] = {
    --      "c", function() kulala_mod.copy() end, ft = { "http", "rest" },
    --    },

    --    ["Paste from curl"] = {
    --      "C", function() kulala_mod.from_curl() end, ft = { "http", "rest" },
    --    },

    --    ["Inspect current request"] = {
    --      "i", function() kulala_mod.inspect() end, ft = { "http", "rest" },
    --    },

    --    ["Select environment"] = {
    --      "e", function() kulala_mod.set_selected_env() end, ft = { "http", "rest" },
    --    },

    --    ["Manage Auth Config"] = {
    --      "u", function() require("kulala.ui.auth_manager").open_auth_config() end, ft = { "http", "rest" },
    --    },

    --    ["Send request <cr>"] = {
    --      "<CR>", function() kulala_mod.run() end, mode = { "n", "v" }, ft = { "http", "rest" }, prefix = false,
    --    },

    --    ["Download GraphQL schema"] = {
    --      "g", function() kulala_mod.download_graphql_schema() end, ft = { "http", "rest" },
    --    },

    --    ["Jump to next request"] = {
    --      "n", function() kulala_mod.jump_next() end, ft = { "http", "rest" },
    --    },

    --    ["Jump to previous request"] = {
    --      "p", function() kulala_mod.jump_prev() end, ft = { "http", "rest" },
    --    },

    --    ["Find request"] = {
    --      "f", function() kulala_mod.search() end, ft = { "http", "rest" },
    --    },

    --    ["Toggle headers/body"] = {
    --      "t", function() kulala_mod.toggle_view() end, ft = { "http", "rest" },
    --    },

    --    ["Show stats"] = {
    --      "S", function() kulala_mod.show_stats() end, ft = { "http", "rest" },
    --    },

    --    ["Clear globals"] = {
    --      "x", function() kulala_mod.scripts_clear_global() end, ft = { "http", "rest" },
    --    },

    --    ["Clear cached files"] = {
    --      "X", function() kulala_mod.clear_cached_files() end, ft = { "http", "rest" },
    --    },
    --},

    -- Keymapping asicaido popup 'Kulala UI'
    -- Vease: https://github.com/mistweaverco/kulala.nvim/blob/main/lua/kulala/config/keymaps.lua
    kulala_keymaps_prefix = "",

    kulala_keymaps = true,
    --kulala_keymaps = {

    --    ["Show headers"] = {
    --      "H", function() require("kulala.ui").show_headers() end,
    --    },

    --    ["Show body"] = {
    --      "B", function() require("kulala.ui").show_body() end,
    --    },

    --    ["Show headers and body"] = {
    --      "A", function() require("kulala.ui").show_headers_body() end,
    --    },

    --    ["Show verbose"] = {
    --      "V", function() require("kulala.ui").show_verbose() end,
    --    },

    --    ["Show script output"] = {
    --      "O", function() require("kulala.ui").show_script_output() end,
    --    },

    --    ["Show stats"] = {
    --      "S", function() require("kulala.ui").show_stats() end,
    --    },

    --    ["Show report"] = {
    --      "R", function() require("kulala.ui").show_report() end,
    --    },

    --    ["Show filter"] = {
    --      "F", function() require("kulala.ui").toggle_filter() end,
    --    },

    --    ["Next response"] = {
    --      "]", function() require("kulala.ui").show_next() end, prefix = false,
    --    },

    --    ["Previous response"] = {
    --      "[", function() require("kulala.ui").show_previous() end, prefix = false,
    --    },

    --    ["Jump to response"] = {
    --      "<CR>", function() require("kulala.ui").keymap_enter() end, mode = { "n", "v" },
    --      desc = "also: Update filter and Send WS message for WS connections", prefix = false,
    --    },

    --    ["Clear responses history"] = {
    --      "X", function() require("kulala.ui").clear_responses_history() end,
    --    },

    --    ["Send WS message"] = {
    --      "<S-CR>", function() require("kulala.cmd.websocket").send() end, mode = { "n", "v" }, prefix = false,
    --    },

    --    ["Interrupt requests"] = {
    --      "<C-c>", function()  require("kulala.ui").interrupt_requests() end,
    --      desc = "also: CLose WS connection", prefix = false,
    --    },

    --    ["Show help"] = {
    --      "?", function() require("kulala.ui").show_help() end, prefix = false,
    --    },

    --    ["Show news"] = {
    --      "g?", function() require("kulala.ui").show_news() end, prefix = false,
    --    },

    --    ["Close"] = {
    --      "q", function() require("kulala.ui").close_kulala_buffer() end, prefix = false,
    --    },

    --},


})
