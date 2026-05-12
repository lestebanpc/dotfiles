--
-- Plugin que permite:
-- > Busca archivos y folderes usanbdo fd en fzf y luego permite ir a la ubicacion de estos
--   dentro del explorar yazi.
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
local function m_get_urls_of(p_cmd_output, p_base_path)

	local l_urls = {}

    local l_base_url = Url(p_base_path)
    local l_item
	for l_line in p_cmd_output:gmatch("[^\r\n]+") do

		local l_item = Url(l_line)

		if l_item.is_absolute then
            table.insert(l_urls, l_item)
		else
            table.insert(l_urls, l_base_url:join(l_item))
		end

	end

	return l_urls

end


-- Construye el argumentos del comando de 'fd'
-- Parametros:
-- > Define el tipo de objeto a filtrar: 'd' si es directorio, 'f' si es un archivo
local function m_get_fd_arguments(p_state, p_cmd_type)


    local l_type = ""
    if p_cmd_type ~= nil then
        if p_cmd_type == "folder" then
            l_type = 'd'
        else
            l_type = 'f'
        end
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
local function m_get_fzf_arguments(p_state, p_cwd_path, p_cmd_type, p_use_tmux, p_height, p_width)

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
    if p_cmd_type ~= nil then
        if p_cmd_type == "folder" then
            l_type = 'd'
        else
            l_type = 'f'
        end
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
        l_header = "WorkingDir: " .. tostring(p_cwd_path) .. ", " .. l_header
    else
        l_header = "WorkingDir: " .. tostring(p_cwd_path)
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

local function m_go_git_root_folder(p_cwd_path)

    -- Generar el comando 'git'
    local git_cmd = Command("git")
        :arg({ "rev-parse", "--show-toplevel" })
        :cwd(p_cwd_path)
        :stdout(Command.PIPED)

    -- Ejecutar el comando 'git'
    local l_error = nil
    local l_child = nil
    local l_message = nil

    l_child, l_error = git_cmd:spawn()
    if not l_child then
        l_message ="git failed to start: " .. tostring(l_error)
        ya.err(l_message)
        return nil, l_message
    end

    -- Esperar a que el comando termine de ejecutar y devuelva el STDOUT
    local l_output = nil

    l_output, l_error = l_child:wait_with_output()
    if not l_output then
        l_message = "git output error: " .. tostring(l_error)
        ya.err(l_message)
        return nil, l_message
    end

    --ya.dbg("l_output.status.success: " .. tostring(l_output.status.success))
    --ya.dbg("l_output.status.code: " .. tostring(l_output.status.code))
    --ya.dbg("l_output.stdout: " .. tostring(l_output.stdout))
    --ya.dbg("l_output.stderr: " .. tostring(l_output.stderr))

    -- Si el comando devolvio un codigo de error en su ejecucion
    if not l_output.status.success then

        l_message = nil
        if l_output.status.code then
            l_message = "git status-code: " .. tostring(l_output.status.code)
        end

        if l_output.stderr ~= nil and l_output.stderr ~= "" then

            if l_message == nil then
                l_message = "git error: " .. l_output.stderr
            else
                l_message = l_message .. ", git error: " .. l_output.stderr
            end

        end

        ya.err("git status.code: " .. tostring(l_output.status.code))
        ya.err("git stdout: " .. tostring(l_output.stdout))
        ya.err("git stderr: " .. tostring(l_output.stderr))

        return nil, l_message

    end

    l_git_folder = l_output.stdout:gsub("%s*$", "")
    return l_git_folder, nil

end



---------------------------------------------------------------------------------
-- Funcion especificas de fd y fzf
---------------------------------------------------------------------------------

local function m_run_fzf_fd(p_state, p_cwd_path, p_cmd_type, p_use_tmux, p_height, p_width)

    --1. Ejecutar el comando 'fd'

    -- Obtener los argumentos para ejecutar 'fd'
    local l_args = m_get_fd_arguments(p_state, p_cmd_type)
    --ya.dbg("fd args: " .. m_dump_table(l_args))

    -- Generar el comando 'fd'
    local l_cmd = Command(m_command_fd)
        :arg(l_args)
        :cwd(p_cwd_path)
        :stdout(Command.PIPED)

    -- Ejecutar el comando 'fd'
    -- > Por ejemplo: fd --max-depth=16 --prune -t d -E .git -E node_modules -E.cache
    local l_error = nil
    local l_child = nil
    local l_message = nil

    l_child, l_error = l_cmd:spawn()
    if not l_child then
        l_message ="fd failed to start: " .. tostring(l_error)
        ya.err(l_message)
        return nil, l_message
    end

    -- Esperar a que el comando 'fd' termine de ejecutar y devuelva el STDOUT
    local l_fd_output = nil

    l_fd_output, l_error = l_child:wait_with_output()
    if not l_fd_output then
        l_message = "fd output error: " .. tostring(l_error)
        ya.err(l_message)
        return nil, l_message
    end

    --ya.dbg("l_fd_output.status.success: " .. tostring(l_fd_output.status.success))
    --ya.dbg("l_fd_output.status.code: " .. tostring(l_fd_output.status.code))
    --ya.dbg("l_fd_output.stdout: " .. tostring(l_fd_output.stdout))
    --ya.dbg("l_fd_output.stderr: " .. tostring(l_fd_output.stderr))

    if not l_fd_output.status.success then
        l_message = "fd exited with code: " .. tostring(l_fd_output.status.code)
        ya.err(l_message)
        return nil, l_message
    end

    -- Si fd no encontró nada, salir temprano
    if l_fd_output.stdout == "" then
        return "", nil  -- Cadena vacía, sin error
    end



    --2. Ejecutar el comando 'fzf'

    --Obtener los argumentos para ejecutar 'fd'
    l_args = m_get_fzf_arguments(p_state, p_cwd_path, p_cmd_type, p_use_tmux, p_height, p_width)
    --ya.dbg("fzf args: " .. m_dump_table(l_args))

    -- Generar el comando 'fzf'
    -- > Por ejemplo: fzf --info inline --layout reverse --height  80% --ansi --border --prompt "📁 Folder> " --header "WorDir: D:/Users/lucpea/.files"
    l_cmd = Command(m_command_fzf)
        :arg(l_args)
        :cwd(p_cwd_path)
        :stdin(Command.PIPED)
        :stdout(Command.PIPED)

    -- Ejecutar el comando 'fzf'
    l_child, l_error = l_cmd:spawn()
    if not l_child then
        l_message = "fzf failed to start: " .. tostring(l_error)
        ya.err(l_message)
        return nil, l_message
    end

    -- Conectar fd → fzf (pasar el SDTOUT de fs al STDIN de fzf)
    l_child:write_all(l_fd_output.stdout)
    l_child:flush()

    -- Esperar a que el comando 'ffz' termine de ejecutar y devuelva el STDOUT
    local l_fzf_output = nil

    l_fzf_output, l_error = l_child:wait_with_output()
    if not l_fzf_output then
        l_message = "fzf output error: " .. tostring(l_error)
        ya.err(l_message)
        return nil, l_message
    end

    --ya.dbg("l_fzf_output.status.success: " .. tostring(l_fzf_output.status.success))
    --ya.dbg("l_fzf_output.status.code: " .. tostring(l_fzf_output.status.code))
    --ya.dbg("l_fzf_output.stdout: " .. tostring(l_fzf_output.stdout))
    --ya.dbg("l_fzf_output.stderr: " .. tostring(l_fzf_output.stderr))

    -- Si se tiene un cogido de error
    if not l_fzf_output.status.success then

        -- Si retorna 130, el usuario salio de fzf (cancelado por el usuario)
        if l_fzf_output.status.code == 130 then
            return "", nil
        end

        -- Si es otro tipo de error
        l_message = nil
        if l_output.status.code then
            l_message = "fzf status-code: " .. tostring(l_output.status.code)
        end

        if l_output.stderr ~= nil and l_output.stderr ~= "" then
            if l_message == nil then
                l_message = "fzf error: " .. l_output.stderr
            else
                l_message = l_message .. ", fzf error: " .. l_output.stderr
            end
        end

        ya.err("fzf status.code: " .. tostring(l_output.status.code))
        ya.err("fzf stdout: " .. tostring(l_output.stdout))
        ya.err("fzf stderr: " .. tostring(l_output.stderr))
        return nil, l_message

    end

    return l_fzf_output.stdout, nil

end




local function m_read_args(p_job)

    if not p_job then
        return nil, nil, nil, nil, nil
    end

    local args = p_job.args or {}
    local nargs = #args
    --ya.dbg("args: " .. m_dump_table(args))

    -- Leer el 1er argumento (tipo de subcomando)
	if nargs <= 0 then
        ya.dbg('No se define el subcomando')
        return nil
    end

    local l_cmd_type = args[1]
    --ya.dbg("args[1]: " .. l_cmd_type)

    if l_cmd_type == nil or l_cmd_type == "" then
        ya.dbg('No se define el subcomando')
        return nil
    end

    -- Opcion
    local use_tmux = false
	if args.tmux then

        --ya.dbg("args.tmux: " .. tostring(args.tmux))
        use_tmux = true

    end

    -- Opcion
    local height = nil
	if args.height then

        --ya.dbg("args.height: " .. tostring(args.height))
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

        --ya.dbg("args.width: " .. tostring(args.width))
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

    -- Opcion
    local l_editor_type=0
    if args.editor then

        data = tostring(args.editor)
        if data == "vim" then
            l_editor_type = 1
        elseif data == "nvim" then
            l_editor_type = 2
        else
            ya.err("La opcion '--editor' tiene formato invalido '" .. data .. "'." )
        end

    end

    -- Opcion
    local l_find_path_type = nil
    if args.findpath then
        l_find_path_type = tostring(args.findpath)
    end

    return l_cmd_type, use_tmux, height, width, l_editor_type, l_find_path_type

end


local function m_opentab_with_selected_files(p_cwd_path, p_script_path, p_selected_urls, p_pane_wd, p_editor_type)

    -- Creando los argumentos del comando
    local l_args = {
        "-e",
        tostring(p_editor_type),
        "-w",
        p_pane_wd,
    }

    local l_url = nil
    for i = 1, #p_selected_urls do

        l_url = p_selected_urls[i]

        -- Convertir el objeto Url a string y adicionarlo en el arreglo de argumentos
        table.insert(l_args, tostring(l_url))

    end
    --ya.dbg("l_args: " ..  m_dump_table(l_args, " "))


    -- Generar el comando
    local l_cmd = Command(p_script_path)
        :arg(l_args)
        :cwd(p_cwd_path)
        :stdout(Command.PIPED)

    --ya.dbg("Before Command")

    -- Ejecutar el comando
    local l_error = nil
    local l_child = nil
    local l_message = nil

    l_child, l_error = l_cmd:spawn()
    if not l_child then
        l_message ="cmd failed to start: " .. tostring(l_error)
        ya.err(l_message)
        return l_message
    end

    --ya.dbg("Before spawn")

    -- Esperar a que el comando termine de ejecutar y devuelva el STDOUT
    local l_output = nil

    l_output, l_error = l_child:wait_with_output()
    if not l_output then
        l_message = "cmd output error: " .. tostring(l_error)
        ya.err(l_message)
        return l_message
    end

    --ya.dbg("l_output.status.success: " .. tostring(l_output.status.success))
    --ya.dbg("l_output.status.code: " .. tostring(l_output.status.code))
    --ya.dbg("l_output.stdout: " .. tostring(l_output.stdout))
    --ya.dbg("l_output.stderr: " .. tostring(l_output.stderr))

    -- Si el comando devolvio un codigo de error en su ejecucion
    if not l_output.status.success then

        l_message = nil
        if l_output.status.code then
            l_message = "status-code: " .. tostring(l_output.status.code)
        end

        if l_message == nil then
            l_message = "error during the execution '" .. p_script_path .. "'."
        else
            l_message = l_message .. ", error during the execution '" .. p_script_path .. "'."
        end

        ya.err(p_script_path .. " status-code: " .. tostring(l_output.status.code))
        ya.err(p_script_path .. " stdout: " .. tostring(l_output.stdout))
        ya.err(p_script_path .. " stderr: " .. tostring(l_output.stderr))
        return l_message

    end

    return nil

end


---------------------------------------------------------------------------------
-- Funcion que deben ser ejecutadas dentro sanbox de yazi
---------------------------------------------------------------------------------
--
-- Estas funciones se caracterizan:
-- > Tienen, opcionalmente. el 1er argumento al objeto 'state' (configuracion del usuario).
-- > Si tiene mas de 1 argumento, estos son argumento pasados del que lo invoca.
-- > Para evitar problemas entre diferentes llamadas de hilos, solo se puede enviar uno de los siguientes
--   tipo de datos (https://yazi-rs.github.io/docs/plugins/overview/?utm_source=chatgpt.com#sendable).
--

-- Funcion sincrona que se ejecutara por yazi para capturar algunos datos relevantes del estado actual de yazi.
local function m_get_ui_info_sync()

    -- El tab actual
    local l_current_tab = cx.active

    -- Las URLs de lo objetos selecionados
	--local l_selected = {}
	--for _, url in pairs(l_current_tab.selected) do
	--	l_selected[#l_selected + 1] = url
	--end

    -- El folder de trabajo actual
    local l_cwd_url = l_current_tab.current.cwd

    -- Los archivos ocultos se muestran
    --local l_hidden_files_are_shown = l_current_tab.pref.show_hidden

	return l_cwd_url

end

-- Crear un puntero a la funcion sincrona que se ejecuta en el hilo principal del UI.
local m_get_ui_info = ya.sync(m_get_ui_info_sync)



-- Obtener el 'state' del plugin (las opciones configurables por el usuario) y establece valores por defecto.
-- Se genera unc copia del objeto para sea accedido fuera de 'ya.sync()' o 'ya.async()'
local function m_get_plugin_state_sync(p_state)

    -- Establecer el valor por defecto al 'state'
	if p_state == nil then
        p_state = {}
    end

    -- Establecer los valores por defecto de campos generales
	if (p_state.root_wd == nil) then
		p_state.root_wd = ""
	end

	if (p_state.script_path == nil) then
		p_state.script_path = ""
	end

    -- Estalecer los valores por defecto del comando 'fd'
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


    -- Estalecer los valores por defecto del comando 'fzf'
    if p_state.fzf_options == nil then
        p_state.fzf_options = {}
    end

	if p_state.fzf_options.is_multiple == nil then
		p_state.fzf_options.is_multiple = true
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

        root_wd = p_state.root_wd,
        script_path = p_state.script_path,

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

end

-- Crear un puntero a la funcion sincrona que se ejecuta en el hilo principal del UI.
local m_get_plugin_state = ya.sync(m_get_plugin_state_sync)



---------------------------------------------------------------------------------
-- Funciones basicas usando por el entrypopoins del plugin
---------------------------------------------------------------------------------
--

function m_process_action_async(l_cmd_type, l_use_tmux, l_height, l_width, l_editor_type, l_find_path_type, l_state, l_cwd_url)

    -- Salir de modo ...
	ya.emit("escape", { visual = true })

    if l_cwd_url.scheme then
	    if l_cwd_url.scheme.is_virtual then
            ya.dbg("Not supported under virtual filesystems")
	        return ya.notify({ title = "fzf-fd", content = "Not supported under virtual filesystems", timeout = 5, level = "warn" })
	    end
    end

    -- Ocultar la Yazi
	local l_permit = ui.hide()

    local l_cwd_path = tostring(l_cwd_url)
    ya.dbg("l_cwd_path : " .. tostring(l_cwd_path))

    -- Obtener la ruta donde se buscaran los archivos
    local l_rootgit_path = nil
    local l_message = nil

    local l_find_path = l_cwd_path
    if l_find_path_type == "rootwd" then

        -- Validar si el 'root workingdir' esta habilitado
        if l_state.root_wd == nil or l_state.root_wd == "" then
	        return ya.notify({ title = "fzf-fd", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
        end
        l_find_path = l_state.root_wd

    elseif l_find_path_type == "rootgit" then

        l_rootgit_path, l_message = m_go_git_root_folder(l_cwd_path)
        if l_message ~= nil then
	        return ya.notify({ title = "fzf-fd", content = l_message, timeout = 5, level = "error" })
        end

        l_find_path = l_rootgit_path

    end

    ya.dbg("l_find_path  : " .. tostring(l_find_path))

    -- Ejecutar 'fd | fzf' y obtener el STDOUT del resultado
    local l_output = nil
    l_output, l_message = m_run_fzf_fd(l_state, l_find_path, l_cmd_type, l_use_tmux, l_height, l_width)

    -- Restaurar (mostrar) yazi
    if l_permit then
        l_permit:drop()
    end

    -- Si hubo un error al ejecutar fzf
	if l_output == nil then
        --ya.err(tostring(l_message))
		return ya.notify({ title = "fzf-fd", content = tostring(l_message), timeout = 5, level = "error" })
	end

    -- Si no se seleciono nada en fzf
	if l_output == "" then
        return
    end
    --ya.dbg("l_output  : " .. tostring(l_output))

    -- Convertir los STDOUT de ruta de los archivos seleccionados por fzf en objetos Url con rutas absolutas
	local l_selected_urls = m_get_urls_of(l_output, l_find_path)
    ya.dbg("l_selected_urls  : " .. m_dump_table(l_selected_urls))

    -- Si solo se seleciona archivos/folderes
    if l_cmd_type == "file" or l_cmd_type == "folder" then

        -- Segun el tipo de Url, realizar tareas ...
	    if #l_selected_urls == 1 then
	    	local l_cha = fs.cha(l_selected_urls[1])
	    	ya.emit(l_cha and l_cha.is_dir and "cd" or "reveal", { l_selected_urls[1], raw = true })
	    elseif #l_selected_urls > 1 then
	    	l_selected_urls.state = "on"
	    	ya.emit("toggle_all", l_selected_urls)
	    end

        return
    end

    -- Si se edita archivos de texto creando una nueva ventana de la terminal

    -- Obtener el directorio de trabajo a usar
    local l_pane_wd = nil
    l_message = nil

    if l_cmd_type == "rootwd" then

        -- Validar si el 'root workingdir' esta habilitado
        if l_state.root_wd == nil or l_state.root_wd == "" then
	        return ya.notify({ title = "fzf-fd", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
        end
        l_pane_wd = l_state.root_wd

    elseif l_cmd_type == "rootgit" then

        if l_rootgit_path == nil or l_rootgit_path == "" then

            l_pane_wd, l_message = m_go_git_root_folder(l_cwd_path)
            if l_message ~= nil then
	            return ya.notify({ title = "fzf-fd", content = l_message, timeout = 5, level = "error" })
            end

        else
            l_pane_wd = l_rootgit_path
        end

    else

        ya.err("El valor del subcomando no es valido '" .. tostring(l_options.open_type) .. "'.")
        return

    end

    if l_pane_wd == nil or l_pane_wd == "" then
        ya.dbg("No se ha definido el directorio a trabajo a usar")
        return
    end

    -- Abrir los archivos en un tab
    --ya.dbg("l_state.script_path: " .. tostring(l_state.script_path))
    --ya.dbg("l_pane_wd: " .. tostring(l_pane_wd))
	--ya.dbg("l_editor_type: " .. tostring(l_editor_type))
    l_message = m_opentab_with_selected_files(l_cwd_path, l_state.script_path, l_selected_urls, l_pane_wd, l_editor_type)
    if l_message ~= nil then
	    return ya.notify({ title = "fzf-fd", content = l_message, timeout = 5, level = "error" })
    end

end



---------------------------------------------------------------------------------
-- Funciones a exportar e invocados por yazi
---------------------------------------------------------------------------------

-- Funcion que customiza las opciones de configuracion
function mod.setup(p_state, p_args)

    if not p_args then
	    return
	end

    -- Establecer los valores de campos generales
	if p_args.root_wd ~= nil then
		p_state.root_wd = p_args.root_wd
	end

	if p_args.script_path ~= nil then
		p_state.script_path = p_args.script_path
    end

    -- Establecer los valores del comando 'fd'
    if p_args.fd_options then

        if p_state.fd_options == nil then
            p_state.fd_options = {}
        end

        p_state.fd_options.max_depth = p_args.fd_options.max_depth or 16
        p_state.fd_options.excludes = p_args.fd_options.excludes or {}
        p_state.fd_options.extra_args = p_args.fd_options.extra_args or {}

    end

    -- Establecer valores del comando 'fzf'
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
    local l_cmd_type, l_use_tmux, l_height, l_width, l_editor_type, l_find_path_type = m_read_args(p_job)
    if l_cmd_type == nil or l_cmd_type == "" then
        return
    end

    ya.dbg("l_cmd_type  : " .. l_cmd_type)

    -- Obtener las opciones configurable del usuario usando los valores por defecto
    local l_state = m_get_plugin_state()
    ya.dbg("l_state  : " .. m_dump_table(l_state))

    local l_cwd_url =  m_get_ui_info()
    --ya.dbg("l_ui_info: " .. m_dump_table(l_ui_info))

    m_process_action_async(l_cmd_type, l_use_tmux, l_height, l_width, l_editor_type, l_find_path_type, l_state, l_cwd_url)

end


-- Retornar los miembros publicos del modulo
return mod
