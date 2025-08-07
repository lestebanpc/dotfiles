-- Miembros publicos del modulo
local mod = {}

-- Miembros privado del modulo que ser modificado por el usario del modulo
--local m_config = {}


local mm_wezterm = require("wezterm")
local mm_ucommon = require("utils.common")
local mm_udomain = require("utils.domain")

-- Determinar el tipo de SO
--   0 > Si es Linux
--   1 > Si es Windows
--   2 > Si es MacOS (Apple Silicon)
--   3 > Si es MacOS (Intel)
--local m_os_type = mm_ucommon.get_os_type()

-- Constantes
local m_overlay_icon = ''
local m_overlay_color = '#3283D5'

local m_custom_title_icon = '󰙏'
local m_custom_title_color = '#3F40C8'

local m_zoom_icon = "󰁌" --"󰊓"
local m_zoom_color = '#41C9C9'

local m_workspace_icon = '󱂬'
local m_workspace_color = '#41C9C9'

local m_keytable_icon = '󰌌'
local m_keytable_color = '#3283D5'
local m_color_gray1 = '#565757'

local m_use_color_on_title = false



------------------------------------------------------------------------------------
-- Callback del evento 'format-tab-title'
------------------------------------------------------------------------------------


local function m_get_title_info_of(p_tab_info, p_domain_name, p_domain_info)

    -- Prefir usar el nombre establecido 'tab:set_title()' or 'wezterm cli set-tab-title' que el programna actual
    local l_tab_title = p_tab_info.tab_title
    if l_tab_title ~= nil and l_tab_title ~= "" then
        return l_tab_title, m_custom_title_icon, m_custom_title_color
    end

    -- Si es al Wizard para inicializar la conexion a un 'multiplexer server'
    if p_domain_name == "TermWizTerminalDomain" then
        return "Wizard", nil, nil
    end

    -- Obtener el titulo segun el dominio
    if p_domain_info == nil or p_domain_info.type == nil  or p_domain_info.type == 'unknown' then
        return p_domain_name, nil, nil
    end
    --mm_wezterm.log_info("type: " .. p_domain_info.type)

    -- Si es un dominio local
    local l_icon = nil
    local l_info = nil
    local l_color = nil
    if p_domain_info.type == "local" then

        local l_program_name = p_tab_info.active_pane.foreground_process_name

        if l_program_name ~= nil and l_program_name ~= "" then
            l_program_name = mm_ucommon.get_basename(l_program_name)
            l_info = l_program_name
            l_icon = mm_ucommon.get_program_icon(l_program_name)
            l_color = mm_ucommon.get_program_color(l_program_name)
        else
            -- TODO: Como identificar el overlay (debug overlay, input overlay) cuando no es el dominio local
            l_info = 'Overlay'
            l_icon = m_overlay_icon
            l_color = m_overlay_color
        end

        return l_info, l_icon, l_color

    end

    -- Si el dominio es un exec domain
    if p_domain_info.type == "exec" then

        if p_domain_info.ex_data == nil then
            l_info = p_domain_name
            l_icon = nil
        elseif p_domain_info.ex_data.type == 'k8s' then
            l_info = p_domain_info.ex_data.name
            l_icon = p_domain_info.ex_data.icon
            l_color = p_domain_info.ex_data.color
        elseif p_domain_info.ex_data.type == 'container' then
            l_info = p_domain_info.ex_data.name
            l_icon = p_domain_info.ex_data.icon
            l_color = p_domain_info.ex_data.color
        else
            l_info = p_domain_name
            l_icon = p_domain_info.ex_data.icon
            l_color = p_domain_info.ex_data.color
        end

        return l_info, l_icon, l_color

    end

    if p_domain_info.data == nil then
        return 'unknown', nil, nil
    end

    -- Si es un dominio SSH
    if p_domain_info.type == "ssh" then

        local l_server = p_domain_info.data.remote_address or '1.1.1.1'
        local l_username = nil
        if p_domain_info.ex_data ~= nil then
            l_username = p_domain_info.ex_data.user
        else
            l_username = p_domain_info.data.username
        end

        if l_username == nil or l_username == "" then
            l_info = l_server
        else
            l_info = l_username .. '@' .. l_server
        end

        return l_info, l_icon, l_color

    end

    -- Si es un dominio Socket IPC
    if p_domain_info.type == "unix" then

        local l_socket_path = p_domain_info.data.socket_path

        if l_socket_path == nil or l_socket_path == "" then
            l_info = p_domain_name
        else
            local l_socket_name = mm_ucommon.get_basename(l_socket_path)
            l_info = 'ipc://' .. l_socket_name
        end

        return l_info, l_icon, l_color

    end


    -- Si es un dominio TLS
    if p_domain_info.type == "tls" then

        local l_server = p_domain_info.data.remote_address

        if l_server == nil or l_server == "" then
            l_info = p_domain_name
        else
            l_info = l_server
        end

        return l_info, l_icon, l_color

    end

    -- Si es un dominio WSL
    if p_domain_info.type == "wsl" then

        local l_distribution = p_domain_info.data.distribution

        if l_distribution == nil or l_distribution == "" then
            l_info = p_domain_name
        else
            l_info = l_distribution
        end

        return l_info, l_icon, l_color

    end

    return 'unknown', nil, nil

end



-- Evento invocado por cada tab que requiere se redibujado
-- URLs:
--  > https://wezterm.org/config/lua/PaneInformation.html
--  > https://wezterm.org/config/lua/TabInformation.html
function mod.callback_format_tab_title(p_tab_info, p_tabs_info, p_panes_info, p_config, p_hover, p_max_width)

    local l_pane_info = p_tab_info.active_pane

    -- Obtener informacion del dominio actual
    local l_domain_name = l_pane_info.domain_name
    --mm_wezterm.log_info("domain name: " .. l_pane.domain_name)
    local l_domain_info = mm_udomain.get_domain_info(l_domain_name)
    --mm_wezterm.log_info("domain type: " .. l_domain_info.type)

    -- Obtener informacion del titulo a usar
    local l_title_info, l_title_icon, l_title_icon_color = m_get_title_info_of(p_tab_info, l_domain_name, l_domain_info)

    local l_is_zommed = l_pane_info.is_zoomed
    local l_tab_index = p_tab_info.tab_index + 1


    -- Construir título
    local l_format_items = nil

    -- Si no se usa colores (no esta soportando el x11)
    if not m_use_color_on_title then

        l_format_items = {
            { Text = ' ' .. l_domain_info.icon },
            { Text = ' ' .. tostring(l_tab_index) .. ':  ' },
        }

        if l_title_icon ~= nil and l_title_icon ~= '' then
            table.insert(l_format_items, { Text = l_title_icon .. '  ' })
        end

        table.insert(l_format_items, { Text = l_title_info })

        if l_is_zommed then
            table.insert(l_format_items, { Text = '  ' .. m_zoom_icon })
        end

        return l_format_items

    end

    -- Si se usa colores
    l_format_items = {
        { Foreground = { Color =  l_domain_info.color } },
        { Text = ' ' .. l_domain_info.icon },
        'ResetAttributes',
        { Text = ' ' .. tostring(l_tab_index) .. ':  ' },
    }

    if l_title_icon ~= nil and l_title_icon ~= '' then

        if l_title_icon_color ~= nil and l_title_icon_color ~= '' then
            table.insert(l_format_items, { Foreground = { Color =  l_title_icon_color } } )
        end

        table.insert(l_format_items, { Text = l_title_icon .. '  ' })

        if l_title_icon_color ~= nil and l_title_icon_color ~= '' then
            table.insert(l_format_items, 'ResetAttributes')
        end
    end

    if l_domain_info.is_multiplexing then
        table.insert(l_format_items, { Attribute = { Underline = 'Single' } } )
    end

    table.insert(l_format_items, { Text = l_title_info })

    if l_domain_info.is_multiplexing then
        table.insert(l_format_items, 'ResetAttributes')
    end

    if l_is_zommed then
        table.insert(l_format_items, { Foreground = { Color =  m_zoom_color } } )
        table.insert(l_format_items, { Text = '  ' .. m_zoom_icon })
        table.insert(l_format_items, 'ResetAttributes')
    end

    return l_format_items

end



------------------------------------------------------------------------------------
-- Callback del evento 'update_status'
------------------------------------------------------------------------------------

-- Show which key table is active in the status area
function mod.callback_update_status(p_window, p_pane)
    -- Obtener el workspace actual
    local l_workspace_name = p_window:active_workspace()

    -- Obtener el keytable activo
    local l_keytable_name = p_window:active_key_table()


    -- Construir el texto de estado
    local l_format_items = {}

    if l_workspace_name ~= nil and l_workspace_name ~= "" then
        table.insert(l_format_items, { Foreground = { Color =  m_workspace_color } } )
        table.insert(l_format_items, { Text = m_workspace_icon })
        table.insert(l_format_items, 'ResetAttributes')
        table.insert(l_format_items, { Text = '  ' .. l_workspace_name })

        if l_keytable_name ~= nil and l_keytable_name ~= "" then
            table.insert(l_format_items, { Foreground = { Color =  m_color_gray1 }})
            table.insert(l_format_items, { Text = ' | ' })
            table.insert(l_format_items, 'ResetAttributes')
        else
            table.insert(l_format_items, { Text = '  ' })
        end

    end

    if l_keytable_name ~= nil and l_keytable_name ~= "" then
        table.insert(l_format_items, { Foreground = { Color =  m_keytable_color } } )
        table.insert(l_format_items, { Text = m_keytable_icon })
        table.insert(l_format_items, 'ResetAttributes')
        table.insert(l_format_items, { Text = '  ' .. l_keytable_name .. '  ' })
    end

    -- Mostart el status
    if #l_format_items < 1 then
        p_window:set_right_status('')
    end

    p_window:set_right_status(mm_wezterm.format(l_format_items))

end


------------------------------------------------------------------------------------
-- Callback del keymapping del 'copy-mode'
------------------------------------------------------------------------------------

local m_waction = mm_wezterm.action

--local m_search_direction = {
--  BACKWARD = 0,
--  FORWARD = 1,
--}
--
---- Almacenar data a nivel intancie de emulador de terminal
---- URL https://wezterm.org/config/lua/wezterm/GLOBAL.html
--mm_wezterm.GLOBAL.tmux_search_directions = {}
--
--local function m_cbk_clear_pattern(window, pane)
--
--    wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = nil
--    window:perform_action(m_waction.Multiple({
--      m_waction.CopyMode("ClearPattern"),
--      m_waction.CopyMode("AcceptPattern"),
--    }), pane)
--
--end
--
--local function m_cbk_clear_selection_pattern_or_close(window, pane)
--
--    local action
--
--    if window:get_selection_text_for_pane(pane) ~= "" then
--      action = m_waction.Multiple({
--        m_waction.ClearSelection,
--        m_waction.CopyMode("ClearSelectionMode"),
--      })
--    elseif wezterm.GLOBAL.tmux_search_directions[tostring(pane)] then
--      action = m_cbk_clear_pattern
--    else
--      action = m_waction.CopyMode("Close")
--    end
--
--    window:perform_action(action, pane)
--
--end
--
--
--local function m_cbk_accept_and_close(window, pane)
--
--    local action
--
--    if wezterm.GLOBAL.tmux_search_directions[tostring(pane)] then
--
--        wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = nil
--        action = m_waction.Multiple({
--            m_waction.CopyTo("Clipboard"),
--            --m_waction.ClearSelection,
--            --m_waction.CopyMode("ClearSelectionMode"),
--            --m_waction.CopyMode("ScrollToBottom"),
--            m_waction.CopyMode("ClearPattern"),
--            m_waction.CopyMode("AcceptPattern"),
--            m_waction.CopyMode("Close"),
--        })
--
--    else
--
--        action = m_waction.Multiple({
--            m_waction.CopyTo("Clipboard"),
--            --m_waction.ClearSelection,
--            --m_waction.CopyMode("ClearSelectionMode"),
--            --m_waction.CopyMode("ScrollToBottom"),
--            m_waction.CopyMode("Close"),
--        })
--
--    end
--
--    window:perform_action(action, pane)
--
--end
--
--
--local function m_cbk_close_without_accept(window, pane)
--
--    local action
--
--    if wezterm.GLOBAL.tmux_search_directions[tostring(pane)] then
--
--        wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = nil
--        action = m_waction.Multiple({
--            --m_waction.ClearSelection,
--            --m_waction.CopyMode("ClearSelectionMode"),
--            --m_waction.CopyMode("ScrollToBottom"),
--            m_waction.CopyMode("ClearPattern"),
--            m_waction.CopyMode("AcceptPattern"),
--            m_waction.CopyMode("Close"),
--        })
--
--    else
--
--        action = m_waction.Multiple({
--            --m_waction.ClearSelection,
--            --m_waction.CopyMode("ClearSelectionMode"),
--            --m_waction.CopyMode("ScrollToBottom"),
--            m_waction.CopyMode("Close"),
--        })
--
--    end
--
--    window:perform_action(action, pane)
--
--end
--
--
--local function m_cbk_next_match(window, pane)
--
--    local direction = wezterm.GLOBAL.tmux_search_directions[tostring(pane)]
--    if not direction then
--      return
--    end
--
--    local action
--    if direction == m_search_direction.BACKWARD then
--      action = m_waction.Multiple({
--        m_waction.CopyMode("PriorMatch"),
--        m_waction.ClearSelection,
--        m_waction.CopyMode("ClearSelectionMode"),
--      })
--    elseif direction == m_search_direction.FORWARD then
--      action = m_waction.Multiple({
--        m_waction.CopyMode("NextMatch"),
--        m_waction.ClearSelection,
--        m_waction.CopyMode("ClearSelectionMode"),
--      })
--    end
--
--    window:perform_action(action, pane)
--
--end
--
--local function m_cbk_prior_match(window, pane)
--
--    local direction = wezterm.GLOBAL.tmux_search_directions[tostring(pane)]
--    if not direction then
--      return
--    end
--
--    local action
--    if direction == m_search_direction.BACKWARD then
--      action = act.Multiple({
--        act.CopyMode("NextMatch"),
--        act.ClearSelection,
--        act.CopyMode("ClearSelectionMode"),
--      })
--    elseif direction == m_search_direction.FORWARD then
--      action = m_waction.Multiple({
--        m_waction.CopyMode("PriorMatch"),
--        m_waction.ClearSelection,
--        m_waction.CopyMode("ClearSelectionMode"),
--      })
--    end
--
--    window:perform_action(action, pane)
--
--end
--
--
--local function m_cbk_search_backward(window, pane)
--
--    wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = m_search_direction.BACKWARD
--
--    window:perform_action(m_waction.Multiple({
--      m_waction.CopyMode("ClearPattern"),
--      m_waction.CopyMode("EditPattern"),
--    }), pane)
--
--end
--
--local function m_cbk_search_forward(window, pane)
--
--    wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = m_search_direction.FORWARD
--
--    window:perform_action(m_waction.Multiple({
--      m_waction.CopyMode("ClearPattern"),
--      m_waction.CopyMode("EditPattern"),
--    }), pane)
--
--end


------------------------------------------------------------------------------------
-- Callback del keymapping del normal mode
------------------------------------------------------------------------------------

local function m_cbk_move_pane_to_newtab(_, pane)
    local tab, _ = pane:move_to_new_tab()
    tab:activate()
end



------------------------------------------------------------------------------------
-- Generador de los keymappings
------------------------------------------------------------------------------------
--
-- Defualt Keymappings
-- > Modo Normal       : https://wezterm.org/config/default-keys.html
-- > Modo Copia        : https://wezterm.org/copymode.html
-- > Modo Quick Select : https://wezterm.org/quickselect.html
-- > Modo Search       : https://wezterm.org/scrollback.html#enabledisable-scrollbar
--

function mod.get_key_mappins()


    -- Action Callback usado para gestionar los 'workspace'
    local lm_uworkspace = require('utils.workspace')

    local l_keys = {

        --------------------------------------------------------------------------------
        --1. Capacidades basicas de la terminal
        --------------------------------------------------------------------------------

        --1. Scrollback del panel actual en modo normal (Limpieza y navegacion)
        { key = 'PageUp', mods = 'SHIFT', action = m_waction.ScrollByPage(-1) },
        { key = 'PageDown', mods = 'SHIFT', action = m_waction.ScrollByPage(1) },
        { key = 'UpArrow', mods = 'CTRL|SHIFT', action = m_waction.ScrollByLine(-1) },
        { key = 'DownArrow', mods = 'CTRL|SHIFT', action = m_waction.ScrollByLine(1) },
        { key = 'Home', mods = 'SHIFT', action = m_waction.ScrollToTop },
        { key = 'End', mods = 'SHIFT', action = m_waction.ScrollToBottom },
        { key = 'z', mods = 'CTRL|SHIFT', action = m_waction.ScrollToPrompt(-1) },
        { key = 'x', mods = 'CTRL|SHIFT', action = m_waction.ScrollToPrompt(1) },

        --{ key = 'L', mods = 'CTRL|SHIFT', action = m_waction.ClearScrollback 'ScrollbackOnly' },

        --2. Gestion de la fuente usado por la terminal
        { key = '+', mods = 'CTRL', action = m_waction.IncreaseFontSize },
        { key = '+', mods = 'CTRL|SHIFT', action = m_waction.IncreaseFontSize },
        { key = '-', mods = 'CTRL', action = m_waction.DecreaseFontSize },
        { key = '0', mods = 'CTRL', action = m_waction.ResetFontSize },

        --3. Gestion del clipboard
        { key = 'c', mods = 'CTRL|SHIFT', action = m_waction.CopyTo('Clipboard') },
        { key = 'Copy', mods = 'NONE', action = m_waction.CopyTo('Clipboard') },

        { key = 'v', mods = 'CTRL|SHIFT', action = m_waction.PasteFrom('Clipboard') },
        { key = ']', mods = 'LEADER', action = m_waction.PasteFrom('Clipboard') },
        --{ key = ']', mods = 'LEADER|SHIFT', action = m_waction.PasteFrom('Clipboard') },
        { key = 'Paste', mods = 'NONE', action = m_waction.PasteFrom('Clipboard') },

        --{ key = 'Insert', mods = 'CTRL', action = m_waction.CopyTo('PrimarySelection') },
        --{ key = 'Insert', mods = 'SHIFT', action = m_waction.PasteFrom('PrimarySelection') },


        --------------------------------------------------------------------------------
        --2. Gestion de Workspace (sesiones)
        --------------------------------------------------------------------------------

        { key = 's', mods = 'LEADER', action = mm_wezterm.action_callback(lm_uworkspace.cbk_chose_workspace_with_zoxide), },
        { key = 's', mods = 'LEADER|SHIFT', action = mm_wezterm.action_callback(lm_uworkspace.cbk_chose_workspace_with_git), },

        --------------------------------------------------------------------------------
        --3. Uso de 'Damain' y Gestion del 'Tab' (Window)
        --------------------------------------------------------------------------------

        -- Creation> Crear (create) un tab en usando el dominio usado por el panel actual
        { key = 'c', mods = 'LEADER', action = m_waction.SpawnTab('CurrentPaneDomain') },

        -- Creation> Crear (create) una tab en el dominio por defecto
        { key = 'c', mods = 'LEADER|SHIFT', action = m_waction.SpawnTab('DefaultDomain') },

        -- Creation (interactive)> Crear un tab usando un dominio existente (usa el 'Domains Fuzzy Laucher')
        --{ key = 'w', mods = 'LEADER', action = m_waction.ShowLauncherArgs({ flags =  'FUZZY|DOMAINS' }) },
        { key = 'w', mods = 'LEADER', action = mm_wezterm.action_callback(mm_udomain.cbk_new_tab), },

        -- Creation (interactive)> Crear un tab en el dominio 'local' que ejecuta un programa usando el 'Menu Laucher'
        { key = 'w', mods = 'LEADER|SHIFT', action = m_waction.ShowLauncherArgs({ flags =  'LAUNCH_MENU_ITEMS' }) },

        -- Detach un 'multiplexing domain' (asociado al dominio del panel actual) del 'multiplexor server' externo a la terminal.
        -- > No funciona con dominios locales. Funciona con dominios 'unix', 'tls' y solo con los 'ssh' que son multiplexing.
        -- > Desvincula todos 'tab' del dominio y no se muestran en el workspace actual hasta que se vuelva a 'attach'.
        { key = 'd', mods = 'LEADER', action = m_waction.DetachDomain('CurrentPaneDomain') },

        -- Navegation> Ir a un tab segun su posicion (posicion: indice + 1)
        { key = '1', mods = 'LEADER', action = m_waction.ActivateTab(0) },
        { key = '2', mods = 'LEADER', action = m_waction.ActivateTab(1) },
        { key = '3', mods = 'LEADER', action = m_waction.ActivateTab(2) },
        { key = '4', mods = 'LEADER', action = m_waction.ActivateTab(3) },
        { key = '5', mods = 'LEADER', action = m_waction.ActivateTab(4) },
        { key = '6', mods = 'LEADER', action = m_waction.ActivateTab(5) },
        { key = '7', mods = 'LEADER', action = m_waction.ActivateTab(6) },
        { key = '8', mods = 'LEADER', action = m_waction.ActivateTab(7) },
        { key = '9', mods = 'LEADER', action = m_waction.ActivateTab(8) },
        { key = '0', mods = 'LEADER', action = m_waction.ActivateTab(9) },

        -- Navegation> Ir a ultimo ('end') tab
        { key = 'e', mods = 'LEADER', action = m_waction.ActivateTab(-1) },

        -- Navegation> Ir al next/previous tab
        { key = 'n', mods = 'LEADER', action = m_waction.ActivateTabRelative(1) },
        { key = 'p', mods = 'LEADER', action = m_waction.ActivateTabRelative(-1) },

        -- Swap> Intercambiar de posicion 2 paneles continuos
        { key = '>', mods = 'LEADER|SHIFT', action = m_waction.MoveTabRelative(1) },
        { key = '<', mods = 'LEADER|SHIFT', action = m_waction.MoveTabRelative(-1) },
        { key = '<', mods = 'LEADER', action = m_waction.MoveTabRelative(-1) },

        -- Close current Tab
        --{ key = '&', mods = 'LEADER', action = m_waction.CloseCurrentTab{ confirm = true } },
        { key = '&', mods = 'LEADER|SHIFT', action = m_waction.CloseCurrentTab{ confirm = true } },


        --------------------------------------------------------------------------------
        --4. Gestion del Panel (de un Tab/Window)
        --------------------------------------------------------------------------------

        -- Variados> Fullscreen/Restaurar el tamaño del panel actual 
        { key = 'z', mods = 'LEADER', action = m_waction.TogglePaneZoomState },

        -- Variados> Cerrar el panel actual
        { key = 'x', mods = 'LEADER', action = m_waction.CloseCurrentPane({ confirm = true }) },

        -- Split> Dividir el panel actual verticalmente (crear un panel vertical)
        { key = '"', mods = 'LEADER|SHIFT', action = m_waction.SplitVertical({ domain =  'CurrentPaneDomain' }) },
        { key = '=', mods = 'LEADER', action = m_waction.SplitHorizontal({ domain =  'CurrentPaneDomain' }) },
        { key = '=', mods = 'LEADER|SHIFT', action = m_waction.SplitHorizontal({ domain =  'CurrentPaneDomain' }) },
        { key = '|', mods = 'LEADER', action = m_waction.SplitHorizontal({ domain =  'CurrentPaneDomain' }) },
        { key = '|', mods = 'LEADER|SHIFT', action = m_waction.SplitHorizontal({ domain =  'CurrentPaneDomain' }) },

        -- Split> Dividir el panel actual verticalmente (crear un panel vertical)
        { key = '%', mods = 'LEADER|SHIFT', action = m_waction.SplitHorizontal({ domain =  'CurrentPaneDomain' }) },
        { key = '-', mods = 'LEADER', action = m_waction.SplitVertical({ domain =  'CurrentPaneDomain' }) },

        -- Navegation> Ir al paneles continuo ('←/↓/↑/→' o 'h/j/k/l'
        { key = 'LeftArrow', mods = 'LEADER', action = m_waction.ActivatePaneDirection('Left') },
        { key = 'h', mods = 'LEADER', action = m_waction.ActivatePaneDirection('Left') },

        { key = 'RightArrow', mods = 'LEADER', action = m_waction.ActivatePaneDirection('Right') },
        { key = 'l', mods = 'LEADER', action = m_waction.ActivatePaneDirection('Right') },

        { key = 'UpArrow', mods = 'LEADER', action = m_waction.ActivatePaneDirection('Up') },
        { key = 'k', mods = 'LEADER', action = m_waction.ActivatePaneDirection('Up') },

        { key = 'DownArrow', mods = 'LEADER', action = m_waction.ActivatePaneDirection('Down') },
        { key = 'j', mods = 'LEADER', action = m_waction.ActivatePaneDirection('Down') },

        -- Resizing> Modificar el tamaño de un panel
        { key = 'r', mods = 'LEADER', action = m_waction.ActivateKeyTable({ name = 'resize_pane', one_shot = false, }) },
        --{ key = 'r', mods = 'LEADER', action = m_waction.ActivateKeyTable({ name = 'resize_pane', timeout_milliseconds = 1000, }) },

        -- Rotating > Rotar los paneles segun el sentido horario o antihorario
        { key = '{', mods = 'LEADER|SHIFT', action = m_waction.RotatePanes('CounterClockwise') },
        { key = '{', mods = 'LEADER', action = m_waction.RotatePanes('CounterClockwise') },
        { key = '}', mods = 'LEADER|SHIFT', action = m_waction.RotatePanes('Clockwise') },
        { key = '}', mods = 'LEADER', action = m_waction.RotatePanes('Clockwise') },

        -- Convertir el panel actual a un Tab
        { key = '!', mods = 'LEADER|SHIFT', action = mm_wezterm.action_callback(m_cbk_move_pane_to_newtab) },

        -- Mostar el indice del panel
        { key = 'q', mods = 'LEADER', action = m_waction.PaneSelect({ mode = "Activate" }) },


        --------------------------------------------------------------------------------
        --5. Cambiar de modo
        --------------------------------------------------------------------------------

        -- Ingresar a la busqueda rapida
        { key = 'phys:Space', mods = 'LEADER', action = m_waction.QuickSelect },

        -- Activar al modo copia
        { key = '[', mods = 'LEADER', action = m_waction.ActivateCopyMode },
        { key = '[', mods = 'LEADER|SHIFT', action = m_waction.ActivateCopyMode },

        -- Activar la seleccion de caracteres unicode
        { key = 'u', mods = 'LEADER|SHIFT', action = m_waction.CharSelect({ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' }) },


        --------------------------------------------------------------------------------
        --6. Otros
        --------------------------------------------------------------------------------

        { key = 'd', mods = 'LEADER|SHIFT', action = m_waction.ShowDebugOverlay },
        { key = 'r', mods = 'LEADER|SHIFT', action = m_waction.ReloadConfiguration },
        --{ key = 'a', mods = 'LEADER|CTRL', action = m_waction.SendString('\u{1}') },
        --{ key = 'm', mods = 'CTRL|SHIFT', action = m_waction.Hide },
        --{ key = 'p', mods = 'CTRL|SHIFT', action = m_waction.ActivateCommandPalette },


    }

    return l_keys

end


function mod.get_keytables_mappins()


    local l_keytables = {

        --------------------------------------------------------------------------
        -- Modo de copia
        --------------------------------------------------------------------------
        copy_mode = {

          -- Salir del modo sin aceptar la seleccion realizada.
          { key = 'q',       mods = 'NONE',   action = m_waction.Multiple(
              {
                  m_waction.CopyMode('ClearPattern'),
                  m_waction.CopyMode('AcceptPattern'),

                  -- La accion "CopyMode('Close')" limpia cualquiere seleccion o inicio de seleccion, pero no limpia el criterio
                  -- de busqueda.
                  m_waction.CopyMode('Close'),
              }
          ) },
          --{ key = 'q',       mods = 'NONE',   action = mm_wezterm.action_callback(m_cbk_close_without_accept) },

          -- Salir del modo aceptando la seleccion realizada.
          { key = 'Enter',   mods = 'NONE',   action = m_waction.Multiple(
              {
                  m_waction.CopyTo('Clipboard'),
                  m_waction.CopyMode('ClearPattern'),
                  m_waction.CopyMode('AcceptPattern'),

                  -- La accion "CopyMode('Close')" limpia cualquiere seleccion o inicio de seleccion, pero no limpia el criterio
                  -- de busqueda.
                  m_waction.CopyMode('Close'),
              }
          ) },
          --{ key = 'Enter',   mods = 'NONE',   action = mm_wezterm.action_callback(m_cbk_accept_and_close) },

          -- Aceptar una seleccion (copiar al clipboard no salir del modo)
          { key = 'y',       mods = 'NONE',   action = m_waction.Multiple(
              {
                  m_waction.CopyTo('Clipboard'),
                  m_waction.ClearSelection,
                  m_waction.CopyMode('ClearSelectionMode'),
              }
          ) },

          -- Cancelar una seleccion (deseleccionar sin salir del modo)
          { key = 'Escape',  mods = 'NONE',   action = m_waction.Multiple(
              {
                  m_waction.ClearSelection,
                  m_waction.CopyMode('ClearSelectionMode'),
              }
          ) },
          --{ key = 'Escape',  mods = 'NONE',   action = mm_wezterm.action_callback(m_cbk_clear_selection_pattern_or_close) },

          -- Iniciar una seleccion.
          { key = 'Space',   mods = 'NONE',   action = m_waction.CopyMode({ SetSelectionMode =  'Cell'  }) },
          { key = 'v',       mods = 'NONE',   action = m_waction.CopyMode({ SetSelectionMode =  'Cell'  }) },
          { key = 'v',       mods = 'SHIFT',  action = m_waction.CopyMode({ SetSelectionMode =  'Line'  }) },
          { key = 'v',       mods = 'CTRL',   action = m_waction.CopyMode({ SetSelectionMode =  'Block' }) },
          { key = 'q',       mods = 'CTRL',   action = m_waction.CopyMode({ SetSelectionMode =  'Block' }) },

          -- Modificar la selección actual horizontalmente (usado frecuentemente en ua selección rectangular)
          { key = 'o',       mods = 'NONE',   action = m_waction.CopyMode 'MoveToSelectionOtherEnd' },
          { key = 'o',       mods = 'SHIFT',  action = m_waction.CopyMode 'MoveToSelectionOtherEndHoriz' },

          -- Navegacion> Navegacion basica
          { key = 'h',          mods = 'NONE',    action = m_waction.CopyMode 'MoveLeft' },
          { key = 'j',          mods = 'NONE',    action = m_waction.CopyMode 'MoveDown' },
          { key = 'k',          mods = 'NONE',    action = m_waction.CopyMode 'MoveUp' },
          { key = 'l',          mods = 'NONE',    action = m_waction.CopyMode 'MoveRight' },
          { key = 'LeftArrow',  mods = 'NONE',    action = m_waction.CopyMode 'MoveLeft' },
          { key = 'RightArrow', mods = 'NONE',    action = m_waction.CopyMode 'MoveRight' },
          { key = 'UpArrow',    mods = 'NONE',    action = m_waction.CopyMode 'MoveUp' },
          { key = 'DownArrow',  mods = 'NONE',    action = m_waction.CopyMode 'MoveDown' },

          -- Navegacion> Moverse en una misma linea actual
          { key = '^',          mods = 'NONE',    action = m_waction.CopyMode 'MoveToStartOfLineContent' },
          { key = '^',          mods = 'SHIFT',   action = m_waction.CopyMode 'MoveToStartOfLineContent' },
          { key = 'm',          mods = 'ALT',     action = m_waction.CopyMode 'MoveToStartOfLineContent' },

          { key = '$',          mods = 'NONE',    action = m_waction.CopyMode 'MoveToEndOfLineContent' },
          { key = '$',          mods = 'SHIFT',   action = m_waction.CopyMode 'MoveToEndOfLineContent' },
          { key = 'End',        mods = 'NONE',    action = m_waction.CopyMode 'MoveToEndOfLineContent' },

          { key = '0',          mods = 'NONE',    action = m_waction.CopyMode 'MoveToStartOfLine' },
          { key = 'Home',       mods = 'NONE',    action = m_waction.CopyMode 'MoveToStartOfLine' },

          -- Navegacion> Moverse al inicio de la siguiente linea a la actual
          --{ key = 'Enter',      mods = 'NONE',   action = m_waction.CopyMode 'MoveToStartOfNextLine' },

          -- Navegacion> Moverse entre palabras anterior/siguiente
          { key = 'w',          mods = 'NONE',    action = m_waction.CopyMode 'MoveForwardWord' },
          { key = 'f',          mods = 'ALT',     action = m_waction.CopyMode 'MoveForwardWord' },
          { key = 'Tab',        mods = 'NONE',    action = m_waction.CopyMode 'MoveForwardWord' },

          { key = 'b',          mods = 'NONE',    action = m_waction.CopyMode 'MoveBackwardWord' },
          { key = 'b',          mods = 'ALT',     action = m_waction.CopyMode 'MoveBackwardWord' },
          { key = 'LeftArrow',  mods = 'ALT',     action = m_waction.CopyMode 'MoveBackwardWord' },
          { key = 'RightArrow', mods = 'ALT',     action = m_waction.CopyMode 'MoveForwardWord' },
          { key = 'Tab',        mods = 'SHIFT',   action = m_waction.CopyMode 'MoveBackwardWord' },

          { key = 'e',          mods = 'NONE',    action = m_waction.CopyMode 'MoveForwardWordEnd' },

          -- Navegacion> Moverse verticalmente dentro buffer del scrollback
          { key = 'g',          mods = 'NONE',    action = m_waction.CopyMode 'MoveToScrollbackBottom' },
          { key = 'g',          mods = 'SHIFT',   action = m_waction.CopyMode 'MoveToScrollbackBottom' },

          { key = 'b',          mods = 'CTRL',    action = m_waction.CopyMode 'PageUp' },
          { key = 'PageUp',     mods = 'NONE',    action = m_waction.CopyMode 'PageUp' },
          { key = 'u',          mods = 'CTRL',    action = m_waction.CopyMode({ MoveByPage = (-0.5) }) },
          { key = 'f',          mods = 'CTRL',    action = m_waction.CopyMode 'PageDown' },
          { key = 'PageDown',   mods = 'NONE',    action = m_waction.CopyMode 'PageDown' },
          { key = 'd',          mods = 'CTRL',    action = m_waction.CopyMode({ MoveByPage = (0.5) }) },

          -- Mover el viewport dentro buffer del scrollback
          { key = 'h',          mods = 'SHIFT',   action = m_waction.CopyMode 'MoveToViewportTop' },
          { key = 'l',          mods = 'SHIFT',   action = m_waction.CopyMode 'MoveToViewportBottom' },
          { key = 'm',          mods = 'SHIFT',   action = m_waction.CopyMode 'MoveToViewportMiddle' },


          -- Search> Inicia el modo busqueda (muestra el 'input popup' para ingresar el criterio de busqueda).
          { key='/',            mods = 'NONE',    action = m_waction.Multiple(
              {
                  m_waction.CopyMode("ClearPattern"),

                  -- La accion "CopyMode('EditPattern')" como 'Search()', desde el modo copia, realiza los mismo, con la diferencia
                  -- que en el ultimio permite especicar opciones como el tipo de busqueda.
                  m_waction.Search({ CaseSensitiveString = "" }),
                  --m_waction.CopyMode('EditPattern'),
              }
          ) },
          --{ key = '/',          mods = 'NONE',    action = mm_wezterm.action_callback(m_cbk_search_forward) },

          { key='?',            mods = 'NONE',    action = m_waction.Multiple(
              {
                  m_waction.CopyMode("ClearPattern"),

                  -- La accion "CopyMode('EditPattern')" como 'Search()', desde el modo copia, realiza los mismo, con la diferencia
                  -- que en el ultimio permite especicar opciones como el tipo de busqueda.
                  m_waction.Search({ CaseSensitiveString = "" }),
                  --m_waction.CopyMode('EditPattern'),
              }
          ) },
          --{ key = '?',          mods = 'NONE',    action = mm_wezterm.action_callback(m_cbk_search_backward) },

          -- Search> Ir a la anterior coincidencia.
          { key='n',            mods = 'NONE',    action = m_waction.Multiple(
              {
                  m_waction.CopyMode('NextMatch'),

                  -- Deshacer cualquier seleccion o inicio de selecion existente
                  m_waction.ClearSelection,
                  m_waction.CopyMode("ClearSelectionMode"),
              }
          ) },
          --{ key = 'n',          mods = 'NONE',    action = mm_wezterm.action_callback(m_cbk_next_match) },

          { key='n',            mods = 'SHIFT',   action = m_waction.Multiple(
              {
                  m_waction.CopyMode('PriorMatch'),

                  -- Deshacer cualquier seleccion o inicio de selecion existente
                  m_waction.ClearSelection,
                  m_waction.CopyMode("ClearSelectionMode"),
              }
          ) },
          --{ key = 'N',          mods = 'NONE',    action = mm_wezterm.action_callback(m_cbk_prior_match) },

          -- Search> Limpiar el criterio de busqueda (cuando esta en modo copia, limpia el criterio y los marcadores de coincidencia).
          { key ='u',           mods = 'CTRL',    action = m_waction.CopyMode('ClearPattern') },


          -- Search> Remover
          --{ key = 'p',          mods = 'NONE',    action = m_waction.CopyMode 'JumpReverse' },
          --{ key = 'n',          mods = 'NONE',    action = m_waction.CopyMode 'JumpAgain' },
          --{ key = 'f',          mods = 'NONE',    action = m_waction.CopyMode({ JumpForward = { prev_char = false } }) },
          --{ key = 'f',          mods = 'SHIFT',   action = m_waction.CopyMode({ JumpBackward = { prev_char = false } }) },
          --{ key = 't',          mods = 'NONE',    action = m_waction.CopyMode({ JumpForward = { prev_char = true } }) },
          --{ key = 't',          mods = 'SHIFT',   action = m_waction.CopyMode({ JumpBackward = { prev_char = true } }) },

        },

        --------------------------------------------------------------------------
        -- Modo de busqueda
        --------------------------------------------------------------------------
        --
        -- > Muestra el 'input popup' para ingresar el criterio de busqueda.
        --
        search_mode = {

          -- Salir> Ir al modo al modo copia, sim aceptar el criterio de busqueda.
          { key = 'Escape',       mods = 'NONE',   action = m_waction.Multiple(
              {
                  -- No se encuentra una coincidencia, van al modo copia y no inician la seleccion.
                  m_waction.CopyMode('ClearPattern'),
                  m_waction.CopyMode('AcceptPattern'),
              }
          ) },


          -- Salir> Ir al modo copia aceptando el criterio de busqueda.
          { key = 'Enter',        mods = 'NONE',   action = m_waction.Multiple(
              {
                  -- Por defecto tanto "ActivateCopyMode" como "CopyMode('AcceptPattern')" hacen los mismo en este modo:
                  -- > Si se tiene un criterio de busqueda y se encuentra una coincidencia, va al modo copia e inicia una seleccion
                  --   cactarter x caracter.
                  -- > Si no encuentra una coincidencia, van al modo copia y no inician la seleccion.
                  --m_waction.ActivateCopyMode,
                  m_waction.CopyMode('AcceptPattern'),

                  -- Deshacer cualquier seleccion o inicio de selecion existente
                  m_waction.ClearSelection,
                  m_waction.CopyMode("ClearSelectionMode"),
              }
          ) },

          -- Limpiar el criterio de busqueda (cuando esta en modo busqueda, limpia el criterio pero deja el 'input popup' activo).
          { key ='u',             mods = 'CTRL',   action = m_waction.CopyMode('ClearPattern') },

          -- Cambiar el tipo de busqueda usado para el criterio de busqueda. Estos tipos puede ser:
          --  > 'case-sensitive'
          --  > 'case-inssensitive'
          --  > expresiones regulares
          { key ='r',             mods = 'CTRL',   action = m_waction.CopyMode('CycleMatchType') },

        },


        --------------------------------------------------------------------------
        -- 'ActivateKeyTable' del modo normal
        --------------------------------------------------------------------------

        resize_pane = {
            -- Incrementar/Reducir de 1 en 1
            { key = 'LeftArrow', mods = 'NONE', action = m_waction.AdjustPaneSize({ 'Left', 1 }) },
            { key = 'h', mods = 'NONE', action = m_waction.AdjustPaneSize({ 'Left', 1 }) },

            { key = 'RightArrow', mods = 'NONE', action = m_waction.AdjustPaneSize({ 'Right', 1 }) },
            { key = 'l', mods = 'NONE', action = m_waction.AdjustPaneSize({ 'Right', 1 }) },

            { key = 'UpArrow', mods = 'NONE', action = m_waction.AdjustPaneSize({ 'Up', 1 }) },
            { key = 'k', mods = 'NONE', action = m_waction.AdjustPaneSize({ 'Up', 1 }) },

            { key = 'DownArrow', mods = 'NONE', action = m_waction.AdjustPaneSize({ 'Down', 1 }) },
            { key = 'j', mods = 'NONE', action = m_waction.AdjustPaneSize({ 'Down', 1 }) },

            -- Incrementar/Reducir de 5 en 5
            { key = 'LeftArrow', mods = 'SHIFT', action = m_waction.AdjustPaneSize({ 'Left', 5 }) },
            { key = 'h', mods = 'SHIFT', action = m_waction.AdjustPaneSize({ 'Left', 5 }) },

            { key = 'RightArrow', mods = 'SHIFT', action = m_waction.AdjustPaneSize({ 'Right', 5 }) },
            { key = 'l', mods = 'SHIFT', action = m_waction.AdjustPaneSize({ 'Right', 5 }) },

            { key = 'UpArrow', mods = 'SHIFT', action = m_waction.AdjustPaneSize({ 'Up', 5 }) },
            { key = 'k', mods = 'SHIFT', action = m_waction.AdjustPaneSize({ 'Up', 5 }) },

            { key = 'DownArrow', mods = 'SHIFT', action = m_waction.AdjustPaneSize({ 'Down', 5 }) },
            { key = 'j', mods = 'SHIFT', action = m_waction.AdjustPaneSize({ 'Down', 5 }) },

            -- Cancel the mode by pressing escape
            { key = "Escape", action = "PopKeyTable" },
        },

    }


    return l_keytables

end



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
