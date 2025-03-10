------------------------------------------------------------------------------------------------
-- Package UI> EXTENDED> Explorer de archivos
------------------------------------------------------------------------------------------------

require("nvim-tree").setup({
    --hijack_cursor = false,
    --on_attach = function(bufnr)
    --    local bufmap = function(lhs, rhs, desc)
    --        vim.keymap.set('n', lhs, rhs, {buffer = bufnr, desc = desc})
    --    end

    --    local api = require('nvim-tree.api')

    --    bufmap('L', api.node.open.edit, 'Expand folder or go to file')
    --    bufmap('H', api.node.navigate.parent_close, 'Close parent folder')
    --    bufmap('gh', api.tree.toggle_hidden_filter, 'Toggle hidden files')
    --end
})

vim.keymap.set('n', '<leader>ee', '<cmd>NvimTreeToggle<cr>', { noremap = true })


------------------------------------------------------------------------------------------------
-- Package UI> EXTENDED> FZF (FuZzy Finder)
------------------------------------------------------------------------------------------------

----Si no se usa TMUX
--if (vim.g.os_type == 0) then
--
--    local fzf_opts = {
--        ["--ansi"]           = true,
--        ["--info"]           = "inline-right",
--        ["--height"]         = "80%",
--        ["--width"]         =  "99%",
--        ["--layout"]         = "reverse",
--        ["--border"]         = "none",
--        ["--highlight-line"] = true,
--     }
--
----Si se usa TMUX
--else
--
--    local fzf_opts = {
--        ["--ansi"]           = true,
--        ["--info"]           = "inline-right",
--        ["--height"]         = "80%",
--        ["--width"]         =  "99%",
--        ["--layout"]         = "reverse",
--        ["--border"]         = "none",
--        ["--highlight-line"] = true,
--        ["--tmux"]           = "center,99%,80%"
--     }
--
--end



local fzf_lua= require("fzf-lua")
local actions= require("fzf-lua").actions

fzf_lua.setup({
    winopts = { 
        width  = 0.99,
        height = 0.80,
    },
    fzf_colors= {
        true,
    },
    files = {
        actions = {
            ["enter"]   = actions.file_edit,
        },
    },
})



--Listar archivos del proyecto, Seleccionar/Examinar e Ir
--nnoremap <silent> <leader>ll :Files<CR>
vim.keymap.set('n', '<leader>ll', ':lua require("fzf-lua").files({ cwd_prompt = false })<CR>', { noremap = true, silent = true })

--Listar archivos del 'Git Files', Seleccionar/Examinar e Ir
--nnoremap <silent> <leader>lg :GFiles<CR>
vim.keymap.set('n', '<leader>lg', ':lua require("fzf-lua").git_files()<CR>', { noremap = true, silent = true })

--Listar archivos del 'Git Status Files', Seleccionar/Examinar e Ir
--nnoremap <silent> <leader>ls :GFiles?<CR>
vim.keymap.set('n', '<leader>ls', ':lua require("fzf-lua").git_status()<CR>', { noremap = true, silent = true })

--Listar comandos VIM, seleccionar y ejecutar
--nnoremap <silent> <leader>lc :History:<CR>
vim.keymap.set('n', '<leader>lc', ':lua require("fzf-lua").commands()<CR>', { noremap = true, silent = true })

--Listar las marcas (marks), seleccionar e ir
--nnoremap <silent> <leader>mm :Marks<CR>
vim.keymap.set('n', '<leader>mm', ':lua require("fzf-lua").marks()<CR>', { noremap = true, silent = true })

--Listar los saltos (jumps), seleccionar e ir
--nnoremap <silent> <leader>jj :Jumps<CR>
vim.keymap.set('n', '<leader>jj', ':lua require("fzf-lua").jumps()<CR>', { noremap = true, silent = true })

--Listar los tags (generados por ctags) del proyecto ('ctags -R'), seleccionar e ir
--nnoremap <silent> <leader>tt :Tags<CR>
vim.keymap.set('n', '<leader>tt', ':lua require("fzf-lua").tags()<CR>', { noremap = true, silent = true })

--Listar los tags (generados por ctags) del buffer actual, seleccionar e ir
--nnoremap <silent> <leader>tb :BTags<CR>
vim.keymap.set('n', '<leader>tb', ':lua require("fzf-lua").btags()<CR>', { noremap = true, silent = true })

--Listar, Selexionar/Examinar e Ir al buffer
--nnoremap <silent> <leader>bb :Buffers<CR>
vim.keymap.set('n', '<leader>bb', ':lua require("fzf-lua").buffers()<CR>', { noremap = true, silent = true })

--Busqueda de archivos del proyecto usando busqueda difuso 'ripgrep'.
--nnoremap <silent> <leader>ff :Rg<CR>
vim.keymap.set('n', '<leader>ff', ':lua require("fzf-lua").grep_project()<CR>', { noremap = true, silent = true })




--Remplazar el "vim.ui.select" por defecto de NeoVIM
fzf_lua.register_ui_select()


