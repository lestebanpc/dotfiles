--
-- Plugin que muestra directorios y folderes buscados por fd en fzf y luego permite ir
-- a la ubicacion de estos dentro del explorar yazi.
-- Basado en: https://github.com/sxyazi/yazi/blob/main/yazi-plugin/preset/plugins/fzf.lua
--

---------------------------------------------------------------------------------
-- Variables generales del modulos
---------------------------------------------------------------------------------

local m_command_fzf = 'fzf'
local m_command_fd= 'fd'

-- Opciones de configuracion modificables por el usuario
local m_options = {


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

        -- Comando de preview para archivos, directorio y otros
        preview_file = "",
        preview_dir = "",
        preview_both = "",

        -- Header a mostrar
        header = "",

        -- Arreglo de cadenas que representa los binds a usar
        binds = {},

        -- Arreglo de cadenas que representa los argumento adicionales del comando:
        -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
        extra_args = {},

    },

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

}

-- Objeto que el modulo devolvera
local mod = {}



---------------------------------------------------------------------------------
-- Funciones de utilidad
---------------------------------------------------------------------------------

local function is_windows()
    return package.config:sub(1,1) == "\\"
end

-- Simple escape para shell POSIX (entrecomilla con ' y maneja ' internamente)
local function sh_escape(s)
    if s == nil then return "''" end
    -- reemplaza cada ' por '\'' (estándar)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

-- Escape simple para cmd.exe (envuelve en comillas dobles y dobla " internas)
local function cmd_escape(s)
    if s == nil then return '""' end
    return '"' .. tostring(s):gsub('"', '""') .. '"'
end


-- Analiza argumentos como --clave=valor o --flag
local function m_parse_args(args)

    local parsed = {}
    for _, arg in ipairs(args) do
        if arg:find("=") then
            local key, value = arg:match("^--([^=]+)=(.*)$")
            if key and value then
                parsed[key] = value
            end
        elseif arg:find("^--") then
            local flag = arg:match("^--(.+)$")
            if flag then
                parsed[flag] = true
            end
        end
    end

    return parsed

end

-- Si un comando devuelve un conjunto de objetos  de lineas de rutas, genera un arreglo de rutas absolutas
local function m_split_urls(p_cmd_output, p_use_absolute_path, p_cwd)

	local t = {}

	for line in p_cmd_output:gmatch("[^\r\n]+") do

		local u = Url(line)

        if p_use_absolute_path then

		    if u.is_absolute then
			    t[#t + 1] = u
		    else
			    t[#t + 1] = p_cwd:join(u)
		    end

        else
	        t[#t + 1] = u
        end

	end

	return t

end

-- Construye el argumentos del comando de 'fd'
local function m_get_fd_arguments(p_cwd, p_type_filter)


    local l_type = m_options.fd.type or ""
    if p_type_filter ~= nil then
        l_type = p_type_filter
    end

    local l_max_depth = m_options.fd.max_depth or 16
    local l_format = m_options.fd.format or "{//}"
    local l_excludes = m_options.fd.excludes or {}
    local l_extra_args = m_options.fd.extra_args or {}

    local l_args = {
        "--max-depth=" .. l_max_depth,
        "--prune",
        "--format",
        l_format,
    }

    -- Argumento que define el tipo de objeto a filtrar: 'd' si es directorio, 'f' si es un archivo
    if l_type ~= '' then
        table.insert(l_args, '-t')
        table.insert(l_args, l_type)
    end


    -- Argumento de excluir folders
    local l_item = nil
    local l_n = #l_excludes
    for i = 1, l_n do

        l_item = l_excludes[i]

        if l_item ~= nil or l_item ~= '' then
            table.insert(l_args, '-E')
            table.insert(l_args, l_item)
        end

    end

    -- Argumentos adicionales ¿para que se usaria?
    l_n = #l_extra_args
    for i = 1, l_n do

        l_item = l_extra_args[i]

        if l_item ~= nil or l_item ~= '' then
            table.insert(l_args, l_item)
        end

    end

    return l_args

end

-- Construye el argumentos del comando de 'fzf'
local function m_get_fzf_arguments(p_cwd, p_type_filter, p_use_tmux, p_weight, p_height)

    local l_is_multiple = m_options.fzf.is_multiple or false
    local l_has_border = m_options.fzf.has_border or true
    local l_header = m_options.fzf.header or ""
    local l_binds = m_options.fzf.binds or {}
    local l_extra_args = m_options.fzf.extra_args or {}

    local l_use_tmux = m_options.fzf.use_tmux or false
    if p_use_tmux ~= nil then
        l_use_tmux = p_use_tmux
    end

    local l_height = m_options.fzf.height or 80
    if p_height ~= nil then
        l_height = p_height
    end

    local l_weight = m_options.fzf.weight or 99
    if p_weight ~= nil then
        l_weight = p_weight
    end

    -- Calcular argymentos relacionados al tipo de objeto de fd
    local l_preview = ""
    local l_prompt = ""

    local l_type = m_options.fd.type or ""
    if p_type_filter ~= nil then
        l_type = p_type_filter
    end

    if l_type == 'd' then
        l_preview = m_options.fzf.preview_file or ""
        l_prompt = '📁 Folder> '
    else if l_type == 'f' then
        l_preview = m_options.fzf.preview_dir or ""
        l_prompt = '📄 File> '
    else
        l_preview = m_options.fzf.preview_both or ""
        l_prompt = '🔎 File or Folder> '
    end


    local l_args = {
        "--info",
        "inline",
        "--layout",
        "reverse",
        "--height",
        tostring(l_height) .. "%",
        "--weight",
        tostring(l_weight) .. "%",
        "--ansi",
    }

    -- Argumento para permitir la seleccion multiples
    if l_is_multiple then
        table.insert(l_args, '-m')
    end

    -- Argumento para habilitar el borde
    if l_has_border then
        table.insert(l_args, '--border')
    end

    -- Argumento para habilitar el soporte de tmux
    if l_use_tmux then
        table.insert(l_args, '--tmux')
        table.insert(l_args, "center," .. tostring(l_weight) .. "%," .. tostring(l_height) .. "%")
    end


    -- Argumento sobre el prompt a usar
    if l_prompt ~= '' then
        table.insert(l_args, '--prompt')
        table.insert(l_args, l_prompt)
    end

    -- Argumento sobre el preview a usar
    if l_preview ~= '' then
        table.insert(l_args, "--preview-window")
        table.insert(l_args, "right,60%")
        table.insert(l_args, '--preview')
        table.insert(l_args, l_preview)
    end

    -- Argumento sobre el header a usar
    l_header = "WorDir: " .. p_cwd .. ", " .. l_header
    table.insert(l_args, '--header')
    table.insert(l_args, l_header)

    -- Argumentos adicionales ¿para que se usaria?
    local l_item = nil
    local l_n = #l_binds
    for i = 1, l_n do

        l_item = l_binds[i]

        if l_item ~= nil or l_item ~= '' then
            table.insert(l_args, "--bind")
            table.insert(l_args, l_item)
        end

    end

    -- Argumentos adicionales ¿para que se usaria?
    l_n = #l_extra_args
    for i = 1, l_n do

        l_item = l_extra_args[i]

        if l_item ~= nil or l_item ~= '' then
            table.insert(l_args, l_item)
        end

    end

    return l_args

end



---------------------------------------------------------------------------------
-- Funcion especificas de fd y fzf
---------------------------------------------------------------------------------

-- Funcion sincrona que se ejecutara por yazi para capturar algunos datos relevantes del estado actual de yazi.
local m_get_current_state = ya.sync(function()

	--local selected = {}
	--for _, url in pairs(cx.active.selected) do
	--	selected[#selected + 1] = url
	--end

	--return cx.active.current.cwd, selected
	return cx.active.current.cwd

end)


local function m_run_fzf_fd(p_cwd, p_type_filter, p_use_tmux, p_weight, p_height)


    --Obtener los argumentos para ejecutar 'fd'
    local l_args = m_get_fd_arguments(p_cwd, p_type_filter)

    -- Generar el comando 'fd'
    local fd_cmd = Command(m_command_fd)
        :args(l_args)
        :cwd(tostring(p_cwd))
        :stdout(Command.PIPED)

    -- Ejecutar el comando 'fd'
    local fd_child, fd_err = fd_cmd:spawn()
    if not fd_child then
        return nil, "fd failed to start: " .. tostring(fd_err)
    end

    -- Esperar a que el comando 'fd' termine de ejecutar y devuelva el STDOUT
    local fd_output, fd_err2 = fd_child:wait_with_output()
    if not fd_output then
        return nil, "fd output error: " .. tostring(fd_err2)
    end

    -- Si fd no encontró nada, salir temprano
    if fd_output.stdout == "" then
        return "", nil  -- Cadena vacía, sin error
    end

    --Obtener los argumentos para ejecutar 'fd'
    local l_args = m_get_fzf_arguments(p_cwd, p_type_filter, p_use_tmux, p_weight, p_height)

    -- Generar y ejeccutar el comando 'fzf'
    local fzf_child, fzf_err = Command(m_command_fzf)
        :arg(l_args)
        :stdin(Command.PIPED)
        :stdout(Command.PIPED)
        :spawn()

    if not fzf_child then
        return nil, "fzf failed to start: " .. tostring(fzf_err)
    end

    -- Conectar fd → fzf (pasar el SDTOUT de fs al STDIN de fzf)
    fzf_child:write_all(fd_output.stdout)
    fzf_child:flush()

    -- Esperar a que el comando 'ffz' termine de ejecutar y devuelva el STDOUT
    local fzf_output, fzf_err2 = fzf_child:wait_with_output()
    if not fzf_output then
        return nil, "fzf output error: " .. tostring(fzf_err2)
    end

    -- Código 130 es Ctrl+C (cancelado por usuario)
    if not fzf_output.status.success and fzf_output.status.code ~= 130 then
        return nil, "fzf exited with code: " .. tostring(fzf_output.status.code)
    end

    return fzf_output.stdout, nil

end



---------------------------------------------------------------------------------
-- Funciones a exportar
---------------------------------------------------------------------------------

-- Funcion que customiza las opciones de configuracion
function mod.setup(p_self, p_options)

    if not p_options then
	    return
	end

    if not p_options.fd then

        m_options.fd.type = p_options.fd.type or ""
        m_options.fd.max_depth = p_options.fd.max_depth or 16
        m_options.fd.format = p_options.fd.format or "{//}"
        m_options.fd.excludes = p_options.fd.excludes or {}
        m_options.fd.extra_args = p_options.fd.extra_args or {}

    end

    if not p_options.fzf then

        m_options.fzf.is_multiple = m_options.fzf.is_multiple or false
        m_options.fzf.has_border = m_options.fzf.has_border or true
        m_options.fzf.use_tmux = m_options.fzf.use_tmux or false
        m_options.fzf.height = m_options.fzf.height or 80
        m_options.fzf.weight = m_options.fzf.weight or 99
        m_options.fzf.preview_file = m_options.fzf.preview_file or ""
        m_options.fzf.preview_dir = m_options.fzf.preview_dir or ""
        m_options.fzf.preview_both = m_options.fzf.preview_both or ""
        m_options.fzf.header = m_options.fzf.header or ""
        m_options.fzf.binds = m_options.fzf.binds or {}
        m_options.fzf.extra_args = m_options.fzf.extra_args or {}

    end

end


-- Funcion entrypoint del plugin (cuando se ejecuta el keymapping asociado al plugin)
function mod.entry(p_self, p_job)

    -- Analizar argumentos
    local args = m_parse_args(p_job.args or {})
    local type_filter = args.type
    local use_tmux = args.tmux
    local weight = args.weight
    local height = args.height

	ya.emit("escape", { visual = true })

    -- Obtener datos del estado actual
	local cwd = state()
	--local cwd, selected = state()

	if cwd.scheme.is_virtual then
		return ya.notify({ title = "Fzf", content = "Not supported under virtual filesystems", timeout = 5, level = "warn" })
	end

    -- Ocultar la Yazi ¿cuando se muestra?
	local _permit = ui.hide()

    local output, err = m_run_fzf_fd(cwd, type_filter, use_tmux, weight, height)
	if not output then
		return ya.notify({ title = "Fzf", content = tostring(err), timeout = 5, level = "error" })
	end

    -- Convertir los STDOUT en objetos Url que tiene la ruta absoluta de los archivos seleccionados por fzf
	local urls = m_split_urls(output, true, cwd)

    -- Segun el tipo de Url, realizar tareas ...
	if #urls == 1 then
		local cha = #selected == 0 and fs.cha(urls[1])
		ya.emit(cha and cha.is_dir and "cd" or "reveal", { urls[1], raw = true })
	elseif #urls > 1 then
		urls.state = #selected > 0 and "off" or "on"
		ya.emit("toggle_all", urls)
	end

end

-- Retornar los miembros publicos del modulo
return mod
