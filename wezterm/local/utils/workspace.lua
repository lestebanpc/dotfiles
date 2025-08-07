--
-- Se requiere asociar un 'working directory' por defecto usado por el workspace, pero debido a que actualmente el 'workspace'
-- no cuenta con un ID unico diferente al nombre y este puede ser modificado por API ello imposibilida tener un cache de
-- worspace y poder identificarlos unicamente.
-- Ello provoca que la implementacion tenga las siguientes limitaciones:
-- > NO SE DEBE renombrar el worspace desde el comando 'wezterm cli' o usando el API directamente.
-- > DEBE renombrar el nombre usando la accion personalizada usado por ello (ello actualiza el cache de workspace)
--

-- Miembros privado del modulo que ser modificado por el usario del modulo
local m_custom = {

    root_git_folder = nil,
    external_root_git_folder = nil,

    external_equivalent_paths = nil,

    -- Usados para filtrar opciones de la consulta de zoxide
    -- Se adiciona despues del comando a ejecutar : 'zoxide query -l <zoxide_args>'.
    -- Ejemplo de valores:
    --    " | rg -Fxf ~/.projects"
    zoxide_args = "",
}

-- Miembros privados de uso interno
local mm_wezterm = require("wezterm")
local mm_ucommon = require("utils.common")
local mm_udomain = require("utils.domain")

-- Determinar el tipo de SO
--   0 > Si es Linux
--   1 > Si es Windows
--   2 > Si es MacOS (Apple Silicon)
--   3 > Si es MacOS (Intel)
local m_os_type = mm_ucommon.get_os_type()

-- Diccionario de los workspace existentes del windows actual y que fueron creados usando un 'folder' o un 'tag'.
-- > No todos los workspace existente en el windows actual estan registrados.
--   > Workspace que se crea o se renombra usando el API o CLI, no es contralado por este modulo por lo que no esta en
--     este diccionario (incluye 'default' workspace).
-- > Es un diccionario cuyo key es el nombre del workspace y el value es un objeto que incluye los 'working directory'
--   con la que trabajara:
--   > name                   : Nombre del workspace (mismo valor que el key del diccionario)
--   > source_type            : Segun el tipo de origen para generar el workspace pueden ser:
--       > 1 (tag           ) : Worspace creado usando el archio de configuracion.
--       > 2 (folder zoxide ) : Originado por un folder de zoxide
--       > 3 (folder git    ) : Originado por un folder de git
--   > fullpath               : Ruta completa del directorio de trabajo a usar.
--   > domain                 : Dominio al cual pertenece el 'fullpath'
--       > En Linux y Mac es  :
--           > Dominio 'local'.
--           > Dominio de tipo 'unix' (que no esta asociado a un servidor IPC externo al equipo local donde este la terminal).
--           > Dominio de tipo 'exec' asociado a un contenedor distrobox.
--       > En Windows es      :
--           > Dominio 'local'.
--           > Dominio de tipo 'wsl'.
--   > domain_category        : Define una forma de agrupar el domino al cual puede pertener un ruta 'fullpath' (working directory).
--       > local              : Si es el dominio local o un dominio de tipo 'unix' (si esta asociado a un servidor IPC ubicado en
--                              el mismo host que el emulador de terminal).
--                              Estos dominio siempre usan el mismo filesystem.
--       > distrobox          : Si es un dominio de tipo 'exec' asociado a un contenedor distrobox.
--       > wsl                : Si es un dominio de tipo 'wsl'
--   > tag_name               : Solo cuando el source_type es '1'.
--                              Inicialmente es el nombre del workspace pero puede modificarse.
-- > Todos worskpace que no esta en esta lista, se considera que usa el 'working directory' por defecto.
-- > Una vez creado el tab, cada panel adicional creado siempre usa el directorio de trabajo actual.
if mm_wezterm.GLOBAL.workspace_infos == nil then
    mm_wezterm.GLOBAL.workspace_infos = {}
end

-- Arreglo de tag de workspace, usado para crear worspace basado en la configuracion (no en rutas de de folderes git o zoxide).
-- > tag              : Nombre unico del tag.
--                      Debido a que inicialemente es el nombre del workspace, debe ser unico no puede usarse el nombre de workspace
--                      por defecto.
-- > fullpath         : Ruta completa del directorio de trabajo.
-- > is_window_path   : Valor calculado segun el 'fullpath' ingresado.
-- > domain_category  : Define una forma de agrupar el domino al cual puede pertener un ruta 'fullpath' (working directory).
--     > local        : Si es el dominio local o un dominio de tipo 'unix' (si esta asociado a un servidor IPC ubicado en
--                      el mismo host que el emulador de terminal.
--     > distrobox    : Si es un dominio de tipo 'exec' asociado a un contenedor distrobox.
--     > wsl          : Si es un dominio de tipo 'wsl'
-- > domain           : Opcional. Si no se define, la ruta aplica a todos los dominios de la misma categoria
-- > callback         : Funcion con parametros usado que modifica o crea paneles del worspace. Los parametros de este callback son:
--   > Objeto 'Window'
--   > Objeto 'Pane'
--   > Workspace name
--   > Workspace_info
local m_tags = nil

-- Constantes
local m_color_gray1 = '#787878'

local m_tag_icon = ''
local m_tag_color = '#41C9C9'

local m_git_folder_icon = ''
local m_git_folder_color = '#41C9C9'

local m_zoxide_folder_icon = ''
local m_zoxide_folder_color = '#41C9C9'


local m_workspace_icon = '󱂬'
local m_workspace_color = '#41C9C9'


---@alias action_callback any
---@alias MuxWindow any
---@alias Pane any
---@alias InputSelector_choices { id: string, label: string }[]

-- Miembros publicos del modulo
---@class public_module
local mod = {}


------------------------------------------------------------------------------------
-- Funciones inicializacion
------------------------------------------------------------------------------------

-- Arreglo de tag de workspace 'built-in', usado para crear worspace basado en la configuracion (no en rutas de de folderes git o zoxide).
-- > name             : Nombre unico del tag.
--                      Debido a que inicialemente es el nombre del workspace, debe ser unico no puede usarse el nombre de workspace
--                      por defecto.
-- > fullpath         : Ruta completa del directorio de trabajo.
-- > is_window_path   : Valor calculado segun el 'fullpath' ingresado.
-- > domain_category  : Define una forma de agrupar el domino al cual puede pertener un ruta 'fullpath' (working directory).
--     > local        : Si es el dominio local o un dominio de tipo 'unix' (si esta asociado a un servidor IPC ubicado en
--                      el mismo host que el emulador de terminal.
--     > distrobox    : Si es un dominio de tipo 'exec' asociado a un contenedor distrobox.
--     > wsl          : Si es un dominio de tipo 'wsl'
-- > domain           : Opcional. Si no se define, la ruta aplica a todos los dominios de la misma categoria
-- > callback         : Funcion con parametros usado que modifica o crea paneles del worspace. Los parametros de este callback son:
--   > Objeto 'Window'
--   > Objeto 'Pane'
--   > Workspace name
--   > Working directory (campo 'fullpath')
--   > Nombre del dominio al cual pertenece al ruta 'fullpath'
local function m_add_builtin_tags(p_tags)

    -- TODO: Incluir rutas de windows y soporte de WSL (el arreglo debe tener todas la rutas, segun el SO)

    -- Ruta de configuracion de los archivo dotfiles
    local l_tag = {
        name = 'dotfiles',
        fullpath = mm_wezterm.home_dir .. '/.files',
        domain_category = 'local',
        domain = nil,
        callback = nil,
    }
    l_tag.is_window_path = mm_ucommon.is_windows_path(l_tag.fullpath)

    -- Ruta de configuracion de wezterm
    l_tag = {
        name = 'config wezterm',
        fullpath = mm_wezterm.home_dir .. '/.config/wezterm',
        domain_category = 'local',
        domain = nil,
        callback = nil,
    }
    l_tag.is_window_path = mm_ucommon.is_windows_path(l_tag.fullpath)

    table.insert(p_tags, l_tag)


    -- Ruta de configuracion de los archivo ssh
    l_tag = {
        name = 'config ssh',
        fullpath = mm_wezterm.home_dir .. '/.ssh',
        domain_category = 'local',
        domain = nil,
        callback = nil,
    }
    l_tag.is_window_path = mm_ucommon.is_windows_path(l_tag.fullpath)

    table.insert(p_tags, l_tag)

    -- Ruta de configuracion de los archivo tmux
    l_tag = {
        name = 'config tmux',
        fullpath = mm_wezterm.home_dir .. '/.config/tmux',
        domain_category = 'local',
        domain = nil,
        callback = nil,
    }
    l_tag.is_window_path = mm_ucommon.is_windows_path(l_tag.fullpath)

    table.insert(p_tags, l_tag)

    -- Ruta de configuracion de los archivo git
    l_tag = {
        name = 'config git',
        fullpath = mm_wezterm.home_dir .. '/.config/git',
        domain_category = 'local',
        domain = nil,
        callback = nil,
    }
    l_tag.is_window_path = mm_ucommon.is_windows_path(l_tag.fullpath)

    table.insert(p_tags, l_tag)


end



function mod.setup(p_tags, p_root_git_folder, p_external_root_git_folder, p_external_equivalent_paths, p_zoxide_args)

    -- Establecer valores
    if p_root_git_folder ~= nil and p_root_git_folder ~= '' then
        if string.sub(p_root_git_folder, 1, 1) == '~' then
            m_custom.root_git_folder = mm_wezterm.home_dir .. string.sub(p_root_git_folder,2)
        else
            m_custom.root_git_folder = p_root_git_folder
        end
    else
        m_custom.root_git_folder = nil
    end
    m_custom.external_root_git_folder = p_external_root_git_folder
    m_custom.external_equivalent_paths = p_external_equivalent_paths
    m_custom.zoxide_args = p_zoxide_args

    -- Registrar los tag de workspace built-in
    m_tags = nil

    local l_tags = {}
    m_add_builtin_tags(l_tags)

    -- Registrar los tag de workspace personalizados
    local l_item = nil
    if p_tags ~= nil then

        for i = 1, #p_tags do

            l_item = p_tags[i]
            if l_item.name ~= nil and l_item.name ~= '' and
                l_item.fullpath ~= nil and l_item.fullpath ~= '' and
                l_item.domain_category ~= nil and l_item.domain_category ~= '' then

                l_item.is_window_path = mm_ucommon.is_windows_path(l_item.fullpath)
                table.insert(l_tags, l_item)

            end

        end

    end

    if #l_tags > 0 then
        m_tags = l_tags
    end

end



------------------------------------------------------------------------------------
-- Funciones de Utilidad
------------------------------------------------------------------------------------

function m_get_tag(p_tag_name)

    if p_tag_name == nil or p_tag_name == '' then
        return nil
    end

    if m_tags == nil then
        return
    end

    local l_tag = nil
    for i = 1, #m_tags do

        l_tag = m_tags[i]
        if l_tag.name == p_tag_name then
            return l_tag
        end

    end

    return nil

end

function mod.get_equivalent_fullpath(p_workspace_name, p_domain_info)

    -- No soportado para MacOS
    if m_os_type >= 2 then
        return nil
    end

    -- Solo valido para dominios que tiene habilidado una categoria a nivel workspace
    if p_domain_info == nil or p_domain_info.domain_category == nil or p_domain_info.domain_category == '' then
        return nil
    end

    -- Obtener la informacion de workspace
    local l_workspace_info = mm_wezterm.GLOBAL.workspace_infos[p_workspace_name]
    if l_workspace_info == nil then
        return nil
    end

    -- Si el workspace se creo usando una ruta del mismo dominio
    if p_domain_info.name == l_workspace_info.domain then
        return l_workspace_info.fullpath
    end

    -- Si tienen la misma categoria
    if p_domain_info.domain_category == l_workspace_info.domain_category then

        if p_domain_info.domain_category == 'local' then
            return l_workspace_info.fullpath
        end

        return nil

    end


    -- Si tiene diferente categoria. Si es 'local'
    if l_workspace_info.domain_category == 'local' then

        if p_domain_info.domain_category == 'wsl' then
            return mm_ucommon.windows_path_to_wsl_path(l_workspace_info.fullpath)
        end

        if p_domain_info.domain_category == 'distrobox' then
            -- Completar
            return nil
        end

        return nil

    end

    -- Si tiene diferente categoria. Si es 'wsl'
    if l_workspace_info.domain_category == 'wsl' then

        if p_domain_info.domain_category == 'local' then
            return mm_ucommon.wsl_path_to_windows_path(l_workspace_info.fullpath)
        end

        return nil

    end

    -- Si tiene diferente categoria. Si es 'distrobox'
    if l_workspace_info.domain_category == 'distrobox' then

        if p_domain_info.domain_category == 'local' then
            -- Completar
            return nil
        end

        return nil

    end

    return nil

end



------------------------------------------------------------------------------------
-- Funciones para obtener la source de workspaces
------------------------------------------------------------------------------------

local function m_get_current_workspaces()

    -- Obtener los worspaces existentes registrados en el multiplexor
    local l_workspace_names = mm_wezterm.mux.get_workspace_names()
    if l_workspace_names == nil then
        return nil
    end

    -- Obtener informacion de los workspace
    local l_workspace_info = nil

    -- Listado de workspaces
    local l_workspace_infos = mm_wezterm.GLOBAL.workspace_infos
	local l_workspace_datas = {}
    local l_workspace_name = nil

    for i = 1, #l_workspace_names do

        l_workspace_name = l_workspace_names[i]
        l_workspace_info = l_workspace_infos[l_workspace_name]

		table.insert(l_workspace_datas, {
			name = l_workspace_name,
            info = l_workspace_info,
		})

    end

	return l_workspace_datas

end


local function m_is_available_tag_for_domain(p_tag, p_domain_info)

    -- Si el tag y el dominio se tiene categoria de dominio diferentes
    if p_tag.domain_category ~= p_domain_info.domain_category then
        return false
    end

    if p_tag.domain ~= nil and p_tag.domain ~= '' and p_tag.domain ~= p_domain_info.name then
        return false
    end

    -- Si los workspace asociados a fullpaths y tags es nulo o vacio
    local l_workspace_infos = mm_wezterm.GLOBAL.workspace_infos
    --mm_wezterm.log_info(l_workspace_infos)

    if l_workspace_infos == nil then
    --if l_workspace_infos == nil or next(l_workspace_infos) == nil then
        return true
    end

    -- Si el tag ya esta vinculado a un workspace existente
    for _ , l_workspace_info in pairs(l_workspace_infos) do
        if l_workspace_info.tag_name ~= nil and l_workspace_info.tag_name ~= '' and l_workspace_info.tag_name == p_tag.name then
            return false
        end
    end

    return true

end


-- Se debe mostrar tag de dominios registrados (en caso de distrobox para que este registrado debe estar iniciado).
--   > El dominio 'local' siempre esta registrado.
--   > Un dominio de tipo 'wsl' siempre es registrados.
--   > Una distribucion distrobox no estan registrado si este no esta en ejecucion y en la carga de archivo de configuracion se cargo.
local function m_get_tags_of_domain(p_domain_info)

    if m_tags == nil then
        return nil
    end

    -- Si el dominio no tiene definido una categoria de agrupacion para workspace
    if p_domain_info == nil or p_domain_info.domain_category == nil or p_domain_info.domain_category == '' then
        return nil
    end

    local l_tags = {}
    local l_tag = nil
    local l_is_available = false

    for i = 1, #m_tags do

        l_tag = m_tags[i]

        -- Mostrar tags del dominio actual
        l_is_available = m_is_available_tag_for_domain(l_tag, p_domain_info)
        if l_is_available then
            table.insert(l_tags, l_tag)
        end

    end

    return l_tags

end


local function m_is_available_fullpath_for_domain(p_fullpath, p_domain_info)

    -- Si los workspace asociados a fullpaths y tags es nulo o vacio
    local l_workspace_infos = mm_wezterm.GLOBAL.workspace_infos
    if l_workspace_infos == nil then
    --if l_workspace_infos == nil or next(l_workspace_infos) == nil then
        return true
    end

    -- Si el tag ya esta vinculado a un workspace existente
    for _ , l_workspace_info in pairs(l_workspace_infos) do

        if l_workspace_info.fullpath ~= nil and l_workspace_info.fullpath ~= '' and
           l_workspace_info.domain ~= nil and l_workspace_info.domain == p_domain_info.name then

            if p_fullpath == l_workspace_info.fullpath then
                return false
            end

        end
    end

    return true

end



local function m_get_zoxide_folders(p_domain_info)

    -- Si el dominio no tiene definido una categoria de agrupacion para workspace
    if p_domain_info == nil or p_domain_info.domain_category == nil or p_domain_info.domain_category == '' then
        return nil
    end

    -- Determinar la distribucion externa asociado al dominio
    local l_distribution = nil
    if p_domain_info.domain_category == 'wsl' then
        l_distribution = p_domain_info.data.distribution
    elseif p_domain_info.domain_category == 'distrobox' then
        l_distribution = p_domain_info.ex_data.name
    end

    -- Validar si tiene instalado 'zoxide'
    local l_exist_commnad = mm_ucommon.exist_command('zoxide', m_os_type, l_distribution)

    if not l_exist_commnad then

        if l_distribution == nil and l_distribution == '' then
	    	mm_wezterm.log_error("Command 'zoxide' is not installed.")
        else
	    	mm_wezterm.log_error("Command 'zoxide' on '" .. l_distribution .. "' is not installed.")
        end

        return nil

    end

    -- Obtener los folderes de zoxide
    local l_folders = mm_ucommon.get_zoxide_folders(m_os_type, l_distribution)

    local l_is_available = false
    local l_filtered_folders = nil
    local l_folder = nil
    if l_folders ~= nil then

        l_filtered_folders = {}
        for i = 1, #l_folders do

            l_folder = l_folders[i]

            l_is_available = m_is_available_fullpath_for_domain(l_folders[i], p_domain_info)
            if l_is_available then
                table.insert(l_filtered_folders, l_folder)
            end

        end

    end

    return l_filtered_folders

end



local function m_get_git_folders(p_domain_info)

    --mm_wezterm.log_info(p_domain_info)

    -- Si el dominio no tiene definido una categoria de agrupacion para workspace
    if p_domain_info == nil or p_domain_info.domain_category == nil or p_domain_info.domain_category == '' then
        return nil
    end

    -- Determinar la distribucion externa asociado al dominio
    local l_root_folder = nil
    local l_distribution = nil

    if p_domain_info.domain_category == 'wsl' then

        l_distribution = p_domain_info.data.distribution
        l_root_folder = m_custom.external_root_git_folder

    elseif p_domain_info.domain_category == 'distrobox' then

        l_distribution = p_domain_info.ex_data.name
        l_root_folder = m_custom.external_root_git_folder

    else
        l_root_folder = m_custom.root_git_folder
    end

    -- Validar que se definio un folder git
    if l_root_folder == nil or l_root_folder == '' then
	    mm_wezterm.log_error("It does not define the git base path.")
    end

    -- Si el folder externo inicia con '~', expandirlo
    if p_domain_info.domain_category ~= 'local' then

        local l_initial_char = string.sub(l_root_folder, 1, 1)
        local l_home_dir = nil

        if l_initial_char == '~' then
            l_home_dir = mm_udomain.get_home_directory_of_domain1(p_domain_info)
        elseif l_initial_char == '@' then
            l_home_dir = mm_wezterm.home_dir
        end
        mm_wezterm.log_info(l_home_dir)

        if l_home_dir ~= nil and l_home_dir ~= '' then
                l_root_folder = l_home_dir .. string.sub(l_root_folder,2)
        end
        mm_wezterm.log_info(l_root_folder)

    end
    --mm_wezterm.log_info(l_root_folder)

    -- Validar si tiene instalado 'zoxide'
    local l_exist_commnad = mm_ucommon.exist_command('fd', m_os_type, l_distribution)

    if not l_exist_commnad then

        if l_distribution == nil and l_distribution == '' then
	    	mm_wezterm.log_error("Command 'fd' is not installed.")
        else
	    	mm_wezterm.log_error("Command 'fd' on '" .. l_distribution .. "' is not installed.")
        end

        return nil

    end

    -- Obtener los folderes de git
    local l_folders = mm_ucommon.get_git_folders({ path = l_root_folder, }, m_os_type, l_distribution)
    --mm_wezterm.log_info(l_folders)

    local l_is_available = false
    local l_filtered_folders = nil
    local l_folder = nil
    if l_folders ~= nil then

        l_filtered_folders = {}
        for i = 1, #l_folders do

            l_folder = l_folders[i]

            l_is_available = m_is_available_fullpath_for_domain(l_folders[i], p_domain_info)
            if l_is_available then
                table.insert(l_filtered_folders, l_folder)
            end

        end

    end

    return l_filtered_folders

end



------------------------------------------------------------------------------------
-- Workspace selector> Mostrar los label de las source de workspaces
------------------------------------------------------------------------------------

---@return string
local function m_get_choice_label_of_workspace(p_workspace_name, p_workspace_info, p_current_workspace_name)

    --   > name                   : Nombre del workspace (mismo valor que el key del diccionario)
    --   > source_type            : Segun el tipo de origen para generar el workspace pueden ser:
    --       > 1 (tag           ) : Worspace creado usando el archio de configuracion.
    --       > 2 (folder zoxide ) : Originado por un folder de zoxide
    --       > 3 (folder git    ) : Originado por un folder de git
    --   > fullpath               : Ruta completa del directorio de trabajo a usar.
    --   > domain                 : Dominio al cual pertenece el 'fullpath'
    --       > En Linux y Mac es  :
    --           > Dominio 'local'.
    --           > Dominio de tipo 'unix' (que no esta asociado a un servidor IPC externo al equipo local donde este la terminal).
    --           > Dominio de tipo 'exec' asociado a un contenedor distrobox.
    --       > En Windows es      :
    --           > Dominio 'local'.
    --           > Dominio de tipo 'wsl'.
    --   > domain_category        : Define una forma de agrupar el domino al cual puede pertener un ruta 'fullpath' (working directory).
    --       > local              : Si es el dominio local o un dominio de tipo 'unix' (si esta asociado a un servidor IPC ubicado en
    --                              el mismo host que el emulador de terminal).
    --                              Estos dominio siempre usan el mismo filesystem.
    --       > distrobox          : Si es un dominio de tipo 'exec' asociado a un contenedor distrobox.
    --       > wsl                : Si es un dominio de tipo 'wsl'
    --   > tag                    : Solo cuando el source_type es '1'.
    --                              Inicialmente es el nombre del workspace pero puede modificarse.

    local l_domain_info = nil
    if p_workspace_info ~= nil then
        l_domain_info = mm_udomain.get_domain_info(p_workspace_info.domain)
    end

    -- Mostrar informacion del dominio asociado al workspace
    local l_format_items = nil
    if l_domain_info == nil then

        local l_empty_str = string.rep(" ", 23)
        l_format_items = {
            { Foreground = { Color =  m_color_gray1 } },
            { Text = l_empty_str },
            'ResetAttributes',
        }

    else

        local l_domain_icon = l_domain_info.icon
        if l_domain_info.type == 'exec' and l_domain_info.ex_data ~= nil then

            if l_domain_info.ex_data.type == 'distrobox' then
                l_domain_icon = l_domain_info.ex_data.icon
            elseif l_domain_info.ex_data.type == 'container' then
                l_domain_icon = l_domain_info.ex_data.icon
            end

        end

        local l_fix_domain_name = mm_ucommon.truncate_string(l_domain_info.name, 20)
        l_format_items = {
            { Foreground = { Color =  m_color_gray1 } },
            { Text = ' ' .. l_domain_icon .. ' ' .. l_fix_domain_name  },
            'ResetAttributes',
        }
    end


    -- Mostrar informacion del workspace actual
    local l_is_current_workspace = p_workspace_name == p_current_workspace_name
    local l_fix_workspace_name = mm_ucommon.truncate_string(p_workspace_name, 40)

    if l_is_current_workspace then
        table.insert(l_format_items, { Foreground = { Color =  m_workspace_color } } )
        table.insert(l_format_items, { Text = ' ' .. m_workspace_icon .. ' ' .. l_fix_workspace_name .. ' ' } )
        table.insert(l_format_items, 'ResetAttributes' )
    else
        table.insert(l_format_items, { Foreground = { Color =  m_workspace_color } } )
        table.insert(l_format_items, { Text = ' ' .. m_workspace_icon .. ' ' } )
        table.insert(l_format_items, 'ResetAttributes' )
        table.insert(l_format_items, { Text = l_fix_workspace_name .. ' ' } )
    end

    -- Mostrar informacion adicional
    if p_workspace_info ~= nil then

        table.insert(l_format_items, { Foreground = { Color =  m_color_gray1 } } )

        local l_source_icon = nil
        local l_text = ''

        if p_workspace_info.source_type == 1 then

            l_source_icon = m_tag_icon
            if p_workspace_info.tag_name ~= nil and p_workspace_info.tag_name ~= p_workspace_name then
                l_text = p_workspace_info.tag_name .. ', ' .. p_workspace_info.fullpath
            else
                l_text = p_workspace_info.fullpath
            end

        elseif p_workspace_info.source_type == 2 then

            l_source_icon = m_zoxide_folder_icon
            if p_workspace_info.fullpath ~= p_workspace_name then
                l_text = p_workspace_info.fullpath
            end

        else

            l_source_icon = m_git_folder_icon
            if p_workspace_info.fullpath ~= p_workspace_name then
                l_text = p_workspace_info.fullpath
            end

        end



        table.insert(l_format_items, { Text = ' ' .. l_source_icon .. ' ' .. l_text .. ' ' } )
        table.insert(l_format_items, 'ResetAttributes' )

    end

    return mm_wezterm.format(l_format_items)

end

---@return string
local function m_get_choice_label_of_tag(p_tag, p_home_dir, p_domain_info)

    -- Mostrar informacion del dominio asociado al workspace
    local l_domain_icon = p_domain_info.icon
    if p_domain_info.type == 'exec' and p_domain_info.ex_data ~= nil then

        if p_domain_info.ex_data.type == 'distrobox' then
            l_domain_icon = p_domain_info.ex_data.icon
        elseif p_domain_info.ex_data.type == 'container' then
            l_domain_icon = p_domain_info.ex_data.icon
        end

    end

    local l_fix_domain_name = mm_ucommon.truncate_string(p_domain_info.name, 20)
    local l_format_items = {
        { Foreground = { Color =  m_color_gray1 } },
        { Text = ' ' .. l_domain_icon .. ' ' .. l_fix_domain_name  },
        'ResetAttributes',
    }

    -- Enviar informacion del tag
    --mm_wezterm.log_info(p_tag)
    local l_fix_tag_name = mm_ucommon.truncate_string(p_tag.name, 40)

    table.insert(l_format_items, { Foreground = { Color =  m_tag_color } } )
    table.insert(l_format_items, { Text = ' ' .. m_tag_icon .. ' ' } )
    table.insert(l_format_items, 'ResetAttributes' )
    table.insert(l_format_items, { Text = l_fix_tag_name .. ' ' } )

    -- Mostrar informacion adicional
    if p_tag.name ~= p_tag.fullpath then

        local l_short_fullpath = string.gsub(p_tag.fullpath, p_home_dir, '~')
        table.insert(l_format_items, { Foreground = { Color =  m_color_gray1 } } )
        table.insert(l_format_items, { Text = ' ' .. l_short_fullpath .. ' ' } )
        table.insert(l_format_items, 'ResetAttributes' )

    end

    return mm_wezterm.format(l_format_items)

end



---@return string
local function m_get_choice_label_of_folder(p_fullpath, p_home_dir, p_use_zoxide_folder, p_domain_info)

    -- Mostrar informacion del dominio asociado al workspace
    local l_domain_icon = p_domain_info.icon
    if p_domain_info.type == 'exec' and p_domain_info.ex_data ~= nil then

        if p_domain_info.ex_data.type == 'distrobox' then
            l_domain_icon = p_domain_info.ex_data.icon
        elseif p_domain_info.ex_data.type == 'container' then
            l_domain_icon = p_domain_info.ex_data.icon
        end

    end

    local l_fix_domain_name = mm_ucommon.truncate_string(p_domain_info.name, 20)
    local l_format_items = {
        { Foreground = { Color =  m_color_gray1 } },
        { Text = ' ' .. l_domain_icon .. ' ' .. l_fix_domain_name  },
        'ResetAttributes',
    }

    -- Enviar informacion del tag
    local l_short_fullpath = string.gsub(p_fullpath, p_home_dir, '~')
    --local l_fix_fullpath = mm_ucommon.truncate_string(l_short_fullpath, 40)
    local l_folder_color = m_zoxide_folder_color
    local l_folder_icon = m_zoxide_folder_icon
    if not p_use_zoxide_folder then
        l_folder_icon = m_git_folder_icon
        l_folder_color = m_git_folder_color
    end

    table.insert(l_format_items, { Foreground = { Color =  l_folder_color } } )
    table.insert(l_format_items, { Text = ' ' .. l_folder_icon .. ' ' } )
    table.insert(l_format_items, 'ResetAttributes' )
    table.insert(l_format_items, { Text = l_short_fullpath .. ' ' } )
    --table.insert(l_format_items, { Text = l_fix_fullpath .. ' ' } )

    return mm_wezterm.format(l_format_items)

end



------------------------------------------------------------------------------------
-- Workspace selector> Obtener los 'choices' que se muestra en el 'input selector'
------------------------------------------------------------------------------------

local function m_get_choices_of_workspace(p_workspace_datas, p_current_workspace_name)


    local l_choices = {}

    -- 1. Mostar el workspace ya creados
    local l_item = nil
    if p_workspace_datas ~= nil then

        for i = 1, #p_workspace_datas do

            l_item = p_workspace_datas[i]

            table.insert(l_choices, {
                id = string.format('0|*|%s', l_item.name),
                label = m_get_choice_label_of_workspace(l_item.name, l_item.info, p_current_workspace_name),
            })

        end

    end

    return l_choices


end



local function m_add_choices_of_domain(p_choices, p_tags, p_folders, p_use_zoxide_folder, p_domain_info)

    -- 1. Precondiciones
    --mm_wezterm.log_info(p_domain_info)

    -- Si no se envio donde se adicionara los 'chioces'
    if p_choices == nil then
        return
    end

    -- Si el dominio no tiene definido una categoria de agrupacion para workspace
    if p_domain_info == nil or p_domain_info.domain_category == nil or p_domain_info.domain_category == '' then
        return
    end

    -- Si no se tiene data
    if p_tags == nil and p_folders == nil then
        return
    end

    -- 2. Obtener el 'home dir' asociado al dominio
    local l_home_dir = mm_udomain.get_home_directory_of_domain1(p_domain_info)
    --mm_wezterm.log_info(l_home_dir)
    --mm_wezterm.log_info(p_folders)


    -- 3. Mostrar los tag
    local l_source_type = 1
    local l_item = nil

    if p_tags ~= nil then

        for i = 1, #p_tags do

            l_item = p_tags[i]

            table.insert(p_choices, {
                id = string.format('%d|%s|%s', l_source_type, p_domain_info.name, l_item.name),
                label = m_get_choice_label_of_tag(l_item, l_home_dir, p_domain_info),
            })

        end

    end

    -- 4. Mostrar los folderes
    l_source_type = 3
    if p_use_zoxide_folder then
        l_source_type = 2
    end

    if p_folders ~= nil then

        for i = 1, #p_folders do

            l_item = p_folders[i]

            table.insert(p_choices, {
                id = string.format('%d|%s|%s', l_source_type, p_domain_info.name, l_item),
                label = m_get_choice_label_of_folder(l_item, l_home_dir, p_use_zoxide_folder, p_domain_info),
            })

        end

    end


end



-- Los 'choices' puede ser:
--  > Siempre se debe mostrar todos los worskpace creados hasta el momento.
--  > Los tag y fullpath a mostrar, dependeran de varios factores:
--    > Si el dominio NO es de categoria local, siempre mostrara tag y fullpath de su dominio actual.
--      Por ahora solo estan habilitados los dominios de categoria 'wsl' y 'distrobox'.
--    > Si el domnio es de categorio 'local', se mostrar los tag y fullpath de este dominio y puede mostrar los de un dominio alternativo.
--       > El dominio alternativo es una domnio asociado a una instancia Distrobox/WSL en ejecución y que esta registrado.
--         > Para una dominio exec 'Distrobox', se requiere dominio este registrado y ello implica que el contenedor distrobox este
--           en ejecucion (inicie el contenedor y recargue el archivo de configuracion).
--         > Para un dominio WSL este registrado no se requiere que la distribucion WSL este iniciado. Este se inicia automaticamente
--           cuando se inicia un dominio de esta instancia.
---@param p_current_domain_name string
---@param p_current_workspace_name string
---@param p_use_zoxide_folder boolean
---@return InputSelector_choices
local function m_get_choices(p_current_domain_name, p_current_workspace_name, p_use_zoxide_folder)

    -- 1. Obtener la informacion del domnio actual
    local l_current_domain_info = mm_udomain.get_domain_info(p_current_domain_name)
    if l_current_domain_info == nil then
        mm_wezterm.log_error('not fount domain info of "' .. p_current_domain_name .. '".')
        return {}
    end
    --mm_wezterm.log_info(l_current_domain_info)


    -- 2. Obtener los workspace ya creados
	local l_workspace_datas = m_get_current_workspaces()


    -- 3. Si es un dominio de categoria local, determinar existe un dominio alternativo al actual donde se debe mostrar sus tag y fullpath.
    local l_alternative_domain_info = nil

    if not l_current_domain_info.is_external then

        if m_os_type == 1 then

            -- Verificar si existe una instancia WSL en ejecucion y esta registrado
            l_alternative_domain_info = mm_udomain.get_wsl_running_domain()

        elseif m_os_type == 0 then

            -- Verificar si la instancia Distrobox en ejecucion y esta registrado
            l_alternative_domain_info = mm_udomain.get_distrobox_running_domain()

        end

    end

    -- 4. Obtener los tags que se usara para crear los workspace
    local l_current_tags = m_get_tags_of_domain(l_current_domain_info)
    local l_alternative_tags = m_get_tags_of_domain(l_alternative_domain_info)

    -- 5. Obtener los folderes de Zoxide
    local l_current_folders = nil
    local l_alternative_folders = nil
    if p_use_zoxide_folder then

        l_current_folders = m_get_zoxide_folders(l_current_domain_info)
        l_alternative_folders = m_get_zoxide_folders(l_alternative_domain_info)
        --mm_wezterm.log_info(l_current_folders)

    -- 6. Obtener los folderes de Git
    else

        l_current_folders = m_get_git_folders(l_current_domain_info)
        l_alternative_folders = m_get_git_folders(l_alternative_domain_info)

    end

    -- 7. Generar las opciones a mostrar

    -- Adicionar los worskpace ya creados
    local l_choices = m_get_choices_of_workspace(l_workspace_datas, p_current_workspace_name)

    -- Adicionar los tag y foldere del dominio actual
    m_add_choices_of_domain(l_choices, l_current_tags, l_current_folders, p_use_zoxide_folder, l_current_domain_info)

    -- Adicionar los tag y foldere del dominio alternativo
    m_add_choices_of_domain(l_choices, l_alternative_tags, l_alternative_folders, p_use_zoxide_folder, l_alternative_domain_info)

    return l_choices

end



------------------------------------------------------------------------------------
-- Workspace selector> Procesar el 'choice' seleccionado
------------------------------------------------------------------------------------


-- Crear el workspace asociado al dominio selecionado.
local function m_create_workspace_of_tag(p_window, p_pane, p_selected_tag_name, p_selected_domain_info, p_current_domain_name)

    -- Obtener la informacion del tag seleccionado
    local l_tag = m_get_tag(p_selected_tag_name)
    if l_tag == nil then
        return
    end

    --mm_wezterm.log_info(l_tag)

    -- Crear la informacion del workspace info
    --   > name                   : Nombre del workspace (mismo valor que el key del diccionario)
    --   > source_type            : Segun el tipo de origen para generar el workspace pueden ser:
    --       > 1 (tag           ) : Worspace creado usando el archio de configuracion.
    --       > 2 (folder zoxide ) : Originado por un folder de zoxide
    --       > 3 (folder git    ) : Originado por un folder de git
    --   > fullpath               : Ruta completa del directorio de trabajo a usar.
    --   > domain                 : Dominio al cual pertenece el 'fullpath'
    --       > En Linux y Mac es  :
    --           > Dominio 'local'.
    --           > Dominio de tipo 'unix' (que no esta asociado a un servidor IPC externo al equipo local donde este la terminal).
    --           > Dominio de tipo 'exec' asociado a un contenedor distrobox.
    --       > En Windows es      :
    --           > Dominio 'local'.
    --           > Dominio de tipo 'wsl'.
    --   > domain_category        : Define una forma de agrupar el domino al cual puede pertener un ruta 'fullpath' (working directory).
    --       > local              : Si es el dominio local o un dominio de tipo 'unix' (si esta asociado a un servidor IPC ubicado en
    --                              el mismo host que el emulador de terminal).
    --                              Estos dominio siempre usan el mismo filesystem.
    --       > distrobox          : Si es un dominio de tipo 'exec' asociado a un contenedor distrobox.
    --       > wsl                : Si es un dominio de tipo 'wsl'
    --   > tag                    : Solo cuando el source_type es '1'.
    --                              Inicialmente es el nombre del workspace pero puede modificarse.
    local l_workspace_info = {
        name = p_selected_tag_name,
        source_type = 1,
        fullpath = l_tag.fullpath,
        domain = p_selected_domain_info.name,
        domain_category = p_selected_domain_info.domain_category,
        tag_name = p_selected_tag_name,
    }

    mm_wezterm.GLOBAL.workspace_infos[p_selected_tag_name] = l_workspace_info


    -- Crear el workspace selecionado
    local l_spawncommand = {
	    label = "Workspace: " .. p_selected_tag_name,
        domain = { DomainName = p_selected_domain_info.name },
		cwd = l_tag.fullpath,
	}

	p_window:perform_action(
		mm_wezterm.action.SwitchToWorkspace({
			name = p_selected_tag_name,
			spawn = l_spawncommand,
		}),
		p_pane
	)

    -- Ejecutar el callback
    if l_tag.callback ~= nil then
        --   > Objeto 'Window'
        --   > Objeto 'Pane'
        --   > Workspace name
        --   > Workspace_info
        l_tag.callback(p_window, p_pane, p_selected_tag_name, l_workspace_info)
    end




end


-- Crear el workspace asociado al fullpath dominio selecionado.
local function m_create_workspace_of_fullpath(p_window, p_pane, p_selected_fullpath, p_is_zoxide_folder, p_selected_domain_info, p_current_domain_name)


    -- Crear la informacion del workspace info
    --   > name                   : Nombre del workspace (mismo valor que el key del diccionario)
    --   > source_type            : Segun el tipo de origen para generar el workspace pueden ser:
    --       > 1 (tag           ) : Worspace creado usando el archio de configuracion.
    --       > 2 (folder zoxide ) : Originado por un folder de zoxide
    --       > 3 (folder git    ) : Originado por un folder de git
    --   > fullpath               : Ruta completa del directorio de trabajo a usar.
    --   > domain                 : Dominio al cual pertenece el 'fullpath'
    --       > En Linux y Mac es  :
    --           > Dominio 'local'.
    --           > Dominio de tipo 'unix' (que no esta asociado a un servidor IPC externo al equipo local donde este la terminal).
    --           > Dominio de tipo 'exec' asociado a un contenedor distrobox.
    --       > En Windows es      :
    --           > Dominio 'local'.
    --           > Dominio de tipo 'wsl'.
    --   > domain_category        : Define una forma de agrupar el domino al cual puede pertener un ruta 'fullpath' (working directory).
    --       > local              : Si es el dominio local o un dominio de tipo 'unix' (si esta asociado a un servidor IPC ubicado en
    --                              el mismo host que el emulador de terminal).
    --                              Estos dominio siempre usan el mismo filesystem.
    --       > distrobox          : Si es un dominio de tipo 'exec' asociado a un contenedor distrobox.
    --       > wsl                : Si es un dominio de tipo 'wsl'
    --   > tag                    : Solo cuando el source_type es '1'.
    --                              Inicialmente es el nombre del workspace pero puede modificarse.
    local l_workspace_info = {
        name = p_selected_fullpath,
        source_type = 2,
        fullpath = p_selected_fullpath,
        domain = p_selected_domain_info.name,
        domain_category = p_selected_domain_info.domain_category,
        tag_name = nil,
    }

    if not p_is_zoxide_folder then
        l_workspace_info.source_type = 3
    end

    mm_wezterm.GLOBAL.workspace_infos[p_selected_fullpath] = l_workspace_info


    -- Crear el workspace selecionado
    local l_spawncommand = {
	    label = "Workspace: " .. p_selected_fullpath,
        domain = { DomainName = p_selected_domain_info.name },
		cwd = p_selected_fullpath,
	}

	p_window:perform_action(
		mm_wezterm.action.SwitchToWorkspace({
			name = p_selected_fullpath,
			spawn = l_spawncommand,
		}),
		p_pane
	)

    -- Determinar la distribucion externa asociado al dominio
    local l_distribution = nil
    if p_selected_domain_info.domain_category == 'wsl' then
        l_distribution = p_selected_domain_info.data.distribution
    elseif p_selected_domain_info.domain_category == 'distrobox' then
        l_distribution = p_selected_domain_info.ex_data.name
    end

	-- Increment zoxide path score
    mm_ucommon.register_zoxide_folder(p_selected_fullpath, m_os_type, l_distribution)

end



local function m_cbk_process_selected_item(p_window, p_pane, p_item_id, p_item_label)

    --mm_wezterm.log_info(p_item_id)
    if p_item_id == nil or p_item_id == '' then
        return
    end

    -- Obtener el tipo, el dominio y su valor (separado con '|')
    local l_type, l_domain_name, l_value = p_item_id:match("([^|]+)|([^|]+)|(.+)")
    --mm_wezterm.log_info('l_value: ' .. l_value)

    if l_type == nil or l_type == '' or l_value == nil or l_value == '' then
        return
    end


    -- El item seleccionado es un workspace ya creado ('l_value' es nombre del workspace)
    if l_type == '0' then

        -- Cambiar el worskpace del window actual
	    p_window:perform_action(
	    	mm_wezterm.action.SwitchToWorkspace({
	    		name = l_value,
	    	}),
	    	p_pane
	    )

    -- El item seleccionado no es un workspace y requiere ser creado ('l_value', es el tag o la ruta a crear)
    else

        local l_selected_domain_info = mm_udomain.get_domain_info(l_domain_name)
        if l_selected_domain_info == nil then
	    	mm_wezterm.log_error("Invalid selected domain: name = '" .. l_selected_domain_info .. "'.")
            return
        end

        -- Determinar si el dominio actual es WSL
        local l_current_domain_name = p_pane:get_domain_name()

        if l_type == '1' then
            m_create_workspace_of_tag(p_window, p_pane, l_value, l_selected_domain_info, l_current_domain_name)
        elseif l_type == '2' then
            m_create_workspace_of_fullpath(p_window, p_pane, l_value, true, l_selected_domain_info, l_current_domain_name)
        elseif l_type == '3' then
            m_create_workspace_of_fullpath(p_window, p_pane, l_value, false, l_selected_domain_info, l_current_domain_name)
        else
	    	mm_wezterm.log_error("Invalid selected opcion: type = '" .. l_type .. "', value = '" .. l_value  .. "'.")
        end

    end


end



------------------------------------------------------------------------------------
-- Callback usados para los keymappins
------------------------------------------------------------------------------------

function mod.cbk_chose_workspace_with_zoxide(p_window, p_pane)

    local l_current_domain_name = p_pane:get_domain_name()
    local l_current_workspace_name = p_window:active_workspace()

    local l_choices = m_get_choices(l_current_domain_name, l_current_workspace_name, true)

    p_window:perform_action(
    	mm_wezterm.action.InputSelector({
    		action = mm_wezterm.action_callback(m_cbk_process_selected_item),
    		title = "Choose Workspace",
    		description = "Select a workspace and press Enter = accept, Esc = cancel, / = filter",
    		fuzzy_description = "Workspace to switch: ",
    		choices = l_choices,
    		fuzzy = true,
    	}),
    	p_pane
    )

end


function mod.cbk_chose_workspace_with_git(p_window, p_pane)

    local l_current_domain_name = p_pane:get_domain_name()
    local l_current_workspace_name = p_window:active_workspace()

    local l_choices = m_get_choices(l_current_domain_name, l_current_workspace_name, false)

    p_window:perform_action(
    	mm_wezterm.action.InputSelector({
    		action = mm_wezterm.action_callback(m_cbk_process_selected_item),
    		title = "Choose Workspace",
    		description = "Select a workspace and press Enter = accept, Esc = cancel, / = filter",
    		fuzzy_description = "Workspace to switch: ",
    		choices = l_choices,
    		fuzzy = true,
    	}),
    	p_pane
    )

end



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
