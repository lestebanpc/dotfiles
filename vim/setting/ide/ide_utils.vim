"###################################################################################
" IDE > Typing> Emmet-Vim (Generador de elementos HTML)
"###################################################################################

if g:use_typing_html_emmet

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


if g:use_typing_surround

    "Plugin IDE> Encerrar/Modificar con (), {}, [] un texto
    packadd vim-surround
endif



"###################################################################################
" IDE> Typing> Vim-Visual-Multi (Crear y modificar una seleccion multiple)
"###################################################################################

if g:use_typing_visual_multi

    "Plugin IDE> Selector multiple de texto
    packadd vim-visual-multi

endif




"###################################################################################
" IDE> Soporte a Universal CTags
"###################################################################################

"Plugin IDE> Soporte a Universal CTags
"packadd vim-gutentags

"let g:gutentags_trace = 1
"let g:gutentags_ctags_extra_args = ['--tag-relative=always', ]

"let g:gutentags_generate_on_empty_buffer = 1

"let g:gutentags_exclude_filetypes= []

"let g:gutentags_ctags_exclude = [
"\   '.git',
"\   'build',
"\   'dist',
"\   'node_modules',
"\   '.venv',
"\   '*swp', '*json', '*yaml', '*toml', '*md', '*css'
"\]



"###################################################################################
" IDE> Configuracion exclusivas para NeoVim
"###################################################################################
"
if g:is_neovim

    "Plugin IDE> Librerias basicas
    packadd plenary.nvim
    
    "Plugin IDE> Resaltador de sintexis o semantica
    packadd nvim-treesitter

    "Configuracion de los plugin exclusivos
    lua require('ide.ide_utils')

endif



