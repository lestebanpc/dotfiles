local mm_wezterm = require("wezterm")

-- Miembros publicos del modulo
local mod = {}

-- Miembros privado del modulo que ser modificado por el usario del modulo
--local m_config = {}



------------------------------------------------------------------------------------
-- Dominios de multiplexion de tipo SSH Domains
------------------------------------------------------------------------------------

-- > Por cada entrada 'Host' se creara 2 entradas: para iniciar SSH sin usar el mulitplexer server remoto o para usar con este.
-- > Sus campos por defecto son:
--   > name           : Los dominios creados iniciaran con 'SSH:' y 'SSHMUX:'
--   > username       :
--   > remote_address :
--   > multiplexing   : Para lo que inicia con SSHMUX su valor es 'WezTerm'. Los que inician con SSH su valor es 'None'.
--   > ssh_option     : {}
-- > URLs:
--   > https://wezterm.org/config/lua/wezterm/default_ssh_domains.html
function mod.get_ssh_domains(p_custom_ssh_domains)

    local l_ssh_domains = mm_wezterm.default_ssh_domains()

    -- Ignorar los dominios que tengan un wilcard en el nombre
    local l_filtered_ssh_domains = {}

    for _, domain in ipairs(l_ssh_domains) do
        if not domain.name:match("^SSH.*:.local") and not domain.name:match("^SSH.*:gh-") and not domain.name:match("^SSH.*:gl-") then
            table.insert(l_filtered_ssh_domains, domain)
        end
    end

    -- Adicionar los dominios adicionados por el usuario
    if p_custom_ssh_domains ~= nil then

        for _, domain in ipairs(p_custom_ssh_domains) do
            if not string.find(domain.name, "*") then
                table.insert(l_filtered_ssh_domains, domain)
            end
        end

    end

    return l_filtered_ssh_domains

end



------------------------------------------------------------------------------------
-- Callback del evento 'format-tab-title'
------------------------------------------------------------------------------------

-- Mapeo de íconos NerdFont para dominios
local m_tbl_domain_icons = {
  ["local"] = "",
  ["wsl"] = "",
  ["ssh"] = "󰣀",
  ["unix"] = "",
  ["tls"] = "󰖟",
  ["unknown"] = ""
}

-- Mapeo de íconos NerdFont para los programas
local m_tbl_program_icons = {
  ["bash"] = "",
  ["zsh"] = "",
  ["fish"] = "󰈺",
  ["pwsh"] = "",
  ["powershell"] = "",
  ["cmd"] = "",
  ["vim"] = "",
  ["nvim"] = "",
  ["overlaywindow"] = '',
  ["unknown"] = "󰙵",
}

local function m_get_title_of(p_domain_info, p_tab)

    -- Prefir usar el nombre establecido 'tab:set_title()' or 'wezterm cli set-tab-title' que el programna actual
    local l_tab_title = p_tab.tab_title
    if l_tab_title ~= nil and l_tab_title ~= "" then
        return l_tab_title
    end

    -- Obtener el titulo segun el dominio
    local lm_ucommon = require("utils.commom")
    local l_title = ''
    --mm_wezterm.log_info("type: " .. p_domain_info.domain_type)

    -- Si es un dominio local
    if p_domain_info.domain_type == "local" then

        local l_program_name = p_tab.active_pane.foreground_process_name
        --mm_wezterm.log_info("program: " .. l_program_name)
        local l_program_icon = ''

        if l_program_name == nil or l_program_name == "" then
            l_program_name = 'Overlay Window'
            l_program_icon = m_tbl_program_icons["overlaywindow"]
        else
            l_program_name = lm_ucommon.get_basename(l_program_name)
            --mm_wezterm.log_info("program: " .. l_program_name)
            l_program_icon = m_tbl_program_icons[l_program_name]
            if l_program_icon == nil then
                l_program_icon = m_tbl_program_icons["unknown"]
            end
        end

        l_title = string.format("%s %s", l_program_icon, l_program_name)
        return l_title

    end

    if p_domain_info == nil or p_domain_info.domain_data == nil then
        return 'unknown'
    end

    -- Si es un dominio SSH
    if p_domain_info.domain_type == "ssh" then

        local l_server = p_domain_info.domain_data.remote_address or '1.1.1.1'
        local l_username = p_domain_info.domain_data.username

        if l_username == nil or l_username == "" then
            return l_server
        end

        l_title = l_username .. '@' .. l_server
        return l_title

    end

    -- Si es un dominio Socket IPC
    if p_domain_info.domain_type == "unix" then

        local l_socket_path = p_domain_info.domain_data.socket_path or 'unknown'
        local l_socket_name = lm_ucommon.get_basename(l_socket_path)

        l_title = 'ipc:' .. l_socket_name
        return l_title

    end


    -- Si es un dominio TLS
    if p_domain_info.domain_type == "tls" then

        local l_server = p_domain_info.domain_data.remote_address or 'unknown:111'
        return l_title

    end

    -- Si es un dominio WSL
    if p_domain_info.domain_type == "wsl" then

        local l_distribution = p_domain_info.domain_data.distribution or 'unknown'
        return l_distribution

    end

    return 'unknown'

end



-- Evento invocado por cada tab que requiere se redibujado
-- URLs:
--  > https://wezterm.org/config/lua/PaneInformation.html
--  > https://wezterm.org/config/lua/TabInformation.html
function mod.callback_format_tab_title(tab, tabs, panes, config, hover, max_width)

    local l_pane = tab.active_pane

    --1. Obtener informacion del dominio de ejecucion actual
    local lm_ucommon = require("utils.commom")
    --mm_wezterm.log_info("domain_name: " .. pane.domain_name)
    local l_domain_info = lm_ucommon.get_domain_info(l_pane.domain_name)
    --mm_wezterm.log_info("domain_type: " .. l_domain_info.domain_type)

    local l_domain_icon= m_tbl_domain_icons[l_domain_info.domain_type]

    --2. Obtener informacion del titulo a usar
    local l_title = m_get_title_of(l_domain_info, tab)

    --3. Otra informacion del tab
    local l_zoom_indicator = "󰁌" --"󰊓"
    local l_zoomed = l_pane.is_zoomed
    local l_tab_index = tab.tab_index + 1


    --4. Construir título
    local l_tab_title = ''

    if l_zoomed then
      l_tab_title = string.format(" %s %d:  %s  %s", l_domain_icon, l_tab_index, l_title, l_zoom_indicator)
    else
      l_tab_title = string.format(" %s %d:  %s", l_domain_icon, l_tab_index, l_title)
    end

    return l_tab_title

end



------------------------------------------------------------------------------------
-- Callback del evento 'update_status'
------------------------------------------------------------------------------------

-- Show which key table is active in the status area
function mod.callback_update_status(window, pane)

    local l_status = ''

    -- Obtener el workspace actual
    local l_workspace = window:active_workspace()

    if l_workspace ~= nil and l_workspace ~= "" then
        if l_status == '' then
            l_status = string.format('%s %s', mm_wezterm.nerdfonts.cod_archive, l_workspace)
        else
            l_status = string.format('%s %s | %s', mm_wezterm.nerdfonts.cod_archive, l_workspace, l_status)
        end
    end

    -- Obtener el keytable activo
    local l_keytable = window:active_key_table()

    if l_keytable ~= nil and l_keytable ~= "" then
        if l_status == '' then
            l_status = string.format('%s %s', mm_wezterm.nerdfonts.cod_record_keys, l_keytable)
        else
            l_status = string.format('%s %s | %s', mm_wezterm.nerdfonts.cod_record_keys, l_keytable, l_status)
        end
    end

    -- Mostart el status
    if l_status ~= '' then
      l_status =  ' ' .. l_status .. '  '
    end

    window:set_right_status(l_status)

    --window:set_right_status(mm_wezterm.format({
    --    { Attribute = { Intensity = "Normal" } },
    --    { Foreground = { Color = "#f0f0f0" } },
    --    { Background = { Color = "#333333" } },
    --    { Text = l_status },
    --}))

end



------------------------------------------------------------------------------------
-- Generador de los keymappings
------------------------------------------------------------------------------------

function mod.get_key_mappins()

    local l_waction = mm_wezterm.action

    -- Action Callback usado para gestionar los 'workspace'
    local lm_uworkspace = require('utils.workspace')

    local l_keys = {

        --------------------------------------------------------------------------------
        --1. Capacidades basicas de la terminal
        --------------------------------------------------------------------------------

        --2. Scrollback del panel actual en modo normal (Limpieza y navegacion)
        --{ key = 'k', mods = 'CTRL|SHIFT', action = l_waction.ClearScrollback 'ScrollbackOnly' },
        --{ key = 'k', mods = 'SUPER', action = l_waction.ClearScrollback 'ScrollbackOnly' },
        { key = 'PageUp', mods = 'SHIFT', action = l_waction.ScrollByPage(-1) },
        { key = 'PageDown', mods = 'SHIFT', action = l_waction.ScrollByPage(1) },
        { key = 'UpArrow', mods = 'CTRL|SHIFT', action = l_waction.ScrollByLine(-1) },
        { key = 'DownArrow', mods = 'CTRL|SHIFT', action = l_waction.ScrollByLine(1) },
        { key = 'Home', mods = 'SHIFT', action = l_waction.ScrollToTop },
        { key = 'End', mods = 'SHIFT', action = l_waction.ScrollToBottom },
        { key = 'z', mods = 'CTRL|SHIFT', action = l_waction.ScrollToPrompt(-1) },
        { key = 'x', mods = 'CTRL|SHIFT', action = l_waction.ScrollToPrompt(1) },

        --5. Gestion de la fuente usado por la terminal
        { key = '+', mods = 'CTRL', action = l_waction.IncreaseFontSize },
        { key = '+', mods = 'CTRL|SHIFT', action = l_waction.IncreaseFontSize },
        { key = '=', mods = 'CTRL', action = l_waction.IncreaseFontSize },
        --{ key = '=', mods = 'SUPER', action = l_waction.IncreaseFontSize },
        { key = '-', mods = 'CTRL', action = l_waction.DecreaseFontSize },
        --{ key = '-', mods = 'SUPER', action = l_waction.DecreaseFontSize },
        { key = '0', mods = 'CTRL', action = l_waction.ResetFontSize },
        --{ key = '0', mods = 'SUPER', action = l_waction.ResetFontSize },

        --6. Gestion del clipboard
        { key = 'c', mods = 'CTRL|SHIFT', action = l_waction.CopyTo 'Clipboard' },
        --{ key = 'c', mods = 'SUPER', action = l_waction.CopyTo 'Clipboard' },
        --{ key = 'Copy', mods = 'NONE', action = l_waction.CopyTo 'Clipboard' },

        { key = 'v', mods = 'CTRL|SHIFT', action = l_waction.PasteFrom 'Clipboard' },
        --{ key = 'v', mods = 'SUPER', action = l_waction.PasteFrom 'Clipboard' },
        --{ key = 'Paste', mods = 'NONE', action = l_waction.PasteFrom 'Clipboard' },

        { key = 'Insert', mods = 'CTRL', action = l_waction.CopyTo 'PrimarySelection' },
        { key = 'Insert', mods = 'SHIFT', action = l_waction.PasteFrom 'PrimarySelection' },


        --------------------------------------------------------------------------------
        --2. Gestion del Tab (Window)
        --------------------------------------------------------------------------------

        -- Creation> Crear (create) el panel usando el dominio del panel actual
        { key = 'c', mods = 'LEADER', action = l_waction.SpawnTab('CurrentPaneDomain') },

        -- Creation> Crear (create) el panel usado el dominio por defecto
        { key = 'c', mods = 'LEADER|SHIFT', action = l_waction.SpawnTab('DefaultDomain') },

        -- Creation (interactive)> Usando el 'Domains Fuzzy Laucher'
        { key = 'w', mods = 'LEADER', action = l_waction.ShowLauncherArgs({ flags =  'FUZZY|DOMAINS' }) },

        -- Creation (interactive)> Usando el 'Menu Laucher'
        { key = 'w', mods = 'LEADER|SHIFT', action = l_waction.ShowLauncherArgs({ flags =  'LAUNCH_MENU_ITEMS' }) },

        -- Navegation> Ir a un tab segun su posicion (posicion: indice + 1)
        { key = '1', mods = 'LEADER', action = l_waction.ActivateTab(0) },
        { key = '2', mods = 'LEADER', action = l_waction.ActivateTab(1) },
        { key = '3', mods = 'LEADER', action = l_waction.ActivateTab(2) },
        { key = '4', mods = 'LEADER', action = l_waction.ActivateTab(3) },
        { key = '5', mods = 'LEADER', action = l_waction.ActivateTab(4) },
        { key = '6', mods = 'LEADER', action = l_waction.ActivateTab(5) },
        { key = '7', mods = 'LEADER', action = l_waction.ActivateTab(6) },
        { key = '8', mods = 'LEADER', action = l_waction.ActivateTab(7) },
        { key = '9', mods = 'LEADER', action = l_waction.ActivateTab(8) },
        { key = '0', mods = 'LEADER', action = l_waction.ActivateTab(9) },

        -- Navegation> Ir a ultimo ('end') tab
        { key = 'e', mods = 'LEADER', action = l_waction.ActivateTab(-1) },

        -- Navegation> Ir al next/previous tab
        { key = 'n', mods = 'LEADER', action = l_waction.ActivateTabRelative(1) },
        { key = 'p', mods = 'LEADER', action = l_waction.ActivateTabRelative(-1) },

        -- Swap> Intercambiar de posicion 2 paneles continuos
        { key = '>', mods = 'LEADER|SHIFT', action = l_waction.MoveTabRelative(1) },
        { key = '<', mods = 'LEADER|SHIFT', action = l_waction.MoveTabRelative(-1) },
        { key = '<', mods = 'LEADER', action = l_waction.MoveTabRelative(-1) },

        --{ key = 'w', mods = 'CTRL|SHIFT', action = l_waction.CloseCurrentTab{ confirm = true } },
        --{ key = 'w', mods = 'SUPER', action = l_waction.CloseCurrentTab{ confirm = true } },


        --------------------------------------------------------------------------------
        --3. Gestion del Panel (de un Tab/Window)
        --------------------------------------------------------------------------------

        -- Variados> Fullscreen/Restaurar el tamaño del panel actual 
        { key = 'z', mods = 'LEADER', action = l_waction.TogglePaneZoomState },

        -- Variados> Cerrar el panel actual
        { key = 'x', mods = 'LEADER', action = l_waction.CloseCurrentPane({ confirm = true }) },

        -- Split> Dividir el panel actual verticalmente (crear un panel vertical)
        { key = '"', mods = 'LEADER|SHIFT', action = l_waction.SplitVertical({ domain =  'CurrentPaneDomain' }) },
        { key = '=', mods = 'LEADER', action = l_waction.SplitHorizontal({ domain =  'CurrentPaneDomain' }) },
        { key = '=', mods = 'LEADER|SHIFT', action = l_waction.SplitHorizontal({ domain =  'CurrentPaneDomain' }) },
        { key = '|', mods = 'LEADER', action = l_waction.SplitHorizontal({ domain =  'CurrentPaneDomain' }) },
        { key = '|', mods = 'LEADER|SHIFT', action = l_waction.SplitHorizontal({ domain =  'CurrentPaneDomain' }) },

        -- Split> Dividir el panel actual verticalmente (crear un panel vertical)
        { key = '%', mods = 'LEADER|SHIFT', action = l_waction.SplitHorizontal({ domain =  'CurrentPaneDomain' }) },
        { key = '-', mods = 'LEADER', action = l_waction.SplitVertical({ domain =  'CurrentPaneDomain' }) },

        -- Navegation> Ir al paneles continuo ('←/↓/↑/→' o 'h/j/k/l'
        { key = 'LeftArrow', mods = 'LEADER', action = l_waction.ActivatePaneDirection('Left') },
        { key = 'h', mods = 'LEADER', action = l_waction.ActivatePaneDirection('Left') },

        { key = 'RightArrow', mods = 'LEADER', action = l_waction.ActivatePaneDirection('Right') },
        { key = 'l', mods = 'LEADER', action = l_waction.ActivatePaneDirection('Right') },

        { key = 'UpArrow', mods = 'LEADER', action = l_waction.ActivatePaneDirection('Up') },
        { key = 'k', mods = 'LEADER', action = l_waction.ActivatePaneDirection('Up') },

        { key = 'DownArrow', mods = 'LEADER', action = l_waction.ActivatePaneDirection('Down') },
        { key = 'j', mods = 'LEADER', action = l_waction.ActivatePaneDirection('Down') },

        -- Resizing> Modificar el tamaño de un panel
        { key = 'r', mods = 'LEADER', action = l_waction.ActivateKeyTable({ name = 'resize_pane', one_shot = false, }) },
        --{ key = 'r', mods = 'LEADER', action = l_waction.ActivateKeyTable({ name = 'resize_pane', timeout_milliseconds = 1000, }) },

        -- Rotating > Rotar los paneles segun el sentido horario o antihorario
        { key = '{', mods = 'LEADER|SHIFT', action = l_waction.RotatePanes('CounterClockwise') },
        { key = '{', mods = 'LEADER', action = l_waction.RotatePanes('CounterClockwise') },
        { key = '}', mods = 'LEADER|SHIFT', action = l_waction.RotatePanes('Clockwise') },
        { key = '}', mods = 'LEADER', action = l_waction.RotatePanes('Clockwise') },

        --------------------------------------------------------------------------------
        --4. Generales
        --------------------------------------------------------------------------------

        -- Ingresar a un determinado modo
        { key = 'f', mods = 'CTRL|SHIFT', action = l_waction.Search('CurrentSelectionOrEmptyString') },
        --{ key = 'f', mods = 'SUPER', action = l_waction.Search 'CurrentSelectionOrEmptyString' },
        { key = 'phys:Space', mods = 'CTRL|SHIFT', action = l_waction.QuickSelect },
        { key = 'w', mods = 'CTRL|SHIFT', action = l_waction.ActivateCopyMode },
        { key = 'u', mods = 'CTRL|SHIFT', action = l_waction.CharSelect({ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' }) },


        { key = 'd', mods = 'LEADER|SHIFT', action = l_waction.ShowDebugOverlay },
        { key = 'r', mods = 'LEADER|SHIFT', action = l_waction.ReloadConfiguration },
        --{ key = 'a', mods = 'LEADER|CTRL', action = l_waction.SendString('\u{1}') },
        --{ key = 'm', mods = 'CTRL|SHIFT', action = l_waction.Hide },
        --{ key = 'p', mods = 'CTRL|SHIFT', action = l_waction.ActivateCommandPalette },


        --------------------------------------------------------------------------------
        --5. Custom
        --------------------------------------------------------------------------------

        { key = 's', mods = 'LEADER', action = mm_wezterm.action_callback(lm_uworkspace.callback_chose_workspace), },
        { key = 's', mods = 'LEADER|SHIFT', action = mm_wezterm.action_callback(lm_uworkspace.callback_go_to_prev_workspace), },

    }

    return l_keys

end


function mod.get_keytables_mappins()

    local l_waction = mm_wezterm.action

    local l_keytables = {

        --------------------------------------------------------------------------
        -- Modo de copia
        --------------------------------------------------------------------------
        copy_mode = {

          -- Salir del modo copia (de submodo inicial y submodo seleccion)
          { key = 'c', mods = 'CTRL', action = l_waction.Multiple{ 'ScrollToBottom', { CopyMode =  'Close' } } },
          { key = 'g', mods = 'CTRL', action = l_waction.Multiple{ 'ScrollToBottom', { CopyMode =  'Close' } } },
          { key = 'q', mods = 'NONE', action = l_waction.Multiple{ 'ScrollToBottom', { CopyMode =  'Close' } } },
          { key = 'Escape', mods = 'NONE', action = l_waction.Multiple{ 'ScrollToBottom', { CopyMode =  'Close' } } },

          -- Con una seleccion (desde el submodo seleccion), copiar al clipboard y salir de modo copia
          { key = 'y', mods = 'NONE', action = l_waction.Multiple{ { CopyTo =  'ClipboardAndPrimarySelection' }, { Multiple = { 'ScrollToBottom', { CopyMode =  'Close' } } } } },

          -- Ingresar la submodo seleccion
          { key = 'Space', mods = 'NONE', action = l_waction.CopyMode{ SetSelectionMode =  'Cell' } },
          { key = 'v', mods = 'NONE', action = l_waction.CopyMode{ SetSelectionMode =  'Cell' } },
          { key = 'v', mods = 'SHIFT', action = l_waction.CopyMode{ SetSelectionMode =  'Line' } },
          { key = 'v', mods = 'CTRL', action = l_waction.CopyMode{ SetSelectionMode =  'Block' } },

          -- Modificar la selección actual horizontalmente (usado frecuentemente en ua selección rectangular)
          { key = 'o', mods = 'NONE', action = l_waction.CopyMode 'MoveToSelectionOtherEnd' },
          { key = 'o', mods = 'SHIFT', action = l_waction.CopyMode 'MoveToSelectionOtherEndHoriz' },

          -- Navegacion basica (en el submodo inicio y selección)
          { key = 'h', mods = 'NONE', action = l_waction.CopyMode 'MoveLeft' },
          { key = 'j', mods = 'NONE', action = l_waction.CopyMode 'MoveDown' },
          { key = 'k', mods = 'NONE', action = l_waction.CopyMode 'MoveUp' },
          { key = 'l', mods = 'NONE', action = l_waction.CopyMode 'MoveRight' },
          { key = 'LeftArrow', mods = 'NONE', action = l_waction.CopyMode 'MoveLeft' },
          { key = 'RightArrow', mods = 'NONE', action = l_waction.CopyMode 'MoveRight' },
          { key = 'UpArrow', mods = 'NONE', action = l_waction.CopyMode 'MoveUp' },
          { key = 'DownArrow', mods = 'NONE', action = l_waction.CopyMode 'MoveDown' },

          -- Moverse en la misma linea actual
          { key = '^', mods = 'NONE', action = l_waction.CopyMode 'MoveToStartOfLineContent' },
          { key = '^', mods = 'SHIFT', action = l_waction.CopyMode 'MoveToStartOfLineContent' },
          { key = 'm', mods = 'ALT', action = l_waction.CopyMode 'MoveToStartOfLineContent' },

          { key = '$', mods = 'NONE', action = l_waction.CopyMode 'MoveToEndOfLineContent' },
          { key = '$', mods = 'SHIFT', action = l_waction.CopyMode 'MoveToEndOfLineContent' },
          { key = 'End', mods = 'NONE', action = l_waction.CopyMode 'MoveToEndOfLineContent' },

          { key = '0', mods = 'NONE', action = l_waction.CopyMode 'MoveToStartOfLine' },
          { key = 'Home', mods = 'NONE', action = l_waction.CopyMode 'MoveToStartOfLine' },

          -- Moverse al inicio de la siguiente linea a la actual
          { key = 'Enter', mods = 'NONE', action = l_waction.CopyMode 'MoveToStartOfNextLine' },

          -- Moverse entre palabras anterior/siguiente
          { key = 'w', mods = 'NONE', action = l_waction.CopyMode 'MoveForwardWord' },
          { key = 'f', mods = 'ALT', action = l_waction.CopyMode 'MoveForwardWord' },
          { key = 'Tab', mods = 'NONE', action = l_waction.CopyMode 'MoveForwardWord' },

          { key = 'b', mods = 'NONE', action = l_waction.CopyMode 'MoveBackwardWord' },
          { key = 'b', mods = 'ALT', action = l_waction.CopyMode 'MoveBackwardWord' },
          { key = 'LeftArrow', mods = 'ALT', action = l_waction.CopyMode 'MoveBackwardWord' },
          { key = 'RightArrow', mods = 'ALT', action = l_waction.CopyMode 'MoveForwardWord' },
          { key = 'Tab', mods = 'SHIFT', action = l_waction.CopyMode 'MoveBackwardWord' },

          { key = 'e', mods = 'NONE', action = l_waction.CopyMode 'MoveForwardWordEnd' },

          -- Moverse verticalmente dentro buffer del scrollback
          { key = 'g', mods = 'NONE', action = l_waction.CopyMode 'MoveToScrollbackBottom' },
          { key = 'g', mods = 'SHIFT', action = l_waction.CopyMode 'MoveToScrollbackBottom' },

          { key = 'b', mods = 'CTRL', action = l_waction.CopyMode 'PageUp' },
          { key = 'PageUp', mods = 'NONE', action = l_waction.CopyMode 'PageUp' },
          { key = 'u', mods = 'CTRL', action = l_waction.CopyMode{ MoveByPage = (-0.5) } },
          { key = 'f', mods = 'CTRL', action = l_waction.CopyMode 'PageDown' },
          { key = 'PageDown', mods = 'NONE', action = l_waction.CopyMode 'PageDown' },
          { key = 'd', mods = 'CTRL', action = l_waction.CopyMode{ MoveByPage = (0.5) } },

          -- Mover el viewport dentro buffer del scrollback
          { key = 'h', mods = 'SHIFT', action = l_waction.CopyMode 'MoveToViewportTop' },
          { key = 'l', mods = 'SHIFT', action = l_waction.CopyMode 'MoveToViewportBottom' },
          { key = 'm', mods = 'SHIFT', action = l_waction.CopyMode 'MoveToViewportMiddle' },

          -- Navegacion por ¿busqueda?
          { key = ',', mods = 'NONE', action = l_waction.CopyMode 'JumpReverse' },
          { key = ';', mods = 'NONE', action = l_waction.CopyMode 'JumpAgain' },
          { key = 'f', mods = 'NONE', action = l_waction.CopyMode{ JumpForward = { prev_char = false } } },
          --{ key = 'f', mods = 'SHIFT', action = l_waction.CopyMode{ JumpBackward = { prev_char = false } } },
          { key = 't', mods = 'NONE', action = l_waction.CopyMode{ JumpForward = { prev_char = true } } },
          --{ key = 't', mods = 'SHIFT', action = l_waction.CopyMode{ JumpBackward = { prev_char = true } } },


        },

        --------------------------------------------------------------------------
        -- Modo de busqueda
        --------------------------------------------------------------------------
        search_mode = {
          -- Cambia el modo de búsqueda, reiniciando la búsqueda. Los modos de busqueda: "case-sensitive", "case-inssensitive" y "expresiones regulares".
          { key = 'r', mods = 'CTRL', action = l_waction.CopyMode 'CycleMatchType' },
          -- Salir del modo de Busqeuda
          { key = 'Escape', mods = 'NONE', action = l_waction.CopyMode 'Close' },
          -- Resetear la búsqueda (Limpia el criterio de búsqueda actual, pero no sale del modo de búsqueda)
          { key = 'u', mods = 'CTRL', action = l_waction.CopyMode 'ClearPattern' },
          -- Busqueda de la siguiente/anterior coincidencia:
          { key = 'p', mods = 'CTRL', action = l_waction.CopyMode 'PriorMatch' },
          { key = 'Enter', mods = 'NONE', action = l_waction.CopyMode 'PriorMatch' },
          { key = 'UpArrow', mods = 'NONE', action = l_waction.CopyMode 'PriorMatch' },
          { key = 'DownArrow', mods = 'NONE', action = l_waction.CopyMode 'NextMatch' },
          { key = 'n', mods = 'CTRL', action = l_waction.CopyMode 'NextMatch' },
          { key = 'PageUp', mods = 'NONE', action = l_waction.CopyMode 'PriorMatchPage' },
          { key = 'PageDown', mods = 'NONE', action = l_waction.CopyMode 'NextMatchPage' },
        },


        --------------------------------------------------------------------------
        -- 'ActivateKeyTable' del modo normal
        --------------------------------------------------------------------------

        resize_pane = {
            -- Incrementar/Reducir de 1 en 1
            { key = 'LeftArrow', mods = 'NONE', action = l_waction.AdjustPaneSize({ 'Left', 1 }) },
            { key = 'h', mods = 'NONE', action = l_waction.AdjustPaneSize({ 'Left', 1 }) },

            { key = 'RightArrow', mods = 'NONE', action = l_waction.AdjustPaneSize({ 'Right', 1 }) },
            { key = 'l', mods = 'NONE', action = l_waction.AdjustPaneSize({ 'Right', 1 }) },

            { key = 'UpArrow', mods = 'NONE', action = l_waction.AdjustPaneSize({ 'Up', 1 }) },
            { key = 'k', mods = 'NONE', action = l_waction.AdjustPaneSize({ 'Up', 1 }) },

            { key = 'DownArrow', mods = 'NONE', action = l_waction.AdjustPaneSize({ 'Down', 1 }) },
            { key = 'j', mods = 'NONE', action = l_waction.AdjustPaneSize({ 'Down', 1 }) },

            -- Incrementar/Reducir de 5 en 5
            { key = 'LeftArrow', mods = 'SHIFT', mods = 'SHIFT', action = l_waction.AdjustPaneSize({ 'Left', 5 }) },
            { key = 'h', mods = 'SHIFT', action = l_waction.AdjustPaneSize({ 'Left', 5 }) },

            { key = 'RightArrow', mods = 'SHIFT', action = l_waction.AdjustPaneSize({ 'Right', 5 }) },
            { key = 'l', mods = 'SHIFT', action = l_waction.AdjustPaneSize({ 'Right', 5 }) },

            { key = 'UpArrow', mods = 'SHIFT', action = l_waction.AdjustPaneSize({ 'Up', 5 }) },
            { key = 'k', mods = 'SHIFT', action = l_waction.AdjustPaneSize({ 'Up', 5 }) },

            { key = 'DownArrow', mods = 'SHIFT', action = l_waction.AdjustPaneSize({ 'Down', 5 }) },
            { key = 'j', mods = 'SHIFT', action = l_waction.AdjustPaneSize({ 'Down', 5 }) },

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
