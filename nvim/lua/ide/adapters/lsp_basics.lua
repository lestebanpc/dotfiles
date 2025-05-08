--
-- Aqui configure los cliente LSP configurados directamente usando el API 'vim.lsp'.
--  > URL: https://neovim.io/doc/user/lsp.html#lsp-config
--  > Desde la NeoVim < 0.11, se dejo de usar funciones: require('lspconfig').<adapter>.setup({}).
--  > Se recomienda usar el API nativo de NeoVim >= 0.11: vim.lsp.config(<adapter>, {}).
--
local lsp_server_path = ""

--
-- Valores por defecto de los LSP Client
--
-- Adicionando valores a las capadades por defecto del LSP, las capadades adicionales de autocompletado
local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config('*', {
    capabilities = lsp_capabilities,
    root_markers = { '.git' },
})

--
-- Segun el API 'vim.lsp', los adaptadores LSP deberan definirse dentro del folder '<runtimepath>/lsp'.
-- En un adaptador es un script que reotorna valores de configuración requiridos para el cliente LSP se
-- contecte al servidor LSP.
-- Los adaptadores que se usaran seran de 2 tipos:
--  > Adaptador definidos por el plugin 'nvim-lspconfig'
--    - URL de adapatadores: https://github.com/neovim/nvim-lspconfig/tree/master/lsp
--  > Adaptador propios ubicados en dicha ruta.
--
local lsp_adapters = {}


--------------------------------------------------------------------------------------------------
--LSP Client> Para C++ y C
--------------------------------------------------------------------------------------------------

--
-- LSP Server : Clangd (Parte del proyecto LLVM)
-- URL        : https://github.com/llvm/llvm-project
-- Docs       :
-- Install    : En windows, descargar el binario. El linux usar paquetes de repositorio.
--
local use_adapter = vim.g.use_lsp_adapters['cpp']
local adapter_name = 'clangd'

if use_adapter ~= nil and use_adapter == true then

    vim.lsp.config(adapter_name, {

        cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
        },

        --filetypes = {"c", "cpp", "objc", "objcpp"},
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto", "hpp" },

        -- Se usa el por defecto
        --root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", "configure.ac", ".git" }
    })

    lsp_adapters[#lsp_adapters + 1] = adapter_name

    --
    -- Atajos de teclado especificos
    --

    -- Alternar entre archivos fuente y encabezado en C/C++:
    --vim.api.nvim_set_keymap('n', '<leader>ch', '<cmd>ClangdSwitchSourceHeader<CR>', { noremap = true, silent = true })

    -- Mostrar informacion de un simbolo C/C++:
    --vim.api.nvim_set_keymap('n', '<leader>ss', '<cmd>LspClangdShowSymbolInfo<CR>', { noremap = true, silent = true })

end


--------------------------------------------------------------------------------------------------
--LSP Client> Para Rust
--------------------------------------------------------------------------------------------------

--
-- LSP Server  : Rust Roslyn (LSP oficial)
-- URL         : https://github.com/rust-lang/rust-analyzer
-- Docs        : https://rust-analyzer.github.io/book/configuration.html
-- Install     : Descargar el binario
--
use_adapter = vim.g.use_lsp_adapters['rust']
adapter_name = 'rust_analyzer'

if use_adapter ~= nil and use_adapter == true then

    -- TODO: Incluir
    -- Formateador: rustfmt
    -- Linter: Clippy
    vim.lsp.config(adapter_name, {

        settings = {
            ["rust-analyzer"] = {
                cargo = {
                    allFeatures = true,
                    loadOutDirsFromCheck = true,
                    runBuildScripts = true,
                },

                diagnostics = {
                    enable = false;
                },

                -- Habilita macros de procedimiento.
                procMacro = {
                    enable = true,
                    ignored = {
                        ["async-trait"] = { "async_trait" },
                        ["napi-derive"] = { "napi" },
                        ["async-recursion"] = { "async_recursion" },
                    },
                },
            },
        },

    })

    lsp_adapters[#lsp_adapters + 1] = adapter_name

end


--------------------------------------------------------------------------------------------------
--LSP Client> Para Go
--------------------------------------------------------------------------------------------------

--
-- LSP Server : GoPls (LSP oficial e integrado a su RTE)
-- URL        : https://github.com/golang/tools/tree/master/gopls
-- Install    : go install golang.org/x/tools/gopls@latest
-- Validate   : gopls --version
--
use_adapter = vim.g.use_lsp_adapters['golang']
adapter_name = 'gopls'

if use_adapter ~= nil and use_adapter == true then

    vim.lsp.config(adapter_name, {
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


    lsp_adapters[#lsp_adapters + 1] = adapter_name

    --
    -- Autocomando> Evento al guardar un archivo .go, organizar sus importaciones al guardar usando la lógica
    -- de 'goimports'
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

end


--------------------------------------------------------------------------------------------------
--LSP Client> Para C#
--------------------------------------------------------------------------------------------------

--
-- LSP Server : OmniSharp
-- URL        : https://github.com/omnisharp/omnisharp-roslyn
-- Prioridad  : Si de define usar tambien 'Roslyn LSP' para C# de Microsoft, no se usara este adaptador.
-- Install    : Desacargar el binario
--
use_adapter = vim.g.use_lsp_adapters['omnisharp']
adapter_name = 'omnisharp'

if use_adapter ~= nil and use_adapter == true then

    -- No usar si se definio usar 'Roslyn LSP'
    use_adapter = vim.g.use_lsp_adapters['csharp']
    if use_adapter == nil or use_adapter ~= true then

        if (vim.g.os_type == 0) then
            --Si es Windows
            lsp_server_path = vim.g.programs_base_path .. '/lsp_servers/omnisharp_ls/OmniSharp.exe'
        else
            --Si es un WSL, no se usara LSP de Windows (debe instalar OmniSharp en propio WSL)
            lsp_server_path = vim.g.programs_base_path .. '/lsp_servers/omnisharp_ls/OmniSharp'
        end

        --local pid = vim.fn.getpid()
        vim.lsp.config(adapter_name, {
            cmd = {
                lsp_server_path,
                "-z",
                "DotNet:enablePackageRestore=false",
                "--encoding", "utf-8",
                "--languageserver"
            },
        })

        lsp_adapters[#lsp_adapters + 1] = adapter_name

    end

end


--------------------------------------------------------------------------------------------------
--LSP Client> Para Swift
--------------------------------------------------------------------------------------------------

--
-- LSP Server : SourceKit LSP (LSP oficial de swift)
-- URL        : https://github.com/swiftlang/sourcekit-lsp
--
use_adapter = vim.g.use_lsp_adapters['swift']
adapter_name = 'sourcekit'

--if use_adapter ~= nil and use_adapter == true then
--
--
--    vim.lsp.config(adapter_name, {
--        cmd = {
--            "sourcekit-lsp",
--        }
--    })
--
--    lsp_adapters[#lsp_adapters + 1] = adapter_name
--
--end


--------------------------------------------------------------------------------------------------
--LSP Client> Kotlin
--------------------------------------------------------------------------------------------------

--
-- LSP Server : Kotlin LS
-- URL        : https://github.com/fwcd/kotlin-language-server
--
use_adapter = vim.g.use_lsp_adapters['kotlin']
adapter_name = 'kotlin_language_server'

--if use_adapter ~= nil and use_adapter == true then
--
--
--    vim.lsp.config(adapter_name, {
--        cmd = {
--            "kotlin-language-server",
--        }
--    })
--
--    lsp_adapters[#lsp_adapters + 1] = adapter_name
--
--end


--------------------------------------------------------------------------------------------------
--LSP Client> Para Javascript y Typescript
--------------------------------------------------------------------------------------------------

--
-- LSP Server : typescript es un adapador que convierte el 'tsserver' en LSP server
-- URL        : https://github.com/typescript-language-server/typescript-language-server
--
use_adapter = vim.g.use_lsp_adapters['typescript']
adapter_name = 'ts_ls'

if use_adapter ~= nil and use_adapter == true then

    vim.lsp.config(adapter_name, {
        cmd = {
            "typescript-language-server",
            "--stdio",
        }
    })

    lsp_adapters[#lsp_adapters + 1] = adapter_name

end


--------------------------------------------------------------------------------------------------
--LSP Client> Para Python
--------------------------------------------------------------------------------------------------

--
-- LSP Server : BasedPyRight (hecho en python y basado de PyRight)
-- URL        : https://docs.basedpyright.com/latest/
-- Install    : pip install --user basedpyright
-- Validate   : basedpyright --version
--
use_adapter = vim.g.use_lsp_adapters['python']
adapter_name = 'basedpyright'

if use_adapter ~= nil and use_adapter == true then


    vim.lsp.config(adapter_name, {

        cmd = { "basedpyright-langserver", "--stdio" },
        filetypes = { "python" },

        settings = {
            basedpyright = {
                analysis = {
                    autoSearchPaths = true,
                    diagnosticMode = "openFilesOnly",
                    useLibraryCodeForTypes = true
                }
            }
        }

    })

    lsp_adapters[#lsp_adapters + 1] = adapter_name

end


--
-- LSP Server : PyRight (usado como base para varios LSP server)
-- URL        : https://github.com/microsoft/pyright
-- Docs       : https://microsoft.github.io/pyright/#/
-- Install    : pip install pyright
--
use_adapter = vim.g.use_lsp_adapters['pyright']
adapter_name = 'pyright'

if use_adapter ~= nil and use_adapter == true then


    -- No usar si se definio usar 'BasedPyRight'
    use_adapter = vim.g.use_lsp_adapters['python']
    if use_adapter == nil or use_adapter ~= true then

        vim.lsp.config(adapter_name, {

            cmd = { "pyright-langserver", "--stdio" },
            filetypes = { "python" },

        })

        lsp_adapters[#lsp_adapters + 1] = adapter_name

    end

end


--------------------------------------------------------------------------------------------------
--LSP Client> Para Bash
--------------------------------------------------------------------------------------------------

--
-- LSP Server : Bash LS
-- URL        : https://github.com/bash-lsp/bash-language-server
-- Validate   : npm install -g bash-language-server
--
use_adapter = vim.g.use_lsp_adapters['bash']
adapter_name = 'bashls'

if use_adapter ~= nil and use_adapter == true then

    vim.lsp.config(adapter_name, {

        cmd = { "bash-language-server", "start" },
        filetypes = { "bash", "sh" },

    })

    lsp_adapters[#lsp_adapters + 1] = adapter_name

end


--------------------------------------------------------------------------------------------------
--LSP Client> Para VimL (VimScript)
--------------------------------------------------------------------------------------------------

--
-- LSP Server : Vim LS
-- URL        : https://github.com/iamcco/vim-language-server
-- Install    : npm install -g vim-language-server
--
use_adapter = vim.g.use_lsp_adapters['viml']
adapter_name = 'vimls'

if use_adapter ~= nil and use_adapter == true then

    vim.lsp.config(adapter_name, {

        cmd = { "vim-language-server", "--stdio" },
        filetypes = { "vim" },

    })

    lsp_adapters[#lsp_adapters + 1] = adapter_name

end


--------------------------------------------------------------------------------------------------
--LSP Client> Para Lua
--------------------------------------------------------------------------------------------------

--
-- LSP Server : Lua LS
-- URL        : https://github.com/luals/lua-language-server
-- Install    : Descargar binario
-- Validate   : lua-language-server --version
--
use_adapter = vim.g.use_lsp_adapters['lua']
adapter_name = 'luals'

if use_adapter ~= nil and use_adapter == true then


    vim.lsp.config(adapter_name, {

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

    lsp_adapters[#lsp_adapters + 1] = adapter_name

end


--------------------------------------------------------------------------------------------------
--LSP Client> Para archivos Ansible
--------------------------------------------------------------------------------------------------

--
-- LSP Server : Ansible LS de Red Hat (paquete nodejs)
-- URL        : https://github.com/ansible/vscode-ansible
-- Requiere   : Python, paquetes python de Ansible y del linter 'Ansible-Lint'
-- Linter     : https://github.com/ansible/ansible-lint
-- Install    : pipx install --include-deps ansible
--              pip3 install ansible-lint
--              npm install -g @ansible/ansible-language-server
-- Validate   : ansible-language-server --version
--
use_adapter = vim.g.use_lsp_adapters['ansible']
adapter_name = 'ansiblels'

if use_adapter ~= nil and use_adapter == true then


    vim.lsp.config(adapter_name, {

        cmd = { "ansible-language-server", "--stdio" },
        filetypes = { "yaml.ansible" },
        root_markers = { "ansible.cfg", ".ansible-lint" }

    })

    lsp_adapters[#lsp_adapters + 1] = adapter_name

end


--------------------------------------------------------------------------------------------------
--LSP Client> Para archivos Markdown
--------------------------------------------------------------------------------------------------

--
-- LSP Server : Marksman LS
-- URL        : https://github.com/artempyanykh/marksman
-- Install    : Descargar el binario
-- Validate   : marksman --version
--
use_adapter = vim.g.use_lsp_adapters['markdown']
adapter_name = 'marksman'

if use_adapter ~= nil and use_adapter == true then


    vim.lsp.config(adapter_name, {

        cmd = { "marksman", "server" },
        filetypes = { "markdown", "markdown.mdx" },
        root_markers = { ".marksman.toml", ".git" }

    })

    lsp_adapters[#lsp_adapters + 1] = adapter_name

end



--------------------------------------------------------------------------------------------------
-- Activando los cliente LSP
--------------------------------------------------------------------------------------------------
--
-- Esto hara que cuando habra un buffer asociado al filetypes del servidor, este inicie el servidor
-- (si aun no este iniciado) y luego lo vincule (attached) al buffer.
--

vim.lsp.enable(lsp_adapters)
