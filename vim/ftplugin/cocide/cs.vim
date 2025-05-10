"--------------------------------------------------------------------------------
"1. Inicialización
"--------------------------------------------------------------------------------
if !g:use_ide | finish | endif
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
nnoremap <silent> <buffer> K <Plug>(omnisharp_documentation)

"
"Popup de Vista Previa (Preview Popup)
"
" > Mostrar el 'Preview Popup'
nnoremap <silent> <buffer> <space>pd <Plug>(omnisharp_preview_definition)
nnoremap <silent> <buffer> <space>pi <Plug>(omnisharp_preview_implementations)

"
" > Mostrar el 'Signature Help'
nnoremap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)
inoremap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.2. Asociados a mostrar información (sin usar popup)
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
" > Mostrar el tipo del simbolo en la 'Barra de estado'
nnoremap <silent> <buffer> <space>ty <Plug>(omnisharp_type_lookup)

"¿?
"nnoremap <silent> <buffer> <space>hi <Plug>(omnisharp_highlight_type)


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.3. Asociados a la Navegación ('Navegation'): Ir a un 'Location' especifico.
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"

"1. 'Location' especifico dentro del buffer:
"
" > Nevegar el inicio del anterior metodo (method/property/field) o clase
nnoremap <silent> <buffer> [[ <Plug>(omnisharp_navigate_up)

" > Nevegar el inicio del siguiente metodo (method/property/field) o clase
nnoremap <silent> <buffer> ]] <Plug>(omnisharp_navigate_down)

"2. 'Location' (dentro de todo el 'workspace') basado en el simbolo actual:
"
" > Ir a la definición del simbolo actual (donde esta el prompt)
nnoremap <silent> <buffer> gd <Plug>(omnisharp_go_to_definition)

" > Ir a la implementación del simbolo actual (donde esta el prompt)
nnoremap <silent> <buffer> gi <Plug>(omnisharp_find_implementations)

" > Ir a la referencias o uso del simbolo actual (donde esta el prompt)
nnoremap <silent> <buffer> gr <Plug>(omnisharp_find_usages)

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'symbol' en el proyecto
nnoremap <silent> <buffer> <space>sw <Plug>(omnisharp_find_symbol)

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'type' en el proyecto
nnoremap <silent> <buffer> <space>lt <Plug>(omnisharp_find_type)

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'members' de las clases asociados al buffer actual
nnoremap <silent> <buffer> <space>lm <Plug>(omnisharp_find_members)

" > Listar, Selecionar e Ir a un error y/o warning en el proyecto/workspace ('Diagnostic')
"   Muestra un panel vim 'QuickFix' la cual se puede cerrar usando ':close'
nnoremap <silent> <buffer> <space>dw <Plug>(omnisharp_global_code_check)


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.4. Asociados al 'Code Formatting'
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
"Formatear el codigo del buffer actual
nnoremap <silent> <buffer> <space>cf <Plug>(omnisharp_code_format)

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.5. Asociados al 'Refactoring'
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
" > Renombrar un simbolo
nnoremap <silent> <buffer> <space>rn <Plug>(omnisharp_rename)


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.6. Asociados al 'Code Actions'
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
"1. Code Actions > All (Listar, seleccionar y ejecutar)
"   Muestra un popup fzf la cual se puede cerrar usando '[ESC]'

"   > Listar, seleccionar y ejecutar un 'Code Actions' existentes en la linea actual.
nnoremap <silent> <buffer> <space>al <Plug>(omnisharp_code_actions)

"   > Listar, seleccionar y ejecutar un 'Code Actions' existentes que aplican a un rango de codigo selecionado.
xnoremap <silent> <buffer> <space>ar <Plug>(omnisharp_code_actions)

"   > Repetir el ultima 'Code Actions' ejecutado
nnoremap <silent> <buffer> <space>a. <Plug>(omnisharp_code_action_repeat)
xnoremap <silent> <buffer> <space>a. <Plug>(omnisharp_code_action_repeat)

"3. Code Actions > Ejecutar un 'Code Fix'
"   > Acción de reparación:  Organización y/o reparar las refencias de importaciones usadas por el archivo
nnoremap <silent> <buffer> <space>oi <Plug>(omnisharp_fix_usings)



" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.7. Asociados al 'LSP Server'
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

"Restart server (Omnisharp/Roslyn)
nnoremap <silent> <buffer> <space>or <Plug>(omnisharp_restart_server)
"Start server (Omnisharp/Roslyn)
nnoremap <silent> <buffer> <space>os <Plug>(omnisharp_start_server)
"Stop/Down server (Omnisharp/Roslyn)
nnoremap <silent> <buffer> <space>od <Plug>(omnisharp_stop_server)


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2.8. Asociados al 'Unit Test'
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"
"Unit test : Build en Debug, Run en Debug hasta el prompt actual.
nnoremap <silent> <buffer> <space>dbp <Plug>(omnisharp_debug_test)
"Unit test : Run en Debug el hasta el prompt actual.
nnoremap <silent> <buffer> <space>drp <Plug>(omnisharp_debug_test_no_build)
"Unit test : Build en Release, Run en Release hasta el prompt actual.
nnoremap <silent> <buffer> <space>rbp <Plug>(omnisharp_run_test)
"Unit test : Run en Release hasta el prompt actual.
nnoremap <silent> <buffer> <space>rrp <Plug>(omnisharp_run_test_no_build)
"Unit test : Build en Release, Run en Release del File actual.
nnoremap <silent> <buffer> <space>rbf <Plug>(omnisharp_run_tests_in_file)
"Unit test : Run en Release del File actual.
nnoremap <silent> <buffer> <space>rrf <Plug>(omnisharp_run_tests_in_file_no_build)

"--------------------------------------------------------------------------------
"3. Fuente de diagnostico para ALE
"--------------------------------------------------------------------------------

"Fuente de diagnostico para C# (OmniSharp se convierte en un Linter para C#)
"let b:ale_linters = {'cs': ['OmniSharp']}

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
            execute 'autocmd' au '<buffer> call lsp_cs#codeactions_count()'
        endfor
    augroup END

    let b:undo_ftplugin .= '| execute "autocmd! csharp_ftplugin * <buffer>"'
endif

"4. Finalización
let &cpoptions = s:save_cpo
unlet s:save_cpo
