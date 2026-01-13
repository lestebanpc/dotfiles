------------------------------------------------------------------------------------
-- My settings variables
------------------------------------------------------------------------------------

local mm_ucommon = require("utils.common")

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


-- Establece el 'default current working directory' a ser usando durante la creacion de un panel (cuando API 'SpawnCommand' no especifica
-- la opcion '.cwd'). Tiene limitaciones respecto si el Domain del panel a crear esta asociado a 'MuxDomain' remoto.
-- The value is a string specifying the absolute path that should be used for the home directory (no use relative path or '~').
-- Vease: https://wezterm.org/config/lua/config/default_cwd.html
if m_custom_config.default_cwd ~= nil then
    mod.default_cwd = m_custom_config.default_cwd
end
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

-- Ruta de los folderes de directorios personalizados (diferentes a la rutas reservadas del sistema) donde estan los archivos de fuentes.
-- Usado cuando no tiene acceso a colocar archivos de fuentes en las rutas reservadas para el sistema o el usuario actual.
if m_custom_config.font_dirs ~= nil then

    mod.font_dirs = m_custom_config.font_dirs

end

-- Si es 'ConfigDirsOnly' solo se usaran las fuentes integradas y las fuentes especificadas en los folderes 'font_dirs' (descarta las fuentes
-- del sistema).
if m_custom_config.font_locator ~= nil then

    --font_locator = "ConfigDirsOnly",
    mod.font_locator = m_custom_config.font_locator

end

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

-- Establecer el valor por defecto del estilo de ventana a usar.
-- > 'm_custom_config.windows_style' define elstilo a usar en la ventana de la terminal y pede ser:
--    0 > Se establece el por defecto.
--    1 > Muestra el 'title bar' ocultando el 'tab bar' si existe solo 1 tab (estilo 'TITLE|RESIZE')
--    2 > Muestra el 'title bar' y siempre muestra el 'tab bar' (estilo 'TITLE|RESIZE')
--    3 > Solo muestra el 'tab bar' el cual incluyen los botones cerrar, maximizar, minimizar (estilo 'INTEGRATED_BUTTONS|RESIZE')
if m_custom_config.windows_style == nil then
    m_custom_config.windows_style = 0
end

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
if m_custom_config.windows_style == 1  or m_custom_config.windows_style == 2 then
    mod.window_decorations = "TITLE|RESIZE"
elseif m_custom_config.windows_style == 3 then
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

-- Ocultar el 'tab bar' cuando solo se tiene un solo tab.
-- > Default is false.
if m_custom_config.windows_style == 3 or m_custom_config.windows_style == 2 then

    --Recomendado para estilo de tipo "INTEGRATED_BUTTONS|RESIZE"
    mod.hide_tab_bar_if_only_one_tab = false

elseif m_custom_config.windows_style == 1 then

    -- Ocultar el 'tab bar' cuando solo hay uno.
    mod.hide_tab_bar_if_only_one_tab = true

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
-- Setting> Damains
------------------------------------------------------------------------------------
--
-- > Un 'Domain' es a nivel emulador de terminal ('wezter-gui') define la forma en que se crearan los paneles de un tab (el proceso local a usar, el
--   interprete de shell a usar, los parametros que se usaran para crearlo) el cual puede ser complejo cuando este se conecta a shell o procesos
--   remotos.
--   > Un 'Domain' esta asociado a un 'MuxDomain' de un multiplexor (local o remoto).
--   > Se organiza según como se conecta al su `MuxDomain` de un multiplexor (local o remoto):
--
--     > Asociados a `MuxDomain` **local built-in** (si es un objeto de un multiplexor es el builtin o el externo pero en el mismo servidor y usando IPC)
--       - Siempre esta asociado un proceso locales ejecutado sobre un interprete shell del sistema
--       - Siempre crean un pseudo-terminal `tty` (local).
--       - Pueden ser:
--         > 'Local Domain'
--           - Sus paneles solo  proceso locales, usualmente el interprete shell
--         > 'Exec Domain'
--           - Sus paneles solo ejecutan proceso locales interactivos que están asociado al interprete shell del sistema.
--           - Usualmente estos procesos interactivos y locales esta asociado a:
--             - A un proceso local que crea pseudo-terminal local dentro del mismo namespace de procesos principal.
--             - A un proceso local que crea pseudo-terminal local pero esta en otro namespace de procesos (contenedores docker o similares como distrobox).
--             - A un proceso local que crea pseudo-terminal local pero que redirige a otro pseudo-terminal remota: kubernates, wsl, etc.
--	       > 'WSL Domain'
--           - Ejecutan un proceso local `wsl` y siempre esta asocaido a un `MuxDomain` del `built-in multiplexer`.
--           - Es un tipo especial de *Exec Domain*
--         > 'SSH Domain' built-in
--           - Si el 'SSH Domain' esta asociado al mulitplexor integrado a un 'multiplexer server'.
--           - Internamente es considerado un proceso 'ssh' que se ejecuta localmente pero requiere conectarse remotamente por SSH.
--
--     > Asociados a `MuxDomain` local IPC (si es un objeto de un multiplexor externo pero en el mismo servidor)
--       - Siempre esta asociado un proceso locales ejecutado sobre un interprete shell del sistema
--       - Siempre crean un pseudo-terminal `tty` (local).
--       - Pueden ser:
--         > 'Unix Damain'
--           - Siempre esta asociado a `MuxDomain` de un `multiplexer server` que esta local donde esta el emulador de terminal.
--           - Se usa socket IPC para comunicarse con este.
--
--     > Asociados a `MuxDomain` *remoto* (si es un objeto de un multiplexor externo que esta en otro servidor)
--       - Nunca crean un pseudo-terminal `tty` local (siempre crean uno remoto no asociado a este).
--       - Pueden ser:
--         > 'SSH Domain' remoto
--           - Si el 'SSH Domain' esta asociado a un 'MuxDomain' de un 'multiplexer server'.
--           - En su configuracion indica como conectarse al 'multiplexer server', y sera este el que decida como crear los 'MuxTab' y sus 'MuxPane'.
--           - Se usa SSH para comunicarse con el servidor.
--         > 'TSL Domain'
--           - Siempre esta asociado a 'MuxDomain' de un 'multiplexer server', este indica como conectarse al 'multiplexer server', y sera este el que
--             decida como crear los 'MuxTab' y sus 'MuxPane'.
--           - Se usa TLS para comunicarse con este, aunque tambien puede usarse SSH solo para el inicio automatico del 'multiplexer server'.
-- For more details, see: https://wezfurlong.org/wezterm/multiplexing.html
--

local mm_udomain = require("utils.domain")
mm_udomain.setup(
    m_custom_config.default_domain,
    m_custom_config.ssh_domains, m_custom_config.filter_config_ssh, m_custom_config.filter_config_ssh_mux,
    m_custom_config.unix_domains, m_custom_config.external_unix_domains,
    m_custom_config.tls_clients,
    m_custom_config.exec_domain_datas, m_custom_config.load_containers,
    m_custom_config.external_running_distribution, m_custom_config.program_paths.pwsh)

-- Cargar los dominios WSL
-- > URLs:
--   > https://wezterm.org/config/lua/WslDomain.html
if m_os_type == 1 then

    -- Si es windows, realizar un 'wsl -l -v' para obtener todos los dominios de multiplexacion de tipo WSL
    -- > Sus campos por defecto son:
    --   > name         : Los dominios creados tendran un nombre 'WSL:<distritucion>'
    --   > username     :
    --   > default_cwd  : '~'
    --   > default_prog : Shell predetermino de la distribucion WSL2
    -- > URLs:
    --   > https://wezterm.org/config/lua/wezterm/default_wsl_domains.html?h=wsl
    mod.wsl_domains = mm_udomain.get_wsl_domains()

end

-- Cargar los dominios SSH usando el archivo de configuracion '~/.ssh/config'.
-- > URLs:
--   > https://wezterm.org/config/lua/SshDomain.html
mod.ssh_domains = mm_udomain.get_ssh_domains()


-- Establecer los Socket IPC domains
-- > URLs:
--   > https://wezterm.org/multiplexing.html#unix-domains
mod.unix_domains = mm_udomain.get_unix_domains()


-- Establecer los TLS domains
-- > URLs:
--   > https://wezterm.org/multiplexing.html#tls-domains
mod.tls_clients = mm_udomain.get_tls_clients()

-- Establecer los Exec domains
mod.exec_domains = mm_udomain.get_exec_domains()

-- Sets which ssh backend should be used by default for the integrated ssh client.
-- Possible values are:
-- - "Ssh2"   - use libssh2
-- - "LibSsh" - use libssh
--mod.ssh_backend = "Libssh"

-- When set to true (the default), wezterm will configure the SSH_AUTH_SOCK environment variable for panes spawned in the local domain.
if m_os_type == 1 then
    -- En Windows y usando la implementacion de OpenSSH de Windows, no usa el valor existente de SSH_AUTH_SOCK, para generar uno nuevo
    -- Vease: https://github.com/wezterm/wezterm/issues/5817
    mod.mux_enable_ssh_agent = false
end




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
    mod.default_prog = m_custom.default_prog
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

-- Establecer los argumentos que se estabecera a zoxide
local mm_uworkspace = require('utils.workspace')
mm_uworkspace.setup(
    m_custom_config.workspace_tags, m_custom_config.load_local_builtin_tags, m_custom_config.load_external_builtin_tags,
    m_custom_config.root_git_folder, m_custom_config.external_root_git_folder,
    nil, m_custom_config.program_paths.fd, m_custom_config.program_paths.zoxide)



------------------------------------------------------------------------------------
--
-- Return the configuration to wezterm
--
return mod
