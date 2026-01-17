--
-- Plugin que muestra directorios y folderes buscados por fd en fzf y luego permite ir
-- a la ubicacion de estos dentro del explorar yazi.
-- Basado en: https://github.com/sxyazi/yazi/blob/main/yazi-plugin/preset/plugins/fzf.lua
--

---------------------------------------------------------------------------------
-- Variables generales del modulos
---------------------------------------------------------------------------------

-- Objeto que el modulo devolvera
local mod = {}

local m_command_fzf = 'fzf'
local m_command_fd  = 'fd'


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

-- Construye el argumentos del comando de 'fd'
-- Parametros:
-- > Define el tipo de objeto a filtrar: 'd' si es directorio, 'f' si es un archivo
local function m_get_fd_arguments(p_state, p_obj_type)


    local l_type = ""
    if p_obj_type ~= nil then
        l_type = p_obj_type
    end

    local l_max_depth = p_state.fd_options.max_depth or 16
    local l_excludes = p_state.fd_options.excludes or {}
    local l_extra_args = p_state.fd_options.extra_args or {}

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
local function m_get_fzf_arguments(p_state, p_cwd, p_obj_type, p_use_tmux, p_height, p_width)

    local l_is_multiple = p_state.fzf_options.is_multiple or false

	local l_has_border = false
    if p_state.fzf_options.has_border == nil then
        l_has_border = false
    else
        l_has_border = p_state.fzf_options.has_border
    end

    local l_header = p_state.fzf_options.header or ""
    local l_binds = p_state.fzf_options.binds or {}
    local l_extra_args = p_state.fzf_options.extra_args or {}

    local l_use_tmux = p_state.fzf_options.use_tmux or false
    if p_use_tmux ~= nil then
        l_use_tmux = p_use_tmux
    end

    local l_height = p_state.fzf_options.height or 80
    if p_height ~= nil then
        l_height = p_height
    end

    local l_width = p_state.fzf_options.width or 99
    if p_width ~= nil then
        l_width = p_width
    end

    -- Calcular argymentos relacionados al tipo de objeto de fd
    local l_preview = ""
    local l_preview_window = ""
    local l_prompt = ""

    local l_type = ""
    if p_obj_type ~= nil then
        l_type = p_obj_type
    end

    if l_type == 'd' then
        l_preview = p_state.fzf_options.preview_dir
        l_preview_window = p_state.fzf_options.preview_window_dir
        l_prompt = '📁 Folder> '
    elseif l_type == 'f' then
        l_preview = p_state.fzf_options.preview_file
        l_preview_window = p_state.fzf_options.preview_window_file
        l_prompt = '📄 File> '
    else
        l_preview = p_state.fzf_options.preview_both
        l_preview_window = p_state.fzf_options.preview_window_both
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


local function m_run_fzf_fd(p_state, p_cwd, p_obj_type, p_use_tmux, p_height, p_width)

    --Obtener los argumentos para ejecutar 'fd'
    local l_args = m_get_fd_arguments(p_state, p_obj_type)
    --ya.dbg("fd args: " .. m_dump_table(l_args))

    -- Generar el comando 'fd'
    local fd_cmd = Command(m_command_fd)
        :arg(l_args)
        :cwd(tostring(p_cwd))
        :stdout(Command.PIPED)

    -- Ejecutar el comando 'fd', por ejemplo: fd --max-depth=16 --prune -t d -E .git -E node_modules -E.cache
    local fd_child, fd_err = fd_cmd:spawn()
    local l_message = ""
    if not fd_child then
        l_message ="fd failed to start: " .. tostring(fd_err)
        ya.err(l_message)
        return nil, l_message
    end

    -- Esperar a que el comando 'fd' termine de ejecutar y devuelva el STDOUT
    local fd_output, fd_err2 = fd_child:wait_with_output()
    if not fd_output then
        l_message = "fd output error: " .. tostring(fd_err2)
        ya.err(l_message)
        return nil, l_message
    end

    -- Si fd no encontró nada, salir temprano
    if fd_output.stdout == "" then
        return "", nil  -- Cadena vacía, sin error
    end

    --Obtener los argumentos para ejecutar 'fd'
    local l_args = m_get_fzf_arguments(p_state, p_cwd, p_obj_type, p_use_tmux, p_height, p_width)
    --ya.dbg("fzf args: " .. m_dump_table(l_args))

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

    -- Conectar fd → fzf (pasar el SDTOUT de fs al STDIN de fzf)
    fzf_child:write_all(fd_output.stdout)
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




local function m_read_args(p_job)

    if not p_job then
        return nil, nil, nil, nil
    end

    local width = nil

    local args = p_job.args or {}
    local nargs = #args
    --ya.dbg("args: " .. m_dump_table(args))

    -- 1er argumento
    local obj_type = nil
    local data = nil
	if nargs > 0 then

        data = args[1]
        ya.dbg("args[1]: " .. data)

        if data ~= nil and data ~= "" then
            if data == "d" or data == "f" then
                obj_type = data
            else
                obj_type = "d"
                ya.err("El argumento nro 1 'type' solo puede ser 'd' o 'f', pero, tiene formato invalido '" .. data .. "'." )
            end
        end

    end

    -- Opcion
    local use_tmux = false
	if args.tmux then

        ya.dbg("args.tmux: " .. tostring(args.tmux))
        use_tmux = true

    end

    -- Opcion
    local height = nil
	if args.height then

        ya.dbg("args.height: " .. tostring(args.height))
        data = tostring(args.height)

        if data ~= nil and data ~= "" then

            -- Eliminar los espacios finales o iniciales
            --data = data:match("^%s*(.-)%s*$")

            -- Validar "0" o "0.12" OR números 1-99 con opcional fracción de 1-2 dígitos
            if data:match("^0(%.%d%d?)?$") or data:match("^[1-9]%d?(%.%d%d?)?$") then
                height = data
            else
                ya.err("La opcion '--height' tiene formato invalido '" .. data .. "'." )
            end

        end

    end

    -- Opcion
    local width = nil
	if args.width then

        ya.dbg("args.width: " .. tostring(args.width))
        data = tostring(args.width)

        if data ~= nil and data ~= "" then

            -- Eliminar los espacios finales o iniciales
            --data = data:match("^%s*(.-)%s*$")

            -- Validar "0" o "0.12" OR números 1-99 con opcional fracción de 1-2 dígitos
            if data:match("^0(%.%d%d?)?$") or data:match("^[1-9]%d?(%.%d%d?)?$") then
                width = data
            else
                ya.err("La opcion '--width' tiene formato invalido '" .. data .. "'." )
            end

        end

    end

    return obj_type, use_tmux, height, width

end


---------------------------------------------------------------------------------
-- Funcion que deben ser ejecutadas dentro sanbox de yazi
---------------------------------------------------------------------------------
--
-- Estas funciones se caracterizan:
-- > Tienen, opcionalmente. el 1er argumento al objeto 'state' (configuracion del usuario).
-- > Si tiene mas de 1 argumento, estos son argumento pasados del que lo invoca.
--

-- Funcion sincrona que se ejecutara por yazi para capturar algunos datos relevantes del estado actual de yazi.
local m_get_current_yazi_info = ya.sync(function()

	--local selected = {}
	--for _, url in pairs(cx.active.selected) do
	--	selected[#selected + 1] = url
	--end

	--return cx.active.current.cwd, selected
	return cx.active.current.cwd

end)



-- Obtener las opciones configurables por el usuario (state) y establece valores por defecto
-- Se genera unc copia del objeto para sea accedido fuera de 'ya.sync()' o 'ya.async()'
local m_get_current_yazi_state = ya.sync(function(p_state)

    -- Establecer el valor por defecto al 'state'
	if p_state == nil then
        p_state = {}
    end

    if p_state.fd_options == nil then
        p_state.fd_options = {}
    end

	if p_state.fd_options.max_depth == nil then
		p_state.fd_options.max_depth = 16
	end

	if p_state.fd_options.excludes == nil then
		p_state.fd_options.excludes = { ".git", "node_modules", ".cache" }
	end

	if p_state.fd_options.extra_args == nil then
		p_state.fd_options.extra_args = {}
	end


    if p_state.fzf_options == nil then
        p_state.fzf_options = {}
    end

	if p_state.fzf_options.is_multiple == nil then
		p_state.fzf_options.is_multiple = false
	end

	if p_state.fzf_options.has_border == nil then
		p_state.fzf_options.has_border = true
	end

	if p_state.fzf_options.use_tmux == nil then
		p_state.fzf_options.use_tmux = false
	end

	if p_state.fzf_options.height == nil then
		p_state.fzf_options.height = 80
	end

	if p_state.fzf_options.width == nil then
		p_state.fzf_options.width = 99
	end

	if p_state.fzf_options.preview_file == nil then
		p_state.fzf_options.preview_file = ""
		--p_state.fzf_options.preview_file = "bat --color=always --paging always {}"
	end

	if p_state.fzf_options.preview_dir == nil then
		p_state.fzf_options.preview_dir = ""
		--p_state.fzf_options.preview_dir = "eza --color=always --icons always {}"
	end

	if p_state.fzf_options.preview_both == nil then
		p_state.fzf_options.preview_both = ""
	end

	if p_state.fzf_options.preview_window_file == nil then
		p_state.fzf_options.preview_window_file = "down,60%"
		--p_state.fzf_options.preview_window_file = ""
	end

	if p_state.fzf_options.preview_window_dir == nil then
		p_state.fzf_options.preview_window_dir = "down,60%"
		--p_state.fzf_options.preview_window_dir = ""
	end

	if p_state.fzf_options.preview_window_both == nil then
		p_state.fzf_options.preview_window_both = "right,60%"
		--p_state.fzf_options.preview_window_both = ""
	end

	if p_state.fzf_options.header == nil then
		p_state.fzf_options.header = ""
	end

	if p_state.fzf_options.binds == nil then
		p_state.fzf_options.binds = {}
	end

	if p_state.fzf_options.extra_args == nil then
		p_state.fzf_options.extra_args = {}
	end


    -- Devolver un copia del objeto 'state'
    local l_state = {

        -- Opciones de configuracion para el comando fzf
        fzf_options = {

            -- Permite la seleccion multiple
            is_multiple = p_state.fzf_options.is_multiple,

            -- Tiene un border
            has_border = p_state.fzf_options.has_border,

            -- Usar tmux
            use_tmux = p_state.fzf_options.use_tmux,

            -- Tamaño por defecto del popup en porcentajes
            height = p_state.fzf_options.height,
            width = p_state.fzf_options.width,

            -- Comando de preview para archivos, directorio y otros
            preview_file = p_state.fzf_options.preview_file,
            preview_dir  = p_state.fzf_options.preview_dir,
            preview_both = p_state.fzf_options.preview_both,

            -- Estilo de la ventana preview
            preview_window_file = p_state.fzf_options.preview_window_file,
            preview_window_dir  = p_state.fzf_options.preview_window_dir,
            preview_window_both = p_state.fzf_options.preview_window_both,

            -- Header a mostrar
            header = p_state.fzf_options.header,

            -- Arreglo de cadenas que representa los binds a usar
            binds = p_state.fzf_options.binds,

            -- Arreglo de cadenas que representa los argumento adicionales del comando:
            -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
            extra_args = p_state.fzf_options.extra_args,

        },

        -- Opciones de configuracion para el comando fd
        fd_options = {
            max_depth = p_state.fd_options.max_depth,

            -- Patrones de exclusión.
            excludes = p_state.fd_options.excludes,

            -- Arreglo de cadenas que representa los argumento adicionales del comando:
            -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
            extra_args = p_state.fd_options.extra_args,

        },
    }

    return l_state

end)



---------------------------------------------------------------------------------
-- Funciones a exportar e invocados por yazi
---------------------------------------------------------------------------------

-- Funcion que customiza las opciones de configuracion
function mod.setup(p_state, p_args)

    if not p_args then
	    return
	end

    if p_args.fd_options then

        if p_state.fd_options == nil then
            p_state.fd_options = {}
        end

        p_state.fd_options.max_depth = p_args.fd_options.max_depth or 16
        p_state.fd_options.excludes = p_args.fd_options.excludes or {}
        p_state.fd_options.extra_args = p_args.fd_options.extra_args or {}

    end

    if p_args.fzf_options then

        if p_state.fzf_options == nil then
            p_state.fzf_options = {}
        end

        p_state.fzf_options.is_multiple = p_args.fzf_options.is_multiple or false
		if p_args.fzf_options.has_border == nil then
            p_state.fzf_options.has_border = false
        else
            p_state.fzf_options.has_border = p_args.fzf_options.has_border
        end
        p_state.fzf_options.use_tmux = p_args.fzf_options.use_tmux or false
        p_state.fzf_options.height = p_args.fzf_options.height or 80
        p_state.fzf_options.width = p_args.fzf_options.width or 99
        p_state.fzf_options.preview_file = p_args.fzf_options.preview_file or ""
        p_state.fzf_options.preview_dir = p_args.fzf_options.preview_dir or ""
        p_state.fzf_options.preview_both = p_args.fzf_options.preview_both or ""
        p_state.fzf_options.preview_window_file = p_args.fzf_options.preview_window_file or ""
        p_state.fzf_options.preview_window_dir = p_args.fzf_options.preview_window_dir or ""
        p_state.fzf_options.preview_window_both = p_args.fzf_options.preview_window_both or ""
        p_state.fzf_options.header = p_args.fzf_options.header or ""
        p_state.fzf_options.binds = p_args.fzf_options.binds or {}
        p_state.fzf_options.extra_args = p_args.fzf_options.extra_args or {}

    end

end


-- Funcion entrypoint del plugin (cuando se ejecuta el keymapping asociado al plugin)
function mod.entry(p_self, p_job)

    -- Obtener los argumentos
    local obj_type, use_tmux, height, width = m_read_args(p_job)

    -- Salir de modo ...
	ya.emit("escape", { visual = true })

    -- Obtener las opciones configurable del usaurio usando los valores por defecto
    local l_state = m_get_current_yazi_state()

    -- Obtener datos del estado actual de yazi
	local cwd = m_get_current_yazi_info()
    --ya.dbg("cwd: " .. tostring(cwd))

    if cwd.scheme then
	    if cwd.scheme.is_virtual then
            ya.dbg("Not supported under virtual filesystems")
	        return ya.notify({ title = "Fzf", content = "Not supported under virtual filesystems", timeout = 5, level = "warn" })
	    end
    end

    -- Ocultar la Yazi
	local permit = ui.hide()

    -- Ejecutar 'fd | fzf' y obtener el STDOUT del resultado
    local output, err_msg = m_run_fzf_fd(l_state, cwd, obj_type, use_tmux, height, width)

    -- Restaurar (mostrar) yazi
    if permit then
        permit:drop()
    end

    -- Si al ejecutar 'fd | fzf' se obtuvo error
	if err_msg ~= nil then
		return ya.notify({ title = "Fzf", content = tostring(err_msg), timeout = 5, level = "error" })
	end

    -- Si al ejecutar 'fd | fzf' no se obtuvo archivos o el usuario cancelo la seleccion
    if output == nil or output == "" then
        ya.dbg("fd no encontro archivos o el usuario cancelo la seleccion")
        return
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
