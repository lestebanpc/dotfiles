--------------------------------------------------------------------------------------------------
-- UI> Color Schema
--------------------------------------------------------------------------------------------------
--

if vim.g.main_theme == 'catppuccin' then

    require("catppuccin").setup({

        -- latte, frappe, macchiato, mocha
        flavour = "mocha",

        -- Force no italic
        no_italic = true,

        -- Sets terminal colors (e.g. `g:terminal_color_0`)
        --term_colors = true,

        -- Disables setting the background color.
        transparent_background = false,

        color_overrides = {
            mocha = {
       	        base = "#0f0f0f",
                --mantle = "#000000",
                --crust = "#000000",
            },
        },

        integrations = {
            nvimtree = true,
            treesitter = true,
            aerial = true,
            fzf = true,
            cmp = true,
            dap = true,
            dap_ui = true,
            --coc_nvim = true,
        },
    })

    -- The setup() must be called before loading
    vim.cmd.colorscheme "catppuccin"

end

--------------------------------------------------------------------------------------------------
-- UI> StatusBar (LuaLine)
--------------------------------------------------------------------------------------------------
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
        theme = vim.g.main_theme,
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
        lualine_c = {'filename'},
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

local mocha = require("catppuccin.palettes").get_palette("mocha")

require("bufferline").setup({

    -- Modificar los colores segun el tema elegido (no existe integration nativa como 'catppuccin')
    highlights = require("catppuccin.groups.integrations.bufferline").get({
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
    }),

    -- Opciones del tema:
    options = {

        mode = "buffers",
        --separator_style = "slant",

    }

})
