--------------------------------------------------------------------------------------------------
--Configuracion de LSP client (LSPConfig)
--------------------------------------------------------------------------------------------------

--Extendiendo las capacidad de autocompletado de LSPConfig: Usando la fuente CMP para LSP 
local lspconfig = require('lspconfig')
local lsp_defaults = lspconfig.util.default_config

lsp_defaults.capabilities = vim.tbl_deep_extend(
    'force',
    lsp_defaults.capabilities,
    require('cmp_nvim_lsp').default_capabilities()
)

--Establecer el key mapping mediante autocomando (Neovim > 0.7.2)
--  Si usa Neovim <= 0.7.2, debera implementar una funcion on_attach, por cada cliente LSP que configura 
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
--Configuracion del Completado y los Snippets
--------------------------------------------------------------------------------------------------

--Cargar '.lazy_load()' las implementacion de snippet (por ejemplo 'friendly-snippets') que estan 'runtimepath'
require('luasnip.loaders.from_vscode').lazy_load()

local cmp = require('cmp')
local luasnip = require('luasnip')

--xxx
local select_opts = {behavior = cmp.SelectBehavior.Select}

--Configurar el completado para todos los tipos de archivos
cmp.setup({

    --Configuracion de los Snippets
    snippet = {
        --Expansion de un snippets
        expand = function(args)
                --Usar los snippets registros por LuaSnip para expnadirlos
                luasnip.lsp_expand(args.body)    
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
                if luasnip.jumpable(1) then
                    luasnip.jump(1)
                else
                    fallback()
                end
            end, {'i', 's'}),

        --Salta al placeholder anterior de snippet
        ['<C-b>'] = cmp.mapping(function(fallback)
                if luasnip.jumpable(-1) then
                    luasnip.jump(-1)
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


--Configurar el completado para un tipos de archivo especifico
--cmp.setup.filetype({ 'yourfiletype' }, {
--   -- Options here
--
--})

--------------------------------------------------------------------------------------------------
--Personalizacion adicionles
--------------------------------------------------------------------------------------------------

--Personalizando los iconos de diagnostivo (funcion VIM 'sing_define')
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

--Configuración global de diagnósticos
vim.diagnostic.config({
    --Muestra mensaje de diagnóstico con un "texto virtual" al final de la línea.
    virtual_text = false,
    --Mostrar un "signo" en la línea donde hay un diagnóstico presente.
    --signs = true,
    --Subrayar la localización de un diagnóstico.
    --underline = true,
    --Actualizar los diagnósticos mientras se edita el documento en modo de inserción.
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

--Bordes en ventanas de ayuda:
--  Modificar la configuración del "handler" de 'vim.lsp.buf.hover()' que muestra ventana flotante
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    {border = 'rounded'}
)

--  Modificar la configuración del "handler" de 'vim.lsp.buf.signature_help()' que muestra ventana flotante
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
    vim.lsp.handlers.signature_help,
    {border = 'rounded'}
)



