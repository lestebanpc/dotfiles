
local pid = vim.fn.getpid()

require('lspconfig').omnisharp.setup({
    cmd = { vim.g.lsp_server_cs_path },
    --cmd = { vim.g.lsp_server_cs_pat, "--languageserver" , "--hostPID", tostring(pid) },
    --cmd = { 'dotnet', '/mnt/d/Tools/Cmds/Windows/omnisharp-roslyn/OmniSharp.dll' },
})



