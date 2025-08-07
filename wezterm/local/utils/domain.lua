local mm_wezterm = require("wezterm")
local mm_ucommon = require("utils.common")

-- Determinar el tipo de SO
--   0 > Si es Linux
--   1 > Si es Windows
--   2 > Si es MacOS (Apple Silicon)
--   3 > Si es MacOS (Intel)
local m_os_type = mm_ucommon.get_os_type()

-- Miembros publicos del modulo
local mod = {}

-- Constantes: Iconos y color para un tipo de 'tab domain'
local m_unknown_domain_type_icon = ''
local m_unknown_domain_type_color = '#565757'

local m_domain_types = {
  ["local"]   =  { icon = '', color = '#3283D5', weight = 0,  },
  ["wsl"]     =  { icon = '', color = '#D3832D', weight = 10, },
  ["serial"]  =  { icon = '󰙜', color = '#41C9C9', weight = 20, },
  ["ssh"]     =  { icon = '󰣀', color = '#C9C941', weight = 50, },
  ["unix"]    =  { icon = '', color = '#DB4B4C', weight = 60, },
  ["tls"]     =  { icon = '󰖟', color = '#217E8C', weight = 70, },
  ["exec"]    =  {
      icon   = '',
      color  = '#41C9C9',
      weight = 40,
      types  = {
          distrobox = { icon = '', color = '#CA40A9', weight = 1, },
          container = { icon = '', color = '#CA40A9', weight = 2, },
          --k8s       = { icon = '󱃾', color = '#41C9C9', weight = 3, },
          custom    = { icon = '', color = '#3283D5', weight = 4, },
      }
  },
  -- Wizard popup usado para que el usuario ingresa parametros requeridos para conectarse a un dominio asociado a 'multiplexer server'
  ["TermWizTerminalDomain"] = { icon = '', color = '#3283D5', weight = 600, },
}

local m_aditional_weight_mux_ssh = 11
local m_color_gray1 = '#787878'
local m_container_runtime = 'podman'

-- Miembros privados del modulo que ser modificado por el usario del modulo
local m_custom = {
    ssh_domains = nil,
    filter_config_ssh = nil,
    filter_config_ssh_mux = nil,

    unix_domains = nil,
    external_unix_domains = nil,

    exec_domain_datas = nil,
    load_containers = false,

    container_shell = 'env bash',

    tls_clients = nil,

    -- El valor usado para selecionar la distribucion externa a usar cuando existe mas de uno que esta ejecutandose.
    -- El valor real es calculado en 2 escenarios:
    --  > Durante el primer inicio del emulador de terminal 'wezterm' y es usado para calcular los dominios 'exec' generados automaticamente.
    --  > Cuando se desea crear o ir a un workspace, donde muestra los 'path' o 'tag' asociados es esta distribucion.
    external_running_distribution = nil,
}

-- Miembros privados
local m_ssh_domains = nil
local m_ssh_infos = nil
local m_wsl_domains = nil

-- Distribucion WSL/Distrobox que esta ejecutandose cuando se inicia Wezterm (usuado para cargar los dominios exec).
local m_external_running_distribution = nil

-- Si esta instalado WSL/Distrobox a nivel local
local m_is_installed_external_distribution = false

local m_unix_domains = nil

local m_exec_domains = nil
local m_exec_infos = nil

local m_tls_clients = nil

-- Cache de la informacion de los dominios (calculada automaticamente cuando se usa 'mod.get_domain_info()').
-- > Tabla tipo diccionario cuyo key es el nombre del dominio
-- > Se valor es un objeto que tiene campos:
--   > name            : Nombre del dominio (mismo valor que el key del diccionario)
--   > type            : Tipo de dominio.
--   > is_multiplexing : El dominio es una vinculacion a un servidor de multiplexacion externo.
--   > is_external     : Si esta asociado a un proceso remoto externo al equipo local donde se ejecuta el emulador de terminal.
--                       Si el dominio es 'local' y es de tipo 'unix' (que no estan en 'external_unix_domains') siempre es false.
--                       Siempre tiene un filesystem diferente al equipo local, por los contenedores son considerados external.
--   > domain_category : Similar a 'type', pero usada para agrupar segun soporte a crear los workspace desde su tag y fullpath.
--   > icon            : Icono usado para el dominio
--   > color           : Color usado para el icono usado para el dominio
--   > weight          : Peso del dominio
--   > data            : Data con la informacion del dominio registrado en wezterm.
--     > Si el domnio es de tipo 'Local' o 'Exec' su valor es 'nil'.
--   > ex_data         : Solo para algunos dominios.
--     > Si es un dominio SSH y se su configuracion se genero del '~/.ssh/config' muestra la informacion del 'host'.
--     > Si es un dominio es de tipo 'Exec' muestra la data relevanta del proceso a ejecutar.
--       > type        : Puede ser 'container' o 'k8s' o 'custom'
--       > icon        : Icono del tipo de 'exec domain'.
--       > color       : Color usado por el icono del tipo de 'exec domain'.
--       > is_external : Si esta asociado a un proceso remoto externo al equipo local donde se ejecuta el emulador de terminal.
--       > Si 'container', se adiciona los siguientes campos:
--         > id        : ID del container
--         > name      : Name del container
--       > Si es 'k8s', se adiciona los siguientes campos:
--         > id        : ID del pod
--         > name      : Name del pod
local m_domain_infos = {}

-- Cache de 'home_dir' de un dominio de categoria external.
-- Es un diccionario donde la 'key' es el nombre del dominio y el 'value' es el 'home_dir'.
local m_domain_home_dirs = {}



------------------------------------------------------------------------------------
-- Setup
------------------------------------------------------------------------------------

local function m_get_external_running_distribution(p_dafult_external_distribution)

    if not m_is_installed_external_distribution then
        return nil
    end

    local l_default_external_distribution = nil
    if p_dafult_external_distribution == nil or p_dafult_external_distribution == '' then
        l_default_external_distribution = m_custom.external_running_distribution
    end

    -- Obtener las distribuciones en ejecucion
    local l_distros = nil

    if m_os_type == 1 then
        l_distros = mm_ucommon.list_running_wsl_distributions()
    else
        l_distros = mm_ucommon.list_running_distrobox()
    end

    --mm_wezterm.log_info(l_distros)
    if l_distros == nil or #l_distros < 1 then
        return nil
    end

    -- Si no se define una distribucion por defecto usar la primero encontrado
    if l_default_external_distribution == nil or l_default_external_distribution == '' then

        if m_os_type == 1 then
            return l_distros[1]
        end

        return l_distros[1].name

    end

    -- Si se define una distribucion por defecto, solo usarlo si esta en ejecucion
    local l_distro = nil

    for i = 1, #l_distros do

        l_distro = l_distros[i]
        if m_os_type == 1 and l_distro == l_default_external_distribution then
            return l_distro
        elseif m_os_type == 0 and l_distro.name == l_default_external_distribution then
            return l_distro.name
        end

    end

    if m_os_type == 1 then
        return l_distros[1]
    end

    return l_distros[1].name

end


function mod.setup(
    p_ssh_domains, p_filter_config_ssh, p_filter_config_ssh_mux,
    p_unix_domains, p_external_unix_domains,
    p_tls_clients,
    p_exec_domain_datas, p_load_containers, p_external_running_distribution)

    -- Establecer los valores
    m_custom.ssh_domains = p_ssh_domains
    m_custom.filter_config_ssh = p_filter_config_ssh
    m_custom.filter_config_ssh_mux = p_filter_config_ssh_mux

    m_custom.unix_domains = p_unix_domains
    m_custom.external_unix_domains = p_external_unix_domains

    m_custom.tls_clients = p_tls_clients

    m_custom.exec_domain_datas = p_exec_domain_datas

    if p_load_containers ~= nil and p_load_containers == true then
        m_custom.load_containers = true
    else
        m_custom.load_containers = false
    end

    m_custom.external_running_distribution = p_external_running_distribution

    -- Validar si esta instalado distribucion Distrobox/WSL
    if m_os_type == 0 then
        m_is_installed_external_distribution = mm_ucommon.exist_command('distrobox', false, nil)
    elseif m_os_type == 1 then
        m_is_installed_external_distribution = mm_ucommon.exist_command('wsl', true, nil)
    end
    --mm_wezterm.log_info(m_is_installed_external_distribution)

    -- Limpiar el cache
    m_domain_infos = {}
    m_domain_home_dirs = {}

    -- Obtener la distribucion en ejecucion por defecto actual (cuando wezterm se esta inicializando)
    m_external_running_distribution = m_get_external_running_distribution(p_external_running_distribution)
    mm_wezterm.log_info("The module 'domain' has been initialized")

end



------------------------------------------------------------------------------------
-- Dominios de tipo SSH
------------------------------------------------------------------------------------


local function m_is_filtered(p_value, p_filter_patterns)

    if p_value == nil or p_value == "" then
        return true
    end

    if p_filter_patterns == nil then
        return false
    end

    -- Realizar el filtro
    local l_filtered = false
    for i = 1, #p_filter_patterns do
        if string.find(p_value, p_filter_patterns[i]) then
            l_filtered = true
            break
        end
    end

    return l_filtered

end


-- > Por cada entrada 'Host' se creara 2 entradas: para iniciar SSH sin usar el mulitplexer server remoto o para usar con este.
-- > Sus campos por defecto son:
--   > name           : Los dominios creados iniciaran con 'SSH:' y 'SSHMUX:'
--   > username       :
--   > remote_address :
--   > multiplexing   : Para lo que inicia con SSHMUX su valor es 'WezTerm'. Los que inician con SSH su valor es 'None'.
--   > ssh_option     : {}
-- > URLs:
--   > https://wezterm.org/config/lua/wezterm/default_ssh_domains.html
function mod.get_ssh_domains()

    -- Si ya fue calculado (cache)
    if m_ssh_domains ~= nil then
        return m_ssh_domains
    end

    -- Obtener dominios del '~/.ssh/config' y recorrelo
    m_ssh_infos = {}
    local l_domains = {}
    local l_domain = nil
    for l_host, l_config in pairs(mm_wezterm.enumerate_ssh_hosts()) do

        -- Se debe filtrar el host del '~/.ssh/config'
        local l_filtered = m_is_filtered(l_host, m_custom.filter_config_ssh)

        -- Si no se filtra adicionar como dominio
        if not l_filtered then

            -- Crear el domnio SSH
            l_domain = {
                name = 'ssh:' .. l_host,
                remote_address = l_host,
                multiplexing = 'None',
                assume_shell = 'Posix',
            }

            m_ssh_infos[l_host] = l_config

            table.insert(l_domains, l_domain)

            -- Validar si se filtra para considerador una referencia a multiplexer externo.
            l_filtered = m_is_filtered(l_host, m_custom.filter_config_ssh_mux)

            -- Si no se filtra adicionar como dominio
            if not l_filtered then

                l_domain = mm_ucommon.clone_simple_dicctionary(l_domain)
                l_domain.name = 'ssh:mux:' .. l_host
                l_domain.multiplexing = 'WezTerm'

                table.insert(l_domains, l_domain)

            end

        end

    end

    -- Adicionar los dominios adicionados por el usuario
    if m_custom.ssh_domains == nil then
        m_ssh_domains = l_domains
        return m_ssh_domains
    end


    for i = 1, #m_custom.ssh_domains do

        l_domain =  m_custom.ssh_domains[i]
        table.insert(l_domains, l_domain)

    end

    m_ssh_domains = l_domains
    return m_ssh_domains

end



------------------------------------------------------------------------------------
-- Dominios de tipo WSL
------------------------------------------------------------------------------------

function mod.get_wsl_domains()

    -- Si no es windows y no esta instalado WSL
    if m_os_type ~= 1 or not m_is_installed_external_distribution then
        return nil
    end

    -- Si ya fue calculado (cache)
    if m_wsl_domains ~= nil then
        return m_wsl_domains
    end


    -- Obtener los dominios WSL
    local l_domains = mm_wezterm.default_wsl_domains()

    if l_domains == nil or #l_domains <= 0 then
        m_wsl_domains = {}
        return m_wsl_domains
    end

    -- Obtener datos de ese dominio por defecto
    m_wsl_domains = l_domains
    return m_wsl_domains

end


--function mod.get_distribution_of_wsl_domain(p_domain_name)
--
--    if m_os_type ~= 1 then
--        return nil
--    end
--
--    -- Determinar si el dominio actual es WSL
--    local l_domain_info = mod.get_domain_info(p_domain_name)
--    if l_domain_info == nil or l_domain_info.type == nil or l_domain_info.type ~= 'wsl' then
--        return nil
--    end
--
--    -- Enviar la distribucion
--    return l_domain_info.data.distribution
--
--end


function mod.get_wsl_running_domain()

    -- Si no es windows y no esta instalado WSL
    if m_os_type ~= 1 or not m_is_installed_external_distribution then
        return nil
    end

    if m_wsl_domains == nil then
        return nil
    end

    -- Obtener la distribucion WSL por defecto y en ejecucion
    local l_wsl_distribution = m_get_external_running_distribution()
    if l_wsl_distribution == nil or l_wsl_distribution == '' then
        return nil
    end

    -- Obtener el nombre del dominio asociado a la distribucion Linux
    local l_item = nil
    local l_domain_name = nil

    for i = 1, #m_wsl_domains do
        l_item = m_wsl_domains[i]
        if l_wsl_distribution == l_item.distribution then
            l_domain_name = l_item.name
        end
    end

    if l_domain_name == nil then
        return nil
    end


    -- Determinar si el dominio actual es WSL
    local l_domain_info = mod.get_domain_info(l_domain_name)
    if l_domain_info == nil or l_domain_info.type == nil or l_domain_info.type ~= 'wsl' then
        return nil
    end

    -- Enviar la distribucion
    return l_domain_info

end



------------------------------------------------------------------------------------
-- Dominios de tipo Unix (Socket IPC)
------------------------------------------------------------------------------------

function mod.get_unix_domains()

    -- Si ya fue calculado (cache)
    if m_unix_domains ~= nil then
        return m_unix_domains
    end


    -- Adicionar el dominio 'built-in' a usar por defecto
    local l_type_info = m_domain_types['unix']
    local l_domains = {}
    local l_domain = nil

    local l_domain_info = nil
    if m_domain_infos == nil then
        m_domain_infos = {}
    end

    if m_os_type ~= 1 then

        -- Crea automaticamente crea el socket llamado 'unix' (no cambiar el nombre)
        -- Por defecto crea un socket IPC '/run/user/1000/wezterm/sock' cuyo dominio es 'unix'
        l_domain = {
            name = 'unix',
        }

        table.insert(l_domains, l_domain)

        l_domain_info =  {
            type = "unix", name = l_domain.name, data = l_domain,
            is_multiplexing = true,
            icon = l_type_info.icon, color = l_type_info.color, weight = l_type_info.weight,
            is_external = false, domain_category = 'local',
        }
        m_domain_infos[l_domain.name] = l_domain_info

    else

        -- Por cada distribucion Linux, registrar un socket ipc asociado a dicha distribucion WSL
        if m_wsl_domains ~= nil then

            local l_item = nil

            for i = 1, #m_wsl_domains do

                l_item = m_wsl_domains[i]

                if l_item.distribution ~= nil and l_item.distribution ~= "" then

                    -- Si no existe el socket escribir un warning
                    l_domain = {
                        name = 'unix:' .. l_item.distribution,
                        socket_path = '/mnt/c/Users/' .. os.getenv("USERNAME") .. '/.local/share/wezterm/' .. l_item.distribution .. '.sock',

                        serve_command = { 'wsl', '--name', l_item.distribution , 'wezterm-mux-server', '--daemonize' },

                        -- NTFS permissions will always be "wrong", so skip that check
                        --skip_permissions_check = true,
                    }

                    table.insert(l_domains, l_domain)

                    l_domain_info =  {
                        type = "unix", name = l_domain.name, data = l_domain,
                        is_multiplexing = true,
                        icon = l_type_info.icon, color = l_type_info.color, weight = l_type_info.weight,
                        is_external = true, domain_category = nil,
                    }
                    m_domain_infos[l_domain.name] = l_domain_info

                end

            end
        end

    end

    -- Adicionar los dominios adicionados por el usuario
    if m_custom.unix_domains == nil then

        m_unix_domains = l_domains
        return m_unix_domains

    end

    for i = 1, #m_custom.unix_domains do

        l_domain = m_custom.unix_domains[i]
        table.insert(l_domains, l_domain)

    end

    m_unix_domains = l_domains
    return m_unix_domains


end



------------------------------------------------------------------------------------
-- Dominios de tipo TLS
------------------------------------------------------------------------------------

function mod.get_tls_clients()

    -- Si ya fue calculado (cache)
    if m_tls_clients ~= nil then
        return m_tls_clients
    end

    -- Adicionar los dominios adicionados por el usuario
    if m_custom.tls_clients == nil then

        m_tls_clients = {}
        return m_tls_clients

    end

     m_tls_clients = m_custom.tls_clients
     return m_tls_clients

end


------------------------------------------------------------------------------------
-- Dominios de tipo Exec > Distrobox
------------------------------------------------------------------------------------

local function m_cbk_distrobox_label(p_domain_name)

    --local l_info = mod.get_domain_info(p_domain_name)
    return p_domain_name

end



local function m_make_cbk_distrobox_fixup(p_container_name)

    return function(p_spawncommand)

        p_spawncommand.args = mm_ucommon.get_args_to_enter_distrobox(p_container_name)
        return p_spawncommand

    end

end



------------------------------------------------------------------------------------
-- Dominios de tipo Exec > Contenedores
------------------------------------------------------------------------------------

local function m_cbk_container_label(p_domain_name)

    --local l_info = mod.get_domain_info(p_domain_name)
    return p_domain_name

end



local function m_make_cbk_container_fixup(p_container_id)

    return function(p_spawncommand)

        p_spawncommand.args = mm_ucommon.get_args_to_enter_container(m_container_runtime, p_container_id, m_custom.container_shell, m_os_type == 1, m_external_running_distribution)
        return p_spawncommand

    end

end



------------------------------------------------------------------------------------
-- Dominios de tipo Exec
------------------------------------------------------------------------------------

function mod.get_exec_domains()

    -- Si ya fue calculado (cache)
    if m_exec_domains ~= nil then
        return m_exec_domains
    end


    m_exec_infos = {}
    local l_domains = {}
    local l_type_info = m_domain_types['exec']
    local l_subtype_info = nil

    -- Obtener los dominios de asociados a los contenedores distrobox
    local l_excluded_container_ids = nil
    local l_item = nil
    local l_domain_name = nil

    if m_os_type == 0 and  m_is_installed_external_distribution then

        l_subtype_info = l_type_info.types['distrobox']
        local l_containers = mm_ucommon.list_running_distrobox()

        if l_containers ~= nil then

            l_excluded_container_ids = {}

            for i = 1, #l_containers do

                l_item = l_containers[i]
                l_domain_name = 'distrobox:' .. l_item.name

                table.insert(l_domains,
                    mm_wezterm.exec_domain(
                        l_domain_name,
                        m_make_cbk_distrobox_fixup(l_item.name),
                        m_cbk_distrobox_label
                    )
                )

                m_exec_infos[l_domain_name] = {
                    type = 'distrobox',
                    icon = l_subtype_info.icon,
                    color = l_subtype_info.color,
                    is_external = true,
                    id = l_item.id,
                    name = l_item.name,
                }

                table.insert(l_excluded_container_ids, l_item.id)

            end

        end

    end

    -- Obtener los dominios de asociados a los contenedores en ejecucion
    local l_is_windows = m_os_type == 1

    if m_custom.load_containers and mm_ucommon.exist_command(m_container_runtime, l_is_windows, m_external_running_distribution) then

        l_subtype_info = l_type_info.types['container']
        local l_containers = mm_ucommon.list_running_containers(m_container_runtime, l_excluded_container_ids, l_is_windows, m_external_running_distribution)

        if l_containers ~= nil then

            for i = 1, #l_containers do

                l_item = l_containers[i]
                l_domain_name = m_container_runtime .. ':' .. l_item.name

                table.insert(l_domains,
                    mm_wezterm.exec_domain(
                        l_domain_name,
                        m_make_cbk_container_fixup(l_item.id),
                        m_cbk_container_label
                    )
                )

                m_exec_infos[l_domain_name] = {
                    type = 'container',
                    icon = l_subtype_info.icon,
                    color = l_subtype_info.color,
                    -- si es de una instancia WSL colocar false
                    is_external = true,
                    id = l_item.id,
                    name = l_item.name,
                }

            end

        end

    end



    -- Adicionar los dominios adicionados por el usuario
    if m_custom.exec_domain_datas == nil then

        m_exec_domains = l_domains
        return m_exec_domains

    end

    local l_domain = nil
    local l_info = nil

    l_subtype_info = l_type_info.types['custom']
    for i = 1, #m_custom.exec_domain_datas do

        l_item =  m_custom.exec_domain_datas[i]
        if l_item.name and l_item.callback_fixup then

            l_domain = mm_wezterm.exec_domain(l_item.name, l_item.callback_fixup, l_item.callback_label)
            table.insert(l_domains, l_domain)

            l_info = {
                type = 'custom',
                icon = l_subtype_info.icon,
                color = l_subtype_info.color,
                is_external = l_item.is_external ~= nil and l_item.is_external == true,
            }

            -- TODO: Adicionar los campos definios en l_item.data a l_info
            m_exec_infos[l_item.name] = l_info


        end

    end

    m_exec_domains = l_domains
    return m_exec_domains

end


function mod.get_distrobox_running_domain()

    -- Si no es Linux y no esta instalado distrobox
    if m_os_type ~= 0 or not m_is_installed_external_distribution then
        return nil
    end

    if m_exec_infos == nil then
        return nil
    end

    -- Obtener la distribucion distrobox en ejecucuib y por defecto
    local l_distrobox_distribution = m_get_external_running_distribution(nil)
    if l_distrobox_distribution == nil or l_distrobox_distribution == '' then
        return nil
    end


    -- Obtener el nombre del dominio asociado a la distribucion distrobox
    local l_domain_name = nil

    for l_key, l_item in pairs(m_exec_infos) do
        l_item = m_exec_infos[l_key]
        if l_item.type == 'distrobox' and l_item.name == l_distrobox_distribution then
            l_domain_name = l_key
        end
    end

    if l_domain_name == nil then
        return nil
    end


    -- Determinar si el dominio actual es WSL
    local l_domain_info = mod.get_domain_info(l_domain_name)
    if l_domain_info == nil or l_domain_info.type == nil or l_domain_info.type ~= 'exec' then
        return nil
    end

    -- Enviar la distribucion
    return l_domain_info

end



------------------------------------------------------------------------------------
-- Obtener la informacion del dominio actual
------------------------------------------------------------------------------------

local function m_get_domain_info_of(p_domain_name, p_domains)

    if p_domains == nil or #p_domains < 1 then
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

    --1. Si no especifica dominio, considerar desconocido
    if p_domain_name == nil or p_domain_name == "" then
        return  {
            type = "unknown", name = p_domain_name, data = nil, is_multiplexing = false,
            icon = m_unknown_domain_type_icon, color = m_unknown_domain_type_color,
            weight = 999,
            is_external = true,
            domain_category = nil,
        }
    end

    --2. Si es un dominio local
    local l_type_info = nil
    if p_domain_name == 'local' then

        l_type_info = m_domain_types['local']
        return  {
            type = "local", name = p_domain_name, data = nil, is_multiplexing = false,
            icon = l_type_info.icon, color = l_type_info.color,
            weight = l_type_info.weight,
            is_external = false,
            domain_category = 'local',
        }

    end

    --3. Si es el wizard popup usado para que el usuario ingresa parametros requeridos para conectarse a un dominio asociado a 'multiplexer server'
    if p_domain_name == 'TermWizTerminalDomain' then

        l_type_info = m_domain_types['TermWizTerminalDomain']
        return  {
            type = "TermWizTerminalDomain", name = p_domain_name, data = nil, is_multiplexing = false,
            icon = l_type_info.icon, color = l_type_info.color,
            weight = l_type_info.weight,
            is_external = false,
            domain_category = nil,
        }

    end

    --4. Si no es un dominio local, buscar en el cache
    local l_domain_info = m_domain_infos[p_domain_name]
    if l_domain_info ~= nil then
        return l_domain_info
    end


    --5. Si no es un dominio local y no esta en el cache, buscarlo
    l_domain_info= {
        type = "unknown", name = p_domain_name, data = nil, is_multiplexing = false,
        icon = m_unknown_domain_type_icon, color = m_unknown_domain_type_color,
        weight = 998,
        is_external = true,
        domain_category = nil,
    }

    -- Si su nombre inicia con 'WSL:', es un dominio WSL
    local l_domain = nil
    if p_domain_name:match("^WSL:") then

        l_domain = m_get_domain_info_of(p_domain_name, m_wsl_domains)
        if l_domain ~= nil then

            l_type_info = m_domain_types['wsl']

            l_domain_info.type = "wsl"
            l_domain_info.is_multiplexing = false
            l_domain_info.icon = l_type_info.icon
            l_domain_info.color = l_type_info.color
            l_domain_info.weight = l_type_info.weight
            l_domain_info.data = l_domain
            l_domain_info.is_external = true
            l_domain_info.domain_category = 'wsl'

            m_domain_infos[p_domain_name] = l_domain_info
            return l_domain_info

        end

        return l_domain_info

    end

    -- Determinar si es dominio Socket Unix
    --mm_wezterm.log_info("get_domain_info: " .. p_domain_name)
    l_domain = m_get_domain_info_of(p_domain_name, m_unix_domains)
    if l_domain ~= nil then

        l_type_info = m_domain_types['unix']

        l_domain_info.type = "unix"
        l_domain_info.is_multiplexing = true
        l_domain_info.icon = l_type_info.icon
        l_domain_info.color = l_type_info.color
        l_domain_info.weight = l_type_info.weight
        l_domain_info.data = l_domain
        l_domain_info.is_external = false
        if m_custom.external_unix_domains ~= nil then

            l_domain_info.is_external = mm_ucommon.exist_in_string_array(m_custom.external_unix_domains, p_domain_name)
            if not l_domain_info.is_external then
                l_domain_info.domain_category = 'local'
            end

        end

        m_domain_infos[p_domain_name] = l_domain_info
        return l_domain_info

    end

    -- Determinar si es dominio TLS
    l_domain = m_get_domain_info_of(p_domain_name, m_tls_clients)
    if l_domain ~= nil then

        l_type_info = m_domain_types['tls']

        l_domain_info.type = "tls"
        l_domain_info.is_multiplexing = true
        l_domain_info.icon = l_type_info.icon
        l_domain_info.color = l_type_info.color
        l_domain_info.weight = l_type_info.weight
        l_domain_info.data = l_domain
        l_domain_info.is_external = true
        l_domain_info.domain_category = nil

        m_domain_infos[p_domain_name] = l_domain_info
        return l_domain_info

    end

    -- Determinar si es dominio SSH
    l_domain = m_get_domain_info_of(p_domain_name, m_ssh_domains)
    if l_domain ~= nil then

        l_type_info = m_domain_types['ssh']

        l_domain_info.type = "ssh"

        if l_domain.multiplexing ~= nil and l_domain.multiplexing == 'WezTerm' then
            l_domain_info.is_multiplexing = true
            l_domain_info.weight = l_type_info.weight + m_aditional_weight_mux_ssh
        else
            l_domain_info.is_multiplexing = false
            l_domain_info.weight = l_type_info.weight
        end

        if l_domain.remote_address ~= nil and l_domain.remote_address ~= "" and m_ssh_infos ~= nil then
            l_domain_info.ex_data = m_ssh_infos[l_domain.remote_address]
        end

        l_domain_info.icon = l_type_info.icon
        l_domain_info.color = l_type_info.color
        l_domain_info.data = l_domain
        l_domain_info.is_external = true
        l_domain_info.domain_category = nil

        m_domain_infos[p_domain_name] = l_domain_info
        return l_domain_info

    end

    -- Determinar si es un dominio 'Exec'
    if m_exec_infos ~= nil then

        l_domain = m_exec_infos[p_domain_name]
        if l_domain ~= nil then

            l_type_info = m_domain_types['exec']
            local l_subtype_info = l_type_info.types[l_domain.type]

            l_domain_info.type = "exec"
            l_domain_info.icon = l_type_info.icon
            l_domain_info.color = l_type_info.color
            l_domain_info.is_multiplexing = false
            l_domain_info.data = nil
            l_domain_info.weight = l_type_info.weight + l_subtype_info.weight
            l_domain_info.ex_data = l_domain
            l_domain_info.is_external = l_subtype_info.is_external
            l_domain_info.domain_category = nil
            if l_domain.type == 'distrobox' then
                l_domain_info.domain_category = 'distrobox'
            end

            m_domain_infos[p_domain_name] = l_domain_info
            return l_domain_info

        end

    end

    return l_domain_info

end


function mod.get_home_directory_of_domain1(p_domain_info)

    -- Si esta en el cache, devolverlo
    local l_home_dir = m_domain_home_dirs[p_domain_info.name]
    if l_home_dir ~= nil then
        return l_home_dir
    end

    -- Si NO esta en el cache, obtenerlo
    if p_domain_info.domain_category == 'local' then
        l_home_dir = mm_wezterm.home_dir
        return l_home_dir
    end

    local l_distribution = nil
    if p_domain_info.domain_category == 'wsl' then
        l_distribution = p_domain_info.data.distribution
    elseif p_domain_info.domain_category == 'distrobox' then
        l_distribution = p_domain_info.ex_data.name
    else
        return nil
    end

    -- 4. Obtener el 'home dir' asociado al dominio
    l_home_dir = mm_ucommon.get_home_dir(m_os_type, l_distribution)
    m_domain_home_dirs[p_domain_info.name] = l_home_dir

    return l_home_dir

end


function mod.get_home_directory_of_domain2(p_domain_name)

    local l_domain_info = mod.get_domain_info(p_domain_name)
    if l_domain_info == nil then
        return nil
    end

    return mod.get_home_directory_of_domain1(l_domain_info)

end



------------------------------------------------------------------------------------
-- Domain selector> Fuente para mostrar las opciones de seleccion
------------------------------------------------------------------------------------

-- Parametros:
-- > p_filter_type
--   Un entero que representa el tipo de filtro y sus valores son:
--   > 1
local function m_get_all_domains()

    -- Obtener los objetos 'MuxDomain'
    local l_mux_domains = mm_wezterm.mux.all_domains()
    if l_mux_domains == nil then
        return nil
    end

    -- Obtener la informacion basico del dominio
    local l_item = nil
    local l_domains = {}
    local l_domain = nil
    local l_domain_name = nil

    for i = 1, #l_mux_domains do

        l_item = l_mux_domains[i]
        l_domain_name = l_item:name()

        -- Excluir el wizard popup usado para que el usuario ingresa parametros requeridos para conectarse
        -- a un dominio asociado a 'multiplexer server'
        if l_domain_name ~= "TermWizTerminalDomain" then

            l_domain = {
                name = l_domain_name,
                is_attached = l_item:state() == 'Attached',
                info = mod.get_domain_info(l_domain_name),
            }

            table.insert(l_domains, l_domain)

        end

    end

    -- Ordenar el arreglo segun el peso
    table.sort(l_domains, function(p_item1, p_item2)

        -- Los nulos enviarlos al final
        if p_item1.info == nil or p_item2.info == nil then
            return false
        end

        if p_item1.info.weight ~= p_item2.info.weight then
            -- Los de mayor peso mandarlos al final
            return p_item1.info.weight < p_item2.info.weight
        end

        -- Si tiene el miso peso, ordenarlos alfabeticamente
        return p_item1.name < p_item2.name

    end)

    -- Devolver
    return l_domains

end



------------------------------------------------------------------------------------
-- Domain selector> Mostrar informacion del source en el popup
------------------------------------------------------------------------------------

local function m_get_domain_details(p_domain_info)

    if p_domain_info == nil or p_domain_info.type == nil then
        return {}, m_unknown_domain_type_icon, m_unknown_domain_type_color
    end

    local l_infos = {}
    local l_icon = p_domain_info.icon
    local l_color =p_domain_info.color

    -- Si es un dominio no tiene data adicional
    if p_domain_info.type == 'unknown' or p_domain_info.type == 'local' then
        return l_infos, l_icon, l_color
    end

    -- Si el dominio es un exec domain
    local l_key = nil
    local l_value = nil
    if p_domain_info.type == "exec" then

        if p_domain_info.ex_data ~= nil then

            if p_domain_info.ex_data.type == 'distrobox' then

                l_key = 'Id'
                l_value = p_domain_info.ex_data.id
                if l_value ~= nil and l_value ~= '' then
                    table.insert(l_infos, { key = l_key , value = l_value, })
                end

                l_key = 'Name'
                l_value = p_domain_info.ex_data.name
                if l_value ~= nil and l_value ~= '' then
                    table.insert(l_infos, { key = l_key , value = l_value, })
                end

                l_icon = p_domain_info.ex_data.icon
                l_color = p_domain_info.ex_data.color

            elseif p_domain_info.ex_data.type == 'container' then

                l_key = 'Id'
                l_value = p_domain_info.ex_data.id
                if l_value ~= nil and l_value ~= '' then
                    table.insert(l_infos, { key = l_key , value = l_value, })
                end

                l_key = 'Name'
                l_value = p_domain_info.ex_data.name
                if l_value ~= nil and l_value ~= '' then
                    table.insert(l_infos, { key = l_key , value = l_value, })
                end

                l_icon = p_domain_info.ex_data.icon
                l_color = p_domain_info.ex_data.color

            end

        end

        return l_infos, l_icon, l_color

    end

    if p_domain_info.data == nil then
        return l_infos, l_icon, l_color
    end

    -- Si es un dominio SSH
    if p_domain_info.type == "ssh" then

        local l_username = nil
        local l_server = nil
        if p_domain_info.ex_data ~= nil then
            l_username = p_domain_info.ex_data.user
            l_server = p_domain_info.ex_data.hostname
        else
            l_username = p_domain_info.data.username
        end

        local l_alias = p_domain_info.data.remote_address
        if l_alias == l_server then
            l_alias = nil
        end

        l_key = 'Server'
        l_value = l_server
        if l_value ~= nil and l_value ~= '' then
            table.insert(l_infos, { key = l_key , value = l_value, })
        end

        l_key = 'User'
        l_value = l_username
        if l_value ~= nil and l_value ~= '' then
            table.insert(l_infos, { key = l_key , value = l_value, })
        end

        l_key = 'Alias'
        l_value = l_alias
        if l_value ~= nil and l_value ~= '' then
            table.insert(l_infos, { key = l_key , value = l_value, })
        end

        return l_infos, l_icon, l_color

    end

    -- Si es un dominio Socket IPC
    if p_domain_info.type == "unix" then

        l_key = 'Alias'
        l_value = p_domain_info.data.socket_path
        if l_value ~= nil and l_value ~= '' then
            table.insert(l_infos, { key = l_key , value = l_value, })
        end

        return l_infos, l_icon, l_color

    end


    -- Si es un dominio TLS
    if p_domain_info.type == "tls" then

        l_key = 'Server'
        l_value = p_domain_info.data.remote_address
        if l_value ~= nil and l_value ~= '' then
            table.insert(l_infos, { key = l_key , value = l_value, })
        end

        l_key = 'Via SSH'
        l_value = p_domain_info.data.bootstrap_via_ssh
        if l_value ~= nil and l_value ~= '' then
            table.insert(l_infos, { key = l_key , value = l_value, })
        end

        return l_infos, l_icon, l_color

    end


    -- Si es un dominio WSL
    if p_domain_info.type == "wsl" then


        l_key = 'Distribution'
        l_value = p_domain_info.data.distribution
        if l_value ~= nil and l_value ~= '' then
            table.insert(l_infos, { key = l_key , value = l_value, })
        end

        l_key = 'User'
        l_value = p_domain_info.data.user
        if l_value ~= nil and l_value ~= '' then
            table.insert(l_infos, { key = l_key , value = l_value, })
        end

        return l_infos, l_icon, l_color

    end

    return l_infos, l_icon, l_color

end



local function m_get_choice_label(p_domain_data, p_current_domain_name)

    local l_domain_info = p_domain_data.info

    -- New tab of domain
    -- New tab on server
    -- Attach tabs of server
    local l_action = 'New tab     on domain '
    if l_domain_info.is_multiplexing then
        if p_domain_data.is_attached then
            l_action = 'New tab     on server '
        else
            l_action = 'Attach tabs of server '
        end
    end

    local l_aditional_infos, l_icon, l_color = m_get_domain_details(l_domain_info)

    local l_fix_domain_type = mm_ucommon.truncate_string(l_domain_info.type, 8)

    -- Construir el label con la data obtenida
    local l_format_items = {
        { Text = l_action },
        { Foreground = { Color =  m_color_gray1 } },
        { Text = l_fix_domain_type },
        --'ResetAttributes',
    }

    local l_fix_domain_name = mm_ucommon.truncate_string(p_domain_data.name, 25)
    table.insert(l_format_items, { Foreground = { Color =  l_color } } )
    table.insert(l_format_items, { Text = ' ' ..l_icon .. ' ' ..  l_fix_domain_name .. '  ' })
    --table.insert(l_format_items, 'ResetAttributes')

    if l_aditional_infos ~= nil and #l_aditional_infos > 0 then


        --table.insert(l_format_items, { Text = '   ' })
        table.insert(l_format_items, { Foreground = { Color =  m_color_gray1 } } )

        local l_item = nil
        for i = 1, #l_aditional_infos do

            l_item = l_aditional_infos[i]
            if l_item ~= nil and l_item.value ~= nil and l_item.value ~= '' then
                if i == 1 then
                    table.insert(l_format_items, { Text = l_item.key .. ": '" .. l_item.value .. "'" })
                else
                    table.insert(l_format_items, { Text = ', ' .. l_item.key .. ": '" .. l_item.value .. "'" })
                end
            end

        end

        table.insert(l_format_items, 'ResetAttributes')

    end

    return mm_wezterm.format(l_format_items)

end



------------------------------------------------------------------------------------
-- Domain selector> Listar los elementos a elegir
------------------------------------------------------------------------------------

local function m_get_choices(p_current_domain_name, p_current_workspace_name)

    -- Obtener los objetos 'MuxDomain'
    local l_domains = m_get_all_domains()
    if l_domains == nil then
        return {}
    end

    -- Obtener
    local l_domain = nil
    local l_choices = {}

    for i = 1, #l_domains do

        l_domain = l_domains[i]

        table.insert(l_choices, {
            id = l_domain.name,
            label = m_get_choice_label(l_domain, p_current_domain_name),
        })

        --if p_current_domain_name == l_domain.name then
        --    table.insert(l_choices, {
        --        id = l_domain.name,
        --        label = m_get_choice_label(l_domain, p_current_domain_name),
        --    })
        --else
        --    table.insert(l_choices, 1, {
        --        id = l_domain.name,
        --        label = m_get_choice_label(l_domain, p_current_domain_name),
        --    })
        --end

    end

    return l_choices

end



------------------------------------------------------------------------------------
-- Domain selector> Logica cuando la opcion fue seleccionado
------------------------------------------------------------------------------------

local function m_cbk_process_selected_item(p_window, p_pane, p_item_id, p_item_label)

    if p_item_id == nil or p_item_id == '' then
        return
    end

    local l_selected_domain_name = p_item_id
    --mm_wezterm.log_info('Selected domain "' .. l_selected_domain_name .. '"')

    local l_mux_domain = mm_wezterm.mux.get_domain(l_selected_domain_name)
    if l_mux_domain == nil then
        mm_wezterm.log_info('not found MuxDomain "' .. l_selected_domain_name .. '"')
        return
    end

    local l_is_attached = l_mux_domain:state() == 'Attached'

    local l_selected_domain_info = mod.get_domain_info(l_selected_domain_name)
    if l_selected_domain_info == nil then
        mm_wezterm.log_info('not found info of domain "' .. l_selected_domain_name .. '"')
        return
    end


    if l_selected_domain_info.is_multiplexing and not l_is_attached then

        p_window:perform_action(
            mm_wezterm.action.AttachDomain(l_selected_domain_name),
            p_pane
        )

    else

        --local l_current_domain_name = p_pane:get_domain_name()
        --local l_current_workspace_name = p_window:active_workspace()
        --mm_wezterm.log_info('Curren domain "' .. l_current_domain_name .. '", Selected domain "' .. l_selected_domain_name .. '"')

        local l_fullpath = nil
        --local lm_uworkspace = require('utils.workspace')
        --local l_fullpath = lm_uworkspace.get_equivalent_fullpath(l_current_workspace_name, l_domain_info)
        local l_spawncommand = {
            domain = { DomainName = l_selected_domain_name },
        }

        if l_fullpath ~= nil and l_fullpath ~= '' then
            l_spawncommand.cwd = l_fullpath
        end

        p_window:perform_action(
            mm_wezterm.action.SpawnCommandInNewTab(l_spawncommand),
            p_pane
        )

    end

end

------------------------------------------------------------------------------------
-- Callbacks usados para los keymappins
------------------------------------------------------------------------------------

function mod.cbk_new_tab(p_window, p_pane)

    local l_current_domain_name = p_pane.domain_name
    local l_current_workspace_name = p_window:active_workspace()

    local l_choices = m_get_choices(l_current_domain_name, l_current_workspace_name)

    p_window:perform_action(
        mm_wezterm.action.InputSelector({
            action = mm_wezterm.action_callback(m_cbk_process_selected_item),
            title = "New Tabs",
            description = "Select a domain and press Enter = accept, Esc = cancel, / = filter",
            fuzzy_description = "Domains: ",
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
