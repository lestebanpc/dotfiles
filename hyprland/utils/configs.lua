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

    input = {
        kb_layout = "us",
        kb_variant = "altgr-intl",
        numlock_by_default = true,
    },

    general = {
        -- Espacio de la ventana el final de la pantalla del monitor
        gaps_in = 1,

        -- Espacio entre ventanas
        gaps_out = 2,

        -- Borde de la ventana
        border_size = 1,

        -- Layout por defecto
        layout = "dwindle",

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

    decoration = {
        -- Redondes del borde de la ventana
        rounding = 8,

        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 30,
            render_power = 5,
            offset = "0 5",
            color = "rgba(00000070)",
        },
    },

    animations = {
        enabled = true,
        animation = {
            "windowsIn, 1, 3, default",
            "windowsOut, 1, 3, default",
            "workspaces, 1, 5, default",
            "windowsMove, 1, 4, default",
            "fade, 1, 3, default",
            "border, 1, 3, default",
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

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
})



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
