
--------------------------------------------------------------------------------------------------
-- Native LSP Client> Configuracion del protocolo LSP
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
-- Native LSP Client> Configuraciones del LSP cliente 
--------------------------------------------------------------------------------------------------

--1. Logica que se ejecuta cuando el cliente LSP se vincula al servidor LSP.
--   > SE configura principalmente el keybinding
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
        vim.keymap.set('n', '<space>ls', '<cmd>lua vim.lsp.buf.document_symbol()<cr>', opts)

        -- > Diagnostico: Listar, Seleccionar e Ir un diagnóstico (error y/o warning) del workspace (Telescope)
        vim.keymap.set('n', '<space>ld', '<cmd>Telescope diagnostics<CR>', opts)

        -- > Diagnostico: Listar, Seleccionar e Ir a un diagnósticos de la línea actual
        vim.keymap.set('n', '<space>dl', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)

        -- > Diagnostico: Ir al siguiente diagnostico desde la posicion actual y dentro del buffer
        vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)

        -- > Diagnostico: Ir a la anterior diagnostico desde la posicion actual y dentro del buffer
        vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts)


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Formateo 
        -- ---------------------------------------------------------------------------------------------
        
        -- Formateo del codigo
        vim.keymap.set('n', '<space>cf', '<cmd>lua vim.lsp.buf.formatting()<cr>', opts)
        --Neovim 0.7 - timeout 2 segundos
        --vim.keymap.set('n', '<space>cf', '<cmd>lua vim.lsp.buf.formatting_sync(nil, 2000)<cr>', opts)
        --Neovim 0.8 - timeout 2 segundos
        --vim.keymap.set('n', '<space>cf', '<cmd>lua vim.lsp.buf.format({ timeout_ms = 2000 })<cr>', opts)

        -- Formateo del codigo de rango seleccionado
        vim.keymap.set('x', '<space>cf', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', opts)


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Workspace 
        -- ---------------------------------------------------------------------------------------------
        
        -- Acciones relacionados al 'Workspace' (proyecto)
        vim.keymap.set('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
        vim.keymap.set('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
        

        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Otros 
        -- ---------------------------------------------------------------------------------------------
        
        -- 'Code Actions' > Listar, Selecionar e Ir a 'Code Actions' disponibles en la posición del cursor
        vim.keymap.set('n', '<space>al', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
        --vim.keymap.set('x', '<space>ar', '<cmd>lua vim.lsp.buf.range_code_action()<cr>', opts)
        --vim.keymap.set('n', '<space>ar', '<cmd>lua vim.lsp.buf.range_code_action()<cr>', opts)

        -- Renombrar símbolo
        vim.keymap.set('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)

        
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
-- Native LSP Client> Personalización adicionales del LSP Client
--------------------------------------------------------------------------------------------------

--1. Handlers para manejar los eventos enviados por LSP server
--   > SE modificaran sus bordes en ventanas de ayuda
--
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
