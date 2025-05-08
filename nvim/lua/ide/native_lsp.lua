--
-- Configuraciones para optimizar los efectos
--

-- Disminuir el tiempo de espera (en ms) sin actividad del usuario antes de ejecutar ciertos eventos automáticos.
-- Valor por defecto 4000 ms (4 s), lo cual suele dar apariencia de efectos lentos.
vim.opt.updatetime = 400


--------------------------------------------------------------------------------------------------
-- Native LSP Client> Configuraciones del LSP cliente
--------------------------------------------------------------------------------------------------

--1. Configurar los "highlight groups" (resaltado) utilizados por el LSP (Language Server Protocol).

-- USAR SOLAMENTE, si su ColorSchema no soporta los siguiente grupo de resaltado:
-- Definir el resaltado requerido para usar el 'highlight symbol under cursor'.
--  > LspReferenceRead
--    Marca/Resalta las ubicaciones donde el símbolo es leído, pero no modificado.
--  > LspReferenceText
--    Marca/resalta todas las referencias del símbolo sin distinguir si son de lectura o escritura.
--  > LspReferenceWrite
--    Marca/resalta las ubicaciones donde el símbolo es modificado o escrito.
--

-- Usar el mismo color usado para el grupo de resaltado 'Search' (cuando se hace busquedas en VIM)
--vim.api.nvim_set_hl(0, 'LspReferenceRead', {link = 'Search'})
--vim.api.nvim_set_hl(0, 'LspReferenceText', {link = 'Search'})
--vim.api.nvim_set_hl(0, 'LspReferenceWrite', {link = 'Search'})



--2. Logica que se ejecuta cuando el cliente LSP se vincula al servidor LSP.
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
    desc = 'LSP Actions',
    callback = function(args)

        -- Obtener el buffer actual
        local buffer = args.buf

        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Mostar informacion en un Popup
        -- ---------------------------------------------------------------------------------------------

        -- Muestra información sobre símbolo debajo/arriba del prompt actual
        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Hover info' })

        -- Mostrar el popup de 'Signature Help' (se usara el key-mapping de 'ray-x/lsp_signature.nvim')
        -- esta opcion solo usa mapeo en modo edición y popup
        --vim.keymap.set('n', '<C-\\>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { noremap = true, buffer = buffer, desc = '' })
        --vim.keymap.set('i', '<C-\\>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { noremap = true, buffer = buffer, desc = '' })

        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : "Navigation" a un "Location" especifico
        -- ---------------------------------------------------------------------------------------------

        -- 1. "Location" dentor del buffer


        -- 2. "Location" basado en el simbolo actual (si existe mas de uno, muestra una lista para que selecciones uno de ellos)

        -- > Ir a una definición
        vim.keymap.set('n', 'gd', '<cmd>lua require("fzf-lua").lsp_definitions()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to definition' })
        --vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to definition' })

        -- > Ir a declaración
        vim.keymap.set('n', 'gc', '<cmd>lua require("fzf-lua").lsp_declarations()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to declaration' })
        --vim.keymap.set('n', 'gc', '<cmd>lua vim.lsp.buf.declaration()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to declaration' })

        -- > Ir a la implementacion
        vim.keymap.set('n', 'gi', '<cmd>lua require("fzf-lua").lsp_implementations()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to implementation' })
        --vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to implementation' })

        -- > Ir a definición de tipo
        vim.keymap.set('n', 'gy', '<cmd>lua require("fzf-lua").lsp_typedefs()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to type definition' })
        --vim.keymap.set('n', 'gy', '<cmd>lua vim.lsp.buf.type_definition()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to type definition' })

        -- > Listar referencias (incluyendo el declaraciones del simbolo)
        vim.keymap.set('n', 'gr', '<cmd>lua require("fzf-lua").lsp_references()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to references' })
        --vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to references' })


        -- 3. Listar, Seleccionar e Ir

        -- > Listar, Seleccionar e Ir a un 'symbol' en el buffer.
        vim.keymap.set('n', '<space>ss', '<cmd>lua require("fzf-lua").lsp_document_symbols()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search buffer symbol' })
        --vim.keymap.set('n', '<space>ss', '<cmd>lua vim.lsp.buf.document_symbol()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search symbol' })

        -- > Listar, Seleccionar e Ir a un 'symbol' en el workspace.
        vim.keymap.set('n', '<space>sw', '<cmd>lua require("fzf-lua").lsp_workspace_symbols()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search workspace symbol' })

        -- > Diagnostico: Listar, Seleccionar e Ir un diagnóstico (error y/o warning) del buffer
        vim.keymap.set('n', '<space>dd', '<cmd>lua require("fzf-lua").lsp_document_diagnostics()<CR>', { noremap = true, buffer = buffer, desc = 'LSP Search buffer diagnostic' })

        -- > Diagnostico: Listar, Seleccionar e Ir un diagnóstico (error y/o warning) del workspace
        vim.keymap.set('n', '<space>dw', '<cmd>lua require("fzf-lua").lsp_workspace_diagnostics()<CR>', { noremap = true, buffer = buffer, desc = 'LSP Search workspace diagnostic' })
        --vim.keymap.set('n', '<space>dw', '<cmd>diagnostics_workspace<CR>', { noremap = true, buffer = buffer, desc = 'LSP Search workspace diagnostic' })

        -- > Diagnostico: Listar, Seleccionar e Ir a un diagnósticos de la línea actual
        --vim.keymap.set('n', '<space>ds', '<cmd>lua vim.diagnostic.open_float()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search current line diagnostic' })


        -- TODO: ¿Todo el diganostico de LSP nativo se envia a ALE?. Si es asi, no es necesario estos Keymapping:
        --
        -- > Diagnostico: Ir al siguiente diagnostico desde la posicion actual y dentro del buffer
        vim.keymap.set('n', '[l', '<cmd>lua vim.diagnostic.goto_prev()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go Previous diagnostic' })

        -- > Diagnostico: Ir a la anterior diagnostico desde la posicion actual y dentro del buffer
        vim.keymap.set('n', ']l', '<cmd>lua vim.diagnostic.goto_next()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go Next diagnostic' })


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Formateo
        -- ---------------------------------------------------------------------------------------------

        -- Formateo del codigo
        vim.keymap.set('n', '<space>cf', '<cmd>lua vim.lsp.buf.formatting()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Format buffer code' })
        --Neovim 0.7 - timeout 2 segundos
        --vim.keymap.set('n', '<space>cf', '<cmd>lua vim.lsp.buf.formatting_sync(nil, 2000)<cr>', { noremap = true, buffer = buffer, desc = '' })
        --Neovim 0.8 - timeout 2 segundos
        --vim.keymap.set('n', '<space>cf', '<cmd>lua vim.lsp.buf.format({ timeout_ms = 2000 })<cr>', { noremap = true, buffer = buffer, desc = '' })

        -- Formateo del codigo de rango seleccionado
        vim.keymap.set('x', '<space>cf', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', { noremap = true, buffer = buffer, desc = 'LSP Format selected range' })


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Workspace
        -- ---------------------------------------------------------------------------------------------

        -- Acciones relacionados al 'Workspace' (proyecto)
        vim.keymap.set('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', { noremap = true, buffer = buffer, desc = 'LSP Add folder to workspace' })
        vim.keymap.set('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', { noremap = true, buffer = buffer, desc = 'LSP Remove folder to workspace' })


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping : Otros
        -- ---------------------------------------------------------------------------------------------

        -- 'Code Actions' > Listar, Selecionar e Ir a 'Code Actions' disponibles en la posición del cursor
        vim.keymap.set('n', '<space>ca', '<cmd>lua require("fzf-lua").lsp_code_actions()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search Code actions' })
        --vim.keymap.set('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search Code actions' })
        --vim.keymap.set('x', '<space>ar', '<cmd>lua vim.lsp.buf.range_code_action()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search Code actions' })
        --vim.keymap.set('n', '<space>ar', '<cmd>lua vim.lsp.buf.range_code_action()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search Code actions' })

        -- Renombrar símbolo
        vim.keymap.set('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Remame symbol' })


        -- ---------------------------------------------------------------------------------------------
        -- Otros
        -- ---------------------------------------------------------------------------------------------

        -- Obtener el client LSP actual
        local id = vim.tbl_get(args, 'data', 'client_id')
        local client = id and vim.lsp.get_client_by_id(id)

        -- Si se tiene un cliente asignado
        if client ~= nil then

            --
            -- Disable semantic highlights
            --
            -- ¿No permite que el LSP cambie el color del texto?
            --client.server_capabilities.semanticTokensProvider = nil

            --
            -- Highlight symbol under cursor (Resaltado de palabras similaras al actual)
            --
            if client.supports_method('textDocument/documentHighlight') then

                local group = vim.api.nvim_create_augroup('highlight_symbol', {clear = false})

                vim.api.nvim_clear_autocmds({buffer = buffer, group = group})

                vim.api.nvim_create_autocmd({'CursorHold', 'CursorHoldI'}, {
                    group = group,
                    buffer = buffer,
                    callback = vim.lsp.buf.document_highlight,
                })

                vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI'}, {
                    group = group,
                    buffer = buffer,
                    callback = vim.lsp.buf.clear_references,
                })

            end

            --
            -- Enable inlay hints
            --
            -- Algunos LSP server por defecto tiene 'inlay hints' desactivado, activarlo si LSP server lo soporta.
            if client.supports_method('textDocument/inlayHint') then

                vim.lsp.inlay_hint.enable(true, {bufnr = buffer})

            end

            --
            -- Mostrar el popup de diagnostics de la linea actual cuando el prompt
            --
            --vim.api.nvim_create_autocmd("CursorHold", {
            --    buffer = buffer,
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


  end,

})


--------------------------------------------------------------------------------------------------
-- Native LSP Client> Personalización adicionales del LSP Client
--------------------------------------------------------------------------------------------------

--01. Handler (controlador de eventos) de 'vim.lsp.buf.hover()' que muestra el 'Documentation Windows'.
--    Se modificaran los borde del 'Documentation Windows'.
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    { border = 'rounded' }
)

--01. Handler (controlador de eventos) de 'vim.lsp.buf.signature_help()' que muestra el 'Signature Help'.
--    Se modificaran los borde del 'Signature Help'.
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
    vim.lsp.handlers.signature_help,
    { border = 'rounded' }
)
