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


" Para VIM
if g:is_neovim

    lua require('ide.ide_additional_tools')

    "Solo continuar si es VIM
    finish

endif
