"###################################################################################
" Settings> UI> Package - StatusLine y TabLine
"###################################################################################

if g:is_neovim
    
    "Inicializar el StatusLine, TabLine, ...
    lua require('native.ui.core')

else
    "StatusLine y TabLine : AirLine

    "Airline : Tema a usar
    let g:airline_theme = 'powerlineish'

    "Airline : Mostrar la rama GIT
    let g:airline#extensions#branch#enabled = 1

    "Airline : Mostrar informacion de ALE
    let g:airline#extensions#ale#enabled = 1

    "Airline : Mostrar el Tabline (buffer y tabs)
    if g:use_tabline
        let g:airline#extensions#tabline#enabled = 1
    endif

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

endif

"###################################################################################
" Settings> UI > Integración con TMUX
"###################################################################################

if g:use_tmux

    "The percent of the screen the split pane Vimux will spawn should take up.
    "let g:VimuxHeight = "20"
    
    "The default orientation of the split tmux pane. This tells tmux to make the pane either vertically or
    "horizontally, which is backward from how Vim handles creating splits.
    "   'v': vertical
    "   'h': horizontal
    "let g:VimuxOrientation = "h"
    
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

