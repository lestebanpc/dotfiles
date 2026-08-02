--
-- El 'multiplexer server' cuando se inicia, por defecto (sin configurar algo adicional) permite:
--   > Localmente abre un socket IPC por defecto.
--   > Acceso remoto requiere que se ejecute una proxy 'wezterm cli proxy'.
--   > Por defectro el proxy se comuinica usando el tunel SSH. Tambien puede comunicarse usando TLS pero requiere configuracacion del
--     'config.tls_server'.
-- Adicional a esta configuracion por defecto se puede configurar:
--   > Moficiar el socket IPC por defecto, establiendo uno con un nombre y ubicacion personalizada.
--   > Crear otros sockets IPC para permitir instanciaer otras instancias del servidor.
--   > Habilitar acesso remoto por TLS al 'multiplexer server':
--     > Usando SSH para conectarse e iniciar automaticamente el servidor (el handkshake TLS sera automatico si
--       pasa el handshake SSH).
--     > Sir usar SSH. El 'multiplexer server' dene ser inicia previamente.
--
local mm_wezterm = require('wezterm')
local mod = mm_wezterm.config_builder()


------------------------------------------------------------------------------------
-- Definir el server TLS
------------------------------------------------------------------------------------
--
-- > Si el cliente realiza el handshake TLS usando una conexion SSH previa, no es obligatorio configurar
--   certificados para el servidor TLS:
--   > A nivel del cliente TLS (terminal GUI) debera tener acceso al server SSH y indicado su acceso en
--     la propiedad 'bootstrap_via_ssh'.
--   > Si no se especifica el certificado del servidor, el servidor se inicia creando sus propios
--     certificados autofirmados.
--   > El cliente TLS esta diseñado para conectar al servidor TLS con estos certificados autofirmados.
-- > Por defecto la VM WSL2 esta en un red ¿aislada conectado al host usando un ruoter virtual?.
--   Por tal motivo:
--   > No es recomendado acceder a este por SSH ni por TLS.
-- > Vease: https://wezterm.org/multiplexing.html#tls-domains
--

--mod.tls_servers = {
--    {
--        -- The 'address:port' combination on which the server will listen for client connections.
--        -- Use '0.0.0.0' cuando dese vicular el puerto a todas las interfaz de red del servidor.
--        -- Use la IP especifica si desea vincular a la interfaz de red especifica (asociada a la IP).
--        bind_address = '0.0.0.0:8091',
--        --bind_address = '192.168.50.50:8091',
--
--        --
--        -- Campos requeridos si el cliente no se conecta usando SSH:
--        --
--
--        -- Si el cliente no se conecta usando SSH, se requiere que el servidor especificar el certificado que
--        -- usara el servidor TLS:
--
--        -- Clave privada del certificado del servidor TLS
--        --pem_private_key = "/path/to/key.pem",
--
--        -- Certificado del servidor TLS
--        --pem_cert = "/path/to/cert.pem",
--
--        -- Bundle de certificado del CA que realizan/validan la firman el certificado del servidor TLS
--        --pem_ca = "/path/to/chain.pem",
--
--        -- Lista de certificados CA adicionales usados como 'trust-store' para el 'multiplexer server' cuando
--        -- este actual como cliente TLS.
--        --pem_root_certs = { "/some/path/ca1.pem", "/some/path/ca2.pem" },
--    },
--}


------------------------------------------------------------------------------------
-- Definir los client/server IPC
------------------------------------------------------------------------------------
--
-- > Cada servidor IPC que se define implica una instancia independiente del 'multiplexer server'.
-- > Cada cliente IPC se conecta a un servidor IPC definido, iniciando antes un comando 'serve_command' y
--   pudiendo enviar las peticiones del cliente a un 'proxy_commnad'.
--

mod.unix_domains = {
    {
        -- Variables usado por cliente/server IPC:

        -- Nombre del dominio
        name = 'wsl_ipc',

        -- Ruta y nombre de socket IPC. Si no se especifca se crea en base a nombre del dominio.
        -- Notas: Para que la terminal GUI usa la misma ruta del socket, modificar:
        --   > Cambiar 'lucianoepc' por nombre del usuario usado en Windows.
        --   > Cambiar 'Ubuntu' por el nombre de la distribucion linux a usado.
        socket_path = "/mnt/c/Users/lucianoepc/.local/share/wezterm/Ubuntu.sock",

        -- If true, do not attempt to start this server if we try and fail to connect to it.
        --no_serve_automatically = false,

        -- If true, bypass checking for secure ownership of the socket_path.
        -- No se recomienda usarlo solo en casos especiales como:
        --  > Si usa WSL y el archivo socket este en una unidad montada NTFS del host, esta siempre se crea con
        --    muchos permisos de lo recomendado. Esta opcion permite usar este tipo de archivo desde Linux.
        skip_permissions_check = true,


        -- Variables usados solo por el cliente IPC:

        -- Specify the round-trip latency threshold for enabling predictive local.
        -- This option only applies when 'multiplexing = "WezTerm"'.
        --local_echo_threshold_ms = 10,

        -- Wezterm envia la peticiones al 'proxy command' el cual se encarga de redirigir la peticion al socket
        -- real asociadoa al mutiplexer.
        -- No se recomienda usarlo solo en casos especiales como:
        --  > Si usa WSL permite acceder al socket IPC usando ....
        --proxy_command = { 'nc', '-U', '/Users/lucianoepc/.local/share/wezterm/sock' },

        -- Comando ejecutado antes que el cliente IPC se conecte al server IPC.
        --serve_command = { 'wsl', 'wezterm-mux-server', '--daemonize' },
    },
}


------------------------------------------------------------------------------------
--
-- Return the configuration to wezterm
return mod
