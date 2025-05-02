--
-- Aqui configure los cliente LSP cuyo adaptadores son creados por un plugin
--


--------------------------------------------------------------------------------------------------
-- DAP Client Adapter> Adaptador del cliente DAP para 'Eclipse JDTLS' para Java SE
--------------------------------------------------------------------------------------------------
--
-- Vease ./ftplugin/java.lua
--

-- Descubrir el 'main clase' para la depuracion usando el DAP cliente (Equivalente a ':JdtUpdateDebugConfigs')
-- No se recomienda invocarlo en este funcion. Debe ser invocado cuando 'eclipse.jdt.ls' esta completamente cargado
--require("jdtls.dap").setup_dap_main_class_configs()

-- https://github.com/mfussenegger/nvim-jdtls/discussions/592
--require('jdtls.dap').setup_dap_main_class_configs({ on_ready = function() require("dap").continue() end })
