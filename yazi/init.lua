--------------------------------------------------------------------------------------
-- Configuración general
--------------------------------------------------------------------------------------

-- Variables generales
local m_is_unix_family = ya.target_family() == "unix"
local m_is_windows = ya.target_os() == "windows"


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

-- Obtener la ruta del diretorio de trabajo actual durante el inicio de yazi
local t_root_url, t_error = fs.cwd()
local m_root_path = tostring(t_root_url.path)
--ya.dbg("root path: " .. m_root_path)

-- Obtener la ruta de script para procesar archivos de texto en nuevo tab/windows del terminal
local m_script_proccess_files = nil
if m_is_windows then
    m_script_proccess_files = m_base_script_path .. "/go_files_new_termtab.cmd"
else
    m_script_proccess_files = m_base_script_path .. "/go_files_new_termtab.bash"
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

    -- Parametros usados para 'fd'
    fd_options = {

        max_depth = 16,

        -- Patrones de exclusión.
        excludes = { ".git", "node_modules", ".cache" },

        -- Arreglo de cadenas que representa los argumento adicionales del comando:
        -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
        extra_args = {},

    },

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
        preview_file = "bat --color=always --paging always --style=numbers,header-filename {}",
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
})


--------------------------------------------------------------------------------------
-- Configuracion del plugin 'fzf-rg'
--------------------------------------------------------------------------------------
--
t_plugin = require("fzf-rg")
t_plugin:setup({

    cwd_root =  m_root_path,
    script_path = m_script_proccess_files,

    -- Parametros usados para 'rg'
    rg_options = {

        max_depth = 10,
        use_smart_case = true,

        -- Patrones de exclusión.
        excludes = { ".git/*", "node_modules/*", ".cache/*" },

        -- Arreglo de cadenas que representa los argumento adicionales del comando:
        -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
        --extra_args = {},

    },

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
        --preview = "bat --color=always --paging always --style=numbers,header-filename --highlight-line {2} {1}",

        -- Estilo de la ventana preview
        --preview_window = "down,60%",

        -- Arreglo de cadenas que representa los argumento adicionales del comando:
        -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
        extra_args = {},

    },
})


--------------------------------------------------------------------------------------
-- Configuracion del plugin 'go-fs'
--------------------------------------------------------------------------------------
--

t_plugin = require("go-fs")
t_plugin:setup({
    cwd_root =  m_root_path,
    script_path = m_script_proccess_files,
})
