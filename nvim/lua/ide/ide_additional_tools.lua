-----------------------------------------------------------------------------------------------
-- Tool> Git> Signs de cambios del staging area (similar a coc-git)
-----------------------------------------------------------------------------------------------
--
-- URL: https://github.com/lewis6991/gitsigns.nvim
-- Muestra signgs de los cambios del staging area
-- Muesta infromacion del ultimo commit realizado para la linea de codigo ('git blame')
--

--Si se no usas COC
if vim.g.use_coc == false then

    require('gitsigns').setup({

        -- Keymappings
        on_attach = function(bufnr)

            local gitsigns = require('gitsigns')

            -- Navigation
            vim.keymap.set('n', ']c',
                function()
                    if vim.wo.diff then
                        vim.cmd.normal({']c', bang = true})
                    else
                        gitsigns.nav_hunk('next')
                    end
                end,
                { noremap = true, buffer = bufnr, desc = 'GIT Next stage hunks' })

            vim.keymap.set('n', '[c',
                function()
                    if vim.wo.diff then
                        vim.cmd.normal({'[c', bang = true})
                    else
                        gitsigns.nav_hunk('prev')
                    end
                end,
                { noremap = true, buffer = bufnr, desc = 'GIT Previous stage hunks' })

            -- Actions
            vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { noremap = true, buffer = bufnr, desc = 'GIT Stage hunk' })
            vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { noremap = true, buffer = bufnr, desc = 'GIT Reset hunk' })

            vim.keymap.set('v', '<leader>hs',
                function()
                    gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
                end,
                { noremap = true, buffer = bufnr, desc = 'GIT Stage hunks' })

            vim.keymap.set('v', '<leader>hr',
                function()
                    gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
                end,
                { noremap = true, buffer = bufnr, desc = 'GIT Stage hunks' })

            vim.keymap.set('n', '<leader>hS', gitsigns.stage_buffer, { noremap = true, buffer = bufnr, desc = 'GIT Stage hunks all buffer' })
            vim.keymap.set('n', '<leader>hR', gitsigns.reset_buffer, { noremap = true, buffer = bufnr, desc = 'GIT Reset hunks all buffer' })
            vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, { noremap = true, buffer = bufnr, desc = 'GIT Preview hunks' })
            vim.keymap.set('n', '<leader>hi', gitsigns.preview_hunk_inline, { noremap = true, buffer = bufnr, desc = 'GIT Preview hunks inline' })

            vim.keymap.set('n', '<leader>hb',
                function()
                    gitsigns.blame_line({ full = true })
                end,
                { noremap = true, buffer = bufnr, desc = 'GIT Blame line' })

            vim.keymap.set('n', '<leader>hd', gitsigns.diffthis, { noremap = true, buffer = bufnr, desc = 'GIT Diff this' })

            vim.keymap.set('n', '<leader>hD',
                function()
                    gitsigns.diffthis('~')
                end,
                { noremap = true, buffer = bufnr, desc = 'GIT Diff this' })

            vim.keymap.set('n', '<leader>hQ', function() gitsigns.setqflist('all') end, { noremap = true, buffer = bufnr, desc = 'GIT Show hunks Quickfix/Location List' })
            vim.keymap.set('n', '<leader>hq', gitsigns.setqflist, { noremap = true, buffer = bufnr, desc = 'GIT Show hunks Quickfix/Location List' })

            -- Toggles
            vim.keymap.set('n', '<leader>tb', gitsigns.toggle_current_line_blame, { noremap = true, buffer = bufnr, desc = 'GIT Stage hunks' })
            vim.keymap.set('n', '<leader>tw', gitsigns.toggle_word_diff, { noremap = true, buffer = bufnr, desc = 'GIT Stage hunks' })

            -- Text object
            vim.keymap.set({'o', 'x'}, 'ih', gitsigns.select_hunk, { noremap = true, buffer = bufnr, desc = 'GIT Select hunks' })

        end
    })
end

--------------------------------------------------------------------------------------------------
-- Tool> Merge Tool y File History for Git
--------------------------------------------------------------------------------------------------
--
-- URL: https://github.com/sindrets/diffview.nvim
-- Usar el modo diff de vim para mostrar diferencias entre commit Git

--------------------------------------------------------------------------------------------------
-- Tool> REST Client 'Kulala'
--------------------------------------------------------------------------------------------------
--
-- > URL: https://github.com/mistweaverco/kulala.nvim
--        https://neovim.getkulala.net/docs/getting-started
-- > Si se usa CoC, no funcionara el autocomletado si no se configura un cio para su cliente LSP
--


-- 01. Asociando el filtetype al una extension
--     Similar al siuguiente autocomando vim
--        augroup kulala_filetype_detect
--          autocmd!
--          autocmd BufRead,BufNewFile *.http set filetype=http
--          autocmd BufRead,BufNewFile *.rest set filetype=rest
--        augroup END

vim.filetype.add({
  extension = {
    ['http'] = 'http',
    --['rest'] = 'rest',
  },
})


-- 02. Configuracion (https://neovim.getkulala.net/docs/getting-started/configuration-options)
local kulala_mod = require("kulala")

kulala_mod.setup({

    -- Keymapping global y del filetype 'http' y 'rest'
    -- Vease: https://github.com/mistweaverco/kulala.nvim/blob/main/lua/kulala/config/keymaps.lua
    global_keymaps_prefix = "<leader>r",

    global_keymaps = true,
    --global_keymaps = {

    --    -- Keymapping global
    --    ["Open scratchpad"] = {
    --      "b", function() kulala_mod.scratchpad()  end,
    --    },

    --    ["Open kulala"] = {
    --      "o", function() kulala_mod.open() end,
    --    },

    --    ["Send request"] = {
    --      "s", function() kulala_mod.run() end, mode = { "n", "v" },
    --    },

    --    ["Send all requests"] = {
    --      "a", function() kulala_mod.run_all() end, mode = { "n", "v" },
    --    },

    --    ["Replay the last request"] = {
    --      "r", function() kulala_mod.replay() end,
    --    },

    --    -- Keymapping asociado al filetype 'http' y 'rest'
    --    ["Close window"] = {
    --      "q", function() kulala_mod.close() end, ft = { "http", "rest" },
    --    },

    --    ["Copy as cURL"] = {
    --      "c", function() kulala_mod.copy() end, ft = { "http", "rest" },
    --    },

    --    ["Paste from curl"] = {
    --      "C", function() kulala_mod.from_curl() end, ft = { "http", "rest" },
    --    },

    --    ["Inspect current request"] = {
    --      "i", function() kulala_mod.inspect() end, ft = { "http", "rest" },
    --    },

    --    ["Select environment"] = {
    --      "e", function() kulala_mod.set_selected_env() end, ft = { "http", "rest" },
    --    },

    --    ["Manage Auth Config"] = {
    --      "u", function() require("kulala.ui.auth_manager").open_auth_config() end, ft = { "http", "rest" },
    --    },

    --    ["Send request <cr>"] = {
    --      "<CR>", function() kulala_mod.run() end, mode = { "n", "v" }, ft = { "http", "rest" }, prefix = false,
    --    },

    --    ["Download GraphQL schema"] = {
    --      "g", function() kulala_mod.download_graphql_schema() end, ft = { "http", "rest" },
    --    },

    --    ["Jump to next request"] = {
    --      "n", function() kulala_mod.jump_next() end, ft = { "http", "rest" },
    --    },

    --    ["Jump to previous request"] = {
    --      "p", function() kulala_mod.jump_prev() end, ft = { "http", "rest" },
    --    },

    --    ["Find request"] = {
    --      "f", function() kulala_mod.search() end, ft = { "http", "rest" },
    --    },

    --    ["Toggle headers/body"] = {
    --      "t", function() kulala_mod.toggle_view() end, ft = { "http", "rest" },
    --    },

    --    ["Show stats"] = {
    --      "S", function() kulala_mod.show_stats() end, ft = { "http", "rest" },
    --    },

    --    ["Clear globals"] = {
    --      "x", function() kulala_mod.scripts_clear_global() end, ft = { "http", "rest" },
    --    },

    --    ["Clear cached files"] = {
    --      "X", function() kulala_mod.clear_cached_files() end, ft = { "http", "rest" },
    --    },
    --},

    -- Keymapping asicaido popup 'Kulala UI'
    -- Vease: https://github.com/mistweaverco/kulala.nvim/blob/main/lua/kulala/config/keymaps.lua
    kulala_keymaps_prefix = "",

    kulala_keymaps = true,
    --kulala_keymaps = {

    --    ["Show headers"] = {
    --      "H", function() require("kulala.ui").show_headers() end,
    --    },

    --    ["Show body"] = {
    --      "B", function() require("kulala.ui").show_body() end,
    --    },

    --    ["Show headers and body"] = {
    --      "A", function() require("kulala.ui").show_headers_body() end,
    --    },

    --    ["Show verbose"] = {
    --      "V", function() require("kulala.ui").show_verbose() end,
    --    },

    --    ["Show script output"] = {
    --      "O", function() require("kulala.ui").show_script_output() end,
    --    },

    --    ["Show stats"] = {
    --      "S", function() require("kulala.ui").show_stats() end,
    --    },

    --    ["Show report"] = {
    --      "R", function() require("kulala.ui").show_report() end,
    --    },

    --    ["Show filter"] = {
    --      "F", function() require("kulala.ui").toggle_filter() end,
    --    },

    --    ["Next response"] = {
    --      "]", function() require("kulala.ui").show_next() end, prefix = false,
    --    },

    --    ["Previous response"] = {
    --      "[", function() require("kulala.ui").show_previous() end, prefix = false,
    --    },

    --    ["Jump to response"] = {
    --      "<CR>", function() require("kulala.ui").keymap_enter() end, mode = { "n", "v" },
    --      desc = "also: Update filter and Send WS message for WS connections", prefix = false,
    --    },

    --    ["Clear responses history"] = {
    --      "X", function() require("kulala.ui").clear_responses_history() end,
    --    },

    --    ["Send WS message"] = {
    --      "<S-CR>", function() require("kulala.cmd.websocket").send() end, mode = { "n", "v" }, prefix = false,
    --    },

    --    ["Interrupt requests"] = {
    --      "<C-c>", function()  require("kulala.ui").interrupt_requests() end,
    --      desc = "also: CLose WS connection", prefix = false,
    --    },

    --    ["Show help"] = {
    --      "?", function() require("kulala.ui").show_help() end, prefix = false,
    --    },

    --    ["Show news"] = {
    --      "g?", function() require("kulala.ui").show_news() end, prefix = false,
    --    },

    --    ["Close"] = {
    --      "q", function() require("kulala.ui").close_kulala_buffer() end, prefix = false,
    --    },

    --},


})
