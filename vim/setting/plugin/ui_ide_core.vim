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


let g:ale_sign_error = '•'
let g:ale_sign_warning = '•'
let g:ale_sign_info = '·'
let g:ale_sign_style_error = '·'
let g:ale_sign_style_warning = '·'

"xxxx
"let g:ale_linters_explicit = 1
"xxxx
"let g:ale_fix_on_save = 1

"###################################################################################
" Settings> IDE > Package: UltiSnippets (Framework para snippets)
"###################################################################################

if g:has_python3
    
    "Expandir el snippets (por defecto es <TAB> y entre en conflicto con el autocompletado)
    let g:UltiSnipsExpandTrigger="<C-e>"

    "Navegar entre los snippets
    let g:UltiSnipsJumpForwardTrigger="<C-b>"
    let g:UltiSnipsJumpBackwardTrigger="<C-z>"

    "Tipo de split para navegar al editar los snippets :UltiSnipsEdit
    let g:UltiSnipsEditSplit="vertical"

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
" Settings> IDE > Package: CoC > Completition
"###################################################################################

"-----------------------------------------------------------------------------------
" CoC> Completition> Generic Popup Windows
"-----------------------------------------------------------------------------------
"Definir acciones personalizadas VIM para mostrar y navegar el popup generico de completado

"Funciones usado para navegación siguente
function! CheckBackspace() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction

"Usar '[TAB]' para nevegar hacie adelente el popup generico de completado
" Siempre hay un elemento completo seleccionado de forma predeterminada. Si desea que no se
" selecione uno por defecto configurar '"suggest.noselect": true' en el archivo de configuración
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()

"Usar '[SHIFT] + [TAB]' para nevegar hacie adelente el popup generico de completado.
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

"Usar '<CR>' ('[ENTER]') para aceptar el item selecionado en popup o notificar 'Coc.nVim'
" para formatear '<C-g>u' e interrumpe el deshacer actual, haga su propia elección. 
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"


"Use '[CRTL] + [SPACE]' para iniciar el popup de completado. 
if has('nvim')
    inoremap <silent><expr> <c-space> coc#refresh()
else
    inoremap <silent><expr> <c-@> coc#refresh()
endif


"-----------------------------------------------------------------------------------
" CoC> Completition> Signature-help Popup Windows (Float Popup Windows)
"-----------------------------------------------------------------------------------
"Definir acciones personalizadas VIM para mostrar y navegar el popup flotante donde se muestra
"información como parametros o argumentos de funciones.
"Requiere nVim > '0.4.0' y Vim >= 8.3 u 8.2 con parche 'patch-8.2.0750'

"Remapear '[CTRL] + f' para navegar el siguiente, para mejorar la navegacion
nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"

"Remapear '[CTRL] + b' para navegar el anterior, para mejorar la navegacion
nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"



"###################################################################################
" Settings> IDE > Package: CoC > LSP Client
"###################################################################################

"-----------------------------------------------------------------------------------
" CoC> Comandos personalizados de VIM
"-----------------------------------------------------------------------------------

"Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')

"Add `:Fold` command to fold current buffer.
command! -nargs=? Fold   :call CocAction('fold', <f-args>)

"Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR     :call CocActionAsync('runCommand', 'editor.action.organizeImport')


"-----------------------------------------------------------------------------------
" CoC> Acciones personalizadas de VIM> Navegación
"-----------------------------------------------------------------------------------

"GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)


"-----------------------------------------------------------------------------------
" CoC> Acciones personalizadas de VIM> Seleccionar y mostrar información
"-----------------------------------------------------------------------------------

"Seleccion de una funcion o clase
"NOTE : Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)

xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)

xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)

xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)


"Use '[CTRL] + s' for selections ranges.
"NOTE : Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

"Use K to show documentation in preview window.
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

nnoremap <silent> K :call ShowDocumentation()<CR>


"-----------------------------------------------------------------------------------
" CoC> Acciones personalizadas de VIM> Code Actions
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


"-----------------------------------------------------------------------------------
" CoC> Acciones personalizadas de VIM> Otros
"-----------------------------------------------------------------------------------

"Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

"Formatting selected code.
xmap <leader>cf  <Plug>(coc-format-selected)
nmap <leader>cf  <Plug>(coc-format-selected)



"-----------------------------------------------------------------------------------
" Autocomandos (ejecutar comandos autocomandos cuando ocurre cierto tipo de evento)
"-----------------------------------------------------------------------------------

augroup mygroup

    autocmd!

    "Setup formatexpr specified filetype(s).
    autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')

    "Update signature help on jump placeholder.
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')

augroup end


"Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')


"###################################################################################
" Settings> IDE > Package: CoC > Otros
"###################################################################################

"-----------------------------------------------------------------------------------
" CoC> Autodiagnostico (Ligting)
"-----------------------------------------------------------------------------------

"Definir acciones personalizadas VIM para navegar y listar los diganosticos
"El motor de diagnostico es ALE (no se usara el existente de CoC)

"Use `[g` and `]g` to navigate diagnostics
"Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>


"-----------------------------------------------------------------------------------
" CoC> Listado de algunos opciones
"-----------------------------------------------------------------------------------

"Mappings for CoCList
"Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>

"Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>

"Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>

"Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>

"Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>

"Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>

"Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>


"-----------------------------------------------------------------------------------
" CoC> Integración con barra de estado (Status Line)
"-----------------------------------------------------------------------------------

"NOTE : See  `:h coc-status` for integrations con statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}





