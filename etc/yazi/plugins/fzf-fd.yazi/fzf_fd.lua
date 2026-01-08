local mm_utils = require("utils")

local mod = {}

function mod.execute_search(self, job, config)

    -- Analizar argumentos
    local args = mm_utils.parse_args(job.args or {})
    local type_filter = args.type or "both"  -- "file", "dir", o "both"
    local use_tmux = args.tmux or false
    local size = args.size or config.default_size

    -- Obtener directorio actual (contexto síncrono)
    local cwd = tostring(cx.active.current.cwd)

    -- Construir comandos
    local fd_cmd = mm_utils.build_fd_command(cwd, type_filter, config)
    local fzf_cmd = mm_utils.build_fzf_command(type_filter, size, config)
    local full_cmd = fd_cmd .. " | " .. fzf_cmd

    -- Para modo tmux
    if use_tmux then
        local width, height = size:match("(%d+)x(%d+)")
        if not width or not height then
            width, height = 80, 24
        end
        full_cmd = string.format(
            "tmux popup -d '%s' -w %s -h %s -E '%s'",
            cwd, width, height, full_cmd
        )
    end

    -- Ejecutar y capturar selección
    ya.sync({
        cmd = "sh",
        args = { "-c", full_cmd },
        cwd = cwd,
        callback = function(output)
            if output and output.stdout and #output.stdout > 0 then
                local selected = output.stdout:gsub("\n$", "")
                mod.handle_selection(selected, cwd)
            end
        end
    })

end

function mod.handle_selection(selected_path, original_cwd)

    if not selected_path or selected_path == "" then
        return  -- El usuario canceló
    end

    -- Determinar si es directorio
    ya.sync({
        cmd = "test",
        args = { "-d", selected_path },
        callback = function(result)

            if result.code == 0 then  -- Es un directorio
                ya.emit("cd", { Url(selected_path) })
                ya.notify({
                    title = "Directorio cambiado",
                    content = "Seleccionado: " .. selected_path
                })
            else  -- Es un archivo
                local dir_padre = selected_path:match("^(.*)/[^/]+$") or "."
                local nombre_archivo = selected_path:match("([^/]+)$")

                -- Navegar al directorio padre
                ya.emit("cd", { Url(dir_padre) })

                -- Buscar y seleccionar el archivo
                ya.emit("find_arrow", { nombre_archivo })

                ya.notify({
                    title = "Archivo seleccionado",
                    content = nombre_archivo
                })
            end

        end
    })

end

return mod
