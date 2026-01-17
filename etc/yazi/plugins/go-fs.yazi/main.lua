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
        return nil
    end

    -- Actualmente el soporte de opciones esta en beta, solo soporta argumentos posicionales
    local args = p_job.args or {}
    local nargs = #args
    --ya.dbg("args: " .. m_dump_table(args))

    -- Leer el 1er argumento (tipo de subcomando)
	if nargs <= 0 then
        ya.dbg('No se define el subcomando')
        return
    end

    local cmd_type = args[1]
    ya.dbg("args[1]: " .. cmd_type)

    if cmd_type == nil or cmd_type == "" then
        ya.dbg('No se define el subcomando')
        return
    end

    -- Leer los siguientes arugmentos segun el subcomando
    --ya.dbg("args.flag: " .. tostring(args.flag))

    ---- 2do argumento
    --local data = nil
	--if nargs > 1 then

    --    data = tostring(args[2])
    --    ya.dbg("args[2]: " .. data)

    --    if data ~= nil and data ~= "" then
    --        if data == "yes" then
    --            use_tmux = true
    --        elseif data == "no" then
    --            use_tmux = false
    --        else
    --            use_tmux = nil
    --            ya.err("El argumento nro 2 'tmux' solo puede ser 'yes' o 'no', pero, tiene formato invalido '" .. data .. "'." )
    --        end
    --    end

    --end

    ---- 3er argumento
	--if nargs > 2 then

    --    data = tostring(args[3])
    --    ya.dbg("args[3]: " .. data)

    --    if data ~= nil and data ~= "" then

    --        -- Eliminar los espacios finales o iniciales
    --        --data = data:match("^%s*(.-)%s*$")

    --        -- Validar "0" o "0.12" OR números 1-99 con opcional fracción de 1-2 dígitos
    --        if data:match("^0(%.%d%d?)?$") or data:match("^[1-9]%d?(%.%d%d?)?$") then
    --            height = data
    --        else
    --            height = nil
    --            ya.err("El argumento nro 3 'height' tiene formato invalido '" .. data .. "'." )
    --        end

    --    end

    --end

    return cmd_type

end


local function m_go_git_root_folder(p_cwd)

    -- Generar el comando 'git'
    local git_cmd = Command("git")
        :arg({ "rev-parse", "--show-toplevel" })
        :cwd(tostring(p_cwd))
        :stdout(Command.PIPED)

    -- Ejecutar el comando 'git'
    local git_child, git_err = git_cmd:spawn()
    local l_message = ""
    if not git_child then
        l_message ="git failed to start: " .. tostring(git_err)
        ya.err(l_message)
        return nil, l_message
    end

    -- Esperar a que el comando termine de ejecutar y devuelva el STDOUT
    local git_output, git_err = git_child:wait_with_output()
    if not git_output then
        l_message = "git output error: " .. tostring(git_output)
        ya.err(l_message)
        return nil, l_message
    end

    -- Si el comando devolvio un codigo de error en su ejecucion
    if not git_output.status.success then
        l_message = "git error: " .. tostring(git_output.stderr)
        ya.err(l_message)
        return nil, l_message
    end

    l_git_folder = git_output.stdout:gsub("%s*$", "")
    return l_git_folder, nil

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
local m_get_current_yazi_info = ya.sync(function()

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
    local cmd_type = m_read_args(p_job)
    if cmd_type == nil or cmd_type == "" then
        return
    end

    -- Obtener las opciones configurable del usaurio usando los valores por defecto
    local l_state = m_get_current_yazi_state()

    -- Salir el modo ....
	ya.emit("escape", { visual = true })


    -- Si se desea ir al root working-dir
    if cmd_type == "rootdir" then

        --ya.dbg("cwd_root: " .. tostring(l_state.cwd_root))
        if l_state.cwd_root == nil or l_state.cwd_root == "" then
	        return ya.notify({ title = "go-fs", content = "Initial working directory is not defined", timeout = 5, level = "warn" })
        end

        local url = Url(l_state.cwd_root)
		ya.emit("cd", { url, raw = true })
        return

    end

    -- Obtener informacion actual
    local l_cwd, l_selects = m_get_current_yazi_info()

    -- Si se desea ir al root git folder
    if cmd_type == "rootgit" then

        local l_git_folder, l_message = m_go_git_root_folder(l_cwd)
        if l_message ~= nil then
	        return ya.notify({ title = "go-fs", content = l_message, timeout = 5, level = "error" })
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


end



-- Retornar los miembros publicos del modulo
return mod
