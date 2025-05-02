--
-- Aqui configure los cliente LSP configurados directamente usando el API 'vim.lsp'.
--  > URL: https://neovim.io/doc/user/lsp.html#lsp-config
--  > Desde la NeoVim < 0.11, se dejo de usar funciones: require('lspconfig').<adapter>.setup({}).
--  > Se recomienda usar el API nativo de NeoVim >= 0.11: vim.lsp.config(<adapter>, {}).
--
local lsp_server_path = ""

--------------------------------------------------------------------------------------------------
-- Valores por defecto de los LSP Client
--------------------------------------------------------------------------------------------------
--
-- Adicionando valores a las capadades por defecto del LSP, las capadades adicionales de autocompletado
--
local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config('*', {
    capabilities = lsp_capabilities,
    root_markers = { '.git' },
})

--
-- Se usaran los valores los valores de configuración retornodos por los adaptradores definidos en el
-- '<runtimepath>/lsp'. En nuestro caso estos adaptadores son:
--  > Adaptador definidos por el plugin 'nvim-lspconfig'
--    - URL de adapatadores: https://github.com/neovim/nvim-lspconfig/tree/master/lsp
--  > Adaptador propios ubicados en dicha ruta.
--

--------------------------------------------------------------------------------------------------
--LSP Client> Para 'OmniSharp LSP' para C#
--------------------------------------------------------------------------------------------------
--
-- NO se usara, se usara el 'Roslyn LSP' para C# de Microsoft.
--

--if (vim.g.os_type == 0) then
--    --Si es Windows
--    lsp_server_path = vim.g.programs_base_path .. '/lsp_servers/omnisharp_ls/OmniSharp.exe'
--else
--    --Si es un WSL, no se usara LSP de Windows (debe instalar OmniSharp en propio WSL)
--    lsp_server_path = vim.g.programs_base_path .. '/lsp_servers/omnisharp_ls/OmniSharp'
--end
--
----local pid = vim.fn.getpid()
--vim.lsp.config('omnisharp', {
--    cmd = { lsp_server_path },
--    --cmd = { vim.g.lsp_server_path, "--languageserver" , "--hostPID", tostring(pid) },
--})


--------------------------------------------------------------------------------------------------
--LSP Client> GoLang (Adaptador para GoPls de Go)
--------------------------------------------------------------------------------------------------

vim.lsp.config('gopls', {
    --Ajuste las opciones del comando 'gopls' segun lo que se requiera
    cmd = { "gopls" },
    filetypes = { "go", "gomod", 'gowork', 'gotmpl' },

    -- Si se desea que se active LSP server aun si no esta asociado a un workspace (archivos solos)
    --single_file_support = true,  
    
    -- Se usa el por defecto (no funciona usando en NeoVim < 0.11
    --root_dir = 

    settings = {
        gopls = {
            analyses = {
                unusedparams = true,
                --fieldalignment = true,
                --nilness = true,
                --unusedwrite = true,
                --useany = true,
            },
            staticcheck = true,
            --gofumpt = true,
            --usePlaceholders = true,
            --completeUnimported = true,
            --codelenses = {
            --    generate = true,
            --    gc_details = true,
            --    test = true,
            --    tidy = true,
            --    upgrade_dependency = true,
            --    vendor = true,
            --},
            --hints = {
            --    assignVariableTypes = true,
            --    compositeLiteralFields = true,
            --    compositeLiteralTypes = true,
            --    constantValues = true,
            --    functionTypeParameters = true,
            --    parameterNames = true,
            --    rangeVariableTypes = true,
            --},
        },
    },
})

--
-- Autocomando> Evento al guardar un archivo .go, organizar sus importaciones al guardar usando la lógica de 'goimports'
--  > Requiere Neovim >= 0.7.0
--  > Usa el formato recomando para go:
--    Los inicios de linea de codigo esta separados por tab, no por espacios.
--
vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.go',
    callback = function()
        --vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
        local params = vim.lsp.util.make_range_params()
        params.context = { only = { 'source.organizeImports' } }
        local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params, 1000)
        for _, res in pairs(result or {}) do
          for _, r in pairs(res.result or {}) do
            if r.edit then
              local enc = (vim.lsp.get_client_by_id(res.client_id) or {}).offset_encoding or 'utf-16'
              vim.lsp.util.apply_workspace_edit(r.edit, enc)
            end
          end
        end
        vim.lsp.buf.format({ async = false })
    end,
})


--------------------------------------------------------------------------------------------------
--LSP Client> CLang (Adaptador para Clang de C++)
--------------------------------------------------------------------------------------------------

vim.lsp.config('clangd', {

    cmd = { "clangd" },
    --cmd = {
    --    "clangd",
    --    "--background-index",
    --    "--clang-tidy",
    --    "--header-insertion=iwyu",
    --    "--completion-style=detailed",
    --    "--function-arg-placeholders",
    --    "--fallback-style=llvm",
    --},

    --filetypes = {"c", "cpp", "objc", "objcpp"},
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto", "hpp" },

    -- Se usa el por defecto
    --root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", "configure.ac", ".git" }
})

--
-- Atajos de teclado especificos
--

-- Alternar entre archivos fuente y encabezado en C/C++:
--vim.api.nvim_set_keymap('n', '<leader>ch', '<cmd>ClangdSwitchSourceHeader<CR>', { noremap = true, silent = true })

-- Mostrar informacion de un simbolo C/C++:
--vim.api.nvim_set_keymap('n', '<leader>ss', '<cmd>LspClangdShowSymbolInfo<CR>', { noremap = true, silent = true })



--------------------------------------------------------------------------------------------------
--LSP Client> Rust Analizer (Adaptador para LSP server de Rust)
--------------------------------------------------------------------------------------------------
--
-- https://rust-analyzer.github.io/book/configuration.html
--


-- TODO: Incluir
-- Formateador: rustfmt
-- Linter: Clippy

vim.lsp.config('rust_analyzer', {

    settings = {
        ["rust-analyzer"] = {
            cargo = {
                allFeatures = true,
            },

            -- Ejecuta el linter 'clippy' al guardar
            --checkOnSave = {
            --    command = "clippy",
            --},

            -- Habilita macros de procedimiento.
            procMacro = {
                enable = true,
            },
        },
    },

})

--------------------------------------------------------------------------------------------------
--LSP Client> PyRight (Adaptador para LSP server para Python)
--------------------------------------------------------------------------------------------------

vim.lsp.config('pyright', {

    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },

})



--------------------------------------------------------------------------------------------------
--LSP Client> Bash LS (Adaptador para LSP server para Bash)
--------------------------------------------------------------------------------------------------

vim.lsp.config('bashls', {

    cmd = { "bash-language-server", "start" },
    filetypes = { "bash", "sh" },

})



--------------------------------------------------------------------------------------------------
--LSP Client> Vim LS (Adaptador para LSP server para VimScript)
--------------------------------------------------------------------------------------------------

vim.lsp.config('vimls', {

    cmd = { "vim-language-server", "--stdio" },
    filetypes = { "vim" },

})



--------------------------------------------------------------------------------------------------
--LSP Client> Lua LS (Adaptador para LSP server para Lua)
--------------------------------------------------------------------------------------------------

vim.lsp.config('luals', {

    on_init = function(client)
        if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if path ~= vim.fn.stdpath('config') and (vim.uv.fs_stat(path..'/.luarc.json') or vim.uv.fs_stat(path..'/.luarc.jsonc')) then
                return
            end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
                -- Tell the language server which version of Lua you're using
                -- (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT'
            },
            -- Make the server aware of Neovim runtime files
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME
                    -- Depending on the usage, you might want to add additional paths here.
                    -- "${3rd}/luv/library"
                    -- "${3rd}/busted/library",
                }
                -- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration
                -- (see https://github.com/neovim/nvim-lspconfig/issues/3189)
                -- library = vim.api.nvim_get_runtime_file("", true)
            }
          })
    end,
    --settings = {
    --    Lua = {}
    --},
    cmd = { "lua-language-server" },
    filetypes = { "lua" },

})



--------------------------------------------------------------------------------------------------
-- Activando los cliente LSP
--------------------------------------------------------------------------------------------------
--
-- Esto hara que cuando habra un buffer asociado al filetypes del servidor, este inicie el servidor
-- (si aun no este iniciado) y luego lo vincule (attached) al buffer.
--

vim.lsp.enable({ 'gopls', 'clangd', 'rust_analyzer', 'pyright', 'bashls', 'vimls', 'luals' })

