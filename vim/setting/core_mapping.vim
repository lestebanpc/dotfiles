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

"Soporte adicional a los portapales
if (g:os_type == 2) || (g:os_type == 3)

    if executable('wl-copy')

        "Copiar el ultimo yank realizado al portapapeles ('CLIPBOARD' selecction)
        nnoremap <Leader>cy :<C-u>call system('wl-copy', @0)<CR>

        "Copiar el ultimo delete realizado al portapapeles ('CLIPBOARD' selection)
        nnoremap <Leader>cd :<C-u>call system('wl-copy', @1)<CR>

        "Pegar el portapapeles al ultimo yank ('CLIPBOARD' selecction)
        nnoremap <Leader>py :<C-u>let @0=system('wl-paste --no-newline 2> /dev/null')<CR>

        "Copiar las lineas seleccionadas al portapapeles ('CLIPBOARD' selection)
        vnoremap <Leader>cl :w !wl-copy<CR><CR>

        "Pegar del portapapeles ('CLIPBOARD' selecction) en nuevas lineas siguientes
        nnoremap <Leader>pl :<C-u>r !wl-paste --no-newline<CR>

        "Si no se tiene soporte al clipboard:
        "Si no es NeoVIM (NeoVIM usa un backend de clipboard, es decir comandos externos, no se integra on el API del SO)
        if !g:is_neovim && !g:has_clipboard
            augroup Yank
                autocmd!
                autocmd TextYankPost * if v:event.operator ==# 'y' | silent! call system('wl-copy',@") | endif
            augroup END
        endif

    elseif exists('$DISPLAY') && executable('xclip')

        "Copiar el ultimo yank realizado al portapapeles ('CLIPBOARD' selecction)
        nnoremap <Leader>cy :<C-u>call system('xclip -i -selection clipboard', @0)<CR>

        "Copiar el ultimo delete realizado al portapapeles ('CLIPBOARD' selection)
        nnoremap <Leader>cd :<C-u>call system('xclip -i -selection clipboard', @1)<CR>

        "Pegar el portapapeles al ultimo yank ('CLIPBOARD' selecction)
        nnoremap <Leader>py :<C-u>let @0=system('xclip -o -selection clipboard 2> /dev/null')<CR>

        "Copiar las lineas seleccionadas al portapapeles ('CLIPBOARD' selection)
        vnoremap <Leader>cl :w !xclip -i -selection clipboard<CR><CR>

        "Pegar del portapapeles ('CLIPBOARD' selecction) en nuevas lineas siguientes
        nnoremap <Leader>pl :<C-u>r !xclip -o -selection clipboard<CR>

        "Si no se tiene soporte al clipboard:
        "Si no es NeoVIM (NeoVIM usa un backend de clipboard, es decir comandos externos, no se integra on el API del SO)
        if !g:has_clipboard
            augroup Yank
                autocmd!
                autocmd TextYankPost * if v:event.operator ==# 'y' | silent! call system('xclip -i -selection clipboard',@") | endif
            augroup END
        endif

    endif


"elseif g:os_type == 0

"Si es WSL2:
"  Aparte de usar como registro por defecto a '+' (el portapales principal de Linux, establecido por 'set clipboard=unnamedplus').
"  Se usara requiere copiar el ultimo yank registro del portapapeles del SO.
elseif g:os_type == 3

    "Copia cualquier yank que esta en el registro " (por defecto) se copia al portapales del SO
    augroup WslYank
        autocmd!
        autocmd TextYankPost * if v:event.operator ==# 'y' | call system('/mnt/c/windows/system32/clip.exe ',@") | endif
    augroup END

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


