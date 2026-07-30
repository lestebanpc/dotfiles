-- Miembros publicos del modulo
local mod = {}

-- Miembros privados de inicializacion (modificables por el usuario del modulo)
--local m_custom = {
--    data_1 = nil,
--}

-- Miembros privados constantes
local m_primary = "rgb(42a5f5)"
local m_outline = "rgb(8c9199)"
local m_error   = "rgb(f2b8b5)"
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

hl.config({

    general = {

        -- Color del borde de una ventana
        col = {
            active_border = m_primary,
            inactive_border = m_outline,
        },

    },

    -- Windows group
    group = {

        -- Color del borde de un ventana dentro del grupo
        col = {
            border_active = m_primary,
            border_inactive = m_outline,
            border_locked_active = m_error,
            border_locked_inactive = m_outline,
        },

        -- Color de la pestaña dentro del grupo
        groupbar = {
            col = {
                active = m_primary,
                inactive = m_outline,
                locked_active = m_error,
                locked_inactive = m_outline,
            },
        },
    },

})



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
