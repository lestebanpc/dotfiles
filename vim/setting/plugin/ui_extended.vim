"###################################################################################
" PSettings> UI> File Explorer> Package: Vim-DevIcons
"###################################################################################

"ONLY VIM : Neovim usa otro tipo de plugins
if !g:is_neovim

    "xxx
    let g:WebDevIconsUnicodeDecorateFileNodesDefaultSymbol='x'

    "NERDTree : Adding the flags to NERDTree
    let g:webdevicons_enable_nerdtree = 1

    "NERDTree : whether or not to show the nerdtree brackets around flags
    let g:webdevicons_conceal_nerdtree_brackets = 1

    "NERDTree : Personalizar los folderes para abrir y cerrar
    let g:WebDevIconsUnicodeDecorateFolderNodes = 1
    let g:DevIconsEnableFoldersOpenClose = 1

    let g:DevIconsDefaultFolderOpenSymbol='' " symbol for open folder (f07c)
    let g:WebDevIconsUnicodeDecorateFolderNodesDefaultSymbol='' " symbol for closed folder (f07b)

    "Adding to vim-airline's tabline
    let g:webdevicons_enable_airline_tabline = 1

    "Adding to vim-airline's statusline
    let g:webdevicons_enable_airline_statusline = 1
endif

"###################################################################################
" Settings> UI> Search Files> Plug-In: FZF (FuZzy Finder")
"###################################################################################

let $FZF_DEFAULT_OPTS="--layout=reverse --info=inline"

"Layout 
"  > Border : rounded, sharp, horizontal, vertical, top, bottom, left, right
"  > Highlight: Comment, Identifier 
if g:is_neovim
    let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.8, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'highlight': 'Identifier', 'border': 'rounded' } }
else
    let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.8, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'border': 'rounded' } }
    "let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.8, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'highlight': 'Identifier', 'border': 'rounded' } }
endif

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


nnoremap <silent> <leader>f :Files<CR>
nnoremap <silent> <leader>b :Buffers<CR>
nnoremap <silent> <leader>sa :Ag<CR>
nnoremap <silent> <leader>sr :Rg<CR>
nnoremap <leader>c :History:<CR>
"cnoremap <C-P> <C-R>=expand("%:p:h") . "/" <CR>
"Recovery commands from history through FZF

"###################################################################################
" PSettings> UI> File Explorer> Package: NerdTree
"###################################################################################


let g:NERDTreeChDirMode=2
"let g:NERDTreeIgnore=['node_modules','\.rbc$', '\~$', '\.pyc$', '\.db$', '\.sqlite$', '__pycache__']
"let g:NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$', '\.bak$', '\~$']
let g:NERDTreeShowBookmarks=1
let g:NERDTreeMapOpenInTabSilent = '<RightMouse>'
let g:NERDTreeWinSize = 50
"set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,*.db,*.sqlite,*node_modules/

"nnoremap <leader><C-f> :NERDTreeFind<CR>
nnoremap <leader><C-n> :NERDTreeToggle<CR>


