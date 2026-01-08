-- Configuración por defecto, editable por el usuario
local mod = {

    -- Patrones de exclusión para 'fd' (se pueden agregar más)
    fd_exclude = { ".git", "node_modules", ".cache" },

    -- Opciones por defecto para 'fzf' (se pueden modificar)
    fzf_options = "--reverse --border --height 50%",

    -- Comando de preview para archivos
    fzf_preview_file = "cat {}",

    -- Comando de preview para directorios
    fzf_preview_dir = "ls -la {}",

    -- Tamaño por defecto del popup (ancho x alto)
    default_size = "80x24",

    -- Comandos externos (asegúrate de que estén en tu PATH)
    commands = {
        fd = "fd",
        fzf = "fzf"
    }
}

return mod
