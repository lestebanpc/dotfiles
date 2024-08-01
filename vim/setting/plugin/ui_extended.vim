"###################################################################################
" Settings> UI> File Explorer> Package: Vim-DevIcons
"###################################################################################

if g:is_neovim
    
    "Configurar el explorador de archivos ('nvim-tree'):
    lua require('ui.extended')

else

    "Configurar el explorador de archivos:
    let g:WebDevIconsUnicodeDecorateFileNodesDefaultSymbol='x'

    "NERDTree : Adding the flags to NERDTree
    let g:webdevicons_enable_nerdtree = 1

    "NERDTree : whether or not to show the nerdtree brackets around flags
    let g:webdevicons_conceal_nerdtree_brackets = 1

    "NERDTree : Personalizar los folderes para abrir y cerrar
    let g:WebDevIconsUnicodeDecorateFolderNodes = 1

    "Symbol for open folder (f07c)
    let g:DevIconsEnableFoldersOpenClose = 1
    let g:DevIconsDefaultFolderOpenSymbol=''
    "Symbol for closed folder (f07b)
    let g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol='' 

    "Adding to vim-airline's tabline
    let g:webdevicons_enable_airline_tabline = 1

    "Adding to vim-airline's statusline
    let g:webdevicons_enable_airline_statusline = 1

    "Permiter refrescar el tree, del re-sourcing del .vimrc
    if exists("g:loaded_webdevicons")
        call webdevicons#refresh()
    endif

endif

"###################################################################################
" Settings> UI> Search Files> Plug-In: FZF (FuZzy Finder)
"###################################################################################

"Sobreescribir las opciones por defecto de FZF (VIM define muchas opciones usando
"variables globales). 
let $FZF_DEFAULT_OPTS="--layout=reverse --info=inline"

"El comando por defecto de FZF sera 'fd' y no 'find' debido a que:
"  - 'fd' excluye de la busqueda folderes y archivos, y lo indicado por '.gitignore'.
"  - La opcion '--walker-skip' aun no permite excluir archivos solo carpetas.
"Adicionalmente :
"  > Solo incluir archivos '-t f' o '--type f'
"  > Incluir los archivos ocultos '-H' o '--hidden'
"  > Excluir de la busqueda '-E' o '--exclue'
"    > La carpetas de git                        : '.git' 
"    > Paquetes ('binario' del Node.JS) locales  : 'node_modules'
"    > Archivo de Swap o temporales de VIM       : '.swp'
"    > Archivo de 'persistence undo' de VIM      : '.un~'
let $FZF_DEFAULT_COMMAND="fd -H -t f -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"

"Layout de FZF, define el tamaño y posicion del popup, usando la variable global 'g:fzf_layout'
if g:use_tmux
	"Si se usa TMUX, usar el 'tmux popup', definiendo el valor de la opcion '--tmux'
    "Su valor es la misma que la opcion: [center|top|bottom|left|right][,SIZE[%]][,SIZE[%]]
    let g:fzf_layout = { 'tmux': '99%,80%' }
else
    "Si no se usa TMUX, definir el valor de las opciones '--height', '--width' y '--border'.
    "Campos obligatorios:
    " - 'width'    : float range [0 ~ 1] or integer range [8 ~ ]
    " - 'height'   : float range [0 ~ 1] or integer range [4 ~ ]
    "Campos opcionales:
    " - 'xoffset'  : float default 0.5 range [0 ~ 1]
    " - 'yoffset'  : float default 0.5 range [0 ~ 1]
    " - 'relative' : boolean (default v:false)
    " - 'border'   : Border style (default is 'rounded')
    "                Values : rounded, sharp, horizontal, vertical, top, bottom, left, right
    " - 'highlight': Comment, Identifier 
    if g:is_neovim
        "let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.9, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'highlight': 'Identifier', 'border': 'rounded' } }
        "let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.99, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'border': 'rounded' } }
        let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.99, 'height': 0.8 } }
    else
        let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.99, 'height': 0.8 } }
        "let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.99, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'border': 'rounded' } }
        "let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.9, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'highlight': 'Identifier', 'border': 'rounded' } }
    endif

endif

"Soporte a color 24 bits (RGB)
"Permite traducir color 'ANSI 256 color' (muchos de los temas de VIM usa este tipo de color) a su equivalente a 24 bits (RGB)
let g:fzf_force_24_bit_colors = 1

"Color de FZF, usando la variable global 'g:fzf_colors'.
"La variable global define la opcion '--color' de FZF.
"Los campos a definir se usaran:
"   fg, bg, hl                Item (foreground / background / highlight)
"   fg+, bg+, hl+             Current item (foreground / background / highlight)
"   preview-fg, preview-bg    Preview window text and background
"   hl, hl+                   Highlighted substrings (normal / current)
"   gutter                    Background of the gutter on the left
"   pointer                   Pointer to the current line (>)
"   marker                    Multi-select marker (>)
"   border                    Border around the window (--border and --preview)
"   header                    Header (--header or --header-lines)
"   info                      Info line (match counters)
"   spinner                   Streaming input indicator
"   query                     Query string
"   disabled                  Query string when search is disabled
"   prompt                    Prompt before query (> )
"   pointer                   Pointer to the current line (>)
"Se usaran los colores del tema de VIM para definir el color
let g:fzf_colors =
\ { 'fg':         ['fg', 'Normal'],
  \ 'bg':         ['bg', 'Normal'],
  \ 'preview-bg': ['bg', 'NormalFloat'],
  \ 'hl':         ['fg', 'Comment'],
  \ 'fg+':        ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':        ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':        ['fg', 'Statement'],
  \ 'info':       ['fg', 'PreProc'],
  \ 'border':     ['fg', 'Ignore'],
  \ 'prompt':     ['fg', 'Conditional'],
  \ 'pointer':    ['fg', 'Exception'],
  \ 'marker':     ['fg', 'Keyword'],
  \ 'spinner':    ['fg', 'Label'],
  \ 'header':     ['fg', 'Comment'] }

"Listar archivos del proyecto, Seleccionar/Examinar e Ir
nnoremap <silent> <leader>ll :Files<CR>
"Listar archivos del 'Git Files', Seleccionar/Examinar e Ir
nnoremap <silent> <leader>lg :GFiles<CR>
"Listar archivos del 'Git Status Files', Seleccionar/Examinar e Ir
nnoremap <silent> <leader>ls :GFiles?<CR>
"Listar comandos VIM, seleccionar y ejecutar
nnoremap <silent> <leader>cc :History:<CR>
"Listar las marcas (marks), seleccionar e ir
nnoremap <silent> <leader>mm :Marks<CR>
"Listar los saltos (jumps), seleccionar e ir
nnoremap <silent> <leader>jj :Jumps<CR>
"Listar los tags (generados por ctags) del proyecto ('ctags -R'), seleccionar e ir
nnoremap <silent> <leader>tt :Tags<CR>
"Listar los tags (generados por ctags) del buffer actual, seleccionar e ir
nnoremap <silent> <leader>tb :BTags<CR>

"Listar, Selexionar/Examinar e Ir al buffer
nnoremap <silent> <leader>bb :Buffers<CR>

"Busqueda de archivos del proyecto usando busqueda difuso 'Ag'.
nnoremap <silent> <leader>fa :Ag<CR>
"Busqueda de archivos del proyecto usando busqueda difuso 'Rg'.
nnoremap <silent> <leader>fr :Rg<CR>


"###################################################################################
" Settings> UI> File Explorer> Package: NerdTree
"###################################################################################

if !g:is_neovim

    let g:NERDTreeChDirMode=2
    "let g:NERDTreeIgnore=['node_modules','\.rbc$', '\~$', '\.pyc$', '\.db$', '\.sqlite$', '__pycache__']
    "let g:NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$', '\.bak$', '\~$']
    let g:NERDTreeShowBookmarks=1
    let g:NERDTreeMapOpenInTabSilent = '<RightMouse>'
    let g:NERDTreeWinSize = 50
    "set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,*.db,*.sqlite,*node_modules/

    "nnoremap <leader><C-f> :NERDTreeFind<CR>
    nnoremap <leader>ee :NERDTreeToggle<CR>

endif


