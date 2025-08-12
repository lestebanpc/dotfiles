local M = {}


local m_path_jdtls = vim.g.tools_path .. '/lsp_servers/jdtls'
local m_path_vsc_extension = vim.g.tools_path .. '/vsc_extensions'

---@return string|nil
function M.get_workspace_root()

    -- Obtener la ruta del workspace (ruta del proyecto principal)
    -- En version Neovim < 0.10, use 'jdtls_cfg.setup.find_root({...})'
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

    return root_path

end


function M.get_server_capabilities()

    -- Modificar las capacidades ofrecidas por defecto por el servidor LSP
    local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

    -- Modificando algunas capacidades por defecto
    --lsp_capabilities.textDocument.completion.completionItem.snippetSupport = true
    --lps_capabilities.textDocument.foldingRange = {
    --    dynamicRegistration = false,
    --    lineFoldingOnly = true,
    --  }

    return lsp_capabilities

end

---@param p_folder string
---@param p_files_patterns string[]
---@param p_files_to_exclude string[]|nil
---@return string[]
local function get_file_of_patterns(p_folder, p_files_patterns, p_files_to_exclude)

    local all_files = {}

    for i = 1, #p_files_patterns do
        local files_str = vim.fn.glob(p_folder .. '/' .. p_files_patterns[i], false)
        local files = vim.split(files_str, '\n')

        local n = #files
        local item = nil
        local excluded = false

        for j = 1, n do

            item = files[j]

            -- Verificar si se exluye
            excluded = false

            if p_files_to_exclude ~= nil then

                for k = 1, #p_files_to_exclude do
                    if not excluded and vim.startswith(item, p_files_to_exclude[k]) then
                        excluded = true
                    end
                end

            end

            -- Adicionar si no se excluye
            if not excluded then
                table.insert(all_files, item)
            end

        end


    end

    return all_files

end

-- Language server 'initializationOptions'
-- Plugins usados para JDTLS
-- See: https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
function M.get_osgi_bundles()

    --1. Obtiener la ruta de jar plugins para el JDTLS

    -- Adicionar la ruta de plugins de VSCode Java Debugger
    local bundles = get_file_of_patterns(m_path_vsc_extension .. '/ms_java_debug/server', { 'com.microsoft.java.debug.plugin-*.jar' }, nil)

    -- Adicionar la ruta plugin para VSCode Java Test
    local new_items = get_file_of_patterns(m_path_vsc_extension .. '/ms_java_test/server',
        {
            'junit-jupiter-*.jar',
            'junit-platform-*.jar',
            'junit-vintage-engine_*.jar',
            'org.opentest4j*.jar',
            'org.apiguardian.api_*.jar',
            'org.eclipse.jdt.junit4.runtime_*.jar',
            'org.eclipse.jdt.junit5.runtime_*.jar',
            'org.opentest4j_*.jar',
            'org.jacoco.*.jar',
            'org.objectweb.asm*.jar'
        },
        {
            'com.microsoft.java.test.runner-jar-with-dependencies.jar',
            'com.microsoft.java.test.runner.jar'
        })

    if #new_items > 0 then
        vim.list_extend(bundles, new_items)
    end

    -- Adicionar la ruta de plugins de VSCode Eclipse PDE
    new_items = get_file_of_patterns(m_path_vsc_extension .. '/tf_eclipse_pde/server', { '*.jar' }, nil)

    if #new_items > 0 then
        vim.list_extend(bundles, new_items)
    end

    -- Adicionar la ruta de plugins de VSCode Java Decompiler
    new_items = get_file_of_patterns(m_path_vsc_extension .. '/dg_java_decompiler/server', { '*.jar' }, nil)

    if #new_items > 0 then
        vim.list_extend(bundles, new_items)
    end

    -- Adicionar la ruta de plugins de VSCode Spring Boot
    if vim.g.java_springboot == true then

        local base_path = m_path_vsc_extension .. '/vm_spring_boot/jars/'

        -- https://github.com/spring-projects/spring-tools/blob/7d3d91ecfa6087ae2d0e0f595da61ce8f52fed96/vscode-extensions/vscode-spring-boot/package.json#L33
        -- https://github.com/JavaHello/spring-boot.nvim/blob/main/lua/spring_boot.lua
        new_items = {
            base_path .. "io.projectreactor.reactor-core.jar",
            base_path .. "org.reactivestreams.reactive-streams.jar",
            base_path .. "jdt-ls-commons.jar",
            base_path .. "jdt-ls-extension.jar",
            base_path .. "sts-gradle-tooling.jar",
        }

        vim.list_extend(bundles, new_items)
    end

    --vim.notify('jdtls> lsp_server_config_path: \n' .. vim.inspect(bundles))
    return bundles

end

-- Language server 'initializationOptions'
-- Plugins usados para JDTLS
-- See: https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
function M.get_client_capabilities()

    -- Capacidades adicionales al por defecto enviados por el LSP server
    local lsp_extendedClientCapabilities = require('jdtls').extendedClientCapabilities
    lsp_extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
    lsp_extendedClientCapabilities.onCompletionItemSelectedCommand = "editor.action.triggerParameterHints"

    return lsp_extendedClientCapabilities

end

-- Configure 'eclipse.jdt.ls' specific settings.
-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
function M.get_default_java_setting()

    -- General setting for Java
    local setting = {


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
                starThreshold = 9999,
                staticStarThreshold = 9999,
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


    return setting


end



-- The command that starts the language server. Whatever is placed here is what is passed to the command line to execute jdtls.
-- Note that eclipse.jdt.ls must be started with a Java version of 17 or higher.
-- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
---@param metadata_name string
---@param java_home string|nil
function M.get_lsp_cmd(metadata_name, java_home)

    --1. Generar la ruta donde se almacena la metadata de proyectos usado 'eclipse.jdt.ls' (cache).
    --   If you are working with multiple different projects, each project must use a dedicated
    --   data directory.
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
    metadata_path = metadata_path .. metadata_name
    --vim.notify('jdtls> metadata_path: ' .. metadata_path)


    --2. Obtener la ruta del LSP server
    local lsp_server_path = m_path_jdtls .. "/plugins/org.eclipse.equinox.launcher_*.jar"
    lsp_server_path = vim.fn.glob(lsp_server_path)
    --vim.notify('jdtls> lsp_server_path: ' .. lsp_server_path)


    --3. Ruta del archivo de configuracion del LSP server
    local lsp_server_config_path = m_path_jdtls .. "/config_"

    if (vim.g.os_type == 0) then
        --Si es Windows
        lsp_server_config_path = lsp_server_config_path .. 'win'
    else
        --Linux x64
        lsp_server_config_path = lsp_server_config_path .. 'linux'
    end
    --vim.notify('jdtls> lsp_server_config_path: ' .. lsp_server_config_path)


    --4. Java path
    local java_path = 'java'
    if java_home ~= nil then
        java_path = java_home .. '/bin/java'
    end


    local cmd = {
        java_path,
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
        '-javaagent:' .. m_path_jdtls .. '/lombok.jar',

        -- The jar file is located where jdtls was installed. This will need to be updated
        -- to the location where you installed jdtls
        '-jar', lsp_server_path,

        -- The configuration for jdtls is also placed where jdtls was installed. This will
        -- need to be updated depending on your environment
        '-configuration', lsp_server_config_path,

        -- Use the workspace_folder defined above to store data for this project
        '-data', metadata_path,
    }

    return cmd
end



function M.get_test_dap_config()
    local conf_overrides = {
        stepFilters = {
            skipClasses = { "$JDK", "junit.*" },
            skipSynthetics = true
        },
    }

    conf_overrides.vmArgs = table.concat({
        "-ea",
        "-XX:+TieredCompilation",
        "-XX:TieredStopAtLevel=1",
        "--add-modules", "jdk.incubator.vector",
        "--enable-native-access=ALL-UNNAMED",
    }, " ")

    return conf_overrides
end



---@param profile_event string
local function get_profile_dap_config(profile_event)

    if not profile_event then
        return nil
    end

    local async_profiler_so = vim.g.tools_path .. "/async_profiler/lib/libasyncProfiler.so"
    local event = 'event=' .. profile_event
    local vmArgs = "-ea -agentpath:" .. async_profiler_so .. "=start,"
    vmArgs = vmArgs .. event .. ",collapsed,file=/tmp/traces.txt"

    local config_overrides = {
        vmArgs = vmArgs,
        noDebug = true,
    }

    return config_overrides

end


local function show_profile_traces()

    -- Si no se soporta tmux, mostar en un tab de vim
    if not vim.g.use_tmux then
        vim.cmd.tabnew()
        vim.fn.jobstart({ "flamelens", "/tmp/traces.txt" }, { term = true })
        vim.cmd.startinsert()

        return
    end

    -- Si soporta tmux, ejecutar en un panel de una windows siguiente al actual
    vim.system({ 'tmux_run_cmd', '-s', '-c', '--', 'flamelens "/tmp/traces.txt"' })

end

function M.test_with_profile(test_fn)

    local choices = {
        'cpu,alloc=2m,lock=10ms',
        'cpu',
        'alloc',
        'wall',
        'context-switches',
        'cycles',
        'instructions',
        'cache-misses',
    }

    vim.ui.select(choices, { format_item = tostring }, function(choice)

        if not choice then
            return
        end

        local test_options = {
            config_overrides = get_profile_dap_config(choice),
            after_test = show_profile_traces,
        }

        test_fn(test_options)

    end)

end

return M
