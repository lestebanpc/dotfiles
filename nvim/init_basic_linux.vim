"
" Se recomienda ejecutar ('~/.files/shell/bash/bin/linuxsetup/04_install_profile.bash') el script de 
" configuración del profile y escoger uno de los modos Editor o IDE, el cual creara los enlaces simbolicos
" requeridos para la inicialización de NeoVIM en dicho modo. El runtime path donde se encuentra el archivo 
" de inicialización de NeoVIM ('~/.config/nvim') tiene la siguiente estructura:
"  ./init.vim          -> Archivo de inicialización de NeoVIM como IDE
"                         En modo IDE, es un enlace simbolico a '~/.files/nvim/init_ide_linux.vim' 
"                         En modo editor, es un enlace simbolico a '~/.files/nvim/init_basic_linux.vim' 
"  ./coc-settings.json -> Archivo de configurarion de CoC (solo es usado cuando esta en modo IDE y se usan
"                         la variable de entorno 'USE_COC=1'. 
"                         Es un enlace a '~/.files/nvim/coc-settings_linux.json'
"  ./setting/         -> Carpeta de script VimScript de configuracion de VIM/NeoVIM invocados desde el 
"                         archivo de inicialización. Es un enlace simbolico a '~/.files/vim/setting/'.
"  ./lua/              -> Carpeta de script LUA de configuracion de NeoVIM invocados por los script
"                         ubicados en './setting/plugin/' ('ui_core.vim', 'ui_extended.vim' y 
"                         'ide_core.vim'). Es un enlace simbolico a '~/.files/nvim/lua/'.
"  ./ftplugin/         -> Carpeta de plugin de filetypes usado por cualquier IDE.
"                         Enlace simbolico a '~/.files/nvim/ftplugin/commonide/'.
"  ./rte_cocide/       -> Folder que formara parte del runtime path de NeoVIM de manera dinamicamente si 
"                         es IDE CoC (por el script './settigs/core_setting.vim').
"      ./ftplugin/     -> Carpeta de plugin de filetypes usado cuando el IDE es CoC.
"                         Enlace simbolico a '~/.files/nvim/ftplugin/cocide/'.
"  ./rte_nativeide/    -> Folder que formara parte del runtime path de NeoVIM de manera dinamicamente si
"                         es IDE Nativo (por el script './settigs/core_setting.vim').
"      ./ftplugin/     -> Carpeta de plugin de filetypes usado cuando el IDE nativo de NeoVIM.
"                         Enlace simbolico a '~/.files/nvim/ftplugin/nativeide/'.
" Por defecto el IDE es el nativo de NeoVIM. Si desea usar el IDE CoC, usa la variable de entorno 
" 'USE_COC'   : USE_COC=1 nvim
" Si esta instalado en modo IDE y no desea cargar los plugins del IDE, use la variable de entorno 
" 'USE_EDITOR': USE_EDITOR=1 nvim
" En este ultimo caso, los plugins de filetypes de modo IDE ni el modo editor no se cargaran. La unica 
" forma de cargar los plugins de filetypes en modo editor sera configurando NeoVIM en modo editor.
"


"#########################################################################################################
" Variables Globales
"#########################################################################################################

" Cargar los valores de las variables globales
runtime config.vim

" Si es 1 ('true'), se habilita el uso de IDE (puede desabilitarse automatica si no cumple
" requisitos minimos).
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
let g:use_ide = 0

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


"#########################################################################################################
" Basic Settings
"#########################################################################################################

runtime setting/setting_basic.vim


"#########################################################################################################
" Setup plugins basicos
"#########################################################################################################

"Tema, Iconos, StatusLine, TabLine, Explorador NERDTree, ...
runtime setting/plugin/ui_basic.vim

"Utilitarios basicos: FZF, TMUX, ...
runtime setting/plugin/ui_extended.vim


