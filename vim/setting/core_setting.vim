"###################################################################################
" Settings - Core
"###################################################################################

"----------------------------- Calcular de Variables  ------------------------------

"Tipos de sistemas operativos
"  0 - Windows
"  1 - MacOS
"  2 - Linux
"  3 - WSL
"
if !exists("g:os_type")
    if has("win64") || has("win32") || has("win16")
        "Es Windows
        let g:os_type = 0
    else
        let s:kernelsys = system("uname -s")
        let s:kernelrel = system("uname -r")

        if (s:kernelsys =~ "Linux*") && (stridx(s:kernelrel,"WSL") > 0)
            "Es Linux WSL
            let g:os_type = 3
        elseif s:kernelsys =~ "Darwin*"
            "Es MacOS
            let g:os_type = 1
        else
            "Es Linux
            let g:os_type = 2
        endif
    endif
endif

"Determinar si VIM corre en modo GUI o en el modo consola:
" > En Linux y MacOS, se usa otro archivo de configuracion para este proceso
" > En Windows se reusa el mismo archivo de configuracion para la versio GUI y la consola
if has("gui_running")
    let g:is_gui_vim = 1
else
    let g:is_gui_vim = 0
endif

"Cacular si NeoVim
if has('nvim')
    let g:is_neovim = 1
else
    let g:is_neovim = 0
endif

"Si esta compilado para soporte a Python3 (soporta plugins hechos en python)
if has('python3')
    let g:has_python3 = 1
else
    let g:has_python3 = 0
endif

"Si esta compilado para soporte Clipboard del sistema operativo
if has('clipboard')
    let g:has_clipboard = 1
else
    let g:has_clipboard = 0
endif

"Determinar si se usa TMUX
if (g:os_type != 0) && exists('$TMUX') 
    let g:use_tmux = 1
else
    let g:use_tmux = 0
endif

"Determinar automaticamente si esta configurado como IDE
"let g:use_ide = 1

if g:use_ide && $USE_EDITOR != ""
    "Para no remover la carpeta de 'ftplugin' del runtimepath en VIM instalado para
    "en cada 'file type' se validara esta variable antes de que se carge.
    let g:use_ide = 0
endif

"Path del home del usuario (siempre se usara como separador de carpetas es '/')
"Si es Windows
if g:os_type == 0
    let g:home_path=substitute($USERPROFILE,"\\","/","g")
else
    let g:home_path=$HOME
endif

"Calcular variables que solo se usan en un IDE
if g:use_ide

    "Si es NeoVim, el IDE puede usar CoC o el LSP interno
    "  > Usar '~/.config/nvim/ftplugin' solo para 'file types' comunes para el IDE CoC/No-CoC
    "  > Usar '~/.config/nvim/runtime_coc/ftplugin' solo para 'file types' del IDE CoC
    "  > Usar '~/.config/nvim/runtime_nococ/ftplugin' solo para 'file types' del IDE No-CoC
    if g:is_neovim
        if $USE_COC != ""
            let g:use_coc_in_nvim = 1
            let &runtimepath.=',' .. g:home_path .. '/.config/nvim/runtime_coc'
        else
            let g:use_coc_in_nvim = 0
            let &runtimepath.=',' .. g:home_path .. '/.config/nvim/runtime_nococ'        
         endif
    endif
	
endif

"----------------------------- Validar los requisitos ------------------------------

"Si es VIM y no tiene tiene instalado python3, no soporta Snippets
"Si es VIM y no tiene instalado nodejs, no soporta CoC

"----------------------------- Opciones del Encoding   -----------------------------
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set ttyfast
set fileformats=unix,dos,mac

"Habilitar el key <backspace> en modo edicion
set backspace=indent,eol,start

"Convertir el key <tab> en 3 espacio en blancos
set tabstop=4
set shiftwidth=4
set softtabstop=0
set expandtab


"Enable hidden buffers (permitir cerrar split que sean el unico que muestre un buffer modificado)
set hidden

"----------------------------- Opciones de busqueda   ------------------------------
"Sombrear la coincidiencias
set hlsearch
"Busqueda incremental
set incsearch
"Busqueda ignora las maysucualas y minusculas, excepto ...
set ignorecase
"Excepto se tenga al menos una letra en mayuscula
set smartcase


"----------------------------- Apariencia : Color     ------------------------------
syntax on

set background=dark
"Permite que las parte final de la linea sin texto no tenga un color del fondo diferente
set t_ut=

"Color de terminal de 24 bits ('True Colors'). Windows >= 10.1809 recien lo soportan. 
"Los servidores linux por defecto trabaja con 'ANSI 256 Color', pero generalmente las terminales modernas traducen el color 16bits a 24 bits para mostrar el color sin problemas.
"Si su terminal no traduce bien los 16 bits de color que envia su servidor, COMENTE esta linea y habilite 'set t_Co=256'
set termguicolors

"Color de la terminal 'ANSI 256 Colors' (16 bits). Descomentar en Linux que se ven mal su terminal, en Windows >= 11 siempre debe estar comentado.
"set t_Co=256

"Establcer el tipo de terminal (pseudoterminal o pty)
if (g:os_type == 0) && !g:is_neovim
"if g:os_type == 0
    "Si es Windows >= 10.1809, usar 'Windows Pseudo Console' (ConPTY)
	set termwintype=conpty
    "Si es Windows <  10.1809, usar 'Windows Pseudo terminal' (WinPTY)
	"set termwintype=winpty
endif

"Configuracion de la terminal que se puede abrir en VIM
" > Personalizar los 16 colores usados por defecto por toda terminal
"    00  Black        08  Bright Black (Gray)
"    01  Red          09  Bright Red
"    02  Green        10  Bright Green
"    03  Yellow       11  Bright Yellow
"    04  Blue         12  Bright Blue
"    05  Magenta      13  Bright Magenta
"    06  Cyan         14  Bright Cyan
"    07  White        15  Bright White
if g:is_neovim
  let g:terminal_color_0 = '#104040'
  let g:terminal_color_1 = '#D84A33'
  let g:terminal_color_2 = '#5DA602'
  let g:terminal_color_3 = '#EEBB6E'
  let g:terminal_color_4 = '#417AB3'
  let g:terminal_color_5 = '#9F4E85'
  let g:terminal_color_6 = '#7DD6CF'
  let g:terminal_color_7 = '#DBDED8'
  let g:terminal_color_8 = '#685656'
  let g:terminal_color_9 = '#D76B42'
  let g:terminal_color_10 = '#99B52C'
  let g:terminal_color_11 = '#FFB670'
  let g:terminal_color_12 = '#6C99BB'
  let g:terminal_color_13 = '#9F4E85'
  let g:terminal_color_14 = '#7DD6CF'
  let g:terminal_color_15 = '#E4D5C7'
else
  let g:terminal_ansi_colors = ['#104040', '#D84A33', '#5DA602', '#EEBB6E', '#417AB3', '#9F4E85', '#7DD6CF', '#DBDED8', '#685656', '#D76B42', '#99B52C', '#FFB670', '#6C99BB', '#9F4E85', '#7DD6CF', '#E4D5C7']
endif

" > Colores del sistema o propios del terminal
"highlight Terminal guibg='#040404' guifg='#EBEBEB' ctermbg='#040404' ctermfg='#EBEBEB'
"highlight Terminal guibg=#040404 guifg=#EBEBEB

"----------------------------- Apareciencia : Otros   ------------------------------
set ruler
set relativenumber
"set number
"let no_buffers_menu=1

"Resaltar linea actual (current line highlighting)
set cursorline

"Resaltar columna actual (COMENTAR: Activala a demanda debido a que afecta la performance)
"set cursorcolumn

"Better command line completion
set wildmenu

"Mouse support: Permite la selección usando el mouse
set mouse=a
"Mouse support:
set mousemodel=popup


"Disable the blinking cursor.
"set guicursor=a:blinkon0

"Cuando se mueve entre paginas del buffer, siempre trata colocar la linea actual, 'n'
"lineas por abajo/arriba de la primera/ultima linea de la pagina a moverse
"set scrolloff=3

"Use modeline overrides
set modeline
set modelines=10

"Activa la detecion del tipo de archivo
filetype on
"Cuando se detecta el tipo de archivo se carga su contralador de './ftplugin/'
filetype plugin on
"Cuando se detecta el tipo de archivo se carga su contralador de './indent/'
filetype indent on

"----------------------------- Defualt Shell           -----------------------------
"Usado para ejecutar 'system('cmd')' o usando ':!cmd'. No usado para terminales
"Windows
if g:os_type == 0

    "El plugin de FZF no tiene soporte a pwsh, se corrigio manualmente para ello
    set shell=pwsh
    "set shell=powershell
    
    "Neovim no tiene soporte completo a diferentes interpretes shell que no sea el nativo (Para Windows, usa el 'cmd')
    "Para dar soporte a Powershell requiere tambien configurar
    if g:is_neovim
        let &shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
        let &shellredir = '-RedirectStandardOutput %s -NoNewWindow -Wait'
        let &shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
        set shellquote =  
        set shellxquote = 
    endif
"Linux incluyendo WSL
elseif (g:os_type == 2) || (g:os_type ==3)

    if exists('$SHELL')
        set shell=$SHELL
    else
        set shell=/bin/sh
    endif

endif 


"----------------------------- Clipboard de SO         -----------------------------

"Uso de los registros vinculados al portapales del SO
"Solo WSL
if g:os_type == 3

    "Copia cualquier yank que esta en el registro " (por defecto) se copia al portapales del SO
    augroup Yank
    autocmd!
    autocmd TextYankPost * :call system('/mnt/c/windows/system32/clip.exe ',@")
    augroup END

elseif g:has_clipboard
"elseif g:has_clipboard || g:is_gui_vim

    "Usar como registro predeterminado a '*' vinculado al portapales principal del SO 
    "En Linux, se usa el portapales 'CLIPBOARD' del servidor X11
    "Para copiar selecione y use "CTRL + c", para pegar use "CTRL + v"
    set clipboard=unnamed

    ""Solo Linux
    "if g:os_type == 2
    "    "Usar como registro predeterminado a '+' (que apunta al portapales 'PRIMARY' del servidor X11)
    "    "Para copiar el al portapales solo selecione el texto, 
    "    "Para pegar del portapales use el boton central o boton secundario o 'SHFIT + INSERT'
    "    "Se esta usando esto en Linux porque es mas facil usar y mas eficiente en recursos
    "    set clipboard=unnamedplus
    ""No es Linux o WSL
    "else        
    "    "Usar como registro predeterminado a '*' vinculado al portapales principal del SO 
    "    "En Linux, se usa el portapales 'CLIPBOARD' del servidor X11
    "    "Para copiar selecione y use "CTRL + c", para pegar use "CTRL + v"
    "    set clipboard=unnamed
    "endif

endif 


"Solo para Windows y MAC (Linux usa gVim la cual tiene su propio archivo ".gvimrc")
if g:is_gui_vim
    set guioptions=egmrti
    set gfn=Cousine\ Nerd\ Font\ Mono:h10
endif


"------------------------------- TabLine y StatusLine    ----------------------------
"Mostrar siempre StatusLine (barra de estado): 0 (ocultar), 1 (solo si existe 1 buffer) 
set laststatus=2

"Mostrar siempre TabLine (barra de buffer y tab): 0 (ocultar), 1 (solo si existe 1 buffer)
if g:use_tabline 
    set showtabline=2
else
    set showtabline=0
endif

"Habilitar un titulo en la barra de estado
set title
"Establecer como titulo de la barra de estado el nombre del archivo
set titleold="Terminal"
set titlestring=%F

"Establecer el estado de la barra de estado
set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)\

if exists("*fugitive#statusline")
    set statusline+=%{fugitive#statusline()}
endif

"----------------------------- Completado               ----------------------------
"El completado de VIM se realiza usando diferentes fuentes de completado:
"    - Palabras existentes en el buffer actual
"    - Palabras enviados por un servidor de lenguajes LSP
"    - Ruta del sistema operativo
"    - etc.
"Varios plugins de completado implementan la fuente 'omni-complete', pero algunos como CoC
"no usan esta fuente e implementan una fuente personalizada por usuario.

"Configuraciones del completado en modo insercion de VIM
if g:is_neovim
    "Neovim aun no soporta 'popuphidden' or 'popup'    
    set completeopt=menu,menuone,noinsert,preview
    "set completeopt=menu,menuone,noselect
else
    "Si se tiene soporte a Popup
    if v:version > 802
        "Completado en modo insercion: 
        set completeopt=menu,menuone,noinsert,popuphidden,preview
        "set completeopt=menuone,noinsert,noselect,popuphidden

        "Para mayor legibilidad usar el mismo resaltado que es usado popup del menu 
        set completepopup=highlight:Pmenu,border:off
    else
        "Completado en modo insercion: 
        set completeopt=menu,menuone,noinsert,preview
    endif
endif

"----------------------------- Configuraciones de CoC   ----------------------------

if g:use_ide && (!g:is_neovim || g:use_coc_in_nvim)

    "Some servers have issues with backup files
    "set nobackup
    "set nowritebackup

    "Reducir el tiempo de updatetime para mejorar la experiencia de usuario (timeout por defecto 4000 = 4s)
    set updatetime=300
    "Mostrar la columna para el diganostico (NO usar, lo hara ALE no CoC)
    "set signcolumn=yes

endif




