--------------------------------------------------------------------------------------------------
--No-LSP> Ligting, Code Formatting (incluyendo Fixers) de servidores No-LSP
--------------------------------------------------------------------------------------------------

local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.diagnostics.eslint,
        --null_ls.builtins.completion.spell,
        --null_ls.builtins.formatting.shfmt,        -- shell script formatting
        --null_ls.builtins.diagnostics.shellcheck,  -- shell script diagnostics
        --null_ls.builtins.code_actions.shellcheck, -- shell script code actions
    },
})

--------------------------------------------------------------------------------------------------
--LSP Client> Configuracion del protocolo LSP
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
--LSP Client> Configuracion de LSPConfig
--------------------------------------------------------------------------------------------------

--1. Extendiendo las capacidad de autocompletado de LSPConfig: Usando la fuente CMP para LSP 
local lsp_config = require('lspconfig')
local cmp_lsp = require('cmp_nvim_lsp')

lsp_config.util.default_config.capabilities = vim.tbl_deep_extend(
    'force',
    lsp_config.util.default_config.capabilities,
    cmp_lsp.default_capabilities()
)

--2. Logica que se ejecuta cuando el cliente LSP se vincula al servidor LSP.
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
    callback = function()

        local bufmap = function(mode, lhs, rhs)
            local opts = { buffer = true, noremap = true }
            vim.keymap.set(mode, lhs, rhs, opts)
        end

        -- Muestra información sobre símbolo debajo/arriba del prompt actual
        bufmap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>')

        -- Saltar a definición
        bufmap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>')

        -- Saltar a declaración
        bufmap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>')

        -- Mostrar implementaciones
        bufmap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>')

        -- Saltar a definición de tipo
        bufmap('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>')

        -- Listar referencias
        bufmap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>')

        -- Listar Simbolos, buscar e ir
        bufmap('n', 'gs', '<cmd>lua vim.lsp.buf.document_symbol()<cr>')

        -- Mostrar argumentos de función
        bufmap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>')
        bufmap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>')

        -- Renombrar símbolo
        bufmap('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>')

        -- Listar "code actions" disponibles en la posición del cursor
        bufmap('n', '<Leader>fa', '<cmd>lua vim.lsp.buf.code_action()<cr>')
        bufmap('x', '<Leader>fa', '<cmd>lua vim.lsp.buf.range_code_action()<cr>')

        -- Listar el diagnistico usando Telescope
        bufmap('n', 'fd', '<cmd>Telescope diagnostics<CR>')

        -- Mostrar diagnósticos de la línea actual
        bufmap('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>')

        -- Saltar al diagnóstico anterior
        bufmap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')

        -- Saltar al siguiente diagnóstico
        bufmap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')

        -- Acciones relacionados al 'Workspace' (projecto)
        bufmap('n', '<Leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>')
        bufmap('n', '<Leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>')
        
        -- Formateo del codigo
        bufmap('n', '<Leader>cf', '<cmd>lua vim.lsp.buf.formatting()<cr>')
        --Neovim 0.7 - timeout 2 segundos
        --bufmap('n', '<Leader>cf', '<cmd>lua vim.lsp.buf.formatting_sync(nil, 2000)<cr>')
        --Neovim 0.8 - timeout 2 segundos
        --bufmap('n', '<Leader>cf', '<cmd>lua vim.lsp.buf.format({ timeout_ms = 2000 })<cr>')

        -- Formateo del codigo de rango
        bufmap('x', '<Leader>crg', '<cmd>lua vim.lsp.buf.range_formatting()<CR>')

        --LspInfo
        
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
--Completado y Snippets> Configuración del Completado y su integración con los Snippets y el LSP Client
--------------------------------------------------------------------------------------------------

local cmp = require('cmp')
local snippet = require('luasnip')

--Cargar '.lazy_load()' las implementacion de snippet (por ejemplo 'friendly-snippets') que estan 'runtimepath'
require('luasnip.loaders.from_vscode').lazy_load()

--xxx
local select_opts = {behavior = cmp.SelectBehavior.Select}

--1. Configurar el completado para todos los tipos de archivos
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
        { name = 'nvim_lsp_signature_help' },
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
                    luasnip = '⋗',
                    buffer = 'Ω',
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

    --Atajos de teclado usado en el completado
    mapping = {
        --Navegar entre las sugerencias
        ['<Up>'] = cmp.mapping.select_prev_item(select_opts),
        ['<Down>'] = cmp.mapping.select_next_item(select_opts),

        ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
        ['<C-n>'] = cmp.mapping.select_next_item(select_opts),
       
        --Desplazar el texto de la ventada de navegacion
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),

        --Cancelar el completado
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({select = false}),
        
        --Salta al proximo placeholder de un snippet
        ['<C-d>'] = cmp.mapping(function(fallback)
                if snippet.jumpable(1) then
                    snippet.jump(1)
                else
                    fallback()
                end
            end, {'i', 's'}),

        --Salta al placeholder anterior de snippet
        ['<C-b>'] = cmp.mapping(function(fallback)
                if snippet.jumpable(-1) then
                    snippet.jump(-1)
                else
                    fallback()
                end
            end, {'i', 's'}),

        --Autocmpletado con 'Tab' (si la linea es vacia, no se autocompleta y escribe 'Tab')
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

        --Si la lista de sugerencias es visible, navega al item anterior
        ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item(select_opts)
                else
                    fallback()
                end
            end, {'i', 's'}),
    },
})


--2. Configurar el completado para un tipos de archivo especifico
--cmp.setup.filetype({ 'yourfiletype' }, {
--   -- Options here
--
--})

--------------------------------------------------------------------------------------------------
--LSP Client> Diagnostico 
--------------------------------------------------------------------------------------------------

--1. Signos (iconos/simbolos) usuados para el diagnostivo
vim.fn.sign_define('DiagnosticSignError', { text = '✘', texthl = 'DiagnosticSignError', numhl = '' })
vim.fn.sign_define('DiagnosticSignWarn',  { text = '▲', texthl = 'DiagnosticSignWarn', numhl = '' })
--vim.fn.sign_define('DiagnosticSignHint',  { text = '⚑', texthl = 'DiagnosticSignHint', numhl = '' })
vim.fn.sign_define('DiagnosticSignHint',  { text = '', texthl = 'DiagnosticSignHint', numhl = '' })
vim.fn.sign_define('DiagnosticSignInfo',  { text = '', texthl = 'DiagnosticSignInfo', numhl = '' })
--vim.fn.sign_define('DiagnosticSignInfo',  { text = '', texthl = 'DiagnosticSignInfo', numhl = '' })
--vim.fn.sign_define('DiagnosticSignInfo',  { text = 'כֿ', texthl = 'DiagnosticSignInfo', numhl = '' })

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
    },
})

--3. Mostar el popup de diagnostics de la linea actual cuando el prompt esta sobre la palabra con error de diagnóstico.
--   ¿No usarlo, usar mejor lo definido a nivel cuando se vincula al LSP server?
--vim.cmd [[autocmd! CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]

--------------------------------------------------------------------------------------------------
--LSP Client> Personalización adicionales del LSP Client
--------------------------------------------------------------------------------------------------

--1. Bordes en ventanas de ayuda:
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


--2. Configurar Lightbulb (kosayoda/nvim-lightbulb)
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

--3. Mostrar el Lightbulb cuando ocurre el evento (autocomando): el prompt esta en la palabra 
--   cuando existe un 'Code Action'
--TODO se configura para todos los 'file type', se puede especificar solo para algunos lenguajes?
vim.cmd [[autocmd CursorHold,CursorHoldI * lua require('nvim-lightbulb').update_lightbulb()]]


--------------------------------------------------------------------------------------------------
--DAP Client> Configuracion del DAP Client nVim.DAP
--------------------------------------------------------------------------------------------------

--Customize the signs
--vim.highlight.create('DapBreakpoint', { ctermbg=0, guifg='#993939', guibg='#31353f' }, false)
--vim.highlight.create('DapLogPoint', { ctermbg=0, guifg='#61afef', guibg='#31353f' }, false)
--vim.highlight.create('DapStopped', { ctermbg=0, guifg='#98c379', guibg='#31353f' }, false)

--vim.fn.sign_define('DapBreakpoint', { text='', texthl='DapBreakpoint', linehl='DapBreakpoint', numhl='DapBreakpoint' })
--vim.fn.sign_define('DapBreakpointCondition', { text='ﳁ', texthl='DapBreakpoint', linehl='DapBreakpoint', numhl='DapBreakpoint' })
--vim.fn.sign_define('DapBreakpointRejected', { text='', texthl='DapBreakpoint', linehl='DapBreakpoint', numhl= 'DapBreakpoint' })
--vim.fn.sign_define('DapLogPoint', { text='', texthl='DapLogPoint', linehl='DapLogPoint', numhl= 'DapLogPoint' })
--vim.fn.sign_define('DapStopped', { text='', texthl='DapStopped', linehl='DapStopped', numhl= 'DapStopped' })

vim.fn.sign_define('DapBreakpoint', { text='', texthl='DapBreakpoint', linehl='', numhl='' })
vim.fn.sign_define('DapBreakpointCondition', { text='ﳁ', texthl='DapBreakpoint', linehl='', numhl='' })
vim.fn.sign_define('DapBreakpointRejected', { text='', texthl='DapBreakpoint', linehl='', numhl= '' })
vim.fn.sign_define('DapLogPoint', { text='', texthl='DapLogPoint', linehl='', numhl= '' })
vim.fn.sign_define('DapStopped', { text='', texthl='DapStopped', linehl='', numhl= '' })

--------------------------------------------------------------------------------------------------
--DAP Client> Mejoras del UI asociado a nVim.DAP
--------------------------------------------------------------------------------------------------

local dap=require("dap")
local dap_ui=require("dapui")

--1. Paquete 'nvim-dap-ui': Adicionar mejoras en el UI por defecto de nVim.DAP

--Usar la configuración por defecto
dap_ui.setup({
    icons = { expanded = "", collapsed = "", current_frame = "" },
    mappings = {
      -- Use a table to apply multiple mappings
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "d",
      edit = "e",
      repl = "r",
      toggle = "t",
    },
    -- Use this to override mappings for specific elements
    element_mappings = {
      -- Example:
      -- stacks = {
      --   open = "<CR>",
      --   expand = "o",
      -- }
    },
    -- Expand lines larger than the window
    -- Requires >= 0.7
    expand_lines = vim.fn.has("nvim-0.7") == 1,
    -- Layouts define sections of the screen to place windows.
    -- The position can be "left", "right", "top" or "bottom".
    -- The size specifies the height/width depending on position. It can be an Int
    -- or a Float. Integer specifies height/width directly (i.e. 20 lines/columns) while
    -- Float value specifies percentage (i.e. 0.3 - 30% of available lines/columns)
    -- Elements are the elements shown in the layout (in order).
    -- Layouts are opened in order so that earlier layouts take priority in window sizing.
    layouts = {
      {
        elements = {
        -- Elements can be strings or table with id and size keys.
          { id = "scopes", size = 0.25 },
          "breakpoints",
          "stacks",
          "watches",
        },
        size = 40, -- 40 columns
        position = "left",
      },
      {
        elements = {
          "repl",
          "console",
        },
        size = 0.25, -- 25% of total lines
        position = "bottom",
      },
    },
    controls = {
      -- Requires Neovim nightly (or 0.8 when released)
      enabled = true,
      -- Display controls in this element
      element = "repl",
      icons = {
        pause = "",
        play = "",
        step_into = "",
        step_over = "",
        step_out = "",
        step_back = "",
        run_last = "",
        terminate = "",
      },
    },
    floating = {
      max_height = nil, -- These can be integers or a float between 0 and 1.
      max_width = nil, -- Floats will be treated as percentage of your screen.
      border = "single", -- Border style. Can be "single", "double" or "rounded"
      mappings = {
        close = { "q", "<Esc>" },
      },
    },
    windows = { indent = 1 },
    render = {
      max_type_length = nil, -- Can be integer or nil.
      max_value_lines = 100, -- Can be integer or nil.
    }

})

dap.listeners.after.event_initialized["dapui_config"] = function()
      dap_ui.open()
   end

dap.listeners.before.event_terminated["dapui_config"] = function()
      dap_ui.close()
   end

dap.listeners.before.event_exited["dapui_config"] = function()
      dap_ui.close()
   end


--2. Paquete 'telescope-dap.nvim': Integracion entre Telescope y nVim.DAP
local telescope = require('telescope')
telescope.load_extension('dap')


--3. Paquete 'nvim-dap-virtual-text': Adicionar texto de ayuda en la depuracion
local dap_virtual_text = require('nvim-dap-virtual-text')
dap_virtual_text.setup ({
    commented = true,              -- prefix virtual text with comment string
})


--------------------------------------------------------------------------------------------------
--Mason Wizard> Wizard de configuración de adaptadores LSP, adaptadores de depuración
--------------------------------------------------------------------------------------------------

--1. Configuración
require("mason").setup()
require("mason-lspconfig").setup()







