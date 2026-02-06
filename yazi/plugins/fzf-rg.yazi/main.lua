--
-- Plugin que permite:
--  > Buscar en el contenido de archivos texto usando en fzf y luego permite ir a la ubicacion
--    de estos dentro del explorar yazi.
--

---------------------------------------------------------------------------------
-- Variables generales del modulos
---------------------------------------------------------------------------------

-- Objeto que el modulo devolvera
local mod = {}

local m_command_fzf = 'fzf'
local m_command_rg  = 'rg'

-- Variables generales
local m_is_windows = ya.target_os() == "windows"
--local m_is_unix_family = ya.target_family() == "unix"


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


-- Procesa la salida de rg (filtrada por fzf) que son lineas de formato 'archivo:linea:columna:texto'
local function m_get_files_of_rg_output(p_rg_output, p_cwd)

    -- Tabla de archivos unicos con informacion relevante
    local l_unique_files = {}

    -- Tabla usada para rastrear archivos ya procesados
    local l_processed_files = {}

    -- Contadores para debugging
    local l_total_lines = 0
    local l_processed_lines = 0

    local l_item_file    = nil
    local l_item_linenbr = nil
    local l_item_colnbr  = nil
    local l_item_txt     = nil
    local l_linenbr      = 0
    local l_colnbr       = 0
    local l_url_file     = nil
    local l_full_path    = nil

    -- Procesar cada línea del resultado
    for l_linea in p_rg_output:gmatch("[^\r\n]+") do

        l_total_lines = l_total_lines + 1

        -- Extraer archivo, línea, columna y texto
        l_item_file, l_item_linenbr, l_item_colnbr, l_item_txt = l_linea:match("^([^:]+):(%d+):(%d+):(.+)$")

        if l_item_file and l_item_linenbr then

            -- Convertir a números
            l_linenbr = tonumber(l_item_linenbr)
            l_colnbr  = tonumber(l_item_colnbr)

            if m_is_windows then
                l_item_file = l_item_file:gsub('/', '\\')
            end

            -- Crear URL absoluta
            l_url_file = Url(l_item_file)
            if not l_url_file.is_absolute then
                l_url_file = p_cwd:join(l_url_file)
            end

            l_full_path = tostring(l_url_file)

            -- Si es la primera vez que vemos este archivo
            if not l_processed_files[l_full_path] then

                table.insert(l_unique_files, {
                    full_path = l_full_path,
                    line_nbr = l_linenbr,
                    col_nrb = l_colnbr,
                })

                l_processed_files[l_full_path] = true
                l_processed_lines = l_processed_lines + 1
            end

        end

    end

    -- Debugging opcional
    --ya.dbg(string.format("Procesadas %d/%d líneas, %d archivos únicos", l_processed_lines, l_total_lines, #l_unique_files))

    return l_unique_files

end


-- Construye el argumentos del comando de 'rg'
-- Parametros:
-- > Define el tipo de objeto a filtrar: 'd' si es directorio, 'f' si es un archivo
local function m_build_rg_cmd(p_state, p_hidden_files_are_shown)


    local l_max_depth = p_state.rg_options.max_depth or 16

    local l_use_smart_case = false
    if p_state.rg_options.use_smart_case then
        l_use_smart_case = true
    end

    local l_excludes = p_state.rg_options.excludes or {}
    local l_extra_args = p_state.rg_options.extra_args or {}

    local l_cmd = "rg --column --line-number --no-heading --color=always"

    --if l_max_depth then
    --    l_cmd = l_cmd .. " --max-depth=" .. tostring(l_max_depth)
    --end

    if l_use_smart_case then
        l_cmd = l_cmd .. " --smart-case"
    end

    if p_hidden_files_are_shown then
        l_cmd = l_cmd .. " --hidden"
    end


    -- Argumento de excluir folders
    local l_item = nil
    local l_n = #l_excludes
    for i = 1, l_n do

        l_item = l_excludes[i]

        if l_item ~= nil and l_item ~= '' then
            l_cmd = l_cmd .. " --glob " .. ya.quote("!" .. l_item)
        end

    end

    l_cmd = l_cmd .. " {q}"
    return l_cmd

end


-- Construye el argumentos del comando de 'fzf'
local function m_get_fzf_arguments(p_state, p_cwd, p_initial_query, p_hidden_files_are_shown, p_use_tmux, p_height, p_width)

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

    local l_args = {
        "--disabled",
        "--info",
        "inline",
        "--layout",
        "reverse",
        "--height",
        tostring(l_height) .. "%",
        "--ansi",
        "--delimiter",
        ":",
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

    -- Query inicial de busqueda
    if p_initial_query then
        table.insert(l_args, '--query')
        table.insert(l_args, p_initial_query)
    end

    -- Argumento sobre el prompt a usar
    local l_prompt = '🔎 ripgrep> '
    if l_prompt ~= nil and l_prompt ~= "" then
        table.insert(l_args, '--prompt')
        table.insert(l_args, l_prompt)
    end

    -- Argumento sobre el preview a usar
    local l_preview = p_state.fzf_options.preview
    local l_preview_window = p_state.fzf_options.preview_window
    --ya.dbg("l_preview: " .. tostring(l_preview))
    --ya.dbg("l_preview_window: " .. tostring(l_preview_window))

    if l_preview ~= nil and l_preview ~= "" then
        table.insert(l_args, "--preview-window")
        table.insert(l_args, l_preview_window)
        table.insert(l_args, '--preview')
        table.insert(l_args, l_preview)
    end

    -- Argumento sobre el header a usar
    if l_header ~= nil and l_header ~= "" then
        l_header = "WorkingDir: " .. tostring(p_cwd) .. ", <ctrl+f> Fzf search" .. l_header
    else
        l_header = "WorkingDir: " .. tostring(p_cwd) .. ", <ctrl+f> Fzf search"
    end
    table.insert(l_args, '--header')
    table.insert(l_args, l_header)


    -- Argumentos bind de recarga y modificacion segun el cambio del query
    local l_rg_cmd = m_build_rg_cmd(p_state, p_hidden_files_are_shown)
    table.insert(l_args, "--bind")
    table.insert(l_args, "start:reload:" .. l_rg_cmd)

    table.insert(l_args, "--bind")
    if m_is_windows then
        table.insert(l_args, "change:reload:" .. l_rg_cmd .. " || call;")
    else
        table.insert(l_args, "change:reload:sleep 0.1;" .. l_rg_cmd .. " || true")
    end

    table.insert(l_args, "--bind")
    table.insert(l_args, "ctrl-f:unbind(change,alt-enter)+change-prompt(🔎 fzf> )+enable-search+clear-query")

    -- Argumentos bind adicionales ¿para que se usaria?
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


local function m_run_fzf_rg(p_state, p_cwd, p_initial_query, p_hidden_files_are_shown, p_use_tmux, p_height, p_width)

    --Obtener los argumentos para ejecutar 'fd'
    local l_args = m_get_fzf_arguments(p_state, p_cwd, p_initial_query, p_hidden_files_are_shown, p_use_tmux, p_height, p_width)
    --ya.dbg("fzf args: " .. m_dump_table(l_args))

    -- Generar el comando 'fzf'
    local l_cmd = Command(m_command_fzf)
        :arg(l_args)
        :cwd(tostring(p_cwd))
        :stdout(Command.PIPED)

    -- Ejecutar el comando 'fzf'
    local l_error = nil
    local l_child = nil
    local l_message = nil

    l_child, l_error = l_cmd:spawn()
    if not l_child then
        l_message = "fzf failed to start: " .. tostring(l_error)
        ya.err(l_message)
        return nil, l_message
    end

    -- Esperar a que el comando 'fzf' termine de ejecutar y devuelva el STDOUT
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



local function m_opentab_with_selected_files(p_cwd, p_script_path, p_info_files, p_pane_wd, p_editor_type)

    -- Creando los argumentos del comando
    local l_args = {
        "-e",
        tostring(p_editor_type),
        "-w",
        p_pane_wd,
        "-l",
        ""
    }

    local l_linenbr_lists = ""

    local l_item = nil
    for i = 1, #p_info_files do

        l_item = p_info_files[i]

        if i == 1 then
            l_linenbr_lists = tostring(l_item.line_nbr)
        else
            l_linenbr_lists = l_linenbr_lists .. "," .. tostring(l_item.line_nbr)
        end
        table.insert(l_args, l_item.full_path)

    end

    l_args[6] = l_linenbr_lists
    --ya.dbg("l_args: " ..  m_dump_table(l_args, " "))

    -- Generar el comando
    local l_cmd = Command(p_script_path)
        :arg(l_args)
        :cwd(tostring(p_cwd))
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


local function m_go_git_root_folder(p_cwd)

    -- Generar el comando 'git'
    local git_cmd = Command("git")
        :arg({ "rev-parse", "--show-toplevel" })
        :cwd(tostring(p_cwd))
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


local function m_read_args(p_job)

    if not p_job then
        return nil
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
    local data = nil

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

    return l_cmd_type, use_tmux, height, width, l_editor_type

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

    -- El tab actual
    local l_current_tab = cx.active

    -- Las URLs de lo objetos selecionados
	--local l_selected = {}
	--for _, url in pairs(l_current_tab.selected) do
	--	l_selected[#l_selected + 1] = url
	--end

    -- El folder de trabajo actual
    local l_cwd = l_current_tab.current.cwd

    -- Los archivos ocultos se muestran
    local l_hidden_files_are_shown = l_current_tab.pref.show_hidden


	return l_cwd, l_hidden_files_are_shown

end)



-- Obtener las opciones configurables por el usuario (state) y establece valores por defecto
-- Se genera unc copia del objeto para sea accedido fuera de 'ya.sync()' o 'ya.async()'
local m_get_current_yazi_state = ya.sync(function(p_state)

    -- Establecer el valor por defecto al 'state'
	if p_state == nil then
        p_state = {}
    end

    -- Establecer el valor por defecto al 'state'
	if (p_state.cwd_root == nil) then
		p_state.cwd_root = ""
	end

	if (p_state.script_path == nil) then
		p_state.script_path = ""
	end

    -- Estalecer valores del comando 'rg'
    if p_state.rg_options == nil then
        p_state.rg_options = {}
    end

	if p_state.rg_options.max_depth == nil then
		p_state.rg_options.max_depth = 16
	end

	if p_state.rg_options.excludes == nil then
		p_state.rg_options.excludes = { ".git/*", "node_modules/*", ".cache/*" }
	end

	if p_state.rg_options.use_smart_case == nil then
		p_state.rg_options.use_smart_case = true
	end

	--if p_state.rg_options.include_hidden == nil then
	--	p_state.rg_options.include_hidden = true
	--end

	if p_state.rg_options.extra_args == nil then
		p_state.rg_options.extra_args = {}
	end

    -- Estalecer valores del comando 'fzf'
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

	if not p_state.fzf_options.preview then
		p_state.fzf_options.preview = "bat --color=always --paging always --style=numbers,header-filename --highlight-line {2} {1}"
	end

	if not p_state.fzf_options.preview_window then
		p_state.fzf_options.preview_window = "down,60%"
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

        cwd_root = p_state.cwd_root,
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
            preview = p_state.fzf_options.preview,

            -- Estilo de la ventana preview
            preview_window = p_state.fzf_options.preview_window,

            -- Header a mostrar
            header = p_state.fzf_options.header,

            -- Arreglo de cadenas que representa los binds a usar
            binds = p_state.fzf_options.binds,

            -- Arreglo de cadenas que representa los argumento adicionales del comando:
            -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
            extra_args = p_state.fzf_options.extra_args,

        },

        -- Opciones de configuracion para el comando fd
        rg_options = {

            use_smart_case = p_state.rg_options.use_smart_case,
            --include_hidden = p_state.rg_options.include_hidden,

            -- Patrones de exclusión.
            excludes = p_state.rg_options.excludes,

            -- Arreglo de cadenas que representa los argumento adicionales del comando:
            -- > Si es una opcion con valor, colocar el nombre y su valor como elementos separado del arreglo.
            extra_args = p_state.rg_options.extra_args,

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

	if p_args.cwd_root ~= nil then
		p_state.cwd_root = p_args.cwd_root
	end

	if p_args.script_path ~= nil then
		p_state.script_path = p_args.script_path
    end

    if p_args.rg_options then

        if p_state.rg_options == nil then
            p_state.rg_options = {}
        end

        p_state.rg_options.max_depth = p_args.rg_options.max_depth or 16
        p_state.rg_options.excludes = p_args.rg_options.excludes or {}
        p_state.rg_options.extra_args = p_args.rg_options.extra_args or {}

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

	    if p_args.fzf_options.preview ~= nil then
            p_state.fzf_options.preview = p_args.fzf_options.preview
        end

	    if p_args.fzf_options.preview_window ~= nil then
            p_state.fzf_options.preview_window = p_args.fzf_options.preview_window
        end

        p_state.fzf_options.header = p_args.fzf_options.header or ""
        p_state.fzf_options.binds = p_args.fzf_options.binds or {}
        p_state.fzf_options.extra_args = p_args.fzf_options.extra_args or {}

    end

end


-- Funcion entrypoint del plugin (cuando se ejecuta el keymapping asociado al plugin)
function mod.entry(p_self, p_job)

    --1. Obtener datos de entrada

    -- Obtener los argumentos
    local l_cmd_type, l_use_tmux, l_height, l_width, l_editor_type = m_read_args(p_job)

    -- Salir de modo ...
	ya.emit("escape", { visual = true })

    -- Obtener las opciones configurable del usaurio usando los valores por defecto
    local l_state = m_get_current_yazi_state()
    --ya.dbg("l_state.fzf_options.preview: " .. tostring(l_state.fzf_options.preview))
    --ya.dbg("l_state.fzf_options.preview_window: " .. tostring(l_state.fzf_options.preview_window))

    -- Obtener datos del estado actual de yazi
	local l_cwd, l_hidden_files_are_shown = m_get_current_yazi_info()
    --ya.dbg("l_cwd: " .. tostring(l_cwd))
    --ya.dbg("l_hidden_files_are_shown: " .. tostring(l_hidden_files_are_shown))

    if l_cwd.scheme then
	    if l_cwd.scheme.is_virtual then
            ya.dbg("Not supported under virtual filesystems")
	        return ya.notify({ title = "fzf-rg", content = "Not supported under virtual filesystems", timeout = 5, level = "warn" })
	    end
    end


    --2. Obtener el query inicial de busqueda
    local l_initial_query, l_status = ya.input {
	    -- Position
	    pos = { "center", w = 50 },

	    -- Title
	    title = "RipGrep Query:",

	    -- Default value
	    value = "",

	    -- Whether to obscure the input.
	    obscure = false,

	    -- Whether to report user input in real time.
	    realtime = false,

	    -- Number of seconds to wait for the user to stop typing, available if `realtime = true`.
	    --debounce = 0.3,
    }

    if l_status ~= 1 then
        ya.dbg("El status al leer 'l_initial_query' es " .. tostring(l_status))
        return
    end

    if l_initial_query == nil or l_initial_query == "" then
        ya.dbg("No se ingreso el valor de 'l_initial_query'.")
        return
    end


    --3. Ejecutar 'fzf' y obtener los archivos seleccionados

    -- Ocultar la Yazi
	local l_permit = ui.hide()

    local l_output, l_message = m_run_fzf_rg(l_state, l_cwd, l_initial_query, l_hidden_files_are_shown, l_use_tmux, l_height, l_width)

    -- Restaurar (mostrar) yazi
    if l_permit then
        l_permit:drop()
    end

    -- Si hubo un error al ejecutar fzf
	if l_output == nil then
        --ya.err(tostring(l_message))
		return ya.notify({ title = "fzf-rg", content = tostring(l_message), timeout = 5, level = "error" })
	end

    -- Si no se seleciono nada en fzf
	if l_output == "" then
        return
    end

    -- Convertir los STDOUT de ruta de los archivos seleccionados indicando la lined del archivo a seleccionar.
	local l_info_files = m_get_files_of_rg_output(l_output, l_cwd)


    --4. Ejecutar el script que abre vim y los archivos selecionados

    -- Obtener el directorio de trabajo a usar
    local l_pane_wd = nil
    local l_message = nil
    if l_cmd_type == "rootdir" then

        -- Validar si el root directorio
        if l_state.cwd_root == nil or l_state.cwd_root == "" then
	        return ya.notify({ title = "fzf-rg", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
        end
        l_pane_wd = l_state.cwd_root

    elseif l_cmd_type == "rootgit" then

        l_pane_wd, l_message = m_go_git_root_folder(l_cwd)
        if l_message ~= nil then
	        return ya.notify({ title = "fzf-rg", content = l_message, timeout = 5, level = "error" })
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
    l_message = m_opentab_with_selected_files(l_cwd, l_state.script_path, l_info_files, l_pane_wd, l_editor_type)
    if l_message ~= nil then
	    return ya.notify({ title = "fzf-rg", content = l_message, timeout = 5, level = "error" })
    end


end


-- Retornar los miembros publicos del modulo
return mod
