--------------------------------------------------------------------------------------------------
-- Diagnostic> Confioguracion general
--------------------------------------------------------------------------------------------------

local codes = {
    -- Lua
    no_matching_function = {
      message = " Can't find a matching function",
      "redundant-parameter",
      "ovl_no_viable_function_in_call",
    },
    empty_block = {
      message = " That shouldn't be empty here",
      "empty-block",
    },
    missing_symbol = {
      message = " Here should be a symbol",
      "miss-symbol",
    },
    expected_semi_colon = {
      message = " Please put the `;` or `,`",
      "expected_semi_declaration",
      "miss-sep-in-table",
      "invalid_token_after_toplevel_declarator",
    },
    redefinition = {
      message = " That variable was defined before",
      icon = " ",
      "redefinition",
      "redefined-local",
      "no-duplicate-imports",
      "@typescript-eslint/no-redeclare",
      "import/no-duplicates"
    },
    no_matching_variable = {
      message = " Can't find that variable",
      "undefined-global",
      "reportUndefinedVariable",
    },
    trailing_whitespace = {
      message = " Whitespaces are useless",
      "trailing-whitespace",
      "trailing-space",
    },
    unused_variable = {
      message = " Don't define variables you don't use",
      icon = " ",
      "unused-local",
      "@typescript-eslint/no-unused-vars",
      "no-unused-vars"
    },
    unused_function = {
      message = " Don't define functions you don't use",
      "unused-function",
    },
    useless_symbols = {
      message = " Remove that useless symbols",
      "unknown-symbol",
    },
    wrong_type = {
      message = " Try to use the correct types",
      "init_conversion_failed",
    },
    undeclared_variable = {
      message = " Have you declared that variable somewhere?",
      "undeclared_var_use",
    },
    lowercase_global = {
      message = " Should that be a global? (if so make it uppercase)",
      "lowercase-global",
    },
    -- Typescript
    no_console = {
      icon = " ",
      "no-console",
    },
    -- Prettier
    prettier = {
      icon = " ",
      "prettier/prettier"
    }
}

--1. Signos (iconos/simbolos) usuados para el diagnostivo (deprecated)
--    En NeoVim <= 0.9.5, se usa 'vim.fn.sign_define()'
--    En NeoVim >= 0.10, se usa 'vim.diagnostic.config()'
--
--vim.fn.sign_define('DiagnosticSignError', { text = '✘', texthl = 'DiagnosticSignError', numhl = '' })
--vim.fn.sign_define('DiagnosticSignWarn',  { text = '▲', texthl = 'DiagnosticSignWarn', numhl = '' })
--vim.fn.sign_define('DiagnosticSignHint',  { text = '⚑', texthl = 'DiagnosticSignHint', numhl = '' })
--vim.fn.sign_define('DiagnosticSignInfo',  { text = '', texthl = 'DiagnosticSignInfo', numhl = '' })
--vim.fn.sign_define('DiagnosticSignInfo',  { text = '', texthl = 'DiagnosticSignInfo', numhl = '' })


--2. Autocomando (evento) cuando se ingresa al modo insert y se sale del modo insert)
--    Desabilitar el diganostico en el modo inserción
vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = {'n:i', 'v:s'},
    desc = 'Disable diagnostics in insert and select mode',
    callback = function(e) vim.diagnostic.disable(e.buf) end,
})

vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = 'i:n',
    desc = 'Enable diagnostics when leaving insert mode',
    callback = function(e) vim.diagnostic.enable(e.buf) end,
})


--3. Configuración global de diagnósticos
vim.diagnostic.config({

    --Muestra mensaje de diagnóstico eb 'virtual text' al final de la línea.
    --virtual_text = {
    --    source = 'always',     --Si es 'always' siempre se muestra la fuente de diagnóstico 'always'
    --                           --Si es 'if_many' solo se muestra la fuente si existe mas de uno.
    --    prefix = '●',          --Establece el carácter que precede al texto virtual
    --},

    -- Mostrar mensaje del diagnosito en 'virtual lines' (NeoVim >= 0.11)
    -- https://gpanders.com/blog/whats-new-in-neovim-0-11/#virtual-lines
    virtual_lines = true,

    --Subrayar la localización de un diagnóstico.
    underline = true,

    --Actualizar los diagnósticos mientras se edita el documento en modo de inserción.
    update_in_insert = false,

    --Ordenar los diagnósticos de acuerdo a su prioridad.
    severity_sort = true,

    --Mostrar un "signo" en la línea donde hay un diagnóstico presente.
    signs = {

        -- Signo que se muestra segun la severidad del diagnostivo
        text = {
            [vim.diagnostic.severity.ERROR] = '✘',
            [vim.diagnostic.severity.WARN] = '',
            [vim.diagnostic.severity.HINT] = '⚑',
            [vim.diagnostic.severity.INFO] = '»',
        },

        -- Hihgligth group asociado a la linea de texto donde ocurre la severidad
        linehl = {
            [vim.diagnostic.severity.ERROR] = "ErrorMsg",
        },

        -- Hihgligth group asociado al la linea de la columna de numero donde ocurre la severidad
        numhl = {
            [vim.diagnostic.severity.WARN] = "WarningMsg",
        },
    },



    --Habilitar ventanas flotantes para mostrar los mensajes de diagnósticos.
    float = {
        border = 'rounded',
        source = 'always',     -- 'always' o 'if_many'
        --header = '',
        --prefix = '',
        --format = function(diagnostic)
        --    local code = diagnostic.user_data.lsp.code
        --
        --    if not diagnostic.source or not code then
        --        return string.format('%s', diagnostic.message)
        --    end

        --    if diagnostic.source == 'eslint' then
        --        for _, table in pairs(codes) do
        --            if vim.tbl_contains(table, code) then
        --                return string.format('%s [%s]', table.icon .. diagnostic.message, code)
        --            end
        --        end

        --        return string.format('%s [%s]', diagnostic.message, code)
        --    end

        --    for _, table in pairs(codes) do
        --        if vim.tbl_contains(table, code) then
        --            return table.message
        --        end
        --    end
        --    return string.format('%s [%s]', diagnostic.message, diagnostic.source)
        --end
    },
})

--3. Mostar el popup de diagnostics de la linea actual cuando el prompt esta sobre la palabra con error de diagnóstico.
--   ¿No usarlo, usar mejor lo definido a nivel cuando se vincula al LSP server?
--vim.cmd [[autocmd! CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]


--------------------------------------------------------------------------------------------------
-- UI Personalization> Mostrar Lightbulb
--------------------------------------------------------------------------------------------------

--1. Configurar Lightbulb (kosayoda/nvim-lightbulb)
require('nvim-lightbulb').setup({
    -- LSP client names to ignore
    -- Example: {"sumneko_lua", "null-ls"}
    ignore = {},
    sign = {
        enabled = true,
        -- Priority of the gutter sign
        priority = 10,
    },
    float = {
        enabled = false,
        -- Text to show in the popup float
        text = "💡",
        -- Available keys for window options:
        -- - height     of floating window
        -- - width      of floating window
        -- - wrap_at    character to wrap at for computing height
        -- - max_width  maximal width of floating window
        -- - max_height maximal height of floating window
        -- - pad_left   number of columns to pad contents at left
        -- - pad_right  number of columns to pad contents at right
        -- - pad_top    number of lines to pad contents at top
        -- - pad_bottom number of lines to pad contents at bottom
        -- - offset_x   x-axis offset of the floating window
        -- - offset_y   y-axis offset of the floating window
        -- - anchor     corner of float to place at the cursor (NW, NE, SW, SE)
        -- - winblend   transparency of the window (0-100)
        win_opts = {},
    },
    virtual_text = {
        enabled = false,
        -- Text to show at virtual text
        text = "💡",
        -- highlight mode to use for virtual text (replace, combine, blend), see :help nvim_buf_set_extmark() for reference
        hl_mode = "replace",
    },
    status_text = {
        enabled = false,
        -- Text to provide when code actions are available
        text = "💡",
        -- Text to provide when no actions are available
        text_unavailable = ""
    },
    autocmd = {
        enabled = false,
        -- see :help autocmd-pattern
        pattern = {"*"},
        -- see :help autocmd-events
        events = {"CursorHold", "CursorHoldI"}
    }
})

--2. Mostrar el Lightbulb cuando ocurre el evento (autocomando): el prompt esta en la palabra
--   cuando existe un 'Code Action'
--TODO se configura para todos los 'file type', se puede especificar solo para algunos lenguajes?
vim.cmd [[autocmd CursorHold,CursorHoldI * lua require('nvim-lightbulb').update_lightbulb()]]
