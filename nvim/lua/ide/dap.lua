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

vim.fn.sign_define('DapBreakpoint', { text='', texthl='DapBreakpoint', linehl='', numhl='' })
vim.fn.sign_define('DapBreakpointCondition', { text='ﳁ', texthl='DapBreakpoint', linehl='', numhl='' })
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

dap.listeners.after.event_initialized["dapui_config"] = function()
      dap_ui.open()
   end

dap.listeners.before.event_terminated["dapui_config"] = function()
      dap_ui.close()
   end

dap.listeners.before.event_exited["dapui_config"] = function()
      dap_ui.close()
   end


--2. Paquete 'telescope-dap.nvim': Integracion entre Telescope y nVim.DAP
local telescope = require('telescope')
telescope.load_extension('dap')


--3. Paquete 'nvim-dap-virtual-text': Adicionar texto de ayuda en la depuracion
local dap_virtual_text = require('nvim-dap-virtual-text')
dap_virtual_text.setup ({
    commented = true,              -- prefix virtual text with comment string
})


