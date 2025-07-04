--
-- URL        : https://github.com/mfussenegger/nvim-jdtls
-- Referencia :
--    https://github.com/mfussenegger/nvim-jdtls/blob/master/doc/jdtls.txt
--    https://github.com/neovim/nvim-lspconfig/blob/master/lsp/jdtls.lua
--    https://codeberg.org/mfussenegger/dotfiles/src/branch/master/vim/dot-config/nvim/ftplugin/java.lua
-- Codigo de integracion con 'nvim-dap'
--    https://github.com/mfussenegger/nvim-jdtls/blob/master/lua/jdtls/dap.lua
--

-- Validar si ya se esta cargando o se cargo
if vim.b.ftplg_java_loaded then
  -- Si ya lo cargamos o esta en proceso de carge en este buffer, salimos
  return
end

-- Se inicia la carga del plugin
vim.b.ftplg_java_loaded = true


-- Si no esta habilitado el usar el LSP cliente
local use_adapter = vim.g.use_lsp_adapters['java']
if use_adapter == nil or use_adapter ~= true then
    return
end


--------------------------------------------------------------------------------------------------
-- Configuracion general de Eclipse JDTLS
--------------------------------------------------------------------------------------------------

local utils = require("utils.java")

--1. Validar si existe un root del workspace valido
local root_path = utils.get_workspace_root()
if root_path == nil or root_path == "" then
    return
end
--vim.notify('jdtls> root_path: ' .. root_path)


--2. Logica del autocomando 'LspAttach' que se ejecuta cuando el buffer se vincula al LSP server.
--   Autocomando espefico para Java y adicional al ejecutado 'vim.api.nvim_create_autocmd('LspAttach', {})'.
local jdtls_cfg = require('jdtls')

local on_attach = function(client, bufnr)

    --1. Obtener la informacion del CodeLens ¿del workspace?
    vim.lsp.codelens.refresh()

    -- Si se usa tmux, usar la terminal externa configurada para el cliente DAP 'nvim-dap'
    local dap_config_override = { }
    if vim.g.use_tmux then
        dap_config_override.console = 'externalTerminal'
    end


    --2. Configura el cliente DAP para Java ('dap.adapter.java')
    --   > Si la configuracion no define 'config.mainClass', 'config.projectName', 'config.modulePaths', 'config.classPaths', 'config.javaExec',
    --     este calcula los valores usando la configuracion usada en el maven o graadle (vease el 'enrich_dap_config()').
    --   > Se define 'hotcodereplace' para permitir los cambios en depuracion en caliente.
    jdtls_cfg.setup_dap({ hotcodereplace = "auto", config_overrides = dap_config_override, })


    --3. Keymappings: Code Actions
    vim.keymap.set("n", "<space>oi", jdtls_cfg.organize_imports, { noremap=true, silent=true, buffer=bufnr, desc="LSP Organize Imports" })

    vim.keymap.set("n", "<space>ev", jdtls_cfg.extract_variable, { noremap=true, silent=true, buffer=bufnr, desc="LSP Extract Variable" })
    vim.keymap.set("v", "<space>ev", "<esc><cmd>lua require('jdtls').extract_variable(true)<cr>", { noremap=true, silent=true, buffer=bufnr, desc="Extract Variable" })

    vim.keymap.set("n", "<space>ec", jdtls_cfg.extract_constant, { noremap=true, silent=true, buffer=bufnr, desc="LSP Extract Constant" })
    vim.keymap.set("v", "<space>ec", "<esc><cmd>lua require('jdtls').extract_constant(true)<cr>", { noremap=true, silent=true, buffer=bufnr, desc="LSP Extract Constant" })

    vim.keymap.set("n", "<space>em", jdtls_cfg.extract_method, { noremap=true, silent=true, buffer=bufnr, desc="LSP Extract Method" })
    vim.keymap.set("v", "<space>em", "<esc><Cmd>lua require('jdtls').extract_method(true)<cr>", { noremap=true, silent=true, buffer=bufnr, desc="LSP Extract Method" })


    --4. Keymappings: Star debugger creando una configuracion personalizada (no usa la configuracion existente)
    vim.keymap.set("n", "<space>F5", function ()
        jdtls_cfg.setup_dap_main_class_configs()
        require("dap").continue()
    end, { noremap=true, silent=true, buffer=bufnr, desc="DAP Start debugger" })


    --5. Keymappings: Debug a 'JUnit Test'
    --   > Permite iniciar el debugger de 'JUnit Test'.
    --   > Crea una config especifico y lo ejecuta usando usando 'require("dap").run()'.
    vim.keymap.set("n", "<space>dtm", function ()
        local dap_cfg_override = {}
        --local dap_cfg_override = utils.get_test_dap_config()
        jdtls_cfg.test_nearest_method({ config_overrides = dap_cfg_override, })
    end, { noremap=true, silent=true, buffer=bufnr, desc="DAP Test Nearest Method" })

    vim.keymap.set("n", "<space>dtc", function ()
        local dap_cfg_override = {}
        --local dap_cfg_override = utils.get_test_dap_config()
        jdtls_cfg.test_class({ config_overrides = dap_cfg_override, })
    end, { noremap=true, silent=true, buffer=bufnr, desc="DAP Test Class" })

    --6. Keymappings: Profile a 'JUnit Test'
    vim.keymap.set("n", "<space>dpm", function ()
        utils.test_with_profile(jdtls_cfg.test_nearest_method)
    end, { noremap=true, silent=true, buffer=bufnr, desc="DAP Test Nearest Method" })

    vim.keymap.set("n", "<space>dpc", function ()
        utils.test_with_profile(jdtls_cfg.test_class)
    end, { noremap=true, silent=true, buffer=bufnr, desc="DAP Test Class" })



    --7. Keymappings: General
    --vim.keymap.set("n", "<space>ju", "<cmd>JdtUpdateConfig<cr>", { noremap=true, silent=true, buffer=bufnr, desc="Update Config" })


    --8. Autocomando (evento) que se ejecuta cuando se guarda el buffer
    --   Refrescar el CodeLens ¿del workspace?
    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = { "*.java" },
        callback = function()
            local _, _ = pcall(vim.lsp.codelens.refresh)
        end,
    })

end


--3. Configuracion usada para ejecutar server LSP
local config = {

    flags = {
        debounce_text_changes = 80,
    },
    init_options = { },
    settings = { },
}

-- We pass our on_attach keybindings to the configuration map
config.on_attach = on_attach


config.capabilities = utils.get_server_capabilities()

-- Set the root directory to our found root_marker
config.root_dir = root_path

-- Language server `initializationOptions`
-- See: https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
config.init_options.bundles = utils.get_osgi_bundles()
config.init_options.extendedClientCapabilities = utils.get_client_capabilities()


-- Configure 'eclipse.jdt.ls' specific settings.
-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
-- General setting for Java
config.settings.java = utils.get_default_java_setting()

-- cmd is the command that starts the language server. Whatever is placed
-- here is what is passed to the command line to execute jdtls.
-- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
config.cmd = utils.get_lsp_cmd(vim.fn.fnamemodify(root_path, ":p:h:t"), nil)


--4. Starts a new client & server LSP, or attaches to an existing client & server
jdtls_cfg.start_or_attach(config)
