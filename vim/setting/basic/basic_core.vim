"###################################################################################
" UI> Temas y sus schema colors
"###################################################################################
"
" > 256-color : https://www.ditig.com/256-colors-cheat-sheet
" > 16-color  : https://github.com/jonasjacek/colors
"
let g:colorschema_main = ''

if g:is_neovim

    "Plugin UI> Tema 'Tokyo Night'
    "packadd tokyonight.nvim

    "Esquema de color se define dentro de 'ui_basic.lua'.
    "let g:colorschema_main = 'tokyonight'


    "Plugin UI> Tema 'Catppuccin'
    packadd nvim

    "Esquema de color se define dentro de 'ui_basic.lua'.
    let g:colorschema_main = 'catppuccin'


else


    "Plugin UI> Tema Gruvbox
    "packadd gruvbox

    "Elige el contraste (soft, medium, hard)
    "let g:gruvbox_contrast_dark = 'medium'

    "Esquema de color del tema
    "colorscheme gruvbox
    "let g:colorschema_main = 'gruvbox'

    "Personalizacion (No funciona)
    "highlight Normal guibg=#0f0f0f ctermbg=233
    "highlight NormalNC guibg=#171717 ctermbg=234
    "highlight Comment guifg=#737a88 ctermfg=245 gui=italic




    "Plugin UI> Tema Onedark
    packadd onedark.vim

    "Soporte a letras cursivas
    let g:onedark_terminal_italics = 1

    "Personalizar el schema
    "Donde por tipo de color se tiene los siguientes campos:
    " - 'gui'     : is the hex color code used in GUI mode/nvim true-color mode
    " - 'cterm'   : is the color code used in 256-color mode
    " - 'cterm16' : is the color code used in 16-color mode
    let g:onedark_color_overrides = {
    \ "background": {"gui": "#0f0f0f", "cterm": "233", "cterm16": "0" }
    \}

    "Personalizacion (No funciona)
    "augroup colorset
    "    autocmd!
    "    autocmd ColorScheme * call onedark#set_highlight("NormalNC", { "bg": {"gui": "#171717", "cterm": "234", "cterm16": "0" } })
    "augroup END

    "Esquema de color del tema
    colorscheme onedark
    let g:colorschema_main = 'onedark'

    "Personalizacion (No funciona)
    "highlight NormalNC guibg=#171717 ctermbg=234
    "highlight Comment guifg=#737a88 ctermfg=245 gui=italic


endif



"###################################################################################
" UI > Integración con TMUX
"###################################################################################

"En Windows no existe TMUX (Solo en Linux, incluyendo: WSL, solo en Linux y MacOS)

if g:use_tmux

    "1. Package UI> Crear paneles TMUX desde VIM
    packadd vimux

    "The percent of the screen the split pane Vimux will spawn should take up.
    "let g:VimuxHeight = '20'

    "The default orientation of the split tmux pane. This tells tmux to make the pane either vertically or
    "horizontally, which is backward from how Vim handles creating splits.
    "   'v': vertical
    "   'h': horizontal
    "let g:VimuxOrientation = 'h'

    "Abrir el panel tmux (por defecto es horizontal).
    "function! s:MyOpenRunner() abort

    "    " Abrimos el panel de tmux de Vimux
    "    call VimuxOpenRunner()

    "    if exists('g:VimuxRunnerIndex') && !empty(g:VimuxRunnerIndex)
    "        "Remover el caracter '%' del ID panel tmux
    "        let pane_id = g:VimuxRunnerIndex[1:]
    "        silent call system('tmux set-window-option @cmd_pane_idx ' . pane_id)
    "    endif

    "endfunction

    nnoremap <Leader>to :VimuxOpenRunner<CR>
    "nnoremap <Leader>to :call <SID>MyOpenRunner()<CR>

    "Cerrar el panel tmux (por defecto es horizontal).
    nnoremap <Leader>tq :VimuxCloseRunner<CR>

    "Ir al panel tmux, ingresar al modo copia del panel tmux.
    " > Inicie la selección usando 'v' o [SPACE]
    " > Despues de la selección, copie el texto al buffer de tmux y el portapeles (del SO de la terminal) usando
    "   'y' o '[ENTER]'
    " > Para pegar el texto en el prompt de la terminal, usando el buffer 'CTRL + B, ]' o usando el portapeles
    "   los atajos del sistema operativo donde ejecuta el terminal.
    " > Para pegar/mostrar en el flujo de salida estandar, usando el comando 'tmux show-buffer'.
    nnoremap <Leader>t[ :VimuxInspectRunner<CR>

    "Ir al panel tmux, maximizando el panel (para restaurar/maximizar nuevamente el panel use 'CTRL + B, z')
    nnoremap <Leader>tz :VimuxZoomRunner<CR>

    "Ejecutar comando un comando (sin ir/salir de panel de VIM):
    "function! s:MyPromptCommand() abort

    "    let save_pane_id = v:false
    "    if exists('g:VimuxRunnerIndex') && !empty(g:VimuxRunnerIndex)
    "        save_pane_id = v:true
    "    endif

    "    " Abrimos el panel de tmux de Vimux si no esta abierto y ejecutar un comando
    "    call VimuxPromptCommand()

    "    if exists('g:VimuxRunnerIndex') && !empty(g:VimuxRunnerIndex) && save_pane_id
    "        "Remover el caracter '%' del ID panel tmux
    "        let pane_id = g:VimuxRunnerIndex[1:]
    "        silent call system('tmux set-window-option @cmd_pane_idx ' . pane_id)
    "    endif

    "endfunction

    nnoremap <Leader>tp :VimuxPromptCommand<CR>
    "nnoremap <Leader>tp :call <SID>MyPromptCommand()<CR>

    "Ejecutar comando espaciales (sin ir/salir de panel de VIM):
    " > Ejecutar el ultimo comando.
    nnoremap <Leader>tr :VimuxRunLastCommand<CR>
    "
    " > Cancelar el comando en ejecución (CTRL + C).
    nnoremap <Leader>tx :VimuxInterruptRunner<CR>
    "
    " > Limpiar la terminal (clear).
    nnoremap <Leader>tl :call VimuxRunCommand('clear')<CR>
    " Ejeucta CTRL+L el cual no soportado bash vim solo el emacs
    "nnoremap <Leader>tc :VimuxClearTerminalScreen<CR>


    "2. Paquete UI> Permite navegar entre split VIM y hacia paneles TMUX.
    "   URI : https://github.com/christoomey/vim-tmux-navigator
    "   > Pemite ir de un split VIM a un panel tmux (identifica si existe un panel TMUX, y genera comando tmux
    "     para ir panel), pero, para ir de panel TMUX a un split VIM, requiere configurar estos keybinding en
    "     el 'tmux.config', para reenviar las teclas en VIM.
    "
    "   Los default keybinding se mantiene:
    "    > En VIM  'CTRL + w, ...'
    "    > En TMUX 'CTRL + b, ...'
    "
    "   Los keybinding defenidos, estan el modo normal y terminal, por este mantiene:
    "    > <CTRL-h> => Left
    "    > <CTRL-j> => Down
    "    > <CTRL-k> => Up
    "    > <CTRL-l> => Right
    "    > <CTRL-\> => Previous split
    "
    packadd vim-tmux-navigator



    "3. Adicionar soporte para copiar el contenido de 'vim record' a un 'tmux buffer'

    " Funcion que obtiene el texto de un vim record y lo escribe en un tmux buffer
    " > El buffer a crear siempre se adiciona a la pila de buffer existentes en tmux.
    " Parameters :
    " > 'record_name' : Nombre del registro.
    function! s:RecordToTmuxBuffer(record_name) abort

        "1. Obtener el texto yankeado
        let l:txt = getreg(a:record_name)

        if empty(l:txt)
            echo printf("Record '%s' is empty.", a:record_name)
            return
        endif

        " Eliminar salto final extra
        if g:os_type == 3
            let l:txt = substitute(l:txt, '\r', '', 'g')
        endif
        let l:txt = substitute(l:txt, '\n\+$', '', '')


        "2. Obtener el correlativo del ultimo buffer creado por vim
        let l:full_cmd = "tmux list-buffers -F '#{buffer_name}' | grep -P '^vim\\d+$' | awk -F 'vim' '{print $2}' | head -n 1"
        let l:correlative = 0
        let l:result = system(full_cmd)

        if v:shell_error == 0

            " Eliminar el fin de linea final
            if g:os_type == 3
                let l:result = substitute(l:result, '\r', '', 'g')
            endif
            let l:result = substitute(l:result, '\n\+$', '', '')

            " Convertir a entero y sumar
            if !empty(l:result)
                let l:correlative = str2nr(l:result) + 1
            endif

        endif


        "3. Escribir en el tmux buffer (crear un tmux buffer)
        let l:full_cmd = printf('tmux set-buffer -b vim%d -', l:correlative)
        call system(l:full_cmd, l:txt)

        if v:shell_error != 0
            echo printf("Error to write tmux buffer 'vim%d'.", l:correlative)
            return
        endif

        "4. Mensaje de confirmación
        "let l:lines = count(l:text, "\n") + 1
        echo printf("Record '%s' was written to tmux buffer 'vim%d'.", a:record_name, l:correlative)

    endfunction

    " Copiar el registro por defecto (el ultimo yank o delete) en un nuevo tmux buffer.
    nnoremap <Leader>tt :<C-u>call <SID>RecordToTmuxBuffer('"')<CR>

    " Copiar el registro del ultimo yank realizado en un nuevo tmux buffer.
    nnoremap <Leader>t0 :<C-u>call <SID>RecordToTmuxBuffer('0')<CR>

    " Copiar el registro de los ultimo deletes en un nuevo tmux buffer.
    nnoremap <Leader>t1 :<C-u>call <SID>RecordToTmuxBuffer('1')<CR>
    nnoremap <Leader>t2 :<C-u>call <SID>RecordToTmuxBuffer('2')<CR>
    nnoremap <Leader>t3 :<C-u>call <SID>RecordToTmuxBuffer('3')<CR>



    "4. Adicionar soporte para realizar un delete/yank una seleccion y luego copiarlo al 'tmux buffer'

    " Funcion que delete/yank el texto selecionado y luego escribe en un tmux buffer
    " Parameters :
    " > 'use_delete' : Si se realiza un yank o un delete.
    function! s:WriteToTmuxBuffer(use_delete) abort

        "1. Yank or Delete la selección actual al registro 'x'
        "   Desde el modo normal, realiza la ultima seleccion (gv) y luego realiza la operacion en el registro '"').
        if a:use_delete
            silent normal! gv"xd
        else
            silent normal! gv"xy
        endif


        "2. Obtener el texto yankeado (por defecto obtiene un solo texto y no una lista)
        let l:txt = getreg('x')

        " Eliminar salto final extra
        if g:os_type == 3
            let l:txt = substitute(l:txt, '\r', '', 'g')
        endif
        let l:txt = substitute(l:txt, '\n\+$', '', '')

        " Si es vacio
        if empty(l:txt)
            echo "No text in the clipboard."
            return
        endif


        "3. Obtener el correlativo del ultimo buffer creado por vim
        let l:full_cmd = "tmux list-buffers -F '#{buffer_name}' | grep -P '^vim\\d+$' | awk -F 'vim' '{print $2}' | head -n 1"
        let l:correlative = 0
        let l:result = system(full_cmd)

        if v:shell_error == 0

            " Eliminar el fin de linea final
            if g:os_type == 3
                let l:result = substitute(l:result, '\r', '', 'g')
            endif
            let l:result = substitute(l:result, '\n\+$', '', '')

            " Convertir a entero y sumar
            if !empty(l:result)
                let l:correlative = str2nr(l:result) + 1
            endif

        endif


        "4. Escribir en el tmux buffer (crear un tmux buffer)
        let l:full_cmd = printf('tmux load-buffer -b vim%d -', l:correlative)
        call system(l:full_cmd, l:txt)

        if v:shell_error != 0
            echo printf("Error to write tmux buffer 'vim%d'.", l:correlative)
            return
        endif


        "6. Mensaje de confirmación
        let l:lines = count(l:txt, "\n") + 1
        echo printf("%d lines was written to tmux buffer 'vim%d'.", l:lines, l:correlative)

    endfunction

    " En el modo visual: 'yank' el texto selecionado (escribe en el buffer por defecto) y luego crea un tmux buffer
    vnoremap <Leader>ty :<C-u>call <SID>WriteToTmuxBuffer(v:false)<CR>

    " En el modo visual: 'delete' el texto selecionado (escribe en el buffer por defecto) y leugo crea un tmux buffer
    vnoremap <Leader>td :<C-u>call <SID>WriteToTmuxBuffer(v:true)<CR>


    "5. Adicionar pegar un 'tmux buffer' en buffer actual

    " Funcion que obtiene el texto de un tmux buffer y lo pega al buffer actual
    " Parameters :
    " > 'tmux_buffer_pos' : posicion en la pila del tmux buffer a escribir (inicia desde 1).
    " > 'record_type' : 'c' (carácter), 'l' (línea), 'b' (bloque).
    " > 'insert_mode' : true si se usa en insert mode
    function! s:PasteTmuxAfterCursor(use_insert_mode, tmux_buffer_pos, record_type)

        if empty(a:record_type)
            let a:record_type = "c"
        endif

        "1. Obtener el nombre del buffer segun la posicion en la pila
        let l:full_cmd = printf('tmux list-buffers -F "#{buffer_name}" | sed -n "%dp"', a:tmux_buffer_pos)
        let l:result = system(full_cmd)
        let l:buffer_name = ''

        if v:shell_error == 0

            " Eliminar el fin de linea final
            if g:os_type == 3
                let l:result = substitute(l:result, '\r', '', 'g')
            endif
            let l:result = substitute(l:result, '\n\+$', '', '')

            " Convertir a entero y sumar
            let l:buffer_name = l:result

        endif

        "Si no se encontro un buffer
        if empty(l:buffer_name)
            echo printf("No buffer found at position %d of the buffer stack.", a:tmux_buffer_pos)
            return ''
        endif

        "2. Obtener texto del buffer
        let l:full_cmd = printf('tmux show-buffer -b %s', l:buffer_name)
        let l:txt = system(l:full_cmd)

        if v:shell_error != 0
            echo printf("Error to get content of tmux buffer '%s'.", l:buffer_name)
            return ''
        endif

        " Eliminar salto final extra
        if g:os_type == 3
            let l:txt = substitute(l:txt, '\r', '', 'g')
        endif
        let l:txt = substitute(l:txt, '\n\+$', '', '')

        if empty(l:txt)
            echo printf("The tmux buffer '%s' has no text.", l:buffer_name)
            return ''
        endif


        "3.Guardalo en el registro 'x'
        if a:record_type == "c"
            call setreg('x', l:txt)
        else

            " TODO: No funciona 'l' ni 'b'
            " Obtener un arreglo con las lineas (requerido para un pegado en 'line' y 'block')
            let l:lines = split(l:txt, '\n')
            if a:record_type == "l"
                call setreg('x', l:lines, 'V')
            else

                " Calcular el ancho máximo del bloque (columna más ancha)
                let l:width = max(map(copy(l:lines), {_, v -> len(v)}))

                " Crear diccionario para el bloque visual
                let l:block = {
                    \ 'type': "\<C-V>",
                    \ 'lines': l:lines,
                    \ 'width': l:width
                \ }

                " Guardar en el registro
                call setreg('x', l:block)

            endif

        endif


        "5. Pegar justo después del cursor
        if a:use_insert_mode
        "if mode() =~ 'i'
            "call feedkeys("\<C-o>\"xp", 'n')
            "return ''
            return "\<C-o>\"xp"
        endif

        silent normal! "xp
        return ''

    endfunction


    " Normal mode: insertar contenido de buffer tmux despues del cursor actual
    nnoremap <C-F1>  :<C-u>call <SID>PasteTmuxAfterCursor(v:false,1,"c")<CR>
    nnoremap <C-F2>  :<C-u>call <SID>PasteTmuxAfterCursor(v:false,2,"c")<CR>
    nnoremap <C-F3>  :<C-u>call <SID>PasteTmuxAfterCursor(v:false,3,"c")<CR>
    nnoremap <C-F4>  :<C-u>call <SID>PasteTmuxAfterCursor(v:false,4,"c")<CR>
    nnoremap <C-F5>  :<C-u>call <SID>PasteTmuxAfterCursor(v:false,5,"c")<CR>

    "nnoremap <C-F6>  :<C-u>call <SID>PasteTmuxAfterCursor(v:false,1,"b")<CR>
    "nnoremap <C-F7>  :<C-u>call <SID>PasteTmuxAfterCursor(v:false,2,"b")<CR>
    "nnoremap <C-F8>  :<C-u>call <SID>PasteTmuxAfterCursor(v:false,3,"b")<CR>
    "nnoremap <C-F9>  :<C-u>call <SID>PasteTmuxAfterCursor(v:false,4,"b")<CR>
    "nnoremap <C-F10> :<C-u>call <SID>PasteTmuxAfterCursor(v:false,5,"b")<CR>


    " Insert mode: insertar contenido de buffer tmux despues del cursor actual
    inoremap <expr> <C-F1>  <SID>PasteTmuxAfterCursor(v:true,1,"c")
    inoremap <expr> <C-F2>  <SID>PasteTmuxAfterCursor(v:true,2,"c")
    inoremap <expr> <C-F3>  <SID>PasteTmuxAfterCursor(v:true,3,"c")
    inoremap <expr> <C-F4>  <SID>PasteTmuxAfterCursor(v:true,4,"c")
    inoremap <expr> <C-F5>  <SID>PasteTmuxAfterCursor(v:true,5,"c")

    "inoremap <expr> <C-F6>  <SID>PasteTmuxAfterCursor(v:true,1,"b")
    "inoremap <expr> <C-F7>  <SID>PasteTmuxAfterCursor(v:true,2,"b")
    "inoremap <expr> <C-F8>  <SID>PasteTmuxAfterCursor(v:true,3,"b")
    "inoremap <expr> <C-F9>  <SID>PasteTmuxAfterCursor(v:true,4,"b")
    "inoremap <expr> <C-F10> <SID>PasteTmuxAfterCursor(v:true,5,"b")



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

    " Solo para soporte a algunos plugin VIM de coc-fzf.
    " No se usa directamente este plugin.
    if g:use_coc

        "Plug-In UI> FZF ("FuZzy Finder") - Funciones shell basicas de utilidad para fzf
        packadd fzf

        "Plug-In UI> FZF ("FuZzy Finder") - Comandos VIM para usar mejor FzF
        packadd fzf.vim

    endif

    "Plug-In UI> FZF ("FuZzy Finder")
    packadd fzf-lua

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
let g:airline_theme = g:colorschema_main
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



"###################################################################################
" UI> FZF (FuZzy Finder)
"###################################################################################

"Plug-In UI> FZF ("FuZzy Finder") - Funciones shell basicas de utilidad para fzf
packadd fzf

"Plug-In UI> FZF ("FuZzy Finder") - Comandos VIM para usar mejor FzF
packadd fzf.vim


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
    let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.99, 'height': 0.8 } }
    "let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.9, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'highlight': 'Identifier', 'border': 'rounded' } }
    "let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.99, 'height': 0.8, 'yoffset': 0.5, 'xoffset': 0.5, 'border': 'rounded' } }

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


"let g:fzf_vim.tags_command = 'ctags -R'


"Busqueda de archivos del proyecto usando busqueda difuso 'ripgrep'.
nnoremap <silent> <leader>ff :Rg<CR>
nnoremap <silent> <leader>fw :Rg <C-r><C-w><CR>
"nnoremap <silent> <leader>fW :call fzf#vim#grep('rg --vimgrep --no-heading --smart-case ' . shellescape(expand('<cWORD>')), 1, fzf#vim#with_preview(), 0)

"Listar, Selexionar/Examinar e Ir al buffer
nnoremap <silent> <leader>bb :Buffers<CR>

"Listar archivos del proyecto, Seleccionar/Examinar e Ir
nnoremap <silent> <leader>ll :Files<CR>

"Listar archivos del 'Git Files', Seleccionar/Examinar e Ir
nnoremap <silent> <leader>lg :GFiles<CR>

"Listar archivos del 'Git Status Files', Seleccionar/Examinar e Ir
nnoremap <silent> <leader>ls :GFiles?<CR>

"Listar comandos VIM, seleccionar y ejecutar
nnoremap <silent> <leader>lc :History:<CR>

"Listar las marcas (marks), seleccionar e ir
nnoremap <silent> <leader>lm :Marks<CR>

"Listar los saltos (jumps), seleccionar e ir
nnoremap <silent> <leader>lj :Jumps<CR>

"Listar todos los tags del proyecto. (Si no se encuenta el archivo tags, debe generarlo usando 'ctags -R')
nnoremap <silent> <leader>lT :Tags<CR>

"Listar los tags (generados por ctags) del buffer actual, seleccionar e ir
nnoremap <silent> <leader>lt :BTags<CR>

"Listar help tags de vim (archivos de ayuda de vim)
nnoremap <silent> <leader>lh :Helptags<CR>

"Recomendaciones del uso de tags de codigo:
" - Regenerar los tags cuando realiza cambios ejecutando 'ctags -R' en el folder root del proyecto.
" - Crear archivos 'option files' dentro del proyecto (ubicados usualmente carpata './.ctags.d/'),
"   donde defina las opciones por defecto cuando se ejecuta 'ctags', por ejemplo, coloque los archivos
"   y carpetas de exclusiion.
