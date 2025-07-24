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

local mod= {

    --------------------------------------------------------------------------------
    -- Settings> Campos Generales
    --------------------------------------------------------------------------------

    -- Si establece en false la navegacion solo lo puede hacer usando teclas para ingresa`r al modo copia, busqueda, copia rapida.
    enable_scrollbar = false,

    -- Built-in scheme: https://wezfurlong.org/wezterm/colorschemes/index.html
    color_scheme = 'Ayu Dark (Gogh)',

    -- Specifies the size of the font, measured in points. You may use fractional point sizes, such as 13.3, to fine tune the size.
    -- The default font size is 12.0
    font_size = 10.5,

    -- Estilo a usar en la ventana de la terminal
    --  0 > Se establece el por defecto.
    --  1 > Se usa el estilo 'TITLE|RESIZE'
    --  2 > Se usa el estilo 'INTEGRATED_BUTTONS|RESIZE'
    windows_style = 2,


    --------------------------------------------------------------------------------
    -- Setting> Parametros de inicio de Terminal GUI (usando subcomando 'start')
    --------------------------------------------------------------------------------
    --
    -- No aplica si se inicia sin subcomandos ('wezterm-gui' o 'wezterm') y se configura el parametro 'config.default_gui_startup_args'
    -- que no sea '{"start"}'.
    -- Es decir, no aplica si la terminal se crea usando 'wezterm connect', 'wezterm ssh' o 'wezterm serial'.
    --

    -- Establecer el dominio por defecto a usar.
    -- Si no se define el domonio por defecto sera 'local'.
    default_domain = nil,
    --default_domain = "local",
    --default_domain = "WSL:ubuntu",

    -- Programa por defecto a ejecutar cuando se crea un nuevo tab del dominio 'local'. Si no se especifica se usara el shell predeterminado
    -- del usuario actual que usa la terminal GUI.
    -- > En otros dominios su valor se especifica cuando se define el dominio. Excepto cuando es un 'multiplexing domain' el shell a usar
    --   siempre es el shell predterminado donde se ejecuta el 'multiplexer domain'.
    default_prog = nil,
    --default_prog = { "pwsh" },
    --default_prog = { "/usr/bin/bash", "-l" },
    --default_prog = { "/usr/bin/zsh", "-l" },

}



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


-- Definir el 'IPC client' y/o 'IPC server':
-- > Cada servidor IPC que se define implica una instancia independiente del 'multiplexer server'.
-- > Cada cliente IPC se conecta a un servidor IPC definido, iniciando antes un comando 'serve_command' y
--   pudiendo enviar las peticiones del cliente a un 'proxy_commnad'.
-- > Vease: https://wezterm.org/multiplexing.html#unix-domains
mod.unix_domains = nil
--mod.unix_domains = {
--    {
--        -- Variables usado por cliente/server IPC:
--
--        -- Nombre del dominio
--        name = 'local-unix',
--
--        -- Ruta y nombre de socket IPC. Si no se especifca se crea en base a nombre del dominio.
--        --socket_path = "/tmp/mysocket1",
--
--        -- If true, do not attempt to start this server if we try and fail to connect to it.
--        --no_serve_automatically = false,
--
--        -- If true, bypass checking for secure ownership of the socket_path.
--        -- No se recomienda usarlo solo en casos especiales como:
--        --  > Si usa WSL y el archivo socket este en una unidad montada NTFS del host, esta siempre se crea con
--        --    muchos permisos de lo recomendado. Esta opcion permite usar este tipo de archivo desde Linux.
--        --skip_permissions_check = true,
--
--
--        -- Variables usados solo por el cliente IPC:
--
--        -- Specify the round-trip latency threshold for enabling predictive local.
--        -- This option only applies when 'multiplexing = "WezTerm"'.
--        --local_echo_threshold_ms = 10,
--
--        -- Wezterm envia la peticiones al 'proxy command' el cual se encarga de redirigir la peticion al socket
--        -- real asociadoa al mutiplexer.
--        -- No se recomienda usarlo solo en casos especiales como:
--        --  > Si usa WSL permite acceder al socket IPC usando ....
--        --proxy_command = { 'nc', '-U', '/Users/lucianoepc/.local/share/wezterm/sock' },
--
--        -- Comando ejecutado antes que el cliente IPC se conecte al server IPC.
--        --serve_command = { 'wsl', 'wezterm-mux-server', '--daemonize' },
--    },
--}


-- Definir el cliente SSH para conectarse a un un servidor
-- > Si 'multiplexing' es 'Wezterm', el cliente (terminal) intentara de iniciar automaticamente el 'multiplexer server' luego del
--   haber iniciado la session SSH. En este caso el cliente se conecta a un 'multiplexing domain' (con sus propios worskpace
--   diferentes al definido dominio 'local').
-- > Si 'multiplexing' es 'None', el cliente (terminal) se conecta al servidor SSH.
--   El dominio es un 'multiplexing domian' debido a que no tiene su propio 'multiplexer server'.
-- > Vease: https://wezterm.org/multiplexing.html#ssh-domains
mod.ssh_domains = nil
--mod.ssh_domains = {
--    {
--        -- The name of this specific domain. Must be unique amongst all types of domain in the configuration file.
--        name = 'SSH:vmfedsrv',
--
--        -- SSH server address. Puede ser:
--        -- > Alias registrado en el archivo de configuracion '~/.ssh/config'
--        -- > Direccion del servidor SSH 'host:port', donde 'host' puede ser DNS o IP y ':port' es opcional.
--        remote_address = 'vmfedsrv',
--
--        -- The username to use for authenticating with the remote host
--        username = 'myusername',
--
--        -- Opciones del cliente SSH a usar
--        --ssh_option = {
--        --    identityfile = '/path/to/id_rsa.pub',
--        --    identitiesonly= 'yes',
--        --},
--
--        -- Whether agent auth should be disabled. Set to true to disable it.
--        --no_agent_auth = false,
--
--        -- Specify an alternative read timeout
--        --timeout = 60,
--
--        -- Si se define 'Wezterm' intenta iniciar y luego conectarse al 'mulitplexer server' remoto (ubicado en el servidor SSH).
--        multiplexing = 'None',
--        --multiplexing = 'WezTerm',
--
--
--        --
--        -- Campos usados cuando 'multiplexing' es 'WezTerm':
--        --
--
--        -- The path to the wezterm binary on the remote host. Primarily useful if it isn't installed in the $PATH that is configure for ssh.
--        --remote_wezterm_path = "/home/yourusername/bin/wezterm"
--
--        -- Specify the round-trip latency threshold for enabling predictive local 'echo'
--        --local_echo_threshold_ms = 10,
--
--
--        --
--        -- Campos usados cuando 'multiplexing' es 'None':
--        --
--
--        -- Used to specify the default program to run in new tabs/panes. Due to the way that ssh works, you cannot specify default_cwd,
--        -- but you could instead change your default_prog to put you in a specific directory.
--        --default_prog = { 'fish' },
--
--        -- assume that we can use syntax like:  "env -C /some/where $SHELL"
--        -- using whatever the default command shell is on this remote host, so that shell integration will respect the current directory
--        -- on the remote host.
--        --assume_shell = 'Posix',
--
--    },
--}


-- Definir client TLS para conectarse a un 'multiplexer server' remoto usando TLS.
-- > Si el cliente realiza el handshake TLS usando una conexion SSH previa, no es obligatorio configurar
--   certificados para el servidor TLS:
--   > A nivel del cliente TLS (terminal GUI) debera tener acceso al server SSH y indicado su acceso en
--     la propiedad 'bootstrap_via_ssh'.
--   > Si no se especifica el certificado del servidor, el servidor se inicia creando sus propios
--     certificados autofirmados.
--   > El cliente TLS esta diseñado para conectar al servidor TLS con estos certificados autofirmados.
-- > Vease: https://wezterm.org/multiplexing.html#tls-domains
mod.tls_clients = nil
--mod.tls_clients = {
--    {
--        -- The name of this specific domain. Must be unique amongst all types of domain in the configuration file.
--        name = 'server.name',
--
--        -- TLS server address (host:port)
--        remote_address = 'server.hostname:8080',
--
--        -- The value can be "user@host:port" (it accepts the same syntax as the 'wezterm ssh' subcommand).
--        bootstrap_via_ssh = 'server.hostname',
--
--        -- Explicitly control whether the client checks that the certificate presented by the server matches the hostname
--        -- portion of 'remote_address'.
--        -- This option is made available for troubleshooting purposes and should not be used outside of a controlled environment
--        -- as it weakens the security of the TLS channel.
--        -- The default is true.
--        --accept_invalid_hostnames = false,
--
--        -- The hostname string that we expect to match against the common name field in the certificate presented by the server.
--        -- This defaults to the hostname portion of the 'remote_address' configuration and you should not normally need to override
--        -- this value.
--        --expected_cn = "other.name",
--
--        -- If true, connect to this domain automatically at startup
--        --connect_automatically = false,
--
--        --Specify an alternate read timeout
--        -- read_timeout = 60,
--
--        --Specify an alternate write timeout
--        -- write_timeout = 60,
--
--        --The path to the wezterm binary on the remote host
--        -- remote_wezterm_path = "/home/myname/bin/wezterm"
--
--
--        --
--        -- Campos requeridos si el cliente no se conecta usando SSH:
--        --
--
--        -- Lista de certificados CA adicionales usados como 'trust-store' para el 'multiplexer server' cuando
--        -- este actual como cliente TLS.
--        --pem_root_certs = { "/some/path/ca1.pem", "/some/path/ca2.pem" },
--
--
--        --
--        -- Campos requeridos si el cliente no se conecta usando SSH y usa mTLS:
--        --
--
--        -- Clave privada del certificado del servidor TLS
--        --pem_private_key = "/path/to/key.pem",
--
--        -- Lista de certificados CA adicionales usados como 'trust-store' para el 'multiplexer server' cuando
--        -- Certificado del servidor TLS
--        --pem_cert = "/path/to/cert.pem",
--
--        -- Bundle de certificado del CA que realizan/validan la firman el certificado del servidor TLS
--        --pem_ca = "/path/to/chain.pem",
--
--  },
--}



------------------------------------------------------------------------------------
-- Setting> Launching Programs
------------------------------------------------------------------------------------
--
-- The launcher menu is accessed from the new tab button in the tab bar UI; the + button to the right of the tabs. Left clicking on the button will spawn a new tab,
-- but right clicking on it will open the launcher menu. You may also bind a key to the ShowLauncher or ShowLauncherArgs action to trigger the menu.
-- The launcher menu by default lists the various non-lolcal multiplexer domains and offers the option of connecting and spawning tabs/windows in those domains.
--

--mod.launch_menu = nil
mod.launch_menu = {
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
--
-- Exportar
--
return mod
