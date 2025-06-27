local M = {}



-- Si la configuracion ingresada no define la ruta de python o la funcion para calcular la ruta
-- se usara una funcion para obtener la ruta del venv usado por el proyecto
local function enrich_dap_config(config, on_config)

    if not config.pythonPath and not config.python then

        local pythonPath = require("utils.python").get_venv_python_path()
        if pythonPath == nil or pythonPath == "" then
            -- Si es Linux
            if vim.g.os_type == 2 or vim.g.os_type == 3 then
                pythonPath = 'python3'
            else
                pythonPath = 'python'
            end
        end
        config.pythonPath = pythonPath

    end

    on_config(config)

end

-- Inicializar el DAP client usando la configuracion ingresada por el usuario.
function M.setup_dap_adapter(cb, config)

    -- Parametros del DAP client
    local adapter

    -- Si el cliente DAP se vincula a un servidor DAP (proceso 'debugpy')
    -- > El servidor DAP esta enlazado a un programa a depurar que esta en ejecución.
    -- > El cliente DAP tiene los archivos de codigo (no requiere el RTE del programa), y 'path mappings'
    if config.request == 'attach' then

        local port = (config.connect or config).port
        local host = (config.connect or config).host or '127.0.0.1'
        adapter = {
            type = 'server',
            port = assert(port, '`connect.port` is required for a python `attach` configuration'),
            host = host,
            --enrich_config = enrich_config,
            options = {
              source_filetype = 'python',
            },
        }

    -- Si el cliente DAP inicia el servidor DAP y programa a depurar.
    -- > El cliente DAP crea el servidor DAP usando un determino interprete python (no es necesariamente el mismo del proyecto).
    -- > El cliente DAP tambien ejecuta programa a depurar el debe usar el interprete python asociado al proyecto.
    else

        local cmd = vim.g.dap_launcher_python

        local basename
        if cmd == nil or cmd == "" then

            -- Si es Linux
            if vim.g.os_type == 2 or vim.g.os_type == 3 then
                cmd = 'python3'
                basename = cmd
            else
                cmd = 'python'
                basename = cmd
            end

        else
            cmd = vim.fn.expand(vim.fn.trim(cmd), true)
            basename = vim.fn.fnamemodify(cmd, ":t")
        end

        adapter= {
            type = 'executable',
            command = cmd,
            args = { '-m', 'debugpy.adapter' },
            enrich_config = enrich_dap_config,
            options = {
              source_filetype = 'python',
            },
        }

        if basename == "uv" then
            adapter.args = { "run", "--with", "debugpy", "python", "-m", "debugpy.adapter" }
        elseif basename == "debugpy-adapter" then
            adapter.args = {}
        end

    end

    -- Inicalizar el cliente DAP
    cb(adapter)

end




local function get_roots()

    return coroutine.wrap(function()

        -- Directorio de trabajo actual de vim
        local cwd = vim.fn.getcwd()
        coroutine.yield(cwd)

        -- Directorio de trabajo del archivo actual (ventana actual)
        local wincwd = vim.fn.getcwd(0)
        if wincwd ~= cwd then
        coroutine.yield(wincwd)
        end

        -- Obtiene los 'root_dir' de los cliente LSP vinculados al archivo actual
        local get_clients = vim.lsp.get_clients
        for _, client in ipairs(get_clients()) do
            if client.config.root_dir then
                coroutine.yield(client.config.root_dir)
            end
        end

    end)


end


--- Devuelve la ruta de 'python' dentro de un determinado venv asociado al proyecto.
---@return string|nil
function M.get_venv_python_path()

    local venv_path = os.getenv('VIRTUAL_ENV')
    if venv_path then
        -- Si es Windows
        if vim.g.os_type == 0 then
            return venv_path .. '\\scripts\\python.exe'
        end

        -- Si no es Windows
        return venv_path .. '/bin/python'
    end

    venv_path = os.getenv("CONDA_PREFIX")
    if venv_path then
        -- Si es Windows
        if vim.g.os_type == 0 then
            return venv_path .. '\\python.exe'
        end

        -- Si no es Windows
        return venv_path .. '/bin/python'
    end

    local stat = ''
    for root in get_roots() do
        for _, folder in ipairs({ "venv", ".venv", "env", ".env" }) do
            venv_path = root .. "/" .. folder
            stat = vim.loop.fs_stat(venv_path)
            if stat and stat.type == "directory" then
                -- Si es Windows
                if vim.g.os_type == 0 then
                    return venv_path .. '\\scripts\\python.exe'
                end

                -- Si no es Windows
                return venv_path .. '/bin/python'
            end
        end
    end

end


--- Strips extra whitespace at the start of the lines
--  Ejemplo: >>> remove_indent({'    print(10)', '    if True:', '        print(20)'})
--  Output:  {'print(10)', 'if True:', '    print(20)'}
---@param lines string[]
---@return string[]
local function remove_indent(lines)

    local offset = nil
    for _, line in ipairs(lines) do
        local first_non_ws = line:find('[^%s]') or 0
        if first_non_ws >= 1 and (not offset or first_non_ws < offset) then
            offset = first_non_ws
        end
    end

    if offset > 1 then
        assert(offset)
        return vim.tbl_map(function(x) return string.sub(x, offset) end, lines)
    else
        return lines
    end

end



--- Devuelve el codigo selecionado
---@return string|nil
local function get_selected_code()

    local start_row, _ = unpack(vim.api.nvim_buf_get_mark(0, '<'))
    local end_row, _ = unpack(vim.api.nvim_buf_get_mark(0, '>'))
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    local code = table.concat(remove_indent(lines), '\n')
    return code

end


-- Supported test frameworks are unittest, pytest and django.
-- By default it tries to detect the runner by probing for presence of pytest.ini or manage.py, or for a tool.pytest
-- directive inside pyproject.toml, if none are present it defaults to unittest.
local function get_default_tester()

  for root in get_roots() do
    if vim.loop.fs_stat(root .. "/pytest.ini") then
      return "pytest"
    elseif vim.loop.fs_stat(root .. "/manage.py") then
      return "django"
    elseif vim.loop.fs_stat(root .. "/pyproject.toml") then
      local f = io.open(root .. "/pyproject.toml")
      if f then
        for line in f:lines() do
          if line:find("%[tool.pytest") then
            f:close()
            return "pytest"
          end
        end
        f:close()
      end
    end
  end

  return "unittest"

end



local function get_params_by_tester(tester_type, class_names, method_name)

    local data
    local args
    local test_path
    if tester_type == "unittest" then

        -- Obtener del nombre del modulo python
        local module_name

        if vim.g.os_type == 0 then
            -- Si es Windows
            module_name = vim.fn.expand('%:.:r:gs?\\?.?')
        else
            module_name = vim.fn.expand('%:.:r:gs?/?.?')
        end

        -- Concatenar y obtener la ruta de elemento a realizar las pruebas
        data = { module_name, class_names, method_name }
        data = vim.iter(data):flatten(2):totable()

        test_path = table.concat(data, '.')
        args = {'-v', test_path}

        return "unittest", args

    end

    if tester_type == "pytest" then

        -- Obtener la ruta del archivo del modulo
        local file_path = vim.fn.expand('%:p')

        -- Concatenar y obtener la ruta de elemento a realizar las pruebas
        data = { file_path, class_names, method_name }
        data = vim.iter(data):flatten(2):totable()

        test_path = table.concat(data, '::')
        args = {'-s', test_path}

        return "pytest", args

    end

    if tester_type == "django" then

        -- Obtener del nombre del modulo python
        local module_name

        if vim.g.os_type == 0 then
            -- Si es Windows
            module_name = vim.fn.expand('%:.:r:gs?\\?.?')
        else
            module_name = vim.fn.expand('%:.:r:gs?/?.?')
        end

        -- Concatenar y obtener la ruta de elemento a realizar las pruebas
        data = { module_name, class_names, method_name }
        data = vim.iter(data):flatten(2):totable()

        test_path = table.concat(data, '.')
        args = {'test', test_path}

        return "django", args

    end

end



function M.test_nearest_method()

    -- Obtener el nombre de la clase y metodo mas cercano al cursor actual
    local class_names, method_name = require("utils.ast_navegation").get_nearest_method()
    if not class_names or not method_name then
        print('No test method found near cursor')
        return
    end

    -- Obtener el framerwork de testing a usar
    local tester_type = vim.g.python_tester_type
    if tester_type == nil or tester_type == "" then
        tester_type = get_default_tester()
    end

    if tester_type == nil or tester_type == "" then
        tester_type = "unittest"
    end

    -- Obtener los parametros para ejecutar el tester
    local classes = #class_names == 1 and class_names[1] or class_names
    local module, args = get_params_by_tester(tester_type, classes, method_name)
    if not module or not args then
        vim.notify('Testing framerwork `' .. tester_type .. '` is not supported', vim.log.levels.WARN)
        return
    end

    -- Crear la configuracion pora ejecutar dap
    local data = { class_names, method_name }
    data = vim.iter(data):flatten(2):totable()

    local config = {
        name = table.concat(data, '.'),
        type = 'python',
        request = 'launch',
        module = module,
        args = args,
        -- Puede ser "internalConsole", "integratedTerminal" o "externalTerminal"
        console = 'integratedTerminal'
    }


    if vim.g.use_tmux then
        config.console = 'externalTerminal'
    end

    --config = vim.tbl_extend('force', config, opts.config or {}))

    require("dap").run(config)


end



function M.test_nearest_class()

    -- Obtener el nombre de la clase y metodo mas cercano al cursor actual
    local class_names = require("utils.ast_navegation").get_nearest_class()
    if not class_names then
        print('No test class found near cursor')
        return
    end

    -- Obtener el framerwork de testing a usar
    local tester_type = vim.g.python_tester_type
    if tester_type == nil or tester_type == "" then
        tester_type = get_default_tester()
    end

    if tester_type == nil or tester_type == "" then
        tester_type = "unittest"
    end

    -- Obtener los parametros para ejecutar el tester
    local module, args = get_params_by_tester(tester_type, class_names, nil)
    if not module or not args then
        vim.notify('Testing framerwork `' .. tester_type .. '` is not supported', vim.log.levels.WARN)
        return
    end

    -- Crear la configuracion pora ejecutar dap
    local data = { class_names, nil }
    data = vim.iter(data):flatten(2):totable()

    local config = {
        name = table.concat(data, '.'),
        type = 'python',
        request = 'launch',
        module = module,
        args = args,
        -- Puede ser "internalConsole", "integratedTerminal" o "externalTerminal"
        console = 'integratedTerminal'
    }


    if vim.g.use_tmux then
        config.console = 'externalTerminal'
    end


    --config = vim.tbl_extend('force', config, opts.config or {}))

    require("dap").run(config)


end


function M.debug_selected_code()

    -- Obtener el codigo selecionado
    local code = get_selected_code()
    if code == nil or code == "" then
        print('No hay codigo selecionado')
        return
    end

    -- Crear la configuracion pora ejecutar dap
    local config = {
        name = 'Launch selected code',
        type = 'python',
        request = 'launch',
        code = code,
        -- Puede ser "internalConsole", "integratedTerminal" o "externalTerminal"
        console = 'integratedTerminal'
    }


    if vim.g.use_tmux then
        config.console = 'externalTerminal'
    end

    --config = vim.tbl_extend('force', config, opts.config or {}))

    require("dap").run(config)


end


return M
