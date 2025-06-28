
--------------------------------------------------------------------------------------------------
--DAP Client> Configuracion del DAP Client nVim.DAP
--------------------------------------------------------------------------------------------------

--Customize the signs
--vim.highlight.create('DapBreakpoint', { ctermbg=0, guifg='#993939', guibg='#31353f' }, false)
--vim.highlight.create('DapLogPoint', { ctermbg=0, guifg='#61afef', guibg='#31353f' }, false)
--vim.highlight.create('DapStopped', { ctermbg=0, guifg='#98c379', guibg='#31353f' }, false)

--vim.fn.sign_define('DapBreakpoint', { text='', texthl='DapBreakpoint', linehl='DapBreakpoint', numhl='DapBreakpoint' })
--vim.fn.sign_define('DapBreakpointCondition', { text='ﳁ', texthl='DapBreakpoint', linehl='DapBreakpoint', numhl='DapBreakpoint' })
--vim.fn.sign_define('DapBreakpointRejected', { text='', texthl='DapBreakpoint', linehl='DapBreakpoint', numhl= 'DapBreakpoint' })
--vim.fn.sign_define('DapLogPoint', { text='', texthl='DapLogPoint', linehl='DapLogPoint', numhl= 'DapLogPoint' })
--vim.fn.sign_define('DapStopped', { text='', texthl='DapStopped', linehl='DapStopped', numhl= 'DapStopped' })

vim.fn.sign_define('DapBreakpoint', { text='', texthl='DapBreakpoint', linehl='', numhl='' })
vim.fn.sign_define('DapBreakpointCondition', { text='•', texthl='DapBreakpoint', linehl='', numhl='' })
vim.fn.sign_define('DapBreakpointRejected', { text='', texthl='DapBreakpoint', linehl='', numhl= '' })
vim.fn.sign_define('DapLogPoint', { text='', texthl='DapLogPoint', linehl='', numhl= '' })
vim.fn.sign_define('DapStopped', { text='', texthl='DapStopped', linehl='', numhl= '' })



--------------------------------------------------------------------------------------------------
--DAP Client> Mejoras del UI asociado a nVim.DAP
--------------------------------------------------------------------------------------------------

local dap=require("dap")
local dap_ui=require("dapui")

--1. Paquete 'nvim-dap-ui': Adicionar mejoras en el UI por defecto de nVim.DAP
--Usar la configuración por defecto
dap_ui.setup({
    icons = { expanded = "", collapsed = "", current_frame = "" },
    mappings = {
        -- Use a table to apply multiple mappings
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
        toggle = "t",
    },
    -- Use this to override mappings for specific elements
    element_mappings = {
        -- Example:
        -- stacks = {
        --   open = "<CR>",
        --   expand = "o",
        -- }
    },
    -- Expand lines larger than the window
    -- Requires >= 0.7
    expand_lines = vim.fn.has("nvim-0.7") == 1,
    -- Layouts define sections of the screen to place windows.
    -- The position can be "left", "right", "top" or "bottom".
    -- The size specifies the height/width depending on position. It can be an Int
    -- or a Float. Integer specifies height/width directly (i.e. 20 lines/columns) while
    -- Float value specifies percentage (i.e. 0.3 - 30% of available lines/columns)
    -- Elements are the elements shown in the layout (in order).
    -- Layouts are opened in order so that earlier layouts take priority in window sizing.
    layouts = {
        {
            elements = {
                -- Elements can be strings or table with id and size keys.
                { id = "scopes", size = 0.25 },
                "breakpoints",
                "stacks",
                "watches",
            },
            size = 40, -- 40 columns
            position = "left",
        },
        {
            elements = {
                "repl",
                "console",
            },
            size = 0.25, -- 25% of total lines
            position = "bottom",
        },
    },
    controls = {
        -- Requires Neovim nightly (or 0.8 when released)
        enabled = true,
        -- Display controls in this element
        element = "repl",
        icons = {
            pause = "",
            play = "",
            step_into = "",
            step_over = "",
            step_out = "",
            step_back = "",
            run_last = "",
            terminate = "",
        },
    },
    floating = {
        max_height = nil, -- These can be integers or a float between 0 and 1.
        max_width = nil, -- Floats will be treated as percentage of your screen.
        border = "single", -- Border style. Can be "single", "double" or "rounded"
        mappings = {
            close = { "q", "<Esc>" },
        },
    },
    windows = { indent = 1 },
    render = {
        max_type_length = nil, -- Can be integer or nil.
        max_value_lines = 100, -- Can be integer or nil.
    }

})
--2. Mostrar y cerrar UI segun los eventos del DAP
dap.listeners.after.event_initialized["dapui_config"] = function()

        dap_ui.open()

        -- En python, si usas una terminal externa, cerrar el consola integrada REPL
        --local cfg = session.config
        --if cfg.type == "python" and cfg.console == "externalTerminal" then
        --    dap_ui.close("repl")
        --end

    end

dap.listeners.before.event_terminated["dapui_config"] = function()
      dap_ui.close()
   end

dap.listeners.before.event_exited["dapui_config"] = function()
      dap_ui.close()
   end


--3. External terminal


if vim.g.use_tmux then

    --dap.defaults.fallback.external_terminal = {
    --    command = 'tmux',
    --    args = { 'split-pane', '-vp', '20', '-c', vim.fn.getcwd() },
    --    --args = { 'split-pane', '-vp', '20', '-c', vim.fn.getcwd(), 'bash', '-ic' },
    --}

    dap.defaults.fallback.external_terminal = {
        command = 'tmux_run_cmd',
        args = { '-w' , vim.fn.getcwd(), '-h', '20', '--', },
    }

--else

    --dap.defaults.fallback.external_terminal = {
    --    command = 'ptyxis',
    --    args = { '-d', vim.fn.getcwd(), '--' },
    --}

end



--------------------------------------------------------------------------------------------------
--DAP Client> Keymappings
--------------------------------------------------------------------------------------------------
--
-- URL: https://github.com/mfussenegger/nvim-dap/blob/master/doc/dap.txt
--


--1. Crear/Iniciar o Continuar una sesion DAP
--   > Si aún no hay una sesión activa.
--     > Se carga la configuración (definido en 'dap.configurations.java[]' y en '.vscode/launch.json').
--     > Si existe mas de uno, muestra un selector de configuracion a usar. Si solo existe uno, solo usa este.
--     > Se usa la configuracion seleccionada y se ejecuta 'requiere("dap").run(selected_config)'.
--   > Si existe una session activa (detenida), se usa la sesion activa y ejecuta la sesion
--     Se ejecuta hasta encontrar otro breakpoint o terminar la aplicacion.
vim.keymap.set("n", "<F5>", function() dap.continue() end, { noremap=true, silent=true, desc="DAP Start/Continue" })


--2. Termina solo la sesion DAP manteniendo los panels UI
--   Permite usar la UI para iniciar una nueva sesion y continuar la depuracion
vim.keymap.set("n", '<F3>', function() dap.disconnect() end, { noremap=true, silent=true, desc="DAP Disconnect" })


--3. Crear/Iniciar una sesion DAP usando la ultima configuracion usada.
--   > Ejecuta 'requiere("dap").run(config)' usando la ultima configuracion usada.
vim.keymap.set("n", "<F4>", function() dap.run_last()() end, { noremap=true, silent=true, desc="DAP Run" })


--4. Terminar la sesion DAP y cerrar los paneles UI
vim.keymap.set("n", "<space><F4>", function() dap.terminate() end, { noremap=true, silent=true, desc="DAP Terminate" })


--5. Gestion de keymappings
vim.keymap.set("n", "<F9>", function() dap.toggle_breakpoint() end, { noremap=true, desc="DAP Toogle breakpoint" })

vim.keymap.set("n", "<space><F9>",
    function()
        dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
    end,
    { noremap=true, silent=true, desc="DAP Set conditional breakpoint" }
)

--vim.keymap.set("n", "<space>dbs", "<cmd>lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>", { noremap=true, silent=true, desc="DAP Set log point" })
--vim.keymap.set("n", "<space>dbc", "<cmd>lua require'dap'.clear_breakpoints()<cr>", { noremap=true, silent=true, desc="DAP Clear breakpoints"})


--6. Navegacion dentro de la sesion DAP actual
vim.keymap.set("n", "<space><F8>", function() dap.run_to_cursor() end, { noremap=true, silent=true, desc="DAP Run to cursor" })
vim.keymap.set("n", "<F10>", function() dap.step_over() end, { noremap=true, silent=true, desc="DAP Step over" })
vim.keymap.set("n", "<F11>", function() dap.step_into() end, { noremap=true, silent=true, desc="DAP Step into" } )
vim.keymap.set("n", "<F12>", function() dap.step_out() end, { noremap=true, silent=true, desc="DAP Step out" })


--7. Generales

-- Abrir o cerrar (toogle) la consola integrada (REPL Console)
vim.keymap.set("n", "<space>dc", function() dap.repl.toggle() end, { noremap=true, silent=true, desc="DAP Toggle REPL console" })

--vim.keymap.set("n", "<space>dh", "<cmd>lua require('dapui').eval()<CR>", { noremap=true, silent=true, desc="DAP Evaluate" })


-- Listar, ir o eliminar breakpoint (usando fzf-lua)
vim.keymap.set("n", "<space>db", function() require("fzf-lua").dap_breakpoints() end, { noremap=true, silent=true, desc="DAP List breakpoints" })

-- Listar e ir a los frames de depuracion (requiere una sesion DAP activa)
vim.keymap.set("n", "<space>df", function() require("fzf-lua").dap_frames() end, { noremap=true, silent=true, desc="DAP List debug frames" })



--------------------------------------------------------------------------------------------------
--DAP Client> Mejoras del UI asociado a nVim.DAP
--------------------------------------------------------------------------------------------------

--1. Paquete 'nvim-dap-virtual-text': Adicionar texto de ayuda en la depuracion
local dap_virtual_text = require('nvim-dap-virtual-text')
dap_virtual_text.setup ({
    commented = true,              -- prefix virtual text with comment string
})



--------------------------------------------------------------------------------------------------
--DAP Client> DAP adapters
--------------------------------------------------------------------------------------------------

-- Configuraciones del cliente DAO
require('ide.adapters.dap_basics')

-- Configuraciones del un adaptador de un cliente DAP
--   > DAP cliente complejos de configurar o
--   > DAP cliente que requieren adapatadores que lo conviertan el DAP server estandar
require('ide.adapters.dap_plugins')
