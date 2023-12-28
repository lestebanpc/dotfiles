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

vim.keymap.set('n', '<leader>ee', '<cmd>NvimTreeToggle<cr>')


------------------------------------------------------------------------------------------------
-- Package UI> EXTENDED> Telescope
------------------------------------------------------------------------------------------------

--require('telescope').setup({})

--Usando key-mapping usando Comando ':Telescope'
vim.keymap.set('n', '<leader>tf', '<cmd>Telescope find_files<cr>')
vim.keymap.set('n', '<leader>tb', '<cmd>Telescope buffers<cr>')
--vim.keymap.set('n', '<leader>?', '<cmd>Telescope oldfiles<cr>')
--vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')

--Usando key-mapping usando la funciones de Telescope
--local builtin = require('telescope.builtin')
--vim.keymap.set('n', '<leader>tf', builtin.find_files, {})
--vim.keymap.set('n', '<leader>tb', builtin.buffers, {})
--vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
--vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})



