"###################################################################################
" Settings> IDE > Typing> Package: Emmet-Vim (Generador de elementos HTML)
"###################################################################################

if g:use_typing_html_emmet
    "Enable just for html/css
    let g:user_emmet_install_global = 0
    autocmd FileType html,css EmmetInstall
    
    "Only enable normal mode functions.
    "let g:user_emmet_mode='n'
    
    "Enable all functions, which is equal to
    "let g:user_emmet_mode='inv'

    "Enable all function in all mode.
    "let g:user_emmet_mode='a'
    
    "To remap the default key leader '<C-Y>' a 'C-Z':
    "let g:user_emmet_leader_key='<C-Z>'
endif

"###################################################################################
" Settings> IDE > Typing> Package: Vim-Surround (Cierra texto usando bracket (),[],{})
"###################################################################################



"###################################################################################
" Settings> IDE> Typing> Package: Vim-Visual-Multi (Crear y modificar una seleccion multiple)
"###################################################################################


