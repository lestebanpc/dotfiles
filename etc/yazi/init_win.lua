local m_plugin = nil

-- Configuracion del plugin built-in 'fzf.lua'

-- Configuracion del plugin built-in 'zoxide.lua'
--m_plugin = require("zoxide")
--m_plugin:setup({
--	update_db = true,
--})

-- Configuracion del plugin built-in 'fzf.lua'
m_plugin = require("fzf-fd")
m_plugin:setup({

    -- Parametros usados para 'fzf'
    fzf = {

        -- Permite la seleccion multiple
        is_multiple = false,

        -- Tiene un border
        has_border = true,

        -- Usar tmux
        use_tmux = false,

        -- Tamaño por defecto del popup en porcentajes
        height = 80,
        weight = 99,

        -- Header a mostrar
        header = "",

        -- Arreglo de cadenas que representa los binds a usar
        binds = {},

        -- Comando de preview para archivos, directorio y otros
        preview_file = "bat --color=always --paging always {}",
        preview_dir = "dir {}",
        preview_both = "dir {}",

        -- Arreglo de cadenas que representa los argumento adicionales del comando:
        -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
        extra_args = {},

    },

    -- Parametros usados para 'fd'
    fd = {

        -- Define el tipo de objeto a filtrar: 'd' si es directorio, 'f' si es un archivo
        ["type"] = "d",

        max_depth = 16,
        format = "{//}",

        -- Patrones de exclusión.
        excludes = { ".git", "node_modules", ".cache" },

        -- Arreglo de cadenas que representa los argumento adicionales del comando:
        -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
        extra_args = {},

    },
})
