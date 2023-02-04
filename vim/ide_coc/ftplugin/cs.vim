"--------------------------------------------------------------------------------
"1. Inicialización
"--------------------------------------------------------------------------------
if get(b:, 'csharp_ftplugin_loaded', 0) | finish | endif

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
let b:csharp_ftplugin_loaded = 1
let b:undo_ftplugin .= '| unlet b:csharp_ftplugin_loaded'

let s:save_cpo = &cpoptions
set cpoptions&vim

"--------------------------------------------------------------------------------
"2. Acciones personalizadas
"--------------------------------------------------------------------------------

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.1. Acciones asociados 'Custom Popup Windows' 
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
"Popup de Documentación (Documentation Popup)
"
" > Mostrar el 'Documentation Popup'
nmap <silent> <buffer> K <Plug>(omnisharp_documentation)


"
"Popup de Vista Previa (Preview Popup)
"
" > Mostrar el 'Preview Popup'
nmap <silent> <buffer> <Leader>pd <Plug>(omnisharp_preview_definition)
nmap <silent> <buffer> <Leader>pi <Plug>(omnisharp_preview_implementations)

"
" > Mostrar el 'Signature Help'
nmap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)
imap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.2. Asociados a mostrar información (sin usar popup)
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
" > Mostar el tipo del simbolo en la 'Barra de estado'
nmap <silent> <buffer> <Leader>ty <Plug>(omnisharp_type_lookup)

"¿?
nmap <silent> <buffer> <Leader>hi <Plug>(omnisharp_highlight_type)


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.3. Asociados a la Navegación ('Navegation')
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
"Navegación desde el simbolo actual:
"
" > Ir a la definición del simbolo actual (donde esta el prompt)
nmap <silent> <buffer> gd <Plug>(omnisharp_go_to_definition)

" > Ir a la implementación del simbolo actual (donde esta el prompt)
nmap <silent> <buffer> gi <Plug>(omnisharp_find_implementations)

" > Ir a la referencias o uso del simbolo actual (donde esta el prompt)
nmap <silent> <buffer> gr <Plug>(omnisharp_find_usages)

"
"Navegación dentro del buffer:
"
" > Nevegar el inicio del anterior method/property/field
map <silent> <buffer> [[ <Plug>(omnisharp_navigate_up)

" > Nevegar el inicio del siguiente method/property/field
map <silent> <buffer> ]] <Plug>(omnisharp_navigate_down)

"
"Busqueda, Seleccionar e Ir:
"
" > Listar, buscar e ir a un 'symbol' en el proyecto
nmap <silent> <buffer> <Leader>fs <Plug>(omnisharp_find_symbol)

" > Listar, buscar e ir a un 'type' en el proyecto
nmap <silent> <buffer> <Leader>ft <Plug>(omnisharp_find_type)

" > Listar, buscar e ir a un error y/o warning en el proyecto ('Diagnostic')
"   Muestra un panel vim 'QuickFix' la cual se puede cerrar usando ':close'
nmap <silent> <buffer> <Leader>fd <Plug>(omnisharp_global_code_check)


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.4. Asociados al 'Code Formatting'
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
"Formatear el codigo del buffer actual
nmap <silent> <buffer> <Leader>cf <Plug>(omnisharp_code_format)

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.5. Asociados al 'Refactoring'
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
" > Renombrar un simbolo
nmap <silent> <buffer> <Leader>rn <Plug>(omnisharp_rename)

" > 'Code Fix' > Eliminar las refencias de namespace no usados
nmap <silent> <buffer> <Leader>fx <Plug>(omnisharp_fix_usings)


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.6. Asociados al 'Code Actions' (o 'Quick Actions')
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
"Busqueda, Seleccionar e Ir:
" > Listar, buscar e ir a un 'symbol' en el proyecto
"   Muestra un panel vim 'Code Actions' la cual se puede cerrar usando ':close'
nmap <silent> <buffer> <Leader>fa <Plug>(omnisharp_code_actions)
xmap <silent> <buffer> <Leader>fa <Plug>(omnisharp_code_actions)

"Repetir el ultima 'Code Actions' ejecutado
nmap <silent> <buffer> <Leader>. <Plug>(omnisharp_code_action_repeat)
xmap <silent> <buffer> <Leader>. <Plug>(omnisharp_code_action_repeat)


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.7. Asociados al 'LSP Server'
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
nmap <silent> <buffer> <Leader>re <Plug>(omnisharp_restart_server)
nmap <silent> <buffer> <Leader>st <Plug>(omnisharp_start_server)
nmap <silent> <buffer> <Leader>sp <Plug>(omnisharp_stop_server)


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.8. Asociados al 'Unit Test'
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
nmap <silent> <buffer> <Leader>re <Plug>(omnisharp_run_test)
nmap <silent> <buffer> <Leader>rnt <Plug>(omnisharp_run_test_no_build)
nmap <silent> <buffer> <Leader>rat <Plug>(omnisharp_run_tests_in_file)
nmap <silent> <buffer> <Leader>rant <Plug>(omnisharp_run_tests_in_file_no_build)
nmap <silent> <buffer> <Leader>rdt <Plug>(omnisharp_debug_test)
nmap <silent> <buffer> <Leader>rdnt <Plug>(omnisharp_debug_test_no_build)

"--------------------------------------------------------------------------------
"3. Fuente de diagnostico para ALE
"--------------------------------------------------------------------------------

"Fuente de diagnostico para C# (OmniSharp se convierte en un Linter para C#)
let b:ale_linters = {'cs': ['OmniSharp']}

"--------------------------------------------------------------------------------
"4. Soporte a 'Code Actions'
"--------------------------------------------------------------------------------
if exists("g:csharp_codeactions_enable") && g:csharp_codeactions_enable

    if g:csharp_codeactions_set_signcolumn
        setlocal signcolumn=yes
        let b:undo_ftplugin .= '| setlocal signcolumn<'
    endif

    augroup csharp_ftplugin
        autocmd! * <buffer>
        for au in split(g:csharp_codeactions_autocmd, ',')
            execute 'autocmd' au '<buffer> call ui_ide_lsp_cs#codeactions_count()'
        endfor
    augroup END

    let b:undo_ftplugin .= '| execute "autocmd! csharp_ftplugin * <buffer>"'
endif

"4. Finalización
let &cpoptions = s:save_cpo
unlet s:save_cpo

