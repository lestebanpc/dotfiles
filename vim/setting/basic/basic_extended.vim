"###################################################################################
" UI> Configuraciones exclusivas de NeoVim
"###################################################################################
if g:is_neovim

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

    "Configuraciones de los plugins exclusivas
    lua require('basic.basic_extended')

endif


"###################################################################################
" UI> FZF (FuZzy Finder)
"###################################################################################

if !g:is_neovim

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


    "Listar archivos del proyecto, Seleccionar/Examinar e Ir
    nnoremap <silent> <leader>ll :Files<CR>
    "Listar archivos del 'Git Files', Seleccionar/Examinar e Ir
    nnoremap <silent> <leader>lg :GFiles<CR>
    "Listar archivos del 'Git Status Files', Seleccionar/Examinar e Ir
    nnoremap <silent> <leader>ls :GFiles?<CR>
    "Listar comandos VIM, seleccionar y ejecutar
    nnoremap <silent> <leader>lc :History:<CR>
    "Listar las marcas (marks), seleccionar e ir
    nnoremap <silent> <leader>mm :Marks<CR>
    "Listar los saltos (jumps), seleccionar e ir
    nnoremap <silent> <leader>jj :Jumps<CR>

    "Listar, Selexionar/Examinar e Ir al buffer
    nnoremap <silent> <leader>bb :Buffers<CR>

    "Busqueda de archivos del proyecto usando busqueda difuso 'ripgrep'.
    nnoremap <silent> <leader>ff :Rg<CR>

    "Recomendaciones del uso de tags:
    " - Regenerar los tags cuando realiza cambios ejecutando 'ctags -R' en el folder root del proyecto.
    " - Crear archivos 'option files' dentro del proyecto (ubicados usualmente carpata './.ctags.d/'),
    "   donde defina las opciones por defecto cuando se ejecuta 'ctags', por ejemplo, coloque los archivos
    "   y carpetas de exclusiion.

    "Listar todos los tags del proyecto. (Si no se encuenta el archivo tags, lo genera usando 'ctags -R')
    nnoremap <silent> <leader>tw :Tags<CR>

    "Listar los tags (generados por ctags) del buffer actual, seleccionar e ir
    nnoremap <silent> <leader>tt :BTags<CR>


endif


"###################################################################################
" UI > Integración con TMUX
"###################################################################################

"En Windows no existe TMUX (Solo en Linux, incluyendo: WSL, solo en Linux y MacOS)
if (g:os_type != 0)

    if g:use_tmux

        "Package UI> Crear paneles TMUX desde VIM
        packadd vimux

        "The percent of the screen the split pane Vimux will spawn should take up.
        "let g:VimuxHeight = '20'

        "The default orientation of the split tmux pane. This tells tmux to make the pane either vertically or
        "horizontally, which is backward from how Vim handles creating splits.
        "   'v': vertical
        "   'h': horizontal
        "let g:VimuxOrientation = 'h'

        "Abrir el panel tmux (por defecto es horizontal).
        nnoremap <Leader>to :VimuxOpenRunner<CR>

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
        nnoremap <Leader>tp :VimuxPromptCommand<CR>

        "Ejecutar comando espaciales (sin ir/salir de panel de VIM):
        " > Ejecutar el ultimo comando.
        nnoremap <Leader>tl :VimuxRunLastCommand<CR>
        "
        " > Cancelar el comando en ejecución (CTRL + C).
        nnoremap <Leader>tx :VimuxInterruptRunner<CR>
        "
        " > Limpiar la terminal (clear).
        nnoremap <Leader>tc :VimuxClearTerminalScreen<CR>

    endif

    " Paquete UI> Permite navegar entre split VIM y hacia paneles TMUX.
    " URI : https://github.com/christoomey/vim-tmux-navigator
    " > Pemite ir de un split VIM a un panel tmux (identifica si existe un panel TMUX, y genera comando tmux
    "   para ir panel), pero, para ir de panel TMUX a un split VIM, requiere configurar estos keybinding en
    "   el 'tmux.config', para reenviar las teclas en VIM.
    "
    " Los default keybinding se mantiene:
    "  > En VIM  'CTRL + w, ...'
    "  > En TMUX 'CTRL + b, ...'
    "
    " Los keybinding defenidos, estan el modo normal y terminal, por este mantiene:
    "  > <CTRL-h> => Left
    "  > <CTRL-j> => Down
    "  > <CTRL-k> => Up
    "  > <CTRL-l> => Right
    "  > <CTRL-\> => Previous split
    "
    packadd vim-tmux-navigator

endif
