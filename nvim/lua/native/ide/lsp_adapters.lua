local lsp_config = require('lspconfig')
local lsp_config_util = require('lspconfig/util')
local lsp_server_path = ""

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
--LSP Adapters> C# (Adaptador para OmniSharp Roslyn)
--------------------------------------------------------------------------------------------------

if (vim.g.os_type == 0) then
    --Si es Windows
    lsp_server_path = vim.g.home_path_lsp_server .. '/Omnisharp_Roslyn/OmniSharp.exe'
else
    lsp_server_path = vim.g.home_path_lsp_server .. '/omnisharp_roslyn/OmniSharp'
end

--local pid = vim.fn.getpid()
lsp_config.omnisharp.setup({
    cmd = { lsp_server_path },
    --cmd = { vim.g.lsp_server_path, "--languageserver" , "--hostPID", tostring(pid) },
})


--------------------------------------------------------------------------------------------------
--LSP Adapters> GoLang (Adaptador para GoPls de Go)
--------------------------------------------------------------------------------------------------

lsp_config.gopls.setup({
    --Ajuste las opciones del comando 'gopls' segun lo que se requiera
    cmd = {"gopls", "serve"},
    filetypes = {"go", "gomod"},
    root_dir = lsp_config_util.root_pattern("go.work", "go.mod", ".git"),
    settings = {
        gopls = {
            analyses = {
                unusedparams = true,
            },
            staticcheck = true,
        },
    },
})

--Autocomandos: 
--
--Evento al guardar un archivo .go, organizar sus importaciones al guardar usando la lógica de 'goimports'
--requiere Neovim >= 0.7.0
--vim.api.nvim_create_autocmd('BufWritePre', {
--    pattern = '*.go',
--    callback = function()
--        vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
--    end
--})


--------------------------------------------------------------------------------------------------
--LSP Adapters> CLang (Adaptador para Clang de C++)
--------------------------------------------------------------------------------------------------

lsp_config.clangd.setup({
    cmd = {"clangd"},
    --filetypes = {"c", "cpp", "objc", "objcpp", "cuda", "proto"},
    filetypes = {"c", "cpp", "objc", "objcpp"},
    --root_dir = lsp_config_util.root_pattern('.clangd', '.clang-tidy','.clang-format', 'compile_commands.json', 'compile_flags.txt', 'configure.ac', '.git'),
    root_dir = lsp_config_util.root_pattern('.clangd', '.clang-tidy','.clang-format', '.git'),
})



