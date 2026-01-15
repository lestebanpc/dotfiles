--
-- Plugin que muestra directorios y folderes buscados por rg en fzf y luego permite ir
-- a la ubicacion de estos dentro del explorar yazi.
-- Basado en: https://github.com/sxyazi/yazi/blob/main/yazi-plugin/preset/plugins/fzf.lua
--

---------------------------------------------------------------------------------
-- Variables generales del modulos
---------------------------------------------------------------------------------

-- Objeto que el modulo devolvera
local mod = {}

-- Opciones de configuracion modificables por el usuario
mod.fzf_options = {

    -- Permite la seleccion multiple
    is_multiple = false,

    -- Tiene un border
    has_border = true,

    -- Usar tmux
    use_tmux = false,

    -- Tamaño por defecto del popup en porcentajes
    height = 80,
    width = 99,

    -- Comando de preview para archivos, directorio y otros
    --preview_file = "",
    preview_file = "bat --color=always --paging always {}",
    preview_dir  = "eza --color=always --icons always {}",
    --preview_dir  = "eza --tree --color=always --icons always -L 4 {}",
    --preview_dir  = "eza --tree --color=always --icons always -L 4 {} | head -n 300",
    preview_both = "",

    -- Estilo de la ventana preview
    preview_window_file = "down,60%",
    preview_window_dir  = "down,60%",
    preview_window_both = "right,60%",

    -- Header a mostrar
    header = "",

    -- Arreglo de cadenas que representa los binds a usar
    binds = {},

    -- Arreglo de cadenas que representa los argumento adicionales del comando:
    -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
    extra_args = {},

}

mod.rg_options = {

    max_depth = 16,

    -- Patrones de exclusión.
    excludes = { ".git", "node_modules", ".cache" },

    -- Arreglo de cadenas que representa los argumento adicionales del comando:
    -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
    extra_args = {},

}

local m_command_fzf = 'fzf'
local m_command_rg  = 'rg'


---------------------------------------------------------------------------------
-- Funciones de utilidad
---------------------------------------------------------------------------------

-- Función de utilidad para debugging que permite convertir una tabla en texto
local function m_dump_table(t, indent)

    indent = indent or ""
    local lines = {}
    for k, v in pairs(t) do

        local key = tostring(k)
        local value
        if type(v) == "table" then
            -- recursivo para tablas anidadas
            value = "\n" .. m_dump_table(v, indent .. "  ")
        else
            value = tostring(v)
        end

        lines[#lines + 1] = indent .. key .. " = " .. value

    end

    return table.concat(lines, "\n")

end

-- Analiza argumentos como --clave=valor o --flag
--local function m_parse_args(args)
--
--    local parsed = {}
--    for _, arg in ipairs(args) do
--        if arg:find("=") then
--            local key, value = arg:match("^--([^=]+)=(.*)$")
--            if key and value then
--                parsed[key] = value
--            end
--        elseif arg:find("^--") then
--            local flag = arg:match("^--(.+)$")
--            if flag then
--                parsed[flag] = true
--            end
--        end
--    end
--
--    return parsed
--
--end

-- Si un comando devuelve un conjunto de objetos  de lineas de rutas, genera un arreglo de rutas absolutas
local function m_get_urls_of(p_cmd_output, p_cwd)

	local t = {}

	for line in p_cmd_output:gmatch("[^\r\n]+") do

		local u = Url(line)

		if u.is_absolute then
		    t[#t + 1] = u
		else
		    t[#t + 1] = p_cwd:join(u)
		end

	end

	return t

end

-- Construye el argumentos del comando de 'rg'
-- Parametros:
-- > Define el tipo de objeto a filtrar: 'd' si es directorio, 'f' si es un archivo
local function m_get_rg_arguments(p_obj_type)


    local l_type = ""
    if p_obj_type ~= nil then
        l_type = p_obj_type
    end

    local l_max_depth = mod.rg_options.max_depth or 16
    local l_excludes = mod.rg_options.excludes or {}
    local l_extra_args = mod.rg_options.extra_args or {}

    local l_args = {
        "--max-depth=" .. l_max_depth,
    }

    -- Argumento que define el tipo de objeto a filtrar: 'd' si es directorio, 'f' si es un archivo
    if l_type ~= "" then
        table.insert(l_args, '-t')
        table.insert(l_args, l_type)
    end


    -- Argumento de excluir folders
    local l_item = nil
    local l_n = #l_excludes
    for i = 1, l_n do

        l_item = l_excludes[i]

        if l_item ~= nil and l_item ~= '' then
            table.insert(l_args, '-E')
            table.insert(l_args, l_item)
        end

    end

    -- Argumentos adicionales ¿para que se usaria?
    l_n = #l_extra_args
    for i = 1, l_n do

        l_item = l_extra_args[i]

        if l_item ~= nil and l_item ~= '' then
            table.insert(l_args, l_item)
        end

    end

    return l_args

end

-- Construye el argumentos del comando de 'fzf'
local function m_get_fzf_arguments(p_cwd, p_obj_type, p_use_tmux, p_height, p_width)

    local l_is_multiple = mod.fzf_options.is_multiple or false

	local l_has_border = false
    if mod.fzf_options.has_border == nil then
        l_has_border = false
    else
        l_has_border = mod.fzf_options.has_border
    end

    local l_header = mod.fzf_options.header or ""
    local l_binds = mod.fzf_options.binds or {}
    local l_extra_args = mod.fzf_options.extra_args or {}

    local l_use_tmux = mod.fzf_options.use_tmux or false
    if p_use_tmux ~= nil then
        l_use_tmux = p_use_tmux
    end

    local l_height = mod.fzf_options.height or 80
    if p_height ~= nil then
        l_height = p_height
    end

    local l_width = mod.fzf_options.width or 99
    if p_width ~= nil then
        l_width = p_width
    end

    -- Calcular argymentos relacionados al tipo de objeto de rg
    local l_preview = ""
    local l_preview_window = ""
    local l_prompt = ""

    local l_type = ""
    if p_obj_type ~= nil then
        l_type = p_obj_type
    end

    if l_type == 'd' then
        l_preview = mod.fzf_options.preview_dir
        l_preview_window = mod.fzf_options.preview_window_dir
        l_prompt = '📁 Folder> '
    elseif l_type == 'f' then
        l_preview = mod.fzf_options.preview_file
        l_preview_window = mod.fzf_options.preview_window_file
        l_prompt = '📄 File> '
    else
        l_preview = mod.fzf_options.preview_both
        l_preview_window = mod.fzf_options.preview_window_both
        l_prompt = '🔎 File or Folder> '
    end


    local l_args = {
        "--info",
        "inline",
        "--layout",
        "reverse",
        "--height",
        tostring(l_height) .. "%",
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
        table.insert(l_args, "--tmux=center," .. tostring(l_width) .. "%," .. tostring(l_height) .. "%")
    end


    -- Argumento sobre el prompt a usar
    if l_prompt ~= nil and l_prompt ~= "" then
        table.insert(l_args, '--prompt')
        table.insert(l_args, l_prompt)
    end

    -- Argumento sobre el preview a usar
	--l_preview = "eza --tree --color=always --icons always -L 4 {}"
    if l_preview ~= nil and l_preview ~= "" then
        table.insert(l_args, "--preview-window")
        table.insert(l_args, l_preview_window)
        table.insert(l_args, '--preview')
        table.insert(l_args, l_preview)
    end

    -- Argumento sobre el header a usar
    if l_header ~= nil and l_header ~= "" then
        l_header = "WorkingDir: " .. tostring(p_cwd) .. ", " .. l_header
    else
        l_header = "WorkingDir: " .. tostring(p_cwd)
    end
    table.insert(l_args, '--header')
    table.insert(l_args, l_header)

    -- Argumentos adicionales ¿para que se usaria?
    local l_item = nil
    local l_n = #l_binds
    for i = 1, l_n do

        l_item = l_binds[i]

        if l_item ~= nil and l_item ~= "" then
            table.insert(l_args, "--bind")
            table.insert(l_args, l_item)
        end

    end

    -- Argumentos adicionales ¿para que se usaria?
    l_n = #l_extra_args
    for i = 1, l_n do

        l_item = l_extra_args[i]

        if l_item ~= nil and l_item ~= '' then
            table.insert(l_args, l_item)
        end

    end

    return l_args

end



---------------------------------------------------------------------------------
-- Funcion especificas de rg y fzf
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


local function m_run_fzf_rg(p_cwd, p_obj_type, p_use_tmux, p_height, p_width)

    --Obtener los argumentos para ejecutar 'rg'
    local l_args = m_get_rg_arguments(p_obj_type)
    ya.dbg("rg args: " .. m_dump_table(l_args))

    -- Generar el comando 'rg'
    local rg_cmd = Command(m_command_rg)
        :arg(l_args)
        :cwd(tostring(p_cwd))
        :stdout(Command.PIPED)

    -- Ejecutar el comando 'rg', por ejemplo: rg
    local rg_child, rg_err = rg_cmd:spawn()
    local l_message = ""
    if not rg_child then
        l_message ="rg failed to start: " .. tostring(rg_err)
        ya.err(l_message)
        return nil, l_message
    end

    -- Esperar a que el comando 'rg' termine de ejecutar y devuelva el STDOUT
    local rg_output, rg_err2 = rg_child:wait_with_output()
    if not rg_output then
        l_message = "rg output error: " .. tostring(rg_err2)
        ya.err(l_message)
        return nil, l_message
    end

    -- Si rg no encontró nada, salir temprano
    if rg_output.stdout == "" then
        ya.dbg("No selected item")
        return "", nil  -- Cadena vacía, sin error
    end

    --Obtener los argumentos para ejecutar 'fzf'
    local l_args = m_get_fzf_arguments(p_cwd, p_obj_type, p_use_tmux, p_height, p_width)
    ya.dbg("fzf args: " .. m_dump_table(l_args))

    -- Generar el comando 'fzf', por ejemplo: fzf --info inline --layout reverse --height  80% --ansi --border --prompt "📁 Folder> " --header "WorDir: D:/Users/lucpea/.files"
    local fzf_cmd = Command(m_command_fzf)
        :arg(l_args)
        :cwd(tostring(p_cwd))
        :stdin(Command.PIPED)
        :stdout(Command.PIPED)

    -- Ejecutar el comando 'fzf'
    local fzf_child, fzf_err = fzf_cmd:spawn()
    if not fzf_child then
        l_message = "fzf failed to start: " .. tostring(fzf_err)
        ya.err(l_message)
        return nil, l_message
    end

    -- Conectar rg → fzf (pasar el SDTOUT de fs al STDIN de fzf)
    fzf_child:write_all(rg_output.stdout)
    fzf_child:flush()

    -- Esperar a que el comando 'ffz' termine de ejecutar y devuelva el STDOUT
    local fzf_output, fzf_err2 = fzf_child:wait_with_output()
    if not fzf_output then
        l_message = "fzf output error: " .. tostring(fzf_err2)
        ya.err(l_message)
        return nil, l_message
    end

    -- Código 130 es Ctrl+C (cancelado por usuario)
    if not fzf_output.status.success and fzf_output.status.code ~= 130 then
        l_message = "fzf exited with code: " .. tostring(fzf_output.status.code)
        ya.err(l_message)
        return nil, l_message
    end

    return fzf_output.stdout, nil

end



---------------------------------------------------------------------------------
-- Funciones a exportar
---------------------------------------------------------------------------------

-- Funcion que customiza las opciones de configuracion
function mod.setup(p_self, p_args)

    if not p_args then
	    return
	end

    if p_args.rg_options then

        if p_self.rg_options == nil then
            p_self.rg_options = {}
        end

        p_self.rg_options.max_depth = p_args.rg_options.max_depth or 16
        p_self.rg_options.excludes = p_args.rg_options.excludes or {}
        p_self.rg_options.extra_args = p_args.rg_options.extra_args or {}

    end

    if p_args.fzf_options then

        if p_self.fzf_options == nil then
            p_self.fzf_options = {}
        end

        p_self.fzf_options.is_multiple = p_args.fzf_options.is_multiple or false
		if p_args.fzf_options.has_border == nil then
            p_self.fzf_options.has_border = false
        else
            p_self.fzf_options.has_border = p_args.fzf_options.has_border
        end
        p_self.fzf_options.use_tmux = p_args.fzf_options.use_tmux or false
        p_self.fzf_options.height = p_args.fzf_options.height or 80
        p_self.fzf_options.width = p_args.fzf_options.width or 99
        p_self.fzf_options.preview_file = p_args.fzf_options.preview_file or ""
        p_self.fzf_options.preview_dir = p_args.fzf_options.preview_dir or ""
        p_self.fzf_options.preview_both = p_args.fzf_options.preview_both or ""
        p_self.fzf_options.preview_window_file = p_args.fzf_options.preview_window_file or ""
        p_self.fzf_options.preview_window_dir = p_args.fzf_options.preview_window_dir or ""
        p_self.fzf_options.preview_window_both = p_args.fzf_options.preview_window_both or ""
        p_self.fzf_options.header = p_args.fzf_options.header or ""
        p_self.fzf_options.binds = p_args.fzf_options.binds or {}
        p_self.fzf_options.extra_args = p_args.fzf_options.extra_args or {}

    end

end


-- Funcion entrypoint del plugin (cuando se ejecuta el keymapping asociado al plugin)
function mod.entry(p_self, p_job)

    -- Analizar argumentos
    local obj_type = nil
    local use_tmux = nil
    local height = nil
    local width = nil

    if p_job then

        -- Actualmente el soporte de opciones esta en beta, solo soporta argumentos posicionales
        local args = p_job.args or {}
        local nargs = #args
        --ya.dbg("args: " .. m_dump_table(args))

        -- 1er argumento
        local data = nil
		if nargs > 0 then

            data = args[1]
            ya.dbg("args[1]: " .. data)

            if data ~= nil and data ~= "" then
                if data == "d" or data == "f" then
                    obj_type = data
                elseif data == "b" then
                    obj_type = nil
                else
                    obj_type = "d"
                    ya.err("El argumento nro 1 'type' solo puede ser 'd' o 'f', pero, tiene formato invalido '" .. data .. "'." )
                end
            end

        end

        -- 2do argumento
		if nargs > 1 then

            data = tostring(args[2])
            ya.dbg("args[2]: " .. data)

            if data ~= nil and data ~= "" then
                if data == "yes" then
                    use_tmux = true
                elseif data == "no" then
                    use_tmux = false
                else
                    use_tmux = nil
                    ya.err("El argumento nro 2 'tmux' solo puede ser 'yes' o 'no', pero, tiene formato invalido '" .. data .. "'." )
                end
            end

        end

        -- 3er argumento
		if nargs > 2 then

            data = tostring(args[3])
            ya.dbg("args[3]: " .. data)

            if data ~= nil and data ~= "" then

                -- Eliminar los espacios finales o iniciales
                --data = data:match("^%s*(.-)%s*$")

                -- Validar "0" o "0.12" OR números 1-99 con opcional fracción de 1-2 dígitos
                if data:match("^0(%.%d%d?)?$") or data:match("^[1-9]%d?(%.%d%d?)?$") then
                    height = data
                else
                    height = nil
                    ya.err("El argumento nro 3 'height' tiene formato invalido '" .. data .. "'." )
                end

            end

        end

        -- 4to argumento
		if nargs > 3 then

            data = tostring(args[4])
            ya.dbg("args[4]: " .. data)

            if data ~= nil and data ~= "" then

                -- Eliminar los espacios finales o iniciales
                --data = data:match("^%s*(.-)%s*$")

                -- Validar "0" o "0.12" OR números 1-99 con opcional fracción de 1-2 dígitos
                if data:match("^0(%.%d%d?)?$") or data:match("^[1-9]%d?(%.%d%d?)?$") then
                    width = data
                else
                    width = nil
                    ya.err("El argumento nro 4 'width' tiene formato invalido '" .. data .. "'." )
                end

            end

        end

    end

	ya.emit("escape", { visual = true })

    -- Obtener datos del estado actual
	local cwd = m_get_current_state()
	--local cwd, selected = m_get_current_state()
    ya.dbg("cwd: " .. tostring(cwd))

    if cwd.scheme then
	    if cwd.scheme.is_virtual then
            ya.dbg("Not supported under virtual filesystems")
	        return ya.notify({ title = "Fzf", content = "Not supported under virtual filesystems", timeout = 5, level = "warn" })
	    end
    end

    -- Ocultar la Yazi
	local permit = ya.hide()

    -- Ejecutar 'rg | fzf' y obtener el STDOUT del resultado
    local output, err = m_run_fzf_rg(cwd, obj_type, use_tmux, height, width)

    -- Restaurar (mostrar) yazi
    if permit then
        permit:drop()
    end

	if not output then
        --ya.err(tostring(err))
		return ya.notify({ title = "Fzf", content = tostring(err), timeout = 5, level = "error" })
	end

    -- Convertir los STDOUT de ruta de los archivos seleccionados por fzf en objetos Url con rutas absolutas
	local urls = m_get_urls_of(output, cwd)

    -- Segun el tipo de Url, realizar tareas ...
	if #urls == 1 then
		local cha = fs.cha(urls[1])
		ya.emit(cha and cha.is_dir and "cd" or "reveal", { urls[1], raw = true })
	elseif #urls > 1 then
		urls.state = "on"
		ya.emit("toggle_all", urls)
	end

end

-- Retornar los miembros publicos del modulo
return mod
