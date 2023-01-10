"###################################################################################
" Mappings> General
"###################################################################################

let mapleader=','


"Search mappings: These will make it so that going to the next one in a search will center on the line it's found in.
nnoremap n nzzzv
nnoremap N Nzzzv

"----------------------------- Apariencia              -----------------------------

"Habilitar/Desabiliar el resaltado de la fila actual (h = horizontal)
nnoremap <Leader>h :set cursorline!<CR>
"Habilitar/Desabiliar el resaltado de la columna actual (v = vertical)
nnoremap <Leader>v :set cursorcolumn!<CR>

"----------------------------- Portapapeles            -----------------------------

if g:os == "Linux"

   nnoremap <leader>cy :silent :call system('xsel -ib', @0)
   nnoremap <leader>cd :silent :call system('xsel -ib', @1)

   "Accion para copiar todo el documento
   "nnoremap <leader>cc :w !xsel -ib<CR>

   "Comando para copiar un rango
   "command -range cc :silent :<line1>,<line2>w !xsel -ib

   "Accion para pegar todo el documento
   nnoremap <leader>cp :r !xsel -ob<CR>

   "Comando para pegar un rango
   "command -range cv :silent :<line1>,<line2>r !xsel -ob

"elseif g:os == "Windows"
"
"   "Accion para copiar todo el documento
"   nnoremap <leader>cc :w !xsel -ib<CR>
"
"   "Comando para copiar un rango
"   command -range cc :silent :<line1>,<line2>w !xsel -ib
"
"   "Accion para pegar todo el documento
"   nnoremap <leader>cv :r !xsel -ob<CR>
"
"   "Comando para pegar un rango
"   command -range cv :silent :<line1>,<line2>r !xsel -ob
"
"elseif g:os == "WSL"
"
"   "Accion para copiar todo el documento
"   nnoremap <leader>cc :w !xsel -ib<CR>
"
"   "Comando para copiar un rango
"   command -range cc :silent :<line1>,<line2>w !xsel -ib
"
"   "Accion para pegar todo el documento
"   nnoremap <leader>cv :r !xsel -ob<CR>
"
"   "Comando para pegar un rango
"   command -range cv :silent :<line1>,<line2>r !xsel -ob

endif

"----------------------------- Splits                  -----------------------------

"COMENTAR su usa Plug-In 'vim-tmux-navigator'. Teclas de navegacion entre split de un tab (similar a las que se usaran para navegar paneles tmux)
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


