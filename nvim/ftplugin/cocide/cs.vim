"
" Inicialización
"
if !g:use_ide || !get(g:use_lsp_adapters, "omnisharp_vim", v:false)
    finish
endif

if get(b:, 'csharp_ftplugin_loaded', 0) | finish | endif

" Variables relevantes
let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
let b:csharp_ftplugin_loaded = 1
let b:undo_ftplugin .= '| unlet b:csharp_ftplugin_loaded'

let s:save_cpo = &cpoptions
set cpoptions&vim

" Disable el lightbulb de CoC para este archivo
let b:coc_lightbulb_disable = 1

"--------------------------------------------------------------------------------
" Omnisharp > Keymapping > Popup Windows
"--------------------------------------------------------------------------------
"
" Popup de Documentación (Documentation Popup)
" > Mostrar el 'Documentation Popup'
nnoremap <silent> <buffer> K <Plug>(omnisharp_documentation)

"
" Popup de Vista Previa (Preview Popup)
" > Mostrar el 'Preview Popup'
nnoremap <silent> <buffer> <space>pd <Plug>(omnisharp_preview_definition)
nnoremap <silent> <buffer> <space>pi <Plug>(omnisharp_preview_implementations)

" Popup de Signature Help
" > Mostrar el 'Signature Help'
nnoremap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)
inoremap <silent> <buffer> <C-\> <Plug>(omnisharp_signature_help)



"--------------------------------------------------------------------------------
" Omnisharp > Keymapping > Mostrar información sin usar popup
"--------------------------------------------------------------------------------
"
" > Mostrar el tipo del simbolo en la 'Barra de estado'
nnoremap <silent> <buffer> <space>ty <Plug>(omnisharp_type_lookup)

" ¿?
"nnoremap <silent> <buffer> <space>hi <Plug>(omnisharp_highlight_type)



"--------------------------------------------------------------------------------
" Omnisharp > Keymapping > Code Navigation > Go to 'Location'
"--------------------------------------------------------------------------------
"
" Permite ir a una determinada ubicacion basado en el contexto actual (usualmente el word actual).
" Si encuentra mas de una opcion, muestra una lista para que puedes seleccionarlo.
"

" > Ir a la definición del simbolo actual (donde esta el prompt)
"   'Location' (dentro de todo el 'workspace') basado en el simbolo actual:
nnoremap <silent> <buffer> gd <Plug>(omnisharp_go_to_definition)

" > Ir a la implementación del simbolo actual (donde esta el prompt)
"   'Location' (dentro de todo el 'workspace') basado en el simbolo actual:
nnoremap <silent> <buffer> gi <Plug>(omnisharp_find_implementations)

" > Ir a la referencias o uso del simbolo actual (donde esta el prompt)
"   'Location' (dentro de todo el 'workspace') basado en el simbolo actual:
nnoremap <silent> <buffer> gr <Plug>(omnisharp_find_usages)

" > Nevegar el inicio del anterior metodo (method/property/field) o clase
"   'Location' especifico dentro del buffer:
nnoremap <silent> <buffer> [[ <Plug>(omnisharp_navigate_up)

" > Nevegar el inicio del siguiente metodo (method/property/field) o clase
"   'Location' especifico dentro del buffer:
nnoremap <silent> <buffer> ]] <Plug>(omnisharp_navigate_down)


"--------------------------------------------------------------------------------
" Omnisharp > Keymapping > Code Navigation > General
"--------------------------------------------------------------------------------
"
" Busca un objeto del buffer o workspace, permite listarlo y su selección para ir a su ubicacion
"

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'symbol' en el proyecto
nnoremap <silent> <buffer> <space>sw <Plug>(omnisharp_find_symbol)

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'type' en el proyecto
nnoremap <silent> <buffer> <space>lt <Plug>(omnisharp_find_type)

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'members' de las clases asociados al buffer actual
nnoremap <silent> <buffer> <space>lm <Plug>(omnisharp_find_members)


"--------------------------------------------------------------------------------
" Omnisharp > Keymapping > Code Diagnostic
"--------------------------------------------------------------------------------
"
" > Listar, Selecionar e Ir a un error y/o warning en el proyecto/workspace ('Diagnostic')
"   Muestra un panel vim 'QuickFix' la cual se puede cerrar usando ':close'
nnoremap <silent> <buffer> <space>dw <Plug>(omnisharp_global_code_check)



"--------------------------------------------------------------------------------
" Omnisharp > Keymapping > Code Formatting
"--------------------------------------------------------------------------------
"
" > Formatear el codigo del buffer actual
nnoremap <silent> <buffer> <space>cf <Plug>(omnisharp_code_format)


"--------------------------------------------------------------------------------
" Omnisharp > Keymapping > Code Actions > Generales
"--------------------------------------------------------------------------------
"
" Los 'Code Actions' puede ser
" > 'Code Action' asociado a objeto de codigo del documento (buffer).
"   > Estas puede ser :
"     > Refactor
"       Acciones de organizacion de codigo, producto de un analisis del arbol sinstanctico, que usualmente
"       requiere parametros ingresados por el usuario.
"       Ejemplos comunes:
"       > refactor.extract
"         Extraer código (por ejemplo, a una función o variable)
"       > refactor.inline
"         Reemplazar el uso de una variable o función con su contenido.
"       > refactor.rewrite
"         Reescrituras más profundas del código (como cambiar la estructura de control).
"     > Quick Fix
"       Acciones simples generados por un diagnostico de codigo que lo corrigen y no requiere parametros
"       ingresadas por el usuario para su ejecucion.
"   > El cliente LSP envía al servidor LSP el rango y este devuelve todos las acciones sobre los diferentes objetos
"     que están en ese rango del documento.
"     El rango del documento es:
"     > En el modo visual, es el rango visual (La acciones son sobre los diferentes objetos que estan en la
"       selección actual).
"     > En el normal, es la posición del cursor (La acciones son sobre la objeto donde esta el cursor actual).
" > 'Source' que son acciones de codigo asociados a todos el documento (buffer).
"    Ejemplos comunes:
"    > source.organizeImports
"      Reordenar, eliminar o añadir imports automáticamente.
"    > source.removeUnused
"      Eliminar código no utilizado (variables, imports, etc.).
"    > source.addMissingImports
"      Añadir imports faltantes automáticamente.
"    > source.sortImports
"      Ordenar imports (alfabéticamente o según estilo de proyecto).
"

" > Listar, seleccionar y ejecutar un 'Code Actions' existentes en el cursor actual.
"   Muestra un popup fzf la cual se puede cerrar usando '[ESC]'
nnoremap <silent> <buffer> <space>aa <Plug>(omnisharp_code_actions)

" > Listar, seleccionar y ejecutar un 'Code Actions' existentes que aplican a un rango de codigo selecionado.
"   Muestra un popup fzf la cual se puede cerrar usando '[ESC]'
xnoremap <silent> <buffer> <space>aa <Plug>(omnisharp_code_actions)

" > QuickFix > Repetir el ultima 'Quick Fix' ejecutado
nnoremap <silent> <buffer> <space>q. <Plug>(omnisharp_code_action_repeat)

" > Refactor > Renombrar un simbolo
nnoremap <silent> <buffer> <space>rn <Plug>(omnisharp_rename)

" > Source > Organización y/o reparar las refencias de importaciones usadas por el archivo
nnoremap <silent> <buffer> <space>oi <Plug>(omnisharp_fix_usings)



"--------------------------------------------------------------------------------
" Omnisharp > Gestion del LSP Server
"--------------------------------------------------------------------------------
"

" Restart server (Omnisharp/Roslyn)
nnoremap <silent> <buffer> <space>rs <Plug>(omnisharp_restart_server)

" Start server (Omnisharp/Roslyn)
nnoremap <silent> <buffer> <space>sa <Plug>(omnisharp_start_server)

" Stop/Down server (Omnisharp/Roslyn)
nnoremap <silent> <buffer> <space>so <Plug>(omnisharp_stop_server)



"--------------------------------------------------------------------------------
" Omnisharp > Keymapping > Unit Test (ejecuta en terminal o background process)
"--------------------------------------------------------------------------------
"
" Test nearest method (ejecuta el unit test asociado al metodo cercano al cursor actual).
nnoremap <silent> <buffer> <space>tm <Plug>(omnisharp_run_test_no_build)

" Test nearest method (ejecuta el unit test asociado al metodo cercano al cursor actual) realizando el building antes.
"nnoremap <silent> <buffer> <space>tmb <Plug>(omnisharp_run_test)

" Test (todo los metodos de) un archivo actual.
nnoremap <silent> <buffer> <space>tf <Plug>(omnisharp_run_tests_in_file_no_build)

" Test (todo los metodos de) un archivo actual, realizando un building antes
"nnoremap <silent> <buffer> <space>tfb <Plug>(omnisharp_run_tests_in_file)



"--------------------------------------------------------------------------------
" Omnisharp > Keymapping > Unit Test ejecutado sobre Debugger UI
"--------------------------------------------------------------------------------
"
" Depende de Vimspector
"
" Similar a 'Run to cursor' de Vimspector pero asociado a Unit Test.
nnoremap <silent> <buffer> <space>td <Plug>(omnisharp_debug_test_no_build)

" Similar a 'Run to cursor' de Vimspector, pero asociado a Unit Test y realiza un build antes.
"nnoremap <silent> <buffer> <space>tdb <Plug>(omnisharp_debug_test)



"--------------------------------------------------------------------------------
" Omnisharp > Code Actions > Mostrar Lightbulb
"--------------------------------------------------------------------------------
"
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



"--------------------------------------------------------------------------------
" Omnisharp > Keymapping para UltiSnips
"--------------------------------------------------------------------------------
"
" Keymapping para el framework de snippet UltiSnips
if g:has_python3

    " > Muestra el completado con solo snippet asociado al prompt actual. Si solo existe un snippet,
    "   expande este automaticamente.
    inoremap <buffer> <C-s>   <C-R>=UltiSnips#ExpandSnippet()<CR>

    "2. Navegar por cada nodo del snippet (placeholder modificable del snippet):

    " > Permite ir al siguiente nodo del snippets ('f' de 'follow').
    " > Reinicar la navegación de un snippet desde un nodo seleccionado.
    inoremap <buffer> <silent> <C-f> <C-R>=UltiSnips#JumpForwards()<cr>
    snoremap <buffer> <silent> <C-f> <Esc>:call UltiSnips#JumpForwards()<cr>

    " > Permite ir al anterior nodo del snippets ('b' de 'before').
    inoremap <buffer> <silent> <C-b> <C-R>=UltiSnips#JumpBackwards()<cr>
    snoremap <buffer> <silent> <C-b> <Esc>:call UltiSnips#JumpBackwards()<cr>


    "4. Listar los snippets existentes para el 'filetype'.
    "inoremap <buffer> <space>sn :UltiSnipsListAvailable<CR>

endif



"
" Finalización
"
let &cpoptions = s:save_cpo
unlet s:save_cpo
