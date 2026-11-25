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

    if exists('*wildtrigger')

        " Activa el popup para mostrar coincidencias
        set wildmenu

        " Opciones del popup
        set wildoptions=pum,fuzzy

        " Opciones de modo del popup
        " > No seleccionar automáticamente el primer resultado.
        " > Ordenar buffers por último uso. Navegar por todas las coincidencias.
        set wildmode=noselect:lastused,full

        " Altura máxima del popup
        set pumheight=12

        " Ignorar mayúsculas/minúsculas al completar nombres de archivos
        set wildignorecase

        " Activar autocompletado mientras se escribe:
        " : comandos
        " / búsquedas hacia adelante
        " ? búsquedas hacia atrás
        augroup acmd_cmdline_completion
            autocmd!
            autocmd CmdlineChanged [:\/\?] call wildtrigger()
        augroup END

        " Cerrar el popup y mantener la navegación del historial de comandos usando flechas
        "cnoremap <expr> <Up> wildmenumode()
        "            \ ? "\<C-E>\<Up>" : "\<Up>"

        "cnoremap <expr> <Down> wildmenumode()
        "            \ ? "\<C-E>\<Down>" : "\<Down>"

    endif

endif
