
-- Definiciones (funciones globales) o variables a exportar
local l_mod= {}


------------------------------------------------------------------------------------
-- Settings > General Variables
------------------------------------------------------------------------------------

-- Si establece en false la navegacion solo lo puede hacer usando teclas para ingresar al modo copia, busqueda, copia rapida.
local l_enable_scrollbar = false

-- Built-in scheme: https://wezfurlong.org/wezterm/colorschemes/index.html
local l_color_scheme = 'Ayu Dark (Gogh)',

-- This field is a array where the 0th element is the command to run and the rest of the elements are passed as the positional arguments to that command.
-- It is is the program used if the argument to the "start" subcommand is not specified. The default value is the current user's shell (executed in login mode).
local l_default_prog = {"pwsh"}
--local l_default_prog = nil
--local l_default_prog = {"/usr/bin/bash", "-l"}
--local l_default_prog = {"/usr/bin/zsh", "-l"}


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

--local l_wsl_domains = nil
local l_wsl_domains = {
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


-- The launcher menu is accessed from the new tab button in the tab bar UI; the + button to the right of the tabs. Left clicking on the button will spawn a new tab, 
-- but right clicking on it will open the launcher menu. You may also bind a key to the ShowLauncher or ShowLauncherArgs action to trigger the menu.
-- The launcher menu by default lists the various non-lolcal multiplexer domains and offers the option of connecting and spawning tabs/windows in those domains.
--local l_launch_menu = nil
local l_launch_menu = {
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


------------------------------------------------------------------------------------

-- Exportar
l_mod.enable_wayland = false
l_mod.enable_scroll_bar = l_enable_scrollbar
l_mod.color_scheme = l_color_scheme
l_mod.default_prog = l_default_prog
l_mod.default_domain = l_default_domain
l_mod.wsl_domains= l_wsl_domains
l_mod.ssh_domains = l_ssh_domains
l_mod.launch_menu = l_launch_menu

return l_mod

