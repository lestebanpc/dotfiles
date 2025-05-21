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

" Instalar extensiones automaticamente
let g:coc_global_extensions = ['coc-json', 'coc-yaml', 'coc-xml', 'coc-html', 'coc-css', 'coc-snippets', 'coc-lightbulb', 'coc-tsserver', 'coc-pyright']

if g:os_type != 0
    " Si no es Windows
    call extend(g:coc_global_extensions, ['coc-sh'])
endif

"if !g:is_neovim
"    " Si es VIM
"    call extend(g:coc_global_extensions, ['coc-symbol-line'])
"endif

"###################################################################################
" CoC> Completition Popup (modo inserción)
"###################################################################################
"
" > Cancelar el popup y permanecar el modo inserción: '[CTRL] + e', '←', '→', '↑', '↓', 'BACKSPACE'
"   > Cierra el  popup y si la palabra cambio por alguna acción de navegación este se anula
" > Cancelar el popup y salir al modo edición: '[ESC]'
"   > Cierra el  popup y si la palabra cambio por alguna acción de navegación este se anula
"   > '<esc>' es la accion estandar
"

" Funciones que valida si el caracter anterior al prompt actual sea inicio de linea o
" un espacio (espace, tab, ..)
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
" > Desde coc.nvim >= '0.0.82', no se usa 'pumvisible()', se usa 'coc#pum#visible()'
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



"###################################################################################
" CoC> Custom Popup > Signature-help Popup, Documentation Popup, etc.
"###################################################################################
"
" Requiere nVim > '0.4.0' y Vim >= 8.3 u 8.2 con parche 'patch-8.2.0750'
"

" Navegar a la siguiente pagina: '[CTRL] + f' (solo si existe scrool en el popup)
nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"

" Navegar a la siguiente anterior: '[CTRL] + f' (solo si existe scrool en el popup)
nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"

"1. Signature-help Popup (modo inserción)
"   > Abrir automaticamente el popup: Cuando acepta el completado de un metodo
"   > Abrir manualmente el popup: Escribir ( despues del nombre de una funcion, escribir ',' dentro de ()
"   > Cerrar el popup: Si se mueva fuera de () o use '↑', '↓'


"2. Documentation Popup (modo normal)
"   Muesta la documentación definida para un simbolo (definicion, variable, ...).
"   Si no se define una documentación, se muestra solo como de define el simbolo.

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


"3. Preview Popup (modo normal)
"   Mustra parte de la definicion o implementation de un simbolo.
"   CoC no implementa este popup.
"



"###################################################################################
" CoC> LSP Client> Code Navegation > Go to Location
"###################################################################################
"
" Permite ir a una determinada ubicacion basado en el contexto actual (usualmente el word actual).
" Si encuentra mas de una opcion, muestra una lista para que puedes seleccionarlo.
"

" > Ir a la definición del simbolo actual (donde esta el prompt)
nnoremap <silent> gd <Plug>(coc-definition)

" > Ir al tipo de definición del simbolo actual (donde esta el prompt)
nnoremap <silent> gy <Plug>(coc-type-definition)

" > Ir a la implementación del simbolo actual (donde esta el prompt)
nnoremap <silent> gc <Plug>(coc-declaration)

" > Ir a la implementación del simbolo actual (donde esta el prompt)
nnoremap <silent> gi <Plug>(coc-implementation)

" > Ir a la referencias/usos del simbolo actual (donde esta el prompt)
"   Excluyendo los declaraciones del simbolo.
nnoremap <silent> gr <Plug>(coc-references)

" > Ir a la referencias o uso del simbolo actual (donde esta el prompt)
"   Excluyendo los declaraciones del simbolo.
nnoremap <silent> gu <Plug>(coc-references-used)



"###################################################################################
" CoC> LSP Client> Code Navegation > General
"###################################################################################
"
" Permite ir a una determinada ubicacion basado en el contexto actual (usualmente el word actual).
" Si encuentra mas de una opcion, muestra una lista para que puedes seleccionarlo.
"

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'symbol' en el buffer
nnoremap <silent> <space>ss :CocFzfList outline<cr>
"nnoremap <silent><nowait> <space>ss :<C-u>CocList outline<cr>

" > Listar, Selecionar (en este caso tambien buscar) e Ir a un 'symbol' en el workspace
nnoremap <silent><nowait> <space>sw  :<C-u>CocList -I symbols<cr>



"###################################################################################
" CoC> LSP Client> Selección
"###################################################################################
"
" > CoC hace de cliente LSP y consulta al servidor LSP 'textDocument.documentSymbol' el cual es el arbol de
"   objetos del buffer.
" > CoC implementa funciones para navegar este arbol de objetos del buffer.
" > No todos los servidores LSP soportan o envian 'textDocument.documentSymbol'
" > Solo definir cuando se usan en VIM. En NeoVIM se usara el arbol AST generado por Treesitter.
"

if !g:is_neovim

    " > Selección la parte interior (inner) del metodo.
    xnoremap im <Plug>(coc-funcobj-i)
    onoremap im <Plug>(coc-funcobj-i)

    " > Selección de todo (arround) el metodo.
    xnoremap am <Plug>(coc-funcobj-a)
    onoremap am <Plug>(coc-funcobj-a)

    " > Selección la parte interior (inner)  del clase.
    xnoremap ic <Plug>(coc-classobj-i)
    onoremap ic <Plug>(coc-classobj-i)

    " > Selección de todo (around) el clase.
    xnoremap ac <Plug>(coc-classobj-a)
    onoremap ac <Plug>(coc-classobj-a)

    " > Selection inteligente ('Incremental Selection' o 'Smart Selecction')

    " Iniciar la selecion y/o expandir la seleccion (expand selection)
    " > En VIM puede existir problemas en el  key-mapping usando '<c-space>', debido a que muchos terminales
    "   espera que despues CRTL exista un caracter visible, para evitar ello use '@', ello hara que vim
    "   lo trare como tecla '<space>'.
    nnoremap <silent> <C-@> <Plug>(coc-range-select)
    xnoremap <silent> <C-@> <Plug>(coc-range-select)

    " Reducir la selecion (shrink selection)
    xnoremap <silent> <bs> <Plug>(coc-range-select-backward)

endif



"###################################################################################
" CoC> LSP Client> Code Diagnostic
"###################################################################################
"
"  Un error y/o warning de codigo se mostrara usando ALE
"

" > Listar, Selecionar e Ir a un error y/o warning del workspace.
"   En CoC, se inica su popup 'Fuzzy' (no es un panel vim), la cual se cierra usando '[ESC]'.
nnoremap <silent> <space>dw  :<C-u>CocFzfList diagnostics<cr>
"nnoremap <silent><nowait> <space>dw  :<C-u>CocList diagnostics<cr>

" > Navegar en por el los diagnostico del workspace
"   Usar solos los de definidos en ALE?
"nnoremap <silent> [d <Plug>(coc-diagnostic-prev)
"nnoremap <silent> ]d <Plug>(coc-diagnostic-next)



"###################################################################################
" CoC> LSP Client > Code Formatting
"###################################################################################

"1. Formateo de una selección/buffer (Acciones personalizadas VIM)
nnoremap <silent> <space>cf :<C-u>call CocActionAsync('format')<CR>
xnoremap <space>cf  <Plug>(coc-format-selected)
"nnoremap <space>cf  <Plug>(coc-format-selected)


"2. Formateo del buffer ':Format' (Comando personalizado de VIM)
command! -nargs=0 Format :call CocActionAsync('format')



"###################################################################################
" CoC> LSP Client> Code Actions
"###################################################################################
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

" > Listar, seleccionar y ejecutar un 'Code Actions' (que no son de tipo source) existente en el cursor actual.
nnoremap <space>aa  <Plug>(coc-codeaction-cursor)

" > Listar, seleccionar y ejecutar un 'Code Actions' (que no son de tipo source) existente en la selección actual.
xnoremap <space>aa  <Plug>(coc-codeaction-selected)
"nnoremap <space>as  <Plug>(coc-codeaction-selected)

" > Listar, seleccionar y ejecutar un 'Code Actions' (que no son de tipo source) existente en la linea actual.
nnoremap <space>al  <Plug>(coc-codeaction-line)

" > Listar, seleccionar y ejecutar un 'Code Actions' de tipo 'QuickFix' existentes en ¿linea actual?
"nnoremap <space>af  <Plug>(coc-codeaction)

" > Listar, seleccionar y ejecutar un 'Code Actions' de tipo 'Refactor' existentes en cursor actual
nnoremap <space>ar  <Plug>(coc-codeaction-refactor)

" > Listar, seleccionar y ejecutar un 'Code Actions' de tipo 'Refactor' existentes en la selección actual
xnoremap <space>ar  <Plug>(coc-codeaction-refactor-selected)
"nnoremap <space>rs  <Plug>(coc-codeaction-refactor-selected)


" > Listar, seleccionar y ejecutar un 'Code Actions' de tipo 'Source'.
nnoremap <space>as  <Plug>(coc-codeaction-source)

" > Source CA > Organización y/o reparar las refencias de importaciones usadas por el archivo
"   El comando 'CocActionAsync(action_type, action_name)' permite ejecutar acciones de forma asíncrona.
"   Si el primer argumento es 'runCommand' se ejecuta un comando CoC.
nnoremap <silent> <space>oi :<C-u>call CocAction('runCommand', 'editor.action.organizeImport')<CR>
"nnoremap <silent> <space>oi :<C-u>call CocActionAsync('runCommand', 'editor.action.organizeImport')<CR>

" > QuickFix CA > Ejecutar los 'Code Actions' de tipo 'QuickFix' existentes en la linea actual
nnoremap <space>fx  <Plug>(coc-fix-current)

" > Refactor CA > Renombrar un simbolo.
nnoremap <space>rn <Plug>(coc-rename)



"###################################################################################
" CoC> LSP Client> CodeLens
"###################################################################################


" > Listas, Selecionar y Ejecutar acciones personalizadas asociadas a una linea:
nnoremap <space>cl <Plug>(coc-codelens-action)


"Do default action for next item.
"noremap <silent><nowait> <space>j  :<C-u>CocNext<CR>

"Do default action for previous item.
"nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>



"###################################################################################
" CoC> LSP Client> Otros
"###################################################################################
"

" Comandos personalizados > Command to fold current buffer.
command! -nargs=? Fold   :call CocAction('fold', <f-args>)


" Open link under cursor
nnoremap <space>ol <Plug>(coc-openlink)



"###################################################################################
" CoC> IDE> Variados
"###################################################################################

" Integración con barra de estado (Status Line)
" See ':h coc-status' for integrations con statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Manage extensions.
nnoremap <silent> <space>ee  :<C-u>CocList extensions<cr>

" Show commands.
nnoremap <silent> <space>cc  :<C-u>CocFzfList commands<cr>
"nnoremap <silent><nowait> <space>cc  :<C-u>CocList commands<cr>

" Resume latest coc list.
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
" Requiere instalar la extensión: ':CocInstall'
"

if g:has_python3

    " > El snippet siempre se muestra como parte de 'completion' (manual o automatico).
    "   Cuando se acepta el item vinculado al snippet este se expande y se inicia la navegación al
    "   1er nodo del snippet.
    " > Un snippet esta formado por 1 o mas nodos. Un nodo del snippet es un placeholder/fragmento
    "   que se permite una modificación

    "1. Mostrar los snippet en el completado asociado al cursor actual (desde el modo insert).


    " > Muestra el completado con solo snippet asociado al prompt actual.
    "inoremap <C-l> <Plug>(coc-snippets-expand)


    " > Muestra el completado con solo snippet asociado al prompt actual. Si solo existe un snippet,
    "   expande este automaticamente (se realiza el salto al primer nodo).
    inoremap <C-s> <Plug>(coc-snippets-expand-jump)

    "2. Navegar por cada nodo del snippet (placeholder/fragmento modificable del snippet):
    " > La navegación se da desde el modo insert, aunque puede volver a reiniciar la navegación desde
    "   el modo visual (se seleciona el nodo, y desde alli se puede iniciar la navegación desde ese nodo
    "   en el modo insert)
    " > Cada vez que se va aun determinado nodo, el texto del nodo se seleciona y pasa al modo 'select'
    "   (donde cualquier escritura sobrescribe su valor).

    " > Permite ir al siguiente nodo del snippets ('f' de 'follow').
    let g:coc_snippet_next="<C-f>"

    " ¿?
    "vnoremap <C-f> <Plug>(coc-snippets-select)

    " > Permite ir al anterior nodo del snippets ('b' de 'before').
    let g:coc_snippet_pre="<C-b>"


    "3. Crear un snippet
    " > Debe selecionar un texto el caul sera el nombre inicial del snippet.
    " > Mostrar un archivo para crear un snippet cuyo nombre es el mismo que el texto seleccionado.
    " > Solo si guarda se genera el snippet.
    xnoremap <space>sc  <Plug>(coc-convert-snippet)

    "4. Listar los snippets existentes para el 'filetype'.
    nnoremap <silent> <space>sn  :<C-u>CocFzfList snippets<cr>



endif
