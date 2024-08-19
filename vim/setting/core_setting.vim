"###################################################################################
" Settings - Core
"###################################################################################

"----------------------------- Calcular de Variables  ------------------------------

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


"Determinar si se usa TMUX
"if (g:os_type != 0) && exists('$TMUX') && executable('tmux')
if (g:os_type != 0) && exists('$TMUX') 
    let g:use_tmux = 1
else
    let g:use_tmux = 0
endif

"Si se esta en el modo IDE (g:use_ide se define en el archivo de inicialización), determinar 
"si realmente se requiere usar el modo IDE
if g:use_ide && $USE_EDITOR != ""
    "Para no remover la carpeta de 'ftplugin' del runtimepath en VIM instalado para
    "en cada 'file type' se validara esta variable antes de que se carge.
    let g:use_ide = 0
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
"     1 > Usar CoC como IDE
"     0 y otro valor > Usar el LSP nativo de NeoVIM
if g:use_ide && g:is_neovim

    "Si es NeoVim, el IDE puede usar CoC o el LSP interno
    "  > Usar '~/.config/nvim/ftplugin' solo para 'file types' comunes para el IDE CoC/No-CoC
    "  > Usar '~/.config/nvim/rte_cocide/ftplugin' solo para 'file types' del IDE CoC
    "  > Usar '~/.config/nvim/rte_nativeide/ftplugin' solo para 'file types' del IDE No-CoC
    if $USE_COC == 1
        let g:use_coc_in_nvim = 1
        let &runtimepath.=',' .. g:home_path .. '/.config/nvim/rte_cocide'
    else
        let g:use_coc_in_nvim = 0
        let &runtimepath.=',' .. g:home_path .. '/.config/nvim/rte_nativeide'        
    endif
	
endif


"----------------------------- Clipboard de SO         -----------------------------
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
"   > Cuando se usa 'ctrl+V', es la terminal la que obtiene el texto del portapapeles y reenvía la tecla 
"     'ctrl+V' al comando de ejecución.
"   > Algunos comandos, como 'vim', 'nvim', 'tmux', 'ssh', …. implementan un acción frente a este evento 
"     algunos no lo implementan.
"   > Cuando se usa 'ctrl+C', este se envía al programa, pero muchos comandos una accion para gestionar el 
"     portapapeles, debido a que acoplan la lógica del comando con el API de gestión de portapapeles del SO.
"     VIM/Neovim no implementan logica de pegado al portapapeles con esta key.
"

"Si esta compilado tiene nativo para poder escribir en el clipboard del SO
if has('clipboard')
    let g:has_clipboard = 1
else
    let g:has_clipboard = 0
endif

"Determinar si existe el backend de gestion del clipboard y obtener del comando externo para escribir el portapapeles
let g:clipboard_command = ''

"Si es Linux (sea WSL y no-WSL)
if (g:os_type == 2) || (g:os_type == 3)

    if  exists('$WAYLAND_DISPLAY') 
        if executable('wl-copy')
            let g:clipboard_command='wl-copy'
        endif
    elseif exists('$DISPLAY') 
        if executable('xclip')
            let g:clipboard_command='xclip -i -selection clipboard'
        elseif executable('xclip')
            let g:clipboard_command='xsel -i -b'
        endif
    endif

"Si es Windows
elseif g:os_type == 0

    if executable('clip.exe')
        let g:clipboard_command='clip.exe'
    endif

"Si es MacOS
elseif g:os_type == 1

    if executable('pbcopy')
        let g:clipboard_command='pbcopy'
    endif

endif

"Establecer el mecanismo de escritura en el clipboard del SO. Variable 'g:set_clipboard_type' cuyos
"valores son:
"  0 > Usar el mecanismo nativo de VIM/NeoVIM (siempre que este esta habilitado).
"  1 > Implementar un mecanismo usando OSC 52.
"  2 > Implementar un mecanismo usando comandos externos de gestion de clipboard.
"  9 > No se puedo Implementar ninguno de los mecanismos.
let g:set_clipboard_type = 9
if g:is_neovim

    " > La variable de entorno 'NVIM_CLIPBOARD' pueden tener los siguientes valores:
    "    0 > Usar el mecanismo nativo de escritura al clipboard de NeoVIM
    "    1 > Implementar el mecanismo de uso OSC 52
    "    2 > Implementar el mecanismo de uso comandos externo del gestion de clipboard
    "    Otro valor > Determinar automaticamente el mecanismo correcto segun order de prioridad: 
    "      > Usar mecanismo nativo (SOC y comandos externos) si esta habilitado.
    "      > Implementar el mecanismo OSC 52.
    if $NVIM_CLIPBOARD != '' && $NVIM_CLIPBOARD == 0
        let g:set_clipboard_type = 0
    elseif $NVIM_CLIPBOARD == 1
        let g:set_clipboard_type = 1
    elseif $NVIM_CLIPBOARD == 2
        let g:set_clipboard_type = 2
    else

        "Determinar el mecanismo de escritura del clipboard a usar:
        if g:has_clipboard
            let g:set_clipboard_type = 0
        else
            let g:set_clipboard_type = 1
        endif

    endif


else

    " > La variable de entorno 'VIM_CLIPBOARD' pueden tener los siguientes valores:
    "    0 > Usar el mecanismo nativo de escritura al clipboard de VIM
    "    1 > Implementar el mecanismo de uso OSC 52
    "    2 > Implementar el mecanismo de uso comandos externo del gestion de clipboard
    "    Otro valor > Determinar automaticamente el mecanismo correcto segun order de prioridad: 
    "      > Implementar el mecanismo OSC 52, si la terminal lo permite.
    "      > Usar mecanismo nativo (API del SO) si esta habilitado.
    "      > Implementar el mecanismo de uso comandos externo del gestion de clipboard
    "      > Si no existe comando externo, se Implementara el mecanismo OSC 52
    if $VIM_CLIPBOARD != '' && $VIM_CLIPBOARD == 0
        let g:set_clipboard_type = 0
    elseif $VIM_CLIPBOARD == 1
        let g:set_clipboard_type = 1
    elseif $VIM_CLIPBOARD == 2
        let g:set_clipboard_type = 2
    else

        "1. Intentar determinar el valor adecuado automaticamente: Determinar si la terminal soporta OSC 52
        "se usa parte de la logica 'setting_clipboard()' definida en './shell/bash/bin/tmux/fun_general.bash'
        let s:terminal_use_osc54 = 0

        "Si esta ejecutando sobre tmux
        if g:use_tmux

            "Si usa el archivo de configuracion './tmux/tmux.conf', se establece la variable de entorno 'TMUX_SET_CLIPBOARD'
            "con valor 1 o 2, si se configurado tmux con soporte a OSC 52
            if ($TMUX_SET_CLIPBOARD == 1) || ($TMUX_SET_CLIPBOARD == 2)
                let s:terminal_use_osc54 = 1
            endif

        "Si esta ejecutando directamente sobre la terminal.
        else
            
            "Los siguientes emuladores definen por defecto la variable de entorno 'TERM_PROGRAM'
            if ($TERM_PROGRAM == 'WezTerm') || ($TERM_PROGRAM == 'contour') || ($TERM_PROGRAM == 'iTerm.app')

                let s:terminal_use_osc54 = 1

            "Los siguientes emuladores debera definir la variable 'TERM_PROGRAM' con este valor en su archivo de configuracion:
            elseif ($TERM_PROGRAM == 'foot') || ($TERM_PROGRAM == 'kitty') || ($TERM_PROGRAM == 'alacritty')

                let s:terminal_use_osc54 = 1

            "Opcionalmente, aunque no se recomienta usar un TERM personalizado (no estan en todos los equipos que accede
            "por SSH), algunas terminales definen un TERM personalizado (aunque por campatibilidad, puede modificarlo).
            else
                if ($TERM == 'xterm-kitty') || ($TERM == 'alacritty') || ($TERM == 'foot')
                    let s:terminal_use_osc54 = 1
                endif
            endif

        endif

        "2. Determinar el mecanismo de escritura del clipboard a usar:
        if s:terminal_use_osc54
            let g:set_clipboard_type = 1
        else
            if g:has_clipboard
                let g:set_clipboard_type = 0
            else
                if g:clipboard_command != ''
                    let g:set_clipboard_type = 2
                else
                    let g:set_clipboard_type = 1
                endif
            endif
        endif

    endif

endif


"Establecer la opcion VIM 'clipboard' para el uso del mecanismo nativo para acceder al clipboard del SO
if g:set_clipboard_type == 0

    "NeoVIM no interactua directamente con el clipboard del SO (no usa API del SO) y tiene una Integracion
    "nativa con:
    " > Usa el caracter de escape OSC 52 para enviar texto a la terminal, para que este lo interprete y escriba
    "   al portapales del SO de la terminal.
    " > Usa comandos externos de gestion de clipboard (backend de clipboard) las cuales registra a eventos de
    "   establecer texto en registro de yank de VIM.
    if g:is_neovim

        "Si es NeoVIM, siempre se usa la opción 'unnamedplus'
        set clipboard=unnamedplus
    
    "VIM puede interactuar directamente con el clipboard del SO (usa el API del SO para ello)
    "La instegracion con comandos externos de gestion de clipboard y OSC 52, no lo hace de forma nativa.
    elseif (g:os_type == 2) || (g:os_type == 3 )

        "Si VIM y es Linux
        
        "Usar como registro predeterminado a '+' vinculado al portapales principal del SO 
        "En Linux, se usa el portapales 'CLIPBOARD' del servidor X11
        "Para copiar selecione y use 'CTRL + c', para pegar use 'CTRL + v'
        set clipboard=unnamedplus

        "Usar como registro predeterminado a '*' (que apunta al portapales 'PRIMARY' del servidor X11)
        "Para copiar el al portapales solo selecione el texto, 
        "Para pegar del portapales use el boton central o boton secundario o 'SHFIT + INSERT'
        "Se esta usando esto en Linux porque es mas facil usar y mas eficiente en recursos
        "set clipboard+=unnamed
    else
        "Si es VIM y no es Linux
        set clipboard=unnamed
    endif

else

    "Desabilitar el menanismo nativo de escritura del clipboard
    set clipboard=

endif

"Determinar el formato OSC52 a usar. Ello dependera del valor de la variable de entorno 'OSC52_FORMAT'. Esta variable
"solo sera usado cuando 'g:set_clipboard_type' es '1' y puede tener los siguientes posibles valores:
"    0 > Formato OSC 52 estandar que es enviado directmente una terminal que NO use como '$TERM' a GNU screen.
"    1 > Formato OSC52 es dividio en pequeños trozos y enmascador en formato DSC, para enviarlo directmente a una terminal 
"        basada en GNU ('$TERM' inicia con screen).
"    2 > Formato OSC52 se enmascara DSC enmascarado para TMUX (tmux requiere un formato determinado) y sera este el que 
"        decida si este debera reenvíarse a la terminal donde corre tmux (en este caso Tmux desenmacara y lo envia).
"    Si no define o tiene otro valor, se calucara automaticamente su valor. Solo use esta opcion cuando VIM/NeoVIM se ejecuta
"    de manera local la terminal, si lo ejecuta de manera remota, por ejemplo esta dentro programa ssh o dentro de un 
"    contenedor, se recomianda establecer el valor si esta dentro de tmux o de una terminal GNU '$TERM' a screen.   
let g:osc52_format = 0

if g:set_clipboard_type == 1

    if $OSC52_FORMAT != '' && $OSC52_FORMAT == 0
        let g:osc52_format = 0
    elseif $OSC52_FORMAT == 1
        let g:osc52_format = 1
    elseif $OSC52_FORMAT == 2
        let g:osc52_format = 2
    else

        "Si no define o tiene otro valor, se calucara automaticamente su valor. Solo use esta opcion cuando VIM/NeoVIM 
        "se ejecuta de manera local la terminal, si lo ejecuta de manera remota, por ejemplo esta dentro programa ssh 
        "o dentro de un contenedor, se recomianda establecer el valor si esta dentro de tmux o de una terminal GNU '$TERM'
        "a screen.   
        if g:use_tmux
            let g:osc52_format = 2
        elseif match($TERM, 'screen') > -1
            let g:osc52_format = 1
        else
            let g:osc52_format = 0
        endif

    endif

endif




"BUG IN VIM : Cuanto la terminal soporta 'modifyOtherKeys' de nivel 2, cuando se apreta ciertos key 
"reservados (usando 'ctrl', 'shfit', 'alt') se genera texto con caracteres escapa/control la cual puede generar
"comportamiento inesperados cuando el comando no lo reconoce este tips de key y el tipp de 'modifyOtherKeys'.
"En caso de VIM, estas secuenncias de escapa puede generar que algunos keybiding dejen de funcionar.
" > Issue VIM  : https://github.com/vim/vim/issues/9014
"                https://codeberg.org/dnkl/foot/wiki#ctrl-key-breaks-input-in-vim
"                https://codeberg.org/dnkl/foot/issues/849
" > WORKAROUND : Caundo la terminal soporte 'modifyOtherKeys' de nivel 2, forzar que VIM soporte los secuencias de 
"   escape generados
" > Los emuladores de terminal, como 'foot', no definir por defecto la variable 'TERM_PROGRAM', por lo que debera 
"   definir manualmente este valor en su archivo de configuracion.
if !g:is_neovim && ($TERM_PROGRAM == 'foot' || $TERM_PROGRAM == 'WezTerm')
    let &t_TI = "\<Esc>[>4;2m"
    let &t_TE = "\<Esc>[>4;m"
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
"Los servidores linux por defecto trabaja con 'ANSI 256 Color', pero generalmente las terminales modernas traducen
"el color 16bits a 24 bits para mostrar el color sin problemas.
"Si su terminal no traduce bien los 16 bits de color que envia su servidor, COMENTE esta linea y habilite 'set t_Co=256'
set termguicolors

"You might have to force true color when using regular vim inside tmux as the colorscheme can appear to be grayscale 
"with 'termguicolors' option enabled.
if !g:is_neovim && !g:is_gui_vim
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif

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
elseif (g:os_type == 2) || (g:os_type == 3)

    if exists('$SHELL')
        set shell=$SHELL
    else
        set shell=/bin/sh
    endif

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
"set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)\

"if exists("*fugitive#statusline")
"    set statusline+=%{fugitive#statusline()}
"endif

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

"----------------------------- Completado               ----------------------------



