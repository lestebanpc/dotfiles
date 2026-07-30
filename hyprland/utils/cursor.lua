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

-- Variables de entorno para los cursores
hl.env("HYPRCURSOR_THEME", "default")
hl.env("XCURSOR_THEME", "default")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_SIZE", "24")

------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
