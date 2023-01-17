--------------------------------------------------------------------------------------------------
--LSP Client> Configuracion de LSP client (LSPConfig)
--------------------------------------------------------------------------------------------------

--1. Extendiendo las capacidad de autocompletado de LSPConfig: Usando la fuente CMP para LSP 
local lsp_config = require('lspconfig')
local cmp_lsp = require('cmp_nvim_lsp')

lsp_config.util.default_config.capabilities = vim.tbl_deep_extend(
    'force',
    lsp_config.util.default_config.capabilities,
    cmp_lsp.default_capabilities()
)

--2. Establecer el key mapping mediante autocomando (Neovim > 0.7.2)
--   Si usa Neovim <= 0.7.2, debera implementar una funcion on_attach, por cada cliente LSP que configura 
vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'Acciones LSP',
    callback = function()
            local bufmap = function(mode, lhs, rhs)
            local opts = {buffer = true}
            vim.keymap.set(mode, lhs, rhs, opts)
        end

    -- Muestra información sobre símbolo debajo del cursor
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

    -- Mostrar argumentos de función
    bufmap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>')

    -- Renombrar símbolo
    bufmap('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>')

    -- Listar "code actions" disponibles en la posición del cursor
    bufmap('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>')
    bufmap('x', '<F4>', '<cmd>lua vim.lsp.buf.range_code_action()<cr>')

    -- Mostrar diagnósticos de la línea actual
    bufmap('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>')

    -- Saltar al diagnóstico anterior
    bufmap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')

    -- Saltar al siguiente diagnóstico
    bufmap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')
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
        {name = 'path'},
        {name = 'nvim_lsp'},
        --{name = 'nvim_lsp', keyword_length = 3, trigger_characters = { '.', '[' }},
        --{name = 'nvim_lsp', keyword_length = 3},
        {name = 'buffer', keyword_length = 3},
        {name = 'luasnip', keyword_length = 2},
    },

    --Controla la apariencia de la ventana donde se muestra la documentación: usar bordes
    window = {
        documentation = cmp.config.window.bordered()
    },

    --xxx
    formatting = {
        --Controla el orden en el que aparecen los elementos de un item.
        fields = {'menu', 'abbr', 'kind'},
        --Determina el formado del item
        format = function(entry, item)
                --Asignarles icono a field 'menu'
                local menu_icon = {
                    nvim_lsp = 'λ',
                    luasnip = '⋗',
                    buffer = 'Ω',
                    path = '🖫'
                }
                item.menu = menu_icon[entry.source.name]
                return item
            end,
    },

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
--LSP Client> Personalización adicionales del LSP Client
--------------------------------------------------------------------------------------------------

--1. Personalizando los iconos de diagnostivo (funcion VIM 'sing_define')
local sign = function(opts)
        vim.fn.sign_define(opts.name, {
            texthl = opts.name,
            text = opts.text,
            numhl = ''
        })
    end

sign({name = 'DiagnosticSignError', text = '✘'})
sign({name = 'DiagnosticSignWarn', text = '▲'})
sign({name = 'DiagnosticSignHint', text = '⚑'})
sign({name = 'DiagnosticSignInfo', text = ''})

--2. Configuración global de diagnósticos
vim.diagnostic.config({
    --Muestra mensaje de diagnóstico con un "texto virtual" al final de la línea.
    virtual_text = false,

    ----Mostrar un "signo" en la línea donde hay un diagnóstico presente.
    --signs = true,
    ----Subrayar la localización de un diagnóstico.
    --underline = true,
    ----Actualizar los diagnósticos mientras se edita el documento en modo de inserción.
    --update_in_insert = false,

    --Ordenar los diagnósticos de acuerdo a su prioridad.
    severity_sort = true,
    --Habilitar ventanas flotantes para mostrar los mensajes de diagnósticos.
    float = {
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
    },
})

--3. Bordes en ventanas de ayuda:
--   Modificar la configuración del "handler" de 'vim.lsp.buf.hover()' que muestra ventana flotante
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    {border = 'rounded'}
)

--  Modificar la configuración del "handler" de 'vim.lsp.buf.signature_help()' que muestra ventana flotante
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
    vim.lsp.handlers.signature_help,
    {border = 'rounded'}
)

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
dap_ui.setup()

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




