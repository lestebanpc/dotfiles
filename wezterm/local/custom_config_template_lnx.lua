--
-- Consideraciones a tener en cuenta:
--
-- > Un proceso 'wezterm-gui' representa una instancia del emulador de terminal wezterm con su propio 'built-in multiplexor'.
--   > Una (instancia del) emulador (proceso 'wezterm-gui') tiene su propia instancia de 'built-in multiplexor'. El emulador de terminal siempre depende
--     de su multiplexor integrado y se encarga de visualizar y mostrar sus objetos: el workspace seleccionado y presenta cada 'MuxWindow' creando su
--     objeto 'Window', su tabs y su panel.
--   > El multiplexor es el encargado de gestionar los objetos:
--     > 'Workspace' que es un conjunto de 'MuxWindow' exclusivos (no pueden ser compartido con otros workspace). Por defecto el multiplexor siempre
--       tiene un workspace llamado 'default' con una solo 'MuxWindow' y con un solo tab 'MuxTab' con un solo panel 'MuxPane'.
--     > 'MuxWindow' que tiene un conjunto de 'MuxTab' y este a su vez un conjunto de 'MuxPane'.
--     > 'MuxDamain' es objeto que define una determina forma de crear 'MuxPane' (la shell que usara, el proceso que ejecutara y sus argumentos, etc.)
--     > Un 'MuxTab' esta vinculado a un solo objeto 'MuxDomain', por lo que los 'MuxPane' de un 'MuxTab' solo se pueden crear de un sola forma definida
--       por el 'MuxDomain'.
--   > Una objeto 'Window' (ventana GUI) es gestionado por el gestor de ventanas del SO (por ejemplo, Wayland) y tiene su 'title bar', 'tab bar' y su
--     'status bar', y muestran un conjunto de tab (objeto 'TabInformation') y paneles (objeto 'Pane').
--   > Por cada objeto 'Workspace' (del built-in multiplexer) selecionado en el emulador de terminal, segun la 'MuxDomain' existentes, se creara/mostrara
--     el un objeto 'Window' mostrando los tab y paneles presentes en este.
--
-- > El comando 'wezterm start/connect/ssh/serial', si no encuentra un instancia de emulador de terminal iniciado, siempre inicia uno proceso 'wezterm-gui'.
--   > Una instancia de (emulador de) terminal se puede crear usando:
--     > 'wezterm start --domain <defualt_domain> -- <default_prog>'
--     > 'wezterm-gui start  --domain <defualt_domain> -- <default_prog>'
--       Es usado en los 'launcher' de los diferentes sistemas operativo para iniciar el (emulador de terminal). Internamente invoca a 'wezterm start'.
--     > Otras formas de iniciar una instancia del (emulador de terminal) es usando Los subcomandos:
--       > 'wezterm connect <domian>' o 'wezterm-gui connect <domian>',
--       > 'wezterm ssh <server>'     o 'wezterm-gui ssh <server>'
--       > 'wezterm ssh serial'       o 'wezterm-gui ssh serial'
--   > Si ya existe un proceso 'wezterm-gui', la forma de crear otra instancia es usando 'wezterm start --always-new-process'.
--   > Pora cada una instancia de terminal que se ejecuta el archivo de configuracion '~/.config/wezterm/wezterm.lua'.
--     > El archivo de configuracion puede volver a cargarse automaticamete cuando este tiene un cambio.
--   > Si inicia una instancia del (emulador de) terminal usando 'wezterm' o 'wezterm-gui' sin especificar el subcomando, se considera:
--     > El comando por defecto es 'start'.
--     > Este valor por defecto se puede modificar, estableciendo el parametro 'config.default_gui_startup_args' del archivo de configuracion y especificando,
--       por ejemplo:
--       > '{ 'start' }'               si desea usar 'wezterm start'
--       > '{ 'ssh', '<server>' }'     si desea usar 'wezterm ssh <server>'
--       > '{ 'connect', '<domain>' }' si desea usar 'wezterm connect <domain>'
--       > '{ 'serial', '<server>' }'  si desea usar 'wezterm serial <server>'
--
-- > Los 'multiplexer' usados por Wezterm son:
--   > 'Multiplexer Server'
--      > Es un multiplexer externo al proceso 'wezterm-gui'.
--      > Se ejecuta en un proceso 'wezterm-mux-server' externa a la terminal y expone su API en TSL/HTTPS (usualmente usando un socket IPC).
--      > Los clientes (procesos 'wezterm-gui') solo se pueden conectar usando:
--        > Localmente usando el socket IPC expuesto por el 'multiplexer' (actual de IPC server).
--        > Remotamente se accede usando:
--          > TLS
--            > Mediante configuracion del 'multiplexer server' puede exponer el socket IPC en un socket TCP exponiendo el API TLS/HTTPS sobre TPC.
--          > SSH
--            > Require de un proxy creado por 'wezterm cli proxy' que facilite la comunicacion de TLS/HTTPS sobre el tunel SSH.
--      > Actualmente, tiene las siguiente restricciones:
--        > Solo cuanta con i solo 'MuxDomain' llamado 'local'.
--        > Solo puede tener 1 solo 'Workspace' llamado 'default' que solo tiene tener 'MuxWindow' locales a este (no existe un 'attach' a 'MuxWindow'
--          remotos).
--        > El workspace puede tener multiples 'MuxWindow' con sus 'MuxTab' y sus 'MuxPane' el cual solo puede estar asociado al unico 'MuxDomain'
--          existente.
--   > 'Built-in multiplexer'
--      > Es un multiplexer que se instancia dentreo del proceso 'wezterm-gui'.
--      > Se crea dentro del propio proceso de la instancia de la terminal.
--      > Puede tener multiples 'workspace', las cuales son creados desde el emulador de terminal.
--      > Tiene diferentes 'MuxDomains'.
--      > A un workspace se puede tener vincular (attach) tanto 'MuxWindow' multiplexor integrado o del multiplexor remoto usando IPC/TLS/SSH.
--        Cuando se vincula a un multiplexor remoto y no existe workspace, se creara automaticamente con un 'MuxWindow' y su respectivo 'Muxtab'
--        y 'MuxPane'.
--
-- > Un cliente de un 'multiplexer' es un proceso 'wezterm-gui' (un mismo usuario y de una maquina) que se conecta a un 'multiplexer'.
--
-- > Un 'Domain' es a nivel emulador de terminal ('wezter-gui') define la forma en que se crearan los paneles de un tab (el proceso local a usar, el
--   interprete de shell a usar, los parametros que se usaran para crearlo) el cual puede ser complejo cuando este se conecta a shell o procesos
--   remotos.
--   > Un 'Domain' esta asociado a un 'MuxDomain' de un multiplexor integraado o remoto.
--   > Los tipos puede ser:
--     > 'Local Domain'
--          > Sus paneles solo  proceso locales, usualmente el interprete shell
--     > 'SSH Domain'
--        > Puede asociarse al mulitplexor integrado a un 'multiplexer server'.
--        > Si esta asociado a 'MuxDomain' del multiplexor integrado, es considerado un proceso 'ssh' que se ejecuta localmente pero requiere
--          conectarse remotamente por SSH.
--        > Si esta asociado a 'MuxDomain' de un 'multiplexer server', este indica como conectarse al 'multiplexer server', y sera este el que
--          decida como crear los 'MuxTab' y sus 'MuxPane'. Se usa SSH para comunicarse con el servidor.
--     > 'WSL Domain'
--        > Ejecutan un proceso local 'wsl' y siempre esta asocaido a un 'MuxDomain' del 'built-in multiplexer'.
--     > 'TSL Domain'
--        > Siempre esta asociado a 'MuxDomain' de un 'multiplexer server', este indica como conectarse al 'multiplexer server', y sera este el que
--          decida como crear los 'MuxTab' y sus 'MuxPane'.
--        > Se usa TLS para comunicarse con este, aunque tambien puede usarse SSH solo para el inicio automatico del 'multiplexer server'.
--     > 'Unix Damain'
--        > Siempre esta asociado a 'MuxDomain' de un 'multiplexer server' que usualemtne esta local donde esta la termina.
--        > Se usa socket IPC para comunicarse con este.
--


local mod= {

    --------------------------------------------------------------------------------
    -- Settings> Campos Generales
    --------------------------------------------------------------------------------

    -- Solo valido para Linux. Si es 'true' se conectara a un compositor Wayland, caso contrario se considera un server X11.
    -- > Si usa X11 en una distribucion que solo usa Wayland, revise que el compositor 'Xwayland' para X11 este activo:
    --   'ps -fea | grep Xwayland'
    -- > Limitaciones de usar 'Wayland' en 2024.07.07:
    --   > No funciona correctamente el sopotte a OSC 52 para manejo del clipboard.
    --   > El estilo de ventanas funciona peor que el de X11.
    enable_wayland = false,

    -- Si establece en false la navegacion solo lo puede hacer usando teclas para ingresa`r al modo copia, busqueda, copia rapida.
    enable_scrollbar = false,

    -- Built-in scheme: https://wezfurlong.org/wezterm/colorschemes/index.html
    color_scheme = 'Ayu Dark (Gogh)',

    -- Specifies the size of the font, measured in points. You may use fractional point sizes, such as 13.3, to fine tune the size.
    -- The default font size is 12.0
    font_size = 10.5,

    -- Estilo a usar en la ventana de la terminal
    --  0 > Se establece el por defecto.
    --  1 > Muestra el 'title bar' ocultando el 'tab bar' si existe solo 1 tab (estilo 'TITLE|RESIZE')
    --  2 > Muestra el 'title bar' y siempre muestra el 'tab bar' (estilo 'TITLE|RESIZE')
    --  3 > Solo muestra el 'tab bar' el cual incluyen los botones cerrar, maximizar, minimizar (estilo 'INTEGRATED_BUTTONS|RESIZE')
    windows_style = 2,

    -- Ruta de los folderes de directorios personalizados (diferentes a la rutas reservadas del sistema) donde estan los archivos de fuentes.
    -- Usado cuando no tiene acceso a colocar archivos de fuentes en las rutas reservadas para el sistema o el usuario actual.
    font_dirs = nil,
    --font_dirs = {
    --    '/var/opt/tools/'
    --},

    -- Si es 'ConfigDirsOnly' solo se usaran las fuentes integradas y las fuentes especificadas en los folderes 'font_dirs' (descarta las fuentes
    -- del sistema).
    --font_locator = "ConfigDirsOnly",
    font_locator = nil,

    -- Ruta donde se encuentra 'pwsh' (si no se especifica, lo buscara dentro del PATH)
    pwsh_path = nil,
    --pwsh_path = 'D:/apps/powershell',


    --------------------------------------------------------------------------------
    -- Setting> Campos para personalizar Dominios
    --------------------------------------------------------------------------------

    -- Permite excluidos los 'host' obtenidos del archivo de configuracion '~/.ssh/config' el cual no se creara su respectivo 'ssh domain'.
    -- Solo los dominios que no son filtrados se crearan un 'ssh domain' con 'multiplexion = "None"'.
    -- Por defecto, se crea adiciona 2 entradas host: '.local' y 'machine/.local'
    -- > Use '%' para escapar carateres especiales: ( ) . % + - * ? [ ^ $
    filter_config_ssh = {
        '^%.host',
        '^machine/%.host',
        '^gl-',
        '^gh-',
    },

    -- De los domonios obtenidos anteriormente, permite filtrar los dominios SHH que se no se vinculara a un 'multiplexer server' externo.
    -- Solo los dominios que no son filtrados se crearan un 'ssh domain' con 'multiplexion = "WezTerm"'.
    -- > Use '%' para escapar carateres especiales: ( ) . % + - * ? [ ^ $
    filter_config_ssh_mux = {
        '^sw',
        '^192$.168%.1%.',
        '^192$.168%.199%.',
    },


    -- Dominios Unix/IPC que se conectan a servidor IPC externo al host al que se ejecuta el emulador de terminal. Usualmente estos casos se
    -- genera cuando usa tecnicas de redireccion de socket IPC a servidor IPC ubicado en equipos remotos.
    -- En Windows, los dominios sockets registrados se consideran que siempre son a servicios externos, por tal motivo no necesita incluirlo
    -- en esta lista.
    external_unix_domains = nil,
    --external_unix_domains = {
    --    'ipc:mysocket1',
    --    'ipc:mysocket2',
    --},


    --------------------------------------------------------------------------------
    -- Setting> Campos para personalizar Dominios de tipo 'exec'
    --------------------------------------------------------------------------------

    -- Identificador de la distribucion linux Distrobox/WSL diferente al local y que que esta ejecutandose, el cual es usado para cargar dominios de tipo 'exec'
    -- asociados a sus procesos que ejecutan dentro de esta distribucion.
    -- > El valor puede variar en el sistema operativo:
    --   > En Windows: es el nombre de la distribucion WSL (este siempre esta asociado a un dominios WSL que se carga automaticamente).
    --   > En Linux  : es el nombre de la distribucion distrobox (este es un contenedor especial gestionado por distrobox y esta asociado a u
    --     dominio 'exec' cargado cuando 'load_containers' es 'true').
    -- > El valor real es calculado automaticamente usando los siguientes criterios:
    --   > Si no se tiene distribuciones WSL/distrobox en ejecucion, su valor se establecera a 'nil'.
    --   > Si su valor es por defecto ('nil') y existe distribuciones WSL/distrobox en ejecucion, su valor siempre sera el primera distribucion
    --     WSL/distrobox en ejecucion encontrada.
    --   > Si se establece un valor y no es encontrado en una distribucion WSL en ejecucion, su valor se establece en la primera encontrada.
    -- > El valor real es calculado en 2 escenarios:
    --   > Durante el primer inicio del emulador de terminal 'wezterm' y es usado para calcular los dominios 'exec' generados automaticamente.
    --   > Cuando se desea crear o ir a un workspace, donde muestra los 'path' o 'tag' asociados es esta distribucion.
    external_running_distribution = nil,

    -- Permite adicionar 'exec domains' que permite ingresar a shell de los contenedores, que estan ejecutando localmente y/o en la distribucion WSL
    -- definido por 'external_running_distribution', pero no esta gestionados por distrobox (en caso de Linux).
    load_containers = false,


    --------------------------------------------------------------------------------
    -- Setting> Campos para configurar worskpace
    --------------------------------------------------------------------------------

    -- Ruta del folder donde buscar los repositorios git, donde se encuentra diferentes proyectos 'git', usados para crear un workspace asociado
    -- a path del dominio local y dominios tipos unix (asociados servidor IPC locales).
    -- > Se puede usar '~' al inicio para representar el 'home directory' del usuario actual y local.
    --root_git_folder = nil,
    root_git_folder = '~/code',

    -- Ruta del folder donde buscar los repositorios git, donde se encuentra diferentes proyectos 'git', usados para crear un workspace asociado
    -- a path del dominio externo al local:
    -- > En Windows: el directorio donde se encuentra en cualquier distribucion WSL (actualmente aplica a todos los dominios WSL).
    -- > En Linux  : el directorio donde se encuentra en cualquier contenedor distrobox (un tipo de dominio 'exec' y actualmente aplica a todos
    --   estos dominios existentes)
    -- > Se puede usar '~' al inicio para representar el 'home directory' del usuario por defecto de la distribucion WSL/distrobox remota.
    -- > Se puede usar '@' al inicio para representar el 'home directory' del usuario actual y local.
    external_root_git_folder = '@/code',
    --external_root_git_folder = nil,
    --external_root_git_folder = '~/code',

    -- Cargar los built-in tags para crear worspace usando rutas de carpetas del dominio local.
    load_local_builtin_tags = true,

    -- Cargar los built-in tags para crear worspace usando rutas de carpetas externas al dominio local.
    load_external_builtin_tags = true,


    --------------------------------------------------------------------------------
    -- Setting> Parametros de inicio de Terminal GUI (usando subcomando 'start')
    --------------------------------------------------------------------------------
    --
    -- No aplica si se inicia sin subcomandos (de 'wezterm-gui' o 'wezterm') y se configura el parametro 'config.default_gui_startup_args'
    -- que no sea '{"start"}'. Es decir, no aplica si la terminal se crea usando 'wezterm connect', 'wezterm ssh' o 'wezterm serial'.
    --

    -- Establecer el dominio por defecto a usar. Si no se define el domonio por defecto sera 'local'.
    -- > Los dominios built-in de Wezterm:
    --   > local            : Dominio local. Inicia un interprete shell por defecto del sistema operativo (en Windows es 'cmd').
    --   > unix             : Dominio de tipo unix (solo para Linux). Ruta de socket IPC para acceder al multiplexor local de wezterm).
    --   > WSL:<distro-wsl> : Dominio de tipo wsl (solo Windows).
    -- > Los dominios 'exec' creados por defecto por el archivos de configuración:
    --   > bash             : Inicia un interprete shell bash (solo Linux y MacOS).
    --   > pwsh             : Inicia un interprete shell Powershell Core.
    --   > pwsh2            : Inicia un interprete shell Powershell Core sobre Windows Powershell (solo en Windows).
    --                        Uselo cuando solo tiene acceso a iniciar shell 'Windows Powershell'
    --   > powershell       : Inicia un interprete shell Windows Powershell (solo Windows).
    default_domain = nil,
    --default_domain = "local",
    --default_domain = "pwsh",
    --default_domain = "WSL:ubuntu",


    -- Si el dominio por defecto esta asociado a un interpre shell, puede ejecutar un determinado comando dentro del interprete cuando este
    -- se inicia.
    -- Esto es util en windows, cuando esta bloquedo el acceso a 'cmd' y tiene acceso a otro interprete shell.
    default_prog = nil,
    --default_prog = 'D:/apps/powershell/pwsh.exe',
    --default_prog = 'C:/apps/powershell/pwsh.exe',

}



------------------------------------------------------------------------------------
-- Setting> Damains
------------------------------------------------------------------------------------
--
-- > Un 'Domain' es a nivel emulador de terminal ('wezter-gui') define la forma en que se crearan los paneles de un tab (el proceso local a usar, el
--   interprete de shell a usar, los parametros que se usaran para crearlo) el cual puede ser complejo cuando este se conecta a shell o procesos
--   remotos.
--   > Un 'Domain' esta asociado a un 'MuxDomain' de un multiplexor integraado o remoto.
--   > Los tipos puede ser:
--     > 'Local Domain'
--          > Sus paneles solo  proceso locales, usualmente el interprete shell
--     > 'SSH Domain'
--        > Puede asociarse al mulitplexor integrado a un 'multiplexer server'.
--        > Si esta asociado a 'MuxDomain' del multiplexor integrado, es considerado un proceso 'ssh' que se ejecuta localmente pero requiere
--          conectarse remotamente por SSH.
--        > Si esta asociado a 'MuxDomain' de un 'multiplexer server', este indica como conectarse al 'multiplexer server', y sera este el que
--          decida como crear los 'MuxTab' y sus 'MuxPane'. Se usa SSH para comunicarse con el servidor.
--     > 'WSL Domain'
--        > Ejecutan un proceso local 'wsl' y siempre esta asocaido a un 'MuxDomain' del 'built-in multiplexer'.
--     > 'TSL Domain'
--        > Siempre esta asociado a 'MuxDomain' de un 'multiplexer server', este indica como conectarse al 'multiplexer server', y sera este el que
--          decida como crear los 'MuxTab' y sus 'MuxPane'.
--        > Se usa TLS para comunicarse con este, aunque tambien puede usarse SSH solo para el inicio automatico del 'multiplexer server'.
--     > 'Unix Damain'
--        > Siempre esta asociado a 'MuxDomain' de un 'multiplexer server' que usualemtne esta local donde esta la termina.
--        > Se usa socket IPC para comunicarse con este.


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
--        -- Ruta y nombre de socket IPC. Si no se especifica la ruta usado depende de la distribucion, pero usualemnte es:
--        -- > '/run/user/1000/wezterm/sock' (su nombre siempre es 'sock').
--        -- > '~/.local/share/wezterm/sock' (su nombre siempre es 'sock').
--        --socket_path = "/tmp/mysocket1",
--
--        -- If true, do not attempt to start this server if we try and fail to connect to it.
--        --no_serve_automatically = false,
--
--        -- If true, bypass checking for secure ownership of the socket_path.
--        -- No se recomienda usarlo solo en casos especiales como:
--        --  > Si usa WSL y el archivo socket este en una unidad montada NTFS del host, esta siempre se crea con
--        --    muchos permisos de lo recomendado. Esta opcion permite usar este tipo de archivo desde Linux.
--        --skip_permissions_check = false,
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
--        name = 'vmfedsrv',
--
--        -- TLS server address (host:port)
--        remote_address = '192.168.50.20:8091',
--        --remote_address = 'vmfedsrv.quyllur.home:8091',
--
--        -- The value can be "user@host:port" (it accepts the same syntax as the 'wezterm ssh' subcommand).
--        bootstrap_via_ssh = 'vmfedsrv',
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


------------------------------------------------------------------------------------
-- Setting> Data para crear mis Exec Domains
------------------------------------------------------------------------------------
--
-- Data usada para definir un 'ExecDomain' (parametros que se usa la funcion 'wezterm.exec_domain()' para definir este dominio).
-- URL: https://wezterm.org/config/lua/ExecDomain.html
mod.exec_domain_datas = nil
--mod.exec_domain_datas = {
--    {
--        -- Nombre del dominio
--        name = 'exec:name1',
--
--        -- Callback que tiene como argumento el objeto 'SpawnCommand' el cual modifica y devuelve el mismo objeto modificiado.
--        -- URL: https://wezterm.org/config/lua/SpawnCommand.html
--        callback_fixup = nil,
--
--        -- Callback usado para generar el label usado para mostrar el los 'InputSelector' de 'Launcher Menu'.
--        -- Se envia un solo argumento que es el nombre del dominio.
--        -- Opcional.
--        callback_label = nil,
--
--        -- Informacion adicional usado para pintar informacion adicional en el 'InputSelector'
--        -- Opcional.
--        data = nil,
--
--        -- Si esta asociado a un proceso remoto externo al equipo local donde se ejecuta el emulador de terminal.
--        -- Siempre tiene un filesystem diferente al equipo local, por los contenedores son considerados external.
--        -- Por defecto es 'true'.
--        is_external = true,
--    },
--}



------------------------------------------------------------------------------------
-- Setting> Workspace tag (permite crear workspace asociado a full-path)
------------------------------------------------------------------------------------
--
-- Arreglo de tag de workspace, usado para crear worspace basado en ruta de un determinado categoria de dominio o dominio.
-- > name             : Nombre unico del tag.
--                      Debido a que inicialemente es el nombre del workspace, debe ser unico no puede usarse el nombre de workspace
--                      por defecto.
-- > fullpath         : Ruta completa del directorio de trabajo.
-- > domain_category  : Define una forma de agrupar el domino al cual puede pertener un ruta 'fullpath' (working directory).
--     > local        : Si es el dominio local o un dominio de tipo 'unix' (si esta asociado a un servidor IPC ubicado en
--                      el mismo host que el emulador de terminal.
--     > distrobox    : Si es un dominio de tipo 'exec' asociado a un contenedor distrobox.
--     > wsl          : Si es un dominio de tipo 'wsl'
-- > domain           : Opcional. Si no se define, la ruta aplica a todos los dominios de la misma categoria
-- > callback         : Funcion con parametros usado que modifica o crea paneles del workspace. Los parametros de este callback son:
--   > Objeto 'Window'
--   > Objeto 'Pane' (nuevo panel creado del tab por defecto del worspace creado)
--   > Workspace name
--   > Workspace info
--mod.workspace_tags = nil
mod.workspace_tags = {
    {
        name = 'download',
        fullpath = '/tempo/download',
        domain_category = 'local',
    },
}



------------------------------------------------------------------------------------
-- Setting> Launching Programs
------------------------------------------------------------------------------------

mod.launch_menu = {
   {
       -- Optional label to show in the launcher. If omitted, a label is derived from the `args`.
       label = " PowerShell Core",
       -- Command to run into new tab. The argument array to spawn.
       args =  { "pwsh", "-l" },
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
--
-- Exportar
--
return mod
