"Para Neovim usar la configuracion con LSP nativo con Omnisharp Server
if g:is_neovim
    lua require('ui_ide_lsp_cs')
    finish
endif

"###################################################################################
" Settings> IDE > Package: omnisharp-vim (Pluing del Client LSP para Roslyn)
"###################################################################################

"Roslyn Server (LSP Server para C#) - Type (default: 1, stdio version)
"let g:OmniSharp_server_stdio = 1

"Roslyn Server (LSP Server para C#) - Path (Cambiar la ubicacion real)
let g:OmniSharp_server_path = g:lsp_server_cs_path 

"Roslyn Server (LSP Server para C#) - Si se usa WSL:
"  - Usar el LSP server de Windows (no requiere instalar LSP server en WSL)
"  - Las rutas de windows obtenidas de los archivo de solucion es traducida a la ruta de Linux
if g:os == "WSL"
	let g:OmniSharp_translate_cygwin_wsl = 1
else
	let g:OmniSharp_translate_cygwin_wsl = 0
endif


"Roslyn Server (LSP Server para C#) - Si se usa la version desarollado en .NET 6 (anteriormente se usaba Mono)
let g:OmniSharp_server_use_net6 = 1

"Herramienta que se usara en 'Code Actions'
let g:OmniSharp_selector_ui = 'fzf' 

"Herramienta que se usara en 'Find Symbols'
let g:OmniSharp_selector_findusages = 'fzf'

"Popup - position
let g:OmniSharp_popup_position = 'peek'

"Popup - Border del popup para VIM (por defecto no tiene borde)
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
        \ 'borderchars': ['─', ' ', '─', ' ', '╭', '╮', '╯', '╰'],
        \ 'borderhighlight': ['ModeMsg']
        \}
endif

"Popup - Personalizar el algunos key mappings que se usaran cuando aparezca un popup
let g:OmniSharp_popup_mappings = {
\ 'sigNext': '<C-n>',
\ 'sigPrev': '<C-p>',
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

"Fuente de diagnostico para C# (OmniSharp se convierte en un Linter para C#)
call extend(g:ale_linters, {'cs': ['OmniSharp'], })

"###################################################################################
" Settings> IDE > Plug-In: Vim-SharpenUp (Mappings, Code-actions para OmniSharp)
"###################################################################################

"Cambia del 'prefix' de los atajos de '\os' a ';' (os de OmniShrap)
let g:sharpenup_map_prefix = ';'

