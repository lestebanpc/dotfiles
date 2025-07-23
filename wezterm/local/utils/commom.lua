local m_wezterm = require("wezterm")

-- Miembros publicos del modulo
local mod = {}

-- Miembros privado del modulo que ser modificado por el usario del modulo
local m_config = {}



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

    m_os_type =  m_get_os_type(m_wezterm.target_triple)
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



------------------------------------------------------------------------------------
-- Obtener el 'custom config'
------------------------------------------------------------------------------------

function mod.get_custom_config()

    -- Obtener las variables a usar al ejecutar el modulo/script de mis configuraciones
    local l_is_ok, l_custom_config = pcall(require, 'custom_config')

    -- Si se cargo con exito
    if l_is_ok then
        return l_custom_config
    end

    -- Si no se pudo cargar, establecer valores por defecto a las variables
    l_custom_config = {

        -- Usar Wayland y solo si es Linux.
        -- Debido a que la version de Wayland esta en rescontruccion por lo se optara por usar X11.
        -- Limitaciones al 2024.07.07:
        --  > No funciona correctamente el sopotte a OSC 52 para manejo del clipboard.
        --  > El estilo de ventanas funciona peor que el de X11.
        -- Si usa Wayland, revise que el compositor 'Xwayland' para X11 este activo: 'ps -fea | grep Xwayland'
        enable_wayland = false,


        -- Built-in scheme: https://wezfurlong.org/wezterm/colorschemes/index.html
        color_scheme = 'Ayu Dark (Gogh)',

        -- Si establece en false la navegacion solo lo puede hacer usando teclas para ingresar al modo copia, busqueda, copia rapida.
        enable_scrollbar = false,

        default_prog = nil,
        font_size = 10.5,
        default_domain = nil,
        ssh_domains = nil,
        launch_menu = nil,
        windows_style = 0,

    }

    print("Module 'custom_config' no load due to not exist ot have a error")
    return l_custom_config

end



------------------------------------------------------------------------------------
-- Obtener la informacion del dominio actual
------------------------------------------------------------------------------------

local m_cache_nonlocal_session = {}

function mod.set_domains_info(p_ssh_domains, p_unix_domains, p_tls_clients, p_wsl_domains)
    m_config.ssh_domains = p_ssh_domains
    m_config.unix_domains = p_unix_domains
    m_config.wsl_domains = p_wsl_domains
    m_config.tls_clients = p_tls_clients
    m_cache_nonlocal_session = nil
end


local function m_get_domain_data_of(p_domain_name, p_domains)

    if p_domains == nil then
        return nil
    end

    -- Encontar la informacion del dominio
    local l_domain = nil
    for i = 1, #p_domains do

        l_domain =  p_domains[i]
        if l_domain.name ~= nil and l_domain.name ~= "" and l_domain.name == p_domain_name then
            return l_domain
        end

    end

    --local l_domain = next(p_domains)
    --while l_domain do
    --   if l_domain.name ~= nil and l_domain.name ~= "" and l_domain.name == p_domain_name then
    --       return l_domain
    --   end
    --   l_domain = next(p_domains)
    --end

    return nil

end


function mod.get_domain_info(p_domain_name)

    local l_domain_info= { domain_type = "unknown", domain_data = nil }

    --1. Si no especifica dominio, considerar desconocido
    if p_domain_name == nil or p_domain_name == "" then
        return l_domain_info
    end

    --2. Si es un dominio local
    if p_domain_name == 'local' then
        l_domain_info.domain_type = 'local'
        return l_domain_info
    end

    --3. Si no es un dominio local

    --3.1 Buscar primero en el cache
    --3.2 Si no es en cache, calcularlo cache

    -- Si su nombre inicia con 'WSL:', es un dominio WSL
    if p_domain_name:match("^WSL:") then

        l_domain_info.domain_type = "wsl"
        l_domain_info.domain_data = m_get_domain_data_of(p_domain_name, m_config.wsl_domains)
        return l_domain_info

    end

    -- Determinar si es dominio TLS
    local l_domain = m_get_domain_data_of(p_domain_name, m_config.tls_clients)
    if l_domain ~= nil then

        l_domain_info.domain_type = "tls"
        l_domain_info.domain_data = l_domain
        return l_domain_info

    end

    -- Determinar si es dominio Socket Unix
    l_domain = m_get_domain_data_of(p_domain_name, m_config.unix_domains)
    if l_domain ~= nil then

        l_domain_info.domain_type = "unix"
        l_domain_info.domain_data = l_domain
        return l_domain_info

    end

    -- Determinar si es dominio SSH
    l_domain = m_get_domain_data_of(p_domain_name, m_config.ssh_domains)
    if l_domain ~= nil then

        l_domain_info.domain_type = "ssh"
        l_domain_info.domain_data = l_domain
        return l_domain_info

    end

    return l_domain_info

end



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
