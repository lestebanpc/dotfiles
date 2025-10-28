"-----------------------------------------------------------------------------------
" Calcular de Variables
"-----------------------------------------------------------------------------------
"
"Tipos de sistemas operativos
"  0 - Windows
"  1 - MacOS
"  2 - Linux no-WSL
"  3 - Linux WSL
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
    let s:is_gui_vim = v:true
else
    let s:is_gui_vim = v:false
endif

"Cacular si NeoVim
if has('nvim')
    let g:is_neovim = v:true
else
    let g:is_neovim = v:false
endif

"Si esta compilado para soporte a Python3 (soporta plugins hechos en python)
if has('python3')
    let g:has_python3 = v:true
else
    let g:has_python3 = v:false
endif

"Si esta compilado tiene nativo para poder escribir en el clipboard del SO. En NeoVIM, siempre es 1 (v:true).
if has('clipboard')
    let s:has_clipboard = v:true
else
    let s:has_clipboard = v:false
endif

"Determinar si se usa TMUX
"if (g:os_type != 0) && exists('$TMUX') && executable('tmux')
if (g:os_type != 0) && exists('$TMUX')
    let g:use_tmux = v:true
else
    let g:use_tmux = v:false
endif


"Path del home del usuario
if g:os_type == 0
    "Si es Windows, siempre se usara como separador de carpetas es '/'
    let g:home_path=substitute($USERPROFILE,"\\","/","g")
else
    let g:home_path=$HOME
endif

"Si esta en modo IDE y es Neovim, establecer un nuevo path en el 'Runtime Path'
"  > La variable de entorno 'USE_COC' pueden tener los siguientes valores:
"     1 > Se usa (va instalar o tiene instalado) CoC como IDE
"     0 y otro valor > No se usara CoC como IDE
if g:use_ide

    if g:is_neovim

        "Si es NeoVim, el IDE puede usar CoC o el LSP interno
        "  > Usar '~/.config/nvim/ftplugin' solo para 'file types' comunes para el IDE CoC/No-CoC
        "  > Usar '~/.config/nvim/rte_cocide/ftplugin' solo para 'file types' del IDE CoC
        "  > Usar '~/.config/nvim/rte_nativeide/ftplugin' solo para 'file types' del IDE No-CoC
        if g:use_coc
            let &runtimepath.=',' .. g:home_path .. '/.config/nvim/rte_cocide'
        else
            let &runtimepath.=',' .. g:home_path .. '/.config/nvim/rte_nativeide'
        endif

    else
        " Corregir cualquier valor incorrecto (VIM en modo IDE solo es con CoC)
        let g:use_coc = v:true
    endif

endif


"-----------------------------------------------------------------------------------
" Validar los requisitos
"-----------------------------------------------------------------------------------
"
"Si es VIM y no tiene tiene instalado python3, no soporta Snippets
"Si es VIM y no tiene instalado nodejs, no soporta CoC



"-----------------------------------------------------------------------------------
" Opciones basicas
"-----------------------------------------------------------------------------------
"
"1. Mostrar siempre la barra de pesatañas (tabLine):
"   (0) Ocultar,
"   (1) Solo si existe 1 buffer
"   (2) Siempre mostrar
set showtabline=2


"2. Mostrar siempre StatusLine (barra/linea de estado):
"   (0) Ocultar
"   (1) Solo si existe 1 buffer
"   (2) Siempre mostrar
"   (3) La barra de estado global y unica para todos los splits (solo Neovim).
if g:is_neovim
    set laststatus=3
else
    set laststatus=2
endif


"3. Formato estandar del statusline (barra/linea de estado)

" - Muestra la regla en la liena de estado. Ubicado en esquina inferior derecha y muestra:
"   - nro linea,
"   - nro de columna,
"   - % del archivo
"set ruler


"4. Formato personalizado del statusline (la barra/linea de estado)
"set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)\

"if exists("*fugitive#statusline")
"    set statusline+=%{fugitive#statusline()}
"endif


"5. Numero de la linea
set relativenumber
"set number


"6. Habilitar los hidden buffers (buffer que tiene cambios y no se muestran en ningun split)
set hidden


"7. Convertir el key <tab> en espacio en blancos

set expandtab

" - Tamaño del <tab> en forma visual
set tabstop=4

" - Tamaño del <tab> en forma real
"   - Si es 0 y 'expandtab' esta desactivado, siempre se guardara el tab
"   - Si es 0 y 'expandtab' esta activo, el tamaño real del <tab> es lo indicado por 'tabstop'
set softtabstop=0

" - Tamano del tab en la indentacion usando '>>' o '<<'
set shiftwidth=4



"8. Establecer el titulo en la barra de terminal (cuando VIM esta ejecutandose)
"   TMUX sobrescribe el titulo de la barra de estado.
if !g:use_tmux

    set title

    "set titleold="Terminal"

    "Personaliza lo que se muestra el titulo de la barra de titulo del menú
    " - Nuestra la ruta completa del archivo
    set titlestring=%F

endif


"9. Habilitar el key <backspace> en modo edicion
set backspace=indent,eol,start



"-----------------------------------------------------------------------------------
" Opciones adicionales
"-----------------------------------------------------------------------------------
"

"1. Opciones de busqueda

" - Sombrear la coincidiencias
set hlsearch

" - Busqueda incremental
set incsearch

" - Busqueda ignora las maysucualas y minusculas, excepto ...
set ignorecase

" - Excepto se tenga al menos una letra en mayuscula
set smartcase



"2. Opciones de encoding

" Codificación interna de Vim (recomendado UTF-8)
set encoding=utf-8

" Lista para la detección automática del 'fileencoding' cuando se abre un archivos.
" - Si no se especifica.se usara el valor definido en 'encoding'.
" - Si un archivo no tiene ninguno de estos encoding, se usara para mostrar el 'encoding' pero la opcion
"   'fileencoding' es vacio.
set fileencodings=ucs-bom,utf-8,iso-8859-1,cp1252,macroman,default

" Formato de fin de línea multiplataforma: '\n' (Unix), '\r\n' (Windows) y '\r' (macOS Classic).
set fileformats=unix,dos,mac



"3. Soporte del mouse

" - Habilitar la selección usando el mouse
"   (n)     Habilita el ratón en modo normal.
"   (v)     Habilita el ratón en modo visual.
"   (i)     Habilita el ratón en modo insert.
"   (c)     Habilita el ratón en el modo de comandos.
"   (h)     Habilita el ratón en el modo de ayuda (:help).
"   (a)     Habilita el ratón en todos los modos.
"   (r)     Habilita el ratón en modos terminal y prompt.
"   (vacío)	Desactiva el uso del ratón.
set mouse=a

" - Controla cómo se interpretan los clics del ratón
"   (extend) Valor por defecto
"     - Shift + Left click   Expande la selección (similar a seleccionar texto en modo visual).
"     - Rigth click          Abre un menú contextual en GUI (si está disponible).
"   (popup)
"     - Rigth click          Abre un menú contextual en GUI.
"     - Shift + Left click   Se comporta igual que un clic normal.
"   (popup_setpos)
"     - Right Click          Abre un menú contextual y mueve el cursor a la posición del clic.
"     - Shift + Left clic    Igual que un clic normal.
set mousemodel=popup

"4. Soporte de controladores (sintaxis, indentación y plugins) segun el tipo de archivo

" - Habilitar la detección automática
"   Detectar el tipo de archivo si se abre un archivo.
filetype on

" - Habilitar scripts de configuración específicos del tipo de archivo ('./ftplugin/')
"   Permite que Vim cargue configuraciones adicionales basadas en el tipo de archivo.
filetype plugin on

" - Habilitar scripts de indentación específicos ('./indent/')
"   Activa reglas de indentación específicas según el tipo de archivo.
filetype indent on


"5. Soporte a 'modeline overrides'
"   Si esta activado, se analiza lineas de comentario al inicio y al final del archivo,
"   en busqueda de configuracion para definir opciones personalizado para este archivo.
"   Formato :
"     vim: option1 option2 option3:

" - Activa el modoline
set modeline

" - Define el numero de lineas al inicio/final del archivo para buscar el comentario especial
set modelines=10


"6. Menu de opciones de autocompletado de linea de comandos
"   Actualmente no se usan, se usara el plugin de autocompletado 'girishji/vimsuggest' y 'nvim-cmp'.

" - Mejora la forma de mostrar las opciones de autocompletado de la linea de comandos.
"   Si se activa muestra una lista más visible y navegable.
set wildmenu

" - La primera vez que presionas <Tab>, se complete hasta la parte más larga en común.
"   Si sigues presionando Tab, se muestren todas las opciones disponibles en una lista.
set wildmode=longest:full,full

"set wildoptions=pum


"7. Otros

" - Permite optimizar la redibujación y mejorar el rendimiento de la GUI de la terminal
"   Vim reduce la cantidad de actualizaciones parciales en la pantalla, lo que lo hace más fluido
"   en terminales rápidas.
set ttyfast

" - Resaltar linea actual (current line highlighting)
set cursorline

"Resaltar columna actual (COMENTAR: Activala a demanda debido a que afecta la performance)
"set cursorcolumn


"Disable the blinking cursor.
"set guicursor=a:blinkon0

"Cuando se mueve entre paginas del buffer, siempre trata colocar la linea actual, 'n'
"lineas por abajo/arriba de la primera/ultima linea de la pagina a moverse
"set scrolloff=3



"-----------------------------------------------------------------------------------
" Apariencia : Color
"-----------------------------------------------------------------------------------
"

set background=dark

"Permite que las parte final de la linea sin texto no tenga un color del fondo diferente
set t_ut=

"Color de terminal de 24 bits ('True Colors'). Windows >= 10.1809 recien lo soportan.
"Los servidores linux por defecto trabaja con 'ANSI 256 Color', pero generalmente las terminales modernas traducen
"el color 16bits a 24 bits para mostrar el color sin problemas.
"Si su terminal no traduce bien los 16 bits de color que envia su servidor, COMENTE esta linea y habilite 'set t_Co=256'
set termguicolors

"Soporte a 'undercurl' (undercurled text)
if g:is_neovim
    let &t_Cs = "\e[4:3m"
    let &t_Ce = "\e[4:0m"
endif

"You might have to force true color when using regular vim inside tmux as the colorscheme can appear to be grayscale
"with 'termguicolors' option enabled.
"if !g:is_neovim && !s:is_gui_vim
"    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
"    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
"endif

"Color de la terminal 'ANSI 256 Colors' (16 bits). Descomentar en Linux que se ven mal su terminal, en Windows >= 11
"siempre debe estar comentado.
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



"-----------------------------------------------------------------------------------
" Defualt Shell
"-----------------------------------------------------------------------------------
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
elseif (g:os_type == 2) || (g:os_type == 3)

    if exists('$SHELL')
        set shell=$SHELL
    else
        set shell=/bin/sh
    endif

endif



"Solo para Windows y MAC (Linux usa gVim la cual tiene su propio archivo ".gvimrc")
if s:is_gui_vim
    set guioptions=egmrti
    set gfn=Cousine\ Nerd\ Font\ Mono:h10
endif



"-----------------------------------------------------------------------------------
" Complete en insert mode
"-----------------------------------------------------------------------------------
"
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
    set completeopt=menu,menuone,noselect,noselect
    "set completeopt=menu,menuone,noinsert,preview
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



"-----------------------------------------------------------------------------------
" Configuraciones de CoC
"-----------------------------------------------------------------------------------
"
if g:use_ide && (!g:is_neovim || g:use_coc)

    "Some servers have issues with backup files
    "set nobackup
    "set nowritebackup

    "Reducir el tiempo de updatetime para mejorar la experiencia de usuario (timeout por defecto 4000 = 4s)
    set updatetime=300
    "Mostrar la columna para el diganostico (NO usar, lo hara ALE no CoC)
    "set signcolumn=yes

endif



"-----------------------------------------------------------------------------------
" Mappings - General
"-----------------------------------------------------------------------------------
"
"Usando como Key Leader
let mapleader=','

"Usando como Key Local Leader: '\', '[SPACE]'
let maplocalleader = "\\"
"let maplocalleader = "\<Space>"

"Search mappings: These will make it so that going to the next one in a search will center on the line it's found in.
nnoremap n nzzzv
nnoremap N Nzzzv



"-----------------------------------------------------------------------------------
" Clipboard > Calcular las variables interas requeridas
"-----------------------------------------------------------------------------------
"
"Uso de 'ctrl+C' para enviar texto al portapapeles y 'ctrl+V' para obtener texto del portapapeles:
" > Cuando (el panel actual de) la terminal no está ejecutando un comando, las terminales procesan estas
"   teclas y acceden al clipboard:
"   > Ante cualquier texto seleccionado (ya sea con el ratón o con otros atajos de teclado), usando 'ctr+C',
"     la puede capturar el terminal y enviarla al clipboard del SO (donde está la terminal).
"     > Algunas  terminales permiten el copiado automático ante cualquier texto seleccionado a la terminal,
"       solo requiere seleccionar y esto ya se copia en la terminal.
"     > Esta opción permite enviar al portapapeles cual texto del STDOUT generado por el comando (después
"       de su ejecución).
"     > Cuando este en la línea de ejecución del prompt  actual de la terminal, puede usar 'ctrl+V' para
"       obtener el texto del portapapeles y pegarlo después del prompt actual.
" > Cuando (el panel actual de) la terminal está ejecutando un comando, las terminales la terminales reenvias
"   las teclas al comando de ejecución:
"   > Cuando se usa 'ctrl+V', es la terminal la que obtiene el texto del portapapeles y reenvía el texto al STDIN
"     del comando de ejecución (le programa nunca procesa las teclas, solo el texto).
"   > Algunos comandos, como 'vim', 'nvim', 'tmux', 'ssh', …. implementan un logica de hacer frente a cuando se
"     colocan texto a dicho programa.
"   > Cuando se usa 'ctrl+C', este se envía al programa, pero muchos comandos una accion para gestionar el
"     portapapeles, debido a que acoplan la lógica del comando con el API de gestión de portapapeles del SO.
"     VIM/Neovim no implementan logica de pegado al portapapeles con esta key.
"


"Establecer el mecanismo de escritura en el clipboard del SO (define acciones VIM y escritura automatica en el blipboard
"cuando se realiza un yank). Definido por la variiable VIM 'g:clipboard_writer_mode' cuyos valores son:
"  1 > Implementar un mecanismo de escritura del clipboard usando OSC-52.
"  2 > Implementar un mecanismo de escritura del clipboard usando comandos externos de gestion de clipboard.
"  9 > No se puedo implementar mecanismos es escritura.

" Si no se especifica, se debe calcular automaticamente el modo de escritura al clipboard
if g:clipboard_writer_mode != 1 && g:clipboard_writer_mode != 2

    "1. Intentar determinar si la terminal soporta OSC 52
    "   > Parte de la logica 'setting_clipboard()' definida en './shell/bash/fun/tmux/fun_general.bash'.
    "   > La 1ra prioridad de uso del mecanismo del clipboard es OSC 52.
    let s:terminal_use_osc54 = v:false

    "Si esta ejecutando sobre tmux
    if g:use_tmux

        "Si usa el archivo de configuracion './tmux/tmux.conf', se establece la variable de entorno 'TMUX_SET_CLIPBOARD'
        "con valor 1 o 2, si se configurado tmux con soporte a OSC 52
        if ($TMUX_SET_CLIPBOARD == 1) || ($TMUX_SET_CLIPBOARD == 2)
        "if $TMUX_SET_CLIPBOARD == 1
            let s:terminal_use_osc54 = v:true
        endif

    "Si esta ejecutando directamente sobre la terminal.
    else

        "Los siguientes emuladores definen por defecto la variable de entorno 'TERM_PROGRAM'
        if ($TERM_PROGRAM == 'WezTerm') || ($TERM_PROGRAM == 'contour') || ($TERM_PROGRAM == 'iTerm.app')

            let s:terminal_use_osc54 = v:true

        "Los siguientes emuladores debera definir la variable 'TERM_PROGRAM' con este valor en su archivo de configuracion:
        elseif ($TERM_PROGRAM == 'foot') || ($TERM_PROGRAM == 'kitty') || ($TERM_PROGRAM == 'alacritty')

            let s:terminal_use_osc54 = v:true

        "Opcionalmente, aunque no se recomienta usar un TERM personalizado (no estan en todos los equipos que accede
        "por SSH), algunas terminales definen un TERM personalizado (aunque por campatibilidad, puede modificarlo).
        else
            if ($TERM == 'xterm-kitty') || ($TERM == 'alacritty') || ($TERM == 'foot')
                let s:terminal_use_osc54 = v:true
            endif
        endif

    endif


    "2. Determinar el mecanismo de escritura del clipboard a usar:
    if g:is_neovim

        " Determinar el mecanismo de escritura del clipboard a usar, segun orden de prioridad
        "  > Implementar el mecanismo OSC 52.
        "    > Se definira la variable 'g:clipboard' para definirlo como prioridad.
        "  > Usar mecanismo nativo (SOC y comandos externos) si esta habilitado. Segun prioridad.
        "    > El proveedor definido en 'g:clipboard' (no aplicara para nuestro caso).
        "    > Usando un proveedor (backend externo):
        "      > MacOS: pbcopy / pbpaste
        "      > Linux con Wayland: wl-copy / wl-paste, waycopy / waypaste
        "    > Usando OSC 52
        "    > Si es Linux X11, usa proveedor: usa libreria 'libxcb' y 'libX11'.
        "    > Si es Windows y esta compilado con la opcion '+clipboard', utiliza el API de Win32.
        if s:terminal_use_osc54
            let g:clipboard_writer_mode = 1
        else
            let g:clipboard_writer_mode = 2
        endif

    else

        " Determinar automaticamente el mecanismo correcto segun order de prioridad:
        "  > Implementar el mecanismo OSC 52, si la terminal lo permite.
        "  > Usar mecanismo nativo (API del SO) si esta habilitado.
        "  > Implementar el mecanismo de uso comandos externo del gestion de clipboard
        "  > Si no existe comando externo, se implementara el mecanismo OSC 52
        if s:terminal_use_osc54
            let g:clipboard_writer_mode = 1
        else
            let g:clipboard_writer_mode = 2
        endif

    endif

endif

"Determinar si existe el backend para escribir en el clipboard
if !exists("g:clipboard_writer_cmd")

    let g:clipboard_writer_cmd = ''

    if g:clipboard_writer_mode == 2

        "Si es Linux no-WSL
        if g:os_type == 2

            if exists('$WAYLAND_DISPLAY')

                if executable('wl-copy')
                    let g:clipboard_writer_cmd='wl-copy'
                endif

            elseif exists('$DISPLAY')

                if executable('xclip')

                    let g:clipboard_writer_cmd='xclip -i -selection clipboard'

                elseif executable('xclip')

                    let g:clipboard_writer_cmd='xsel -i -b'

                endif

            endif

        "Si es Linux WSL (sobre Windows). Siempre debe usarse el clipboard de Windows, debido a que el emulador de terminal
        "siempre sera un programa windows que accedera a dicho clipboard y WSL2 no implementa un clipboard.
        elseif g:os_type == 3

            if executable('/mnt/c/windows/system32/clip.exe')
                let g:clipboard_writer_cmd='/mnt/c/windows/system32/clip.exe'
            endif

        "Si es Windows
        elseif g:os_type == 0

            if executable('clip.exe')
                let g:clipboard_writer_cmd='clip.exe'
            endif

        "Si es MacOS
        elseif g:os_type == 1

            if executable('pbcopy')
                let g:clipboard_writer_cmd='pbcopy'
            endif

        endif

        "Si no existe el comando: ¿forzar el uso de OSC-52?
        if g:clipboard_writer_cmd == ''
            "let g:clipboard_writer_mode = 1
            let g:clipboard_writer_mode = 9
        endif

    endif

endif

"Determinar si existe el backend para escribir en el clipboard
if !exists("g:clipboard_reader_cmd")

    let g:clipboard_reader_cmd = ''

    if g:os_type == 2

        "Si es Linux no-WSL
        if exists('$WAYLAND_DISPLAY')

            if executable('wl-paste')
                let g:clipboard_reader_cmd='wl-paste'
            endif

        elseif exists('$DISPLAY')

            if executable('xclip')

                let g:clipboard_reader_cmd='xclip -o -selection clipboard'

            elseif executable('xclip')

                let g:clipboard_reader_cmd='xsel --clipboard --output'

            endif

        endif

    elseif g:os_type == 3

        "Si es Linux WSL (sobre Windows). Siempre debe usarse el clipboard de Windows, debido a que el emulador de terminal
        "siempre sera un programa windows que accedera a dicho clipboard y WSL2 no implementa un clipboard.
        "/mnt/c/Program Files/PowerShell/7/pwsh.exe.
        if executable('pwsh.exe')
            let g:clipboard_reader_cmd='pwsh.exe -NoProfile -Command "Get-Clipboard"'
        endif

    elseif g:os_type == 0

        "Si es Windows
        if executable('pwsh.exe')
            let g:clipboard_reader_cmd='pwsh.exe -NoProfile -Command "Get-Clipboard"'
        endif

    elseif g:os_type == 1

        "Si es MacOS
        if executable('pbpaste')
            let g:clipboard_reader_cmd='pbpaste'
        endif

    endif

endif

"Solo sera usado cuando 'g:clipboard_writer_mode' es '1' y puede tener los siguientes posibles valores:
"    0 > Formato OSC 52 estandar que es enviado directmente una terminal que NO use como '$TERM' a GNU screen.
"    1 > Formato OSC52 es dividio en pequeños trozos y enmascador en formato DSC, para enviarlo directmente a una terminal
"        basada en GNU ('$TERM' inicia con screen).
"    2 > Formato OSC52 se enmascara DSC enmascarado para TMUX (tmux requiere un formato determinado) y sera este el que
"        decida si este debera reenvíarse a la terminal donde corre tmux (en este caso Tmux desenmacara y lo envia).
"    Si no define o tiene otro valor, se calucara automaticamente su valor. Solo use esta opcion cuando VIM/NeoVIM se ejecuta
"    de manera local la terminal, si lo ejecuta de manera remota, por ejemplo esta dentro programa ssh o dentro de un
"    contenedor, se recomianda establecer el valor si esta dentro de tmux o de una terminal GNU '$TERM' a screen.

" Si el modo de escritura del clipboard es usando OSC-52, determinar el formato a usar.
if g:clipboard_writer_mode == 1

    " Si se debe calcular el valor automaticamente
    if g:clipboard_osc52_format != 0 && g:clipboard_osc52_format != 1 && g:clipboard_osc52_format != 2

        "Si no define o tiene otro valor, se calucara automaticamente su valor. Solo use esta opcion cuando VIM/NeoVIM
        "se ejecuta de manera local la terminal, si lo ejecuta de manera remota, por ejemplo esta dentro programa ssh
        "o dentro de un contenedor, se recomianda establecer el valor si esta dentro de tmux o de una terminal GNU '$TERM'
        "a screen.
        if g:use_tmux
            let g:clipboard_osc52_format = 2
        elseif match($TERM, 'screen') > -1
            let g:clipboard_osc52_format = 1
        else
            let g:clipboard_osc52_format = 0
        endif

    endif

endif



"-----------------------------------------------------------------------------------
" Clipboard> Cambiar el registro por defecto
"-----------------------------------------------------------------------------------
"
" > El registro por defecto es aquel:
"   - Es el registro donde todo 'yank' o 'delete'  almacena el registro, si no especifica el registro donde se almacena. 
"   - Es el registro donde todo 'put' se obtiene la data para pegar su contenido, si no especifica el registro donde se obtiene. 
" > Usaramos como registro por defecto al registro unnamed '"'.
" > Para uso del clipboard se recomienda usar el registro '+' (Windows, MacOS, Linux Wayland, Linux con X11 representa a la
"   seleccion X11 secundaria).
" > Evitaremos de usar el registro '*' (Linux con X11 representa al la seleccion X11 primaria).
" > No se cambiara el registro por a los registros del clipboar '+' ni '*'.
"

"if g:is_neovim
"
"    if s:has_clipboard
"
"        "Si es NeoVIM, siempre se usa la opción 'unnamedplus'
"        set clipboard=unnamedplus
"
"    else
"        set clipboard=
"    endif
"
"else
"
"
"    " Si se usa el mecanismo nativo de acceso al clipboard
"    if g:clipboard_writer_mode == 0
"
"        "VIM puede interactuar directamente con el clipboard del SO (usa el API del SO para ello)
"        "La instegracion con comandos externos de gestion de clipboard y OSC 52, no lo hace de forma nativa.
"        if (g:os_type == 2) || (g:os_type == 3 )
"
"            "Si VIM y es Linux
"
"            set clipboard=unnamedplus
"
"        else
"            "Si es VIM y no es Linux
"            set clipboard=unnamed
"        endif
"
"    else
"
"        "Desabilitar el menanismo nativo de escritura del clipboard
"        set clipboard=
"
"    endif
"
"endif



"-----------------------------------------------------------------------------------
" Clipboards> Escritura del clipboard
"-----------------------------------------------------------------------------------
"
" > Se implementara:
"   > Acciones de escritura al clipboard usanbdo el valor de los registros VIM.
"   > EScritura automatica al clipboard despues de realizar el yank (si esta habilitado 'g:yank_to_clipboard').
" > No se usara el menacnismo implementado por NeoVIM para tener un mejor soporte a OSC-52 con TMUX.
"
"

" Si no se tiene un mecanismo implementado
if g:clipboard_writer_mode == 9

    " No se puede establecer el mecanismo solicitado
    echo 'Not exist clipboard backend'

" Si se requiere usar OSC 52
elseif g:clipboard_writer_mode == 1

    "A. Escritura manual al clipboard del sistema
    runtime setting/utils/osc52.vim

    " Copiar el registro por defecto al clipboard (el ultimo yank o delete)
    nnoremap <Leader>cc :<C-u>call PutClipboard(g:clipboard_osc52_format, @")<CR>

    " Copiar el registro del ultimo yank al clipboard ('TextYankPost' solo se invoca interactivamente)
    nnoremap <Leader>c0 :<C-u>call PutClipboard(g:clipboard_osc52_format, @0)<CR>

    " Copiar el registro de los ultimo deletes al clipboard
    nnoremap <Leader>c1 :<C-u>call PutClipboard(g:clipboard_osc52_format, @1)<CR>
    nnoremap <Leader>c2 :<C-u>call PutClipboard(g:clipboard_osc52_format, @2)<CR>
    nnoremap <Leader>c3 :<C-u>call PutClipboard(g:clipboard_osc52_format, @3)<CR>
    nnoremap <Leader>c4 :<C-u>call PutClipboard(g:clipboard_osc52_format, @4)<CR>


    function! s:WriteToClipboard1(use_delete) abort

        "1. Yank or Delete la selección actual al registro 'z'
        "   Desde el modo normal, realiza la ultima seleccion (gv) y luego realiza la operacion en el registro '"').
        if a:use_delete
            silent normal! gv"zd
        else
            silent normal! gv"zy
        endif

        "2. Obtener el texto yankeado
        let l:txt = getreg('z')

        if empty(l:txt)
            echo "Must select some text."
            return
        endif

        "3. Limpieza

        " Eliminar salto final extra
        let l:txt = substitute(l:txt, '\n\%$', '', '')

        "4. Escribir al clipboard
        call PutClipboard(g:clipboard_osc52_format, l:txt)

        "5. Mensaje de confirmación
        "let l:lines_nbr = count(l:text, "\n") + 1
        "if a:use_delete
        "    echo printf("%d lines was %s and wrote to clipboard.", l:lines_nbr, 'deleted')
        "else
        "    echo printf("%d lines was %s and wrote to clipboard.", l:lines_nbr, 'yanked')
        "endif

    endfunction

    " En el modo visual: 'yank' el texto selecionado y escribirlo al clipboard
    vnoremap <Leader>cy :<C-u>call <SID>WriteToClipboard1(v:false)<CR>

    " En el modo visual: 'delete' el texto selecionado y escribirlo al clipboard
    vnoremap <Leader>cd :<C-u>call <SID>WriteToClipboard1(v:true)<CR>


    "B. Escritura automatica al clipboard del sistema
    if g:yank_to_clipboard

        " Escritura automatico al clipboard cuando se realiza un yank.
        " > Se descartara la operacion 'delete' para evitar su uso cuando se elimina por comandos vim.
        augroup VimYank
            autocmd!
            autocmd TextYankPost * if v:event.operator ==# 'y' | call PutClipboard(g:clipboard_osc52_format, getreg('"')) | endif
        augroup END

    endif


" Si un backend para el clipboard
else

    "A. Escritura manual al clipboard del sistema

    " Copiar el registro por defecto al clipboard (el ultimo yank o delete)
    nnoremap <Leader>cc :<C-u>call system(g:clipboard_writer_cmd, @")<CR>

    " Copiar el registro del ultimo yank al clipboard ('TextYankPost' solo se invoca interactivamente)
    nnoremap <Leader>c0 :<C-u>call system(g:clipboard_writer_cmd, @0)<CR>

    " Copiar el registro de los ultimo deletes
    nnoremap <Leader>c1 :<C-u>call system(g:clipboard_writer_cmd, @1)<CR>
    nnoremap <Leader>c2 :<C-u>call system(g:clipboard_writer_cmd, @2)<CR>
    nnoremap <Leader>c3 :<C-u>call system(g:clipboard_writer_cmd, @3)<CR>
    nnoremap <Leader>c4 :<C-u>call system(g:clipboard_writer_cmd, @4)<CR>

    function! s:WriteToClipboard2(use_delete) abort

        "1. Yank or Delete la selección actual al registro 'z'
        "   Desde el modo normal, realiza la ultima seleccion (gv) y luego realiza la operacion en el registro '"').
        if a:use_delete
            silent normal! gv"zd
        else
            silent normal! gv"zy
        endif

        "2. Obtener el texto yankeado
        let l:txt = getreg('z')

        if empty(l:txt)
            echo "Must select some text."
            return
        endif

        "3. Limpieza

        " Eliminar salto final extra
        let l:txt = substitute(l:txt, '\n\%$', '', '')

        "4. Escribir al clipboard
        call system(g:clipboard_writer_cmd, l:txt)

        if v:shell_error != 0
            if a:use_delete
                echo printf("Error to write '%s' text to clipboard.", 'deleted')
            else
                echo printf("Error to write '%s' text to clipboard.", 'yanked')
            endif

            return
        endif

        "5. Mensaje de confirmación
        let l:lines_nbr = count(l:txt, "\n") + 1
        if a:use_delete
            echo printf("%d lines was %s and wrote to clipboard.", l:lines_nbr, 'deleted')
        else
            echo printf("%d lines was %s and wrote to clipboard.", l:lines_nbr, 'yanked')
        endif

    endfunction

    " En el modo visual: 'yank' el texto selecionado y escribirlo al clipboard
    vnoremap <Leader>cy :<C-u>call <SID>WriteToClipboard2(v:false)<CR>

    " En el modo visual: 'delete' el texto selecionado y escribirlo al clipboard
    vnoremap <Leader>cd :<C-u>call <SID>WriteToClipboard2(v:true)<CR>


    "B. Escritura automatica al clipboard del sistema
    "   Si se requiere usar comandos externos de gestion de clicomandos externos de gestion de clipboardd
    if g:yank_to_clipboard


        " Escritura automatico al clipboard cuando se realiza un yank.
        " > Se descartara la operacion 'delete' para evitar su uso cuando se elimina por comandos vim.
        augroup VimYank
            autocmd!
            autocmd TextYankPost * if v:event.operator ==# 'y' | silent! call system(g:clipboard_writer_cmd, @") | endif
        augroup END

    endif


endif



"-----------------------------------------------------------------------------------
" Clipboards> Lectura del clipboard y escritura en buffer (opcional)
"-----------------------------------------------------------------------------------
"
" > La terminal implementa un keymapping de lectura de clipboard (usualmente 'Ctrl + V' o 'Ctrl + v').
"   > VIM/NeoVIM permiten que el texto enviado por la terminal se escriba automaticamente al buffer.
"   > El texto se pega como si proveniera de una seleccion caracter (despues del cursor actual).
" > Se implementara un mecanismo personalizado clipboard usando un programa backend del clipboard:
"   > Permitira pegar el texto del clipboard como si la seleccion fuera en bloques.
"   > Permitira pegar el texto del clipboard como si la seleccion fuera en linea.
" > Este mecanismo alternativo, usara el backend de clipboard local, por lo que no usara necesariamente
"   el clipboard usuado por la terminal
"

if g:clipboard_reader_cmd != ''

    " Parameters :
    " > 'use_insert_mode' : true si se usa en insert mode
    " > 'record_type' : 'c' (carácter), 'l' (línea), 'b' (bloque).
    function! s:PasteClipboardAfterCursor(use_insert_mode, record_type) abort

        if empty(a:record_type)
            let a:record_type = "c"
        endif

        "1. Obtener el texto del clipboard
        let l:txt = system(g:clipboard_reader_cmd)

        if v:shell_error != 0
            echo "Error to read text to clipboard."
            return ''
        endif


        "3. Limpieza

        " Eliminar salto final extra
        if g:os_type == 0 || g:os_type == 3
            let l:txt = substitute(l:txt, '\r', '', 'g')
        endif
        let l:txt = substitute(l:txt, '\n\+$', '', '')

        if empty(l:txt)
            echo "No text in the clipboard."
            return ''
        endif


        "4.Guardalo en el registro 'y'
        if a:record_type == "c"
            call setreg('y', l:txt)
        else

            " Obtener un arreglo con las lineas (requerido para un pegado en 'line' y 'block')
            let l:lines = split(l:txt, '\n')
            if a:record_type == "l"
                call setreg('y', l:lines, 'V')
            else

                " Calcular el ancho máximo del bloque (columna más ancha)
                let l:width = max(map(copy(l:lines), {_, v -> len(v)}))

                " Guardar en el registro
                call setreg('y', l:lines, "\<C-v>" . l:width)

            endif

        endif


        "5. Pegar justo después del cursor
        if a:use_insert_mode
        "if mode() =~ 'i'
            "call feedkeys("\<C-o>\"yp", 'n')
            "return ''
            return "\<C-o>\"yp"
        endif

        silent normal! "yp
        return ''

    endfunction

    " Normal mode: insertar contenido de buffer tmux despues del cursor actual
    nnoremap <C-F11> :<C-u>call <SID>PasteClipboardAfterCursor(v:false,"b")<CR>
    nnoremap <C-F12> :<C-u>call <SID>PasteClipboardAfterCursor(v:false,"l")<CR>

    " Normal insert: insertar contenido de buffer tmux despues del cursor actual
    inoremap <expr> <C-F11> <SID>PasteClipboardAfterCursor(v:true,"b")
    inoremap <expr> <C-F12> <SID>PasteClipboardAfterCursor(v:true,"l")

endif


"-----------------------------------------------------------------------------------
" Mappings - Apariencia
"-----------------------------------------------------------------------------------
"
"Habilitar/Desabiliar la linea de resaltado ('Highlight Line') Horizonal
nnoremap <Leader>hh :set cursorline!<CR>

"Habilitar/Desabiliar la linea de resaltado ('Highlight Line') Vertical
nnoremap <Leader>vv :set cursorcolumn!<CR>



"-----------------------------------------------------------------------------------
" Mappings - Splits
"-----------------------------------------------------------------------------------
"
    "Navegación stre splits (no es necesario especificar, lo define el Plug-In 'vim-tmux-navigator').
"noremap <C-j> <C-w>j
"noremap <C-k> <C-w>k
"noremap <C-l> <C-w>l
"noremap <C-h> <C-w>h

"Terminal : Abrir una terminal
if g:is_neovim

    "set termwinsize=15*0
    nnoremap <Leader>th :split <bar> resize 20 <bar> terminal<CR>i
    "nnoremap <Leader>th :split <bar> terminal<CR>i
    nnoremap <Leader>tv :vsplit <bar> terminal<CR>i

else

    "set termwinsize=15*0
    nnoremap <Leader>tv :botright vertical terminal<CR>
    nnoremap <Leader>th :botright terminal<CR>

endif

"Terminal : Salir de modo 'Terminal-Job' e ingresar en modo lectura ('Terminal-Normal')
"noremap <C-N> <C-\><C-n>



"-----------------------------------------------------------------------------------
" Mappings - Tabs
"-----------------------------------------------------------------------------------
"
"nnoremap <silent> <S-t> :tabnew<CR>
"



"-----------------------------------------------------------------------------------
" Mappings - Otros
"-----------------------------------------------------------------------------------
"
"Set working directory
"nnoremap <leader>. :lcd %:p:h<CR>

"Opens an edit command with the path of the currently edited file filled in
"noremap <Leader>e :e <C-R>=expand("%:p:h") . "/" <CR>

"Opens a tab edit command with the path of the currently edited file filled
"noremap <Leader>te :tabe <C-R>=expand("%:p:h") . "/" <CR>



"-----------------------------------------------------------------------------------
" Fix manual de Bugs
"-----------------------------------------------------------------------------------
"
" Bugs en VIM :
" > Cuanto la terminal soporta 'modifyOtherKeys' de nivel 2, cuando se apreta ciertos key reservados (usando 'ctrl', 'shfit', 'alt')
"   se genera texto con caracteres escapa/control la cual puede generar comportamiento inesperados cuando el comando no lo reconoce
"   este tips de key y el tipp de 'modifyOtherKeys'.
" > En caso de VIM, estas secuenncias de escapa puede generar que algunos keybiding dejen de funcionar.
" > Issue VIM  : https://github.com/vim/vim/issues/9014
"                https://codeberg.org/dnkl/foot/wiki#ctrl-key-breaks-input-in-vim
"                https://codeberg.org/dnkl/foot/issues/849
" > WORKAROUND : Caundo la terminal soporte 'modifyOtherKeys' de nivel 2, forzar que VIM soporte los secuencias de
"   escape generados
" > Los emuladores de terminal, como 'foot', no definir por defecto la variable 'TERM_PROGRAM', por lo que debera
"   definir manualmente este valor en su archivo de configuracion.
"if !g:is_neovim && ($TERM_PROGRAM == 'foot' || $TERM_PROGRAM == 'WezTerm')
"    let &t_TI = "\<Esc>[>4;2m"
"    let &t_TE = "\<Esc>[>4;m"
"endif
