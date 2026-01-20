--
-- Plugin que muestra directorios y folderes buscados por rg en fzf y luego permite ir
-- a la ubicacion de estos dentro del explorar yazi.
-- Basado en: https://github.com/sxyazi/yazi/blob/main/yazi-plugin/preset/plugins/fzf.lua
--

---------------------------------------------------------------------------------
-- Variables generales del modulos
---------------------------------------------------------------------------------

-- Objeto retornado por el modulo devolvera
local mod = {}

--local m_command_rg  = 'rg'


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



---------------------------------------------------------------------------------
-- Funcion especificas de rg y fzf
---------------------------------------------------------------------------------

local function m_read_args(p_job)

    if not p_job then
        return nil, {}
    end

    -- Actualmente el soporte de opciones esta en beta, solo soporta argumentos posicionales
    local args = p_job.args or {}
    local nargs = #args
    --ya.dbg("args: " .. m_dump_table(args))

    -- Leer el 1er argumento (tipo de subcomando)
	if nargs <= 0 then
        ya.dbg('No se define el subcomando')
        return nil, {}
    end

    local l_cmd_type = args[1]
    ya.dbg("args[1]: " .. l_cmd_type)

    if l_cmd_type == nil or l_cmd_type == "" then
        ya.dbg('No se define el subcomando')
        return nil, {}
    end

    -- Leer los opciones
    local l_options= {}
    ya.dbg('args.type: ' .. tostring(args["type"]))

    if l_cmd_type == "openintab" then
        l_options.open_type = args["type"]
    end

    return l_cmd_type, l_options

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
        l_message = "git output error: " .. tostring(l_output)
        ya.err(l_message)
        return nil, l_message
    end

    --ya.dbg("l_output.status.success: " .. tostring(l_output.status.success))
    --ya.dbg("l_output.status.code: " .. tostring(l_output.status.code))
    --ya.dbg("l_output.stdout: " .. tostring(l_output.stdout))
    --ya.dbg("l_output.stderr: " .. tostring(l_output.stderr))

    -- Si el comando devolvio un codigo de error en su ejecucion
    if not l_output.status.success then
        l_message = "git error: " .. tostring(l_output.stderr)
        ya.err(l_message)
        return nil, l_message
    end

    l_git_folder = l_output.stdout:gsub("%s*$", "")
    return l_git_folder, nil

end



local function m_opentab_with_files(p_cwd, p_script_path, p_file_paths, p_pane_wd)


    -- Creando los argumentos del comando
    local l_args = {
        "-w",
        p_pane_wd,
    }

    local l_item = nil
    for i = 1, #p_file_paths do

        l_item = p_file_paths[i]
        table.insert(l_args, l_item)

    end


    -- Generar el comando
    local l_cmd = Command(p_script_path)
        :arg(l_args)
        :cwd(tostring(p_cwd))
        :stdout(Command.PIPED)

    ya.dbg("Before Command")

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

    ya.dbg("Before spawn")

    -- Esperar a que el comando termine de ejecutar y devuelva el STDOUT
    local l_output = nil

    l_output, l_err = l_child:wait_with_output()
    if not l_output then
        l_message = "cmd output error: " .. tostring(l_err)
        ya.err(l_message)
        return l_message
    end

    --ya.dbg("l_output.status.success: " .. tostring(l_output.status.success))
    --ya.dbg("l_output.status.code: " .. tostring(l_output.status.code))
    --ya.dbg("l_output.stdout: " .. tostring(l_output.stdout))
    --ya.dbg("l_output.stderr: " .. tostring(l_output.stderr))

    -- Si el comando devolvio un codigo de error en su ejecucion
    if not l_output.status.success then
        l_message = "status code '" .. tostring(l_output.status.code) .. "' during the execution '" .. p_script_path .. "'."
        ya.err(l_message)
        return l_message
    end

    return nil

end



local function m_get_file_fullpath(p_selected_urls)

    local l_files = {}
    if not p_selected_urls then
        return l_files
    end

    local l_url = nil
    local l_cha = nil
    local l_err = nil

    for i = 1, #p_selected_urls do

        l_url = p_selected_urls[i]

        -- Obtener caracteristicas/propiedades del archivo/folder relacionado al objeto URL
        l_cha, l_err = fs.cha(l_url, true)
        if not l_err then

           -- Si no es directorio
           if not l_cha.is_dir then
               table.insert(l_files, tostring(l_url.path))
           end

        end

    end

    return l_files

end


---------------------------------------------------------------------------------
-- Funcion que deben ser ejecutadas dentro sanbox de yazi
---------------------------------------------------------------------------------
--
-- Estas funciones se caracterizan:
-- > Tienen, opcionalmente. el 1er argumento al objeto 'state' (configuracion del usuario).
-- > Si tiene mas de 1 argumento, estos son argumento pasados del que lo invoca.
--

-- Funcion para capturar algunos datos relevantes de yazi.
local m_get_current_yazi_info1 = ya.sync(function()

	return cx.active.current.cwd

end)

-- Funcion para capturar algunos datos relevantes de yazi.
local m_get_current_yazi_info2 = ya.sync(function()

    local selected = {}
	for _, url in pairs(cx.active.selected) do
		selected[#selected + 1] = url
	end

	return cx.active.current.cwd, selected

end)

-- Obtener las opciones configurables por el usuario (state) y establece valores por defecto
-- Se genera unc copia del objeto para sea accedido fuera de 'ya.sync()' o 'ya.async()'
local m_get_current_yazi_state = ya.sync(function(p_state)

    -- Establecer el valor por defecto al 'state'
	if (p_state.cwd_root == nil) then
		p_state.cwd_root = ""
	end

	if (p_state.script_path == nil) then
		p_state.script_path = ""
	end

    -- Devolver un copia del objeto 'state'
    local l_state = {
        cwd_root = p_state.cwd_root,
        script_path = p_state.script_path,
    }

    return l_state

end)


---------------------------------------------------------------------------------
-- Funciones a exportar e invocados por yazi
---------------------------------------------------------------------------------

-- Funcion que customiza las opciones de configuracion
function mod.setup(p_state, p_args)

    --ya.dbg("setup")
    if not p_args then
	    return
	end

    if p_args.cwd_root ~= nil then
        p_state.cwd_root = p_args.cwd_root
    end


    if p_args.script_path ~= nil then
        p_state.script_path = p_args.script_path
    end
    --ya.dbg("cwd_root: " .. p_state.cwd_root)

end



-- Funcion entrypoint del plugin (cuando se ejecuta el keymapping asociado al plugin)
function mod.entry(p_self, p_job)

    -- Leer los argumentos
    local l_cmd_type, l_options = m_read_args(p_job)
    if l_cmd_type == nil or l_cmd_type == "" then
        return
    end

    -- Obtener las opciones configurable del usaurio usando los valores por defecto
    local l_state = m_get_current_yazi_state()

    -- Salir el modo ....
	ya.emit("escape", { visual = true })


    -- Si se desea ir al root working-dir
    if l_cmd_type == "rootdir" then

        --ya.dbg("cwd_root: " .. tostring(l_state.cwd_root))
        if l_state.cwd_root == nil or l_state.cwd_root == "" then
	        return ya.notify({ title = "go-fs (rootdir)", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
        end

        local url = Url(l_state.cwd_root)
		ya.emit("cd", { url, raw = true })
        return

    end

    -- Si se desea ir al root git folder
    if l_cmd_type == "rootgit" then

        -- Obtener informacion actual
        local l_cwd = m_get_current_yazi_info1()

        local l_git_folder, l_message = m_go_git_root_folder(l_cwd)
        if l_message ~= nil then
	        return ya.notify({ title = "go-fs (rootgit)", content = l_message, timeout = 5, level = "error" })
        end

        if l_git_folder == nil or l_git_folder == "" then
            ya.dbg("el comando no arrojo error pero no devolvio la ruta del git padre")
            return
        end

        ya.dbg("git_folder: " .. tostring(l_git_folder))
        local url = Url(l_state.cwd_root)
		ya.emit("cd", { url, raw = true })

        return

    end

    -- Si se desea ir al root git folder
    if l_cmd_type == "openintab" then

        if l_options.open_type == nil then
            return
        end

        -- Obtener informacion actual
        local l_cwd, l_selects = m_get_current_yazi_info2()
        ya.dbg("l_cwd: " .. tostring(l_cwd))

        -- Obtener las rutas absolutas de los archivos seleccionados
        local l_paths = m_get_file_fullpath(l_selects)
        if not l_paths then
	        return ya.notify({ title = "go-fs (openintab)", content = "Not selected files was found", timeout = 5, level = "warn" })
        end
        ya.dbg("l_paths: " .. m_dump_table(l_paths, " "))

        -- Obtener el directorio de trabajo a usar
        local l_pane_wd = nil
        local l_message = nil
        if l_options.open_type == "rootdir" then

            -- Validar si el root directorio
            if l_state.cwd_root == nil or l_state.cwd_root == "" then
	            return ya.notify({ title = "go-fs (openintab)", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
            end
            l_pane_wd = l_state.cwd_root

        elseif l_options.open_type == "rootgit" then

            l_pane_wd, l_message = m_go_git_root_folder(l_cwd)
            if l_message ~= nil then
	            return ya.notify({ title = "go-fs (openintab)", content = l_message, timeout = 5, level = "error" })
            end

        else

            ya.err("El valor de 'state.open_type' no valido '" .. tostring(l_options.open_type) .. "'.")
            return

        end

        if l_pane_wd == nil or l_pane_wd == "" then
            ya.dbg("No se ha definido el directorio a trabajo a usar")
            return
        end

        -- Abrir los archivos en un tab
        ya.dbg("l_state.script_path: " .. tostring(l_state.script_path))
        ya.dbg("l_pane_wd: " .. tostring(l_pane_wd))
        l_message = m_opentab_with_files(l_cwd, l_state.script_path, l_paths, l_pane_wd)
        if l_message ~= nil then
	        return ya.notify({ title = "go-fs (openintab)", content = l_message, timeout = 5, level = "error" })
        end

        return

    end

end



-- Retornar los miembros publicos del modulo
return mod
