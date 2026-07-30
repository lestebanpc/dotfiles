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

    general = {
        -- Espacio de la ventana el final de la pantalla del monitor
        gaps_in = 1,

        -- Espacio entre ventanas
        gaps_out = 2,

        -- Borde de la ventana
        border_size = 1,

        -- Layout por defecto
        layout = "dwindle",

        -- ...
		resize_on_border = false,
    },

    decoration = {
        -- Redondes del borde de la ventana
        rounding = 8,

        active_opacity = 1.0,
        inactive_opacity = 1.0,
        --shadow = {
        --    enabled = true,
        --    range = 30,
        --    render_power = 5,
        --    offset = "0 5",
        --    color = "rgba(00000070)",
        --},
    },

})


hl.layer_rule({
	match = { namespace = "^dms:bar$" },
	xray = true,
})

-- DMS windows floating by default
-- ! Hyprland doesn't size these windows correctly so disabling by default here
-- windowrule = float on, match:class ^(org.quickshell)$
hl.layer_rule({ match = { namespace = "quickshell" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^dms:.*" }, no_anim = true })



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
