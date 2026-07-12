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

-- Monitor principal: Samsumng C34H89x (3440x1440)
hl.monitor({
    output = "DP-1",
    position = "0x0",
    scale = 1,

    --mode = "preferred",
    mode = "3440x1440@99.982",

    -- VRR (Variable Refresh Rate) usando por  FreeSync/G-Sync del monitor.
    -- > '0' Deshabilita el adaptive sync para ese monitor, '1' lo habilita.
    vrr = 0,

})

-- Monitor secundario: Porpoise HT-1730XT (2560x1440)
hl.monitor({
    output = "HDMI-A-1",
    position = "3440x0",
    scale = 1.25,

    --mode = "preferred",
    mode = "2560x1440@59.951",

    -- VRR (Variable Refresh Rate) usando por  FreeSync/G-Sync del monitor.
    -- > '0' Deshabilita el adaptive sync para ese monitor, '1' lo habilita.
    vrr = 0,
})

-- Opcionales:
-- hl.monitor({ output = "DP-1", mode = "3440x1440@99.982", position = "0x0", scale = 1, vrr = 0 })
-- hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@59.951", position = "3440x0", scale = 1.25, vrr = 0 })



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
