"----------------------------- Variables Globales      -----------------------------

" Cargar los valores de las variables globales
if filereadable(expand('~/.files/vim/_config.vim'))
    source ~/.files/vim/_config.vim
endif

" Si es 1 ('true'), se habilita el uso de IDE (puede desabilitarse automatica si no cumple
" requisitos minimos).
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
let g:use_ide = 1

" Habilita el uso del TabLine (barra superior donde se muestran los buffer y los tabs).
" Valor por defecto es 1 ('true'). 
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
let g:use_tabline = get(g:, 'use_tabline', 1)

" Habilitar el plugin de typing 'vim-surround', el cual es usado para encerar/modificar
" texto con '()', '{}', '[]' un texto. Valor por defecto es 0 ('false').
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
" Si cambia este valor, recargar/cerrar VIM para volver a cargar los plugin.
let g:use_typing_surround = get(g:, 'use_typing_surround', 0)

" Habilitar el plugin de typing 'emmet-vim', el cual es usado para crear elementos
" HTML usando palabras claves. Valor por defecto es 0 ('false').
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
" Si cambia este valor, recargar/cerrar VIM para volver a cargar los plugin.
let g:use_typing_html_emmet = get(g:, 'use_typing_html_emmet', 0)

" Habilitar el plugin de typing 'vim-visual-multi', el cual es usado para realizar seleccion
" multiple de texto. Valor por defecto es 0 ('false').
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
" Si cambia este valor, recargar/cerrar VIM para volver a cargar los plugin.
let g:use_typing_visual_multi = get(g:, 'use_typing_visual_multi', 0)

" No usuados
let g:home_path_lsp_server = ''
let g:home_path_dap_server = ''
let g:using_lsp_server_cs_win = 0


"----------------------------- Variables Iniciales    -----------------------------

"Habilita el uso del TabLine (barra superior donde se muestran los buffer y los tabs)
let g:use_tabline = 1

"Habilita el uso de IDE (En VIM, puede ser desabilitado si se cumple los requisitos minimos)
let g:use_ide = 0

"----------------------------- Variables usados x IDE  -----------------------------

"Habilitar Typing
let g:use_typing_html_emmet = 0
let g:use_typing_surround = 0
let g:use_typing_visual_multi = 0

"----------------------------- Basic Settings          -----------------------------
source ~/.files/vim/setting/core_setting.vim
source ~/.files/vim/setting/core_mapping.vim

"----------------------------- Load plugins            -----------------------------
"Registro de los plugin en los gestores de plugins (si se usa)
"Carga automatica de algunos plugins por el gestor de paquetes
"Carga manual de plugin
"Configuracion de basica de plugins basicos:
"  - Configuracion basica requeridos antes de la carga de un plugin
"  - Establecer el 'Color Schema' del tema (requerido antes de cualquiere plugin UI)
source ~/.files/vim/setting/plugin_load.vim

"----------------------------- Setup plugins (UI)       ----------------------------
"StatusLine, TabLine, TMUX, ...
source ~/.files/vim/setting/plugin/ui_core.vim

"Utilitarios basicos: FZF, NERDTree, ...
source ~/.files/vim/setting/plugin/ui_extended.vim







