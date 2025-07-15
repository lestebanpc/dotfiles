
-- Definiciones (funciones globales) o variables a exportar
local l_mod= {}


------------------------------------------------------------------------------------
-- Settings > General Variables
------------------------------------------------------------------------------------

-- Usar Wayland y solo si es Linux.
-- Debido a que la version de Wayland esta en rescontruccion por lo se optara por usar X11. 
-- Limitaciones al 2024.07.07:
--  > No funciona correctamente el sopotte a OSC 52 para manejo del clipboard.
--  > El estilo de ventanas funciona peor que el de X11.
-- Si usa Wayland, revise que el compositor 'Xwayland' para X11 este activo: 'ps -fea | grep Xwayland'
local l_enable_wayland = false

-- Si establece en false la navegacion solo lo puede hacer usando teclas para ingresar al modo copia, busqueda, copia rapida.
local l_enable_scrollbar = false

-- Built-in scheme: https://wezfurlong.org/wezterm/colorschemes/index.html
local l_color_scheme = 'Ayu Dark (Gogh)'

-- This field is a array where the 0th element is the command to run and the rest of the elements are passed as the positional arguments to that command.
-- It is is the program used if the argument to the "start" subcommand is not specified. The default value is the current user's shell (executed in login mode).
local l_default_prog = nil
--local l_default_prog = { "pwsh" }
--local l_default_prog = { "/usr/bin/bash", "-l" }
--local l_default_prog = { "/usr/bin/zsh", "-l" }

-- Specifies the size of the font, measured in points. You may use fractional point sizes, such as 13.3, to fine tune the size.
-- The default font size is 12.0
local l_font_size = 10.5

-- Estilo a usar en la ventana de la terminal
--  0 > Se establece el por defecto.
--  1 > Se usa el estilo 'TITLE|RESIZE'
--  2 > Se usa el estilo 'INTEGRATED_BUTTONS|RESIZE'
local l_windows_style = 0

------------------------------------------------------------------------------------
-- Setting> Non-Local Multiplexing Damains
------------------------------------------------------------------------------------

-- Set default multiplexing domains. Default is "local" multiplexing domain (if not using the serial or connect subcommands).
local l_default_domain = nil
--local l_default_domain = "local"
--local l_default_domain = "wsl:ubuntu"

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

local l_wsl_domains = nil

local l_ssh_domains = nil
--local l_ssh_domains = {
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

local l_launch_menu = {
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


------------------------------------------------------------------------------------

-- Exportar
l_mod.enable_wayland = l_enable_wayland
l_mod.enable_scroll_bar =  l_enable_scrollbar
l_mod.color_scheme = l_color_scheme
l_mod.font_size = l_font_size
l_mod.default_prog = l_default_prog
l_mod.default_domain = l_default_domain
l_mod.wsl_domains= l_wsl_domains
l_mod.ssh_domains = l_ssh_domains
l_mod.launch_menu = l_launch_menu
l_mod.windows_style = l_windows_style

return l_mod
