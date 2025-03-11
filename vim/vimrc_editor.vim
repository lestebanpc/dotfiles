" 
" Para configurar VIM/NeoVIM en los 2 modos de funcionamiento (modo editor y modo IDE), se recomienda
" ejecutar el script:
"   > Instalar en Linux   : ~/.files/shell/bash/bin/linuxsetup/04_install_profile.bash
"   > Instalar en Windows : ~/.files/shell/powershell/bin/windowssetup/02_install_profile.ps1
" Este script crea enlaces simbolico a  archivos y carpetas en uno los runtimepath por defecto:
"   > VIM en Linux        : ~/.vim/
"   > VIM en Windows      : ${env:USERPROFILE}\vimfiles\
"   > NeoVIM en Linux     : ~/.config/nvim/
"   > NeoVIM en Windows   : ${env:LOCALAPPDATA}\nvim\
" Adicionalmente descarga plugin en uno de los subdirectorios del runtimepath por defecto:
"   > VIM en Linux        : ~/.vim/pack/
"   > VIM en Windows      : ${env:USERPROFILE}\vimfiles\pack\
"   > NeoVIM en Linux     : ~/.local/share/nvim/site/pack/
"   > NeoVIM en Windows   : ${env:LOCALAPPDATA}\nvim-data\site\pack

" Modos d funcionamiento de VIM/NeoVIM:
"   > VIM como IDE usa como cliente LSP a CoC. 
"   > NeoVIM como IDE usa el cliente LSP nativo (por defecto), pero pero puede usar CoC: USE_COC=1 nvim
"   > Tanto VIM/NeoVIM configurado en modo IDE puede omitir la cargar los plugins del IDE usando:
"     USE_EDITOR=1 vim
"     USE_EDITOR=1 nvim
"   > La limitacion del ultimo caso es que los no plugins filetypes de modo editor no se cargaran
" 
" Para NeoVIM, el script de instalacion crea link de archivos/carpetas en su runtimepath por defecto:
"  ~/vimrc                   (VIM)
"      Archivo de inicialización de VIM
"      > En modo IDE, es un enlace simbolico a '~/.files/vim/vimrc_ide.vim' 
"      > En modo editor, es un enlace simbolico a '~/.files/vim/vim_editor.vim'
"  ./init.vim                (NeoVIM)
"      Archivo de inicialización de NeoVIM
"      > En modo IDE, es un enlace simbolico a '~/.files/nvim/init_ide.vim' 
"      > En modo editor, es un enlace simbolico a '~/.files/nvim/init_editor.vim'
"  ./coc-settings.json       (VIM/NeoVIM)
"      Archivo de configurarion de CoC
"      > Solo es usado cuando en modo IDE y usando 'USE_COC=1').
"      > Es un enlace a '~/.files/nvim/coc-settings_linux.json'
"  ./setting/                (VIM/NeoVIM) 
"      Carpeta de script VimScript invocados desde el archivo de inicialización de VIM/NeoVIM.
"      > Es un enlace simbolico a '~/.files/vim/setting/'.
"  ./lua/
"      Carpeta de script LUA de configuracion de NeoVIM invocados por los script.
"      > Es un enlace a '~/files/nvim/lua/'
"  ./ftplugin/               (VIM/NeoVIM)
"      En la carpeta predetermina de plugin de filetypes usado por VIM/NeoVIM.
"      > En VIM modo Editor son los plugins de filetypes usados solo para el modo editor y es un link a 
"        '~/.files/vim/ftplugin/editor/'.
"      > En VIM modo IDE son los plugins de filetypes usados solo para modo IDE y es un link a
"        '~/.files/vim/ftplugin/cocide/'.
"      > En NeoVIM modo Editor son los plugins de filetypes usados solo para el modo editor y es un link a 
"        '~/.files/nvim/ftplugin/editor'.
"      > En NeoVIM en modo IDE son los plugins de filetypes usados solo para IDE ya esa usando LSP nativo 
"        o CoC y es un link a '~/.files/nvim/ftplugin/commonide'.
"  ./rte_nativeide/ftplugin/ (NeoVIM)
"      Carpeta de plugin de filetypes usado por NeoVIM en modo IDE usando el cliente LSP nativo.
"      > En es un enlace simbolico a '~/.files/nvim/ftplugin/nativeide/'.
"  ./rte_cocide/ftplugin/    (NeoVIM)
"      Carpeta de plugin de filetypes usado por NeoVIM en modo IDE usando el cliente LSP de CoC.
"      > En es un enlace simbolico a '~/.files/nvim/ftplugin/cocide/'.
"  ./config.vim
"      Archivo que permite modificar las variables globales de este secript.
"      Por defecto no existe pero la plantilla se puede obtener de '~/.files/nvim/config_template.vim' o
"      '~/.files/vim/config_template.vim':
"        cp ~/.files/vim/config_template.vim ~/.vim/config.vim
"        cp ~/.files/nvim/config_template.vim ~/.config/nvim/config.vim
"        cp ${env:USERPROFILE}/.files/vim/config_template.vim ${env:USERPROFILE}/vimfiles/config.vim
"        cp ${env:USERPROFILE}/.files/nvim/config_template.vim ${env:LOCALAPPDATA}/nvim/config.vim
"
"
"
"#########################################################################################################
" Variables globales modificables por el usuario
"#########################################################################################################

" Cargar los valores de las variables globales
runtime config.vim

" Habilita el uso del TabLine (barra superior donde se muestran los buffer y los tabs).
" Valor por defecto es 1 ('true'). 
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
let g:use_tabline = get(g:, 'use_tabline', 1)

" No usuados
let g:use_typing_surround = 0
let g:use_typing_surround = 0
let g:use_typing_html_emmet = 0 
let g:use_ai_plugins = 0
let g:home_path_lsp_server = ''
let g:home_path_dap_server = ''
let g:using_lsp_server_cs_win = 0


"#########################################################################################################
" Basic Settings
"#########################################################################################################

" Si es 1 ('true'), se habilita el uso de IDE (puede desabilitarse automatica si no cumple
" requisitos minimos).
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
let g:use_ide = 0

runtime setting/setting_basic.vim


"#########################################################################################################
" Setup plugins basicos
"#########################################################################################################

"StatusLine, TabLine, TMUX, ...
runtime setting/plugin/ui_basic.vim

"Utilitarios basicos: FZF, NERDTree, ...
runtime setting/plugin/ui_extended.vim


