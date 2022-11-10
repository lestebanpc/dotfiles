"###################################################################################
" Settings> UI> Package - StatusLine y TabLine
"###################################################################################

if g:is_neovim
    
    "Inicializar el StatusLine, TabLine, ...
    lua require('ui_core')

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

    "Solo para fuentes que no son 'Porweline' (Usar caracteres equivalente)
    let g:airline_powerline_fonts = 1

    let g:airline#extensions#virtualenv#enabled = 1
    let g:airline#extensions#tagbar#enabled = 1
    let g:airline_skip_empty_sections = 1

    if !exists('g:airline_symbols')
        let g:airline_symbols = {}
    endif

    if !exists('g:airline_powerline_fonts')
        let g:airline#extensions#tabline#left_sep = ' '
        let g:airline#extensions#tabline#left_alt_sep = '|'
        let g:airline_left_sep          = '▶'
        let g:airline_left_alt_sep      = '»'
        let g:airline_right_sep         = '◀'
        let g:airline_right_alt_sep     = '«'
        let g:airline#extensions#branch#prefix     = '⤴' "➔, ➥, ⎇
        let g:airline#extensions#readonly#symbol   = '⊘'
        let g:airline#extensions#linecolumn#prefix = '¶'
        let g:airline#extensions#paste#symbol      = 'ρ'

        let g:airline_symbols.linenr    = '␊'
        let g:airline_symbols.branch    = '⎇'
        let g:airline_symbols.paste     = 'ρ'
        let g:airline_symbols.paste     = 'Þ'
        let g:airline_symbols.paste     = '∥'
        let g:airline_symbols.whitespace = 'Ξ'
    else
        let g:airline#extensions#tabline#left_sep = ''
        let g:airline#extensions#tabline#left_alt_sep = ''

        "Powerline symbols
        let g:airline_left_sep = ''
        let g:airline_left_alt_sep = ''
        let g:airline_right_sep = ''
        let g:airline_right_alt_sep = ''

        let g:airline_symbols.branch = ''
        let g:airline_symbols.readonly = ''
        let g:airline_symbols.linenr = ''
    endif
endif

"###################################################################################
" Settings>ackage> UI > Integración con TMUX
"###################################################################################

"NO ejecutar en Windows
if g:os == "Windows"
    finish
endif
  
"Plug-in: Crear paneles TMUX en VIM
"Prompt for a command to run
nnoremap <Leader>vp :VimuxPromptCommand<CR>

"Run last command executed by VimuxRunCommand
nnoremap <Leader>vl :VimuxRunLastCommand<CR>


