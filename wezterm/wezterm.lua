------------------------------------------------------------------------------------
-- My functions 
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
local function l_get_os_type (p_target_triple)

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


------------------------------------------------------------------------------------
-- Carge del modulo 'wezterm'
------------------------------------------------------------------------------------

local wezterm = require 'wezterm'

-- Obtain the default configuration. See: https://wezfurlong.org/wezterm/config/lua/config/index.html
local config = wezterm.config_builder()


------------------------------------------------------------------------------------
-- My settings variables
------------------------------------------------------------------------------------

--1. Determinar el tipo de SO
--   0 > Si es Linux
--   1 > Si es Windows
--   2 > Si es MacOS (Apple Silicon)
--   3 > Si es MacOS (Intel)
local l_os_type = l_get_os_type(wezterm.target_triple)
--print(l_os_type)

--2. Obtener las variables a usar al ejecutar el modulo/script de mis configuraciones
--local l_myconfig
local l_ok, l_myconfig = pcall(require, 'config')
--local l_ok = true  
if not l_ok then

    -- Establecer valores por defecto a las variables
    l_myconfig = {

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
        wsl_domains= nil,
        ssh_domains = nil,
        launch_menu = nil,
        windows_style = 0,
        
    }
	
	print("Module 'config' no load due to not exist ot have a error")

end

--l_myconfig = require("config")
--print(l_myconfig.color_scheme)
--print(l_myconfig.default_prog)
--print(package.path)

------------------------------------------------------------------------------------
-- Setting> General
------------------------------------------------------------------------------------

-- If false, do not try to use a Wayland protocol connection when starting the gui frontend, and instead use X11.
if l_os_type == 0 then
    config.enable_wayland = l_myconfig.enable_wayland
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
config.term = 'xterm-256color'
--config.term = 'wezterm'

-- Create my custom scheme based on a built-in schema.
-- Built-in scheme: https://wezfurlong.org/wezterm/colorschemes/index.html
local scheme = wezterm.get_builtin_color_schemes()[l_myconfig.color_scheme]
scheme.foreground = '#c0bfbc'
scheme.background = '#000000'
config.color_schemes = {
    ['lepc-schema']= scheme
  }

-- Specifies the current color schemes in your configuration file.
config.color_scheme = 'lepc-schema'
--config.color_scheme = 'Ayu Dark (Gogh)'


-- Sets the default current working directory used by the initial window.
-- The value is a string specifying the absolute path that should be used for the home directory (no use relative path or '~').
--config.default_cwd = "$HOME"

-- Specifies the name of the default workspace. The default is "default".
--config.default_workspace = "default"

-- Wezterm checks regularly if there is a new stable version available on github, and shows a simple UI to let you
-- know about the update (See show_update_window to control this UI). By default it is checked once every 24 hours.
config.check_for_updates = false
--config.check_for_updates_interval_seconds = 86400

-- When the BEL ascii sequence is sent to a pane, the bell is "rung" in that pane.
-- You may choose to configure the audible_bell option to change the sound that wezterm makes when the bell rings.
-- The follow are possible values:
--    "SystemBeep" - perform the system beep or alert sound. This is the default. On Wayland systems, which have no system beep function, it does not produce a sound.
--    "Disabled" - don't make a sound
--config.audible_bell = "Disabled"

-- If true, the mouse cursor will be hidden when typing, if your mouse cursor is hovering over the window.
-- The default is true. Set to false to disable this behavior.
--config.hide_mouse_cursor_when_typing = true

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
--if l_os_type == 1 then
--    config.canonicalize_pasted_newlines = "CarriageReturnAndLineFeed"
--else
--    config.canonicalize_pasted_newlines = "CarriageReturn"
--end

------------------------------------------------------------------------------------
-- Setting> Font
------------------------------------------------------------------------------------

-- Specifying an ordered list of fonts.
-- when resolving text into glyphs the first font in the list is consulted, and if the glyph isn't present in that font, WezTerm proceeds to the next font in the fallback list.
config.font = wezterm.font_with_fallback({
    { 
      family= "JetBrainsMono Nerd Font Mono", 
      weight= "Light", -- "Thin", "ExtraLigth", "Light", "Regular", "Medium", "SemiBold", "Bold", "ExtraBold"
      stretch= "Normal",
      italic = false,
      harfbuzz_features= {"calt=1", "clig=1", "liga=1"},
    },
    "Incosolata LGC Nerd Font Mono",
  })

-- Specifies the size of the font, measured in points. You may use fractional point sizes, such as 13.3, to fine tune the size.
-- The default font size is 12.0
config.font_size = l_myconfig.font_size
--config.font_size = 11

--config.bold_brightens_ansi_colors = true
config.warn_about_missing_glyphs = true

-- Controls whether the Input Method Editor (IME) will be used to process keyboard input. 
-- The IME is useful for inputting kanji or other text that is not natively supported by the attached keyboard hardware.
config.use_ime = false


------------------------------------------------------------------------------------
-- Setting> Windows> General
------------------------------------------------------------------------------------

--print(l_myconfig.windows_style)

-- Si no esta definido el estilo de la ventana, definirlo
-- Estilo a usar en la ventana de la terminal
--  0 > Se establece el por defecto.
--  1 > Se usa el estilo 'TITLE|RESIZE'
--  2 > Se usa el estilo 'INTEGRATED_BUTTONS|RESIZE'
if l_myconfig.windows_style == 0 then
    
    if l_os_type == 0 then
        if l_myconfig.enable_wayland then
            l_myconfig.windows_style = 1
        else
            --l_myconfig.windows_style = 1
            l_myconfig.windows_style = 2
        end
    else
        l_myconfig.windows_style = 2
    end
    
end

--print(l_myconfig.windows_style)


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
if l_myconfig.windows_style == 1 then
    config.window_decorations = "TITLE|RESIZE"
elseif l_myconfig.windows_style == 2 then
    config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
end

-- Configures the visual style of the tabbar-integrated titlebar button replacements that are shown when window_decorations = "INTEGRATED_BUTTONS|RESIZE".
-- Possible styles are:
-- > "Windows"     - draw Windows-style buttons
-- > "Gnome"       - draw Adwaita-style buttons
-- > "MacOsNative" - on macOS only, move the native macOS buttons into the tab bar.
-- The default value is "MacOsNative" on macOS systems, but "Windows" on other systems.
--config.integrated_title_button_style = "Windows"

-- Configures the ordering and set of window management buttons to show when window_decorations = "INTEGRATED_BUTTONS|RESIZE".
-- The value is a table listing the buttons. Each element can have one of the following values:
-- > "Hide"     - the window hide or minimize button
-- > "Maximize" - the window maximize button
-- > "Close"    - the window close button
-- The default value is equivalent to: "{ 'Hide', 'Maximize', 'Close' }"
--config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }

-- Configures the alignment of the set of window management buttons when window_decorations = "INTEGRATED_BUTTONS|RESIZE".
-- Possible values are:
-- > "Left"  - the buttons are shown on the left side of the tab bar
-- > "Right" - the buttons are shown on the right side of the tab bar
config.integrated_title_button_alignment = "Right"

-- Configures the color of the set of window management buttons when window_decorations = "INTEGRATED_BUTTONS|RESIZE".
-- Possible values are:
-- > "Auto" - automatically compute the color
-- > "red"  - Use a custom color
config.integrated_title_button_color = "auto"

-- If it's 'AlwaysPrompt' display a confirmation prompt when the window is closed by the windowing environment, 
-- either because the user closed it with the window decorations, or instructed their window manager to close it.
-- Set this to "NeverPrompt" if you don't like confirming closing windows every time.
--config.window_close_confirmation = "NeverPrompt"

-- Control whether changing the font size adjusts the dimensions of the window (true) or adjusts the number of terminal rows/columns (false). 
-- If you use a tiling window manager then you may wish to set this to false.
-- The default value is now nil which causes wezterm to match the name of the connected window environment (which you can see if you open the debug overlay) 
-- against the list of known tiling environments configured by tiling_desktop_environments. 
-- If the environment is known to be tiling then the effective value of adjust_window_size_when_changing_font_size is false, and true otherwise.
config.adjust_window_size_when_changing_font_size = true

-- Controls the amount of padding between the window border and the terminal cells. Padding is measured in pixels.
-- If enable_scroll_bar is true, then the value you set for right will control the width of the scrollbar. 
-- If you have enabled the scrollbar and have set right to 0 then the right padding (and thus the scrollbar width) will instead match the width of a cell.
if l_myconfig.enable_scrollbar then
    config.window_padding = {
        left = 4,
        right = 8,
        top = 4,
        bottom = 4,
    }
else
    config.window_padding = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4,
    }
end

-- Initial window size on startup
config.initial_rows = 30
config.initial_cols = 150

-- Controls the behavior when the shell program spawned by the terminal exits. There are three possible values:
-- > "Close"           : close the corresponding pane as soon as the program exits.
-- > "Hold"            : keep the pane open after the program exits. The pane must be manually closed via CloseCurrentPane, CloseCurrentTab or closing the window.
-- > "CloseOnCleanExit": if the shell program exited with a successful status, behave like "Close", otherwise, behave like "Hold". This is the default setting.
config.exit_behavior = "Close"
--config.window_background_opacity = 0.99


------------------------------------------------------------------------------------
-- Setting> Windows> Cursor
------------------------------------------------------------------------------------

-- Specifies the default cursor style for prompt. Various escape sequences can override the default style in different situations 
-- (eg: an editor can change it depending on the mode), but this value controls how the cursor appears when it is reset to default.
-- Acceptable values are SteadyBlock, BlinkingBlock, SteadyUnderline, BlinkingUnderline, SteadyBar, and BlinkingBar.
-- The default is SteadyBlock.
config.default_cursor_style = "BlinkingBlock"

-- Specifies the easing function to use when computing the color for the text cursor when it is set to a blinking style.
--config.cursor_blink_ease_in = "Constant"

-- Specifies the easing function to use when computing the color for the text cursor when it is set to a blinking style.
--config.cursor_blink_ease_out = "Constant"

-- Specifies how often a blinking cursor transitions between visible and invisible, expressed in milliseconds. Setting this to 0 disables blinking.
-- It is recommended to avoid blinking cursors when on battery power, as it is relatively costly to keep re-rendering for the blink!.
--config.cursor_blink_rate = 700

------------------------------------------------------------------------------------
-- Setting> Windows> TabBar autogenerado por Wezterm
------------------------------------------------------------------------------------

-- Controls whether the tab bar is enabled. Set to false to disable it.
config.enable_tab_bar = true

-- If set to true, when there is only a single tab, the tab bar is hidden from the display. If a second tab is created, the tab will be shown.
-- Default is false.
if l_myconfig.windows_style == 2 then

    --Recomendado para estilo de tipo "INTEGRATED_BUTTONS|RESIZE"
    config.hide_tab_bar_if_only_one_tab = false

elseif l_myconfig.windows_style == 1 then

    --Recomendado para estilo de tipo "TITLE|RESIZE"
    config.hide_tab_bar_if_only_one_tab = true

    --Wayland error: No muestra la barra de titulo generado por el sistema/Wayland
    if (l_os_type == 0) and l_myconfig.enable_wayland then
        config.hide_tab_bar_if_only_one_tab = false
    end

end

-- When tab_bar_at_bottom = true, the tab bar will be rendered at the bottom of the window rather than the top of the window.
-- The default is false.
--config.tab_bar_at_bottom = false

-- When set to true (the default), the tab bar is rendered in a 'native tabbar style' with proportional fonts.
-- When set to false, the tab bar is rendered using a 'retro tabbar style' using the main terminal font.
-- Retro  TabBar Style: https://wezfurlong.org/wezterm/config/appearance.html#retro-tab-bar-appearance
-- Native TabBar Style (Fancy TabBar Style): https://wezfurlong.org/wezterm/config/appearance.html#tab-bar-appearance-colors
-- Futuras mejoras: https://github.com/wez/wezterm/issues/1180#issuecomment-1493128725
config.use_fancy_tab_bar = true 

-- Estilo de borde de la ventana el cual incluye:
--  > Estilo por defecto del TabBar autogenerado por Wezterm.
--  > Estilo del borde de la ventana. 
--    En Linux, X11 no permite cambiar el borde de la ventana en Wayland si 
-- No incluye la barra de titulo por defecto generado por el gestor de ventana o escritorio.
-- Url: https://wezfurlong.org/wezterm/config/lua/config/window_frame.html?h=window_frame
config.window_frame = {
    --'Roboto' es una fuente no-mono (proporcional) integrada/built-in dentro del binario de wezterm 
    font = wezterm.font 'Roboto',
    font_size = 10,
}

-- Specifies the maximum width that a tab can have in the tab bar when using retro tab mode. It is ignored when using fancy tab mode.
-- Defaults to 16 glyphs in width.
--config.tab_max_width = 32

-- When set to true (the default), tab titles show their tab number (tab index) with a prefix such as "1:". 
-- When false, no numeric prefix is shown.
-- The tab_and_split_indices_are_zero_based setting controls whether numbering starts with 0 or 1.
--config.show_tab_index_in_tab_bar = false

-- When set to true (the default), the tab bar will display the new-tab button, which can be left-clicked to create a new tab, 
-- or right-clicked to display the Launcher Menu. When set to false, the new-tab button will not be drawn into the tab bar.
--config.show_new_tab_button_in_tab_bar = true

-- If set to true, when the active tab is closed, the previously activated tab will be activated. 
-- Otherwise, the tab to the left of the active tab will be activated. Default is false.
--config.switch_to_last_active_tab_when_closing_tab = true


-- Event 'format-tab-title' usado para cambiar el estilo del tab activo/inactivo, remplazando a la funcion 'tab_bar_style'.
-- Esto complementa el estilo usado para el tab 'https://wezfurlong.org/wezterm/config/appearance.html#retro-tab-bar-appearance'.
-- Url: 'https://wezfurlong.org/wezterm/config/lua/window-events/format-tab-title.html'

---- Callback that change returns the suggested title for a tab. 
---- It prefers the title that was set via `tab:set_title()` or `wezterm cli set-tab-title`, 
---- but falls back to the title of the active pane in that tab.
--function tab_title(tab_info)
--  local title = tab_info.tab_title
--  -- if the tab title is explicitly set, take that
--  if title and #title > 0 then
--    return title
--  end
--  -- Otherwise, use the title from the active pane
--  -- in that tab
--  return tab_info.active_pane.title
--end
--
---- Event controller that change returns the suggested title and style for a tab. 
--local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider  -- The filled in variant of the < symbol
--local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider  -- The filled in variant of the > symbol
--
--wezterm.on(
--  'format-tab-title',
--  function(tab, tabs, panes, config, hover, max_width)
--    local edge_background = '#0b0022'
--    local background = '#1b1032'
--    local foreground = '#808080'
--
--    if tab.is_active then
--      background = '#2b2042'
--      foreground = '#c0c0c0'
--    elseif hover then
--      background = '#3b3052'
--      foreground = '#909090'
--    end
--
--    local edge_foreground = background
--
--    local title = tab_title(tab)
--
--    -- ensure that the titles fit in the available space, and that we have room for the edges.
--    title = wezterm.truncate_right(title, max_width - 2)
--
--    return {
--      { Background = { Color = edge_background } },
--      { Foreground = { Color = edge_foreground } },
--      { Text = SOLID_LEFT_ARROW },
--      { Background = { Color = background } },
--      { Foreground = { Color = foreground } },
--      { Text = title },
--      { Background = { Color = edge_background } },
--      { Foreground = { Color = edge_foreground } },
--      { Text = SOLID_RIGHT_ARROW },
--    }
--  end
--)


------------------------------------------------------------------------------------
-- Setting> Windows> Scroll
------------------------------------------------------------------------------------

-- Enable the scrollbar. This is currently disabled by default. It will occupy the right window padding space.
config.enable_scroll_bar = l_myconfig.enable_scrollbar

-- Lines of scrollback you want to retain (in memory) per tab (default is 3500)
config.scrollback_lines = 5000 


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
--config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Add custom rules to array '.hyperlink_rules'

-- Example: make task numbers clickable the first matched regex group is captured in $1.
--table.insert(config.hyperlink_rules, {
--    regex = [[\b[tt](\d+)\b]],
--    format = 'https://example.com/tasks/?t=$1',
--  })

------------------------------------------------------------------------------------
-- Setting> Key bindings
------------------------------------------------------------------------------------
-- Los 'keybord shorcut' capturados por la ventana wezterm, no es enviado a los paneles. Por tal motivo desabilitelo, si desea
-- que estos no sean procesados por la ventana y sean procesados por el panel actual.
-- La lista inicial se obtuvo de 'wezterm show-keys --lua' y luego se depurando para nuestro layout de teclado en ingles.
-- TODO: Adecuar para MacOS ¿por ejemplo cambiar SUPER con ..? 


-- If you don't want the default assignments to be registered, you can disable all of them with this configuration; 
-- Default key binding: https://wezfurlong.org/wezterm/config/default-keys.html
-- Wezterm ofrece un default keybinding que soporta diferentes layout de teclado, por lo que genera muchos mapeos adicionales.
-- Por tal motivo no usaremos el por defecto.
config.disable_default_key_bindings = true


-- Controls how keys without an explicit phys: or mapped: prefix are treated.
-- If key_map_preference = "Mapped" (the default), then mapped: is assumed. If key_map_preference = "Physical" then phys: is assumed.
config.key_map_preference = "Mapped"


-- Leader key (called 'LEADER') stays active until a keypress is registered (whether it matches a key binding or not), 
-- or until it has been active for the duration specified by timeout_milliseconds, at which point it will automatically cancel itself.
config.leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 1000 }

-- Keybinding del modo normal
local l_action = wezterm.action
config.keys = {

    --1. Ingresar a un determinado modo
    { key = 'f', mods = 'CTRL|SHIFT', action = l_action.Search 'CurrentSelectionOrEmptyString' },
    --{ key = 'f', mods = 'SUPER', action = l_action.Search 'CurrentSelectionOrEmptyString' },
    { key = 'phys:Space', mods = 'CTRL|SHIFT', action = l_action.QuickSelect },
    { key = 'w', mods = 'CTRL|SHIFT', action = l_action.ActivateCopyMode },
    { key = 'u', mods = 'CTRL|SHIFT', action = l_action.CharSelect{ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' } },


    --2. Scrollback del panel actual en modo normal (Limpieza y navegacion)
    --{ key = 'k', mods = 'CTRL|SHIFT', action = l_action.ClearScrollback 'ScrollbackOnly' },
    --{ key = 'k', mods = 'SUPER', action = l_action.ClearScrollback 'ScrollbackOnly' },
    { key = 'PageUp', mods = 'SHIFT', action = l_action.ScrollByPage(-1) },
    { key = 'PageDown', mods = 'SHIFT', action = l_action.ScrollByPage(1) },
    { key = 'UpArrow', mods = 'CTRL|SHIFT', action = l_action.ScrollByLine(-1) },
    { key = 'DownArrow', mods = 'CTRL|SHIFT', action = l_action.ScrollByLine(1) },
    { key = 'Home', mods = 'SHIFT', action = l_action.ScrollToTop },
    { key = 'End', mods = 'SHIFT', action = l_action.ScrollToBottom },
    { key = 'z', mods = 'CTRL|SHIFT', action = l_action.ScrollToPrompt(-1) },
    { key = 'x', mods = 'CTRL|SHIFT', action = l_action.ScrollToPrompt(1) },

    --3. Gestion del Tab de la terminal
    { key = '1', mods = 'ALT', action = l_action.ActivateTab(0) },
    --{ key = '1', mods = 'SUPER', action = l_action.ActivateTab(0) },
    { key = '2', mods = 'ALT', action = l_action.ActivateTab(1) },
    --{ key = '2', mods = 'SUPER', action = l_action.ActivateTab(1) },
    { key = '3', mods = 'ALT', action = l_action.ActivateTab(2) },
    --{ key = '3', mods = 'SUPER', action = l_action.ActivateTab(2) },
    { key = '4', mods = 'ALT', action = l_action.ActivateTab(3) },
    --{ key = '4', mods = 'SUPER', action = l_action.ActivateTab(3) },
    { key = '5', mods = 'ALT', action = l_action.ActivateTab(4) },
    --{ key = '5', mods = 'SUPER', action = l_action.ActivateTab(4) },
    { key = '6', mods = 'ALT', action = l_action.ActivateTab(5) },
    --{ key = '6', mods = 'SUPER', action = l_action.ActivateTab(5) },
    { key = '7', mods = 'ALT', action = l_action.ActivateTab(6) },
    --{ key = '7', mods = 'SUPER', action = l_action.ActivateTab(6) },
    { key = '8', mods = 'ALT', action = l_action.ActivateTab(7) },
    --{ key = '8', mods = 'SUPER', action = l_action.ActivateTab(7) },
    { key = '9', mods = 'ALT', action = l_action.ActivateTab(-1) },
    --{ key = '9', mods = 'SUPER', action = l_action.ActivateTab(-1) },

    --{ key = 'Tab', mods = 'CTRL', action = l_action.ActivateTabRelative(1) },
    --{ key = ']', mods = 'SUPER|SHIFT', action = l_action.ActivateTabRelative(1) },
    --{ key = 'PageDown', mods = 'CTRL', action = l_action.ActivateTabRelative(1) },
    --{ key = '[', mods = 'SUPER|SHIFT', action = l_action.ActivateTabRelative(-1) },
    --{ key = 'Tab', mods = 'CTRL|SHIFT', action = l_action.ActivateTabRelative(-1) },
    --{ key = 'PageUp', mods = 'CTRL', action = l_action.ActivateTabRelative(-1) },

    --{ key = 'w', mods = 'CTRL|SHIFT', action = l_action.CloseCurrentTab{ confirm = true } },
    --{ key = 'w', mods = 'SUPER', action = l_action.CloseCurrentTab{ confirm = true } },
    { key = 't', mods = 'SUPER|SHIFT', action = l_action.SpawnTab 'DefaultDomain' },
    --{ key = 't', mods = 'SUPER', action = l_action.SpawnTab 'CurrentPaneDomain' },
    { key = 't', mods = 'CTRL|SHIFT', action = l_action.SpawnTab 'CurrentPaneDomain' },

    --4. Gestion del Panel del tab activo de la terminal

    { key = '-', mods = 'LEADER', action = l_action.SplitVertical{ domain =  'CurrentPaneDomain' } },
    { key = '=', mods = 'LEADER', action = l_action.SplitHorizontal{ domain =  'CurrentPaneDomain' } },
    { key = '|', mods = 'LEADER', action = l_action.SplitHorizontal{ domain =  'CurrentPaneDomain' } },
    { key = '|', mods = 'LEADER|SHIFT', action = l_action.SplitHorizontal{ domain =  'CurrentPaneDomain' } },
    --{ key = '|', mods = 'LEADER|SHIFT', action = l_action.SplitHorizontal{ domain =  'CurrentPaneDomain' } },

    { key = 'z', mods = 'LEADER', action = l_action.TogglePaneZoomState },
    
    { key = 'a', mods = 'LEADER', action = l_action.ActivateKeyTable{ name = 'activate_pane', one_shot = false, } },
    { key = 's', mods = 'LEADER', action = l_action.ActivateKeyTable{ name = 'resize_pane', one_shot = false, } },
    --{ key = 'a', mods = 'LEADER', action = l_action.ActivateKeyTable{ name = 'activate_pane', timeout_milliseconds = 1000, } },
    --{ key = 's', mods = 'LEADER', action = l_action.ActivateKeyTable{ name = 'resize_pane', timeout_milliseconds = 1000, } },

    --5. Gestion de la fuente usado por la terminal
    { key = '+', mods = 'CTRL', action = l_action.IncreaseFontSize },
    { key = '+', mods = 'CTRL|SHIFT', action = l_action.IncreaseFontSize },
    { key = '=', mods = 'CTRL', action = l_action.IncreaseFontSize },
    --{ key = '=', mods = 'SUPER', action = l_action.IncreaseFontSize },
    { key = '-', mods = 'CTRL', action = l_action.DecreaseFontSize },
    --{ key = '-', mods = 'SUPER', action = l_action.DecreaseFontSize },
    { key = '0', mods = 'CTRL', action = l_action.ResetFontSize },
    --{ key = '0', mods = 'SUPER', action = l_action.ResetFontSize },

    --6. Gestion del clipboard
    { key = 'c', mods = 'CTRL|SHIFT', action = l_action.CopyTo 'Clipboard' },
    --{ key = 'c', mods = 'SUPER', action = l_action.CopyTo 'Clipboard' },
    --{ key = 'Copy', mods = 'NONE', action = l_action.CopyTo 'Clipboard' },

    { key = 'v', mods = 'CTRL|SHIFT', action = l_action.PasteFrom 'Clipboard' },
    --{ key = 'v', mods = 'SUPER', action = l_action.PasteFrom 'Clipboard' },
    --{ key = 'Paste', mods = 'NONE', action = l_action.PasteFrom 'Clipboard' },

    { key = 'Insert', mods = 'CTRL', action = l_action.CopyTo 'PrimarySelection' },
    { key = 'Insert', mods = 'SHIFT', action = l_action.PasteFrom 'PrimarySelection' },


    -- Generales
    { key = 'phys:1', mods = 'CTRL|SHIFT', action = l_action.ShowLauncherArgs{ flags =  'LAUNCH_MENU_ITEMS' } },
    { key = 'phys:2', mods = 'CTRL|SHIFT', action = l_action.ShowLauncherArgs{ flags =  'FUZZY|DOMAINS' } },

    --{ key = 'a', mods = 'LEADER|CTRL', action = l_action.SendString '\u{1}' },
    { key = 'l', mods = 'LEADER', action = l_action.ShowDebugOverlay },
    --{ key = 'm', mods = 'CTRL|SHIFT', action = l_action.Hide },
    --{ key = 'p', mods = 'CTRL|SHIFT', action = l_action.ActivateCommandPalette },
    { key = 'r', mods = 'LEADER', action = l_action.ReloadConfiguration },

  }


-- Keybinding de los otros modos y los 'ActivateKeyTable' del modo normal.
config.key_tables = {

    --------------------------------------------------------------------------
    -- Modo de copia
    --------------------------------------------------------------------------
    copy_mode = {

      -- Salir del modo copia (de submodo inicial y submodo seleccion)
      { key = 'c', mods = 'CTRL', action = l_action.Multiple{ 'ScrollToBottom', { CopyMode =  'Close' } } },
      { key = 'g', mods = 'CTRL', action = l_action.Multiple{ 'ScrollToBottom', { CopyMode =  'Close' } } },
      { key = 'q', mods = 'NONE', action = l_action.Multiple{ 'ScrollToBottom', { CopyMode =  'Close' } } },
      { key = 'Escape', mods = 'NONE', action = l_action.Multiple{ 'ScrollToBottom', { CopyMode =  'Close' } } },

      -- Con una seleccion (desde el submodo seleccion), copiar al clipboard y salir de modo copia
      { key = 'y', mods = 'NONE', action = l_action.Multiple{ { CopyTo =  'ClipboardAndPrimarySelection' }, { Multiple = { 'ScrollToBottom', { CopyMode =  'Close' } } } } },

      -- Ingresar la submodo seleccion
      { key = 'Space', mods = 'NONE', action = l_action.CopyMode{ SetSelectionMode =  'Cell' } },
      { key = 'v', mods = 'NONE', action = l_action.CopyMode{ SetSelectionMode =  'Cell' } },
      { key = 'v', mods = 'SHIFT', action = l_action.CopyMode{ SetSelectionMode =  'Line' } },
      { key = 'v', mods = 'CTRL', action = l_action.CopyMode{ SetSelectionMode =  'Block' } },

      -- Modificar la selección actual horizontalmente (usado frecuentemente en ua selección rectangular) 
      { key = 'o', mods = 'NONE', action = l_action.CopyMode 'MoveToSelectionOtherEnd' },
      { key = 'o', mods = 'SHIFT', action = l_action.CopyMode 'MoveToSelectionOtherEndHoriz' },

      -- Navegacion basica (en el submodo inicio y selección)
      { key = 'h', mods = 'NONE', action = l_action.CopyMode 'MoveLeft' },
      { key = 'j', mods = 'NONE', action = l_action.CopyMode 'MoveDown' },
      { key = 'k', mods = 'NONE', action = l_action.CopyMode 'MoveUp' },
      { key = 'l', mods = 'NONE', action = l_action.CopyMode 'MoveRight' },
      { key = 'LeftArrow', mods = 'NONE', action = l_action.CopyMode 'MoveLeft' },
      { key = 'RightArrow', mods = 'NONE', action = l_action.CopyMode 'MoveRight' },
      { key = 'UpArrow', mods = 'NONE', action = l_action.CopyMode 'MoveUp' },
      { key = 'DownArrow', mods = 'NONE', action = l_action.CopyMode 'MoveDown' },

      -- Moverse en la misma linea actual
      { key = '^', mods = 'NONE', action = l_action.CopyMode 'MoveToStartOfLineContent' },
      { key = '^', mods = 'SHIFT', action = l_action.CopyMode 'MoveToStartOfLineContent' },
      { key = 'm', mods = 'ALT', action = l_action.CopyMode 'MoveToStartOfLineContent' },

      { key = '$', mods = 'NONE', action = l_action.CopyMode 'MoveToEndOfLineContent' },
      { key = '$', mods = 'SHIFT', action = l_action.CopyMode 'MoveToEndOfLineContent' },
      { key = 'End', mods = 'NONE', action = l_action.CopyMode 'MoveToEndOfLineContent' },

      { key = '0', mods = 'NONE', action = l_action.CopyMode 'MoveToStartOfLine' },
      { key = 'Home', mods = 'NONE', action = l_action.CopyMode 'MoveToStartOfLine' },

      -- Moverse al inicio de la siguiente linea a la actual
      { key = 'Enter', mods = 'NONE', action = l_action.CopyMode 'MoveToStartOfNextLine' },

      -- Moverse entre palabras anterior/siguiente
      { key = 'w', mods = 'NONE', action = l_action.CopyMode 'MoveForwardWord' },
      { key = 'f', mods = 'ALT', action = l_action.CopyMode 'MoveForwardWord' },
      { key = 'Tab', mods = 'NONE', action = l_action.CopyMode 'MoveForwardWord' },

      { key = 'b', mods = 'NONE', action = l_action.CopyMode 'MoveBackwardWord' },
      { key = 'b', mods = 'ALT', action = l_action.CopyMode 'MoveBackwardWord' },
      { key = 'LeftArrow', mods = 'ALT', action = l_action.CopyMode 'MoveBackwardWord' },
      { key = 'RightArrow', mods = 'ALT', action = l_action.CopyMode 'MoveForwardWord' },
      { key = 'Tab', mods = 'SHIFT', action = l_action.CopyMode 'MoveBackwardWord' },

      { key = 'e', mods = 'NONE', action = l_action.CopyMode 'MoveForwardWordEnd' },
      
      -- Moverse verticalmente dentro buffer del scrollback 
      { key = 'g', mods = 'NONE', action = l_action.CopyMode 'MoveToScrollbackBottom' },
      { key = 'g', mods = 'SHIFT', action = l_action.CopyMode 'MoveToScrollbackBottom' },

      { key = 'b', mods = 'CTRL', action = l_action.CopyMode 'PageUp' },
      { key = 'PageUp', mods = 'NONE', action = l_action.CopyMode 'PageUp' },
      { key = 'u', mods = 'CTRL', action = l_action.CopyMode{ MoveByPage = (-0.5) } },
      { key = 'f', mods = 'CTRL', action = l_action.CopyMode 'PageDown' },
      { key = 'PageDown', mods = 'NONE', action = l_action.CopyMode 'PageDown' },
      { key = 'd', mods = 'CTRL', action = l_action.CopyMode{ MoveByPage = (0.5) } },

      -- Mover el viewport dentro buffer del scrollback 
      { key = 'h', mods = 'SHIFT', action = l_action.CopyMode 'MoveToViewportTop' },
      { key = 'l', mods = 'SHIFT', action = l_action.CopyMode 'MoveToViewportBottom' },
      { key = 'm', mods = 'SHIFT', action = l_action.CopyMode 'MoveToViewportMiddle' },

      -- Navegacion por ¿busqueda?
      { key = ',', mods = 'NONE', action = l_action.CopyMode 'JumpReverse' },
      { key = ';', mods = 'NONE', action = l_action.CopyMode 'JumpAgain' },
      { key = 'f', mods = 'NONE', action = l_action.CopyMode{ JumpForward = { prev_char = false } } },
      --{ key = 'f', mods = 'SHIFT', action = l_action.CopyMode{ JumpBackward = { prev_char = false } } },
      { key = 't', mods = 'NONE', action = l_action.CopyMode{ JumpForward = { prev_char = true } } },
      --{ key = 't', mods = 'SHIFT', action = l_action.CopyMode{ JumpBackward = { prev_char = true } } },


    },
    
    --------------------------------------------------------------------------
    -- Modo de busqueda
    --------------------------------------------------------------------------
    search_mode = {
      -- Cambia el modo de búsqueda, reiniciando la búsqueda. Los modos de busqueda: "case-sensitive", "case-inssensitive" y "expresiones regulares".
      { key = 'r', mods = 'CTRL', action = l_action.CopyMode 'CycleMatchType' },
      -- Salir del modo de Busqeuda
      { key = 'Escape', mods = 'NONE', action = l_action.CopyMode 'Close' },
      -- Resetear la búsqueda (Limpia el criterio de búsqueda actual, pero no sale del modo de búsqueda)
      { key = 'u', mods = 'CTRL', action = l_action.CopyMode 'ClearPattern' },
      -- Busqueda de la siguiente/anterior coincidencia:
      { key = 'p', mods = 'CTRL', action = l_action.CopyMode 'PriorMatch' },
      { key = 'Enter', mods = 'NONE', action = l_action.CopyMode 'PriorMatch' },
      { key = 'UpArrow', mods = 'NONE', action = l_action.CopyMode 'PriorMatch' },
      { key = 'DownArrow', mods = 'NONE', action = l_action.CopyMode 'NextMatch' },
      { key = 'n', mods = 'CTRL', action = l_action.CopyMode 'NextMatch' },
      { key = 'PageUp', mods = 'NONE', action = l_action.CopyMode 'PriorMatchPage' },
      { key = 'PageDown', mods = 'NONE', action = l_action.CopyMode 'NextMatchPage' },
    },


    --------------------------------------------------------------------------
    -- 'ActivateKeyTable' del modo normal
    --------------------------------------------------------------------------
     activate_pane = {
        { key = 'LeftArrow', action = l_action.ActivatePaneDirection 'Left' },
        { key = 'h', action = l_action.ActivatePaneDirection 'Left' },

        { key = 'RightArrow', action = l_action.ActivatePaneDirection 'Right' },
        { key = 'l', action = l_action.ActivatePaneDirection 'Right' },

        { key = 'UpArrow', action = l_action.ActivatePaneDirection 'Up' },
        { key = 'k', action = l_action.ActivatePaneDirection 'Up' },

        { key = 'DownArrow', action = l_action.ActivatePaneDirection 'Down' },
        { key = 'j', action = l_action.ActivatePaneDirection 'Down' },

        -- Cancel the mode by pressing escape
        { key = "Escape", action = "PopKeyTable" },
    },

    resize_pane = {
        { key = 'LeftArrow', action = l_action.AdjustPaneSize { 'Left', 1 } },
        { key = 'h', action = l_action.AdjustPaneSize { 'Left', 1 } },

        { key = 'RightArrow', action = l_action.AdjustPaneSize { 'Right', 1 } },
        { key = 'l', action = l_action.AdjustPaneSize { 'Right', 1 } },

        { key = 'UpArrow', action = l_action.AdjustPaneSize { 'Up', 1 } },
        { key = 'k', action = l_action.AdjustPaneSize { 'Up', 1 } },

        { key = 'DownArrow', action = l_action.AdjustPaneSize { 'Down', 1 } },
        { key = 'j', action = l_action.AdjustPaneSize { 'Down', 1 } },

        -- Cancel the mode by pressing escape
        { key = "Escape", action = "PopKeyTable" },
    },

  }

------------------------------------------------------------------------------------
-- Setting> Otros
------------------------------------------------------------------------------------

-- Sets which ssh backend should be used by default for the integrated ssh client.
-- Possible values are:
-- - "Ssh2"   - use libssh2
-- - "LibSsh" - use libssh
--config.ssh_backend = "Libssh"

-- When set to true (the default), wezterm will configure the SSH_AUTH_SOCK environment variable for panes spawned in the local domain.
config.mux_enable_ssh_agent = false

------------------------------------------------------------------------------------
-- Setting> Non-Local Multiplexing Damains
------------------------------------------------------------------------------------

-- A multiplexing domain is area where the program to be executed/multiplexed is located. By default the GUI (including keyboard actions and events) runs locally, 
-- but the program that runs the wezterm terminal (usually a shell interpreter) can run in another zone or domain.
-- The multiplexing domains can be:
--   > "local"
--   > WSL Domains
--   > SSH Damains
--   > TLS Domains
--   > Socket IPC Damains
-- In domains other than the "local" one, the weztern GUI acts as a proxy (WSL/SSH/TLS client or IPC socket consumer).
-- For more details, see: https://wezfurlong.org/wezterm/multiplexing.html

if l_myconfig.wsl_domains ~= nil then
    config.wsl_domains = l_myconfig.wsl_domains
end

if l_myconfig.ssh_domains ~= nil then
    config.ssh_domains = l_myconfig.ssh_domains
end


------------------------------------------------------------------------------------
-- Setting> Launching Programs
------------------------------------------------------------------------------------

-- Set default multiplexing domains. Default is "local" multiplexing domain (if not using the serial or connect subcommands).
if l_myconfig.default_domain ~= nil then
    config.default_domain = l_myconfig.default_domain
end

-- This field is a array where the 0th element is the command to run and the rest of the elements are passed as the positional arguments to that command.
-- It is is the program used if the argument to the "start" subcommand is not specified. The default value is the current user's shell (executed in login mode).
if l_myconfig.default_prog ~= nil then
    config.default_prog = l_myconfig.default_prog
	--print(config.default_prog)
end

-- The launcher menu is accessed from the new tab button in the tab bar UI; the + button to the right of the tabs. Left clicking on the button will spawn a new tab, 
-- but right clicking on it will open the launcher menu. You may also bind a key to the ShowLauncher or ShowLauncherArgs action to trigger the menu.
-- The launcher menu by default lists the various non-lolcal multiplexer domains and offers the option of connecting and spawning tabs/windows in those domains.
if l_myconfig.launch_menu ~= nil then
    config.launch_menu = l_myconfig.launch_menu 
end


------------------------------------------------------------------------------------
-- Wezterm Events
------------------------------------------------------------------------------------

-- Show which key table is active in the status area
wezterm.on('update-right-status', function(window, pane)
  local name = window:active_key_table()
  if name then
    name = 'Key table: ' .. name .. ' '
  end
  window:set_right_status(name or '')
end)

------------------------------------------------------------------------------------
--- End
------------------------------------------------------------------------------------

-- Return the configuration to wezterm
return config
