--
-- Plugin que permite:
--  > Permite ir a directorios especificos.
--  > Muestra directorios y folderes buscados por fd y fzf y luego permite ir a la ubicacion de estos
--    dentro del explorar yazi.
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

    -- Opcion 'type'
    ya.dbg('args.type: ' .. tostring(args["type"]))

    if l_cmd_type == "openintab" then

        l_options.open_type = args["type"]

        -- Opcion 'editor'
        l_options.editor_type=0
        local l_data = nil
        if args.editor then

            l_data = tostring(args.editor)
            if l_data == "vim" then
                l_options.editor_type = 1
            elseif l_data == "nvim" then
                l_options.editor_type = 2
            else
                ya.err("La opcion '--editor' tiene formato invalido '" .. l_data .. "'." )
            end

        end

    elseif l_cmd_type == "copycb" then

        l_options.path_type = args["type"]

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
        l_message = "git output error: " .. tostring(l_err)
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



local function m_opentab_with_selected_files(p_cwd, p_script_path, p_file_paths, p_pane_wd, p_editor_type)


    -- Creando los argumentos del comando
    local l_args = {
        "-e",
        tostring(p_editor_type),
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

    -- El tab actual
    local l_current_tab = cx.active

    -- El folder de trabajo actual
    local l_cwd = l_current_tab.current.cwd

    -- Los archivos ocultos se muestran
    --local l_hidden_files_are_shown = l_current_tab.pref.show_hidden

	return l_cwd

end)


-- Funcion para capturar algunos datos relevantes de yazi.
local m_get_current_yazi_info2 = ya.sync(function()

    -- El tab actual
    local l_current_tab = cx.active

    -- Obtener las ruta de los archivos selecionados (omitir los folderes)
	local l_selected_urls = {}
	for _, l_url in pairs(l_current_tab.selected) do
        table.insert(l_selected_urls, l_url)
    end

    -- Si no nada selecionado, y el cursor esta selecionado a un archivo, usar este
    local l_current_file = nil
    local l_file = l_current_tab.current.hovered
    if l_file then

        -- Si no es directorio
        if not l_file.cha.is_dir then
            l_current_file = tostring(l_file.url.path)
        end

    end
    --ya.dbg("l_current_path: " .. tostring(l_current_file))


    -- El folder de trabajo actual
    local l_cwd = l_current_tab.current.cwd

    -- Los archivos ocultos se muestran
    --local l_hidden_files_are_shown = l_current_tab.pref.show_hidden

	return l_cwd, l_selected_urls, l_current_file

end)


-- Funcion para capturar algunos datos relevantes de yazi.
local m_get_current_yazi_info3 = ya.sync(function()

    -- El tab actual
    local l_current_tab = cx.active

    -- Si no nada selecionado, y el cursor esta selecionado a un archivo, usar este
    local l_current_url = nil
    local l_file = l_current_tab.current.hovered
    if l_file then
        l_current_url = l_file.url
    end

    -- El folder de trabajo actual
    local l_cwd = l_current_tab.current.cwd

    -- Los archivos ocultos se muestran
    --local l_hidden_files_are_shown = l_current_tab.pref.show_hidden

	return l_cwd, l_current_url

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
	        return ya.notify({ title = "go-fs (rootgit)", content = "It's not git folder (" .. l_message .. ")", timeout = 5, level = "error" })
        end

        if l_git_folder == nil or l_git_folder == "" then
            ya.dbg("el comando no arrojo error pero no devolvio la ruta del git padre")
            return
        end

        ya.dbg("git_folder: " .. tostring(l_git_folder))
        local url = Url(l_git_folder)
		ya.emit("cd", { url, raw = true })

        return

    end

    -- Si se desea ir al root git folder
    if l_cmd_type == "openintab" then

        if l_options.open_type == nil then
            return
        end

        -- Obtener informacion actual
        local l_cwd, l_selected_urls, l_current_path = m_get_current_yazi_info2()
        ya.dbg("l_cwd: " .. tostring(l_cwd))

        -- Obtener las rutas absolutas de los archivos seleccionados
        local l_paths = m_get_file_fullpath(l_selected_urls)

        if not l_paths or #l_paths < 1 then

            if not l_current_path then
	            return ya.notify({ title = "go-fs (openintab)", content = "You must select at least one file or set the cursor to a file.", timeout = 5, level = "warn" })
            else
                l_paths = { l_current_path }
            end

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
	            return ya.notify({ title = "go-fs (openintab)", content = "It's not git folder (" .. l_message .. ")", timeout = 5, level = "error" })
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
        l_message = m_opentab_with_selected_files(l_cwd, l_state.script_path, l_paths, l_pane_wd, l_options.editor_type)
        if l_message ~= nil then
	        return ya.notify({ title = "go-fs (openintab)", content = l_message, timeout = 5, level = "error" })
        end

        return

    end

    -- Si se desea copiar al clipboard
    if l_cmd_type == "copycb" then

        if l_options.path_type == nil then
            return
        end

        -- Obtener informacion actual
        local l_cwd, l_current_url = m_get_current_yazi_info3()
        if not l_current_url then
	        return ya.notify({ title = "go-fs (copycb)", content = "You must set the cursor to a file or folder.", timeout = 5, level = "warn" })
        end

        local l_base_path = nil

        -- Si se desea ir al root working-dir
        if l_options.path_type == "rootdir" then

            --ya.dbg("cwd_root: " .. tostring(l_state.cwd_root))
            if l_state.cwd_root == nil or l_state.cwd_root == "" then
	            return ya.notify({ title = "go-fs (copycb)", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
            end

            l_base_path = l_state.cwd_root

        -- Si se desea ir al root git folder
        elseif l_options.path_type == "rootgit" then

            local l_git_folder, l_message = m_go_git_root_folder(l_cwd)
            if l_message ~= nil then
	            return ya.notify({ title = "go-fs (copycb)", content = "It's not git folder (" .. l_message .. ")", timeout = 5, level = "error" })
            end

            if l_git_folder == nil or l_git_folder == "" then
                ya.dbg("el comando no arrojo error pero no devolvio la ruta del git padre")
                return
            end

            ya.dbg("git_folder: " .. tostring(l_git_folder))
            l_base_path = l_git_folder

        end

        if l_base_path == nil or l_base_path == "" then
            return
        end

        local l_relative_path = l_current_url:strip_prefix(l_base_path)
        if not l_relative_path then
	        return ya.notify({ title = "go-fs (copycb)", content = "Error to obtain relative path", timeout = 5, level = "error" })
        end

        ya.clipboard(tostring(l_relative_path))
    end

end



-- Retornar los miembros publicos del modulo
return mod
