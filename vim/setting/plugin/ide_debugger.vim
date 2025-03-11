"###################################################################################
" IDE> Configuracion exclusivas para NeoVim si usa CoC
"###################################################################################
"
if g:is_neovim && !g:use_coc_in_nvim

    "Package IDE> Depurador (Cliente DAP y los adaptadores depuracion)
    packadd nvim-dap

    "Package IDE> A library for asynchronous IO in Neovim
    packadd nvim-nio

    "Package IDE> DAP> Mejora de UI para nVim-DAP
    packadd nvim-dap-ui

    "Package IDE> DAP> Mejora de UI para nVim-DAP
    packadd nvim-dap-virtual-text

    lua require('ide.debugger')

    "Solo continuar si se usa NeoVim para CoC
    finish

endif


"###################################################################################
" IDE > DAP Client (Adaptadores de DAP clientes y el Graphical Debugger)
"###################################################################################

if g:has_python3
   
    "Habilitar el tipo de key-mapping por defecto de tipo 'HUMAN'
    let g:vimspector_enable_mappings = 'HUMAN'
    "let g:vimspector_enable_mappings = 'VISUAL_STUDIO'
    
    "Package UI> IDE> Core> Graphical Debugger
    packadd vimspector

    "Key-mappings adicionales al por defecto (se usa 'HUMAM')
    nnoremap <Leader><F4> :call vimspector#Reset()<CR>

    "nmap <F5>         <Plug>VimspectorContinue
    "nmap <leader><F5> <Plug>VimspectorLaunch
    "nmap <F3>         <Plug>VimspectorStop
    "nmap <F4>         <Plug>VimspectorRestart
    "nmap <F6>         <Plug>VimspectorPause
    "nmap <F9>         <Plug>VimspectorToggleBreakpoint
    "nmap <leader><F9> <Plug>VimspectorToggleConditionalBreakpoint
    "nmap <F8>         <Plug>VimspectorAddFunctionBreakpoint
    "nmap <leader><F8> <Plug>VimspectorRunToCursor
    "nmap <F10>        <Plug>VimspectorStepOver
    "nmap <F11>        <Plug>VimspectorStepInto
    "nmap <F12>        <Plug>VimspectorStepOut

endif


"###################################################################################
" IDE> Configuracion exclusivas para NeoVim si usa CoC
"###################################################################################
"
"if g:is_neovim
"
"    lua require('ide.debugger')
"
"endif




