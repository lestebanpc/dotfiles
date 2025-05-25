--Si no esta habilitado AI, no continuar.
if vim.g.use_ai_plugins == false then
    return
end


--------------------------------------------------------------------------------------------------
-- IA> Copilot (IA Autocompletion for Software Development)
--------------------------------------------------------------------------------------------------

require("copilot").setup({
    filetypes = vim.g.completion_filetypes,
    suggestion = {
        enabled = false,
    },
    panel = {
        enabled = false,
    },
})

vim.keymap.set('n', '<leader>cc', function()
        if require("copilot.client").is_disabled() then

            require("copilot.command").enable()

            -- Mostrar el mensaje el command line temporalmente
            print("Copilot completion is enabled")

        else

            require("copilot.command").disable()

            -- Mostrar el mensaje el command line temporalmente
            print("Copilot completion is disabled")

        end
    end, { noremap=true, silent=false, desc = 'Toggle AI Copilot Completion' })



------------------------------------------------------------------------------------------------
-- UI NeoVim> Dressing
------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------
-- UI NeoVim> NUI
------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------
-- UI> render-markdown
------------------------------------------------------------------------------------------------

require('render-markdown').setup({
    file_types = { 'markdown', 'Avante' },
})

------------------------------------------------------------------------------------------------
-- UI> img-clip
------------------------------------------------------------------------------------------------

require("img-clip").setup({
    -- recommended settings
    default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        drag_and_drop = {
            insert_mode = true,
        },
         -- required for Windows users
        use_absolute_path = true,
    },
})


--------------------------------------------------------------------------------------------------
-- IA> Avante (IA Agent/Chat for Software Development)
--------------------------------------------------------------------------------------------------

require("avante").setup({
    provider = "copilot",
    auto_suggestions_provider = 'copilot',

    -- Desabilitar el 'inlay hints' (por defecto esta activado)
    -- > Deja de mostrar 'virtual text' cuando seleciona un texto, indicando los acciones posibles.
    hints = { enabled = false },


    behaviour = {
        auto_suggestions = false, -- Experimental stage
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = false,
        minimize_diff = true, -- Whether to remove unchanged lines when applying a code block
        enable_token_counting = true, -- Whether to enable token counting. Default to true.
        enable_cursor_planning_mode = false, -- Whether to enable Cursor Planning Mode. Default to false.
    },


    copilot = {
        endpoint = 'https://api.githubcopilot.com/',
        model = 'claude-3.5-sonnet',
        proxy = nil, -- [protocol://]host[:port] Use this proxy
        allow_insecure = false, -- Do not allow insecure server connections
        timeout = 30000, -- Timeout in milliseconds
        temperature = 0.1, -- kinda creative
        max_tokens = 8192,
    },
})

-- Toggle el AI chat
--vim.keymap.set('n', '<leader>cr', ':AvanteClear<CR>', { noremap = true, silent = true })
