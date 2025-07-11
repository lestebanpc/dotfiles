"###################################################################################
" Tools> For Git
"###################################################################################
"

" Para NeoVim
if g:is_neovim

    "Tools> Show signs for GIT stangin area changes
    "      Muestra signs de los cambios del staging area
    "      Muesta infromacion del ultimo commit realizado para la linea de codigo ('git blame')
    packadd gitsigns.nvim

    "Tools> Merge Tool y File History for Git
    packadd diffview.nvim

endif

"###################################################################################
" Tools> Rest Client
"###################################################################################
"

" Para NeoVim
if g:is_neovim

    "Package IDE> Client Rest 'Kulala'
    "Si se usa CoC, no funcionara el autocomletado si no se configura un cio para su cliente LSP
    packadd  kulala.nvim

endif


"###################################################################################
" Tools> AI Autocomplete
"###################################################################################
"
" > URL
"   > Copilot.vim
"       > https://github.com/github/copilot.vim
"       > https://github.com/github/copilot.vim/blob/release/plugin/copilot.vim
" > Para 'AI Autocompletion' se usara la capacidade de autocompletado de 'GitHub Copilot' y estara por
"   defecto desabilitado.
"   > Para habilitarlo use ':Copilot enable'
"   > Para CoC (VIM/NeoVIM), se usara 'github/copilot.vim' y el plugin de CoC '@hexuhua/coc-copilot'.
"   > Para NeoVIM y no usas CoC, se usara 'zbirenbaum/copilot.lua'.
"

" Si es CoC, se usara 'github/copilot.vim'
if g:use_ai_plugins

    if g:use_coc

        "Tools> AI Completion
        packadd copilot.vim

        "Deshabilitar el keymapping por defecto generado
        let g:copilot_no_maps = v:true
        let g:copilot_no_tab_map = v:true

        "Estableder el keymapping para aceptar el autocompletado
        "imap <silent><script><expr> <C-J> copilot#Accept("\<CR>")

        "Por defecto se desabilita la sugerencias (autocompletado)  AI, cuando VIM termino de cargarse.

        "Para habilitarlo cuando se use ':Copilot enable'
        autocmd VimEnter * Copilot disable

        " En la documentación oficial no existe esta variable, pero en el codigo es usado.
        " > URL : https://github.com/orgs/community/discussions/57887
        "let g:copilot_enabled

        "Usar los filetypes definidos para el autocompletado por AI
        let g:copilot_filetypes = g:completion_filetypes

    endif


    " Se usa NeoVim sin CoC, se usara 'zbirenbaum/copilot.lua'
    if g:is_neovim && !g:use_coc

        "Tools> AI Completion
        packadd copilot.lua

        "Por defecto se desabilita la sugerencias (autocompletado)  AI, cuando VIM termino de cargarse.
        "Para habilitarlo cuando se use ':Copilot enable' o el keymapping '<Leder>cc'
        autocmd VimEnter * Copilot disable

    endif

endif

"###################################################################################
" Tools> AI Chat, AI Agents
"###################################################################################
"
" > Para 'AI Agent' se usara Avente, usando la API ofrecido por 'GitHub Copilot'.
"

" Para NeoVim
if g:is_neovim

    "Tools> Plugin requeridos para AI Chat, AI Agents
    if g:use_ai_plugins

        packadd avante.nvim
        packadd dressing.nvim
        packadd nui.nvim
        packadd render-markdown.nvim
        packadd img-clip.nvim

    endif

    lua require('ide.ide_extended')

    "Solo continuar si es VIM
    finish

endif

" Para VIM
