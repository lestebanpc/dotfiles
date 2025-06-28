--
-- Aqui configure los cliente LSP cuyo adaptadores son creados por un plugin
--


--------------------------------------------------------------------------------------------------
-- DAP Client Adapter> Adaptador del cliente DAP para 'Eclipse JDTLS' para Java SE
--------------------------------------------------------------------------------------------------
--
-- > El cliente DAP ('dap.adapter.java') se configura en './ftplugin/java.lua' usando las funciones del plugin 'nvim-jdtls'
-- > Ofrece un mecanismo para crear una configuracion, omitiendo todas las configuraciones definidas en 'dap.configuration.java'
--   y en '.vscode/launch.json', usando la funcion 'require("jdtls.dap").setup_dap_main_class_configs()' o el comando
--   ':JdtUpdateDebugConfigs'. Por lo que si usa 'dap.continue()' despues de esta funcion, solo ejecutara el definido por el
--   plugin del JDTLS
-- > Tambien se puede definir configuraciones personalizadas:
--   https://github.com/mfussenegger/nvim-dap/wiki/Java#configuration
--   https://github.com/microsoft/vscode-java-debug#options
--

local dap = require('dap')

local use_adapter = vim.g.use_lsp_adapters['java']

if use_adapter ~= nil and use_adapter == true then

    -- Si el request es 'launch', si la configuracion no define algunos campos esto es autocalculado usando la data de los archivos
    -- de configuracion de maven o graadle.
    -- > Los campos autogenerados son:
    --    > config.mainClass
    --    > config.projectName
    --    > config.modulePaths
    --    > config.classPaths
    --    > config.javaExec
    -- > Vease el 'enrich_dap_config()' del codigo fuente 'https://github.com/mfussenegger/nvim-jdtls/blob/master/lua/jdtls/dap.lua'.
    dap.configurations.java = {
        {
            --1. Options are required by nvim-dap
            type = 'java',
            request = 'attach',
            name = "Attach (Remote debug)",

            --2. Options for debugpy
            --   URL: https://github.com/microsoft/vscode-java-debug#options
            connect = function ()
                local host = vim.fn.input('Host [127.0.0.1]: ')
                host = host ~= '' and host or '127.0.0.1'
                local port = tonumber(vim.fn.input('Port [5678]: ')) or 5678
                return { host = host, port = port }
            end,
        },
        {
            --1. Options are required by nvim-dap
            type = 'java',
            request = 'launch',
            name = "Launch current project",

            --2. Options for debugpy
            --   URL: https://github.com/microsoft/vscode-java-debug#options
            console = 'externalTerminal',
        },
    }


end
