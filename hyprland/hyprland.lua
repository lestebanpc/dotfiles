-- ~/.config/hypr/hyprland.lua
-- Versión corregida para Hyprland 0.55+ (Lua)

-- ============================================================
--  VARIABLES DE COLOR
-- ============================================================

local primary = "rgb(42a5f5)"
local outline = "rgb(8c9199)"
local error   = "rgb(f2b8b5)"

-- ============================================================
--  MONITORES
-- ============================================================

hl.monitor({
    output = "DP-1",
    mode = "preferred",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "preferred",
    position = "3440x0",
    scale = 1.25,
})

-- Opcionales:
-- hl.monitor({ output = "DP-1", mode = "3440x1440@99.982", position = "0x0", scale = 1, vrr = 0 })
-- hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@59.951", position = "3440x0", scale = 1.25, vrr = 0 })

-- ============================================================
--  VARIABLES / DECORACIÓN / LAYOUTS
-- ============================================================

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "altgr-intl",
        numlock_by_default = true,
    },

    general = {
        gaps_in = 1,
        gaps_out = 2,
        border_size = 1,
        layout = "dwindle",
        ["col.active_border"] = primary,
        ["col.inactive_border"] = outline,
    },

    decoration = {
        rounding = 8,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 30,
            render_power = 5,
            offset = "0 5",
            color = "rgba(00000070)",
        },
    },

    animations = {
        enabled = true,
        animation = {
            "windowsIn, 1, 3, default",
            "windowsOut, 1, 3, default",
            "workspaces, 1, 5, default",
            "windowsMove, 1, 4, default",
            "fade, 1, 3, default",
            "border, 1, 3, default",
        },
    },

    dwindle = {
        preserve_split = true,
        force_split = 2,
    },

    master = {
        mfact = 0.5,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

    scrolling = {
        direction = "right",
    },
})

-- Variables de entorno
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("GTK_APPLICATION_PREFER_DARK_THEME", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
-- SSH_AUTH_SOCK se define fuera de Hyprland, por ejemplo en environment.d

-- ============================================================
--  AUTOSTART
-- ============================================================

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
end)

-- ============================================================
--  WORKSPACES
-- ============================================================

local function ws(id, monitor, layout, default)
    local rule = { workspace = tostring(id), monitor = monitor }
    if layout ~= nil then
        rule.layout = layout
    end
    if default ~= nil then
        rule.default = default
    end
    hl.workspace_rule(rule)
end

for i = 1, 7 do
    ws(i, "DP-1", nil, i == 1)
end

ws(8, "HDMI-A-1", "scrolling", true)
ws(9, "HDMI-A-1", "scrolling", false)

-- ============================================================
--  WINDOW RULES
-- ============================================================

local function wr(match, effects)
    effects.match = match
    hl.window_rule(effects)
end

-- Terminal WezTerm
wr({ class = "^(org%.wezfurlong%.wezterm)$" }, { tile = true })

-- GNOME apps
wr({ class = "^(org%.gnome%..*)$" }, { rounding = 12 })

-- Utilities
wr({ class = "^(gnome%-control%-center)$" }, { tile = true })
wr({ class = "^(pavucontrol)$" }, { tile = true })
wr({ class = "^(nm%-connection%-editor)$" }, { tile = true })

-- Floating apps
wr({ class = "^(org%.gnome%.Calculator)$" }, { float = true })
wr({ class = "^(gnome%-calculator)$" }, { float = true })
wr({ class = "^(galculator)$" }, { float = true })
wr({ class = "^(blueman%-manager)$" }, { float = true })
wr({ class = "^(org%.gnome%.Nautilus)$" }, { float = true })
wr({ class = "^(xdg%-desktop%-portal)$" }, { float = true })

-- Steam notifications
wr({ class = "^(steam)$", title = "^(notificationtoasts.*)$" }, { no_initial_focus = true, pin = true })

-- Firefox PiP
wr({ class = "^(firefox)$", title = "^(Picture%-in%-Picture)$" }, { float = true })

-- Zoom
wr({ class = "^(zoom)$" }, { float = true })

-- Specific apps
wr({ class = "^(com%.gabm%.satty)$" }, { float = true, min_size = { 1000, 600 } })
wr({ class = "^(imv)$" }, { float = true })
wr({ class = "^(org%.pwmt%.zathura)$" }, { float = true })
wr({ class = "^(mpv)$" }, { float = true })

-- remote-viewer (SPICE)
wr({ class = "^(remote%-viewer)$", title = "^(SPICE fullscreen.*)$" }, { workspace = "8", fullscreen = true })
wr({ class = "^(remote%-viewer)$", title = "^(SPICE screen 8:5.*)$" }, { float = true, size = { 1680, 1080 }, move = { "(monitor_w-1684)", "45" } })
wr({ class = "^(remote%-viewer)$", title = "^(SPICE screen 16:9.*)$" }, { float = true, size = { 1714, 1016 }, move = { "(monitor_w-1718)", "45" } })

-- scrcpy (Android)
wr({ class = "^(scrcpy)$", title = "^(Android fullscreen.*)$" }, { workspace = "9", fullscreen = true })
wr({ class = "^(scrcpy)$", title = "^(Android screen 3:2.*)$" }, { float = true, size = { 1714, 1148 }, move = { "(monitor_w-1718)", "45" } })
wr({ class = "^(scrcpy)$", title = "^(Android screen 9:20.*)$" }, { float = true, size = { 602, 1342 }, move = { "(monitor_w-606)", "45" } })
wr({ class = "^(scrcpy)$", title = "^(Android screen 20:9.*)$" }, { float = true, size = { 1714, 778 }, move = { "(monitor_w-1718)", "45" } })

-- FreeRDP
wr({ class = "^(freerdp_x11_full)$" }, { workspace = "8", fullscreen = true })
wr({ class = "^(freerdp_sdl_full)$" }, { workspace = "8", fullscreen = true })

wr({ class = "^(freerdp_x11_85)$" }, { float = true, size = { 1680, 1050 }, move = { "(monitor_w-1684)", "45" } })
wr({ class = "^(freerdp_sdl_85)$" }, { float = true, size = { 1680, 1050 }, move = { "(monitor_w-1684)", "45" } })

wr({ class = "^(freerdp_x11_169)$" }, { float = true, size = { 1714, 986 }, move = { "(monitor_w-1718)", "45" } })
wr({ class = "^(freerdp_sdl_169)$" }, { float = true, size = { 1714, 986 }, move = { "(monitor_w-1718)", "45" } })

-- Layer rules
hl.layer_rule({ match = { namespace = "^(quickshell)$" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^dms:.*$" }, no_anim = true })

-- ============================================================
--  BINDINGS
-- ============================================================

local function e(cmd)
    return hl.dsp.exec_cmd(cmd)
end

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

-- Workspace rename / switch / move
hl.bind("CTRL + SHIFT + R", e("dms ipc call workspace-rename open"))

for i = 1, 9 do
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + Page_Up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + U",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + I",         hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind("SUPER + CTRL + Down",  hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + CTRL + Up",    hl.dsp.window.move({ workspace = "e-1" }))
hl.bind("SUPER + CTRL + U",     hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + CTRL + I",     hl.dsp.window.move({ workspace = "e-1" }))
hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + Page_Up",   hl.dsp.window.move({ workspace = "e-1" }))
hl.bind("SUPER + SHIFT + U",         hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + I",         hl.dsp.window.move({ workspace = "e-1" }))
hl.bind("SUPER + CTRL + mouse_down",  hl.dsp.window.move({ workspace = "e+1" }))
hl.bind("SUPER + CTRL + mouse_up",    hl.dsp.window.move({ workspace = "e-1" }))

-- Window management
hl.bind("SUPER + Q",         hl.dsp.window.close())
hl.bind("SUPER + F",         hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ action = "unset" }))
hl.bind("SUPER + SHIFT + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + W", e("dms ipc call window-rules toggle"))

hl.bind("SUPER + Left",  hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + Down",  hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + Up",    hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + H",     hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + J",     hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + K",     hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + L",     hl.dsp.focus({ direction = "r" }))

hl.bind("SUPER + SHIFT + Left",  hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + Down",  hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + Up",    hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + H",     hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + J",     hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + K",     hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + L",     hl.dsp.window.move({ direction = "r" }))

hl.bind("SUPER + W", hl.dsp.group.toggle())
hl.bind("SUPER + ALT + Left",  hl.dsp.window.move({ direction = "l", group_aware = true }))
hl.bind("SUPER + ALT + Down",  hl.dsp.window.move({ direction = "d", group_aware = true }))
hl.bind("SUPER + ALT + Up",    hl.dsp.window.move({ direction = "u", group_aware = true }))
hl.bind("SUPER + ALT + Right", hl.dsp.window.move({ direction = "r", group_aware = true }))
hl.bind("SUPER + ALT + H",     hl.dsp.window.move({ direction = "l", group_aware = true }))
hl.bind("SUPER + ALT + J",     hl.dsp.window.move({ direction = "d", group_aware = true }))
hl.bind("SUPER + ALT + K",     hl.dsp.window.move({ direction = "u", group_aware = true }))
hl.bind("SUPER + ALT + L",     hl.dsp.window.move({ direction = "r", group_aware = true }))

hl.bind("SUPER + bracketleft",  hl.dsp.layout("preselect l"))
hl.bind("SUPER + bracketright", hl.dsp.layout("preselect r"))
hl.bind("SUPER + R", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen({ action = "set" }))

-- Mouse binds
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Repeating resize with keys
hl.bind("SUPER + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })

hl.bind("SUPER + minus",  hl.dsp.window.resize({ x = -1, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + equal",  hl.dsp.window.resize({ x = 1, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -1, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 1, relative = true }), { repeating = true })

-- System / launchers
hl.bind("SUPER + Space",   e("dms ipc call spotlight toggle"))
hl.bind("SUPER + V",       e("dms ipc call clipboard toggle"))
hl.bind("SUPER + M",       e("dms ipc call processlist focusOrToggle"))
hl.bind("SUPER + comma",   e("dms ipc call settings focusOrToggle"))
hl.bind("SUPER + N",       e("dms ipc call notifications toggle"))
hl.bind("SUPER + SHIFT + N", e("dms ipc call notepad toggle"))
hl.bind("SUPER + Y",       e("dms ipc call dankdash wallpaper"))
hl.bind("SUPER + Tab",     e("dms ipc call hypr toggleOverview"))
hl.bind("SUPER + X",       e("dms ipc call powermenu toggle"))
hl.bind("SUPER + SHIFT + P", hl.dsp.dpms({ action = "toggle" }))
hl.bind("SUPER + SHIFT + Slash", e("dms ipc call keybinds toggle hyprland"))
hl.bind("SUPER + SHIFT + B", e("dms ipc call lock lock"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())
hl.bind("CTRL + ALT + Delete", e("dms ipc call processlist focusOrToggle"))

hl.bind("Print", e("dms screenshot --stdout | satty --filename -"))
hl.bind("CTRL + Print", e("dms screenshot full"))
hl.bind("ALT + Print", e("dms screenshot window"))

-- Audio
hl.bind("XF86AudioRaiseVolume", e("dms ipc call audio increment 3"), { repeating = true })
hl.bind("XF86AudioLowerVolume", e("dms ipc call audio decrement 3"), { repeating = true })
hl.bind("CTRL + XF86AudioRaiseVolume", e("dms ipc call mpris increment 3"), { repeating = true })
hl.bind("CTRL + XF86AudioLowerVolume", e("dms ipc call mpris decrement 3"), { repeating = true })

hl.bind("XF86AudioMute", e("dms ipc call audio mute"))
hl.bind("XF86AudioMicMute", e("dms ipc call audio micmute"))
hl.bind("XF86AudioPause", e("dms ipc call mpris playPause"))
hl.bind("XF86AudioPlay", e("dms ipc call mpris playPause"))
hl.bind("XF86AudioPrev", e("dms ipc call mpris previous"))
hl.bind("XF86AudioNext", e("dms ipc call mpris next"))

-- Brightness
hl.bind("XF86MonBrightnessUp", e("dms ipc call brightness increment 5 \"\""), { repeating = true })
hl.bind("XF86MonBrightnessDown", e("dms ipc call brightness decrement 5 \"\""), { repeating = true })

-- User launchers
hl.bind("SUPER + T", e("footclient"))
hl.bind("SUPER + SHIFT + C", e("dms color pick -o \"{0}{1}{2}\" -a"))

-- Optional: if you use submaps later
-- hl.bind("SUPER + Escape", hl.dsp.submap("reset"))
