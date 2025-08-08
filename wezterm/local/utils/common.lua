local mm_wezterm = require("wezterm")

-- Miembros publicos del modulo
local mod = {}


-- Constantes: Iconos y color para los programas
local m_unknown_program_icon = '󰙵'
local m_unknown_program_color = '#565757'

local m_program_infos = {
  ["bash"]       = { icon = '', color = '#41CA4C', },
  ["zsh"]        = { icon = '', color = '#CA40A7', },
  ["fish"]       = { icon = '󰈺', color = '#CA40A7', },
  ["pwsh"]       = { icon = '', color = '#41CA4C', },
  ["powershell"] = { icon = '', color = '#3F40C8', },
  ["cmd"]        = { icon = '', color = '#CA40A7', },
  ["vim"]        = { icon = '', color = '#D3832D', },
  ["nvim"]       = { icon = '', color = '#D3832D', },
}



------------------------------------------------------------------------------------
-- Funciones genericas
------------------------------------------------------------------------------------

-- Obtener el tipo de SO
-- Parametro de entrada
--  > 'p_target_triple' se usa el valor 'wezterm.target_triple' el cual puede tener los siguientes valores
--     > 'x86_64-unknown-linux-gnu'  - Linux
--     > 'x86_64-pc-windows-msvc'    - Windows
--     > 'aarch64-apple-darwin'      - macOS (Apple Silicon)
--     > 'x86_64-apple-darwin'       - macOS (Intel)
-- Parametors de salida> Valor de retorno
--   0 > Si es Linux
--   1 > Si es Windows
--   2 > Si es MacOS (Apple Silicon)
--   3 > Si es MacOS (Intel)
local function m_get_os_type(p_target_triple)

    local l_os_type = 0

    if p_target_triple:find("linux") ~= nil then
        l_os_type = 0
    elseif p_target_triple:find("windows") ~= nil then
        l_os_type = 1
    elseif p_target_triple == "x86_64-apple-darwin" then
        l_os_type = 3
    else
        l_os_type = 2
    end

    return l_os_type

end

-- Cache del tipo del SO
local m_os_type = -1

-- Determinar el tipo de SO
--   0 > Si es Linux
--   1 > Si es Windows
--   2 > Si es MacOS (Apple Silicon)
--   3 > Si es MacOS (Intel)
function mod.get_os_type()

    if m_os_type >= 0 then
        return m_os_type
    end

    m_os_type =  m_get_os_type(mm_wezterm.target_triple)
    return m_os_type

end


-- Función para obtener el basename del una ruta
function mod.get_basename(p_fullpath)

    if p_fullpath == nil or p_fullpath == "" then
        return "unknown"
    end

    -- Limpiar rutas y extensiones
    local name = p_fullpath:match("([^/\\]+)$"):gsub("%.exe$", ""):gsub("%.ELF$", "")
    return name

end

-- Copia todos los pares clave→valor de 'orig' en una nueva tabla
function mod.clone_simple_dicctionary(p_original)

    local l_copy = {}

    for l_key, l_value in pairs(p_original) do
        l_copy[l_key] = l_value
    end

    return l_copy

end


---@param p_array string[]
---@param p_value? string
function mod.exist_in_string_array(p_array, p_value)

    if p_array == nil or p_value == nil or p_value == '' then
        return false
    end

    local l_item = nil
    for i = 1, #p_array do

        l_item = p_array[i]
        if l_item == p_value then
            return true
        end

    end

    return false

end

---@param p_string string
---@return string
function mod.truncate_string(p_string, p_target_length)

    local l_n = 0
    if p_string == nil then
        p_string = ''
    else
        l_n = #p_string
    end

    -- Si la longitud target es invalido
    if p_target_length <= 0 then
        return p_string
    end

    -- Si la longitud target es igual a la cadena
    if l_n == p_target_length then
        return p_string
    end

    -- Si la longitud de la cadena es menor a la longitud target
    if l_n < p_target_length then
        return p_string .. string.rep(" ", p_target_length - l_n)
    end

    -- Si la longitud de la cadena es mayor a la longitud target

    -- Si el tamaño es muy corto que no permite caracteres alrededor de '...', solo truncar
    if l_n < 5 then
        return string.sub(p_string, 1, p_target_length)
    end

    -- Truncamiento con puntos suspensivos

    -- Espacio restante después de "..."
    local l_n_available = p_target_length - 3
    local l_n_start = math.floor(l_n_available / 2)
    local l_n_final = l_n_available - l_n_start

    local l_part1 = string.sub(p_string, 1, l_n_start)
    local l_part2 = string.sub(p_string, -l_n_final + 1)
    return l_part1 .. "..." .. l_part2

end


function mod.wsl_path_to_windows_path(p_wsl_path)

    if p_wsl_path == nil or p_wsl_path == '' then
        return nil
    end

    -- Verificar si es una ruta /mnt (unidades montadas de Windows)
    if not p_wsl_path:match("^/mnt/[a-zA-Z]/") then
        return nil
    end

    -- Extraer componentes de la ruta
    local l_drive_letter = p_wsl_path:sub(6,6):upper()

    -- Elimina "/mnt/X/"
    local l_remaining_path = p_wsl_path:sub(8)

    -- Construir ruta Windows
    local l_win_path = l_drive_letter .. ":\\" .. l_remaining_path:gsub("/", "\\")
    return l_win_path

end


function mod.windows_path_to_wsl_path(p_win_path)

    if p_win_path == nil or p_win_path == '' then
        return nil
    end

    -- Verificar si es una ruta absoluta de Windows (ej: "C:\" o "D:\folder")
    -- > C:\Users\usuario → /mnt/c/Users/usuario
    -- > D:\Proyectos\app → /mnt/d/Proyectos/app
    if p_win_path:match("^%a:[\\/]") then
        -- Extraer letra de unidad y convertir a minúscula
        local l_drive_letter = p_win_path:sub(1,1):lower()

        -- Eliminar la letra de unidad y los dos puntos
        local l_path_without_drive = p_win_path:sub(3)

        -- Reemplazar barras invertidas por barras normales
        local l_unix_style_path = l_path_without_drive:gsub("\\", "/")

        -- Eliminar barras dobles accidentales
        l_unix_style_path = l_unix_style_path:gsub("//+", "/")

        -- Eliminar barra inicial si existe
        l_unix_style_path = l_unix_style_path:gsub("^/", "")

        return "/mnt/" .. l_drive_letter .. "/" .. l_unix_style_path

    end

    -- Para rutas relativas o que ya están en formato Unix
    -- > carpeta\archivo.txt → carpeta/archivo.txt
    return p_win_path:gsub("\\", "/")

end


function mod.is_windows_path(p_fullpath)

    if p_fullpath == nil or p_fullpath ~= '' then
        return false
    end

    -- Es linux o mac
    if p_fullpath:match("^/") then
        return false
    end

    -- Es windows
    --if p_fullpath:match("^%a:[\\/].*") then
    --    return true
    --end

    return true

end


function mod.is_wsl_subfolder_of_windows_disk(p_wsl_path)

    if p_wsl_path == nil or p_wsl_path == '' then
        return nil
    end

    -- Verificar si es una ruta /mnt (unidades montadas de Windows)
    if p_wsl_path:match("^/mnt/[a-zA-Z]/") then
        return true
    end

end


function mod.is_subfolder_of_home_dir(p_folder_path)

    if p_folder_path == nil or p_folder_path == '' then
        return false
    end

    local l_home_dir = mm_wezterm.home_dir

    if p_folder_path == l_home_dir then
        return true
    end

    return p_folder_path:sub(1, #l_home_dir) == l_home_dir

end



------------------------------------------------------------------------------------
-- Funciones obtener informacion de ctes
------------------------------------------------------------------------------------

---@param p_program_name string
---@return string
function mod.get_program_icon(p_program_name)

    -- Si no se define el nombre del programa
    if p_program_name == nil or p_program_name == "" then
        return m_unknown_program_icon
    end

    -- Si se define el programa
    local l_info = m_program_infos[p_program_name]
    if l_info == nil then
        return m_unknown_program_icon
    end

    return l_info.icon

end


---@param p_program_name string
---@return string
function mod.get_program_color(p_program_name)

    -- Si no se define el nombre del programa
    if p_program_name == nil or p_program_name == "" then
        return m_unknown_program_color
    end

    -- Si se define el programa
    local l_info = m_program_infos[p_program_name]
    if l_info == nil then
        return m_unknown_program_color
    end

    return l_info.color

end



------------------------------------------------------------------------------------
-- Funciones que ejecutan comandos externos
------------------------------------------------------------------------------------

-- Obtener el tipo de SO

-- Valida si un comando existe y esta en el PATH del sistema.
---@param p_command_name string
---@param p_os_type integer
---@param p_distribution_name string?
function mod.exist_command(p_command_name, p_os_type, p_distribution_name)

    local l_args = nil

    if p_os_type == 1 then

        if p_distribution_name ~= nil and p_distribution_name ~= '' then
            l_args = {
                'wsl', '-d', p_distribution_name, '--',
                'which', p_command_name,
            }
        else
            l_args = {
                'where', p_command_name,
            }
        end

    elseif p_os_type == 0 then

        if p_distribution_name ~= nil and p_distribution_name ~= '' then
            l_args = {
                'distrobox', 'enter', '-n', p_distribution_name, '--',
                'which', p_command_name,
            }
        else
            l_args = {
                'which', p_command_name,
            }
        end

    else
        l_args = {
            'which', p_command_name,
        }
    end

    ---@type boolean, string?, string?
    local l_success, _, l_stderr = mm_wezterm.run_child_process(l_args)

    if p_is_windows and not l_is_wsl_domain and l_stderr ~= nil then
        return l_success and not l_stderr:find("INFO: Could not find files")
    end

    return l_success

end

-- En windows ejecuta un script CMD. El otros SO ejecuta el script del shell predeterminado
---@param p_script string
---@param p_os_type integer
---@param p_distribution_name string?
---@return string[]?
function mod.run_script(p_script, p_os_type, p_distribution_name)

	local l_args = nil

    if p_os_type == 1 then

        if p_distribution_name ~= nil and p_distribution_name ~= '' then
            l_args = {
                'wsl', '-d', p_distribution_name, '--',
                'sh', '-c', p_script,
            }
        else
            l_args = {
                'cmd', '/c', p_script,
            }
        end

    elseif p_os_type == 0 then

        if p_distribution_name ~= nil and p_distribution_name ~= '' then
            l_args = {
                'distrobox', 'enter', '-n', p_distribution_name, '--',
                'sh', '-c', p_script,
            }
        else
            l_args = {
                'sh', '-c', p_script,
            }
            --l_args = { os.getenv("SHELL"), "-c", p_script }
        end

    else
        l_args = {
            'sh', '-c', p_script,
        }
    end

    ---@type boolean, string?, string?
	local l_success, l_stdout, l_stderr = mm_wezterm.run_child_process(l_args)

	if not l_success then
		mm_wezterm.log_error("Script '" .. p_script .. "' failed with stderr: '" .. l_stderr .. "'")
	end

    local l_lines = mm_wezterm.split_by_newlines(l_stdout)
    if l_lines ~= nil and #l_lines < 1 then
        return nil
    end

    return l_lines

end


function mod.get_home_dir(p_os_type, p_distribution_name)

    if p_distribution_name == nil or p_distribution_name == '' then
        return mm_wezterm.home_dir
    end

    local l_args = nil
    if p_os_type == 1 then

        l_args = {
            'wsl', '-d', p_distribution_name, '--',
            'bash',
            '-c',
            'echo $HOME',
        }

    elseif p_os_type == 0 then

        l_args = {
            'distrobox', 'enter', '-n', p_distribution_name, '--',
            'bash',
            '-c',
            'echo $HOME',
        }

    end

    -- Si no es una Linux ni Windows
    if l_args == nil then
        return mm_wezterm.home_dir
    end

    ---@type boolean, string?, string?
    local l_success, l_stdout, l_stderr = mm_wezterm.run_child_process(l_args)

    if not l_success then
        return nil
    end

    local l_lines = mm_wezterm.split_by_newlines(l_stdout)
    if l_lines ~= nil and #l_lines < 1 then
        return nil
    end

    return l_lines[1]

end



---@return string[]?
function mod.list_running_wsl_distributions()

    local l_args = { "wsl", "--list", "--running", }

    ---@type boolean, string?, string?
	local l_success, l_stdout, l_stderr = mm_wezterm.run_child_process(l_args)

	if not l_success then
		mm_wezterm.log_error("Error on executing 'wsl --list --running': " .. l_stderr)
        return nil
	end

    local l_lines = mm_wezterm.split_by_newlines(l_stdout)

    local l_distributions = {}
    local l_line = nil
    local l_distribution = nil

    for i = 1, #l_lines do

        l_line = l_lines[i]
        l_distribution = l_line --l_line:match('(.-)%s+(.+)')
        if l_distribution ~= nil and l_distribution ~= '' then
            table.insert(l_distributions, l_distribution)
        end

    end

    return l_distributions

end


function mod.get_git_folders(p_options, p_os_type, p_distribution_name)

    local l_options = p_options or {}

    -- Argumentos usados
    local l_path = l_options.path
    local l_include_submodules = l_options.include_submodules or false
    local l_max_depth = l_options.max_depth or 16
    local l_format = l_options.format or "{//}"
    local l_excludes = l_options.excludes or { "node_modules" }
    local l_extra_args = l_options.extra_args or {}

    -- El comando y sus argumentos
    local l_args = nil

    if p_os_type == 1 then

        if p_distribution_name ~= nil and p_distribution_name ~= '' then
            l_args = {
                'wsl', '-d', p_distribution_name, '--',
                "fd",
                "-Hs",
                "^.git$",
                "-td",
                "--max-depth=" .. l_max_depth,
                "--prune",
                "--format",
                l_format,
            }
        else
            l_args = {
                "fd",
                "-Hs",
                "^.git$",
                "-td",
                "--max-depth=" .. l_max_depth,
                "--prune",
                "--format",
                l_format,
            }
        end

    elseif p_os_type == 0 then

        if p_distribution_name ~= nil and p_distribution_name ~= '' then
            l_args = {
                'distrobox', 'enter', '-n', p_distribution_name, '--',
                "fd",
                "-Hs",
                "^.git$",
                "-td",
                "--max-depth=" .. l_max_depth,
                "--prune",
                "--format",
                l_format,
            }
        else
            l_args = {
                "fd",
                "-Hs",
                "^.git$",
                "-td",
                "--max-depth=" .. l_max_depth,
                "--prune",
                "--format",
                l_format,
            }
        end

    else

        l_args = {
            "fd",
            "-Hs",
            "^.git$",
            "-td",
            "--max-depth=" .. l_max_depth,
            "--prune",
            "--format",
            l_format,
        }

    end

    -- Argumento de ...
    if l_include_submodules then
        l_args[#l_args + 1] = "-tf"
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

    -- Adicionar el folder a usar
    if l_path ~= nil or l_path ~= '' then
        table.insert(l_args, l_path)
    end

    -- Argumentos adicionales ¿para que se usaria?
    l_n = #l_extra_args
    for i = 1, l_n do

        l_item = l_extra_args[i]

        if l_item ~= nil or l_item ~= '' then
            table.insert(l_args, l_item)
        end

    end

    -- Ejecutar el comando
    ---@type boolean, string?, string?
	local l_success, l_stdout, l_stderr = mm_wezterm.run_child_process(l_args)

    if not l_success then
        mm_wezterm.log_error("Command failed: ", l_args)
        mm_wezterm.log_error("stderr: ", l_stderr)
        return {}
    end

    if l_stdout == nil or l_stdout == '' then
        mm_wezterm.log_warn("stdout was nil in command: ", l_args)
        return {}
    end

    local l_paths = mm_wezterm.split_by_newlines(l_stdout)

    return l_paths


end


function mod.add_git_folders_to(p_folders, p_options, p_os_type, p_distribution_name)

    if p_folders == nil then
        return  nil
    end

    local l_paths = mod.get_git_folders(p_options, p_os_type, p_distribution_name)
    if l_paths == nil then
        return nil
    end

    local l_path = nil
    for i = 1, #l_paths do
        l_path = l_paths[i]
        table.insert(p_folders, l_path)
    end

    return p_folders

end



function mod.get_zoxide_folders(p_os_type, p_distribution_name)

    local l_args = nil

    if p_os_type == 1 then

        if p_distribution_name ~= nil and p_distribution_name ~= '' then
            l_args = {
                'wsl', '-d', p_distribution_name, '--',
                'zoxide',
                'query',
                '-l',
            }
        else
            l_args = {
                'zoxide',
                'query',
                '-l',
            }
        end

    elseif p_os_type == 0 then

        if p_distribution_name ~= nil and p_distribution_name ~= '' then
            l_args = {
                'distrobox', 'enter', '-n', p_distribution_name, '--',
                'zoxide',
                'query',
                '-l',
            }
        else
            l_args = {
                'zoxide',
                'query',
                '-l',
            }
        end

    else

        l_args = {
            'zoxide',
            'query',
            '-l',
        }

    end

    ---@type boolean, string?, string?
    local l_success, l_stdout, l_stderr = mm_wezterm.run_child_process(l_args)

    if not l_success then
        mm_wezterm.log_error("Failed to run 'zoxide query -l': " .. (l_stderr or "unknown error"))
        return nil
    end

    local l_folders = mm_wezterm.split_by_newlines(l_stdout)
    return l_folders

end



function mod.add_zoxide_folders_to(p_folders, p_os_type, p_distribution_name)

    if p_folders == nil then
        return  nil
    end

    local l_paths = mod.get_zoxide_folders(p_os_type, p_distribution_name)
    if l_paths == nil then
        return nil
    end

    local l_path = nil
    for i = 1, #l_paths do
        l_path = l_paths[i]
        table.insert(p_folders, l_path)
    end

    return p_folders

end



function mod.register_zoxide_folder(p_folder_path, p_os_type, p_distribution_name)

    local l_args = nil

    if p_os_type == 1 then

        if p_distribution_name ~= nil and p_distribution_name ~= '' then
            l_args = {
                'wsl', '-d', p_distribution_name, '--',
                'zoxide',
                'add',
                p_folder_path,
            }
        else
            l_args = {
                'zoxide',
                'add',
                p_folder_path,
            }
        end

    elseif p_os_type == 0 then

        if p_distribution_name ~= nil and p_distribution_name ~= '' then
            l_args = {
                'distrobox', 'enter', '-n', p_distribution_name, '--',
                'zoxide',
                'add',
                p_folder_path,
            }
        else
            l_args = {
                'zoxide',
                'add',
                p_folder_path,
            }
        end

    else

        l_args = {
            'zoxide',
            'add',
            p_folder_path,
        }

    end

    ---@type boolean, string?, string?
    local l_success, _ , l_stderr = mm_wezterm.run_child_process(l_args)

    if not l_success then
        mm_wezterm.log_error("Failed to run 'zoxide query -l': " .. (l_stderr or "unknown error"))
        return false
    end

    return true

end


function mod.list_running_distrobox()

    local l_args = {
        'distrobox-list',
        '--no-color',
    }

    ---@type boolean, string?, string?
    local l_success, l_stdout, l_stderr = mm_wezterm.run_child_process(l_args)

    if not l_success then
        mm_wezterm.log_error("Failed to list distrobox container: " .. (l_stderr or "unknown error"))
        return nil
    end

    local l_lines = mm_wezterm.split_by_newlines(l_stdout)

    -- Ejemplo:
    -- ID           | NAME                 | STATUS             | IMAGE
    -- 684aaa1b6515 | arch1                | Exited (143) 3 months ago | quay.io/toolbx/arch-toolbox:latest
    -- 2cf9ae48130f | opensuse1            | Exited (143) 3 months ago | registry.opensuse.org/opensuse/distrobox:latest
    -- 684bbb1b6515 | arch2                | Up 22 minutes      | quay.io/toolbx/arch-toolbox:latest

    if #l_lines < 2 then
        -- tiene cabeceras
        return nil
    end

    local l_containers = {}
    local l_line = nil
    local l_id, l_name, l_status, l_is_running
    for i = 2, #l_lines do

        l_line = l_lines[i]
        l_id, l_name, l_status = l_line:match('^%s*(.-)%s*|%s*(.-)%s*|%s*(.-)%s*|')
        l_is_running = false
        if l_status ~= nil and l_status ~= '' and l_status:match('^Up') then
            l_is_running = true
        end

        if l_id and l_name and l_is_running then
            table.insert(l_containers, { id = l_id, name = l_name, status = l_is_running })
        end

    end

    return l_containers

end


function mod.get_args_to_enter_distrobox(p_container_name, p_working_dir)

    local l_args = nil

    if p_working_dir ~= nil and p_working_dir ~= '' then

        l_args = {
            'distrobox',
            'enter',
            '-n',
            p_container_name,
            '--',
            'sh',
            '-c',
            'cd ' .. p_working_dir .. ' && exec $SHELL',
        }

    else

        l_args = {
            'distrobox',
            'enter',
            '-n',
            p_container_name,
        }

    end

    --mm_wezterm.log_info(l_args)

    return l_args

end




function mod.list_running_containers(p_container_runtime, p_excluded_ids, p_is_windows, p_wsl_distribution_name)

    local l_is_wsl_domain = p_wsl_distribution_name ~= nil and p_wsl_distribution_name ~= ''

    local l_args = nil
    if p_is_windows then
        if l_is_wsl_domain then
            l_args = {
                "wsl", "-d", p_wsl_distribution_name, "--",
                p_container_runtime,
                'container',
                'ls',
                '--format',
                '{{.ID}}:{{.Names}}',
            }
        else
            l_args = {
                p_container_runtime,
                'container',
                'ls',
                '--format',
                '{{.ID}}:{{.Names}}',
            }
        end
    else
        l_args = {
            p_container_runtime,
            'container',
            'ls',
            '--format',
            '{{.ID}}:{{.Names}}',
        }
    end

    ---@type boolean, string?, string?
    local l_success, l_stdout, l_stderr = mm_wezterm.run_child_process(l_args)

    if not l_success then
        mm_wezterm.log_error("Failed to run '" .. p_container_runtime .. "': " .. (l_stderr or "unknown error"))
        return nil
    end

    local l_lines = mm_wezterm.split_by_newlines(l_stdout)

    local l_containers = {}
    local l_line = nil
    local l_id = nil
    local l_name = nil
    local l_is_excluded = false

    for i = 1, #l_lines do

        l_line = l_lines[i]
        l_id, l_name = l_line:match('(.-):(.+)')

        l_is_excluded = false
        if p_excluded_ids ~= nil then
            l_is_excluded = mod.exist_in_string_array(p_excluded_ids, l_id)
        end

        if l_id and l_name and not l_is_excluded then
            table.insert(l_containers, { id = l_id, name = l_name, })
        end

    end

    return l_containers

end



function mod.get_args_to_enter_container(p_container_runtime, p_container_id, p_container_shell, p_is_windows, p_wsl_distribution_name)

    local l_container_shell = p_container_shell or '/usr/bin/bash'
    local l_is_wsl_domain = p_wsl_distribution_name ~= nil and p_wsl_distribution_name ~= ''

    local l_args = nil

    if p_is_windows then

        if l_is_wsl_domain then
            l_args = {
                "wsl", "-d", p_wsl_distribution_name, "--",
                p_container_runtime,
                'exec',
                '-it',
                p_container_id,
                l_container_shell,
            }
        else
            l_args = {
                'cmd',
                '/c',
                p_container_runtime,
                'exec',
                '-it',
                p_container_id,
                l_container_shell,
            }
        end

    else

        l_args = {
            p_container_runtime,
            'exec',
            '-it',
            p_container_id,
            l_container_shell,
        }

    end



    return l_args

end



function mod.list_pod_of_current_ns(p_is_windows, p_wsl_distribution_name)

    local l_is_wsl_domain = p_wsl_distribution_name ~= nil and p_wsl_distribution_name ~= ''

    local l_args = nil
    if p_is_windows then
        if l_is_wsl_domain then
            l_args = {
                "wsl", "-d", p_wsl_distribution_name, "--",
                'kubectl',
                'get',
                'pods',
                '--no-headers',
                '--output',
                'custom-columns=ID:.metadata.uid,Name:.metadata.name',
            }
        else
            l_args = {
                'kubectl',
                'get',
                'pods',
                '--no-headers',
                '--output',
                'custom-columns=ID:.metadata.uid,Name:.metadata.name',
            }
        end
    else
        l_args = {
            'kubectl',
            'get',
            'pods',
            '--no-headers',
            '--output',
            'custom-columns=ID:.metadata.uid,Name:.metadata.name',
        }
    end

    ---@type boolean, string?, string?
    local l_success, l_stdout, l_stderr = mm_wezterm.run_child_process(l_args)

    if not l_success then
        mm_wezterm.log_error("Failed to run 'kubectl': " .. (l_stderr or "unknown error"))
        return nil
    end

    local l_lines = mm_wezterm.split_by_newlines(l_stdout)

    local l_pods = {}
    local l_line = nil
    for i = 1, #l_lines do

        l_line = l_lines[i]
        local l_id, l_name = l_line:match('(.-)%s+(.+)')
        if l_id and l_name then
            table.insert(l_pods, { id = l_id, name = l_name, })
        end

    end

    return l_pods

end


function mod.get_args_to_enter_pod(p_pod_name, p_container_shell, p_is_windows, p_wsl_distribution_name)

    local l_container_shell = p_container_shell or '/usr/bin/bash'
    local l_is_wsl_domain = p_wsl_distribution_name ~= nil and p_wsl_distribution_name ~= ''

    local l_args = nil

    if p_is_windows then

        if l_is_wsl_domain then
            l_args = {
                "wsl", "-d", p_wsl_distribution_name, "--",
                'kubectl',
                'exec',
                '-it',
                p_pod_name,
                '--',
                l_container_shell,
            }
        else
            l_args = {
                'cmd',
                '/c',
                'kubectl',
                'exec',
                '-it',
                p_pod_name,
                '--',
                l_container_shell,
            }
        end

    else

        l_args = {
            'kubectl',
            'exec',
            '-it',
            p_pod_name,
            '--',
            l_container_shell,
        }

    end

    return l_args


end




------------------------------------------------------------------------------------
-- Obtener el 'custom config'
------------------------------------------------------------------------------------

function mod.get_custom_config()

    -- Obtener las variables a usar al ejecutar el modulo/script de mis configuraciones
    local l_is_ok, l_custom_config = pcall(require, 'custom_config')

    -- Si se cargo con exito
    if l_is_ok then
        return l_custom_config
    else
        mm_wezterm.log_info("Module 'custom_config' no load due to not exist ot have a error:\n" .. l_custom_config)
    end

    -- Si no se pudo cargar, establecer valores por defecto a las variables
    l_custom_config = {

        -- Usar X11 (si usa Wayland debere tener el compositor 'Xwayland')
        enable_wayland = false,

        -- Built-in scheme: https://wezfurlong.org/wezterm/colorschemes/index.html
        color_scheme = 'Ayu Dark (Gogh)',

        -- Si establece en false la navegacion solo lo puede hacer usando teclas para ingresar al modo copia, busqueda, copia rapida.
        enable_scrollbar = false,

        font_size = 10.5,

        launch_menu = nil,
        windows_style = 0,

        ssh_domains = nil,
        unix_domains = nil,
        tls_clients = nil,
        exec_domain_datas = nil,

        filter_config_ssh = {
            '^%.host',
            '^machine/%.host',
        },
        filter_config_ssh_mux = nil,
        external_unix_domains = nil,

        external_running_distribution = nil,
        load_containers = false,

        root_git_folder = nil, --'~/code',
        external_root_git_folder = nil, --'@/code',
        load_local_builtin_tags = true,
        load_external_builtin_tags = true,

        workspace_tags = nil,


        -- Parametros de inicio de Terminal GUI solo si usa 'wezterm start'
        default_prog = nil,
        default_domain = nil,

    }

    return l_custom_config

end





------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
