
--Si se usa COC
if (vim.g.use_coc_in_nvim == 1) then
    return
end

--------------------------------------------------------------------------------------------------
--Native LSP Client> Configuracion del protocolo LSP
--------------------------------------------------------------------------------------------------

--local protocol = require('vim.lsp.protocol')

--No esta funcionando ¿cuando se usa estos simbolos si no es el completado?
--protocol.CompletionItemKind = {
--  '', -- Text
--  '', -- Method
--  '', -- Function
--  '', -- Constructor
--  '', -- Field
--  '', -- Variable
--  '', -- Class
--  'ﰮ', -- Interface
--  '', -- Module
--  '', -- Property
--  '', -- Unit
--  '', -- Value
--  '', -- Enum
--  '', -- Keyword
--  '﬌', -- Snippet
--  '', -- Color
--  '', -- File
--  '', -- Reference
--  '', -- Folder
--  '', -- EnumMember
--  '', -- Constant
--  '', -- Struct
--  '', -- Event
--  'ﬦ', -- Operator
--  '', -- TypeParameter
--}


--------------------------------------------------------------------------------------------------
--Nativwe LSP Client> Configuracion de LSPConfig
--------------------------------------------------------------------------------------------------

--1. Logica que se ejecuta cuando el cliente LSP se vincula al servidor LSP.
--   > En Neovim > 0.7.2, se usa autocomando.
--   > Si usa Neovim <= 0.7.2, debera especificar en la configuración de cada LSP cliente,
--     especificando 'lspconfig.LSP_CLIENT.setup({ on_attach = .., capabilities = ..., settings = {...}})'
--     Donde:
--     > Una funcion 'on_attach' se debera especificar la logica que se ejecuta un cliente LSP
--       cuando se vincula a un servidor LSP.
--       local on_attach = function(client, bufnr)
--          ...
--       end
--     > Colección 'capabilities' donde se especifica las capacidades que debera soportar el servidor LSP
--       --Las capacidades de completado + por defecto de cliente LSP ('vim.lsp.protocol.make_client_capabilities()')
--       local capabilities = require('cmp_nvim_lsp').default_capabilities()
--
vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'Acciones LSP',
    callback = function(args)

        --local buffer = args.buf
        --local client = vim.lsp.get_client_by_id(args.data.client_id)
        local opts = { buffer = true, noremap = true }

        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Mostar informacion en un Popup
        -- ---------------------------------------------------------------------------------------------
        
        -- Muestra información sobre símbolo debajo/arriba del prompt actual
        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)

        -- Mostrar el popup de 'Signature Help' (se usara el key-mapping de 'ray-x/lsp_signature.nvim')
        -- esta opcion solo usa mapeo en modo edición y popup
        --vim.keymap.set('n', '<C-\\>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
        --vim.keymap.set('i', '<C-\\>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)

        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : "Navigation" a un "Location" especifico
        -- ---------------------------------------------------------------------------------------------
        
        -- 1. "Location" dentor del buffer


        -- 2. "Location" basado en el simbolo actual 

        -- > Ir a una definición
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)

        -- > Ir a declaración
        vim.keymap.set('n', 'gc', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)

        -- > Ir a la implementacion
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)

        -- > Ir a definición de tipo
        vim.keymap.set('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)

        -- > Listar referencias (incluyendo el declaraciones del simbolo)
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)


        -- 3. Listar, Seleccionar e Ir 

        -- > Listar, Seleccionar e Ir a un 'symbol' en el buffer.
        vim.keymap.set('n', '<Leader>ls', '<cmd>lua vim.lsp.buf.document_symbol()<cr>', opts)

        -- > Diagnostico: Listar, Seleccionar e Ir un diagnóstico (error y/o warning) del workspace (Telescope)
        vim.keymap.set('n', '<Leader>ld', '<cmd>Telescope diagnostics<CR>', opts)

        -- > Diagnostico: Listar, Seleccionar e Ir a un diagnósticos de la línea actual
        vim.keymap.set('n', '<Leader>dl', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)

        -- > Diagnostico: Ir al siguiente diagnostico desde la posicion actual y dentro del buffer
        vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)

        -- > Diagnostico: Ir a la anterior diagnostico desde la posicion actual y dentro del buffer
        vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts)


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Formateo 
        -- ---------------------------------------------------------------------------------------------
        
        -- Formateo del codigo
        vim.keymap.set('n', '<Leader>cf', '<cmd>lua vim.lsp.buf.formatting()<cr>', opts)
        --Neovim 0.7 - timeout 2 segundos
        --vim.keymap.set('n', '<Leader>cf', '<cmd>lua vim.lsp.buf.formatting_sync(nil, 2000)<cr>', opts)
        --Neovim 0.8 - timeout 2 segundos
        --vim.keymap.set('n', '<Leader>cf', '<cmd>lua vim.lsp.buf.format({ timeout_ms = 2000 })<cr>', opts)

        -- Formateo del codigo de rango seleccionado
        vim.keymap.set('x', '<Leader>cf', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', opts)


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Workspace 
        -- ---------------------------------------------------------------------------------------------
        
        -- Acciones relacionados al 'Workspace' (proyecto)
        vim.keymap.set('n', '<Leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
        vim.keymap.set('n', '<Leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
        

        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Otros 
        -- ---------------------------------------------------------------------------------------------
        
        -- 'Code Actions' > Listar, Selecionar e Ir a 'Code Actions' disponibles en la posición del cursor
        vim.keymap.set('n', '<Leader>al', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
        --vim.keymap.set('x', '<Leader>ac', '<cmd>lua vim.lsp.buf.range_code_action()<cr>', opts)
        --vim.keymap.set('n', '<Leader>ac', '<cmd>lua vim.lsp.buf.range_code_action()<cr>', opts)

        -- Renombrar símbolo
        vim.keymap.set('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)

        
        -- ---------------------------------------------------------------------------------------------
        -- Otros
        -- ---------------------------------------------------------------------------------------------
        
        -- Resaltado de palabras similaras al actual (Highlight symbol under the prompt)
        -- TODO client es parametro de on_attach, ¿como obtengo este valor?
        --if client.resolved_capabilities.documentHighlightProvider then
        --    vim.cmd [[
        --        hi! LspReferenceRead cterm=bold ctermbg=235 guibg=LightYellow
        --        hi! LspReferenceText cterm=bold ctermbg=235 guibg=LightYellow
        --        hi! LspReferenceWrite cterm=bold ctermbg=235 guibg=LightYellow
        --    ]]
        --    vim.api.nvim_create_augroup('lsp_document_highlight', {})
        --    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        --        group = 'lsp_document_highlight',
        --        buffer = 0,
        --        callback = vim.lsp.buf.document_highlight,
        --    })
        --    vim.api.nvim_create_autocmd('CursorMoved', {
        --        group = 'lsp_document_highlight',
        --        buffer = 0,
        --        callback = vim.lsp.buf.clear_references,
        --    })
        --end

        -- Evento: Mostar el popup de diagnostics de la linea actual cuando el prompt
        --         esta sobre la palabra con error de diagnóstico.
        -- TODO client es parametro de bufnr, ¿como obtengo este valor?
        --vim.api.nvim_create_autocmd("CursorHold", {
        --    buffer = bufnr,
        --    callback = function()
        --        local opts_ = {
        --            focusable = false,
        --            close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        --            border = 'rounded',
        --            source = 'always',
        --            prefix = ' ',
        --            scope = 'cursor',
        --        }
        --        vim.diagnostic.open_float(nil, opts_)
        --    end
        --})


  end
})


--------------------------------------------------------------------------------------------------
--Native LSP Client> Personalización adicionales del LSP Client
--------------------------------------------------------------------------------------------------

--1. Handlers para manejar los eventos enviados por LSP server:
--   Modificar la configuración del "handler" de 'vim.lsp.buf.hover()' que muestra ventana flotante
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    { border = 'rounded' }
)

--  Modificar la configuración del "handler" de 'vim.lsp.buf.signature_help()' que muestra ventana flotante
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
    vim.lsp.handlers.signature_help,
    { border = 'rounded' }
)



--------------------------------------------------------------------------------------------------
--Completition> Configuración del Completado (Source: LSP, Snippets, Buffer, ...)
--------------------------------------------------------------------------------------------------

--1. Extendiendo las capacidad de autocompletado de LSPConfig: Usando la fuente CMP para LSP 
local lsp_config = require('lspconfig')
local cmp_lsp = require('cmp_nvim_lsp')

lsp_config.util.default_config.capabilities = vim.tbl_deep_extend(
    'force',
    lsp_config.util.default_config.capabilities,
    cmp_lsp.default_capabilities()
)

--2. Configurar el completado para todos los tipos de archivos
local cmp = require('cmp')
local snippet = require('luasnip')

--Cargar '.lazy_load()' las implementacion de snippet (por ejemplo 'friendly-snippets') que estan 'runtimepath'
--snippet.loaders.from_vscode.lazy_load()
require("luasnip.loaders.from_vscode").lazy_load()

--xxx
local select_opts = {behavior = cmp.SelectBehavior.Select}

cmp.setup({

    --Configuracion de los Snippets
    snippet = {
        --Expansion de un snippets
        expand = function(args)
                --Usar los snippets registros por LuaSnip para expnadirlos
                snippet.lsp_expand(args.body)    
            end
    },

    --Fuentes de completado: Se colocan los nombres con que registro la fuente en CMP
    --  'prioirity': orden en que aparecen las sugerencias en las lista de autocompletado
    --  'keyword_length': cantidad de caracteres necesarios realizar la busqueda en la fuente y mostrar el popup
    --  'trigger_characters': si esta antes de un caracter espcial, el lenght(keyword) = 0, pero  mostrar el popup
    sources = {
        { name = 'path' },
        { name = 'nvim_lsp' },
        --{ name = 'nvim_lsp', keyword_length = 3, trigger_characters = { '.', '[' } },
        --{ name = 'nvim_lsp', keyword_length = 3 },
        { name = 'buffer', keyword_length = 3 },
        { name = 'luasnip', keyword_length = 2 },
    },

    --Controla la apariencia de la ventana donde se muestra la documentación: usar bordes
    window = {
        documentation = cmp.config.window.bordered()
    },

    --Formateo de cada elemento del popup de completado
    formatting = {
        --Controla el orden en el que aparecen los elementos de un item.
        fields = {'menu', 'abbr', 'kind'},
        --Determina el formado del item
        format = function(entry, item)
                --Iconos de tipo de item
                local kind_icons = {
                    Class = "ﴯ",
                    Color = "",
                    Constant = "",
                    Constructor = "",
                    Enum = "",
                    EnumMember = "",
                    Event = "",
                    Field = "",
                    File = "",
                    Folder = "",
                    Function = "",
                    Interface = "",
                    Keyword = "",
                    Method = "",
                    Module = "",
                    Operator = "",
                    Property = "ﰠ",
                    Reference = "",
                    Snippet = "",
                    Struct = "",
                    Text = "",
                    TypeParameter = "",
                    Unit = "",
                    Value = "",
                    Variable = "",
                }
                
                --Mostrar tipo de elemento con su icono antepuesto (concetenadolo)
                item.kind = string.format("%s %s", kind_icons[item.kind], item.kind)

                --Icono por cada fuente de completado (los que no se encuentra, se mostraran en vacio)
                local menu_icons = {
                    nvim_lsp = 'λ',
                    luasnip = '',
                    buffer = '',
                    path = '',
                    nvim_lsp_signature_help = '',                
                }

                --Mostrar solo el icono (no se concatena el icono con el nombre)
                item.menu = menu_icons[entry.source.name]
                return item
        end,
    },

    --Reglas de busqueda con la que se encuentra un item del popup de completado
    --matching = {
    --    --Por defecto la busqueda es difusa y no una busqueda exacta.
    --    disallow_fuzzy_matching = false,
    --},

    --Atajos de teclado usado en el popup de completado
    mapping = {

        -- ----------------------------------------------------------------------------------
        -- Popup de completado
        -- ----------------------------------------------------------------------------------
        
        --Navegar entre los item (sugerencias) de completado mostrado en el popup
        ['<Up>'] = cmp.mapping.select_prev_item(select_opts),
        ['<Down>'] = cmp.mapping.select_next_item(select_opts),

        ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
        ['<C-n>'] = cmp.mapping.select_next_item(select_opts),
       
        --Desplazar el texto en el popup de documentación o preview
        ['<PageDown>'] = cmp.mapping.scroll_docs(-4),
        ['<PageUp>'] = cmp.mapping.scroll_docs(4),

        --Cancelar el completado (Cerrar el popup de completado)
        ['<C-e>'] = cmp.mapping.abort(),
        
        --Aceptar el completado
        ['<CR>'] = cmp.mapping.confirm({select = false}),
        ['<C-y>'] = cmp.mapping.confirm({select = false}),
        

        --Si se muestra el popup de completado (si la esta en un espacio, no se realiza el completado y escribe 'Tab')
        ['<Tab>'] = cmp.mapping(function(fallback)
                local col = vim.fn.col('.') - 1

                if cmp.visible() then
                    cmp.select_next_item(select_opts)
                elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                    fallback()
                else
                    cmp.complete()
                end
            end, {'i', 's'}),

        --Si se muestra el popup de completado, navega al item anterior
        ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item(select_opts)
                else
                    fallback()
                end
            end, {'i', 's'}),
        
        -- ----------------------------------------------------------------------------------
        -- Snippets
        -- ----------------------------------------------------------------------------------

        --Salta al siguente fragmento de snippet expnadido
        ['<C-f>'] = cmp.mapping(function(fallback)
                if snippet.jumpable(1) then
                    snippet.jump(1)
                else
                    fallback()
                end
            end, {'i', 's'}),

        --Salta al anterior fragmento de snippet expnadido
        ['<C-b>'] = cmp.mapping(function(fallback)
                if snippet.jumpable(-1) then
                    snippet.jump(-1)
                else
                    fallback()
                end
            end, {'i', 's'}),

        
    },
})


--3. Configurar el completado para un tipos de archivo especifico
--cmp.setup.filetype({ 'yourfiletype' }, {
--   -- Options here
--
--})


--------------------------------------------------------------------------------------------------
--Completition> Configuración del Popup de 'Signature Help'
--------------------------------------------------------------------------------------------------

local cfg = {
    debug = false,              -- set to true to enable debug logging
    log_path = vim.fn.stdpath("cache") .. "/lsp_signature.log", -- log dir when debug is on
                                                                -- default is  ~/.cache/nvim/lsp_signature.log
    verbose = false,            -- show debug line number
  
    bind = true,                -- This is mandatory, otherwise border config won't get registered.
                                -- If you want to hook lspsaga or other signature handler, pls set to false
    doc_lines = 10,             -- will show two lines of comment/doc(if there are more than two lines in doc, will be truncated);
                                -- set to 0 if you DO NOT want any API comments be shown
                                -- This setting only take effect in insert mode, it does not affect signature help in normal
                                -- mode, 10 by default
  
    max_height = 25,            -- max height of signature floating_window
    max_width = 130,             -- max_width of signature floating_window
    noice = false,              -- set to true if you using noice to render markdown
    wrap = true,                -- allow doc/signature text wrap inside floating_window, useful if your lsp return doc/sig is too long
    
    floating_window = true,     -- show hint in a floating window, set to false for virtual text only mode
  
    floating_window_above_cur_line = true,  -- try to place the floating above the current line when possible Note:
                                            -- will set to true when fully tested, set to false will use whichever side has more space
                                            -- this setting will be helpful if you do not want the PUM and floating win overlap
  
    floating_window_off_x = 1,  -- adjust float windows x position. 
                                -- can be either a number or function
    floating_window_off_y = 0,  -- adjust float windows y position. e.g -2 move window up 2 lines; 2 move down 2 lines
                                -- can be either number or function, see examples
  
    close_timeout = 4000,       -- close floating window after ms when laster parameter is entered
    fix_pos = false,            -- set to true, the floating window will not auto-close until finish all parameters
    hint_enable = true,         -- virtual hint enable
    hint_prefix = "📜 ",        -- Panda for parameter, NOTE: for the terminal not support emoji, might crash
    hint_scheme = "String",
    hi_parameter = "LspSignatureActiveParameter",   -- how your parameter will be highlight
    handler_opts = {
        border = "rounded"        -- double, rounded, single, shadow, none, or a table of borders
    },
  
    always_trigger = false,     -- sometime show signature on new line or in middle of parameter can be confusing, set it to false for #58
  
    auto_close_after = nil,     -- autoclose signature float win after x sec, disabled if nil.
    extra_trigger_chars = {},   -- Array of extra characters that will trigger signature completion, e.g., {"(", ","}
    zindex = 200,               -- by default it will be on top of all floating windows, set to <= 50 send it to bottom
  
    padding = '',               -- character to pad on left and right of signature can be ' ', or '|'  etc
  
    transparency = nil,         -- disabled by default, allow floating win transparent value 1~100
    shadow_blend = 36,          -- if you using shadow as border use this set the opacity
    shadow_guibg = 'Black',     -- if you using shadow as border use this set the color e.g. 'Green' or '#121315'
    timer_interval = 200,       -- default timer check interval set to lower value if you want to reduce latency

    --> Teclas para manejo del popup 'Signature Popup'

    --Abrir/cerrar el popup en modo edición (no se mapea en modo normal)
    toggle_key = '<C-\\>',
  
    --Coloca la siguente 'signature' en la actual (solo en modo insert>popup).
    --generalmente no se usa debido a que automaticamente trata de ubicar el 'signature' segun los
    --argumentos escritos.
    select_signature_key = '<C-k>',

    --imap, use nvim_set_current_win to move cursor between current win and floating
    move_cursor_key = nil,
}

local signature = require('lsp_signature')
signature.setup(cfg)



--------------------------------------------------------------------------------------------------
-- Diagnostic> Simbolos e Iconos
--------------------------------------------------------------------------------------------------

--1. Signos (iconos/simbolos) usuados para el diagnostivo
vim.fn.sign_define('DiagnosticSignError', { text = '✘', texthl = 'DiagnosticSignError', numhl = '' })
vim.fn.sign_define('DiagnosticSignWarn',  { text = '▲', texthl = 'DiagnosticSignWarn', numhl = '' })
--vim.fn.sign_define('DiagnosticSignHint',  { text = '⚑', texthl = 'DiagnosticSignHint', numhl = '' })
vim.fn.sign_define('DiagnosticSignHint',  { text = '', texthl = 'DiagnosticSignHint', numhl = '' })
vim.fn.sign_define('DiagnosticSignInfo',  { text = '', texthl = 'DiagnosticSignInfo', numhl = '' })
--vim.fn.sign_define('DiagnosticSignInfo',  { text = '', texthl = 'DiagnosticSignInfo', numhl = '' })
--vim.fn.sign_define('DiagnosticSignInfo',  { text = 'כֿ', texthl = 'DiagnosticSignInfo', numhl = '' })

--------------------------------------------------------------------------------------------------
-- Diagnostic> 
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

--2. Configuración global de diagnósticos
vim.diagnostic.config({

    --Muestra mensaje de diagnóstico con un "texto virtual" al final de la línea.
    virtual_text = {
        source = 'always',     --Si es 'always' siempre se muestra la fuente de diagnóstico 'always'
                               --Si es 'if_many' solo se muestra la fuente si existe mas de uno.
        prefix = '●',          --Establece el carácter que precede al texto virtual
    },

    --Mostrar un "signo" en la línea donde hay un diagnóstico presente.
    signs = true,
    
    --Subrayar la localización de un diagnóstico.
    underline = true,

    --Actualizar los diagnósticos mientras se edita el documento en modo de inserción.
    update_in_insert = false,

    --Ordenar los diagnósticos de acuerdo a su prioridad.
    severity_sort = true,

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



--------------------------------------------------------------------------------------------------
-- Complementos> Ligthting, Code Formatting (incluyendo Fixers) de servidores No-LSP
--------------------------------------------------------------------------------------------------

--local null_ls = require("null-ls")
--
--null_ls.setup({
--    sources = {
--        null_ls.builtins.formatting.prettier,
--        null_ls.builtins.diagnostics.eslint,
--        --null_ls.builtins.completion.spell,
--        --null_ls.builtins.formatting.shfmt,        -- shell script formatting
--        --null_ls.builtins.diagnostics.shellcheck,  -- shell script diagnostics
--        --null_ls.builtins.code_actions.shellcheck, -- shell script code actions
--    },
--})



--------------------------------------------------------------------------------------------------
-- Adaptadores LSP
--------------------------------------------------------------------------------------------------

require('ide.adapters.lsp.main')


