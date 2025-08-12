"
" Plugin IDE> Cliente LSP para server 'Omnisharp LS' para C#
"
" - Microsoft dejo de usar este LSP para su software y creo su LSP licenciado llamado 'Roslyn LS'.
" - Ambos servidores LSP se basan en el especificacion Roslyn para compiladores para .NET de Microsoft.
" - Este plugin implementa :
"   - Cliente LSP para el servidor 'Omnisharp LS'.
"   - Completion que se usara para filetypes asociado a csharp.
"   - Se implementa un Lightbulb cuando existe acciones en la linea actual.
" - El keymapings se realzia a nivel buffer para filetypes csharp.
"
packadd omnisharp-vim

"###################################################################################
" OmniSharp-Vim> Configuración del servidor LSP
"###################################################################################
"
"Roslyn Server (LSP Server para C#)
" - (1) 'Stdio Version' (default, es la versión recomendada).
" - ( ) 'HTTP Version'  (versión antigua)
"let g:OmniSharp_server_stdio = 1

" > 'OmniSharp_translate_cygwin_wsl' se usa en WSL. Si es '1' implica :
"    - Usar el LSP server de Windows (no requiere instalar LSP server en WSL).
"    - Las rutas de windows obtenidas de los archivo de solucion es traducida a la ruta de Linux.
" > 'OmniSharp_server_path' es el Path del servidor LSP.
"
let g:OmniSharp_translate_cygwin_wsl = 0

if g:os_type == 0

    "Si es Windows
    let g:OmniSharp_server_path = g:tools_path .. '/lsp_servers/omnisharp_ls/OmniSharp.exe'

"elseif (g:os_type == 3) && g:using_lsp_server_cs_win

    "Si es WSL y es se debe usar el servidor LSP de Windows
	"let g:OmniSharp_translate_cygwin_wsl = 1
    "let g:OmniSharp_server_path = g:tools_path .. '/lsp_servers/omnisharp_ls/OmniSharp.exe'

else

    "Si es Linux (2) o MacOS (1) o WSL sin reusar su servidor LSP
    let g:OmniSharp_server_path = g:tools_path .. '/lsp_servers/omnisharp_ls/OmniSharp'

endif


"Roslyn Server (LSP Server para C#) - Si se usa la version desarollado en .NET 6 (anteriormente se usaba Mono)
let g:OmniSharp_server_use_net6 = 1

"###################################################################################
" OmniSharp-Vim> Popup 'Preview', 'Documentation' y 'Signature-Help'
"###################################################################################
"
"
"let g:OmniSharp_popup = 1

"Popup Windows - position (no incluye los popups 'Signature-help' y 'Documentation')
"Valores :
"  > 'atcursor' : xxx
"  > 'peek'     : xxx
"  > 'center'   : xxx
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

"Personalizar los key mappings en modo 'popup' (las  que se usaran cuando aparezca un popup). Las teclas
"usadas en este modo son diferentes a los definidos en el modo edición/.. por lo que puede usarlos sin
"afectar a las teclas definidas en este modo.
"Los identificadores y los valores por defecto son:
"  > 'close'        : 'gq'
"  > 'pageDown'     : '<C-f>'
"  > 'pageUp'       : '<C-b>'
"  > 'lineDown'     : '<C-e>'
"  > 'lineUp'       : '<C-y>'
"  > 'halfPageDown' : '<C-d>'
"  > 'halfPageUp'   : '<C-u>'
"Los identificadores y valores por defecto que solo son para el popup de 'Signature help':
"  > 'sigNext'      : '<C-j>'
"  > 'sigPrev'      : '<C-k>'
"  > 'sigParamNext' : '<C-l>'
"  > 'sigParamPrev' : '<C-h>'
let g:OmniSharp_popup_mappings = {
\ 'pageDown': ['<C-f>', '<PageDown>'],
\ 'pageUp': ['<C-b>', '<PageUp>']
\}

"###################################################################################
" OmniSharp-Vim> Diagnostico y Highlighting
"###################################################################################
"
"When using ALE for displaying diagnostics, OmniSharp-vim can listen for diagnostics sent
"asynchronously by the OmniSharp-roslyn server, and continue to update ALE as these are received.
"  0> Do not listen for diagnostics.
"  1> Listen to the first diagnostic received for each buffer.
"  2> Listen for diagnostics and update ALE (default).
let g:OmniSharp_diagnostic_listen = 2

"let g:OmniSharp_diagnostic_showid = 1

"let g:OmniSharp_diagnostic_overrides = {
"    \ 'IDE0010': {'type': 'I'},
"    \ 'IDE0055': {'type': 'W', 'subtype': 'Style'},
"    \ 'CS8019': {'type': 'None'},
"    \ 'RemoveUnnecessaryImportsFixable': {'type': 'None'}
"    \}

"Rutas de analisis a excluir cuando se realiza un analisis y diagnostico global (del workspace)
"usando ':OmniSharpGlobalCodeCheck'
let g:OmniSharp_diagnostic_exclude_paths = [
    \ 'obj\\',
    \ '[Tt]emp\\',
    \ '\.nuget\\',
    \ '\<AssemblyInfo\.cs\>'
    \]

"Resaltado Sintaxico/Semantico (Semantic Highlighting). Default = 1
"  (0) No hay resaltado,
"  (1) Resaltado nuevos solo se dan cuando se pasa de modo edit a normal (por defecto),
"  (3) Resaltado siempre se da, aun cuando el texto aun en modo insert
"let g:OmniSharp_highlighting = 1


"xxx
let g:OmniSharp_highlight_groups = {
\ 'ExcludedCode': 'NonText'
\}

"###################################################################################
" OmniSharp-Vim> Integración con otras componenetes externas
"###################################################################################
"
"Por defecto para selección y/o busqueda se usa el panel vim llamado 'QuickFix' (no es un popup,
"como por ejemplo un popup basado en fzf). El panel vim se puede cerrar selecionado el panel y
"usando el comando ':close'.
"A diferencia de popup, ese va al lugar y no cierra el panel automaticamente, por lo cual puede
"reusar.
"let g:OmniSharp_open_quickfix = 1

"Especificar la herramienta que se usara como selector alternativo a 'QuickFix'.
"Si 'fzf', se mostrará dentro de un popup, por lo que tiene key-mappings independiente de los
"otros modos y para salir puede usar '<ESC>'.
let g:OmniSharp_selector_ui = 'fzf'

"Personalizar las opciones de fzf
"let g:OmniSharp_fzf_options = { 'right': '50%' }

"Usar popup basado en fzf para 'Find Symbols'.
let g:OmniSharp_selector_findusages = 'fzf'

"Usar popup basado en fzf para 'Find Members'.
let g:OmniSharp_selector_findmembers = 'fzf'

"Si es '1', el completado es de un nombre de un simbolo (funcion, variable, ...) y es aceptado,
"se tratara de ejecutar el snippets por defecto asociado a este.
let g:OmniSharp_want_snippet = 0

"Si se usa un fuente de completado CoC y 'g:OmniSharp_want_snippet = 1', si el completado es un
"nombre de un simbolo y es aceptado, se ejecuta el snippets por defecto.
let g:OmniSharp_coc_snippet = 0

"Si es '1', cuando el completado es de un metodo, no se muestra los argumentos y por ende no se
"muestra una solo metodo por metodo sobrecargado. El 'g:OmniSharp_want_snippet = 0' para que
"esto esta habilitado.
let g:OmniSharp_completion_without_overloads = 1

"###################################################################################
" OmniSharp-Vim> Otros
"###################################################################################
"
"Normalizar el path de los archivos enviados por LSP server, para usar la convención de vim
"(vease 'filename-modifiers').
"let g:OmniSharp_filename_modifiers = ':.'
"let g:OmniSharp_filename_modifiers = ':p:~'
"let g:OmniSharp_filename_modifiers = 'relative'

"Busqueda la metadata de assemblies (binarios) si no se encuentra el archivo de codigo.
"Usado en ':OmniSharpGotoDefinition' y ':OmniSharpPreviewDefinition'
let g:OmniSharp_lookup_metadata = 1

"Cuando busca el tipo de un variable ('Type Lookup') es por defecto se muestra en un el status bar.
"Si desde mostrar en un popup preview establesca en 1
"let g:OmniSharp_typeLookupInPreview = 0

"Obtener y mostrar la documentación completa del servidor LSP cuando se lista los item del completado.
"Por temas de performance, solo se pide la documentación completa cuando se seleciona un simbolo
"determinado (un tipo o metodo).
"let g:omnicomplete_fetch_full_documentation = 1

"###################################################################################
" OmniSharp-Vim> Soporte a Code-actions
"###################################################################################
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
function! lsp_cs#codeactions_count() abort
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
