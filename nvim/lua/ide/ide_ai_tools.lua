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


-- No se implementara una Agente AI como 'Avante' ni se integrara a un agente externo como 'OpenCode'.
