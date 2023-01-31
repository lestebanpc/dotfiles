"Configuracion de NeoVim (usa el LSP nativo y como completado usa CMP)
if g:is_neovim && !g:use_coc_in_nvim

    lua require('ui_ide_core')


    "Settings> IDE > Package: DAP Client (Adaptadores de DAP clientes y el Graphical Debugger)
    "
    nnoremap <F5>          <Cmd>lua require('dap').continue()<CR>
    nnoremap <Leader><F4>  <Cmd>lua require('dap').terminate()<CR>

    nnoremap <F9>          <Cmd>lua require('dap').toggle_breakpoint()<CR>
    nnoremap <Leader><F9>  <Cmd>lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>
    "noremap <Leader>lp    <Cmd>lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>

    "Continues execution to the current cursor.
    nnoremap <Leader><F8>  <Cmd>lua require('dap').run_to_cursor()<CR>
    nnoremap <F10>         <Cmd>lua require('dap').step_over()<CR>
    nnoremap <F11>         <Cmd>lua require('dap').step_into()<CR>
    nnoremap <F12>         <Cmd>lua require('dap').step_out()<CR>

    "Open a REPL / Debug-console.
    "nnoremap <Leader>dr <Cmd>lua require('dap').repl.open()<CR>
    "Re-runs the last debug adapter / configuration that ran using
    "nnoremap <Leader>dl <Cmd>lua require('dap').run_last()<CR>

    finish

endif

"###################################################################################
" Settings> IDE > Package: ALE (Diagnostic: Linting y Fixing)
"###################################################################################

"Signos que se mostraran cuando se realizo el diagnostico:
let g:ale_sign_error = ''
"let g:ale_sign_error = '•'
let g:ale_sign_warning = ''
"let g:ale_sign_warning = '•'
let g:ale_sign_info = '·'
"let g:ale_sign_info = '·'
let g:ale_sign_style_error = ''
"let g:ale_sign_style_error = '·'
let g:ale_sign_style_warning = ''
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
let g:ale_sign_column_always = 1

"###################################################################################
" Settings> IDE > Package: UltiSnippets (Framework para snippets)
"###################################################################################

if g:has_python3
    
    "Expandir el snippet (por defecto es <TAB> y entre en conflicto con el autocompletado)
    let g:UltiSnipsExpandTrigger="<C-s>"

    "Navegar por cada fragmento del snippet expandido.
    "Saltar hacia adelante y salte hacia atrás dentro de un fragmento.
    let g:UltiSnipsJumpForwardTrigger="<C-a>"
    let g:UltiSnipsJumpBackwardTrigger="<C-z>"

    "Tipo de split para navegar al editar los snippets :UltiSnipsEdit
    let g:UltiSnipsEditSplit="vertical"

    "let g:UltiSnipsListSnippets="<C-tab>"

"endif

"###################################################################################
" Settings> IDE > Package: DAP Client (Adaptadores de DAP clientes y el Graphical Debugger)
"###################################################################################

"if g:has_python3
   
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
" CoC> LSP Client> Navegación (Acciones personalizadas de VIM)
"-----------------------------------------------------------------------------------

"1. Navegación> Desde el simbolo actual hacia su ...
"
" > Ir a la definición del simbolo actual
nmap <silent> gd <Plug>(coc-definition)

" > Ir al tipo de definición del simbolo actual
nmap <silent> gy <Plug>(coc-type-definition)

" > Ir a la implementación del simbolo actual
nmap <silent> gi <Plug>(coc-implementation)

" > Ir a la referencias/usos del simbolo actual
nmap <silent> gr <Plug>(coc-references)


"2. Busqueda, Selección e Ir
"
" > Listar, buscar e ir a un 'symbol' en el documento.
nnoremap <silent><nowait> <Leader>fs :<C-u>CocList outline<cr>

" > Listar, buscar e ir a un 'symbol' del workspace.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>


"-----------------------------------------------------------------------------------
" CoC> LSP Client> Selección (Acciones personalizadas de VIM)
"-----------------------------------------------------------------------------------
"NOTE : Requires 'textDocument.documentSymbol' support from the language server.

"1. Selección de una funcion
"
" > Selección la parte interior del metodo.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)

" > Selección de todo el metodo.
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)

"2. Selección de una funcion
"
" > Selección la parte interior del clase.
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)

" > Selección de todo el clase.
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)


"Use '[CTRL] + s' for selections ranges.
"NOTE : Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)


"-----------------------------------------------------------------------------------
" CoC> LSP Client> Formateo de Codigo ("Code Formatting")
"-----------------------------------------------------------------------------------

"1. Formateo de una selección/buffer (Acciones personalizadas VIM)
xmap <leader>cf  <Plug>(coc-format-selected)
nmap <leader>cf  <Plug>(coc-format-selected)


"2. Formateo del buffer ':Format' (Comando personalizado de VIM)
command! -nargs=0 Format :call CocActionAsync('format')


"-----------------------------------------------------------------------------------
" CoC> LSP Client> Diagnostico (incluyendo Ligting)
"-----------------------------------------------------------------------------------
"¿Usar los metodos de navegación de ALE o solo de CoC?

"1. Listar, buscar e ir a un error y/o warning del workspace.
"   En CoC, se inica su popup 'Fuzzy' (no es un panel vim), la cual se cierra usando '[ESC]'.
nnoremap <silent><nowait> <Leader>fd  :<C-u>CocList diagnostics<cr>

"2. Navegar en por el los diagnostico del workspace
nmap <silent> [d <Plug>(coc-diagnostic-prev)
nmap <silent> ]d <Plug>(coc-diagnostic-next)


"-----------------------------------------------------------------------------------
" CoC> LSP Client> Acciones de Codigo ('Code Actions')
"-----------------------------------------------------------------------------------

"Applying codeAction to the selected region.
xmap <leader>as  <Plug>(coc-codeaction-selected)
nmap <leader>as  <Plug>(coc-codeaction-selected)

"Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)

"Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

"Run the Code Lens action on the current line.
nmap <leader>cl  <Plug>(coc-codelens-action)

"Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>

"Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>


"-----------------------------------------------------------------------------------
" CoC> LSP Client> Refactoring
"-----------------------------------------------------------------------------------

"1. Renombrar un simbolo.
nmap <leader>rn <Plug>(coc-rename)



"-----------------------------------------------------------------------------------
" CoC> LSP Client> Autocomandos 
"-----------------------------------------------------------------------------------
"Ejecutar comandos autocomandos cuando ocurre cierto tipo de evento

"
augroup mygroup

    autocmd!

    "Setup formatexpr specified filetype(s).
    autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')

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
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>





