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

hl.config({

    input = {
        kb_layout = "us",
        kb_variant = "altgr-intl",
        numlock_by_default = true,
    },

    -- Windows group
    --group = {
    --},

    --animations = {
    --    enabled = true,
    --    animation = {
    --        "windowsIn, 1, 3, default",
    --        "windowsOut, 1, 3, default",
    --        "workspaces, 1, 5, default",
    --        "windowsMove, 1, 4, default",
    --        "fade, 1, 3, default",
    --        "border, 1, 3, default",
    --    },
    --},

    -- Layout 'dwindle'
    dwindle = {
        preserve_split = true,

        -- Donde se creara el nuevo split:
        --  > 0 Split follows mouse (default)
        --      Dependiendo en que columna esta el cursor de muuse, se crea la ventana
        --  > 1 Always split to the left (new = left or top)
        --  > 2 Always split to the right (new = right or bottom)
        force_split = 2,
    },

    -- Layout 'master'
    master = {
        mfact = 0.5,
    },

    -- Layout 'scrolling'
    scrolling = {
        direction = "right",
        column_width = 0.333,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

})



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
