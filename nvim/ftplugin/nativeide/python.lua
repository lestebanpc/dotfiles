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


-- Keymapping

-- Ejeuctar debug de los test de la clase actual
vim.keymap.set('n', '<space>dtc', utils.test_nearest_class, { noremap = true, buffer = true, desc = 'DAP Run debug nearest class' })

-- Ejeuctar debug de los test de la metodo mas cercado al cursor actual
vim.keymap.set('n', '<space>dtm', utils.test_nearest_method, { noremap = true, buffer = true, desc = 'DAP Run debug nearest method' })

--------------------------------------------------------------------------------------------------
-- Debugging > Otras opciones
--------------------------------------------------------------------------------------------------


-- Ejeuctar debug de los test de la clase actual
vim.keymap.set('v', '<space>dsc', utils.debug_selected_code, { noremap = true, buffer = true, desc = 'DAP Run debug selected code' })
