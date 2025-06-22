--------------------------------------------------------------------------------------------------
-- UI> Color Schema
--------------------------------------------------------------------------------------------------
--
-- > Tokionight
--   https://github.com/folke/tokyonight.nvim
--

local use_cs_tokyonight = true
if vim.g.colorschema_main == 'catppuccin' then
    use_cs_tokyonight = false
end

if use_cs_tokyonight then

    require("tokyonight").setup({

        -- The theme comes in three styles, `storm`, a darker variant `night` and `day`
        style = "night",

        -- Enable this to disable setting the background color
        transparent = false,

        -- Modificar la paleta de colores
        -- https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_storm.lua
        -- https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_night.lua
        -- https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_moon.lua
        -- https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_day.lua
        --on_colors = function(colors)
        --    colors.bg = "#0f0f0f"
        --end,

        -- Override specific highlights to use other groups or a hex color
        on_highlights = function(highlights, colors)

            -- Color de fondo del split actual
            highlights.Normal = { bg = "#0f0f0f" }

            -- Color de fondo del split 'no-current'
            highlights.NormalNC = { bg = "#171717" }

            -- Color del comentario
            --highlights.Comment = { fg = "#737a88", style = { "italic" }, }

        end,

    })

    -- Establecer el colorschema a usar
    vim.cmd("colorscheme tokyonight")

else

    -- Colores principales de 'highligh group' que se usaran para el tema oscuro
    local dark_hi_colors =  {
        -- Color de fondo del split actual
        Normal = { bg = "#0f0f0f" },

        -- Color de fondo del split 'no-current'
        NormalNC = { bg = "#171717" },

        -- Color de fondo del split actual
        --NormalFloat = { bg = "#171717" },

        -- Color de la columna de numero de linea
        --LineNr = { fg = "#000000" },
        --LineNrAbove  = { fg = "#737a88" },
        --LineNrBelow = { fg = "#737a88" },

        -- Color del fondo de la columna de sign al costado izquierdo del numero de linea
        --SignColumn = { bg = "#0f0f0f" },

        -- Color del comentario
        Comment = { fg = "#737a88", style = { "italic" }, },
        --Comment = { fg = "#7a7a7a", style = { "italic" }, },
        --Comment = { fg = "#5c6370", style = { "italic" }, },
    }


    require("catppuccin").setup({

        -- latte, frappe, macchiato, mocha
        flavour = "mocha",
        --flavour = "macchiato",
        --flavour = "frappe",

        -- Force no italic
        --no_italic = true,

        -- Sets terminal colors (e.g. `g:terminal_color_0`)
        --term_colors = true,

        -- Disables setting the background color.
        transparent_background = false,

        --color_overrides = {
        --    mocha = {
       	--        base = "#0f0f0f",
        --        --mantle = "#000000",
        --        --crust = "#000000",
        --    },
        --},

        highlight_overrides = {
            mocha = function(mocha)
                return dark_hi_colors
            end,
            macchiato = function(macchiato)
                return dark_hi_colors
            end,
            frappe = function(frappe)
                return dark_hi_colors
            end,
            latte = function(latte)
                return dark_hi_colors
            end,
        },


        integrations = {
            nvimtree = true,
            treesitter = true,
            aerial = true,
            fzf = true,
            cmp = true,
            dap = true,
            dap_ui = true,
            coc_nvim = vim.g.use_coc,
        },
    })

    -- Establecer el colorschema a usar
    vim.cmd("colorscheme catppuccin")

end

--------------------------------------------------------------------------------------------------
-- UI> StatusBar (LuaLine)
--------------------------------------------------------------------------------------------------
--
-- URL: https://github.com/nvim-lualine/lualine.nvim
--

--
-- Secciones personalzidas a usar
--
local sec_item_diagnostic = {
     'diagnostics',

     -- Table of diagnostic sources, available sources are:
     --   'nvim_lsp', 'nvim_diagnostic', 'nvim_workspace_diagnostic', 'coc', 'ale', 'vim_lsp'.
     -- or a function that returns a table as such:
     --   { error=error_cnt, warn=warn_cnt, info=info_cnt, hint=hint_cnt }
     sources = { 'nvim_diagnostic', 'ale' },

     -- Displays diagnostics for the defined severity types
     sections = { 'error', 'warn', 'info', 'hint' },

     diagnostics_color = {
        -- Same values as the general color option can be used here.
        error = 'DiagnosticError', -- Changes diagnostics' error color.
        warn  = 'DiagnosticWarn',  -- Changes diagnostics' warn color.
        info  = 'DiagnosticInfo',  -- Changes diagnostics' info color.
        hint  = 'DiagnosticHint',  -- Changes diagnostics' hint color.
     },
     symbols = { error = 'E', warn = 'W', info = 'I', hint = 'H'},
     colored = true,           -- Displays diagnostics status in color if set to true.
     update_in_insert = false, -- Update diagnostics in insert mode.
     always_visible = false,   -- Show diagnostics even if there are none.
}

--TODO como usar el diagnostico de ALE en LuaLina cuando ....

--
-- Confiugrar LuaLine
--
require('lualine').setup({
    options = {
        icons_enabled = true,
        theme = vim.g.colorschema_main,
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        disabled_filetypes = {
            statusline = {},
            winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        -- Establece 'statusline=3'
        globalstatus = true,
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
        }
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {
            {
                'filename',
                -- Displays file status (readonly status, modified status)
                file_status = true,

                -- Display new file status (new file means no write after created
                newfile_status = false,

                -- 0: Just the filename
                -- 1: Relative path
                -- 2: Absolute path
                -- 3: Absolute path, with tilde as the home directory
                -- 4: Filename and parent dir, with tilde as the home directory
                path = 3,
            }
        },
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {}
})


--------------------------------------------------------------------------------------------------
-- UI> BufferLine
--------------------------------------------------------------------------------------------------
--
-- URL: https://github.com/akinsho/bufferline.nvim/blob/main/doc/bufferline.txt
--

-- Opciones de configuracion para el plugin 'bufferline'
local bufferline_cfg = {

    -- Opciones del tema:
    options = {

        mode = "buffers",
        --separator_style = "slant",

    },

}

-- Modificar los colores segun el tema elegido (integracion con el tema de 'catppuccin')
if not use_cs_tokyonight then

    local mocha = require("catppuccin.palettes").get_palette("mocha")
    bufferline_cfg.highlights = require("catppuccin.groups.integrations.bufferline").get({
        styles = { "italic", "bold" },
        custom = {
            all = {
                -- Color de fondo usado por LuaLine
                fill = { bg = "#181825" },
            },
            mocha = {
                background = { fg = mocha.text },
            },
            latte = {
                background = { fg = "#000000" },
            },
        },
    })

end

require("bufferline").setup(bufferline_cfg)


------------------------------------------------------------------------------------------------
-- UI> Explorer de archivos
------------------------------------------------------------------------------------------------

require("nvim-tree").setup({
    --hijack_cursor = false,
    --on_attach = function(bufnr)
    --    local bufmap = function(lhs, rhs, desc)
    --        vim.keymap.set('n', lhs, rhs, {buffer = bufnr, desc = desc})
    --    end

    --    local api = require('nvim-tree.api')

    --    bufmap('L', api.node.open.edit, 'Expand folder or go to file')
    --    bufmap('H', api.node.navigate.parent_close, 'Close parent folder')
    --    bufmap('gh', api.tree.toggle_hidden_filter, 'Toggle hidden files')
    --end
})

vim.keymap.set('n', '<leader>ee', '<cmd>NvimTreeToggle<cr>', { noremap=true, silent=true, desc = 'UI Toggle Tree Explorer' })


------------------------------------------------------------------------------------------------
-- UI> FZF (FuZzy Finder)
------------------------------------------------------------------------------------------------

local fzf_lua= require("fzf-lua")
local actions= require("fzf-lua").actions

fzf_lua.setup({
    winopts = {
        width  = 0.99,
        height = 0.80,
        border = "none",
        preview = {
            --Use fzf native previewers (not use 'neovim floating window' in order to support tmux)
            default        = "bat",
        }
    },
    fzf_opts= {
        ["--ansi"]           = true,
        ["--border"]         = "rounded",
        ["--no-separator"]   = "",
        ["--info"]           = "inline-right",
        ["--layout"]         = "reverse",
        ["--highlight-line"] = true,
        ["--tmux"]           = "center,99%,80%"
    },
    fzf_colors= {
        true,
        --["bg"]      = { "bg", "Normal" },
        ["fg"]      = { "fg", "Normal" },
        --["border"]  = { "fg", "Normal" },
    },
    files = {
        actions = {
            ["enter"]   = actions.file_edit,
        },
    },
    --Use fzf native previewers (not use 'neovim floating window' in order to support tmux)
    manpages = { previewer = "man_native" },
    helptags = { previewer = "help_native" },
    tags = { previewer = "bat_async" },
    btags = { previewer = "bat_async" },

    lsp = {
        code_actions = {
            previewer = "codeaction_native",
        },
    },
})


--Busqueda de archivos del proyecto usando busqueda difuso 'ripgrep'.
vim.keymap.set('n', '<leader>ff', ':lua require("fzf-lua").grep_project()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>fw', ':lua require("fzf-lua").grep_cword()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>fW', ':lua require("fzf-lua").grep_cWORD()<CR>', { noremap = true, silent = true })

--Listar, Selexionar/Examinar e Ir al buffer
vim.keymap.set('n', '<leader>bb', ':lua require("fzf-lua").buffers()<CR>', { noremap = true, silent = true })

--Listar archivos del proyecto, Seleccionar/Examinar e Ir
vim.keymap.set('n', '<leader>ll', ':lua require("fzf-lua").files({ cwd_prompt = true })<CR>', { noremap = true, silent = true })

--Listar archivos del 'Git Files', Seleccionar/Examinar e Ir
vim.keymap.set('n', '<leader>lg', ':lua require("fzf-lua").git_files()<CR>', { noremap = true, silent = true })

--Listar archivos del 'Git Status Files', Seleccionar/Examinar e Ir
vim.keymap.set('n', '<leader>ls', ':lua require("fzf-lua").git_status()<CR>', { noremap = true, silent = true })

--Listar comandos VIM, seleccionar y ejecutar
vim.keymap.set('n', '<leader>lc', ':lua require("fzf-lua").commands()<CR>', { noremap = true, silent = true })

--Listar las marcas (marks), seleccionar e ir
vim.keymap.set('n', '<leader>lm', ':lua require("fzf-lua").marks()<CR>', { noremap = true, silent = true })

--Listar los saltos (jumps), seleccionar e ir
vim.keymap.set('n', '<leader>lj', ':lua require("fzf-lua").jumps()<CR>', { noremap = true, silent = true })

--Recomendaciones del uso de tags:
-- - Regenerar los tags cuando realiza cambios ejecutando 'ctags -R' en el folder root del proyecto.
-- - Crear archivos 'option files' dentro del proyecto (ubicados usualmente carpata './.ctags.d/'),
--   donde defina las opciones por defecto cuando se ejecuta 'ctags', por ejemplo, coloque los archivos
--   y carpetas de exclusiion.

--Listar todos los tags del proyecto. (Si no se encuenta el archivo tags, lo genera usando 'ctags -R')
vim.keymap.set('n', '<leader>lT', ':lua require("fzf-lua").tags()<CR>', { noremap = true, silent = true })

--Listar los tags (generados por ctags) del buffer actual, seleccionar e ir
vim.keymap.set('n', '<leader>lt', ':lua require("fzf-lua").btags()<CR>', { noremap = true, silent = true })


--Listar help tags de vim (archivos de ayuda de vim)
vim.keymap.set('n', '<leader>lh', ':lua require("fzf-lua").helptags()<CR>', { noremap = true, silent = true })



--Remplazar el "vim.ui.select" por defecto de NeoVIM
fzf_lua.register_ui_select()
