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
        -- Keymapping > Mostrar informacion en un Popup
        -- ---------------------------------------------------------------------------------------------

        -- Muestra información sobre símbolo debajo/arriba del prompt actual
        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Hover info' })

        -- Mostrar el popup de 'Signature Help' (se usara el key-mapping de 'ray-x/lsp_signature.nvim')
        -- esta opcion solo usa mapeo en modo edición y popup
        --vim.keymap.set('n', '<C-\\>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { noremap = true, buffer = buffer, desc = '' })
        --vim.keymap.set('i', '<C-\\>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { noremap = true, buffer = buffer, desc = '' })

        -- ---------------------------------------------------------------------------------------------
        -- Keymapping > Code Navigation > Go to 'Location'
        -- ---------------------------------------------------------------------------------------------
        --
        -- Permite ir a una determinada ubicacion basado en el contexto actual (usualmente el word actual).
        -- Si encuentra mas de una opcion, muestra una lista para que puedes seleccionarlo.
        --

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

        -- > Ir a las referencias (incluyendo el declaraciones del simbolo)
        vim.keymap.set('n', 'gr', '<cmd>lua require("fzf-lua").lsp_references()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to references' })
        --vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go to references' })


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping > Code Navigation > General
        -- ---------------------------------------------------------------------------------------------
        --
        -- Busca un objeto del buffer o workspace, permite listarlo y su selección para ir a su ubicacion.
        --

        -- > Listar, Seleccionar e Ir a un 'symbol' en el buffer.
        vim.keymap.set('n', '<space>ss', '<cmd>lua require("fzf-lua").lsp_document_symbols()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search buffer symbol' })
        --vim.keymap.set('n', '<space>ss', '<cmd>lua vim.lsp.buf.document_symbol()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search symbol' })

        -- > Listar, Seleccionar e Ir a un 'symbol' en el workspace.
        vim.keymap.set('n', '<space>sw', '<cmd>lua require("fzf-lua").lsp_workspace_symbols()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search workspace symbol' })

        -- ---------------------------------------------------------------------------------------------
        -- Keymapping > Code Diagnostic
        -- ---------------------------------------------------------------------------------------------
        --
        -- TODO: ¿Todo el diganostico de LSP nativo se envia a ALE?. ¿no es necesario estos Keymapping para listar los LSP?
        --

        -- > Listar, Seleccionar e Ir un diagnóstico (error y/o warning) del buffer
        vim.keymap.set('n', '<space>dd', '<cmd>lua require("fzf-lua").lsp_document_diagnostics()<CR>', { noremap = true, buffer = buffer, desc = 'LSP Search buffer diagnostic' })

        -- > Listar, Seleccionar e Ir un diagnóstico (error y/o warning) del workspace
        vim.keymap.set('n', '<space>dw', '<cmd>lua require("fzf-lua").lsp_workspace_diagnostics()<CR>', { noremap = true, buffer = buffer, desc = 'LSP Search workspace diagnostic' })
        --vim.keymap.set('n', '<space>dw', '<cmd>diagnostics_workspace<CR>', { noremap = true, buffer = buffer, desc = 'LSP Search workspace diagnostic' })

        -- > Listar, Seleccionar e Ir a un diagnósticos de la línea actual
        --vim.keymap.set('n', '<space>ds', '<cmd>lua vim.diagnostic.open_float()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search current line diagnostic' })


        -- > Ir al siguiente diagnostico desde la posicion actual y dentro del buffer
        vim.keymap.set('n', '[2', '<cmd>lua vim.diagnostic.goto_prev()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go Previous diagnostic' })

        -- > Ir a la anterior diagnostico desde la posicion actual y dentro del buffer
        vim.keymap.set('n', ']2', '<cmd>lua vim.diagnostic.goto_next()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Go Next diagnostic' })


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping > Code Formatting
        -- ---------------------------------------------------------------------------------------------

        -- > Formateo del codigo
        vim.keymap.set('n', '<space>cf', '<cmd>lua vim.lsp.buf.formatting()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Format buffer code' })
        --Neovim 0.7 - timeout 2 segundos
        --vim.keymap.set('n', '<space>cf', '<cmd>lua vim.lsp.buf.formatting_sync(nil, 2000)<cr>', { noremap = true, buffer = buffer, desc = '' })
        --Neovim 0.8 - timeout 2 segundos
        --vim.keymap.set('n', '<space>cf', '<cmd>lua vim.lsp.buf.format({ timeout_ms = 2000 })<cr>', { noremap = true, buffer = buffer, desc = '' })

        -- > Formateo del codigo de rango seleccionado
        vim.keymap.set('x', '<space>cf', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', { noremap = true, buffer = buffer, desc = 'LSP Format selected range' })


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping > Code Actions
        -- ---------------------------------------------------------------------------------------------
        --
        -- Los 'Code Actions' puede ser
        -- > 'Code Action' asociado a objeto de codigo del documento (buffer).
        --   > Estas puede ser :
        --     > Refactor
        --       Acciones de organizacion de codigo, producto de un analisis del arbol sinstanctico, que usualmente
        --       requiere parametros ingresados por el usuario.
        --       Ejemplos comunes:
        --       > refactor.extract
        --         Extraer código (por ejemplo, a una función o variable)
        --       > refactor.inline
        --         Reemplazar el uso de una variable o función con su contenido.
        --       > refactor.rewrite
        --         Reescrituras más profundas del código (como cambiar la estructura de control).
        --     > Quick Fix
        --       Acciones simples generados por un diagnostico de codigo que lo corrigen y no requiere parametros
        --       ingresadas por el usuario para su ejecucion.
        --   > El cliente LSP envía al servidor LSP el rango y este devuelve todos las acciones sobre los diferentes objetos
        --     que están en ese rango del documento.
        --     El rango del documento es:
        --     > En el modo visual, es el rango visual (La acciones son sobre los diferentes objetos que estan en la
        --       selección actual).
        --     > En el normal, es la posición del cursor (La acciones son sobre la objeto donde esta el cursor actual).
        -- > 'Source' que son acciones de codigo asociados a todos el documento (buffer).
        --    Ejemplos comunes:
        --    > source.organizeImports
        --      Reordenar, eliminar o añadir imports automáticamente.
        --    > source.removeUnused
        --      Eliminar código no utilizado (variables, imports, etc.).
        --    > source.addMissingImports
        --      Añadir imports faltantes automáticamente.
        --    > source.sortImports
        --      Ordenar imports (alfabéticamente o según estilo de proyecto).
        --

        -- > Listar, Selecionar e Ir a 'Code Actions' disponibles en la linea actual
        vim.keymap.set('n', '<space>aa', '<cmd>lua require("fzf-lua").lsp_code_actions()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search Code actions' })
        --vim.keymap.set({ 'n', 'v' }, '<space>aa', '<cmd>lua require("fzf-lua").lsp_code_actions()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Search Code actions' })
        --vim.keymap.set('x', '<space>aa', vim.lsp.buf.code_action, { noremap = true, buffer = buffer, desc = 'LSP Search Code actions' })

        -- > Refactoring > Renombrar símbolo
        vim.keymap.set('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', { noremap = true, buffer = buffer, desc = 'LSP Remame symbol' })


        -- ---------------------------------------------------------------------------------------------
        -- Keymapping > Utilties > Workspace
        -- ---------------------------------------------------------------------------------------------

        -- > Acciones relacionados al 'Workspace' (proyecto)
        vim.keymap.set('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', { noremap = true, buffer = buffer, desc = 'LSP Add folder to workspace' })
        vim.keymap.set('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', { noremap = true, buffer = buffer, desc = 'LSP Remove folder to workspace' })

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
            -- CodeLens
            --
            if client.server_capabilities.codeLensProvider then

                -- Refrescar CodeLens automáticamente en eventos relevantes
                vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave", "BufWritePost" }, {
                    buffer = buffer,
                    callback = vim.lsp.codelens.refresh,
                })

                -- ---------------------------------------------------------------------------------------------
                -- Keymapping > Code Lens
                -- ---------------------------------------------------------------------------------------------
                --

                vim.keymap.set('n', '<space>cl', '<cmd>lua vim.lsp.codelens.run()<CR>', { noremap = true, buffer = buffer, desc = 'LSP CodeLens run' })

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
