--
-- Aqui configure los cliente LSP cuyo adaptadores son creados por un plugin
--


--------------------------------------------------------------------------------------------------
-- DAP Client Adapter> Adaptador del cliente DAP para 'Eclipse JDTLS' para Java SE
--------------------------------------------------------------------------------------------------
--
-- Vease ./ftplugin/java.lua
--

-- TODO Se requiere descubrir el 'main class' antes de iniciar la depuracion usando el DAP cliente.
-- 
-- Se debe usar el comando ':JdtUpdateDebugConfigs' (o invvar la funcion 'setup_dap_main_class_configs') cuando
-- el LSP server esta ready.
-- No se recomienda invocarlo en evento 'on_attach' de 'start_or_attach()' puede debe ser invocado cuando 'eclipse.jdt.ls' esta
-- completamente cargado. ¿sobrescribir el keymappings F5 a nivel buffer?
--
--require("jdtls.dap").setup_dap_main_class_configs()
--
-- Vease: https://github.com/mfussenegger/nvim-jdtls/discussions/592
--require('jdtls.dap').setup_dap_main_class_configs({ on_ready = function() require("dap").continue() end })
--
