"###################################################################################
" IDE > Typing> Emmet-Vim (Generador de elementos HTML)
"###################################################################################

if get(g:use_typing_plugins, 'html_emmet', v:false)

    "Plugin IDE> Crear elementos HTML por comandos
    packadd emmet-vim

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
" IDE > Typing> Vim-Surround (Cierra texto usando bracket (),[],{})
"###################################################################################


if get(g:use_typing_plugins, 'surround', v:false)

    "Plugin IDE> Encerrar/Modificar con (), {}, [] un texto
    packadd vim-surround

endif



"###################################################################################
" IDE> Typing> Vim-Visual-Multi (Crear y modificar una seleccion multiple)
"###################################################################################

if get(g:use_typing_plugins, 'visual_multi', v:false)

    "Plugin IDE> Selector multiple de texto
    packadd vim-visual-multi

endif



"###################################################################################
" IDE> Configuracion exclusivas para NeoVim
"###################################################################################
"
if g:is_neovim

    "Plugin IDE> Librerias basicas
    packadd plenary.nvim

    "Configuracion de los plugin exclusivos
    lua require('ide.ide_utils')

endif
