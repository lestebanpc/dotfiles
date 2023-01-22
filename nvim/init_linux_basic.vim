"----------------------------- Variables Iniciales    -----------------------------

"Habilita el uso del TabLine (barra superior donde se muestran los buffer y los tabs)
let g:use_tabline = 1

"Habilita el uso de IDE (En VIM, puede ser desabilitado si se cumple los requisitos minimos)
let g:use_ide = 0

"----------------------------- Basic Settings          -----------------------------
source ~/.files/vim/setting/core_setting.vim
source ~/.files/vim/setting/core_mapping.vim

"----------------------------- Variables usados x IDE  -----------------------------

"Habilitar Typing
let g:use_typing_html_emmet = 0
let g:use_typing_surround = 0
let g:use_typing_visual_multi = 0

"----------------------------- Plugins Initialize      -----------------------------
"Registro de los plugin en los gestores de plugins Vim-Plug y de paquetes Packer
"Carga automatica de plugins por el gestor de paquetes
"Carga manual de plugin
"Configuracion de basica de inicializacion de plugins:
"  - Configuracion basica requeridos antes de la carga de un plugin
"  - Establecer el 'Color Schema' del tema (requerido antes de cualquiere plugin UI)
"  - Configuracion basica requerida despues de la carga de cirtos plugin
source ~/.files/vim/setting/plugin_initialize.vim

"----------------------------- Plugins UI Basicos      -----------------------------

"StatusLine, TabLine, TMUX, ...
source ~/.files/vim/setting/plugin/ui_core.vim

"Utilitarios basicos: FZF, NERDTree, ...
source ~/.files/vim/setting/plugin/ui_extended.vim







