local wezterm = require 'wezterm'

-- CHANGE a "true" if use Windows
local l_is_win = true

-- Obtain the default configuration. See: https://wezfurlong.org/wezterm/config/lua/config/index.html
local config = wezterm.config_builder()

------------------------------------------------------------------------------------
-- Setting> General
------------------------------------------------------------------------------------

-- If false, do not try to use a Wayland protocol connection when starting the gui frontend, and instead use X11.
if not l_is_win then
    config.enable_wayland = true
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
if l_is_win then
    config.term = 'xterm-256color'
else
    config.term = 'xterm-256color'
    --config.term = 'wezterm'
end

-- Create my custom scheme based on a built-in schema.
-- Built-in scheme: https://wezfurlong.org/wezterm/colorschemes/index.html
local scheme = wezterm.get_builtin_color_schemes()['Ayu Dark (Gogh)']
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
--if l_is_win then
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
config.font_size = 10.7
--config.font_size = 11

--config.bold_brightens_ansi_colors = true
config.warn_about_missing_glyphs = true

-- Controls whether the Input Method Editor (IME) will be used to process keyboard input. 
-- The IME is useful for inputting kanji or other text that is not natively supported by the attached keyboard hardware.
config.use_ime = false


------------------------------------------------------------------------------------
-- Setting> Windows> General
------------------------------------------------------------------------------------

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
if l_is_win then
    config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
else
    --config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
    config.window_decorations = "TITLE|RESIZE"
    --config.window_decorations = "RESIZE"
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
config.window_padding = {
    left = 5,
    right = 10,
    top = 5,
    bottom = 5,
  }

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
if l_is_win then
    config.default_cursor_style = "BlinkingBlock"
else
    -- En Wayland, 'BlinkingBlock' esta arrojando un error.
    config.default_cursor_style = "SteadyBlock"
end

-- Specifies the easing function to use when computing the color for the text cursor when it is set to a blinking style.
--config.cursor_blink_ease_in = "Constant"

-- Specifies the easing function to use when computing the color for the text cursor when it is set to a blinking style.
--config.cursor_blink_ease_out = "Constant"

-- Specifies how often a blinking cursor transitions between visible and invisible, expressed in milliseconds. Setting this to 0 disables blinking.
-- It is recommended to avoid blinking cursors when on battery power, as it is relatively costly to keep re-rendering for the blink!.
--config.cursor_blink_rate = 700

------------------------------------------------------------------------------------
-- Setting> Windows> Tab
------------------------------------------------------------------------------------

-- Controls whether the tab bar is enabled. Set to false to disable it.
config.enable_tab_bar = true

-- If set to true, when there is only a single tab, the tab bar is hidden from the display. If a second tab is created, the tab will be shown.
-- Defult is false.
if l_is_win then
    config.hide_tab_bar_if_only_one_tab = false
else
    config.hide_tab_bar_if_only_one_tab = true
end

-- When tab_bar_at_bottom = true, the tab bar will be rendered at the bottom of the window rather than the top of the window.
-- The default is false.
--config.tab_bar_at_bottom = false

-- When set to true (the default), the tab bar is rendered in a native style with proportional fonts.
-- When set to false, the tab bar is rendered using a retro aesthetic using the main terminal font.
config.use_fancy_tab_bar = true

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
-- Otherwise, the tab to the left of the active tab will be activated. Defult is false.
--config.switch_to_last_active_tab_when_closing_tab = true


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
config.enable_scroll_bar = true

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

-- If you don't want the default assignments to be registered, you can disable all of them with this configuration; 
-- if you chose to do this, you must explicitly register every binding.
-- Default key binding: https://wezfurlong.org/wezterm/config/default-keys.html
--config.disable_default_key_bindings = false

-- Los 'keybord shorcut' capturados por la ventana wezterm, no es enviado a los paneles. Por tal motivo desabilitelo, si desea
-- que estos no sean procesados por la ventana y sean procesados por el panel actual.

-- Leader key (called 'LEADER') stays active until a keypress is registered (whether it matches a key binding or not), 
-- or until it has been active for the duration specified by timeout_milliseconds, at which point it will automatically cancel itself.
config.leader = { key = 'a', mods = 'ALT', timeout_milliseconds = 1000 }

config.keys = {
    -- Eliminar la acceso de teclado para maximizar la ventana actual
    {
        key = 'Enter', mods = 'ALT',
        action = wezterm.action.DisableDefaultAssignment,
    },
    -- Eliminar el acceso de teclado para minimizar la ventana actual
    {
        key = 'm', mods = 'SUPER',
        action = wezterm.action.DisableDefaultAssignment,
    },
    -- Eliminar el acceso de teclado para crear una nueva ventana wezterm 
    {
        key = 'n', mods = 'SUPER',
        action = wezterm.action.DisableDefaultAssignment,
    },
    -- Eliminar el acceso de teclado para crear una nueva ventana wezterm 
    {
        key = 'n', mods = 'CTRL|SHIFT',
        action = wezterm.action.DisableDefaultAssignment,
    },
    -- Eliminar el acceso de teclado para crear una tab (solo se usar 'CTRL + T') 
    {
        key = 't', mods = 'SUPER',
        action = wezterm.action.DisableDefaultAssignment,
    },
    -- Eliminar el acceso de teclado para recargar la configuracion (solo se usar 'CTRL + R') 
    {
        key = 'r', mods = 'SUPER',
        action = wezterm.action.DisableDefaultAssignment,
    },
    -- Eliminar el acceso de teclado para redimencionar el panel actual y crear panels 
    {
        key = 'LeftArrow', mods = 'CTRL|SHIFT|ALT',
        action = wezterm.action.DisableDefaultAssignment,
    },
    {
        key = 'RightArrow', mods = 'CTRL|SHIFT|ALT',
        action = wezterm.action.DisableDefaultAssignment,
    },
    {
        key = 'UpArrow', mods = 'CTRL|SHIFT|ALT',
        action = wezterm.action.DisableDefaultAssignment,
    },
    {
        key = 'UpArrow', mods = 'CTRL|SHIFT|ALT',
        action = wezterm.action.DisableDefaultAssignment,
    },
    -- Eliminar el acceso de teclado para crear panels 
    {
        key = '"', mods = 'CTRL|SHIFT|ALT',
        action = wezterm.action.DisableDefaultAssignment,
    },
    {
        key = '%', mods = 'CTRL|SHIFT|ALT',
        action = wezterm.action.DisableDefaultAssignment,
    },
    -- Send key leader "CTRL + a" to the terminal when pressing CTRL + a, CTRL + a
    { 
        key = 'a', mods = 'LEADER|CTRL', 
        action = wezterm.action.SendString '\x01', 
    },
    -- Crear los nuevos acceso de teclado para redimencionar el panel actual 
    {
        key = 'h', mods = 'ALT|SHIFT',
        action = wezterm.action.AdjustPaneSize { 'Left', 1 },
    },
    {
        key = 'LeftArrow', mods = 'ALT|SHIFT',
        action = wezterm.action.AdjustPaneSize { 'Left', 1 },
    },
    {
        key = 'j', mods = 'ALT|SHIFT',
        action = wezterm.action.AdjustPaneSize { 'Down', 1 },
    },
    {
        key = 'DownArrow', mods = 'ALT|SHIFT',
        action = wezterm.action.AdjustPaneSize { 'Down', 1 },
    },
    {
        key = 'k', mods = 'ALT|SHIFT',
        action = wezterm.action.AdjustPaneSize { 'Up', 1 },
    },
    {
        key = 'UpArrow', mods = 'ALT|SHIFT',
        action = wezterm.action.AdjustPaneSize { 'Up', 1 },
    },
    {
        key = 'l', mods = 'ALT|SHIFT',
        action = wezterm.action.AdjustPaneSize { 'Right', 1 },
    },
    {
        key = 'RightArrow', mods = 'ALT|SHIFT',
        action = wezterm.action.AdjustPaneSize { 'Right', 1 },
    },
    -- Crear los nuevos acceso de teclado para crear el panel actual
    { 
        key = '-', mods = 'LEADER', 
        action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }, 
    },
    { 
        key = '=', mods = 'LEADER', 
        action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, 
    },
    -- Activate the Launcher Menu in the current tab
    {
        key = '1', mods = 'ALT',
        action = wezterm.action.ShowLauncherArgs { flags = 'LAUNCH_MENU_ITEMS' },
    },
    {
        key = '2', mods = 'ALT',
        action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|DOMAINS' },
    },
  }


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

if l_is_win then
    config.wsl_domains = {
      {
        -- The name of this specific domain.  Must be unique amonst all types of domain in the configuration file.
        name = 'wsl:ubuntu',
        -- The name of the distribution.  This identifies the WSL distribution. It must match a valid distribution from your `wsl -l -v` output.
        distribution = 'Ubuntu',
        -- The username to use when spawning commands in the distribution. If omitted, the default user for that distribution will be used.
        username = "lucianoepc",
        -- The current working directory to use when spawning commands, if the SpawnCommand doesn't otherwise specify the directory.
        default_cwd = "/home/lucianoepc"
        -- The default command to run, if the SpawnCommand doesn't otherwise override it. Note that you may prefer to use `chsh` to set the
        -- default shell for your user inside WSL to avoid needing to specify it here.
        --default_prog = { "bash" }
      },
    }
end

--config.ssh_domains = {
--  {
--    -- The name of this specific domain.  Must be unique amongst all types of domain in the configuration file.
--    name = 'my.server',
--    -- Identifies the host:port pair of the remote server. Can be a DNS name or an IP address with an optional ":port" on the end.
--    remote_address = '192.168.1.1',
--    -- Whether agent auth should be disabled. Set to true to disable it. 
--    --no_agent_auth = false,
--    -- The username to use for authenticating with the remote host
--    username = 'yourusername',
--    -- If true, connect to this domain automatically at startup
--    --connect_automatically = true,
--    -- Specify an alternative read timeout
--    --timeout = 60,
--    -- The path to the wezterm binary on the remote host. Primarily useful if it isn't installed in the $PATH that is configure for ssh.
--    --remote_wezterm_path = "/home/yourusername/bin/wezterm"
--  },
--}


------------------------------------------------------------------------------------
-- Setting> Launching Programs
------------------------------------------------------------------------------------

-- Set default multiplexing domains. Default is "local" multiplexing domain (if not using the serial or connect subcommands).
--config.default_domain = "local"
--config.default_domain = "wsl:ubuntu"

-- This field is a array where the 0th element is the command to run and the rest of the elements are passed as the positional arguments to that command.
-- It is is the program used if the argument to the "start" subcommand is not specified. The default value is the current user's shell (executed in login mode).
if l_is_win then
    config.default_prog = { "pwsh" }
--else
--    config.default_prog = {"/usr/bin/bash", "-l"}
--    config.default_prog = {"/usr/bin/zsh", "-l"}
end

-- The launcher menu is accessed from the new tab button in the tab bar UI; the + button to the right of the tabs. Left clicking on the button will spawn a new tab, 
-- but right clicking on it will open the launcher menu. You may also bind a key to the ShowLauncher or ShowLauncherArgs action to trigger the menu.
-- The launcher menu by default lists the various non-lolcal multiplexer domains and offers the option of connecting and spawning tabs/windows in those domains.
if l_is_win then
    config.launch_menu = {
        { 
            -- Optional label to show in the launcher. If omitted, a label is derived from the `args`.
            label = " Windows PowerShell",
            -- Command to run into new tab. The argument array to spawn. 
            args = { "powershell" },
            -- You can specify an alternative current working directory; if you don't specify one then a default based on the OSC 7
            -- escape sequence will be used (see the Shell Integration docs), falling back to the home directory.
            --cwd = "/some/path",
            -- You can override environment variables just for this command by setting this here. 
            --set_environment_variables = { FOO = "bar" },
        },
        { 
            -- Optional label to show in the launcher. If omitted, a label is derived from the `args`.
            label = "󰨊 PowerShell Core", 
            -- Command to run into new tab. The argument array to spawn. 
            args = { "pwsh" },
            -- You can specify an alternative current working directory; if you don't specify one then a default based on the OSC 7
            -- escape sequence will be used (see the Shell Integration docs), falling back to the home directory.
            --cwd = "/some/path",
            -- You can override environment variables just for this command by setting this here. 
            --set_environment_variables = { FOO = "bar" },
        },
        { 
            -- Optional label to show in the launcher. If omitted, a label is derived from the `args`.
            label = " Cmd", 
            -- Command to run into new tab. The argument array to spawn. 
            args = { "cmd" },
            -- You can specify an alternative current working directory; if you don't specify one then a default based on the OSC 7
            -- escape sequence will be used (see the Shell Integration docs), falling back to the home directory.
            --cwd = "/some/path",
            -- You can override environment variables just for this command by setting this here. 
            --set_environment_variables = { FOO = "bar" },
        },
      }
else
    config.launch_menu = {
        { 
            -- Optional label to show in the launcher. If omitted, a label is derived from the `args`.
            label = " PowerShell Core", 
            -- Command to run into new tab. The argument array to spawn. 
            args =  { "pwsh" },
            -- You can specify an alternative current working directory; if you don't specify one then a default based on the OSC 7
            -- escape sequence will be used (see the Shell Integration docs), falling back to the home directory.
            --cwd = "/some/path",
            -- You can override environment variables just for this command by setting this here. 
            --set_environment_variables = { FOO = "bar" },
        },
        { label = " Bash", args = { "bash", "-l" }, },
        { label = " Btop", args = { "btop" }, },
        --{ label = " Fish", args = { "/opt/homebrew/bin/fish" }, },
        --{ label = " Nushell", args = { "/opt/homebrew/bin/nu" }, },
        --{ label = " Zsh", args = { "zsh" } },
      }
end

------------------------------------------------------------------------------------

-- Return the configuration to wezterm
return config
