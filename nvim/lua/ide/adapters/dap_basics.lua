local dap = require('dap')

local dap_server_path = ""

--
-- Respecto a la configuración a nivel proyecto
-- API        : require("dap").configuration
-- URL        : https://github.com/mfussenegger/nvim-dap/blob/master/doc/dap.txt
--
-- Variables que se puede usar:
-- > `${file}`: Active filename
-- > `${fileBasename}`: The current file's basename
-- > `${fileBasenameNoExtension}`: The current file's basename without extension
-- > `${fileDirname}`: The current file's dirname
-- > `${fileExtname}`: The current file's extension
-- > `${relativeFile}`: The current file relative to |getcwd()|
-- > `${relativeFileDirname}`: The current file's dirname relative to |getcwd()|
-- > `${workspaceFolder}`: The current working directory of Neovim
-- > `${workspaceFolderBasename}`: The name of the folder opened in Neovim
-- > `${command:pickProcess}`: Open dialog to pick process using |vim.ui.select|
-- > `${command:pickFile}`: Open dialog to pick file using |vim.ui.select|
-- > `${env:Name}`: Environment variable named `Name`, for example: `${env:HOME}`.


--------------------------------------------------------------------------------------------------
--DAP Adapters> Para C, C++ y Rust
---------------------------------------------------------------------------------------------------

-- Ordenados segun prioridad :
-- > Se adaptador 'cpp_vscode' que esta mejor integrado con nvim-dapui.
-- > Se usara como segun prioridad a adaptadores para LLDB de LLVM.
-- > Como ultima prioridad usando DBG (GNU Linux que soporta DAP).

--
-- DAP Server : El adapador DAP 'cppdbg' de Microsoft para VSCode
--              El Linux, el adapador funciona con GDB y LLDB (prioridad GBD).
--              En MacOS, el adapador funciona con LLDB.
--              El Windows, el adapador funciona con los debugger LLDB y MSVC (require licencia).
-- URL        : https://github.com/Microsoft/vscode-cpptools
-- Docs       :
-- Install    : Descargar de la pagina o del Marketplace de VSCode.
-- Validate   : lldb --version
--              which codelldb
--
local detached = true

if (vim.g.os_type == 0) then
    --Si es Windows
    dap_server_path = vim.g.programs_base_path .. '/vsc_extensions/ms_cpptools/debugAdapters/bin/OpenDebugAD7.cmd'
    detached = false
else
    --Otros casos
    dap_server_path = vim.g.programs_base_path .. '/vsc_extensions/ms_cpptools/debugAdapters/bin/OpenDebugAD7'
end

local use_adapter = vim.g.use_dap_adapters['cpp_vscode']

if use_adapter ~= nil and use_adapter == true then

    -- Configuracion del cliente DAP y/o su adapador.
    dap.adapters.cppdbg = {
        id = 'cppdbg',
        type = 'executable',
        command = dap_server_path,
        options = {
            detached = detached
        }
    }

    -- Configuracion del proyecto C/C++ (Usar archivo '.vscode/launch.json' para modificar estos valores)
    dap.configurations.cpp = {
        {
            name = "Launch file",
            type = "cppdbg",
            request = "launch",
            program = function()
              return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = '${workspaceFolder}',
            stopAtEntry = true,
        },
        {
            name = 'Attach to gdbserver :1234',
            type = 'cppdbg',
            request = 'launch',
            MIMode = 'gdb',
            miDebuggerServerAddress = 'localhost:1234',
            miDebuggerPath = '/usr/bin/gdb',
            cwd = '${workspaceFolder}',
            program = function()
              return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
        },
    }

    dap.configurations.c = dap.configurations.cpp

    -- Configuracion del proyecto Rust (Usar el archivo '.vscode/launch.json' para modificar estos valores)
    dap.configurations.rust = dap.configurations.cpp

end

-- Almacenar anterior estado
local old_use_adapter = use_adapter


--
-- DAP Server : Usando su adapador DAP 'lldb-dap' nativo del debugger LLDB (parte del proyecto LLVM) .
-- URL        : https://github.com/llvm/llvm-project/tree/main/lldb/tools/lldb-dap#configuration-settings-reference
-- Docs       : https://github.com/llvm/llvm-project/blob/main/lldb/tools/lldb-dap/package.json
-- Install    : Usar paquete del SO.
-- Validate   : lldb --version
--              which lldb-dap
--
use_adapter = vim.g.use_dap_adapters['cpp_lldb_dap']

if use_adapter ~= nil and use_adapter == true and (old_use_adapter == nil or old_use_adapter == false) then

    -- Configuracion del cliente DAP y/o su adapador.
    dap.adapters.lldb = {
        type = 'executable',
        command = 'lldb-dap', -- adjust as needed, must be absolute path
        name = 'lldb'
    }

    -- Configuracion del proyecto C/C++ (Usar el archivo '.vscode/launch.json' para modificar estos valores)
    dap.configurations.cpp = {
        {
            name = 'Launch',
            type = 'lldb',
            request = 'launch',
            program = function()
              return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
            args = {},

            -- inherit the environment variables from the parent
            env = function()
                local variables = {}
                for k, v in pairs(vim.fn.environ()) do
                    table.insert(variables, string.format("%s=%s", k, v))
                end
                return variables
            end,
        },
    }

    dap.configurations.c = dap.configurations.cpp

    -- Configuracion del proyecto Rust (Usar el archivo '.vscode/launch.json' para modificar estos valores)
    dap.configurations.rust = {
        {
            name = 'Launch',
            type = 'lldb',
            request = 'launch',
            program = function()
              return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
            args = {},

            -- inherit the environment variables from the parent
            env = function()
                local variables = {}
                for k, v in pairs(vim.fn.environ()) do
                    table.insert(variables, string.format("%s=%s", k, v))
                end
                return variables
            end,

            -- You can get rust types
            initCommands = function()

                -- Find out where to look for the pretty printer Python module.
                local rustc_sysroot = vim.fn.trim(vim.fn.system 'rustc --print sysroot')
                assert(
                    vim.v.shell_error == 0,
                    'failed to get rust sysroot using `rustc --print sysroot`: ' .. rustc_sysroot
                )
                local script_file = rustc_sysroot .. '/lib/rustlib/etc/lldb_lookup.py'
                local commands_file = rustc_sysroot .. '/lib/rustlib/etc/lldb_commands'

                -- The following is a table/list of lldb commands, which have a syntax
                -- similar to shell commands.
                return {
                    ([[!command script import '%s']]):format(script_file),
                    ([[command source '%s']]):format(commands_file),
                }
            end,
        },
    }

end

-- Almacenar anterior estado
old_use_adapter = use_adapter


--
-- DAP Server : Usando el adapador DAP 'codelldb' del debugger LLDB (parte del proyecto LLVM)
-- URL        : https://github.com/vadimcn/codelldb
-- Docs       : https://github.com/vadimcn/codelldb/blob/master/MANUAL.md
-- Install    : Descargar de la pagina.
-- Validate   : lldb --version
--              which codelldb
--
detached = true

if (vim.g.os_type == 0) then
    --Si es Windows
    dap_server_path = vim.g.programs_base_path .. '/vsc_extensions/codelldb/adapter/codelldb.exe'
    detached = false
else
    --Otros casos
    dap_server_path = vim.g.programs_base_path .. '/vsc_extensions/codelldb/adapter/codelldb'
end

use_adapter = vim.g.use_dap_adapters['cpp_lldb_code']

if use_adapter ~= nil and use_adapter == true and (old_use_adapter == nil or old_use_adapter == false) then

    -- Configuracion del cliente DAP y/o su adapador.
    dap.adapters.codelldb = {
        type = "executable",
        command = dap_server_path,
        detached = detached,
    }

    -- Configuracion del proyecto C/C++ (Usar el archivo '.vscode/launch.json' para modificar estos valores)
    dap.configurations.cpp = {
        {
            name = "Launch file",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
        },
    }

    dap.configurations.c = dap.configurations.cpp

    -- Configuracion del proyecto Rust (Usar el archivo '.vscode/launch.json' para modificar estos valores)
    dap.configurations.rust = dap.configurations.cpp

end

-- Almacenar anterior estado
old_use_adapter = use_adapter


--
-- DAP Server : GDB (nativo de GNU Linux y tambien se comporta como DAP server)
-- URL        :
-- Docs       : https://sourceware.org/gdb/current/onlinedocs/gdb#Debugger-Adapter-Protocol
-- Install    : Usar paquete del SO.
-- Validate   : gdb --version
--
use_adapter = vim.g.use_dap_adapters['cpp_gdb']

if use_adapter ~= nil and use_adapter == true and (old_use_adapter == nil or old_use_adapter == false) then

    -- Configuracion del cliente DAP y/o su adapador.
    dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" }
    }

    -- Configuracion del proyecto C/C++ (Usar archivo '.vscode/launch.json' para modificar estos valores)
    dap.configurations.c = {
        {
            name = "Launch",
            type = "gdb",
            request = "launch",
            program = function()
              return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = "${workspaceFolder}",
            stopAtBeginningOfMainSubprogram = false,
        },
        {
            name = "Select and attach to process",
            type = "gdb",
            request = "attach",
            program = function()
               return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            pid = function()
               local name = vim.fn.input('Executable name (filter): ')
               return require("dap.utils").pick_process({ filter = name })
            end,
            cwd = '${workspaceFolder}'
        },
        {
            name = 'Attach to gdbserver :1234',
            type = 'gdb',
            request = 'attach',
            target = 'localhost:1234',
            program = function()
               return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = '${workspaceFolder}'
        },
    }

    dap.configurations.c = dap.configurations.cpp

    -- Configuracion del proyecto Rust (Usar archivo '.vscode/launch.json' para modificar estos valores)
    dap.configurations.rust = dap.configurations.cpp

end

-- Almacenar anterior estado
--old_use_adapter = use_adapter


--------------------------------------------------------------------------------------------------
--DAP Adapters> Para GoLang
---------------------------------------------------------------------------------------------------

-- Segun el orden de priioridad :
-- > El adapador de vscode es mucho mas maduro y Establecer
-- > El soporte nativo de 'delve' es experimental

--
-- DAP Server : Adaptador DAP 'vscode-go' para el debugger Delve de GoLang.
-- URL        : https://github.com/golang/vscode-go
-- Install    : go install github.com/go-delve/delve/cmd/dlv@latest
--              Descargar la extension del repositorio o Marketplace de VSCode.
-- Validate   :
--
use_adapter = vim.g.use_dap_adapters['go_vscode']

if (vim.g.os_type == 0) then
    --Si es Windows
    dap_server_path = vim.g.programs_base_path .. '/vsc_extensions/go_tools/dist/debugAdapter.js'
else
    --Otros casos
    dap_server_path = vim.g.programs_base_path .. '/vsc_extensions/go_tools/dist/debugAdapter.js'
end

if use_adapter ~= nil and use_adapter == true then

    -- Configuracion del cliente DAP y/o su adapador.
    dap.adapters.go = {
        type = 'executable';
        command = 'node';
        args = { dap_server_path };
    }

    -- Configuracion del proyecto (NO USAR. Usar archivo '.vscode/launch.json')
    dap.configurations.go = {
        {
            type = 'go';
            name = 'Debug';
            request = 'launch';
            showLog = false;
            program = "${file}";
            dlvToolPath = vim.fn.exepath('dlv')  -- Adjust to where delve is installed
        },
    }


end

-- Almacenar anterior estado
old_use_adapter = use_adapter


--
-- DAP Server : Adaptador DAP nativo el debugger Delve de GoLang (Modo experimental)
-- URL        : https://github.com/go-delve/delve/tree/master/Documentation/installation
-- Install    : go install github.com/go-delve/delve/cmd/dlv@latest
-- Validate   : dlv version
--
detached = true

if (vim.g.os_type == 0) then
    --Si es Windows
    detached = false
end

use_adapter = vim.g.use_dap_adapters['go_native']

if use_adapter ~= nil and use_adapter == true and (old_use_adapter == nil or old_use_adapter == false) then

    -- Configuracion del cliente DAP y/o su adapador.
    dap.adapters.delve = function(callback, config)

        -- Inicio de servidor delve automaticamente
        if config.mode == 'remote' and config.request == 'attach' then
            callback({
                type = 'server',
                host = config.host or '127.0.0.1',
                port = config.port or '38697'
            })
        else
            callback({
                type = 'server',
                port = '${port}',
                executable = {
                    command = 'dlv',
                    args = { 'dap', '-l', '127.0.0.1:${port}', '--log', '--log-output=dap' },
                    detached = detached,
                }
            })
        end
    end


    -- Configuracion del proyecto (NO USAR. Usar archivo '.vscode/launch.json')
    dap.configurations.go = {
        {
            type = "delve",
            name = "Debug",
            request = "launch",
            program = "${file}"
        },
        {
            type = "delve",
            name = "Debug test", -- configuration for debugging test files
            request = "launch",
            mode = "test",
            program = "${file}"
        },
        -- works with go.mod packages and sub packages
        {
            type = "delve",
            name = "Debug test (go.mod)",
            request = "launch",
            mode = "test",
            program = "./${relativeFileDirname}"
        }
    }

end


--------------------------------------------------------------------------------------------------
--DAP Adapters> Para C#
--------------------------------------------------------------------------------------------------

--
-- DAP Server : NetCoreDbg de Samsumg
-- URL        : https://github.com/Samsung/netcoredbg
-- Install    : Descargar el binario
-- Validate   :
--
use_adapter = vim.g.use_dap_adapters['csharp']

if use_adapter ~= nil and use_adapter == true then

    -- Configuracion del cliente DAP y/o su adapador.
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
        args = { '--interpreter=vscode' }
    }


    -- Configuracion del proyecto (NO USAR. Usar archivo '.vscode/launch.json')
    dap.configurations.cs = {
        {
            type = "netcoredbg",
            name = "launch - netcoredbg",
            request = "launch",
            program = function()
                return vim.fn.input('Path to debugging assembly? ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
            end,
        },
    }

end


--------------------------------------------------------------------------------------------------
--DAP Adapters> Para Swift
---------------------------------------------------------------------------------------------------

--
-- DAP Server :
-- URL        :
-- Install    :
-- Validate   :
--
use_adapter = vim.g.use_dap_adapters['swift']

if use_adapter ~= nil and use_adapter == true then

    -- Configuracion del cliente DAP y/o su adapador.

    -- Configuracion del proyecto (NO USAR. Usar archivo '.vscode/launch.json')

end


--------------------------------------------------------------------------------------------------
--DAP Adapters> Para Kotlin
---------------------------------------------------------------------------------------------------

--
-- DAP Server :
-- URL        :
-- Install    :
-- Validate   :
--
use_adapter = vim.g.use_dap_adapters['kotlin']

if use_adapter ~= nil and use_adapter == true then

    -- Configuracion del cliente DAP y/o su adapador.

    -- Configuracion del proyecto (NO USAR. Usar archivo '.vscode/launch.json')

end


--------------------------------------------------------------------------------------------------
--DAP Adapters> Para Python
---------------------------------------------------------------------------------------------------

--
-- DAP Server : Adaptador 'debugpy' del depurador de Python.
-- URL        : https://github.com/microsoft/debugpy
-- Install    : pip install --user debugpy
-- Validate   : debugpy --version
--
use_adapter = vim.g.use_dap_adapters['python']

if use_adapter ~= nil and use_adapter == true then

    -- Configuracion del cliente DAP y/o su adapador.
    dap.adapters.python = function(cb, config)
        if config.request == 'attach' then
            ---@diagnostic disable-next-line: undefined-field
            local port = (config.connect or config).port
            ---@diagnostic disable-next-line: undefined-field
            local host = (config.connect or config).host or '127.0.0.1'
            cb({
                type = 'server',
                port = assert(port, '`connect.port` is required for a python `attach` configuration'),
                host = host,
                options = {
                  source_filetype = 'python',
                },
            })
        else
            cb({
                type = 'executable',
                command = 'path/to/virtualenvs/debugpy/bin/python',
                args = { '-m', 'debugpy.adapter' },
                options = {
                  source_filetype = 'python',
                },
            })
        end
    end


    -- Configuracion del proyecto (NO USAR. Usar archivo '.vscode/launch.json')
    dap.configurations.python = {
        {
            -- The first three options are required by nvim-dap
            type = 'python'; -- the type here established the link to the adapter definition: `dap.adapters.python`
            request = 'launch';
            name = "Launch file";

            -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

            program = "${file}"; -- This configuration will launch the current file if used.
            pythonPath = function()
                -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
                -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
                -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
                local cwd = vim.fn.getcwd()
                if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                    return cwd .. '/venv/bin/python'
                elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                    return cwd .. '/.venv/bin/python'
                else
                    return '/usr/bin/python'
                end
            end;
        },
    }

end


--------------------------------------------------------------------------------------------------
--DAP Adapters> Para Javascript/Typescript
---------------------------------------------------------------------------------------------------

--
-- DAP Server : Debugger de Microsoft 'vscode-js-debug' que soporta DAP.
-- URL        : https://github.com/microsoft/vscode-js-debug
-- Install    : Descargar de pagina o del Marketplace de VSCode.
-- Validate   :
--
if (vim.g.os_type == 0) then
    --Si es Windows
    dap_server_path = vim.g.programs_base_path .. '/vsc_extensions/ms_js_debug/src/go_tools/dist/dapDebugServer.js'
else
    --Otros casos
    dap_server_path = vim.g.programs_base_path .. '/vsc_extensions/ms_js_debug/src/go_tools/dist/dapDebugServer.js'
end

use_adapter = vim.g.use_dap_adapters['typescript']

if use_adapter ~= nil and use_adapter == true then

    -- Configuracion del cliente DAP y/o su adapador.
    dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
            command = "node",
            args = { dap_server_path, "${port}" },
       }
    }


    -- Configuracion del proyecto JS/TS (Usar archivo '.vscode/launch.json' para modificar estos valores)
    dap.configurations.javascript = {
        {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
        },
    }


end
