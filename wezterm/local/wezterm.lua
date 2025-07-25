--
-- Consideraciones a tener en cuenta:
-- > Por cada (emulador de) terminal iniciado se crea un proceso 'wezterm-gui'.
--   > El comando 'wezterm' si es usado para crear una instancia (de emulador) de terminal siempre invocara al proceso 'wezterm-gui'.
--   > Por cada instancia el archivo de configuracion '~/.config/wezterm/wezterm.lua' es ejecutado.
--   > Por defecto el archivo de configuracion puede volver a cargarse automaticamete cuando este tiene un cambio.
-- > El (emulador de) terminal es un programa GUI que usualmente se inicia de 2 formas:
--   > 'wezterm start --domain <defualt_domain> -- <default_prog>'
--   > 'wezterm-gui start  --domain <defualt_domain> -- <default_prog>', es usado en los 'launcher' de los diferentes sistemas operativo para
--     iniciar el (emulador de terminal). Internamente invoca a 'wezterm start'.
-- > Otras formas de iniciar una instancia del (emulador de terminal) es usando Los subcomandos:
--     > 'wezterm connect <domian>' o 'wezterm-gui connect <domian>',
--     > 'wezterm ssh <server>'     o 'wezterm-gui ssh <server>'
--     > 'wezterm ssh serial'       o 'wezterm-gui ssh serial'
--   Por defecto estos crean una instancia de (emulador de) terminal, pero algunas usando opciones como '--new-tab' permiten que si es
--   eejcutado dentro de terminal existente (que sea WezTerm) puede ejecutar crear un 'Tab' en el workspace actual asociado al dominio asociado
--   al subcomando.
-- > Si inicia el (emulador de) terminal usando 'wezterm' o 'wezterm-gui' sin subcomando, se puede modificar el subcomando a usar estableciendo el
--   parametro 'config.default_gui_startup_args' del archivo de configuracion y especificando, por ejemplo:
--   > '{ 'start' }'               si desea usar 'wezterm start'
--   > '{ 'ssh', '<server>' }'     si desea usar 'wezterm ssh <server>'
--   > '{ 'connect', '<domain>' }' si desea usar 'wezterm connect <domain>'
--   > '{ 'serial', '<server>' }'  si desea usar 'wezterm serial <server>'
-- > El 'workspace' son agrupaciones de diferentes 'tab' (de diferentes dominios) y cuyo objeto solo existen en una instancia de emulador de terminal.
-- > El 'domain' es un objeto que existe solo en una instancia de 'multiplexer'.
--   > El objeto 'tab' solo pertenece a un dominio especifico.
--   > El objeto 'pane' pertene a un ventana especifico.
-- > Existe 2 tipos de 'multiplexer' usados por el (emulador de) terminal.
--   > 'built-in multiplexer'
--     > Cada instancia del (emulador de terminal) inicia su propio 'built-in multiplexer'
--     > Se crea dentro del propio proceso de la instancia de la terminal.
--     > Solo gestion objeto de dominio de tipo:
--       > Local Domain
--       > SSH Damain (solo si se indica que el servidor SSH implementa un 'multiplexer server').
--   > 'multiplexer server'
--     > Se ejecutan en un proceso 'wezterm-mux-server' externa a la terminal.
--     > Se ejecuta en un servidor remoto require tambien de un proceso proxy 'wezterm cli proxy' que facilite la comunicacion de la terminal al
--       'multiplexer server'.
--     > Solo gestion objeto de dominio de tipo:
--       > Unix Domain (local)
--         > No valido en SO Windows. Define socket IPC para comunicar el cliente IPC (terminal) con el servidor IPC (multiplexer server).
--         > El 'multiplexer server' esta en la misma maquina donde este el (emulador de) terminal.
--       > TLS Domain  (remote)
--         > El 'multiplexer server' implementa un TLS server. El cliente TLS es la terminal.
--       > SSH Domain  (remote. only some of them)
--         > Solo aquellos dominios SSH que estan configurados e indican que van a usar 'multiplexer server'.
--         > La terminal seria el cliente SSH y el 'multiplexer server' esta en el servidor SSH.
-- > Solo los dominios asciados a un 'multiplexer server' se pueden 'attach' o 'detach' del workspace actual de la terminal.
-- > Si realiza un 'detach' de un multiplexing domian del worspace actual, se desvincual todos los tab asociados a dicho dominio, pero estos objetos
--   no se destruyen y pueden ser vistos nuevamente dentro del workspace si se vuelve a vincular ('attach').
--

------------------------------------------------------------------------------------
-- My settings variables
------------------------------------------------------------------------------------

local mm_ucommon = require("utils.commom")

-- Determinar el tipo de SO
--   0 > Si es Linux
--   1 > Si es Windows
--   2 > Si es MacOS (Apple Silicon)
--   3 > Si es MacOS (Intel)
local m_os_type = mm_ucommon.get_os_type()
--print(m_os_type)

-- Obtener la configuracion personalizada del usuario
local m_custom_config = mm_ucommon.get_custom_config()



------------------------------------------------------------------------------------
-- Setting> General
------------------------------------------------------------------------------------

-- Obtain the default configuration. See: https://wezfurlong.org/wezterm/config/lua/config/index.html
local mm_wezterm = require('wezterm')
local mod = mm_wezterm.config_builder()

-- If false, do not try to use a Wayland protocol connection when starting the gui frontend, and instead use X11.
if m_os_type == 0 then
    mod.enable_wayland = m_custom_config.enable_wayland
end

-- What to set the TERM environment variable to. The default is xterm-256color, which should provide a good level of feature
-- support without requiring the installation of additional terminfo data.
-- If you want to get the most application support out of wezterm, then you may wish to install a copy of the wezterm TERM definition:
--   $ #Descargar el terminfo
--   $ tempfile=$(mktemp) && curl -o $tempfile https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo
--   $ #Option 1: Compilar y generar el terminfo a para el usuario
--   $ tic -x -o ~/.terminfo $tempfile
--   $ #Option 2: Compilar y generar el terminfo a para todos los usuarios
--   $ tic -x -o /usr/share/terminfo/w/wezterm $tempfile
--   $ #Eliminar el archivo temporal
--   $ rm $tempfile
-- You can then set term = "wezterm". Using this, allow to use more advanced features such as colored underlines, styled underlines (eg: undercurl).
-- If the system you are using has a relatively outdated ncurses installation, the wezterm terminfo will also enable italics and true color support.
mod.term = 'xterm-256color'
--mod.term = 'wezterm'

-- Create my custom scheme based on a built-in schema.
-- Built-in scheme: https://wezfurlong.org/wezterm/colorschemes/index.html
local scheme = mm_wezterm.get_builtin_color_schemes()[m_custom_config.color_scheme]
scheme.foreground = '#c0bfbc'
scheme.background = '#000000'
mod.color_schemes = {
    ['lepc-schema']= scheme
  }

-- Specifies the current color schemes in your configuration file.
mod.color_scheme = 'lepc-schema'
--mod.color_scheme = 'Ayu Dark (Gogh)'


-- Sets the default current working directory used by the initial window.
-- The value is a string specifying the absolute path that should be used for the home directory (no use relative path or '~').
--mod.default_cwd = "$HOME"

-- Specifies the name of the default workspace. The default is "default".
--mod.default_workspace = "default"

-- Wezterm checks regularly if there is a new stable version available on github, and shows a simple UI to let you
-- know about the update (See show_update_window to control this UI). By default it is checked once every 24 hours.
mod.check_for_updates = false
--mod.check_for_updates_interval_seconds = 86400

-- When the BEL ascii sequence is sent to a pane, the bell is "rung" in that pane.
-- You may choose to configure the audible_bell option to change the sound that wezterm makes when the bell rings.
-- The follow are possible values:
--    "SystemBeep" - perform the system beep or alert sound. This is the default. On Wayland systems, which have no system beep function, it does not produce a sound.
--    "Disabled" - don't make a sound
--mod.audible_bell = "Disabled"

-- If true, the mouse cursor will be hidden when typing, if your mouse cursor is hovering over the window.
-- The default is true. Set to false to disable this behavior.
--mod.hide_mouse_cursor_when_typing = true

-- Controls whether pasted text will have newlines normalized.
-- If bracketed paste mode is enabled by the application, the effective value of this configuration option is "None".
-- The following values are accepted:
-- > "None" or "false"
--   The text is passed through unchanged.
-- > "CarriageReturn"
--   Newlines of any style are rewritten as CR
-- > "CarriageReturnAndLineFeed" or "true"
--   Newlines of any style are rewritten as CRLF.
-- > "LineFeed"
--   Newlines of any style are rewritten as LF.
--if m_os_type == 1 then
--    mod.canonicalize_pasted_newlines = "CarriageReturnAndLineFeed"
--else
--    mod.canonicalize_pasted_newlines = "CarriageReturn"
--end



------------------------------------------------------------------------------------
-- Setting> Font
------------------------------------------------------------------------------------

-- Specifying an ordered list of fonts.
-- when resolving text into glyphs the first font in the list is consulted, and if the glyph isn't present in that font, WezTerm proceeds to the next font in the fallback list.
mod.font = mm_wezterm.font_with_fallback({
    {
        family= "JetBrainsMono Nerd Font Mono",
        weight= "Light", -- "Thin", "ExtraLigth", "Light", "Regular", "Medium", "SemiBold", "Bold", "ExtraBold"
        stretch= "Normal",
        --italic = false,
        harfbuzz_features= {"calt=1", "clig=1", "liga=1"},
    },
    "Incosolata LGC Nerd Font Mono",
  })

-- Specifies the size of the font, measured in points. You may use fractional point sizes, such as 13.3, to fine tune the size.
-- The default font size is 12.0
mod.font_size = m_custom_config.font_size
--mod.font_size = 11

--config.bold_brightens_ansi_colors = true
mod.warn_about_missing_glyphs = true

-- Controls whether the Input Method Editor (IME) will be used to process keyboard input.
-- The IME is useful for inputting kanji or other text that is not natively supported by the attached keyboard hardware.
mod.use_ime = false


------------------------------------------------------------------------------------
-- Setting> Windows> General
------------------------------------------------------------------------------------

--  > Estilo por defecto del TabBar autogenerado por Wezterm.
--  > Estilo del borde de la ventana.
--    En Linux, X11 no permite cambiar el borde de la ventana en Wayland si
-- No incluye la barra de titulo por defecto generado por el gestor de ventana o escritorio.
-- Url: https://wezfurlong.org/wezterm/config/lua/config/window_frame.html?h=window_frame
mod.window_frame = {
    --'Roboto' es una fuente no-mono (proporcional) integrada/built-in dentro del binario de wezterm
    --font = mm_wezterm.font 'Roboto',
    font_size = 10,
}

--print(m_custom_config.windows_style)

-- Estilo de borde de la ventana el cual incluye:
-- Si no esta definido el estilo de la ventana, definirlo
-- Estilo a usar en la ventana de la terminal
--  0 > Se establece el por defecto.
--  1 > Se usa el estilo 'TITLE|RESIZE'
--  2 > Se usa el estilo 'INTEGRATED_BUTTONS|RESIZE'
if m_custom_config.windows_style == 0 then

    if m_os_type == 0 then
        if m_custom_config.enable_wayland then
            m_custom_config.windows_style = 1
        else
            --m_custom_config.windows_style = 1
            m_custom_config.windows_style = 2
        end
    else
        m_custom_config.windows_style = 2
    end

end

--print(m_custom_config.windows_style)


-- Configures whether the window has a title bar and/or resizable border.
-- > "NONE"
--   Disables titlebar and border (borderless mode), but causes problems with resizing and minimizing the window, so you probably want to use RESIZE
--   instead of NONE if you just want to remove the title bar.
-- > "TITLE"
--   Disable the resizable border and enable only the title bar.
-- > "RESIZE"
--   Disable the title bar but enable the resizable border
-- > "TITLE|RESIZE"
--   Enable titlebar and border. This is the default.
-- > "INTEGRATED_BUTTONS|RESIZE"
--   Place window management buttons (minimize, maximize, close) into the tab bar instead of showing a title bar.
--   Wayland error: see https://github.com/wez/wezterm/issues/4963
if m_custom_config.windows_style == 1 then
    mod.window_decorations = "TITLE|RESIZE"
elseif m_custom_config.windows_style == 2 then
    mod.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
end

-- Configures the visual style of the tabbar-integrated titlebar button replacements that are shown when window_decorations = "INTEGRATED_BUTTONS|RESIZE".
-- Possible styles are:
-- > "Windows"     - draw Windows-style buttons
-- > "Gnome"       - draw Adwaita-style buttons
-- > "MacOsNative" - on macOS only, move the native macOS buttons into the tab bar.
-- The default value is "MacOsNative" on macOS systems, but "Windows" on other systems.
--mod.integrated_title_button_style = "Windows"

-- Configures the ordering and set of window management buttons to show when window_decorations = "INTEGRATED_BUTTONS|RESIZE".
-- The value is a table listing the buttons. Each element can have one of the following values:
-- > "Hide"     - the window hide or minimize button
-- > "Maximize" - the window maximize button
-- > "Close"    - the window close button
-- The default value is equivalent to: "{ 'Hide', 'Maximize', 'Close' }"
--mod.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }

-- Configures the alignment of the set of window management buttons when window_decorations = "INTEGRATED_BUTTONS|RESIZE".
-- Possible values are:
-- > "Left"  - the buttons are shown on the left side of the tab bar
-- > "Right" - the buttons are shown on the right side of the tab bar
mod.integrated_title_button_alignment = "Right"

-- Configures the color of the set of window management buttons when window_decorations = "INTEGRATED_BUTTONS|RESIZE".
-- Possible values are:
-- > "Auto" - automatically compute the color
-- > "red"  - Use a custom color
mod.integrated_title_button_color = "auto"

-- If it's 'AlwaysPrompt' display a confirmation prompt when the window is closed by the windowing environment,
-- either because the user closed it with the window decorations, or instructed their window manager to close it.
-- Set this to "NeverPrompt" if you don't like confirming closing windows every time.
--mod.window_close_confirmation = "NeverPrompt"

-- Control whether changing the font size adjusts the dimensions of the window (true) or adjusts the number of terminal rows/columns (false).
-- If you use a tiling window manager then you may wish to set this to false.
-- The default value is now nil which causes wezterm to match the name of the connected window environment (which you can see if you open the debug overlay)
-- against the list of known tiling environments configured by tiling_desktop_environments.
-- If the environment is known to be tiling then the effective value of adjust_window_size_when_changing_font_size is false, and true otherwise.
mod.adjust_window_size_when_changing_font_size = true

-- Controls the amount of padding between the window border and the terminal cells. Padding is measured in pixels.
-- If enable_scroll_bar is true, then the value you set for right will control the width of the scrollbar.
-- If you have enabled the scrollbar and have set right to 0 then the right padding (and thus the scrollbar width) will instead match the width of a cell.
if m_custom_config.enable_scrollbar then
    mod.window_padding = {
        left = 4,
        right = 8,
        top = 4,
        bottom = 4,
    }
else
    mod.window_padding = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4,
    }
end

-- Initial window size on startup
mod.initial_rows = 30
mod.initial_cols = 150

-- Controls the behavior when the shell program spawned by the terminal exits. There are three possible values:
-- > "Close"           : close the corresponding pane as soon as the program exits.
-- > "Hold"            : keep the pane open after the program exits. The pane must be manually closed via CloseCurrentPane, CloseCurrentTab or closing the window.
-- > "CloseOnCleanExit": if the shell program exited with a successful status, behave like "Close", otherwise, behave like "Hold". This is the default setting.
mod.exit_behavior = "Close"
--mod.window_background_opacity = 0.99



------------------------------------------------------------------------------------
-- Setting> Windows> Scroll
------------------------------------------------------------------------------------

-- Enable the scrollbar. This is currently disabled by default. It will occupy the right window padding space.
mod.enable_scroll_bar = m_custom_config.enable_scrollbar

-- Lines of scrollback you want to retain (in memory) per tab (default is 3500)
mod.scrollback_lines = 5000



------------------------------------------------------------------------------------
-- Setting> Windows> Tab Bar (Barra de pestañas)
------------------------------------------------------------------------------------

-- Controls whether the tab bar is enabled. Set to false to disable it.
mod.enable_tab_bar = true

-- If set to true, when there is only a single tab, the tab bar is hidden from the display. If a second tab is created, the tab will be shown.
-- Default is false.
if m_custom_config.windows_style == 2 then

    --Recomendado para estilo de tipo "INTEGRATED_BUTTONS|RESIZE"
    mod.hide_tab_bar_if_only_one_tab = false

elseif m_custom_config.windows_style == 1 then

    --Recomendado para estilo de tipo "TITLE|RESIZE"
    mod.hide_tab_bar_if_only_one_tab = true

    --Wayland error: No muestra la barra de titulo generado por el sistema/Wayland
    if (m_os_type == 0) and m_custom_config.enable_wayland then
        mod.hide_tab_bar_if_only_one_tab = false
    end

end

-- When tab_bar_at_bottom = true, the tab bar will be rendered at the bottom of the window rather than the top of the window.
-- The default is false.
--mod.tab_bar_at_bottom = false

-- When set to true (the default), the tab bar is rendered in a 'native tabbar style' with proportional fonts.
-- When set to false, the tab bar is rendered using a 'retro tabbar style' using the main terminal font.
-- Retro  TabBar Style: https://wezfurlong.org/wezterm/config/appearance.html#retro-tab-bar-appearance
-- Native TabBar Style (Fancy TabBar Style): https://wezfurlong.org/wezterm/config/appearance.html#tab-bar-appearance-colors
-- Futuras mejoras: https://github.com/wez/wezterm/issues/1180#issuecomment-1493128725
mod.use_fancy_tab_bar = true

-- Specifies the maximum width that a tab can have in the tab bar when using retro tab mode. It is ignored when using fancy tab mode.
-- Defaults to 16 glyphs in width.
--mod.tab_max_width = 32

-- When set to true (the default), tab titles show their tab number (tab index) with a prefix such as "1:".
-- When false, no numeric prefix is shown.
-- The tab_and_split_indices_are_zero_based setting controls whether numbering starts with 0 or 1.
--mod.show_tab_index_in_tab_bar = false

-- When set to true (the default), the tab bar will display the new-tab button, which can be left-clicked to create a new tab,
-- or right-clicked to display the Launcher Menu. When set to false, the new-tab button will not be drawn into the tab bar.
--mod.show_new_tab_button_in_tab_bar = true

-- If set to true, when the active tab is closed, the previously activated tab will be activated.
-- Otherwise, the tab to the left of the active tab will be activated. Default is false.
--mod.switch_to_last_active_tab_when_closing_tab = true


-- Event 'format-tab-title' usado para cambiar el estilo del tab activo/inactivo, remplazando a la funcion 'tab_bar_style'.
-- Esto complementa el estilo usado para el tab 'https://wezfurlong.org/wezterm/config/appearance.html#retro-tab-bar-appearance'.
-- Url: 'https://wezfurlong.org/wezterm/config/lua/window-events/format-tab-title.html'


-- Personalizar el nombre del tab
-- Evento invocado por cada tab que requiere se redibujado
local mm_ugeneralui = require('utils.general_ui')
mm_wezterm.on('format-tab-title', mm_ugeneralui.callback_format_tab_title)



------------------------------------------------------------------------------------
-- Setting> Windows> Status Bar (Barra de estado)
------------------------------------------------------------------------------------
--
-- Si el tabbar esta visible, se puede mostrar a la izquierda o derecha.
-- Si el tabbar no esta visible, no se muestra.
--

-- Show which key table is active in the status area
mm_wezterm.on('update-status', mm_ugeneralui.callback_update_status)


-- Actualizar la barra cada 1 segundo (opcional)
--mod.status_update_interval = 1000,



------------------------------------------------------------------------------------
-- Setting> Wezterm Damains
------------------------------------------------------------------------------------
--
-- Los domains que se definen el WezTerm son:
--   > Local Doamin
--     > Si la terminal esta en Linux/MacOS este se comunica con el 'multiplexer server' usando socket IPC (la terminal hace de cliente IPC
--       y el 'mulitplexer server' hace de server IPC).
--     > Es un 'multiplexing domain' (asociado al a su 'multiplexer server') con un workspace creado por defecto llaamdo 'default'.
--   > WSL Domains
--     > Definido a nivel terminal (cliente) y solo en Windows.
--     > La termninal (cliente) define un dominio WSL2 al cual conectarse.
--     > Este no crea un 'mulitplxing domain', por lo que el tab creado se crea en el worskpace actual dentro del 'multiplexer server' actual.
--   > SSH Damains (se conecta a un servidor SSH el cual puede tener o no un 'multiplexer server').
--     > Definido a nivel cliente (terminal GUI) que hace de cliente SSH y que tiene acceso a un servidor SSH.
--     > A nivel de servidor SSH, solo se requiere configurar cuando se usara un 'multiplexer server' remoto.
--     > Puede ser de 2 tipos:
--       > El servidor SSH no tiene un 'multiplexer server' ejecutandose.
--         > El dominio no es considerado un 'multiplexing domain'.
--       > El servidor SSH tiene un 'multiplexer server' ejecutandose.
--         > El dominio es considerado un 'multiplexing domain'.
--   > TLS Domains (una terminal hace de cliente TLS que se conecta a un 'multiplexer server' que hace de servidor TLS).
--     > Debe definirse tanto a nivel cliente (terminal GUI) que hace de cliente TLS como a nivel 'multiplexer server' que hace de servidor TLS.
--     > Usado para conectarse de forma remota a un 'multiplexer server'.
--     > Si el 'multiplexer server' esta en un servidor SSH, este puede iniciarse e inicializarse (crear certificados autofirmados) automaticamente
--       cuando un cliente se conecta es este dominio.
--     > Si el 'multiplexer server' no esta en un servidor SSH (por ejemplo en un Windows Server sin esa capacidad), el 'multiplexer server' debe
--       iniciarse manualmente.
--     > Siempre define un 'multiplexing domain'.
--   > Unix Damains
--     > Debe definirse tanto a nivel cliente (terminal GUI) que hace de cliente IPC como a nivel 'multiplexer server' que hace de servidor IPC.
--     > Debido a que socket IPC es usado para comunicacion local, usualmente el cliente IPC y el server IPC estan en la misma equipo.
--       Una excepcion a esta regla es cuando se usa en WSL que es un VM especial que puede ser accedido localmente desde windows.
--     > Por cada socket IPC que se define se permite crear una nueva instancia de 'multiplexer server' al cual se puede conectar.
-- For more details, see: https://wezfurlong.org/wezterm/multiplexing.html
--

-- Cargar los dominios WSL
-- > URLs:
--   > https://wezterm.org/config/lua/WslDomain.html
local m_wsl_domains = nil
if m_os_type == 1 then

    -- Si es windows, realizar un 'wsl -l -v' para obtener todos los dominios de multiplexacion de tipo WSL
    -- > Sus campos por defecto son:
    --   > name         : Los dominios creados tendran un nombre 'WSL:<distritucion>'
    --   > username     :
    --   > default_cwd  : '~'
    --   > default_prog : Shell predetermino de la distribucion WSL2
    -- > URLs:
    --   > https://wezterm.org/config/lua/wezterm/default_wsl_domains.html?h=wsl
    m_wsl_domains = mm_wezterm.default_wsl_domains()
    mod.wsl_domains = m_wsl_domains
end

-- Cargar los dominios SSH usando el archivo de configuracion '~/.ssh/config'.
-- > URLs:
--   > https://wezterm.org/config/lua/SshDomain.html
local m_ssh_domains = mm_ugeneralui.get_ssh_domains(m_custom_config.ssh_domains)

if m_ssh_domains ~= nil then
    mod.ssh_domains = m_ssh_domains
end

-- Establecer los Socket IPC domains
-- > URLs:
--   > https://wezterm.org/multiplexing.html#unix-domains
local m_unix_domains = mm_ugeneralui.get_unix_domains(m_custom_config.unix_domains)

if m_unix_domains ~= nil then
    mod.unix_domains = m_unix_domains
end

-- Establecer los TLS domains
-- > URLs:
--   > https://wezterm.org/multiplexing.html#tls-domains
local m_tls_clients = m_custom_config.tls_clients

if m_tls_clients ~= nil then
    mod.tls_clients = m_tls_clients
end


-- Sets which ssh backend should be used by default for the integrated ssh client.
-- Possible values are:
-- - "Ssh2"   - use libssh2
-- - "LibSsh" - use libssh
--mod.ssh_backend = "Libssh"

-- When set to true (the default), wezterm will configure the SSH_AUTH_SOCK environment variable for panes spawned in the local domain.
--mod.mux_enable_ssh_agent = false




------------------------------------------------------------------------------------
-- Setting> Windows> Cursor
------------------------------------------------------------------------------------

-- Specifies the default cursor style for prompt. Various escape sequences can override the default style in different situations
-- (eg: an editor can change it depending on the mode), but this value controls how the cursor appears when it is reset to default.
-- Acceptable values are SteadyBlock, BlinkingBlock, SteadyUnderline, BlinkingUnderline, SteadyBar, and BlinkingBar.
-- The default is SteadyBlock.
mod.default_cursor_style = "BlinkingBlock"

-- Specifies the easing function to use when computing the color for the text cursor when it is set to a blinking style.
--mod.cursor_blink_ease_in = "Constant"

-- Specifies the easing function to use when computing the color for the text cursor when it is set to a blinking style.
--mod.cursor_blink_ease_out = "Constant"

-- Specifies how often a blinking cursor transitions between visible and invisible, expressed in milliseconds. Setting this to 0 disables blinking.
-- It is recommended to avoid blinking cursors when on battery power, as it is relatively costly to keep re-rendering for the blink!.
--mod.cursor_blink_rate = 700



------------------------------------------------------------------------------------
-- Setting> Hyperlinks
------------------------------------------------------------------------------------

-- Defines rules to match text from the terminal output and generate clickable links.
-- The value is a list of rule entries. Each entry has the following fields:
-- > regex
--   the regular expression to match (see supported Regex syntax)
-- > format
--   Controls which parts of the regex match will be used to form the link. Must have a prefix: signaling the protocol type (e.g., https:/mailto:),
--   which can either come from the regex match or needs to be explicitly added. The format string can use placeholders like $0, $1, $2 etc.
--   that will be replaced with that numbered capture group. So, $0 will take the entire region of text matched by the whole regex,
--   while $1 matches out the first capture group. In the example below, mailto:$0 is used to prefix a protocol to the text to make it into an URL.
-- The default value for hyperlink_rules can be retrieved using wezterm.default_hyperlink_rules():
-- > Matches: a URL in parens: (URL)
-- > Matches: a URL in brackets: [URL]
-- > Matches: a URL in curly braces: {URL}
-- > Matches: a URL in angle brackets: <URL>
-- > Then handle URLs not wrapped in brackets
-- > Implicit mailto link
--mod.hyperlink_rules = mm_wezterm.default_hyperlink_rules()

-- Add custom rules to array '.hyperlink_rules'

-- Example: make task numbers clickable the first matched regex group is captured in $1.
--table.insert(mod.hyperlink_rules, {
--    regex = [[\b[tt](\d+)\b]],
--    format = 'https://example.com/tasks/?t=$1',
--  })



------------------------------------------------------------------------------------
-- Setting> Key bindings
------------------------------------------------------------------------------------
-- Los 'keybord shorcut' capturados por la ventana wezterm, no es enviado a los paneles. Por tal motivo desabilitelo, si desea
-- que estos no sean procesados por la ventana y sean procesados por el panel actual.
-- La lista inicial se obtuvo de 'wezterm show-keys --lua' y luego se depurando para nuestro layout de teclado en ingles.


-- If you don't want the default assignments to be registered, you can disable all of them with this configuration;
-- Default key binding: https://wezfurlong.org/wezterm/config/default-keys.html
-- Wezterm ofrece un default keybinding que soporta diferentes layout de teclado, por lo que genera muchos mapeos adicionales.
-- Por tal motivo no usaremos el por defecto.
mod.disable_default_key_bindings = true


-- Controls how keys without an explicit phys: or mapped: prefix are treated.
-- If key_map_preference = "Mapped" (the default), then mapped: is assumed. If key_map_preference = "Physical" then phys: is assumed.
mod.key_map_preference = "Mapped"


-- Leader key (called 'LEADER') stays active until a keypress is registered (whether it matches a key binding or not),
-- or until it has been active for the duration specified by timeout_milliseconds, at which point it will automatically cancel itself.
mod.leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 2000 }

-- Keybinding de los otros modos y los 'ActivateKeyTable' del modo normal.
mod.key_tables = mm_ugeneralui.get_keytables_mappins()

-- Keybinding del modo normal
mod.keys = mm_ugeneralui.get_key_mappins()



------------------------------------------------------------------------------------
-- Setting> Parametros de inicio de Terminal GUI (usando subcomando 'start')
--------------------------------------------------------------------------------
--
-- No aplica si se inicia sin subcomandos ('wezterm-gui' o 'wezterm') y se configura el parametro 'config.default_gui_startup_args'
-- que no sea '{"start"}'.
-- Es decir, no aplica si la terminal se crea usando 'wezterm connect', 'wezterm ssh' o 'wezterm serial'.
--

-- Establecer el dominio por defecto a usar.
-- Si no se define el domonio por defecto sera 'local'.
if m_custom_config.default_domain ~= nil then
    mod.default_domain = m_custom_config.default_domain
end

-- Programa por defecto a ejecutar cuando se crea un nuevo tab del dominio 'local'. Si no se especifica se usara el shell predeterminado
-- del usuario actual que usa la terminal GUI.
-- > En otros dominios su valor se especifica cuando se define el dominio. Excepto cuando es un 'multiplexing domain' el shell a usar
--   siempre es el shell predterminado donde se ejecuta el 'multiplexer domain'.
if m_custom_config.default_prog ~= nil then
    mod.default_prog = m_custom_config.default_prog
	--print(mod.default_prog)
end



------------------------------------------------------------------------------------
-- Setting> Otros
------------------------------------------------------------------------------------

-- The launcher menu is accessed from the new tab button in the tab bar UI; the + button to the right of the tabs. Left clicking on the button will spawn a new tab,
-- but right clicking on it will open the launcher menu. You may also bind a key to the ShowLauncher or ShowLauncherArgs action to trigger the menu.
-- The launcher menu by default lists the various non-lolcal multiplexer domains and offers the option of connecting and spawning tabs/windows in those domains.
if m_custom_config.launch_menu ~= nil then
    mod.launch_menu = m_custom_config.launch_menu
end



------------------------------------------------------------------------------------
-- Setting> Setup insternal modules
------------------------------------------------------------------------------------

-- Establecer los dominios creados (usdos en la busqueda de dominios)
mm_ucommon.set_domains_info(m_ssh_domains, m_unix_domains, m_tls_clients, m_wsl_domains)

-- Establecer los argumentos que se estabecera a zoxide
local mm_uworkspace = require('utils.workspace')
mm_uworkspace.setup(nil)



------------------------------------------------------------------------------------
--
-- Return the configuration to wezterm
--
return mod
