--------------------------------------------------------------------------------------------------
-- Adaptador del cliente LSP para 'Eclipse JDT LS' para Java SE
--------------------------------------------------------------------------------------------------
--
-- URL        : https://github.com/mfussenegger/nvim-jdtls
-- Referencia : https://github.com/neovim/nvim-lspconfig/blob/master/lsp/jdtls.lua
--

-- 01. Validar si ya se esta cargando o se cargo
if vim.b.ftplg_java_loaded then
  -- Si ya lo cargamos o esta en proceso de carge en este búfer, salimos
  return
end

-- Se inicia la carga del plugin
vim.b.ftplg_java_loaded = true


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
    root_path = vim.fn.getcwd()
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


-- 08. Starts a new client & server LSP, or attaches to an existing client & server
local jdtls_cfg = require('jdtls')

jdtls_cfg.start_or_attach({

      flags = {
        debounce_text_changes = 80,
      }, 

      -- We pass our on_attach keybindings to the configuration map 
      --on_attach = on_attach,
     
      -- Language server `initializationOptions`
      -- Plugins usados para JDTLS
      -- See: https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
      --init_options = {
      --  bundles = bundles
      --},

      
      -- Set the root directory to our found root_marker
      root_dir = root_path,

      -- Configure 'eclipse.jdt.ls' specific settings.
      -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
      -- for a list of options
      settings = {

        -- General setting for Java
        java = {

          --format = {
          --  settings = {
          --    -- Use Google Java style guidelines for formatting
          --    -- To use, make sure to download the file from https://github.com/google/styleguide/blob/gh-pages/eclipse-java-google-style.xml
          --    -- and place it in the ~/.local/share/eclipse directory
          --    url = "/.local/share/eclipse/eclipse-java-google-style.xml",
          --    profile = "GoogleStyle",
          --  },
          --},

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

          -- If you are developing in projects with different Java versions, you need
          -- to tell eclipse.jdt.ls to use the location of the JDK for your Java version
          -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
          -- And search for `interface RuntimeOption`
          -- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
          --configuration = {
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
          --}

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


