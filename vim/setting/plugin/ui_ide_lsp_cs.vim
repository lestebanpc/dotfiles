"Para Neovim usar la configuracion con LSP nativo con Omnisharp Server
if g:is_neovim && !g:use_coc_in_nvim
    "lua require('ui_ide_lsp_cs')
    finish
endif

"###################################################################################
" Settings> IDE > Package: Omnisharp-Vim (Pluing del Client LSP para Roslyn)
"###################################################################################

"Roslyn Server (LSP Server para C#)
" - (1) 'Stdio Version' (default, es la versión recomendada).
" - ( ) 'HTTP Version'  (versión antigua)  
"let g:OmniSharp_server_stdio = 1

"Roslyn Server (LSP Server para C#) - Path (Cambiar la ubicacion real)
let g:OmniSharp_server_path = g:lsp_server_cs_path 

"Roslyn Server (LSP Server para C#) - Si se usa WSL:
"  - Usar el LSP server de Windows (no requiere instalar LSP server en WSL)
"  - Las rutas de windows obtenidas de los archivo de solucion es traducida a la ruta de Linux
if g:os_type == 3
    if g:wsl_cs_using_win_lsp_server
	    let g:OmniSharp_translate_cygwin_wsl = 1
    else
	    let g:OmniSharp_translate_cygwin_wsl = 0
    endif
endif


"Roslyn Server (LSP Server para C#) - Si se usa la version desarollado en .NET 6 (anteriormente se usaba Mono)
let g:OmniSharp_server_use_net6 = 1

"Herramienta que se usara en 'Code Actions'
let g:OmniSharp_selector_ui = 'fzf' 

"Herramienta que se usara en 'Find Symbols'
let g:OmniSharp_selector_findusages = 'fzf'

"Popup Windows - position
let g:OmniSharp_popup_position = 'peek'

"Popup Windows - Border del popup para VIM (por defecto no tiene borde)
if g:is_neovim
    let g:OmniSharp_popup_options = {
        \ 'winblend': 30,
        \ 'winhl': 'Normal:Normal,FloatBorder:ModeMsg',
        \ 'border': 'rounded'
        \}
else
    let g:OmniSharp_popup_options = {
        \ 'highlight': 'Normal',
        \ 'padding': [0],
        \ 'border': [1],
        \ 'borderchars': ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
        \ 'borderhighlight': ['ModeMsg']
        \}
endif

"Popup - Personalizar el algunos key mappings que se usaran cuando aparezca un popup
let g:OmniSharp_popup_mappings = {
\ 'pageDown': ['<C-f>', '<PageDown>'],
\ 'pageUp': ['<C-b>', '<PageUp>']
\}

"Resaltado Sintaxico/Semantico (Semantic Highlighting). Default = 1
"  (0) No hay resaltado,
"  (1) Resaltado nuevos solo se dan cuando se pasa de modo edit a normal (por defecto),
"  (3) Resaltado siempre se da, aun cuando el texto aun en modo insert
"let g:OmniSharp_highlighting = 1

"Fuente de snippets para UltiSnips: OmniSharp
if g:has_python3
    let g:OmniSharp_want_snippet = 1
endif

"xxx
let g:OmniSharp_highlight_groups = {
\ 'ExcludedCode': 'NonText'
\}


"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
" OmniSharp-Vim> Soporte a Code-actions para OmniSharp
"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"Code actions: A flag is displayed in the sign column to indicate that one or more code actions are available.

"Flag para habilitar esta opcion (0 es 'disable')
if !exists('+signcolumn')
    let g:csharp_codeactions_enable = 0
else
    let g:csharp_codeactions_enable = 1

    "Lista separada de comas de las eventos (autocmd) que disparan las acciones de codigo.
    "Suggestions : CursorHold, CursorMoved, BufEnter,CursorMoved
    let g:csharp_codeactions_autocmd = 'CursorHold'

    "'signcolumn' will be set to yes for .cs buffers
    let g:csharp_codeactions_set_signcolumn = 1

    "Definir un columna y el caracter a ser used as the sign-column indicator
    sign define csharp_CodeActions text=💡

endif

"Code action: Funciones de utilidad
function! ui_ide_lsp_cs#codeactions_count() abort
  let opts = {
  \ 'CallbackCount': function('s:CBReturnCount', [bufnr(), line('.')]),
  \ 'CallbackCleanup': {-> execute('sign unplace * group=csharp_CodeActions')}
  \}
  call OmniSharp#actions#codeactions#Count(opts)
endfunction

function! s:CBReturnCount(bufnr, line, count) abort
  if a:count
    execute 'sign place 99'
    \ 'line=' . a:line
    \ 'name=csharp_CodeActions'
    \ 'group=csharp_CodeActions'
    \ 'file=' . bufname(a:bufnr)
  endif
endfunction


