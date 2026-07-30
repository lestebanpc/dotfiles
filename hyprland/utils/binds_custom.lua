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
-- Keybindings> System Application Launchers
------------------------------------------------------------------------------------

-- Color picker (Copiar al clipboard el RGB en formato hexadecimal, ejemplo 'FF8040')
--hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("dms color pick -o \"{0}{1}{2}\" -a"))

-- Optional: if you use submaps later
-- hl.bind("SUPER + Escape", hl.dsp.submap("reset"))



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
