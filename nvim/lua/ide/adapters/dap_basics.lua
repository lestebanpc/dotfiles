local dap = require('dap')

local dap_server_path = ""

--------------------------------------------------------------------------------------------------
--DAP Adapters> C# - 'netcoredbg' de Samsung
--------------------------------------------------------------------------------------------------

if (vim.g.os_type == 0) then
    --Si es Windows
    dap_server_path = vim.g.programs_base_path .. '/dap_servers/netcoredbg/netcoredbg.exe'
else
    --Otros casos
    dap_server_path = vim.g.programs_base_path .. '/dap_servers/netcoredbg/netcoredbg'
end

dap.adapters.netcoredbg = {
    type = 'executable',
    command = dap_server_path, 
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

--------------------------------------------------------------------------------------------------
--DAP Adapters> Javascript/Typescript en servidor Node.JS 
---------------------------------------------------------------------------------------------------

--dap.adapters.node2 = {
--	type = "executable",
--	command = "node",
--	args = { vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
--}


--dap.configurations.javascript = {
--	{
--		type = "node2",
--		request = "launch",
--		program = "${file}",
--		cwd = vim.fn.getcwd(),
--		sourceMaps = true,
--		protocol = "inspector",
--		console = "integratedTerminal",
--	},
--}


--------------------------------------------------------------------------------------------------
--DAP Adapters> Javascript/Typescript en Browser 
---------------------------------------------------------------------------------------------------

-- Chrome
--dap.adapters.chrome = {
--	type = "executable",
--	command = "node",
--	args = { vim.fn.stdpath("data") .. "/mason/packages/chrome-debug-adapter/out/src/chromeDebug.js" },
--}


--dap.configurations.javascript = {
--	{
--		type = "chrome",
--		request = "attach",
--		program = "${file}",
--		cwd = vim.fn.getcwd(),
--		sourceMaps = true,
--		protocol = "inspector",
--		port = 9222,
--		webRoot = "${workspaceFolder}",
--	},
--}


--dap.configurations.javascriptreact = {
--	{
--		type = "chrome",
--		request = "attach",
--		program = "${file}",
--		cwd = vim.fn.getcwd(),
--		sourceMaps = true,
--		protocol = "inspector",
--		port = 9222,
--		webRoot = "${workspaceFolder}",
--	},
--}


--dap.configurations.typescriptreact = {
--	{
--		type = "chrome",
--		request = "attach",
--		program = "${file}",
--		cwd = vim.fn.getcwd(),
--		sourceMaps = true,
--		protocol = "inspector",
--		port = 9222,
--		webRoot = "${workspaceFolder}",
--	},
--}


--------------------------------------------------------------------------------------------------
--DAP Adapters> Delve (Go DAP) 
---------------------------------------------------------------------------------------------------

dap.adapters.delve = {
    type = 'server',
    port = '${port}',
    executable = {
        command = 'dlv',
        args = {'dap', '-l', '127.0.0.1:${port}'},
    }
}

--dap.configurations.go = {
--    {
--        type = "delve",
--        name = "Debug",
--        request = "launch",
--        program = "${file}"
--    },
--    {
--        type = "delve",
--        name = "Debug test", -- configuration for debugging test files
--        request = "launch",
--        mode = "test",
--        program = "${file}"
--    },
--    -- works with go.mod packages and sub packages
--    {
--        type = "delve",
--        name = "Debug test (go.mod)",
--        request = "launch",
--        mode = "test",
--        program = "./${relativeFileDirname}"
--    }
--}


