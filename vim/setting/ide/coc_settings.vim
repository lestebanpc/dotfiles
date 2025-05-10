"
" Plugin CoC (Conquer Of Completion)
"
" Implementa :
"  - El diganostico se enviara ALE (no se usara el integrado de CoC).
"    - El formateador de codigo 'Prettier' sera proveido por ALE
"      (no se usara la extension 'coc-prettier')
"  - Se deberá instalar los adaptadores a los diferentes servidores LSP.
"  - Se integrará con el motor de snippets 'UtilSnips' (no usara el por defecto)
"
packadd coc.nvim

"
" URL : https://github.com/antoinemadec/coc-fzf
"
packadd coc-fzf


let g:coc_fzf_preview = 'down:50%'
let g:coc_fzf_opts = ['--layout=reverse']


"###################################################################################
" CoC> Built-in Popup Windows> Completition Popup Windows (modo inserción)
"###################################################################################
"


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


"###################################################################################
" CoC> Custom Popup Windows> Signature-help Popup, Documentation Popup, etc.
"###################################################################################
"Requiere nVim > '0.4.0' y Vim >= 8.3 u 8.2 con parche 'patch-8.2.0750'

"Navegar a la siguiente pagina: '[CTRL] + f' (solo si existe scrool en el popup)
nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"

"Navegar a la siguiente anterior: '[CTRL] + f' (solo si existe scrool en el popup)
nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"

"1. Signature-help Popup (modo inserción)
"
" > Abrir automaticamente el popup: Cuando acepta el completado de un metodo
" > Abrir manualmente el popup: Escribir ( despues del nombre de una funcion, escribir ',' dentro de ()
" > Cerrar el popup: Si se mueva fuera de () o use '↑', '↓'


"2. Documentation Popup (modo normal)
"
"Muesta la documentación definida para un simbolo (definicion, variable, ...).
"Si no se define una documentación, se muestra solo como de define el simbolo.

"a> Abrir manualmente el popup:
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

nnoremap <silent> K :call ShowDocumentation()<CR>

"b> Cerrar manualmente el popup: '←', '→', '↑', '↓'


"3. Preview Popup (modo normal)
"
"Mustra parte de la definicion o implementation de un simbolo.
"CoC no implementa este popup.



"###################################################################################
" CoC> LSP Client> Navegación o Ir a un 'Location' especifico.
"###################################################################################

"1. 'Location' especifico dentro del buffer:
"


"2. 'Location' (dentro de todo el 'workspace') basado en el simbolo actual:
"
"a> Ir a la definición del simbolo actual (donde esta el prompt)
nnoremap <silent> gd <Plug>(coc-definition)

"b> Ir al tipo de definición del simbolo actual (donde esta el prompt)
nnoremap <silent> gy <Plug>(coc-type-definition)

"c> Ir a la implementación del simbolo actual (donde esta el prompt)
nnoremap <silent> gc <Plug>(coc-declaration)

"d> Ir a la implementación del simbolo actual (donde esta el prompt)
nnoremap <silent> gi <Plug>(coc-implementation)

"f> Ir a la referencias/usos del simbolo actual (donde esta el prompt)
"   Excluyendo los declaraciones del simbolo.
nnoremap <silent> gr <Plug>(coc-references)

"g> Ir a la referencias o uso del simbolo actual (donde esta el prompt)
"   Excluyendo los declaraciones del simbolo.
nnoremap <silent> gu <Plug>(coc-references-used)


"h> Listar, Selecionar (en este caso tambien buscar) e Ir a un 'symbol' en el buffer
nnoremap <silent> <space>ss :CocFzfList outline<cr>
"nnoremap <silent><nowait> <space>ss :<C-u>CocList outline<cr>

"i> Listar, Selecionar (en este caso tambien buscar) e Ir a un 'symbol' en el workspace
nnoremap <silent><nowait> <space>sw  :<C-u>CocList -I symbols<cr>


"3. Diagnostico: Un error y/o warning en el proyecto ¿ALE?
"
"a> Listar, Selecionar e Ir a un error y/o warning del workspace.
"   En CoC, se inica su popup 'Fuzzy' (no es un panel vim), la cual se cierra usando '[ESC]'.
nnoremap <silent> <space>dw  :<C-u>CocFzfList diagnostics<cr>
"nnoremap <silent><nowait> <space>dw  :<C-u>CocList diagnostics<cr>

"b> Navegar en por el los diagnostico del workspace
"   Usar solos los de definidos en ALE?
"nnoremap <silent> [d <Plug>(coc-diagnostic-prev)
"nnoremap <silent> ]d <Plug>(coc-diagnostic-next)


"###################################################################################
" CoC> LSP Client> Selección
"###################################################################################
"
"NOTE : Requires 'textDocument.documentSymbol' support from the language server.
"

"1. Selección de una funcion
"
"a> Selección la parte interior del metodo.
xnoremap im <Plug>(coc-funcobj-i)
onoremap im <Plug>(coc-funcobj-i)

"b> Selección de todo el metodo.
xnoremap am <Plug>(coc-funcobj-a)
onoremap am <Plug>(coc-funcobj-a)

"2. Selección de una funcion
"
"a> Selección la parte interior del clase.
xnoremap ic <Plug>(coc-classobj-i)
onoremap ic <Plug>(coc-classobj-i)

"b> Selección de todo el clase.
xnoremap ac <Plug>(coc-classobj-a)
onoremap ac <Plug>(coc-classobj-a)

"3. Selection inteligente ('Selection Range' o 'Smart Selecction')
"   NOTE : Requires 'textDocument/selectionRange' support of language server.

"Select range forward (Expand Selection)
nnoremap <silent> <space>se <Plug>(coc-range-select)
xnoremap <silent> <space>se <Plug>(coc-range-select)

"Select range backward (Shrink Selection)
nnoremap <silent> <space>sh <Plug>(coc-range-select)
xnoremap <silent> <space>sh <Plug>(coc-range-select)


"###################################################################################
" CoC> LSP Client> Formateo de Codigo ("Code Formatting")
"###################################################################################

"1. Formateo de una selección/buffer (Acciones personalizadas VIM)
xnoremap <space>cf  <Plug>(coc-format-selected)
nnoremap <space>cf  <Plug>(coc-format-selected)


"2. Formateo del buffer ':Format' (Comando personalizado de VIM)
command! -nargs=0 Format :call CocActionAsync('format')



"###################################################################################
" CoC> LSP Client> Acciones de Codigo ('Code Actions')
"###################################################################################

"1. Code Actions > All (Listar, seleccionar y ejecutar)

"a>  Listar, seleccionar y ejecutar un 'Code Actions' existentes en del buffer actual.
nnoremap <space>ca  <Plug>(coc-codeaction)

"b> Listar, seleccionar y ejecutar un 'Code Actions' existentes en la linea actual.
nnoremap <space>al  <Plug>(coc-codeaction-line)

"c> Listar, seleccionar y ejecutar un 'Code Actions' existente en el prompt actual.
nnoremap <space>ap  <Plug>(coc-codeaction-cursor)

"d> Listar, seleccionar y ejecutar un 'Code Actions' existente que pueden aplicar a todo una region/selección actual.
xnoremap <space>ar  <Plug>(coc-codeaction-selected)
nnoremap <space>ar  <Plug>(coc-codeaction-selected)


"2. Code Actions > Refactoring (Listar, seleccionar y ejecutar)

"a> Listar, seleccionar y ejecutar un 'Refactoring' de existente en el prompt actual.
nnoremap <space>rp  <Plug>(coc-codeaction-refactor)

"b> Listar, seleccionar y ejecutar un 'Refactoring' existente que puede aplicar a todo un rango selecionado.
xnoremap <space>rr  <Plug>(coc-codeaction-refactor-selected)
nnoremap <space>rr  <Plug>(coc-codeaction-refactor-selected)

"c> Listar,  seleccionar y ejecutar un 'Refactoring' de todo el archivo (buffer).
nnoremap <space>rb  <Plug>(coc-codeaction-source)


"3. Code Actions > Ejecutar un 'Code Fix'
"
"a> Acción de reparación: Organización y/o reparar las refencias de importaciones usadas por el archivo
nnoremap <silent> <space>oi :call CocAction('organizeImport')<CR>

"b> Acción de reparación: Acción de repación rapida
nnoremap <space>fx  <Plug>(coc-fix-current)


"Do default action for next item.
"nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>

"Do default action for previous item.
"nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>


"###################################################################################
" CoC> LSP Client> Refactoring
"###################################################################################

"1. Renombrar un simbolo.
nnoremap <space>rn <Plug>(coc-rename)



"###################################################################################
" CoC> LSP Client> Otros
"###################################################################################

"1. Comandos personalizados de VIM
"Add `:Fold` command to fold current buffer.
command! -nargs=? Fold   :call CocAction('fold', <f-args>)

"Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR     :call CocActionAsync('runCommand', 'editor.action.organizeImport')

"2. Open link under cursor
nnoremap <space>ol <Plug>(coc-openlink)

"3. CodeLens: Listas, Selecionar y Ejecutar acciones personalizadas asociadas a una linea:
nnoremap <space>cl <Plug>(coc-codelens-action)

"###################################################################################
" CoC> IDE>  Integración con barra de estado (Status Line)
"###################################################################################

"NOTE : See  `:h coc-status` for integrations con statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}


"###################################################################################
" CoC> IDE> Variados
"###################################################################################

"Mappings for CoCList
"Manage extensions.
nnoremap <silent> <space>ee  :<C-u>CocList extensions<cr>

"Show commands.
nnoremap <silent> <space>cc  :<C-u>CocFzfList commands<cr>
"nnoremap <silent><nowait> <space>cc  :<C-u>CocList commands<cr>

"Resume latest coc list.
"nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>


"###################################################################################
" CoC> IDE> Autocomandos
"###################################################################################

"¿Porque no usa un autogroup?
"Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

augroup mygroup

    autocmd!

    "Setup formatexpr specified filetype(s).
    "autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')

    "Update signature help on jump placeholder.
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')

augroup end


"###################################################################################
" CoC > Extension 'coc-setting' (Framework para snippets)
"###################################################################################
"
" URL : https://github.com/neoclide/coc.nvim/wiki/Using-snippets#configure-snippets-workflow
"       https://github.com/neoclide/coc-snippets
" Requiere instalar la extensión: ':CocInstall
" coc-snippets'<Plug>(coc-snippets-expand)<Plug>(coc-snippets-expand)<Plug>(coc-snippets-expand)
"
"Los snippet son usuados en el modo edición
"

if g:has_python3

    " > El snippet siempre se muestra como parte de 'completion' (manual o automatico).
    "   Cuando se acepta el item vinculado al snippet este se expande y se inicia la navegación al
    "   1er nodo del snippet.
    " > Un snippet esta formado por 1 o mas nodos. Un nodo del snippet es un placeholder/fragmento
    "   que se permite una modificación

    "1. Expandir el snippet (desde el modo insert):
    " > Cuando se tiene un texto, al apreta <C-s>, se busca el primer snippets que coincide,
    "   si se encuentra, se expande.
    inoremap <C-l> <Plug>(coc-snippets-expand)


    "Both expand and jump (make expand higher priority.)
    inoremap <C-s> <Plug>(coc-snippets-expand-jump)

    "Mostrar un archivo para crear un snippet cuyo nombre es el mismo que el texto seleccionado.
    xnoremap <space>x  <Plug>(coc-convert-snippet)

    "2. Navegar por cada nodo del snippet (placeholder/fragmento modificable del snippet):
    " > La navegación usualmente se inicia en modo visual, aunque puede iniciar del modo visual.
    " > Cada vez que se va a un nodo pasan desde el modo 'Insert' al modo 'Select' y cualquier escritura
    "   sobrescribe su valor.

    " Permite ir al siguiente nodo del snippets ('f' de 'follow').
    let g:coc_snippet_next="<C-f>"

    " En modo visual y si el texto seleccionado es un nodo snippet, este vuelve a iniciar la navegación
    " desde el nodo ubicado (se borrar el texto selecionado e ingresa en el modo editar).
    vnoremap <C-f> <Plug>(coc-snippets-select)

    " Permite ir al anterior nodo del snippets ('b' de 'before').
    let g:coc_snippet_pre="<C-b>"


    "3. Listar los snippets existentes para el 'filetype'.
    nnoremap <silent> <space>sn  :<C-u>CocFzfList snippets<cr>


    "Plugin IDE> UltiSnips: Implementacion de Snippet para diferentes lenguajes de programacion
    packadd vim-snippets


endif
