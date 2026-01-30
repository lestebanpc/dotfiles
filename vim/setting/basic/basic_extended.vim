"###################################################################################
" UI> Sintax Highlighting (Resaltado de Sintaxis)
"###################################################################################

" Habilitar el resaltado de sintaxis nativo de VIM
" > En NeoVim, si tiene activo plugin de treesitter para el filetype, por el resaltado de sintaxis nativo
"   de VIM se desactivara para el buffer y se usara el ofrecido por el treesitter.
syntax on



"###################################################################################
" UI> Configuraciones exclusivas de NeoVim
"###################################################################################
"
" > Se activara treesitter (incluyendo su resaltado de sintaxis).
" > Se activara el completado automático a nivel 'command line'.
"
if g:is_neovim

    "Plugin IDE> Implementacion del arbol sinstanctico de TreeSitter para NeoVim
    packadd nvim-treesitter

    "Plugin IDE> Modulos a usar del plugin 'nvim-treeSitter'
    packadd nvim-treesitter-textobjects


    "Package Core> CMP (Framework de autocompletado)
    packadd nvim-cmp

    "Package Core> Fuente CMP: Buffer (Sugiere palabras que se encuentra en el archivo actual)
    packadd cmp-buffer

    "Package Core> Fuente CMP: FileSystem Path
    packadd cmp-path

    "Package Core> Fuente CMP: Command Line
    packadd cmp-cmdline

    "Package Core> Render Markdown
    packadd render-markdown.nvim

    "Configuraciones de los plugins exclusivas
    lua require('basic.basic_extended')

    "No continuar
    finish

endif


"###################################################################################
" Completion> Autocompletion de la linea de comandos
"###################################################################################
"
" URL : https://github.com/girishji/vimsuggest
"       https://github.com/girishji/vimsuggest/blob/main/doc/vimsuggest.txt
"

if g:cmdline_completion

    packadd vimsuggest

    " Command Completion Configuration
    let s:vim_suggest = {}
    let s:vim_suggest.cmd = {
        \ 'enable': v:true,
        \ 'pum': v:true,
        \ 'exclude': [],
        \ 'onspace': ['b\%[uffer]','colo\%[rscheme]'],
        \ 'alwayson': v:true,
        \ 'popupattrs': {},
        \ 'wildignore': v:true,
        \ 'addons': v:true,
        \ 'trigger': 't',
        \ 'reverse': v:false,
        \ 'prefixlen': 2,
        \ 'complete_sg': v:false,
    \ }

    " Search Completion Configuration
    let s:vim_suggest.search = {
        \ 'enable': v:true,
        \ 'pum': v:true,
        \ 'fuzzy': v:false,
        \ 'alwayson': v:true,
        \ 'popupattrs': {
        \   'maxheight': 12
        \ },
        \ 'range': 100,
        \ 'timeout': 200,
        \ 'async': v:true,
        \ 'async_timeout': 3000,
        \ 'async_minlines': 1000,
        \ 'highlight': v:true,
        \ 'trigger': 't',
        \ 'prefixlen': 3,
    \ }

    " To apply your configuration
    call g:VimSuggestSetOptions(s:vim_suggest)

endif
