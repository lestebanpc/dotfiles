local mod = {}


function mod.get_custom_config()

    -- Cargar configuración por defecto
    local config = require("config")

    -- Intentar cargar configuración del usuario (opcional)
    local user_config_path = ya.config_dir() .. "/custom_config.lua"
    local user_config_file = io.open(user_config_path, "r")
    if user_config_file then
        user_config_file:close()
        local user_config = loadfile(user_config_path)
        if user_config then
            local user_config_table = user_config()
            -- Fusionar con configuración por defecto
            for k, v in pairs(user_config_table) do
                config[k] = v
            end
        end
    end

    return config

end


-- Analiza argumentos como --clave=valor o --flag
function mod.parse_args(args)
    local parsed = {}
    for _, arg in ipairs(args) do
        if arg:find("=") then
            local key, value = arg:match("^--([^=]+)=(.*)$")
            if key and value then
                parsed[key] = value
            end
        elseif arg:find("^--") then
            local flag = arg:match("^--(.+)$")
            if flag then
                parsed[flag] = true
            end
        end
    end
    return parsed
end

-- Construye el comando 'fd' basado en opciones y configuración
function mod.build_fd_command(cwd, type_filter, config)
    local cmd = config.commands.fd .. " --hidden --follow"

    -- Filtro por tipo
    if type_filter == "file" then
        cmd = cmd .. " --type f"
    elseif type_filter == "dir" then
        cmd = cmd .. " --type d"
    end

    -- Patrones de exclusión
    for _, pattern in ipairs(config.fd_exclude) do
        cmd = cmd .. " --exclude " .. pattern
    end

    -- Directorio de búsqueda
    cmd = cmd .. " . \"" .. cwd .. "\""

    return cmd
end

-- Construye el comando 'fzf' con preview adecuado
function mod.build_fzf_command(type_filter, size, config)
    local cmd = config.commands.fzf .. " " .. config.fzf_options

    -- Selecciona preview basado en el tipo
    local preview_cmd = config.fzf_preview_file
    if type_filter == "dir" then
        preview_cmd = config.fzf_preview_dir
    end
    cmd = cmd .. " --preview='" .. preview_cmd .. "'"

    -- Tamaño (para popup en tmux o terminal)
    if size then
        local width, height = size:match("(%d+)x(%d+)")
        if width and height then
            cmd = cmd .. " --height=" .. height .. " --width=" .. width
        end
    end

    return cmd
end

return mod
