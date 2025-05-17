"###################################################################################
" UI> Temas y sus schema colors
"###################################################################################

let g:main_theme = ''

if g:is_neovim

    "Plugin UI> Tema 'Tokyo Night'
    "packadd tokyonight.nvim
    "let g:main_theme = 'tokyonight'

    "Esquema de color del tema: Se define dentro de 'ui_basic.lua'
    "colorscheme tokyonight-night



    "Plugin UI> Tema 'Catppuccin'
    packadd nvim
    let g:main_theme = 'catppuccin'

    "Esquema de color del tema: Se define dentro de 'ui_basic.lua'
    "colorscheme catppuccin-macchiato
    "colorscheme catppuccin-mocha


else


    "Plugin UI> Tema Gruvbox
    "packadd gruvbox

    "Esquema de color del tema
    "colorscheme gruvbox
    "set background=dark
    "let g:main_theme = 'gruvbox'




    "Plugin UI> Tema Onedark
    packadd onedark.vim

    "Personalizar el schema
    "Donde por tipo de color se tiene los siguientes campos:
    " - 'gui'     : is the hex color code used in GUI mode/nvim true-color mode
    " - 'cterm'   : is the color code used in 256-color mode
    " - 'cterm16' : is the color code used in 16-color mode
    let g:onedark_color_overrides = {
    \ "background": {"gui": "#0f0f0f", "cterm": "233", "cterm16": "0" }
    \}

    "Esquema de color del tema
    colorscheme onedark
    let g:main_theme = 'onedark'



endif


"###################################################################################
" UI> Configuraciones exclusivas de NeoVim
"###################################################################################

if g:is_neovim

    "Plugin UI> Iconos
    packadd nvim-web-devicons

    "Plugin UI> Barra de estado o 'SatusLine'
    packadd lualine.nvim

    "Plugin UI> Barra de buffers/tabs (TabLine)
    packadd bufferline.nvim


    "Plug UI> Explorador de archivos
    packadd nvim-tree.lua

    "Inicializar los plugins UI
    lua require('basic.basic_core')

    "No continuar
    finish

endif


"###################################################################################
" UI> StatusLine y TabLine
"###################################################################################


"Plugin UI> Barra de estado AirLine (incluye 'SatusLine' y 'TabLine')
"Segun la documentación oficial, se deben cargarse antes de 'Vim-DevIcons'.
packadd vim-airline
packadd vim-airline-themes

"Tema a usar por AirLine
let g:airline_theme = g:main_theme
"let g:airline_theme = 'powerlineish'

"Mostrar la rama GIT
let g:airline#extensions#branch#enabled = 1

"Mostrar informacion de ALE
let g:airline#extensions#ale#enabled = 1

"Mostrar el Tabline (buffer y tabs)
let g:airline#extensions#tabline#enabled = 1

let g:airline#extensions#virtualenv#enabled = 1
let g:airline#extensions#tagbar#enabled = 1
let g:airline_skip_empty_sections = 1

"Solo para fuentes que no son 'Porwerline'. En este caso se usara fuente 'NerdFonts'
"la cual incluye caracteres 'Powerline' pero en distinto orden/codigo
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

let g:airline#extensions#tabline#left_sep = ''
let g:airline#extensions#tabline#left_alt_sep = ''

let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''

let g:airline_symbols.branch = ''
"let g:airline_symbols.branch = ''
"let g:airline_symbols.readonly = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''




"###################################################################################
" UI> Iconos > Vim-DevIcons
"###################################################################################


"Plugin UI> Iconos para NERDTree y AirLine
packadd vim-devicons

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



"###################################################################################
" UI> File Explorer> NerdTree
"###################################################################################
"
"Segun la documentación oficial, se deben cargarse antes de 'Vim-DevIcons',
"pero si se hace ello no se muestra los Iconos
"https://github.com/ryanoasis/vim-devicons/issues/428

"Plugin UI> Explorador de archivos.
packadd nerdtree


let g:NERDTreeChDirMode=2
"let g:NERDTreeIgnore=['node_modules','\.rbc$', '\~$', '\.pyc$', '\.db$', '\.sqlite$', '__pycache__']
"let g:NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$', '\.bak$', '\~$']
let g:NERDTreeShowBookmarks=1
let g:NERDTreeMapOpenInTabSilent = '<RightMouse>'
let g:NERDTreeWinSize = 50
"set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,*.db,*.sqlite,*node_modules/

"nnoremap <leader><C-f> :NERDTreeFind<CR>
nnoremap <leader>ee :NERDTreeToggle<CR>
