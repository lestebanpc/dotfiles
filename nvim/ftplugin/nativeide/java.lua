--------------------------------------------------------------------------------------------------
-- Adaptador del cliente LSP para 'Eclipse JDT LS' para Java SE
--------------------------------------------------------------------------------------------------
--
-- URL        : https://github.com/mfussenegger/nvim-jdtls
-- Referencia :
--    https://github.com/neovim/nvim-lspconfig/blob/master/lsp/jdtls.lua
--    https://github.com/mfussenegger/dotfiles/blob/master/vim/dot-config/nvim/ftplugin/java.lua
--

-- 01. Validar si ya se esta cargando o se cargo
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


-- 02. Obtener la ruta del workspace (ruta del proyecto principal)
--     En version Neovim < 0.10, use 'jdtls_cfg.setup.find_root({...})'
local root_path = vim.fs.root(0, {
    -- Multi-module projects
    '.git',
    'mvnw',
    'gradlew',
    'build.gradle',
    'build.gradle.kts',
    -- Single-module projects
    'build.xml',           -- Ant
    'pom.xml',             -- Maven
    'settings.gradle',     -- Gradle
    'settings.gradle.kts', -- Gradle
})

if root_path == nil or root_path == "" then
    --root_path = vim.fn.getcwd()
    return
end
--vim.notify('jdtls> root_path: ' .. root_path)


-- 03. Obtener la ruta donde se almacena la metadata de proyectos usado 'eclipse.jdt.ls' (cache).
--     If you are working with multiple different projects, each project must use a dedicated
--     data directory.
local metadata_path = ""


-- ¿Porque no usar 'vim.fn.stdpath("cache")' que representa a '~/.cache/nvim'?
if (vim.g.os_type == 0) then
    --Si es Windows
    metadata_path = os.getenv('APPDATA') .. "/eclipse/jdtls"
else
    --Otros casos
    metadata_path = os.getenv('HOME') .. "/.local/share/eclipse/jdtls"
end

-- Usado el nombre de workspace para crear un folder unico para el cache.
metadata_path = metadata_path .. vim.fn.fnamemodify(root_path, ":p:h:t")
--vim.notify('jdtls> metadata_path: ' .. metadata_path)


-- 04. Obtener la ruta del LSP server
local lsp_server_path = vim.g.programs_base_path .. "/lsp_servers/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"
lsp_server_path = vim.fn.glob(lsp_server_path)
--vim.notify('jdtls> lsp_server_path: ' .. lsp_server_path)


-- 05. Ruta del archivo de configuracion del LSP server
local lsp_server_config_path = vim.g.programs_base_path .. "/lsp_servers/jdtls/config_"

if (vim.g.os_type == 0) then
    --Si es Windows
   lsp_server_config_path = lsp_server_config_path .. 'win'
else
    --Linux x64
   lsp_server_config_path = lsp_server_config_path .. 'linux'
end
--vim.notify('jdtls> lsp_server_config_path: ' .. lsp_server_config_path)



-- 06. Obtiener la ruta de jar plugins para el JDTLS

-- Adicionar la ruta de plugins de VSCode Java Debugger
local bundles = {
    vim.fn.glob( vim.g.programs_base_path .. '/vsc_extensions/ms_java_debug/server/com.microsoft.java.debug.plugin-*.jar'),
}

-- Adicionar la ruta plugin para VSCode Java Test
vim.list_extend(bundles, vim.split(vim.fn.glob(vim.g.programs_base_path .. '/vsc_extensions/ms_java_test/server/*.jar', 1), "\n"))
--vim.notify('jdtls> lsp_server_config_path: \n' .. vim.inspect(bundles))


-- 07. Fuciones de ayuda

-- Helper function for creating keymaps
--function map(rhs, lhs, bufopts, desc)
--    bufopts.desc = desc
--    vim.keymap.set("n", rhs, lhs, bufopts)
--end


-- 08. Logica del autocomando 'LspAttach' que se ejecuta cuando el buffer se vincula al LSP server.
--     Este autocomando se ejecuta adicional al definido en: vim.api.nvim_create_autocmd('LspAttach', {})
local jdtls_cfg = require('jdtls')
local on_attach = function(client, bufnr)

    --Obtener la informacion del CodeLens ¿del workspace?
    vim.lsp.codelens.refresh()

    --Permitr que la depuracion permitas cambios en caliente.
    jdtls_cfg.setup_dap({ hotcodereplace = "auto" })

    -- Descubrir el 'main clase' para la depuracion usando el DAP cliente (Equivalente a ':JdtUpdateDebugConfigs')
    -- No se recomienda invocarlo en este funcion. Debe ser invocado cuando 'eclipse.jdt.ls' esta completamente cargado
    --require("jdtls.dap").setup_dap_main_class_configs()

    --¿?
    --require("jdtls.setup").add_commands()

    -- Register keymappings
    vim.keymap.set("n", "<space>oi", jdtls_cfg.organize_imports, { noremap=true, silent=true, buffer=bufnr, desc="Organize Imports" })

    vim.keymap.set("n", "<space>ev", jdtls_cfg.extract_variable, { noremap=true, silent=true, buffer=bufnr, desc="Extract Variable" })
    vim.keymap.set("v", "<space>ev", "<esc><cmd>lua require('jdtls').extract_variable(true)<cr>", { noremap=true, silent=true, buffer=bufnr, desc="Extract Variable" })

    vim.keymap.set("n", "<space>ec", jdtls_cfg.extract_constant, { noremap=true, silent=true, buffer=bufnr, desc="Extract Constant" })
    vim.keymap.set("v", "<space>ec", "<esc><cmd>lua require('jdtls').extract_constant(true)<cr>", { noremap=true, silent=true, buffer=bufnr, desc="Extract Constant" })

    vim.keymap.set("n", "<space>em", jdtls_cfg.extract_method, { noremap=true, silent=true, buffer=bufnr, desc="Extract Method" })
    vim.keymap.set("v", "<space>em", "<esc><Cmd>lua require('jdtls').extract_method(true)<cr>", { noremap=true, silent=true, buffer=bufnr, desc="Extract Method" })

    vim.keymap.set("n", "<space>tm", jdtls_cfg.test_nearest_method, { noremap=true, silent=true, buffer=bufnr, desc="Test Nearest Method" })
    vim.keymap.set("n", "<space>tc", jdtls_cfg.test_class, { noremap=true, silent=true, buffer=bufnr, desc="Test Class" })
    --vim.keymap.set("n", "<space>ju", "<cmd>JdtUpdateConfig<cr>", { noremap=true, silent=true, buffer=bufnr, desc="Update Config" })

    -- Autocomando (evento) que se ejecuta cuando se guarda el buffer
    -- Refrescar el CodeLens ¿del workspace?
    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = { "*.java" },
        callback = function()
            local _, _ = pcall(vim.lsp.codelens.refresh)
        end,
    })
end


-- 09. Capacidades adicionales al por defecto enviados por el LSP server

-- Adicionando valores a las capadades por defecto del LSP, las capadades adicionales de autocompletado
local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Modificando algunas capacidades por defecto
--lsp_capabilities.textDocument.completion.completionItem.snippetSupport = true
--lps_capabilities.textDocument.foldingRange = {
--    dynamicRegistration = false,
--    lineFoldingOnly = true,
--  }

local lsp_extendedClientCapabilities = jdtls_cfg.extendedClientCapabilities
lsp_extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
lsp_extendedClientCapabilities.onCompletionItemSelectedCommand = "editor.action.triggerParameterHints"

-- 10. Starts a new client & server LSP, or attaches to an existing client & server
jdtls_cfg.start_or_attach({

      flags = {
        debounce_text_changes = 80,
      },

      -- We pass our on_attach keybindings to the configuration map
      on_attach = on_attach,

      -- Modificar las capacidades ofrecidas por defecto por el servidor LSP
      capabilities = lsp_capabilities,

      -- Set the root directory to our found root_marker
      root_dir = root_path,

      -- Language server `initializationOptions`
      -- Plugins usados para JDTLS
      -- See: https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
      init_options = {
        bundles = bundles,
        extendedClientCapabilities = lsp_extendedClientCapabilities,
      },

      -- Configure 'eclipse.jdt.ls' specific settings.
      -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
      -- for a list of options
      settings = {

        -- General setting for Java
        java = {


          autobuild = { enabled = false },
          signatureHelp = { enabled = true },

          -- Use fernflower to decompile library code
          --contentProvider = { preferred = 'fernflower' },

          -- Specify any completion options
          completion = {
            favoriteStaticMembers = {
              "org.hamcrest.MatcherAssert.assertThat",
              "org.hamcrest.Matchers.*",
              "org.hamcrest.CoreMatchers.*",
              "org.junit.jupiter.api.Assertions.*",
              "java.util.Objects.requireNonNull",
              "java.util.Objects.requireNonNullElse",
              "org.mockito.Mockito.*"
            },
            filteredTypes = {
              "com.sun.*",
              "io.micrometer.shaded.*",
              "java.awt.*",
              "jdk.*",
              "sun.*",
            },
          },


          saveActions = {
            organizeImports = true,
          },

          -- Specify any options for organizing imports
          sources = {
            organizeImports = {
              starThreshold = 9999;
              staticStarThreshold = 9999;
            },
          },

          -- How code generation should act
          codeGeneration = {
            toString = {
              template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
            },
            hashCodeEquals = {
              useJava7Objects = true,
            },
            useBlocks = true,
          },

          eclipse = {
            downloadSources = true,
          },

          -- If you are developing in projects with different Java versions, you need
          -- to tell eclipse.jdt.ls to use the location of the JDK for your Java version
          -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
          -- And search for `interface RuntimeOption`
          -- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
          configuration = {
              updateBuildConfiguration = "interactive",
          --  runtimes = {
          --    {
          --      name = "JavaSE-17",
          --      path = home .. "/.asdf/installs/java/corretto-17.0.4.9.1",
          --    },
          --    {
          --      name = "JavaSE-11",
          --      path = home .. "/.asdf/installs/java/corretto-11.0.16.9.1",
          --    },
          --    {
          --      name = "JavaSE-1.8",
          --      path = home .. "/.asdf/installs/java/corretto-8.352.08.1"
          --    },
          --  }
          },

          maven = {
            downloadSources = true,
          },

          implementationsCodeLens = {
            enabled = true,
          },

          referencesCodeLens = {
            enabled = true,
          },

          references = {
            includeDecompiledSources = true,
          },

          inlayHints = {
            parameterNames = {
              enabled = "all", -- literals, all, none
            },
          },


          format = {
            enabled = false,
          },
          -- NOTE: We can set the formatter to use different styles
          --format = {
          --  enabled = true,
          --  settings = {
          --    -- Use Google Java style guidelines for formatting
          --    -- To use, make sure to download the file from https://github.com/google/styleguide/blob/gh-pages/eclipse-java-google-style.xml
          --    -- and place it in the ~/.local/share/eclipse directory
          --    url = vim.fn.stdpath "config" .. "/lang-servers/intellij-java-google-style.xml",
          --    profile = "GoogleStyle",
          --  },
          --},


        }
      },

      -- cmd is the command that starts the language server. Whatever is placed
      -- here is what is passed to the command line to execute jdtls.
      -- Note that eclipse.jdt.ls must be started with a Java version of 17 or higher
      -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
      -- for the full list of options
      cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xmx2g',
        '--add-modules=ALL-SYSTEM',
        '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
        -- If you use lombok, download the lombok jar and place it in
        '-javaagent:' .. vim.g.programs_base_path .. '/lsp_servers/jdtls/lombok.jar',

        -- The jar file is located where jdtls was installed. This will need to be updated
        -- to the location where you installed jdtls
        '-jar', lsp_server_path,

        -- The configuration for jdtls is also placed where jdtls was installed. This will
        -- need to be updated depending on your environment
        '-configuration', lsp_server_config_path,

        -- Use the workspace_folder defined above to store data for this project
        '-data', metadata_path,
      },
   })
