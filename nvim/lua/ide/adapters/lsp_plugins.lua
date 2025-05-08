--
-- Aqui configure los cliente LSP cuyo adaptadores son creados por un plugin
--
--local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
local lsp_server_path = ""

--------------------------------------------------------------------------------------------------
-- LSP Client> Para C#
--------------------------------------------------------------------------------------------------

--
-- LSP Server : Roslyn LS para C#
-- URL: https://github.com/seblyng/roslyn.nvim
--

local use_adapter = vim.g.use_lsp_adapters['csharp']

if use_adapter ~= nil and use_adapter == true then

    if (vim.g.os_type == 0) then
        --Si es Windows
        lsp_server_path = vim.g.programs_base_path .. '/lsp_servers/roslyn_ls/Microsoft.CodeAnalysis.LanguageServer.dll'
    else
        lsp_server_path = vim.g.programs_base_path .. '/lsp_servers/roslyn_ls/Microsoft.CodeAnalysis.LanguageServer.dll'
    end

    local roslyn_cfg = require('roslyn')

    roslyn_cfg.setup({
        config = {
            cmd = {
                "dotnet",
                lsp_server_path,
                "--logLevel=Information",
                "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
                "--stdio",
            },
        },
      })

end

--------------------------------------------------------------------------------------------------
-- LSP Client Adapter> Adaptador del cliente LSP para 'Eclipse JDTLS' para Java SE
--------------------------------------------------------------------------------------------------
--
-- Vease ./ftplugin/java.lua
--
