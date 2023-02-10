"Configuracion de NeoVim (usa el LSP nativo y como completado usa CMP)
if g:is_neovim && !g:use_coc_in_nvim

    lua require('ide.lsp')
    lua require('ide.completition')
    lua require('ide.diagnostic')
    lua require('ide.dap')
    "lua require('ide.others')
    lua require('ide.lsp_adapters')
    lua require('ide.dap_adapters')

    "Open a REPL / Debug-console.
    "nnoremap <Leader>dr <Cmd>lua require('dap').repl.open()<CR>
    "Re-runs the last debug adapter / configuration that ran using
    "nnoremap <Leader>dl <Cmd>lua require('dap').run_last()<CR>

    finish

endif

"###################################################################################
" Settings> IDE > Package: ALE (Diagnostic: Linting y Fixing)
"###################################################################################
"https://github.com/dense-analysis/ale/blob/master/doc/ale.txt

"Signos que se mostraran cuando se realizo el diagnostico:
let g:ale_sign_error = '✘'
let g:ale_sign_warning = '▲'
let g:ale_sign_info = ''
let g:ale_sign_style_error = ''
let g:ale_sign_style_warning = ''

"let g:ale_sign_error = '•'
"let g:ale_sign_warning = '•'
"let g:ale_sign_info = '·'
"let g:ale_sign_style_error = '·'
"let g:ale_sign_style_warning = '·'


"Por defecto se cargan todos los linter que existe de los diferentes lenguajes soportados por ALE
"Para evitar advertencia/errores innecesarios y tener un mayor control, se cargaran manualmente.
"No se cargaran todos los linter existes por lenguajes (se cargar segun lo que se requiera).
let g:ale_linters_explicit = 1

"Recomendamos evitar de definir los linter o fixers como variable global. Recomienda usar estos 
"segun la demanda, por ello usar las variable de buffer de los archivos 'filetype' del folder ftplugin.
"Es decir usar las variable 'b:ale_fixers' o 'g:ale_linters'
"let g:ale_linters = {}
"let g:ale_fixers  = {}

"Ejecutar el fixers cuando se guarda el documento (incluye el formateador de codigo 'Prettier'
"si este esta configurado para el lenguaje (es corrige errores y/o mejora formato de codigo)
let g:ale_fix_on_save = 1

"keep the sign gutter open at all times
"let g:ale_sign_column_always = 1

"Habilitar el uso del 'Virtual Text' para mostrar el diagnostico (solo a partir Vim >= 9.XX o NeoVim)
" 2 ('all    ) - Muestra el diagnostico de todas las lineas de texto.
" 1 ('current) - Muestra el diagnostico de la linea de texto actual.
" 0 ('disable) - No muestra diagnostico en 'Virtual Text'
let g:ale_virtualtext_cursor = 2

"Permitir que el diagnostico en 'Virtual Text' solo se muestre un tiempo determinado
"en ¿milisegundos? (por defecto es 10 ¿milisegundos?). 0 si se muestra siempre. 
let g:ale_virtualtext_delay = 10

"Prefijo que aparece en el diagnostico en 'Virtual Text'
"'%type%' es 'E' para error, 'W' para Warning, 'I' para Info.
"let g:ale_virtualtext_prefix = '%comment% %type%: '

"Navegar entre los diganosticos del buffer actual
" > Ir al siguiente diagnostico desde la posicion actual y dentro del buffer
nmap <silent> ]d <Plug>(ale_next)
" > Ir a la anterior diagnostico desde la posicion actual y dentro del buffer
nmap <silent> [d <Plug>(ale_previous)

"Habilitar o desabilitar el diagnostico del buffer
"nmap <silent> <Leader>dd <Plug>(ale_toggle_buffer)

"###################################################################################
" Settings> IDE > Package: UltiSnippets (Framework para snippets)
"###################################################################################
"Los snippet son usuados en el modo edición
if g:has_python3
    
    "Expandir el snippet manualmente :
    " > La mayoria de los 'Completion', cuando se acepta un item de tipo snippet, automaticamente
    "   el snippet se expande.
    " > Cuando se tiene un texto, al apreta <C-s>, se busca el primer snippets que coincide,
    "   si se encuentra, se expande.
    let g:UltiSnipsExpandTrigger="<C-s>"

    "Navegar por cada fragmento del snippet expandido. 
    " > Algunos fragmentos pasan desde el modo 'Insert' al modo 'Select' selecionando el fragmento
    "   (similar al modo visual, pero la seleccion es remplazada automaticamente cuando se escribre).
    " > Algunos fragmentos se mantiene en el modo 'Insert'.
    "
    "Ir al siguiente fragmento del Snippets ('f' de 'follow').
    let g:UltiSnipsJumpForwardTrigger="<C-f>"
    "
    "Ir al siguiente fragmento del Snippets ('b' de 'before').
    let g:UltiSnipsJumpBackwardTrigger="<C-b>"

    "Tipo de split para navegar al editar los snippets :UltiSnipsEdit
    let g:UltiSnipsEditSplit="vertical"

    "Listar los snippets existentes para el 'filetype'.
    let g:UltiSnipsListSnippets="<C-;>"

endif


"###################################################################################
" Settings> IDE > Package: CoC (Conquer Of Completion)
"###################################################################################


"-----------------------------------------------------------------------------------
" CoC> Built-in Popup Windows> Completition Popup Windows (modo inserción)
"-----------------------------------------------------------------------------------

"Funciones usado para navegación siguente
function! CheckBackspace() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction

"Abrir el popup automaticamente: En modo edicion escribir por lo menos un caracter visible
"Abrir el popup manualmente: '[CRTL] + [SPACE]'
if g:is_neovim
    inoremap <silent><expr> <c-space> coc#refresh()
else
    "En VIM puede existir problemas en el  key-mapping usando '<c-space>',
    "debido a que muchos terminales espera que despues CRTL exista un caracter
    "visible, para evitar ello use '@', ello hara que vim lo trare como tecla '<space>'
    inoremap <silent><expr> <c-@> coc#refresh()
endif

"Navegación hacia adelente: '[TAB]', '[CTRL] + n'
" > '<Tab>' abrira el popup si no existe uno abierto (siempre que exista una palabra anteponiendo al  prompt)
" > '<C-n>' es la accion estandar (este no puede abrir un popup)
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()

"Navegación hacia atras: '[SHIFT] + [TAB]', '[CTRL] + p'
" > '<C-p>' es la accion estandar.
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

"Aceptar un item seleccionado: '[ENTER]', '[CTRL] + y'
" > Ello permite completar el texto de la palabra actual del prompt y cerrar el popup
" > '<CR>' y '<C-y>' son acciones estandar
" > CoC recomienda el uso de '<CR>' que permite tambien formatear '<C-g>u' e interrumpe el deshacer actual. 
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

"Cancelar el popup y permanecar el modo inserción: '[CTRL] + e', '←', '→', '↑', '↓', 'BACKSPACE'
" > Cierra el  popup y si la palabra cambio por alguna acción de navegación este se anula

"Cancelar el popup y salir al modo edición: '[ESC]'
" > Cierra el  popup y si la palabra cambio por alguna acción de navegación este se anula
" > '<esc>' es la accion estandar


"-----------------------------------------------------------------------------------
" CoC> Custom Popup Windows> Signature-help Popup, Documentation Popup, etc.
"-----------------------------------------------------------------------------------
"Requiere nVim > '0.4.0' y Vim >= 8.3 u 8.2 con parche 'patch-8.2.0750'

"Navegar a la siguiente pagina: '[CTRL] + f' (solo si existe scrool en el popup)
nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"

"Navegar a la siguiente anterior: '[CTRL] + f' (solo si existe scrool en el popup)
nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"1. Signature-help Popup (modo inserción)
"
" > Abrir automaticamente el popup: Cuando acepta el completado de un metodo
" > Abrir manualmente el popup: Escribir ( despues del nombre de una funcion, escribir ',' dentro de ()
" > Cerrar el popup: Si se mueva fuera de () o use '↑', '↓' 


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"2. Documentation Popup (modo normal)
"
"Muesta la documentación definida para un simbolo (definicion, variable, ...).
"Si no se define una documentación, se muestra solo como de define el simbolo.

" > Abrir manualmente el popup:
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

nnoremap <silent> K :call ShowDocumentation()<CR>

" > Cerrar manualmente el popup: '←', '→', '↑', '↓'

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
"3. Preview Popup (modo normal)
"
"Mustra parte de la definicion o implementation de un simbolo.
"CoC no implementa este popup.



"-----------------------------------------------------------------------------------
" CoC> LSP Client> Navegación o Ir a un 'Location' especifico.
"-----------------------------------------------------------------------------------

"1. 'Location' especifico dentro del buffer:
"


"2. 'Location' (dentro de todo el 'workspace') basado en el simbolo actual:
"
" > Ir a la definición del simbolo actual (donde esta el prompt)
nmap <silent> gd <Plug>(coc-definition)

" > Ir al tipo de definición del simbolo actual (donde esta el prompt)
nmap <silent> gy <Plug>(coc-type-definition)

" > Ir a la implementación del simbolo actual (donde esta el prompt)
nmap <silent> gc <Plug>(coc-declaration)

" > Ir a la implementación del simbolo actual (donde esta el prompt)
nmap <silent> gi <Plug>(coc-implementation)

" > Ir a la referencias/usos del simbolo actual (donde esta el prompt)
"   Excluyendo los declaraciones del simbolo.
nmap <silent> gr <Plug>(coc-references)

" > Ir a la referencias o uso del simbolo actual (donde esta el prompt)
"   Excluyendo los declaraciones del simbolo.
nmap <silent> gu <Plug>(coc-references-used)


" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'symbol' en el buffer
nnoremap <silent><nowait> <Leader>ls :<C-u>CocList outline<cr>

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'symbol' en el workspace
nnoremap <silent><nowait> <Leader>lw  :<C-u>CocList -I symbols<cr>

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'type' en el proyecto
"nmap <silent> <buffer> <Leader>lt <Plug>(omnisharp_find_type)

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'members' de las clases asociados al buffer actual
"nmap <silent> <buffer> <Leader>lm <Plug>(omnisharp_find_members)


" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
" > Diagnostico: Un error y/o warning en el proyecto
"
" > Listar, Selecionar e Ir a un error y/o warning del workspace.
"   En CoC, se inica su popup 'Fuzzy' (no es un panel vim), la cual se cierra usando '[ESC]'.
nnoremap <silent><nowait> <Leader>ld  :<C-u>CocList diagnostics<cr>

" > Navegar en por el los diagnostico del workspace
"   Usar solos los de definidos en ALE?
"nmap <silent> [d <Plug>(coc-diagnostic-prev)
"nmap <silent> ]d <Plug>(coc-diagnostic-next)


"-----------------------------------------------------------------------------------
" CoC> LSP Client> Selección
"-----------------------------------------------------------------------------------
"NOTE : Requires 'textDocument.documentSymbol' support from the language server.

"1. Selección de una funcion
"
" > Selección la parte interior del metodo.
xmap im <Plug>(coc-funcobj-i)
omap im <Plug>(coc-funcobj-i)

" > Selección de todo el metodo.
xmap am <Plug>(coc-funcobj-a)
omap am <Plug>(coc-funcobj-a)

"2. Selección de una funcion
"
" > Selección la parte interior del clase.
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)

" > Selección de todo el clase.
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

"3. Selection inteligente ('Selection Range' o 'Smart Selecction')
"   NOTE : Requires 'textDocument/selectionRange' support of language server.

"Select range forward (Expand Selection)
nmap <silent> <Leader>se <Plug>(coc-range-select)
xmap <silent> <Leader>se <Plug>(coc-range-select)

"Select range backward (Shrink Selection)
nmap <silent> <Leader>ss <Plug>(coc-range-select)
xmap <silent> <Leader>ss <Plug>(coc-range-select)


"-----------------------------------------------------------------------------------
" CoC> LSP Client> Formateo de Codigo ("Code Formatting")
"-----------------------------------------------------------------------------------

"1. Formateo de una selección/buffer (Acciones personalizadas VIM)
xmap <Leader>cf  <Plug>(coc-format-selected)
nmap <Leader>cf  <Plug>(coc-format-selected)


"2. Formateo del buffer ':Format' (Comando personalizado de VIM)
command! -nargs=0 Format :call CocActionAsync('format')



"-----------------------------------------------------------------------------------
" CoC> LSP Client> Acciones de Codigo ('Code Actions')
"-----------------------------------------------------------------------------------

"1. Code Actions > All (Listar, seleccionar y ejecutar)
"   >  Listar, seleccionar y ejecutar un 'Code Actions' existentes en del buffer actual.
nmap <Leader>ab  <Plug>(coc-codeaction)

"   > Listar, seleccionar y ejecutar un 'Code Actions' existentes en la linea actual.
nmap <Leader>al  <Plug>(coc-codeaction-line)

"   > Listar, seleccionar y ejecutar un 'Code Actions' existente en el prompt actual.
nmap <Leader>ap  <Plug>(coc-codeaction-cursor)

"   > Listar, seleccionar y ejecutar un 'Code Actions' existente que pueden aplicar a todo una region/selección actual.
xmap <Leader>ar  <Plug>(coc-codeaction-selected)
nmap <Leader>ar  <Plug>(coc-codeaction-selected)


"2. Code Actions > Refactoring (Listar, seleccionar y ejecutar)
"   > Listar, seleccionar y ejecutar un 'Refactoring' de existente en el prompt actual.
nmap <Leader>rp  <Plug>(coc-codeaction-refactor)

"  > Listar, seleccionar y ejecutar un 'Refactoring' existente que puede aplicar a todo un rango selecionado.
xmap <Leader>rr  <Plug>(coc-codeaction-refactor-selected)
nmap <Leader>rr  <Plug>(coc-codeaction-refactor-selected)

"  > Listar,  seleccionar y ejecutar un 'Refactoring' de todo el archivo (buffer).
nmap <Leader>rb  <Plug>(coc-codeaction-source)


"3. Code Actions > Ejecutar un 'Code Fix'
"   > Acción de reparación: Organización y/o reparar las refencias de importaciones usadas por el archivo
nnoremap <silent> fi :call CocAction('organizeImport')<CR>

"   > Acción de reparación: Acción de repación rapida
nmap <Leader>fx  <Plug>(coc-fix-current)


"Do default action for next item.
"nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>

"Do default action for previous item.
"nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>


"-----------------------------------------------------------------------------------
" CoC> LSP Client> Refactoring
"-----------------------------------------------------------------------------------

"1. Renombrar un simbolo.
nmap <Leader>rn <Plug>(coc-rename)



"-----------------------------------------------------------------------------------
" CoC> LSP Client> Autocomandos 
"-----------------------------------------------------------------------------------
"Ejecutar comandos autocomandos cuando ocurre cierto tipo de evento

"
augroup mygroup

    autocmd!

    "Setup formatexpr specified filetype(s).
    "autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')

    "Update signature help on jump placeholder.
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')

augroup end


"Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')


"-----------------------------------------------------------------------------------
" CoC> LSP Client> Otros 
"-----------------------------------------------------------------------------------

"1. Comandos personalizados de VIM
"Add `:Fold` command to fold current buffer.
command! -nargs=? Fold   :call CocAction('fold', <f-args>)

"Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR     :call CocActionAsync('runCommand', 'editor.action.organizeImport')

"2. Open link under cursor
nmap <Leader>ol <Plug>(coc-openlink)

"3. CodeLens: Listas, Selecionar y Ejecutar acciones personalizadas asociadas a una linea:
nmap <Leader>cl <Plug>(coc-codelens-action)

"-----------------------------------------------------------------------------------
" CoC> IDE>  Integración con barra de estado (Status Line)
"-----------------------------------------------------------------------------------

"NOTE : See  `:h coc-status` for integrations con statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}


"-----------------------------------------------------------------------------------
" CoC> IDE> Variados
"-----------------------------------------------------------------------------------

"Mappings for CoCList
"Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>

"Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>

"Resume latest coc list.
"nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>


"###################################################################################
" Settings> IDE > Package: DAP Client (Adaptadores de DAP clientes y el Graphical Debugger)
"###################################################################################

if g:has_python3
   
    "Key-mappings adicionales al por defecto (se usa 'HUMAM')
    nnoremap <Leader><F4> :call vimspector#Reset()<CR>

    "nnoremap <Leader>dd :call vimspector#Launch()<CR>
    "nnoremap <Leader>dc :call vimspector#Continue()<CR>
    "nnoremap <Leader>dt :call vimspector#ToggleBreakpoint()<CR>
    "nnoremap <Leader>dT :call vimspector#ClearBreakpoints()<CR>
    "nmap <Leader>dk <Plug>VimspectorRestart
    "nmap <Leader>dh <Plug>VimspectorStepOut
    "nmap <Leader>dl <Plug>VimspectorStepInto
    "nmap <Leader>dj <Plug>VimspectorStepOver

endif



