-- Validar si ya se esta cargando o se cargo
if vim.b.ftplg_python_loaded then
    -- Si ya lo cargamos o esta en proceso de carge en este buffer, salimos
    return
end

-- Se inicia la carga del plugin
vim.b.ftplg_python_loaded = true


-- Si no esta habilitado el usar el DAP cliente
local use_adapter = vim.g.use_dap_adapters['python']
if use_adapter == nil or use_adapter ~= true then
    return
end


--------------------------------------------------------------------------------------------------
-- Debugging > Soporte al debugging de test unitarios
--------------------------------------------------------------------------------------------------

local utils = require("utils.python")

local function test_nearest_method()

    -- Obtener el nombre de la clase y metodo mas cercano al cursor actual
    local class_names, method_name = require("utils.ast_navegation").get_nearest_method()
    if not class_names or not method_name then
        print('No test method found near cursor')
        return
    end

    -- Obtener el framerwork de testing a usar
    local tester_type = vim.g.python_tester_type
    if tester_type == nil or tester_type == "" then
        tester_type = utils.get_default_tester()
    end

    if tester_type == nil or tester_type == "" then
        tester_type = "unittest"
    end

    -- Obtener los parametros para ejecutar el tester
    local classes = #class_names == 1 and class_names[1] or class_names
    local module, args = utils.get_params_by_tester(tester_type, classes, method_name)
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

    --config = vim.tbl_extend('force', config, opts.config or {}))

    require("dap").run(config)


end

local function test_nearest_class()

    -- Obtener el nombre de la clase y metodo mas cercano al cursor actual
    local class_names = require("utils.ast_navegation").get_nearest_class()
    if not class_names then
        print('No test class found near cursor')
        return
    end

    -- Obtener el framerwork de testing a usar
    local tester_type = vim.g.python_tester_type
    if tester_type == nil or tester_type == "" then
        tester_type = utils.get_default_tester()
    end

    if tester_type == nil or tester_type == "" then
        tester_type = "unittest"
    end

    -- Obtener los parametros para ejecutar el tester
    local module, args = utils.get_params_by_tester(tester_type, class_names, nil)
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

    --config = vim.tbl_extend('force', config, opts.config or {}))

    require("dap").run(config)


end


-- Keymapping

-- Ejeuctar debug de los test de la clase actual
vim.keymap.set('n', '<space>dtc', test_nearest_class, { noremap = true, buffer = true, desc = 'DAP Run debug nearest class' })

-- Ejeuctar debug de los test de la metodo mas cercado al cursor actual
vim.keymap.set('n', '<space>dtm', test_nearest_method, { noremap = true, buffer = true, desc = 'DAP Run debug nearest method' })

--------------------------------------------------------------------------------------------------
-- Debugging > Otras opciones
--------------------------------------------------------------------------------------------------

local function debug_selected_code()

    -- Obtener el codigo selecionado
    local code = utils.get_selected_code()
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

    --config = vim.tbl_extend('force', config, opts.config or {}))

    require("dap").run(config)


end

-- Ejeuctar debug de los test de la clase actual
vim.keymap.set('v', '<space>dsc', debug_selected_code, { noremap = true, buffer = true, desc = 'DAP Run debug selected code' })
