-- Miembros publicos del modulo
local mod = {}

-- Miembros privados de inicializacion (modificables por el usuario del modulo)
--local m_custom = {
--    data_1 = nil,
--}

-- Miembros privados constantes
--local mm_ucommon = require("utils.common")

-- Miembros privados no constantes
--local m_data_2 = nil



------------------------------------------------------------------------------------
-- Module Inicialization
------------------------------------------------------------------------------------

--function mod.setup(
--    p_data_1)
--
--    m_custom.data_1 = p_data_1
--
--end



------------------------------------------------------------------------------------
-- Main Logic
------------------------------------------------------------------------------------

local function m_create_ws_rule(p_id, p_monitor, p_layout, p_default)

    local rule = { workspace = tostring(p_id), monitor = p_monitor }

    if p_layout ~= nil then
        rule.layout = p_layout
    end

    if p_default ~= nil then
        rule.default = p_default
    end

    hl.workspace_rule(rule)

end

-- Monitor principal con layout por defecto ('dwindle')
m_create_ws_rule(1, "DP-1", "scrolling", true)

for i = 2, 7 do
    m_create_ws_rule(i, "DP-1", nil, false)
end

-- Monitor secundario con un layout diferente
m_create_ws_rule(8, "HDMI-A-1", "scrolling", true)
m_create_ws_rule(9, "HDMI-A-1", "scrolling", false)



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
