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



local function m_filter_files1(p_selected_urls)

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


local function m_filter_files2(p_selected_paths)

    local l_files = {}
    if not p_selected_paths then
        return l_files
    end

    local l_path = nil
    local l_url = nil
    local l_cha = nil
    local l_err = nil

    for i = 1, #p_selected_paths do

        l_path = p_selected_paths[i]
        l_url = Url(l_path)

        -- Obtener caracteristicas/propiedades del archivo/folder relacionado al objeto URL
        l_cha, l_err = fs.cha(l_url, true)
        if not l_err then

           -- Si no es directorio
           if not l_cha.is_dir then
               table.insert(l_files, l_path)
           end

        end

    end

    return l_files

end



---------------------------------------------------------------------------------
-- Funcion especificas de rg y fzf
---------------------------------------------------------------------------------


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

local function m_opentab(p_cwd, p_script_path, p_pane_wd)


    -- Creando los argumentos del comando
    local l_args = {
        "-w",
        p_pane_wd,
    }

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




---------------------------------------------------------------------------------
-- Funcion que deben ser ejecutadas dentro sanbox de yazi
---------------------------------------------------------------------------------
--
-- Estas funciones se caracterizan:
-- > Tienen, opcionalmente. el 1er argumento al objeto 'state' (configuracion del usuario).
-- > Si tiene mas de 1 argumento, estos son argumento pasados del que lo invoca.
-- > Para evitar problemas entre diferentes llamadas de hilos, solo se puede enviar uno de los siguientes
--   tipo de datos (https://yazi-rs.github.io/docs/plugins/overview/?utm_source=chatgpt.com#sendable).


local function m_get_ui_info_sync(p_state, p_get_selected_files, p_get_hovered_file)

    ya.dbg("p_get_selected_files : " .. tostring(p_get_selected_files))
    ya.dbg("p_get_hovered_file   : " .. tostring(p_get_hovered_file))

    -- El tab actual
    local l_current_tab = cx.active

    -- Obtener las ruta de los archivos selecionados (omitir los folderes)
	local l_selected_files = nil
    if p_get_selected_files then

	    l_selected_files = {}
	    for _, l_url in pairs(l_current_tab.selected) do
            table.insert(l_selected_files, tostring(l_url))
            --table.insert(l_selected_files, l_url)
        end

    end

    -- Si no nada selecionado, usa el elemento mostrado en el cursor actual ('hovered element')
    local l_hovered_file = nil
    if p_get_hovered_file then
        local l_file = l_current_tab.current.hovered
        if l_file then

            -- Si no es directorio
            if not l_file.cha.is_dir then
                l_hovered_file = tostring(l_file.url)
                --l_hovered_file = tostring(l_file.url.path)
            end

        end
    end
    --ya.dbg("l_hovered_file_path: " .. tostring(l_hovered_file))


    -- El folder de trabajo actual
    local l_cwd = tostring(l_current_tab.current.cwd)
    --local l_cwd = l_current_tab.current.cwd

    -- Los archivos ocultos se muestran
    --local l_hidden_files_are_shown = l_current_tab.pref.show_hidden

    local l_ui_info = {
        cwd = l_cwd,
        selected_files = l_selected_files,
        hovered_file = l_hovered_file,
    }

	return l_ui_info

end



-- Crear uyn puntero a la funcion sincrona que se ejecuta en el hilo principal del UI.
local m_get_ui_info = ya.sync(m_get_ui_info_sync)



-- Obtener el 'state' del plugin (las opciones configurables por el usuario) y establece valores por defecto.
-- Se genera unc copia del objeto para sea accedido fuera de 'ya.sync()' o 'ya.async()'
local function m_get_plugin_state_sync(p_state)

    -- Establecer el valor por defecto al 'state'
	if (p_state.cwd_root == nil) then
		p_state.cwd_root = ""
	end

	if (p_state.script_path_1 == nil) then
		p_state.script_path_1 = ""
	end

	if (p_state.script_path_2 == nil) then
		p_state.script_path_2 = ""
	end

    -- Devolver un copia del objeto 'state'
    local l_state = {
        cwd_root = p_state.cwd_root,
        script_path_1 = p_state.script_path_1,
        script_path_2 = p_state.script_path_2,
    }

    return l_state

end

-- Crear uyn puntero a la funcion sincrona que se ejecuta en el hilo principal del UI.
local m_get_plugin_state = ya.sync(m_get_plugin_state_sync)



---------------------------------------------------------------------------------
-- Funciones basicas usando por el entrypopoins del plugin
---------------------------------------------------------------------------------
--

local function m_read_args_1(p_job)

    if not p_job then
        return nil, {}
    end

    -- Actualmente el soporte de opciones esta en beta, solo soporta argumentos posicionales
    local l_args = p_job.args or {}
    local nargs = #l_args
    --ya.dbg("l_args: " .. m_dump_table(l_args))

    -- Leer el 1er argumento (tipo de subcomando)
	if nargs <= 0 then
        ya.dbg('No se define el subcomando')
        return nil, {}
    end

    local l_cmd_type = l_args[1]
    ya.dbg("args[1]: " .. l_cmd_type)

    if l_cmd_type == nil or l_cmd_type == "" then
        ya.dbg('No se define el subcomando')
        return nil, {}
    end

    -- Leer los opciones
    local l_options= {}

    -- Opcion 'type'
    ya.dbg('args.type: ' .. tostring(l_args["type"]))

    if l_cmd_type == "openintab" then

        l_options.parent_type = l_args["type"]

        -- Opcion 'editor'
        l_options.editor_type=0
        local l_data = nil
        if l_args.editor then

            l_data = tostring(l_args.editor)
            if l_data == "vim" then
                l_options.editor_type = 1
            elseif l_data == "nvim" then
                l_options.editor_type = 2
            else
                ya.err("La opcion '--editor' tiene formato invalido '" .. l_data .. "'." )
            end

        end

    elseif l_cmd_type == "newtab" then

        l_options.parent_type = l_args["type"]

    elseif l_cmd_type == "copycb" then

        l_options.parent_type = l_args["type"]

    elseif l_cmd_type == "gofolder" then

        l_options.parent_type = l_args["type"]

    end

    return l_cmd_type, l_options

end


local function m_read_args_2(p_args)

    if not p_args then
        return nil, {}
    end

    -- Actualmente el soporte de opciones esta en beta, solo soporta argumentos posicionales
    local l_args = p_args or {}
    local nargs = #l_args
    --ya.dbg("l_args: " .. m_dump_table(l_args))

    -- Leer el 1er argumento (tipo de subcomando)
	if nargs <= 0 then
        ya.dbg('No se define el subcomando')
        return nil, {}
    end

    local l_cmd_type = l_args[1]
    ya.dbg("args[1]: " .. l_cmd_type)

    if l_cmd_type == nil or l_cmd_type == "" then
        ya.dbg('No se define el subcomando')
        return nil, {}
    end

    -- Leer los opciones
    local l_options= {}

    -- Opcion 'type'
    ya.dbg('args[2]: ' .. tostring(l_args[2]))

    if l_cmd_type == "openintab" then

        l_options.parent_type = l_args[2]

        -- Opcion 'editor'
        l_options.editor_type=0
        local l_data = nil
        if l_args.editor then

            l_data = tostring(l_args[3])
            if l_data == "vim" then
                l_options.editor_type = 1
            elseif l_data == "nvim" then
                l_options.editor_type = 2
            else
                ya.err("La opcion 'args[3]' tiene formato invalido '" .. l_data .. "'." )
            end

        end

    elseif l_cmd_type == "newtab" then

        l_options.parent_type = l_args[2]

    elseif l_cmd_type == "copycb" then

        l_options.parent_type = l_args[2]

    elseif l_cmd_type == "gofolder" then

        l_options.parent_type = l_args[2]

    end

    return l_cmd_type, l_options

end

-- Obtener los flags de campos a UI obtener por un tipo de accion/comando
local function m_get_flags_ui_info(p_cmd_type)

    local l_flag_get_cwd = false
    local l_flag_get_selected_files = false
    local l_flag_get_hovered_file = false

    -- Si se desea ir un folder determinado
    if p_cmd_type == "gofolder" then

        if p_options.parent_type == "rootdir" then
            l_flag_get_cwd = false
        elseif p_options.parent_type == "rootgit" then
            l_flag_get_cwd = true
        end

    -- Si se desea abrir un terminal editanto los archivos selected o hovered
    elseif p_cmd_type == "openintab" then

        l_flag_get_cwd = true
        l_flag_get_selected_files = true
        l_flag_get_hovered_file = true

    -- Si se desea abrir un terminal en determino folder
    elseif p_cmd_type == "newtab" then

        l_flag_get_cwd = true

    -- Si se desea copiar al clipboard la ruta relativa del archivo actual (selected/hovered)
    elseif p_cmd_type == "copycb" then

        l_flag_get_cwd = true
        l_flag_get_selected_files = false
        l_flag_get_hovered_file = true

    end

    return l_flag_get_cwd, l_flag_get_selected_files, l_flag_get_hovered_file

end



-- Debe ejecutarse en un conexto asincrono
local function m_process_action_async(p_cmd_type, p_options, p_state, p_ui_info)


    -- Salir el modo ....
	ya.emit("escape", { visual = true })


    -- Si se desea ir un folder determinado
    if p_cmd_type == "gofolder" then

        if p_options.parent_type == nil then
            return
        end

        -- Si se desea ir al root working-dir
        if p_options.parent_type == "rootdir" then

            --ya.dbg("cwd_root: " .. tostring(p_state.cwd_root))
            if p_state.cwd_root == nil or p_state.cwd_root == "" then
	            return ya.notify({ title = "go-fs (gofolder)", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
            end

            local url = Url(p_state.cwd_root)
	    	ya.emit("cd", { url, raw = true })
            return

        end

        -- Si se desea ir al root git folder
        if p_options.parent_type == "rootgit" then

            -- Obtener informacion actual
            local l_cwd = p_ui_info.cwd

            local l_git_folder, l_message = m_go_git_root_folder(l_cwd)
            if l_message ~= nil then
	            return ya.notify({ title = "go-fs (gofolder)", content = "It's not git folder (" .. l_message .. ")", timeout = 5, level = "error" })
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

    end

    -- Si se desea abrir un terminal editanto los archivos selected o hovered
    if p_cmd_type == "openintab" then

        if p_options.parent_type == nil then
            return
        end

        -- Obtener informacion actual
        local l_cwd = p_ui_info.cwd
        local l_selected_file_paths = p_ui_info.selected_files
        local l_hovered_file_path = p_ui_info.hovered_file
        ya.dbg("l_cwd: " .. tostring(l_cwd))

        -- Obtener las rutas absolutas de los archivos seleccionados
        local l_paths = m_filter_files2(l_selected_file_paths)

        if not l_paths or #l_paths < 1 then

            if not l_hovered_file_path then
	            return ya.notify({ title = "go-fs (openintab)", content = "You must select at least one file or set the cursor to a file.", timeout = 5, level = "warn" })
            else
                l_paths = { l_hovered_file_path }
            end

        end
        ya.dbg("l_paths: " .. m_dump_table(l_paths, " "))

        -- Obtener el directorio de trabajo a usar
        local l_pane_wd = nil
        local l_message = nil
        if p_options.parent_type == "rootdir" then

            -- Validar si el root directorio
            if p_state.cwd_root == nil or p_state.cwd_root == "" then
	            return ya.notify({ title = "go-fs (openintab)", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
            end
            l_pane_wd = p_state.cwd_root

        elseif p_options.parent_type == "rootgit" then

            l_pane_wd, l_message = m_go_git_root_folder(l_cwd)
            if l_message ~= nil then
	            return ya.notify({ title = "go-fs (openintab)", content = "It's not git folder (" .. l_message .. ")", timeout = 5, level = "error" })
            end

        else

            ya.err("El valor de 'state.parent_type' no valido '" .. tostring(p_options.parent_type) .. "'.")
            return

        end

        if l_pane_wd == nil or l_pane_wd == "" then
            ya.dbg("No se ha definido el directorio a trabajo a usar")
            return
        end

        -- Abrir los archivos en un tab
        ya.dbg("p_state.script_path: " .. tostring(p_state.script_path_1))
        ya.dbg("l_pane_wd: " .. tostring(l_pane_wd))
        l_message = m_opentab_with_selected_files(l_cwd, p_state.script_path_1, l_paths, l_pane_wd, p_options.editor_type)
        if l_message ~= nil then
	        return ya.notify({ title = "go-fs (openintab)", content = l_message, timeout = 5, level = "error" })
        end

        return

    end

    -- Si se desea abrir un terminal en determino folder
    if p_cmd_type == "newtab" then

        if p_options.parent_type == nil then
            return
        end

        -- Obtener informacion actual
        local l_cwd = p_ui_info.cwd
        ya.dbg("l_cwd: " .. tostring(l_cwd))

        -- Obtener el directorio de trabajo a usar
        local l_pane_wd = nil
        local l_message = nil
        if p_options.parent_type == "rootdir" then

            -- Validar si el root directorio
            if p_state.cwd_root == nil or p_state.cwd_root == "" then
	            return ya.notify({ title = "go-fs (newtab)", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
            end
            l_pane_wd = p_state.cwd_root

        elseif p_options.parent_type == "rootgit" then

            l_pane_wd, l_message = m_go_git_root_folder(l_cwd)
            if l_message ~= nil then
	            return ya.notify({ title = "go-fs (newtab)", content = "It's not git folder (" .. l_message .. ")", timeout = 5, level = "error" })
            end

        else

            ya.err("El valor de 'state.parent_type' no valido '" .. tostring(p_options.parent_type) .. "'.")
            return

        end

        if l_pane_wd == nil or l_pane_wd == "" then
            ya.dbg("No se ha definido el directorio a trabajo a usar")
            return
        end

        -- Abrir los archivos en un tab
        ya.dbg("p_state.script_path: " .. tostring(p_state.script_path_2))
        ya.dbg("l_pane_wd: " .. tostring(l_pane_wd))
        l_message = m_opentab(l_cwd, p_state.script_path_2, l_pane_wd)
        if l_message ~= nil then
	        return ya.notify({ title = "go-fs (newtab)", content = l_message, timeout = 5, level = "error" })
        end

        return

    end
    -- Si se desea copiar al clipboard la ruta relativa del archivo actual (selected/hovered)
    if p_cmd_type == "copycb" then

        if p_options.parent_type == nil then
            return
        end

        -- Obtener informacion actual
        local l_cwd = p_ui_info.cwd
        local l_hovered_file_path = p_ui_info.hovered_file
        if not l_hovered_file_path then
	        return ya.notify({ title = "go-fs (copycb)", content = "You must set the cursor to a file or folder.", timeout = 5, level = "warn" })
        end

        local l_base_path = nil

        -- Si se desea ir al root working-dir
        if p_options.parent_type == "rootdir" then

            --ya.dbg("cwd_root: " .. tostring(p_state.cwd_root))
            if p_state.cwd_root == nil or p_state.cwd_root == "" then
	            return ya.notify({ title = "go-fs (copycb)", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
            end

            l_base_path = p_state.cwd_root

        -- Si se desea ir al root git folder
        elseif p_options.parent_type == "rootgit" then


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

        --ya.dbg('l_base_path : ' .. tostring(l_base_path))
        if l_base_path == nil or l_base_path == "" then
            return
        end

        local l_url = Url(l_hovered_file_path)
        local l_relative_path = l_url:strip_prefix(l_base_path)
        if not l_relative_path then
	        return ya.notify({ title = "go-fs (copycb)", content = "Error to obtain relative path", timeout = 5, level = "error" })
        end

        --ya.dbg('l_relative_path : ' .. tostring(l_relative_path))
        ya.clipboard(tostring(l_relative_path))

    end

end


local function m_process_remote_event(p_args)

    local l_cmd_type, l_options = m_read_args_2(p_args)
    ya.dbg('l_cmd_type : ' .. tostring(l_cmd_type))
    ya.dbg("l_options  : " .. m_dump_table(l_options))

    if l_cmd_type == nil or l_cmd_type == "" then
        return
    end

    -- Obtener las opciones configurable del usaurio usando los valores por defecto
    local l_state = m_get_plugin_state()
    ya.dbg("l_state  : " .. m_dump_table(l_state))

    local l_flag_get_cwd, l_flag_get_selected_files, l_flag_get_hovered_file = m_get_flags_ui_info(l_cmd_type)
    local l_ui_info = {}
    if l_flag_get_cwd then
        l_ui_info = m_get_ui_info(l_flag_get_selected_files, l_flag_get_hovered_file)
        ya.dbg("l_ui_info: " .. m_dump_table(l_ui_info))
    end

    -- Por defecto la funcion reservada 'main' se ejecutan en forma asincrona)
    -- Debido a que no tdas las funciones de lo objetos integrados se puede ejecutar de forma sincrona,
    -- se esta ejecutando tambien en forma asincrona
    ya.async(function()
        m_process_action_async(l_cmd_type, l_options, l_state, l_ui_info)
    end)

end




---------------------------------------------------------------------------------
-- Funciones a exportar e invocados por yazi
---------------------------------------------------------------------------------

-- Funcion de inicialización cuando se inicializa yazi.
function mod.setup(p_state, p_args)

    --1. Customizar el 'state' del plugin

    --ya.dbg("setup")
    if not p_args then
	    return
	end

    if p_args.cwd_root ~= nil then
        p_state.cwd_root = p_args.cwd_root
    end


    if p_args.script_path_1 ~= nil then
        p_state.script_path_1 = p_args.script_path_1
    end

    --ya.dbg("script_path_2: " .. tostring(p_args.script_path_2))
    if p_args.script_path_2 ~= nil then
        p_state.script_path_2 = p_args.script_path_2
    end
    --ya.dbg("cwd_root: " .. p_state.cwd_root)


    --2. Registrando el mensajes
    ps.sub_remote("go-fs", m_process_remote_event)
    --ya.dbg("registro plugin (cwd: " .. p_state.cwd_root .. ")")


end



-- Funcion entrypoint del plugin cuando se ejecuta una accion (usualmente desde el keymapping)
function mod.entry(p_self, p_job)

    -- Leer los argumentos
    local l_cmd_type, l_options = m_read_args_1(p_job)
    if l_cmd_type == nil or l_cmd_type == "" then
        return
    end


    -- Obtener las opciones configurable del usuario usando los valores por defecto
    local l_state = m_get_plugin_state()
    ya.dbg("l_state  : " .. m_dump_table(l_state))

    local l_flag_get_cwd, l_flag_get_selected_files, l_flag_get_hovered_file = m_get_flags_ui_info(l_cmd_type)
    local l_ui_info = {}
    if l_flag_get_cwd then
        l_ui_info = m_get_ui_info(l_flag_get_selected_files, l_flag_get_hovered_file)
        ya.dbg("l_ui_info: " .. m_dump_table(l_ui_info))
    end


    m_process_action_async(l_cmd_type, l_options, l_state, l_ui_info)

end



-- Retornar los miembros publicos del modulo
return mod
