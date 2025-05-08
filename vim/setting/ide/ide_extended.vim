
"###################################################################################
" IDE> AI Autocomplete
"###################################################################################
"


if g:use_ai_plugins == v:true

    "Pacakege IDE> Core> AI Completition
    packadd copilot.vim

    "Cambiar el <Tab> por <Ctrl + Enter> para aceptar el autocompletado
    imap <silent><script><expr> <C-J> copilot#Accept("\<CR>")
    let g:copilot_no_tab_map = v:true

    "Por defecto se desabilita copilot.
    "Se habilitara cuando se use ':Copilot enable' o ':let g:copilot_enabled = 1'
    "let g:copilot_enabled = 0

    "let g:copilot_filetypes = {
    "\   '*': v:false,
    "\   'lua': v:false,
    "\   'vimscript': v:false,
    "\   'javascript': v:true,
    "\   'typescript': v:true,
    "\   'bash': v:false,
    "\   'c': v:true,
    "\   'c++': v:true,
    "\   'c#': v:true,
    "\   'go': v:true,
    "\   'rust': v:true,
    "\   'python': v:true,
    "\  }


endif


"###################################################################################
" IDE> AI Chat y AI Agents
"###################################################################################
"

" Para NeoVim
if g:is_neovim

    if g:use_ai_plugins == v:true

        "Pacakege IDE> AI Chat, AI Agents
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
