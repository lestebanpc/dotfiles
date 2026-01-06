"###################################################################################
" Tools> AI Autocomplete
"###################################################################################
"
" > Por el momento solo soportado para NeoVIM y usando el LSP nativo.
" > Para 'AI Autocompletion' se configurara como una fuente de completado de NeoVIM.
" > Según el valor definido por la variable VIM 'g:use_ai_completion'
"     > 0 si usara el broker LLM de 'GitHub Copilot' usando el plugin 'zbirenbaum/copilot.lua'.
"     > 1 si usara un LLM (local o externo) o un broker LLM soportado por el plugin 'milanglacier/minuet-ai.nvim'.
"     > Cualquier otro valor se considera no definido. Si se no se definide, no se usara ningun plugin de 'AI autocompletion'.
" > Si usa como fuente de completado al broker LLM 'GitHub Copilot':
"   > Por defecto esta desabilitado.
"   > Para habilitarlo use ':Copilot enable'
"   > Se usara el plugin 'zbirenbaum/copilot.lua'.
"

" Si es NeoVIM y no usa CoC y ha definido usar 'AI completion'
if g:is_neovim && !g:use_coc && g:use_ai_completion isnot v:null

    " Se usa el broker LLM 'GitHub Copilot' (se usa el plugin 'zbirenbaum/copilot.lua')
    if g:use_ai_completion == 0

        "Tools> AI Completion
        packadd copilot.lua

        "Por defecto se desabilita la sugerencias (autocompletado)  AI, cuando VIM termino de cargarse.
        "Para habilitarlo cuando se use ':Copilot enable' o el keymapping '<Leder>cc'
        autocmd VimEnter * Copilot disable

    " Se usa un LLM (local o externo) o un broker LLM
    elseif g:use_ai_completion == 1

        packadd minuet-ai.nvim

    endif

endif


"###################################################################################
" Tools> AI Agent
"###################################################################################
"
" > Actualmente solo se habilitará el plugin de 'AI Agent' para NeoVIM si usa LSP nativo.
" > Se puede usar un agente integrado dentro del editor y integrarse a un agente externo usualmente de tipo CLI.
" > El tipo de agente, que se se usara se obtendra segun orden de prioridad:
"   > El valor definido por la variable VIM 'g:use_ai_agent':
"     > 0 Si usara un 'AI agent' integrado con NeoVIM usando el plugin 'yetone/avante.nvim'.
"       > Siempre estara desactivado su capacidad de 'AI autocomplete' debido a que no se integra como fuente de autocompletado.
"       > Por el momento, la configuracion actual de este plugin esta configurado para usar el broker 'GitHub Copilot'.
"     > 1 Si integra con 'AI agent' externo en este caso un 'CLI AI agent' conocido como 'OpenCode'
"       > Se usara el plugin 'NickvanDyke/opencode.nvim'.
"     > Cualquier otro valor se considera no definido. Si se no esta definido, no se usara ningun plugin de agente AI.
"

" Si es NeoVIM y no usa CoC y ha definido usar 'AI completion'
if g:is_neovim && !g:use_coc && g:use_ai_agent isnot v:null

    " Si se usa el agente de AI integrado ('yetone/avente.nvim')
    if g:use_ai_agent == 0

        packadd avante.nvim
        packadd dressing.nvim
        packadd nui.nvim
        packadd render-markdown.nvim
        packadd img-clip.nvim

    " Si usa integra con un agente de AI 'OpenCode'
    elseif g:use_ai_agent == 1

        packadd opencode.nvim

    endif

endif


" Para VIM
if g:is_neovim

    lua require('ide.ide_ai_tools')

    "Solo continuar si es VIM
    finish

endif
