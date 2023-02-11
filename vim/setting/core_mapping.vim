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

"Si es Linux incluyendo WSL
if (g:os_type == 2) || (g:os_type == 3)

   "Copiar el ultimo yank realizado al portapapeles ('CLIPBOARD' selecction)
   nnoremap <Leader>cy :<C-u>call system('xsel -ib', @0)<CR>

   "Copiar el ultimo delete realizado al portapapeles ('CLIPBOARD' selection)
   nnoremap <Leader>cd :<C-u>call system('xsel -ib', @1)<CR>

   "Copiar las lineas seleccionadas al portapapeles ('CLIPBOARD' selection)
   vnoremap <Leader>cc :w !xsel -ib<CR><CR>

   "Pegar del portapapeles ('CLIPBOARD' selecction) en nuevas lineas siguientes
   nnoremap <Leader>cp :<C-u>r !xsel -ob<CR>

"elseif g:os_type == 0
"elseif g:os_type == 3

endif

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


