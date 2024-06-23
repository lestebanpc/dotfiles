local wezterm = require 'wezterm'

-- Obtain the default configuration.
-- See: https://wezfurlong.org/wezterm/config/lua/config/index.html
local config = wezterm.config_builder()

------------------------------------------------------------------------------------
-- Setting> General
------------------------------------------------------------------------------------

-- If false, do not try to use a Wayland protocol connection when starting the gui frontend, and instead use X11.
config.enable_wayland = true

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
config.term = 'wezterm'

-- Specifies various named color schemes in your configuration file.
-- See: https://wezfurlong.org/wezterm/colorschemes/index.html
config.color_scheme = 'Ayu Dark (Gogh)'

--config.default_prog = {"/usr/bin/zsh", "-l"}
--config.default_cwd = "$HOME"

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
config.font_size = 10.5
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
config.window_decorations = "RESIZE"
--config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- If it's 'AlwaysPrompt' display a confirmation prompt when the window is closed by the windowing environment, 
-- either because the user closed it with the window decorations, or instructed their window manager to close it.
-- Set this to "NeverPrompt" if you don't like confirming closing windows every time.
--config.window_close_confirmation = "NeverPrompt"

config.adjust_window_size_when_changing_font_size = true

-- Controls the amount of padding between the window border and the terminal cells. Padding is measured in pixels.
-- If enable_scroll_bar is true, then the value you set for right will control the width of the scrollbar. 
-- If you have enabled the scrollbar and have set right to 0 then the right padding (and thus the scrollbar width) will instead match the width of a cell.
config.window_padding = {
    left = 5,
    right = 15,
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

-- Specifies the default cursor style for prompt. Various escape sequences can override the default style in different situations 
-- (eg: an editor can change it depending on the mode), but this value controls how the cursor appears when it is reset to default.
-- Acceptable values are SteadyBlock, BlinkingBlock, SteadyUnderline, BlinkingUnderline, SteadyBar, and BlinkingBar.
-- The default is SteadyBlock.En Wayland, 'BlinkingBlock' esta arrojando un error.
--config.default_cursor_style = "BlinkingBlock"

------------------------------------------------------------------------------------
-- Setting> Windows> Tab
------------------------------------------------------------------------------------

-- Controls whether the tab bar is enabled. Set to false to disable it.
config.enable_tab_bar = true

-- If set to true, when there is only a single tab, the tab bar is hidden from the display. If a second tab is created, the tab will be shown.
-- Defult is false.
config.hide_tab_bar_if_only_one_tab = true

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
-- Setting> Key bindings
------------------------------------------------------------------------------------

-- If you don't want the default assignments to be registered, you can disable all of them with this configuration; 
-- if you chose to do this, you must explicitly register every binding.
-- Default key binding: https://wezfurlong.org/wezterm/config/default-keys.html
config.disable_default_key_bindings = true

--config.keys = {
--    {
--        key = 'RightArrow',mods = 'CTRL',
--        action = wezterm.action.SplitHorizontal {  domain = 'CurrentPaneDomain'},
--    },
--    {
--        key = 'DownArrow',mods = 'CTRL',
--        action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain'},
--    }
--  }

------------------------------------------------------------------------------------

-- return the configuration to wezterm
return config
