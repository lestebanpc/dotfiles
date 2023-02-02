--------------------------------------------------------------------------------------------------
--LSP Client> Configuracion del LSP cliente para C#
--------------------------------------------------------------------------------------------------

local pid = vim.fn.getpid()

require('lspconfig').omnisharp.setup({
    cmd = { vim.g.lsp_server_cs_path },
    --cmd = { vim.g.lsp_server_cs_pat, "--languageserver" , "--hostPID", tostring(pid) },
    --cmd = { 'dotnet', '/mnt/d/Tools/Cmds/Windows/omnisharp-roslyn/OmniSharp.dll' },
})


--------------------------------------------------------------------------------------------------
--DAP Client> Configuracion del DAP Client nVim.DAP
--------------------------------------------------------------------------------------------------

local dap = require('dap')

dap.adapters.netcoredbg = {
  type = 'executable',
  command = '/opt/tools/dap_adapters/netcoredbg/netcoredbg',
  args = {'--interpreter=vscode'}
}

--dap.configurations.cs = {
--  {
--    type = "netcoredbg",
--    name = "launch - netcoredbg",
--    request = "launch",
--    program = function()
--        return vim.fn.input('Path to debugging assembly? ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
--    end,
--  },
--}


