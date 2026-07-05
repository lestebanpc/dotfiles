-- ~/.config/hypr/hyprland.lua
-- Configuración de Hyprland (versión 0.55+ en Lua)
-- https://wiki.hypr.land/Configuring/

-- ============================================================
--  MONITOR CONFIG
-- ============================================================

-- Monitor principal: Samsung C34H89x (3440x1440)
-- Monitor secundario: Porpoise HT-1730XT (2560x1440)
-- (La línea de HDMI tiene un typo intencionado, se mantiene igual)
hl.config({
    monitor = {
        "DP-1, preferred, 0x0, 1",
        "HMDI-A-1, preferred, 3440x0, 1.25",
        -- Opciones alternativas con VRR (comentadas)
        -- "DP-1, 3440x1440@99.982, 0x0, 1, vrr, 0",
        -- "HDMI-A-1, 2560x1440@59.951, 3440x0, 1.25, vrr, 0",
    },

-- ============================================================
--  STARTUP APPS (Variables de entorno y ejecuciones únicas)
-- ============================================================

    -- Tema oscuro para aplicaciones GTK
    env = {
        "GTK_THEME,Adwaita:dark",
        "GTK_APPLICATION_PREFER_DARK_THEME,1",
        -- Tema oscuro para aplicaciones Qt6
        "QT_QPA_PLATFORMTHEME,qt6ct",
        "QT_STYLE_OVERRIDE,kvantum",
        -- Nota: SSH_AUTH_SOCK se define en ~/.config/environment.d/91-myvars.conf
    },

    -- Comandos que se ejecutan una sola vez al inicio
    exec-once = {
        -- Propaga las variables de entorno a D-BUS y systemd
        "dbus-update-activation-environment --systemd --all",
        -- Activa el target hyprland-session.target para iniciar servicios
        "systemctl --user start hyprland-session.target",
    },

-- ============================================================
--  INPUT CONFIG
-- ============================================================

    input = {
        kb_layout     = "us",
        kb_variant    = "altgr-intl",
        numlock_by_default = true,
    },

-- ============================================================
--  GENERAL LAYOUT
-- ============================================================

    general = {
        ["gaps_in"]        = 1,   -- Espacio entre ventana y borde del monitor
        ["gaps_out"]       = 2,   -- Espacio entre ventanas
        ["border_size"]    = 1,
        ["layout"]         = "dwindle",
    },

-- ============================================================
--  DECORATION
-- ============================================================

    decoration = {
        rounding          = 8,
        active_opacity    = 1.0,
        inactive_opacity  = 1.0,
        shadow = {
            enabled      = true,
            range        = 30,
            render_power = 5,
            offset       = "0 5",
            color        = "rgba(00000070)",
        },
    },

-- ============================================================
--  ANIMATIONS
-- ============================================================

    animations = {
        enabled = true,
        -- Cada animación se escribe como una cadena con los parámetros
        animation = {
            "windowsIn, 1, 3, default",
            "windowsOut, 1, 3, default",
            "workspaces, 1, 5, default",
            "windowsMove, 1, 4, default",
            "fade, 1, 3, default",
            "border, 1, 3, default",
        },
    },

-- ============================================================
--  LAYOUTS
-- ============================================================

    -- Dwindle: distribución dinámica por defecto
    dwindle = {
        preserve_split = true,   -- Mantiene la relación de división al cerrar ventanas
        force_split = 2,         -- 2 = siempre dividir a la derecha/abajo
    },

    -- Master: distribución maestra (no se usa por defecto, pero se deja)
    master = {
        mfact = 0.5,
    },

-- ============================================================
--  MISC (varias opciones)
-- ============================================================

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

-- ============================================================
--  COLORS (variables y asignaciones en general/group)
-- ============================================================

    -- Definimos las variables de color (locales de Lua)
    -- (No se usan con $, se referencian directamente)
    -- Los colores se asignan más abajo en las secciones correspondientes
    -- pero las declaramos aquí para mantener el orden lógico.
    --
    -- Nota: Como las variables son locales, las definimos fuera de hl.config
    -- y luego las usamos dentro. Las pondré aquí arriba para que sea claro.
    --
    -- local primary = "rgb(42a5f5)"
    -- local outline = "rgb(8c9199)"
    -- local error   = "rgb(f2b8b5)"
    --
    -- Pero es mejor definirlas justo antes de usarlas, así que las pondré
    -- en la sección "Colors" más abajo.
    --
    -- Nota: Como 'general' y 'group' ya se usaron, las definiciones de color
    -- se colocan en la misma tabla principal, pero para evitar duplicar 'general'
    -- y 'group', fusionaremos las asignaciones con las ya existentes.
    --
    -- En el archivo original, los colores se definen después de misc,
    -- así que los pondré aquí, reutilizando las tablas general y group.
    --
    -- Por tanto, añadimos las claves color a las tablas ya existentes:
    --

-- (Las tablas general y group se completan a continuación con los colores)
-- Pero como ya definimos general arriba, debemos extenderla.
-- En Lua no podemos extender una tabla después de crearla, así que
-- definimos general con todos sus campos de una vez.
-- Re-definimos general y group con los colores, combinando todo.

-- Para no repetir, voy a reescribir las secciones general y group completas
-- con los colores, y eliminar las anteriores definiciones parciales.
-- Lo haré en el orden original: primero general, luego group.

-- (Reescribo desde el principio para tener todo junto)

-- ============================================================
--  RE-DEFINICIÓN DE GENERAL Y GROUP CON COLORES
-- ============================================================

-- Voy a poner todo en una sola tabla grande, así que redefino las secciones
-- que ya había definido para incluir los colores.

-- Para evitar conflictos, voy a construir la tabla completa de una vez,
-- incluyendo todo lo anterior y añadiendo los colores en las secciones correspondientes.

-- Por claridad, reescribo el archivo entero desde cero, pero manteniendo
-- el orden de las secciones.

-- ============================================================
--  COMIENZO DE LA CONFIGURACIÓN FINAL
-- ============================================================

-- Definimos las variables de color (locales)
local primary = "rgb(42a5f5)"
local outline = "rgb(8c9199)"
local error   = "rgb(f2b8b5)"

-- Ahora la tabla principal
hl.config({
    -- MONITORES (ya definidos)
    monitor = {
        "DP-1, preferred, 0x0, 1",
        "HMDI-A-1, preferred, 3440x0, 1.25",
    },

    -- ENV y EXEC-ONCE (ya definidos)
    env = {
        "GTK_THEME,Adwaita:dark",
        "GTK_APPLICATION_PREFER_DARK_THEME,1",
        "QT_QPA_PLATFORMTHEME,qt6ct",
        "QT_STYLE_OVERRIDE,kvantum",
    },
    exec-once = {
        "dbus-update-activation-environment --systemd --all",
        "systemctl --user start hyprland-session.target",
    },

    -- INPUT
    input = {
        kb_layout = "us",
        kb_variant = "altgr-intl",
        numlock_by_default = true,
    },

    -- GENERAL (con colores)
    general = {
        gaps_in = 1,
        gaps_out = 2,
        border_size = 1,
        layout = "dwindle",
        ["col.active_border"]   = primary,
        ["col.inactive_border"] = outline,
    },

    -- DECORATION
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

    -- ANIMATIONS
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

    -- LAYOUTS
    dwindle = {
        preserve_split = true,
        force_split = 2,
    },
    master = {
        mfact = 0.5,
    },

    -- MISC
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

    -- GROUP (con colores)
    group = {
        ["col.border_active"]   = primary,
        ["col.border_inactive"] = outline,
        ["col.border_locked_active"]   = error,
        ["col.border_locked_inactive"] = outline,
        groupbar = {
            ["col.active"]         = primary,
            ["col.inactive"]       = outline,
            ["col.locked_active"]   = error,
            ["col.locked_inactive"] = outline,
        },
    },

-- ============================================================
--  WORKSPACE Y MONITOR (asignación de workspaces a monitores)
-- ============================================================

    workspace = {
        -- Monitor principal (DP-1) con layout por defecto (dwindle)
        "1, monitor:DP-1, default:true",
        "2, monitor:DP-1",
        "3, monitor:DP-1",
        "4, monitor:DP-1",
        "5, monitor:DP-1",
        "6, monitor:DP-1",
        "7, monitor:DP-1",
        -- Monitor secundario (HDMI-A-1) con layout scrolling
        "8, monitor:HDMI-A-1, layout:scrolling, default:true",
        "9, monitor:HDMI-A-1, layout:scrolling",
        -- Opciones alternativas con layout monacle (comentadas)
        -- "8, monitor:HDMI-A-1, layout:monacle, default:true",
        -- "9, monitor:HDMI-A-1, layout:monacle",
    },

-- ============================================================
--  WINDOW RULES (reglas de ventanas)
-- ============================================================

    windowrule = {
        -- Terminal WezTerm: siempre en modo tile
        "tile on, match:class ^(org\\.wezfurlong\\.wezterm)$",

        -- Todas las aplicaciones GNOME: redondeo específico
        "rounding 12, match:class ^(org\\.gnome\\.)",

        -- Ventanas de configuración y utilidades: tile
        "tile on, match:class ^(gnome-control-center)$",
        "tile on, match:class ^(pavucontrol)$",
        "tile on, match:class ^(nm-connection-editor)$",

        -- Aplicaciones que deben ser flotantes
        "float on, match:class ^(org\\.gnome\\.Calculator)$",
        "float on, match:class ^(gnome-calculator)$",
        "float on, match:class ^(galculator)$",
        "float on, match:class ^(blueman-manager)$",
        "float on, match:class ^(org\\.gnome\\.Nautilus)$",
        "float on, match:class ^(xdg-desktop-portal)$",

        -- Steam: notificaciones sin foco y ancladas
        "no_initial_focus on, match:class ^(steam)$, match:title ^(notificationtoasts)",
        "pin on, match:class ^(steam)$, match:title ^(notificationtoasts)",

        -- Firefox: Picture-in-Picture flotante
        "float on, match:class ^(firefox)$, match:title ^(Picture-in-Picture)$",

        -- Zoom: flotante
        "float on, match:class ^(zoom)$",

        -- Capas (layer rules)
        -- Quickshell y dms: sin animaciones
        "no_anim on, match:namespace ^(quickshell)$",
        "no_anim on, match:namespace ^dms:.*",

        -- ============================================================
        --  REGLAS ESPECÍFICAS POR PROGRAMA
        -- ============================================================

        -- Satty (screenshots): flotante con tamaño mínimo
        "match:class ^(com\\.gabm\\.satty)$, float on",
        "match:class ^(com\\.gabm\\.satty)$, min_size 1000 600",

        -- Visor de imágenes imv: flotante
        "match:class ^(imv)$, float on",
        -- Visor de PDFs zathura: flotante
        "match:class ^(org\\.pwmt\\.zathura)$, float on",
        -- Reproductor mpv: flotante
        "match:class ^(mpv)$, float on",

        -- ============================================================
        --  REGLAS PARA remote-viewer (SPICE)
        -- ============================================================

        -- Modo fullscreen 16:9 → workspace 8
        "match:class ^(remote-viewer)$, match:title ^(SPICE fullscreen.*)$, workspace 8",
        "match:class ^(remote-viewer)$, match:title ^(SPICE fullscreen.*)$, fullscreen on",

        -- Modo pantalla 8:5 → flotante, tamaño y posición fijos
        "match:class ^(remote-viewer)$, match:title ^(SPICE screen 8:5.*)$, float on",
        "match:class ^(remote-viewer)$, match:title ^(SPICE screen 8:5.*)$, size 1680 1080",
        "match:class ^(remote-viewer)$, match:title ^(SPICE screen 8:5.*)$, move (monitor_w-1684) 45",

        -- Modo pantalla 16:9 → flotante, tamaño y posición fijos
        "match:class ^(remote-viewer)$, match:title ^(SPICE screen 16:9.*)$, float on",
        "match:class ^(remote-viewer)$, match:title ^(SPICE screen 16:9.*)$, size 1714 1016",
        "match:class ^(remote-viewer)$, match:title ^(SPICE screen 16:9.*)$, move (monitor_w-1718) 45",

        -- ============================================================
        --  REGLAS PARA scrcpy (Android)
        -- ============================================================

        -- Fullscreen 16:9 → workspace 9
        "match:class ^(scrcpy)$, match:title ^(Android fullscreen.*)$, workspace 9",
        "match:class ^(scrcpy)$, match:title ^(Android fullscreen.*)$, fullscreen on",

        -- Pantalla 3:2 → flotante, tamaño y posición
        "match:class ^(scrcpy)$, match:title ^(Android screen 3:2.*)$, float on",
        "match:class ^(scrcpy)$, match:title ^(Android screen 3:2.*)$, size 1714 1148",
        "match:class ^(scrcpy)$, match:title ^(Android screen 3:2.*)$, move (monitor_w-1718) 45",

        -- Pantalla 9:20 → flotante, tamaño y posición
        "match:class ^(scrcpy)$, match:title ^(Android screen 9:20.*)$, float on",
        "match:class ^(scrcpy)$, match:title ^(Android screen 9:20.*)$, size 602 1342",
        "match:class ^(scrcpy)$, match:title ^(Android screen 9:20.*)$, move (monitor_w-606) 45",

        -- Pantalla 20:9 → flotante, tamaño y posición
        "match:class ^(scrcpy)$, match:title ^(Android screen 20:9.*)$, float on",
        "match:class ^(scrcpy)$, match:title ^(Android screen 20:9.*)$, size 1714 778",
        "match:class ^(scrcpy)$, match:title ^(Android screen 20:9.*)$, move (monitor_w-1718) 45",

        -- ============================================================
        --  REGLAS PARA FREERDP (X11 y SDL)
        -- ============================================================

        -- Fullscreen 16:9 → workspace 8
        "match:class ^(freerdp_x11_full)$, workspace 8",
        "match:class ^(freerdp_x11_full)$, fullscreen on",
        "match:class ^(freerdp_sdl_full)$, workspace 8",
        "match:class ^(freerdp_sdl_full)$, fullscreen on",

        -- Pantalla 8:5 → flotante, tamaño y posición
        "match:class ^(freerdp_x11_85)$, float on",
        "match:class ^(freerdp_x11_85)$, size 1680 1050",
        "match:class ^(freerdp_x11_85)$, move (monitor_w-1684) 45",
        "match:class ^(freerdp_sdl_85)$, float on",
        "match:class ^(freerdp_sdl_85)$, size 1680 1050",
        "match:class ^(freerdp_sdl_85)$, move (monitor_w-1684) 45",

        -- Pantalla 16:9 → flotante, tamaño y posición
        "match:class ^(freerdp_x11_169)$, float on",
        "match:class ^(freerdp_x11_169)$, size 1714 986",
        "match:class ^(freerdp_x11_169)$, move (monitor_w-1718) 45",
        "match:class ^(freerdp_sdl_169)$, float on",
        "match:class ^(freerdp_sdl_169)$, size 1714 986",
        "match:class ^(freerdp_sdl_169)$, move (monitor_w-1718) 45",
    },

    -- layerrule (ya incluido en windowrule como no_anim, pero se puede dejar aquí)
    -- En la versión Lua, layerrule también es una lista de strings.
    layerrule = {
        "no_anim on, match:namespace ^(quickshell)$",
        "no_anim on, match:namespace ^dms:.*",
    },

-- ============================================================
--  BINDINGS (atajos de teclado)
-- ============================================================

    -- Nota: Los bindings se escriben como strings con el mismo formato que en .conf.
    --       Los tipos de bind (bind, bindl, binde, etc.) se distinguen por la clave:
    --       bind   → normal (ejecuta acción al presionar)
    --       bindl  → bloquea el teclado mientras se mantiene pulsado (para ajustes)
    --       binde  → repite la acción mientras se mantiene (ej: ajustar volumen)
    --       bindd  → igual que binde pero con delay
    --       bindmd → con mouse
    --       bindm  → con mouse (más específico)
    --       bindel → igual que binde pero con flag l (bloqueo)
    --       bind   → también acepta flags como "l" para bloquear.
    --
    -- En la nueva API, se usa una tabla por cada tipo, p.ej.:
    --   bind = { "SUPER, Q, killactive" }
    --   bindl = { "SUPER, XF86AudioMute, exec, ..." }
    --   binde = { "SUPER, minus, resizeactive, -1% 0" }
    --   etc.

    -- -----------------------------------------------------------------
    --  MONITOR
    -- -----------------------------------------------------------------

    -- Navegación entre monitores
    bind = {
        "SUPER CTRL, left, focusmonitor, l",
        "SUPER CTRL, right, focusmonitor, r",
        "SUPER CTRL, H, focusmonitor, l",
        "SUPER CTRL, J, focusmonitor, d",
        "SUPER CTRL, K, focusmonitor, u",
        "SUPER CTRL, L, focusmonitor, r",
    },
    -- Mover ventana activa a otro monitor
    bind = {
        "SUPER SHIFT CTRL, left, movewindow, mon:l",
        "SUPER SHIFT CTRL, down, movewindow, mon:d",
        "SUPER SHIFT CTRL, up, movewindow, mon:u",
        "SUPER SHIFT CTRL, right, movewindow, mon:r",
        "SUPER SHIFT CTRL, H, movewindow, mon:l",
        "SUPER SHIFT CTRL, J, movewindow, mon:d",
        "SUPER SHIFT CTRL, K, movewindow, mon:u",
        "SUPER SHIFT CTRL, L, movewindow, mon:r",
    },

    -- -----------------------------------------------------------------
    --  WORKSPACES
    -- -----------------------------------------------------------------

    -- Renombrar workspace actual
    bind = {
        "CTRL SHIFT, R, exec, dms ipc call workspace-rename open",
    },
    -- Cambiar a workspace numerado
    bind = {
        "SUPER, 1, workspace, 1",
        "SUPER, 2, workspace, 2",
        "SUPER, 3, workspace, 3",
        "SUPER, 4, workspace, 4",
        "SUPER, 5, workspace, 5",
        "SUPER, 6, workspace, 6",
        "SUPER, 7, workspace, 7",
        "SUPER, 8, workspace, 8",
        "SUPER, 9, workspace, 9",
    },
    -- Navegar a siguiente/anterior workspace
    bind = {
        "SUPER, Page_Down, workspace, e+1",
        "SUPER, Page_Up, workspace, e-1",
        "SUPER, U, workspace, e+1",
        "SUPER, I, workspace, e-1",
        "SUPER, mouse_down, workspace, e+1",
        "SUPER, mouse_up, workspace, e-1",
    },

    -- Mover ventana activa a workspace numerado
    bind = {
        "SUPER SHIFT, 1, movetoworkspace, 1",
        "SUPER SHIFT, 2, movetoworkspace, 2",
        "SUPER SHIFT, 3, movetoworkspace, 3",
        "SUPER SHIFT, 4, movetoworkspace, 4",
        "SUPER SHIFT, 5, movetoworkspace, 5",
        "SUPER SHIFT, 6, movetoworkspace, 6",
        "SUPER SHIFT, 7, movetoworkspace, 7",
        "SUPER SHIFT, 8, movetoworkspace, 8",
        "SUPER SHIFT, 9, movetoworkspace, 9",
    },
    -- Mover a siguiente/anterior workspace
    bind = {
        "SUPER CTRL, down, movetoworkspace, e+1",
        "SUPER CTRL, up, movetoworkspace, e-1",
        "SUPER CTRL, U, movetoworkspace, e+1",
        "SUPER CTRL, I, movetoworkspace, e-1",
        "SUPER SHIFT, Page_Down, movetoworkspace, e+1",
        "SUPER SHIFT, Page_Up, movetoworkspace, e-1",
        "SUPER SHIFT, U, movetoworkspace, e+1",
        "SUPER SHIFT, I, movetoworkspace, e-1",
        "SUPER CTRL, mouse_down, movetoworkspace, e+1",
        "SUPER CTRL, mouse_up, movetoworkspace, e-1",
    },

    -- -----------------------------------------------------------------
    --  WINDOWS
    -- -----------------------------------------------------------------

    -- Gestión básica
    bind = {
        "SUPER, Q, killactive",
        "SUPER, F, fullscreen, 1",
        "SUPER SHIFT, F, fullscreen, 0",
        "SUPER SHIFT, T, togglefloating",
        "SUPER SHIFT, W, exec, dms ipc call window-rules toggle",
    },
    -- Navegación entre ventanas (mover foco)
    bind = {
        "SUPER, left, movefocus, l",
        "SUPER, down, movefocus, d",
        "SUPER, up, movefocus, u",
        "SUPER, right, movefocus, r",
        "SUPER, H, movefocus, l",
        "SUPER, J, movefocus, d",
        "SUPER, K, movefocus, u",
        "SUPER, L, movefocus, r",
        "SUPER, Home, focuswindow, first",
        "SUPER, End, focuswindow, last",
    },
    -- Mover ventana activa (dentro del workspace)
    bind = {
        "SUPER SHIFT, left, movewindow, l",
        "SUPER SHIFT, down, movewindow, d",
        "SUPER SHIFT, up, movewindow, u",
        "SUPER SHIFT, right, movewindow, r",
        "SUPER SHIFT, H, movewindow, l",
        "SUPER SHIFT, J, movewindow, d",
        "SUPER SHIFT, K, movewindow, u",
        "SUPER SHIFT, L, movewindow, r",
    },

    -- Grupos de ventanas
    bind = {
        "SUPER, W, togglegroup",   -- Crear/salir del grupo
    },
    -- Mover ventana dentro/fuera del grupo según dirección
    bind = {
        "SUPER ALT, left, movewindoworgroup, l",
        "SUPER ALT, down, movewindoworgroup, d",
        "SUPER ALT, up, movewindoworgroup, u",
        "SUPER ALT, right, movewindoworgroup, r",
        "SUPER ALT, H, movewindoworgroup, l",
        "SUPER ALT, J, movewindoworgroup, d",
        "SUPER ALT, K, movewindoworgroup, u",
        "SUPER ALT, L, movewindoworgroup, r",
    },
    -- Cambiar entre ventanas del grupo (comentado porque no se usa)
    -- bind = {
    --     "SUPER ALT, Page_Down, changegroupactive f",
    --     "SUPER ALT, Page_Up, changegroupactive b",
    -- },

    -- Orientación de nueva ventana (preselección)
    bind = {
        "SUPER, bracketleft, layoutmsg, preselect l",
        "SUPER, bracketright, layoutmsg, preselect r",
    },

    -- Alternar división (dwindle)
    bind = {
        "SUPER, R, layoutmsg, togglesplit",
    },

    -- Mover ventana con el mouse (arrastrar)
    bindmd = {
        "SUPER, mouse:272, Move window, movewindow",
    },

    -- Redimensionar con el mouse
    bindmd = {
        "SUPER, mouse:273, Resize window, resizewindow",
    },
    -- Redimensionar con teclas (expandir/contraer)
    bindd = {   -- con delay
        "SUPER, code:20, Expand window left, resizeactive, -100 0",
        "SUPER, code:21, Shrink window left, resizeactive, 100 0",
    },
    binde = {   -- repetitivo
        "SUPER, minus, resizeactive, -1% 0",
        "SUPER, equal, resizeactive, 1% 0",
        "SUPER SHIFT, minus, resizeactive, 0 -1%",
        "SUPER SHIFT, equal, resizeactive, 0 1%",
    },

    -- Forzar fullscreen al 100% (tamaño exacto)
    bind = {
        "SUPER CTRL, F, resizeactive, exact 100% 100%",
    },

    -- -----------------------------------------------------------------
    --  SYSTEM APPLICATION LAUNCHERS (lanzadores del sistema)
    -- -----------------------------------------------------------------

    bind = {
        "SUPER, space, exec, dms ipc call spotlight toggle",
        "SUPER, V, exec, dms ipc call clipboard toggle",
        "SUPER, M, exec, dms ipc call processlist focusOrToggle",
        "SUPER, comma, exec, dms ipc call settings focusOrToggle",
        "SUPER, N, exec, dms ipc call notifications toggle",
        "SUPER SHIFT, N, exec, dms ipc call notepad toggle",
        "SUPER, Y, exec, dms ipc call dankdash wallpaper",
        "SUPER, TAB, exec, dms ipc call hypr toggleOverview",

        -- Power Menu
        "SUPER, X, exec, dms ipc call powermenu toggle",

        -- Apagar/encender monitores (DPMS)
        "SUPER SHIFT, P, dpms, toggle",

        -- Cheat sheet de atajos
        "SUPER SHIFT, Slash, exec, dms ipc call keybinds toggle hyprland",

        -- Bloquear pantalla
        "SUPER SHIFT, B, exec, dms ipc call lock lock",

        -- Salir de Hyprland
        "SUPER SHIFT, E, exit",

        -- Abrir gestor de procesos (Ctrl+Alt+Delete)
        "CTRL ALT, Delete, exec, dms ipc call processlist focusOrToggle",

        -- Capturas de pantalla
        ", Print, exec, dms screenshot --stdout | satty --filename -",
        "CTRL, Print, exec, dms screenshot full",
        "ALT, Print, exec, dms screenshot window",
    },

    -- Controles de audio (con repetición y bloqueo)
    bindel = {   -- con flag 'l' (bloqueo)
        ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 3",
        ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 3",
        "CTRL, XF86AudioRaiseVolume, exec, dms ipc call mpris increment 3",
        "CTRL, XF86AudioLowerVolume, exec, dms ipc call mpris decrement 3",
    },
    bindl = {   -- bloqueo (sin repetición)
        ", XF86AudioMute, exec, dms ipc call audio mute",
        ", XF86AudioMicMute, exec, dms ipc call audio micmute",
        ", XF86AudioPause, exec, dms ipc call mpris playPause",
        ", XF86AudioPlay, exec, dms ipc call mpris playPause",
        ", XF86AudioPrev, exec, dms ipc call mpris previous",
        ", XF86AudioNext, exec, dms ipc call mpris next",
    },

    -- Control de brillo
    bindel = {
        ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5 \"\"",
        ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5 \"\"",
    },

    -- -----------------------------------------------------------------
    --  USER APPLICATION LAUNCHERS (lanzadores de usuario)
    -- -----------------------------------------------------------------

    bind = {
        "SUPER, T, exec, footclient",                        -- Terminal
        "SUPER SHIFT, C, exec, dms color pick -o \"{0}{1}{2}\" -a",   -- Selector de color
    },
})
