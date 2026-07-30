--
-- La parte usado por el monitor para las ventanas son:
--  > Ancho : monitor_w - 2 - 2
--    > 2px de espacio entre el borde del monitor y borde de la ventana.
--  > Alto : monitor_h - 45 ¿- 2?
--   > Entre la barra de estado y borde superior de la ventana es de 45 px.
--

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
-- Windows Rule> Aplicaciones generales
------------------------------------------------------------------------------------

local function m_create_windowrule(match, effects)
    effects.match = match
    hl.window_rule(effects)
end

-- Terminal WezTerm
m_create_windowrule({ class = "org\\.wezfurlong\\.wezterm" }, { tile = true })

-- GNOME apps
m_create_windowrule({ class = "org\\.gnome\\..*" }, { rounding = 12 })

-- Utilities
m_create_windowrule({ class = "gnome-control-center" }, { tile = true })
m_create_windowrule({ class = "pavucontrol" }, { tile = true })
m_create_windowrule({ class = "nm-connection-editor" }, { tile = true })

-- Floating apps
m_create_windowrule({ class = "org\\.gnome\\.Calculator" }, { float = true })
m_create_windowrule({ class = "gnome-calculator" }, { float = true })
m_create_windowrule({ class = "galculator" }, { float = true })
m_create_windowrule({ class = "blueman-manager" }, { float = true })
m_create_windowrule({ class = "org\\.gnome\\.Nautilus" }, { float = true })
m_create_windowrule({ class = "xdg-desktop-portal" }, { float = true })

-- Steam notifications
m_create_windowrule({ class = "steam", title = "^notificationtoasts.*" }, { no_initial_focus = true, pin = true })

-- Firefox PiP
m_create_windowrule({ class = "firefox", title = "Picture-in-Picture" }, { float = true })

-- Zoom
m_create_windowrule({ class = "zoom" }, { float = true })

-- DMS windows floating by default
-- ! Hyprland doesn't size these windows correctly so disabling by default here
-- windowrule = float on, match:class ^(org.quickshell)$
hl.layer_rule({ match = { namespace = "quickshell" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^dms:.*" }, no_anim = true })



------------------------------------------------------------------------------------
-- Windows Rule> Aplicaciones basicas
------------------------------------------------------------------------------------

-- Satty
-- > La GUI 'satty' es un utilitario que usamos para screenshot 'satty'.
-- > La ventana siempre debe ser flotante.
m_create_windowrule({ class = "com.gabm.satty" }, { float = true, min_size = { 1000, 600 } })

-- Visor de images 'imv'
m_create_windowrule({ class = "imv" }, { float = false })

-- Visor de PDFs 'zathura'
m_create_windowrule({ class = "org\\.pwmt\\.zathura" }, { float = false })

-- Player de videos 'mpv'
m_create_windowrule({ class = "mpv" }, { float = false })



------------------------------------------------------------------------------------
-- Windows Rule> 'remote-viewer' (SPICE)
------------------------------------------------------------------------------------
--
-- > La GUI 'remote-viewer' es un utilitario de escritorio remoto especializado
--   para conectarte con VM usando el protocolo SPICE.
-- > Tambien puede usar el protocolo VNC, pero no usuaremos para ello.
-- > Para tener diferente comportamiento de la ventana se usara su titulo.
-- > El cliente SPICE y VNC permite modificar la resolucion del monitor virtual de
--   la VM o equipo remoto.
--

-- Usando SPICE sobre monitor virtual fullscreen 16:9
-- > Se mueve al workspace 8, asociado al monitor secundario (17.3 pulgadas y
--   aspecto 16:9).
-- > El monitor virtual de la VM deben usar 16:9, como '1920x1080'.
-- > Se muestra en modo fullscreen.
m_create_windowrule({ class = "remote-viewer", title = "^SPICE fullscreen.*" }, { workspace = "8", fullscreen = true })

-- Usando SPICE sobre monitor virtual con aspecto 8:5
-- > El monitor virtual de la VM debera tener un aspecto 8:5.
--   > Se recomienda usar la resolucion 1680 x 1050.
--   > No hay un escalamiento entre el tamaño del monitor virtual y la ventana.
-- > La ventana 'remote-viewer' tiene un size: 1680 x 1080 = 1680 x (1050 + 30).
--   > La barra titulo, es dibujado por el propio GTK de 'remote-viewer', y
--     tiene 'heigth' es 30.
-- > La ventana se apegada a la esquina superior (debajo de la barra) y a la
--   derecha.
--   > La ventana retrocede '1680 + 2 + 2' (2px por espacio de la ventana con el
--     borde del monitor).
--   > La ventana baja 45 px (incluye la barra de estado y los espacio de 2px
--     entre la ventana y la barra).
m_create_windowrule({ class = "remote-viewer", title = "^SPICE screen 8:5.*" }, { float = true, size = { 1680, 1080 }, move = { "(monitor_w-1684)", "45" } })

-- Usando SPICE sobre monitor virtual con aspecto 16:9
-- > El monitor virtual de la VM debera tener un aspecto de 16:9.
--   > Se recomienda usar la resolucion 1920 x 1080.
--   > Siempre existira un escalamiento, a menos, entre el tamaño del monitor
--     virtual y la ventana.
-- > La ventana 'remote-viewer' tiene un size: 1714 x 1016 = 1714 x (986 + 30).
--   > La barra titulo, es dibujado por el propio GTK de 'remote-viewer', y tiene
--     'heigth' es 30.
-- > La ventana se apegada a la esquina superior (debajo de la barra) y a la derecha.
--   > La ventana retrocede '1714 + 2 + 2' (2px por espacio de la ventana con el
--     borde del monitor).
--   > La ventana baja 45 px (incluye la barra de estado y los espacio de 2px entre
--     la ventana y la barra).
m_create_windowrule({ class = "remote-viewer", title = "^SPICE screen 16:9.*" }, { float = true, size = { 1714, 1016 }, move = { "(monitor_w-1718)", "45" } })



------------------------------------------------------------------------------------
-- Windows Rule> 'scrcpy' (Android)
------------------------------------------------------------------------------------
--
-- > La GUI 'scrcpy' es un utilitario de para conectarse a un dispositivo android.
-- > URL: https://github.com/Genymobile/scrcpy#user-documentation
-- > Para tener diferente comportamiento de la ventana se usara su titulo.
-- > El 'scrcpy' (cliente 'adb') no puede establecer la resolucion del pantalla
--   virtual del dispositivo android y siempre es la resolucion de su pantalla real.
--   'srccpy' envia o calcula el tamaño de la ventana y segun ello escala o reduce
--   lo que se muestra.
--

-- Usando SrcCpy sobre pantalla de tablets 16:9 a fullscreen
-- > Se mueve al workspace 9, asociado al monitor secundario (17.3 pulgadas y
--   aspecto 16:9).
-- > El pantalla virtual de la tableta, recomenda para no tener 'zonas osucuras', es 16:9,
--   como '1920x1080'.
-- > Se muestra en modo fullscreen.
m_create_windowrule({ class = "scrcpy", title = "^Android fullscreen.*" }, { workspace = "9", fullscreen = true })

-- Usando SrcCpy sobre pantalla de tablets con aspecto 3:2
-- > Para que se vea mejor, la pantalla de la tablet debera tener un aspecto de 3:2.
--   > Se recomienda usar la resolucion 2160 X 1440 (usado por la table 'XPen Magic Drawing Pad').
--   > Siempre existira un escalamiento, al menos, entre el tamaño del la ventana y la
--     resolucion de la pantalla de la tablet).
-- > La ventana ScrCpy tiene un size: 1714 x 1148.
-- > La ventana se apegada a la esquina superior (debajo de la barra) y a la derecha.
--   > La ventana retrocede '1714 + 2 + 2' (2px por espacio de la ventana con el
--     borde del monitor).
--   > La ventana baja 45 px (incluye la barra de estado y los espacio de 2px entre
--     la ventana y la barra).
m_create_windowrule({ class = "scrcpy", title = "^Android screen 3:2.*" }, { float = true, size = { 1714, 1148 }, move = { "(monitor_w-1718)", "45" } })

-- Usando SrcCpy sobre pantalla de android con aspecto 9:20
-- > Para que se vea mejor, la pantalla del android debera tener un aspecto de 9:20.
--   > Se recomienda usar la resolucion 1220 x 2712 (Xiomi MI 13T).
--   > Siempre existira un escalamiento, al menos, entre el tamaño del la ventana y la
--     resolucion de la pantalla de la tablet).
-- > La ventana SrcCpy tiene un size: 602 x 1342.
-- > La ventana se apegada a la esquina superior (debajo de la barra) y a la derecha.
--   > La ventana retrocede '602 + 2 + 2' (2px por espacio de la ventana con el
--     borde del monitor).
--   > La ventana baja 45 px (incluye la barra de estado y los espacio de 2px entre
--     la ventana y la barra).
m_create_windowrule({ class = "scrcpy", title = "^Android screen 9:20.*" }, { float = true, size = { 602, 1342 }, move = { "(monitor_w-606)", "45" } })

-- Usando SrcCpy sobre pantalla de android con aspecto 20:9
-- > Para que se vea mejor, la pantalla del android debera tener un aspecto de 20:9.
--   > Se recomienda usar la resolucion 2712 × 1220 (Xiomi MI 13T).
--   > Siempre existira un escalamiento, al menos, entre el tamaño del la ventana y la
--     resolucion de la pantalla de la tablet).
-- > La ventana ScrCpy tiene un size: 1714 x 778.
-- > La ventana se apegada a la esquina superior (debajo de la barra) y a la derecha.
--   > La ventana retrocede '1714 + 2 + 2' (2px por espacio de la ventana con el
--     borde del monitor).
--   > La ventana baja 45 px (incluye la barra de estado y los espacio de 2px entre
--     la ventana y la barra).
m_create_windowrule({ class = "scrcpy", title = "^Android screen 20:9.*" }, { float = true, size = { 1714, 778 }, move = { "(monitor_w-1718)", "45" } })



------------------------------------------------------------------------------------
-- Windows Rule> FreeRDP ('xfreerdp' y 'sdl-freerdp')
------------------------------------------------------------------------------------
--
-- > La GUI freerdp es un utilitarios de escritorio remoto que permite conectarte
--   a equipos remotos usando RDP.
-- > Actualmente ofrece 2 versiones:
--   > 'xfreerdp' para conectarse usando X11 (por ejemplo, usando el compositor
--     compatible de X11 de XWayland)
--   > 'sdl-freerdp' para conectarse a diferentes backend de motor grafico
--     usando SDL. Lo usuaremos solo para conectarnos usando Wayland.
-- > Para tener diferente comportamiento de la ventana se usara una clase de
--   ventana (VM_CLASS) personalizada, usando la opcion del comando '/vm-class'.
-- > Los RDP remoteapp usaran el nombre por defecto de la clase de ventana.
-- > El cliente RDP no puede establecer la resolucion del monitor virtual del equipo
--   remoto. El cliente envia su pantalla, y el servidor RDP calcula la resolucion
--   adecuada, sin poder modificarlo el valor generado.
--

-- Usando RDP sobre monitor virtual fullscreen 16:9
-- > Se mueve al workspace 8, asociado al monitor secundario (17.3 pulgadas y
--   aspecto 16:9).
-- > El monitor virtual de la VM deben usar 16:9, como '1920x1080'.
-- > Se muestra en modo fullscreen.
m_create_windowrule({ class = "freerdp_x11_full" }, { workspace = "8", fullscreen = true })
m_create_windowrule({ class = "freerdp_sdl_full" }, { workspace = "8", fullscreen = true })

-- Usando RDP sobre monitor virtual con aspecto 8:5
-- > El monitor virtual de la VM debera tener un aspecto 8:5.
--   > Se recomienda usar la resolucion 1680 x 1050.
--   > No hay un escalamiento entre el tamaño del monitor virtual y la ventana.
-- > La ventana 'remote-viewer' tiene un size: 1680 x 1050.
-- > La ventana se apegada a la esquina superior (debajo de la barra) y a la
--   derecha.
--   > La ventana retrocede '1680 + 2 + 2' (2px por espacio de la ventana con el
--     borde del monitor).
--   > La ventana baja 45 px (incluye la barra de estado y los espacio de 2px
--     entre la ventana y la barra).
m_create_windowrule({ class = "freerdp_x11_85" }, { float = true, size = { 1680, 1050 }, move = { "(monitor_w-1684)", "45" } })
m_create_windowrule({ class = "freerdp_sdl_85" }, { float = true, size = { 1680, 1050 }, move = { "(monitor_w-1684)", "45" } })

-- Usando RDP sobre monitor virtual con aspecto 16:9
-- > El monitor virtual de la VM debera tener un aspecto de 16:9.
--   > Se recomienda usar la resolucion 1920 x 1080.
--   > Siempre existira un escalamiento, al menos, entre el tamaño del monitor
--     virtual y la ventana.
-- > La ventana 'remote-viewer' tiene un size: 1714 x 986.
-- > La ventana se apegada a la esquina superior (debajo de la barra) y a la derecha.
--   > La ventana retrocede '1714 + 2 + 2' (2px por espacio de la ventana con el
--     borde del monitor).
--   > La ventana baja 45 px (incluye la barra de estado y los espacio de 2px entre
--     la ventana y la barra).
m_create_windowrule({ class = "freerdp_x11_169" }, { float = true, size = { 1714, 986 }, move = { "(monitor_w-1718)", "45" } })
m_create_windowrule({ class = "freerdp_sdl_169" }, { float = true, size = { 1714, 986 }, move = { "(monitor_w-1718)", "45" } })



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
