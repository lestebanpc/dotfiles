"###################################################################################
" UI> Configuraciones exclusivas de NeoVim
"###################################################################################
"
" > Se activara treesitter (incluyendo su resaltado de sintaxis).
" > Se activara el completado automático a nivel 'command line'.
"
if g:is_neovim

    "Package> Permite integrar imagenes externas dentro de NeoVIM
    packadd img-clip.nvim

    "Package> Visualizar un markdown en un browser
    packadd markdown-preview.nvim

    "Configuraciones de los plugins exclusivas
    lua require('basic.basic_desktop')

    "No continuar
    finish

endif
