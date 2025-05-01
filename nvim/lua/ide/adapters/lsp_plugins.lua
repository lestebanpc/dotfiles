--
-- Aqui configure los cliente LSP cuyo adaptadores son creados por un plugin
--
--local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
local lsp_server_path = ""

--------------------------------------------------------------------------------------------------
-- LSP Client Adapter> Adaptador del cliente LSP para 'Roslyn LSP' para C#
--------------------------------------------------------------------------------------------------
--
-- URL: https://github.com/seblyng/roslyn.nvim
--

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



--------------------------------------------------------------------------------------------------
-- LSP Client Adapter> Adaptador del cliente LSP para 'Eclipse JDTLS' para Java SE
--------------------------------------------------------------------------------------------------
--
-- Vease ./ftplugin/java.lua
--

-- Additional mappings:
--nnoremap <A-o> <Cmd>lua require'jdtls'.organize_imports()<CR>
--nnoremap crv <Cmd>lua require('jdtls').extract_variable()<CR>
--vnoremap crv <Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>
--nnoremap crc <Cmd>lua require('jdtls').extract_constant()<CR>
--vnoremap crc <Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>
--vnoremap crm <Esc><Cmd>lua require('jdtls').extract_method(true)<CR>


