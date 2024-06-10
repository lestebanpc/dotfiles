"###################################################################################
" Settings> UI> File Explorer> Package: Vim-DevIcons
"###################################################################################

if g:is_neovim
    
    "Configurar el explorador de archivos ('nvim-tree'):
    lua require('native.ui.extended')

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

let $FZF_DEFAULT_OPTS="--layout=reverse --info=inline"

"Usar el comando 'fd' y no 'find' debido a que excluye de la busqueda lo especificado por '.gitignore'.
"Debido '--walker-skip' no permite excluir archivos, se usara aun 'fd'.
"Adicionalmente :
"  > Solo incluir archivos '-t f' o '--type f'
"  > Incluir los archivos ocultos '-H' o '--hidden'
"  > Excluir de la busqueda '-E' o '--exclue'
"    > La carpetas de git                        : '.git' 
"    > Paquetes ('binario' del Node.JS) locales  : 'node_modules'
"    > Archivo de Swap o temporales de VIM       : '.swp'
"    > Archivo de 'persistence undo' de VIM      : '.un~'
let $FZF_DEFAULT_COMMAND="fd -H -t f -E '.git' -E 'node_modules' -E '*.swp' -E '*.un~'"

"Layout 
"  > Border : rounded, sharp, horizontal, vertical, top, bottom, left, right
"  > Highlight: Comment, Identifier 

"Se dejo de Usar 'tmux popup' (tmux floating window) debido a que usa el color de fondo de la terminal
"if g:use_tmux
"    let g:fzf_layout = { 'tmux': '-p90%,80%' }
"else

if g:is_neovim
    let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.9, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'highlight': 'Identifier', 'border': 'rounded' } }
else
    let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.9, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'border': 'rounded' } }
    "let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.9, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'highlight': 'Identifier', 'border': 'rounded' } }
endif

"endif

"Color : Permitir que se traduzca los temas de VIM de 'ANSI 256 color' a 24 bits (RGB Hex)
let g:fzf_force_24_bit_colors = 1

"Color de popup de fzf, segun el tema usado en VIM
"
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
"
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
nnoremap <silent> <leader>lc :History:<CR>

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


