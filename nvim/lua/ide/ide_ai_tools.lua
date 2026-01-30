--------------------------------------------------------------------------------------------------
-- Tool> IA> Copilot (IA Autocompletion for Software Development)
--------------------------------------------------------------------------------------------------

-- Fuente de completado de un LLM (local o externo) o un broker LLM
if vim.g.use_ai_completion ~= vim.NIL then

    -- Si para el completado se usa el broker LLM 'GitHub Copilot'
    if vim.g.use_ai_completion == 0 then

        require("copilot").setup({
            filetypes = vim.g.completion_filetypes,
            suggestion = {
                enabled = false,
            },
            panel = {
                enabled = false,
            },
        })

        vim.keymap.set('n', '<leader>ac', function()
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


    -- Si para el completado se usa el LLM (local y externo) y/o broker LLM
    elseif vim.g.use_ai_completion == 1 then

        --TODO Adiconar el soporte al LLM, adicionar el keybinding de habilitar el completado
        --https://github.com/milanglacier/minuet-ai.nvim?tab=readme-ov-file
        require('minuet').setup()

    end

end



-- TODO Actualmente hay muchos plugins de utilidad que se activan solo por el agente ¿se puede reutilizar?
-- Si se usan un agente de AI integrado al IDE o se usan una integración a un agente de AI externo (usualmente un 'CLI AI Agent')
if vim.g.use_ai_agent ~= vim.NIL then

    -- Si se usa un agente de AI integrado al IDE (Avente)
    if vim.g.use_ai_agent == 0 then

        ------------------------------------------------------------------------------------------------
        -- UI NeoVim> Dressing
        ------------------------------------------------------------------------------------------------


        ------------------------------------------------------------------------------------------------
        -- UI NeoVim> NUI
        ------------------------------------------------------------------------------------------------



        --------------------------------------------------------------------------------------------------
        -- Tool> IA> Avante (IA Agent/Chat for Software Development)
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

            providers = {
                copilot = {
                    endpoint = 'https://api.githubcopilot.com/',
                    model = 'claude-3.5-sonnet',
                    proxy = nil, -- [protocol://]host[:port] Use this proxy
                    allow_insecure = false, -- Do not allow insecure server connections
                    extra_request_body = {
                        timeout = 30000, -- Timeout in milliseconds
                        temperature = 0.1, -- kinda creative
                        --max_tokens = 8192,
                    },
                },
            },

            web_search_engine = {
                -- tavily, serpapi, searchapi, google, kagi, brave, or searxng
                provider = "tavily",
                -- proxy support, e.g., http://127.0.0.1:7890
                proxy = nil,
            },
        })

        -- Toggle el AI chat
        --vim.keymap.set('n', '<leader>cr', ':AvanteClear<CR>', { noremap = true, silent = true })


    -- Si integre a; agente de programacion de AI 'OpenCode'
    elseif vim.g.use_ai_agent == 1 then

        --TODO https://github.com/NickvanDyke/opencode.nvim
        require("opencode").setup()

        --vim.g.opencode_opts = {}
        --vim.opt.autoread = true

        --vim.keymap.set({ "n", "x" }, "<leader>oa", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask about this" })
        --vim.keymap.set({ "n", "x" }, "<leader>o+", function() require("opencode").prompt("@this") end, { desc = "Add this" })
        --vim.keymap.set({ "n", "x" }, "<leader>os", function() require("opencode").select() end, { desc = "Select prompt" })

    end

end
