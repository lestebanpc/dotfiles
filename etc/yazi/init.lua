--------------------------------------------------------------------------------------
-- Configuración general
--------------------------------------------------------------------------------------

-- Variables generales
m_is_unix_family = ya.target_family() == "unix"
m_is_windows = ya.target_os() == "windows"


-- Handler para adicionar la ruta destino de un 'symbolic link' en una nueva seccion en el 'status bar'.
local function m_add_link_to_statusbar(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end

Status:children_add(m_add_link_to_statusbar, 3300, Status.LEFT)

-- Handler para adicionar el owner del file/folder en una nueva seccion en el 'status bar'.
local function m_add_owner_to_statusbar(self)
	local h = cx.active.current.hovered
	if not h then
		return ""
	end

	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		" ",
	})
end

if m_is_unix_family then
    Status:children_add(m_add_owner_to_statusbar, 500, Status.RIGHT)
end

-- Obtener la ruta donde estan los script a ejecutar
local m_base_script_path = nil
if m_is_windows then
    m_base_script_path = os.getenv("USERPROFILE") .. "/.files/shell/cmd/bin/cmds"
else
    m_base_script_path = os.getenv("HOME") .. "/.files/shell/bash/bin/cmds"
end


--------------------------------------------------------------------------------------
-- Configuración del plugin built-ins
--------------------------------------------------------------------------------------
--
local m_plugin = nil

-- Plugin built-in 'zoxide.lua'
-- Plugin built-in 'fzf.lua'

-- Plugin built-in 'zoxide.lua'
--m_plugin = require("zoxide")
--m_plugin:setup({
--	update_db = true,
--})


--------------------------------------------------------------------------------------
-- Configuracion del plugin 'fzf-fd'
--------------------------------------------------------------------------------------
--
t_plugin = require("fzf-fd")
t_plugin:setup({

    -- Parametros usados para 'fzf'
    fzf_options = {

        -- Permite la seleccion multiple
        is_multiple = true,

        -- Tiene un border
        has_border = true,

        -- Usar tmux
        use_tmux = false,

        -- Tamaño por defecto del popup en porcentajes
        height = 80,
        width = 99,

        -- Header a mostrar
        header = "",

        -- Arreglo de cadenas que representa los binds a usar
        binds = {},

        -- Comando de preview para archivos, directorio y otros
        preview_file = "bat --color=always --paging always {}",
        preview_dir = "eza --color=always --icons always {}",
        preview_both = "ls -la {}",

        -- Estilo de la ventana preview
        preview_window_file = "down,60%",
        preview_window_dir  = "down,60%",
        preview_window_both = "",

        -- Arreglo de cadenas que representa los argumento adicionales del comando:
        -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
        extra_args = {},

    },

    -- Parametros usados para 'fd'
    fd_options = {

        max_depth = 16,

        -- Patrones de exclusión.
        excludes = { ".git", "node_modules", ".cache" },

        -- Arreglo de cadenas que representa los argumento adicionales del comando:
        -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
        extra_args = {},

    },
})


--------------------------------------------------------------------------------------
-- Configuracion del plugin 'go-fs'
--------------------------------------------------------------------------------------
--
-- Obtener la ruta del diretorio de trabajo actual durante el inicio de yazi
local t_root_url, t_error = fs.cwd()
local t_path = tostring(t_root_url.path)
ya.dbg("root path: " .. t_path)

local t_script_path = nil
if m_is_windows then
    t_script_path = m_base_script_path .. "/go_files_new_termtab.cmd"
else
    t_script_path = m_base_script_path .. "/go_files_new_termtab.bash"
end

t_plugin = require("go-fs")
t_plugin:setup({
    cwd_root =  t_path,
    script_path = t_script_path,
})
