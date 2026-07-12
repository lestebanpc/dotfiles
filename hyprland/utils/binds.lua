-- Miembros publicos del modulo
local mod = {}

-- Miembros privados de inicializacion (modificables por el usuario del modulo)
--local m_custom = {
--    data_1 = nil,
--}

-- Miembros privados constantes
--local mm_ucommon = require("utils.common")

-- Miembros privados no constantes
--local m_data_2 = nil



------------------------------------------------------------------------------------
-- Module Inicialization
------------------------------------------------------------------------------------

--function mod.setup(
--    p_data_1)
--
--    m_custom.data_1 = p_data_1
--
--end



------------------------------------------------------------------------------------
-- Keybindings> Monitor
------------------------------------------------------------------------------------

-- Monitor navigation
hl.bind("SUPER + CTRL + Left",  hl.dsp.focus({ monitor = "l" }))
hl.bind("SUPER + CTRL + Right", hl.dsp.focus({ monitor = "r" }))

hl.bind("SUPER + CTRL + H",     hl.dsp.focus({ monitor = "l" }))
hl.bind("SUPER + CTRL + J",     hl.dsp.focus({ monitor = "d" }))
hl.bind("SUPER + CTRL + K",     hl.dsp.focus({ monitor = "u" }))
hl.bind("SUPER + CTRL + L",     hl.dsp.focus({ monitor = "r" }))

-- Move active window to another monitor
hl.bind("SUPER + SHIFT + CTRL + Left",  hl.dsp.window.move({ monitor = "l" }))
hl.bind("SUPER + SHIFT + CTRL + Down",  hl.dsp.window.move({ monitor = "d" }))
hl.bind("SUPER + SHIFT + CTRL + Up",    hl.dsp.window.move({ monitor = "u" }))
hl.bind("SUPER + SHIFT + CTRL + Right", hl.dsp.window.move({ monitor = "r" }))

hl.bind("SUPER + SHIFT + CTRL + H",     hl.dsp.window.move({ monitor = "l" }))
hl.bind("SUPER + SHIFT + CTRL + J",     hl.dsp.window.move({ monitor = "d" }))
hl.bind("SUPER + SHIFT + CTRL + K",     hl.dsp.window.move({ monitor = "u" }))
hl.bind("SUPER + SHIFT + CTRL + L",     hl.dsp.window.move({ monitor = "r" }))



------------------------------------------------------------------------------------
-- Keybindings> Workspace
------------------------------------------------------------------------------------

--1. Workspace Management

-- Rename current workspace
hl.bind("CTRL + SHIFT + R", hl.dsp.exec_cmd("dms ipc call workspace-rename open"))

-- Switch a previos/next workspace
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + Page_Up",   hl.dsp.focus({ workspace = "e-1" }))

-- Switch a previous/next using mouse wheel
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

for i = 1, 9 do
    -- Switch to numbered workspace
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = tostring(i) }))

    -- Move active windows to numbered workspace
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

--2. Move active window to workspace

-- Move active window to previous/next workspace
hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + Page_Up",   hl.dsp.window.move({ workspace = "e-1" }))

-- Move active window to previous/next workspace using mouse wheel
hl.bind("SUPER + CTRL + mouse_down",  hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + CTRL + mouse_up",    hl.dsp.window.move({ workspace = "e-1" }))



------------------------------------------------------------------------------------
-- Keybindings> Window Management
------------------------------------------------------------------------------------

--1. Window Management
hl.bind("SUPER + Q",         hl.dsp.window.close())
hl.bind("SUPER + F",         hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ action = "unset" }))
hl.bind("SUPER + SHIFT + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("dms ipc call window-rules toggle"))

local function m_rotate()

    -- Obtener el workspace actual
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not workspace then
        return
    end

    local layout = workspace.tiled_layout

    if layout == "dwindle" then
        -- Swap (intercambia) la orientacion (vertical/horizantal) de los 2 ventanas split actual dentro del arbol dwindle
        hl.dispatch(hl.dsp.layout("togglesplit"))
    elseif layout == "master" then
        -- Swap intercambia la ventana slave actual como master.
        hl.dispatch(hl.dsp.layout("swapwithmaster"))
    end

end

hl.bind("SUPER + R", m_rotate)


--2. Focus Navigation (within same workspace)

-- Focus to the nearby window
hl.bind("SUPER + Left",  hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + Down",  hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + Up",    hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" }))

hl.bind("SUPER + H",     hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + J",     hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + K",     hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + L",     hl.dsp.focus({ direction = "r" }))

-- Focus to specific window
--bind = SUPER, Home, focuswindow, first
--bind = SUPER, End, focuswindow, last

-- Focus by layout
local function m_focus_next()

    -- Obtener el workspace actual
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not workspace then
        return
    end

    local layout = workspace.tiled_layout

    if layout == "master" or layout == "monacle" then
        -- Establecer la ventana activa a la siguiente a la actual, segun el layout
        hl.dispatch(hl.dsp.layout("cyclenext"))
    else
        -- Establecer la ventana activa a la ventana derecha de la actual, segun su posicion fisica en el layout.
        hl.dispatch(hl.dsp.focus({ direction = "r" }))
    end

end

local function m_focus_previous()

    -- Obtener el workspace actual
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not workspace then
        return
    end

    local layout = workspace.tiled_layout

    if layout == "master" or layout == "monacle" then
        -- Establecer la ventana activa a la previa a la actual, segun el layout
        hl.dispatch(hl.dsp.layout("cycleprv"))
    else
        -- Establecer la ventana activa a la ventana izquierda de la actual, segun su posicion fisica en el layout.
        hl.dispatch(hl.dsp.focus({ direction = "l" }))
    end

end

hl.bind("SUPER + N", m_focus_next)
hl.bind("SUPER + P", m_focus_previous)

--3. Move active window (within same workspace)
local function m_window_move_right()

    -- Obtener el workspace actual
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not workspace then
        return
    end

    local layout = workspace.tiled_layout

    if layout == "scrolling" then
        -- Swap (intercambiar) el orden de la columna/ventana actual con su columna/ventana a la derecha
        hl.dispatch(hl.dsp.layout("swapcol r"))
    else
        -- Intenta mover la ventana actual hacia la derecha, segun su posicion fisica en el layout.
        hl.dispatch(hl.dsp.window.move({ direction = "r" }))
    end

end

local function m_window_move_left()

    -- Obtener el workspace actual
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not workspace then
        return
    end

    local layout = workspace.tiled_layout

    if layout == "scrolling" then
        -- Swap (intercambiar) el orden de la columna/ventana actual con su columna/ventana a la izquiera
        hl.dispatch(hl.dsp.layout("swapcol l"))
    else
        -- Intenta mover la ventana actual hacia la izquierda, segun su posicion fisica en el layout.
        hl.dispatch(hl.dsp.window.move({ direction = "l" }))
    end

end

hl.bind("SUPER + SHIFT + Left",  m_window_move_left)
hl.bind("SUPER + SHIFT + Down",  hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + Up",    hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + Right", m_window_move_right)

hl.bind("SUPER + SHIFT + H",     m_window_move_left)
hl.bind("SUPER + SHIFT + J",     hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + K",     hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + L",     m_window_move_right)


-- Swapping
local function m_swap_right()

    -- Obtener el workspace actual
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not workspace then
        return
    end

    local layout = workspace.tiled_layout

    if layout == "dwindle" then
        -- Swap (intercambia) la posicion de los 2 ventanas split actual dentro del arbol dwindle
        hl.dispatch(hl.dsp.layout("swapsplit"))
    elseif layout == "scrolling" then
        -- Swap (intercambiar) el orden de la columna/ventana actual con su columna/ventana a la derecha
        hl.dispatch(hl.dsp.layout("swapcol r"))
    elseif layout == "master" then
        -- Swap intercambia la ventana actual con la siguiente del segun el layout master.
        hl.dispatch(hl.dsp.layout("swapnext"))
    end

end

local function m_swap_left()

    -- Obtener el workspace actual
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    if not workspace then
        return
    end

    local layout = workspace.tiled_layout

    if layout == "dwindle" then
        -- Swap (intercambia) la posicion de los 2 ventanas split actual dentro del arbol dwindle
        hl.dispatch(hl.dsp.layout("swapsplit"))
    elseif layout == "scrolling" then
        -- Swap (intercambiar) el orden de la columna/ventana actual con su columna/ventana a la derecha
        hl.dispatch(hl.dsp.layout("swapcol l"))
    elseif layout == "master" then
        -- Swap intercambia la ventana anterior con la siguiente del segun el layout master.
        hl.dispatch(hl.dsp.layout("swapprev"))
    end

end

hl.bind("SUPER + SHIFT + P",  m_swap_left)
hl.bind("SUPER + SHIFT + N", m_swap_right)



--4. Windows Groups managment
--   Si la ventana actual pertenece al grupo, cualquier ventana creada tambien pertencera al grupo.

-- Si la ventana actual NO pertenece a un grupo, crea un grupo con la ventana.
-- Si la ventana pertenece a un grupo, elimina el grupo y las ventanas se organizan segun el layout.
hl.bind("SUPER + W", hl.dsp.group.toggle())

-- > Si esta en el grupo, sale del grupo y coloca la ventana en la direccion indicada ('moveintogroup').
-- > Si no esta en el grupo:
--   > Busca el grupo cercano en la direccion indicada para que se una a este grupo (moveoutgroup).
--   > Si no encuentra el grupo, solo mueve la ventana ('movewindow')
hl.bind("SUPER + ALT + Left",  hl.dsp.window.move({ direction = "l", group_aware = true }))
hl.bind("SUPER + ALT + Down",  hl.dsp.window.move({ direction = "d", group_aware = true }))
hl.bind("SUPER + ALT + Up",    hl.dsp.window.move({ direction = "u", group_aware = true }))
hl.bind("SUPER + ALT + Right", hl.dsp.window.move({ direction = "r", group_aware = true }))

hl.bind("SUPER + ALT + H",     hl.dsp.window.move({ direction = "l", group_aware = true }))
hl.bind("SUPER + ALT + J",     hl.dsp.window.move({ direction = "d", group_aware = true }))
hl.bind("SUPER + ALT + K",     hl.dsp.window.move({ direction = "u", group_aware = true }))
hl.bind("SUPER + ALT + L",     hl.dsp.window.move({ direction = "r", group_aware = true }))

-- Switch a previos/next windows in group
hl.bind("SUPER + ALT + Page_Up", hl.dsp.group.next())
hl.bind("SUPER + ALT + Page_Down", hl.dsp.group.prev())

hl.bind("SUPER + ALT + N", hl.dsp.group.next())
hl.bind("SUPER + ALT + P", hl.dsp.group.prev())

--5. Orientation of the new window
hl.bind("SUPER + bracketleft",  hl.dsp.layout("preselect l"))
hl.bind("SUPER + bracketright", hl.dsp.layout("preselect r"))


--7. Moving & Sizing

-- Move active windows with mouse (LMB/RMB and dragging)
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- Resize windows with mouse (LMB/RMB and dragging)
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Force full-screen
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen({ action = "set" }))

-- Resize windows with mouse (LMB/RMB and dragging)
hl.bind("SUPER + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })

-- Manual Sizing
hl.bind("SUPER + minus",  hl.dsp.window.resize({ x = -1, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + equal",  hl.dsp.window.resize({ x = 1, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -1, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 1, relative = true }), { repeating = true })



------------------------------------------------------------------------------------
-- Keybindings> System Application Launchers
------------------------------------------------------------------------------------

--
hl.bind("SUPER + Space",   hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind("SUPER + V",       hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind("SUPER + comma",   hl.dsp.exec_cmd("dms ipc call settings focusOrToggle"))
hl.bind("SUPER + M",       hl.dsp.exec_cmd("dms ipc call notifications toggle"))
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("dms ipc call notepad toggle"))
hl.bind("SUPER + Y",       hl.dsp.exec_cmd("dms ipc call dankdash wallpaper"))
hl.bind("SUPER + Tab",     hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"))

-- Muestra/cierra el "Power Menu"
hl.bind("SUPER + X",       hl.dsp.exec_cmd("dms ipc call powermenu toggle"))

-- Apagar o encender el monitor
hl.bind("SUPER + SHIFT + U", hl.dsp.dpms({ action = "toggle" }))

-- Muestra/cierra el "Keybinding List"
hl.bind("SUPER + SHIFT + Slash", hl.dsp.exec_cmd("dms ipc call keybinds toggle hyprland"))

-- Bloquear la pantalla (no se usa ALT pues se usara para grupos de ventanas)
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("dms ipc call lock lock"))

-- Cierra la sesion actual
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())

-- Muestra/cierra el "Process List"
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("dms screenshot --stdout | satty --filename -"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("dms screenshot full"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("dms screenshot window"))

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 3"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 3"), { repeating = true })
hl.bind("CTRL + XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call mpris increment 3"), { repeating = true })
hl.bind("CTRL + XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call mpris decrement 3"), { repeating = true })

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("dms ipc call audio micmute"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("dms ipc call mpris playPause"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("dms ipc call mpris playPause"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("dms ipc call mpris previous"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("dms ipc call mpris next"))

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("dms ipc call brightness increment 5 \"\""), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("dms ipc call brightness decrement 5 \"\""), { repeating = true })



------------------------------------------------------------------------------------
-- Keybindings> System Application Launchers
------------------------------------------------------------------------------------

-- User launchers
hl.bind("SUPER + T", hl.dsp.exec_cmd("footclient"))

-- Color picker (Copiar al clipboard el RGB en formato hexadecimal, ejemplo 'FF8040')
--hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("dms color pick -o \"{0}{1}{2}\" -a"))

-- Optional: if you use submaps later
-- hl.bind("SUPER + Escape", hl.dsp.submap("reset"))



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
