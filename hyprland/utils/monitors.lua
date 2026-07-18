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

-- Monitor principal : Samsumng Odyssey G75F HNTL200016
-- Resolucion Fisica : 5120x2160
-- Escala            : 1.25
-- Resolucion Logica : 4096x1728
hl.monitor({
    output = "DP-1",

    -- Posicion en el lienzo logico de hyprland (usa la resolucion logica)
    position = "0x0",
    scale = 1.25,

    mode = "preferred",
    --mode = "5120x2160@179.99",
    --mode = "5120x2160@120.00",
    --mode = "5120x2160@59.98",

    -- VRR (Variable Refresh Rate) usando por  FreeSync/G-Sync del monitor.
    -- > '0' Deshabilita el adaptive sync para ese monitor, '1' lo habilita.
    vrr = 0,

})

-- Monitor secundario: Porpoise HT-1730XT
-- Resolucion Fisica : 2560x1440
-- Escala            : 1.25
-- Resolucion Logica : 2048x1152
hl.monitor({
    output = "HDMI-A-1",

    -- Posicion en el lienzo logico de hyprland (usa la resolucion logica)
    position = "4096x0",
    scale = 1.25,

    mode = "preferred",
    --mode = "2560x1440@59.951",

    -- VRR (Variable Refresh Rate) usando por  FreeSync/G-Sync del monitor.
    -- > '0' Deshabilita el adaptive sync para ese monitor, '1' lo habilita.
    vrr = 0,
})



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
