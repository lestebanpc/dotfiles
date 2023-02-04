local lsp_config = require('lspconfig')
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

if (vim.g.os_type == 3) then
    --Si es Linux
    lsp_server_path = vim.g.home_path_lsp_server_lnx .. '/omnisharp_roslyn/OmniSharp'
elseif (vim.g.os_type == 2) then
    --Si es WSL
    if (vim.g.wsl_cs_using_win_lsp_server) then
        lsp_server_path = vim.g.home_path_lsp_server_win .. '/Omnisharp_Roslyn/OmniSharp.exe'
    else
        lsp_server_path = vim.g.home_path_lsp_server_wsl .. '/omnisharp_roslyn/OmniSharp'
    end
elseif (vim.g.os_type == 0) then
    --Si es Windows
    lsp_server_path = vim.g.home_path_lsp_server_win .. '/Omnisharp_Roslyn/OmniSharp.exe'
--elseif (vim.g.os_type == 1) then
    --Si es MacOS
    --lsp_server_path = vim.g.home_path_lsp_server_lnx .. '/omnisharp_roslyn/OmniSharp'
end

--local pid = vim.fn.getpid()
lsp_config.omnisharp.setup({
    cmd = { lsp_server_path },
    --cmd = { vim.g.lsp_server_path, "--languageserver" , "--hostPID", tostring(pid) },
})



