"###################################################################################
" Mappings> General
"###################################################################################

"Usando como Key Leader
let mapleader=','

"Usando como Key Local Leader: '\', '[SPACE]'
let maplocalleader = "\\"
"let maplocalleader = "\<Space>"

"Search mappings: These will make it so that going to the next one in a search will center on the line it's found in.
nnoremap n nzzzv
nnoremap N Nzzzv

"----------------------------- Apariencia              -----------------------------

"Habilitar/Desabiliar la linea de resaltado ('Highlight Line') Horizonal
nnoremap <Leader>hh :set cursorline!<CR>

"Habilitar/Desabiliar la linea de resaltado ('Highlight Line') Vertical
nnoremap <Leader>vv :set cursorcolumn!<CR>

"----------------------------- Portapapeles            -----------------------------
"
"NeoVIM no interactua directamente con el clipboard del SO (no usa API del SO) y tiene una Integracion
"nativa con:
" > Usa el caracter de escape OSC 52 para enviar texto a la terminal, para que este lo interprete y escriba
"   al portapales del SO de la terminal.
" > Usa comandos externos de gestion de clipboard (backend de clipboard) las cuales registra a eventos de
"   establecer texto en registro de yank de VIM.
"   
"VIM puede interactuar directamente con el clipboard del SO (usa el API del SO para ello)
"La instegracion con comandos externos de gestion de clipboard y OSC 52, no lo hace de forma nativa.
"


"Si se requiere usar OSC 52
if g:set_clipboard_type == 1

    runtime setting/utils/osc52.vim

    "Copiar el registro al clipboard (tener en cuenta que el evento 'TextYankPost' solo se invoca de manera interativa)
    nnoremap <Leader>c" :<C-u>call PutClipboard(g:osc52_format, getreg('@"'))<CR>
    nnoremap <Leader>c0 :<C-u>call PutClipboard(g:osc52_format, getreg('@0'))<CR>
    nnoremap <Leader>c1 :<C-u>call PutClipboard(g:osc52_format, getreg('@1'))<CR>
    nnoremap <Leader>c2 :<C-u>call PutClipboard(g:osc52_format, getreg('@2'))<CR>
    nnoremap <Leader>c3 :<C-u>call PutClipboard(g:osc52_format, getreg('@3'))<CR>
    
    "Copiar las lineas seleccionadas al portapapeles ('CLIPBOARD' selection)
    "vnoremap <Leader>cl :w !g:clipboard_command<CR><CR>

    "Opciones que usan el plugion
    "nmap <leader>c <Plug>OSCYankOperator
    "nmap <leader>cc <leader>c_
    "vmap <leader>c <Plug>OSCYankVisual

    "let s:VimOSCYankPostRegisters = ['', '+', '*']
    "function! s:VimOSCYankPostCallback(event)
    "    if a:event.operator == 'y' && index(s:VimOSCYankPostRegisters, a:event.regname) != -1
    "        call OSCYankRegister(a:event.regname)
    "    endif
    "endfunction

    "Habilitar el envio automatico, al clipboard, del ultimo yank realizado.
    augroup VimYank
        autocmd!
        "autocmd TextYankPost * call s:VimOSCYankPostCallback(v:event)
        autocmd TextYankPost * call PutClipboard(g:osc52_format, getreg('"'))
        "autocmd TextYankPost * if v:event.operator ==# 'y' | silent! call OSCYankRegister('') | endif
    augroup END


"Si se requiere usar comandos externos de gestion de clicomandos externos de `gestion de clipboardd
elseif g:set_clipboard_type == 2

    if g:clipboard_command == ''

        "No se puede establecer el mecanismo solicitado
        let g:set_clipboard_type = 9
        echo 'Not exist clipboard backend'

    else

        "Copiar el ultimo delete realizado al portapapeles ('CLIPBOARD' selection)
        nnoremap <Leader>c1 :<C-u>call system(g:clipboard_command, @1)<CR>
    
        "Copiar las lineas seleccionadas al portapapeles ('CLIPBOARD' selection)
        "vnoremap <Leader>cl :w !g:clipboard_command<CR><CR>

        "Habilitar el envio automatico, al clipboard, del ultimo yank realizado.
        augroup VimYank
            autocmd!
            autocmd TextYankPost * if v:event.operator ==# 'y' | silent! call system(g:clipboard_command, @") | endif
        augroup END
    
    
        "Si es WSL2, habilitar el envio automatico, al clipboard del SO Windows, del ultimo yank realizado.
        "  En WSL2, el portapapeles de Linux WSL2 es diferente al de Windows. Por tal motivo cuando se usa VIM/NeoVIM dentro de WSL2,
        "  se requiere que aparte de copiar el buffer del yank al portapapeles de Linux, se usara requiere tambien copiarlo a Windows 
        "  para poderlo ver desde cualquier aplicacion windows.
        if g:os_type == 3
        
            "Copia cualquier yank que esta en el registro " (por defecto) se copia al portapales del SO
            augroup WslYank
                autocmd!
                autocmd TextYankPost * if v:event.operator ==# 'y' | silent! call system('/mnt/c/windows/system32/clip.exe ',@") | endif
            augroup END
    
        endif

    endif

elseif g:set_clipboard_type != 9

    if g:clipboard_command != ''

        "Copiar el registro al clipboard (tener en cuenta que el evento 'TextYankPost' solo se invoca de manera interativa)
        nnoremap <Leader>c" :<C-u>call system(g:clipboard_command, @")<CR>
        nnoremap <Leader>c0 :<C-u>call system(g:clipboard_command, @0)<CR>
        nnoremap <Leader>c1 :<C-u>call system(g:clipboard_command, @1)<CR>
        nnoremap <Leader>c2 :<C-u>call system(g:clipboard_command, @2)<CR>
        nnoremap <Leader>c3 :<C-u>call system(g:clipboard_command, @3)<CR>
    
        "Copiar las lineas seleccionadas al portapapeles ('CLIPBOARD' selection)
        "vnoremap <Leader>cl :w !g:clipboard_command<CR><CR>

    endif

endif


"----------------------------- Buffer TMUX             -----------------------------

"if g:use_tmux
    "Usar 'tmux load-buffer -'
    "Usar 'tmux save-buffer -'
"endif


"----------------------------- Splits                  -----------------------------

"Navegación stre splits (no es necesario especificar, lo define el Plug-In 'vim-tmux-navigator').
"noremap <C-j> <C-w>j
"noremap <C-k> <C-w>k
"noremap <C-l> <C-w>l
"noremap <C-h> <C-w>h

"Terminal : Abrir una terminal
if g:is_neovim

    "set termwinsize=15*0
    nnoremap <Leader>th :split <bar> resize 20 <bar> terminal<CR>i
    "nnoremap <Leader>th :split <bar> terminal<CR>i
    nnoremap <Leader>tv :vsplit <bar> terminal<CR>i
    
else
    
    "set termwinsize=15*0
    nnoremap <Leader>tv :botright vertical terminal<CR>
    nnoremap <Leader>th :botright terminal<CR>
   
endif

"Terminal : Salir de modo 'Terminal-Job' e ingresar en modo lectura ('Terminal-Normal')
"noremap <C-N> <C-\><C-n>

"----------------------------- Tabs                    -----------------------------
"nnoremap <silent> <S-t> :tabnew<CR>

"----------------------------- Session Management      -----------------------------
"nnoremap <leader>so :OpenSession<Space>
"nnoremap <leader>ss :SaveSession<Space>
"nnoremap <leader>sd :DeleteSession<CR>
"nnoremap <leader>sc :CloseSession<CR>

"----------------------------- Git                     -----------------------------
"noremap <Leader>ga :Gwrite<CR>
"noremap <Leader>gc :Git commit --verbose<CR>
"noremap <Leader>gsh :Git push<CR>
"noremap <Leader>gll :Git pull<CR>
"noremap <Leader>gs :Git<CR>
"noremap <Leader>gb :Git blame<CR>
"noremap <Leader>gd :Gvdiffsplit<CR>
"noremap <Leader>gr :GRemove<CR>


"Set working directory
"nnoremap <leader>. :lcd %:p:h<CR>

"Opens an edit command with the path of the currently edited file filled in
"noremap <Leader>e :e <C-R>=expand("%:p:h") . "/" <CR>

"Opens a tab edit command with the path of the currently edited file filled
"noremap <Leader>te :tabe <C-R>=expand("%:p:h") . "/" <CR>


