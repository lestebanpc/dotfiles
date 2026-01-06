
-- Configurar ruta para módulos internos
package.path = package.path .. ";" .. self:plugin_dir() .. "/?.lua"


-- Cargar módulos
local mm_utils = require("utils")
local mm_fzf_fd = require("fzf_fd")

local m_config = mm_utils.get_custom_config()

-- Definir subcomandos del plugin
local mod = {

    --- @sync find
    entry = function(self, job)
        mm_fzf_fd.execute_search(self, job, config)
    end,

    ----- @sync config
    --config = function(self, job)
    --    ya.notify({
    --        title = "Configuración de fzf-fd",
    --        content = "Usando:\n- fd: " .. m_config.commands.fd ..
    --                 "\n- fzf: " .. m_config.commands.fzf ..
    --                 "\nExclusiones: " .. table.concat(m_config.fd_exclude, ", ")
    --    })
    --end
}

return mod
