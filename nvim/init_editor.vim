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

" Modos de funcionamiento de VIM/NeoVIM:
"   > VIM como IDE usa como cliente LSP a CoC.
"   > NeoVIM como IDE usa el cliente LSP nativo (por defecto), pero pero puede usar CoC: USE_COC=1 nvim
"   > Tanto VIM/NeoVIM configurado en modo IDE puede omitir la cargar los plugins del IDE usando:
"     ONLY_BASIC=1 vim
"     ONLY_BASIC=1 nvim
"   > La limitacion del ultimo caso es que los no plugins filetypes de modo editor no se cargaran
"
" Para Vim/NeoVIM, el script de instalacion crea link de archivos/carpetas en su runtimepath por defecto:
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
"  ./custom_config.vim
"      Archivo que permite modificar las variables globales de este secript.
"      Por defecto no existe pero la plantilla se puede obtener de '~/.files/nvim/templates/custom_config.vim' o
"      '~/.files/vim/templates/custom_config.vim':
"        cp ~/.files/vim/templates/custom_config.vim ~/.vim/custom_config.vim
"        cp ~/.files/nvim/templates/custom_config.vim ~/.config/nvim/custom_config.vim
"        cp ${env:USERPROFILE}/.files/vim/templates/custom_config.vim ${env:USERPROFILE}/vimfiles/custom_config.vim
"        cp ${env:USERPROFILE}/.files/nvim/templates/custom_config.vim ${env:LOCALAPPDATA}/nvim/custom_config.vim
"
"
"
"#########################################################################################################
" Variables globales modificables por el usuario
"#########################################################################################################

" Cargar los valores de las variables globales
runtime custom_config.vim


" Establecer un mecanismo de escritura (copy) al clipboard para VIM/NeoVim, lo cual incluye:
"  > Acciones de escritura al clipboard usanbdo el valor de los registros VIM.
"  > Escritura automatica al clipboard despues de realizar el yank (si esta habilitado 'g:yank_to_clipboard').
" El valor real, se obtendra segun orden de prioridad:
"  > El valor definido por la variable de entorno 'CLIPBOARD'
"    Ejemplo : 'CLIPBOARD=1 vim'
"  > El valor definido por esta variable VIM 'g:clipboard_writer_mode'.
" Sus valores es un entero y puden ser:
"  > '1', si se implementa el mecanismo de uso OSC 52
"  > '2', si se implementar el mecanismo de uso comandos externo del gestion de clipboard,
"         por ejemplo: 'wlcopy', 'xsel', 'xclip', etc.
"  > Si la no se define una variable o si se define pero es cualquier otro valor, VIM/NeoVIM
"    determinaran automaticamente el mecanismo correcto segun order de prioridad:
"    > En NeoVIM, se obtendra segun la prioridad:
"      > Usar mecanismo nativo (SOC y comandos externos) si esta habilitado.
"      > Implementar el mecanismo OSC 52.
"    > En VIM, se obtendra segun la prioridad:
"      > Implementar el mecanismo OSC 52, si la terminal lo permite.
"      > Usar mecanismo nativo (API del SO) si esta habilitado.
"      > Implementar el mecanismo de uso comandos externo del gestion de clipboard
" Con fines practicos, internamete se usara el valor '9' para representar que se desea que el mecanismo
" de determacion del clipboard de VIM/NeoVIM se realize automaticamente.
if $CLIPBOARD != ''

    if $CLIPBOARD == 1
        let g:clipboard_writer_mode = 1
    elseif $CLIPBOARD == 2
        let g:clipboard_writer_mode = 2
    else
        let g:clipboard_writer_mode = 9
    endif

elseif exists("g:clipboard_writer_mode")

    if g:clipboard_writer_mode != 1 && g:clipboard_writer_mode != 2
        let g:clipboard_writer_mode = 9
    endif

else
    let g:clipboard_writer_mode = 9
endif


" Solo se debe usar si 'clipboard_writer_mode' es '1' (manual o automático).
" Establecer el formato OSC52 a usar para escribir en el clipboard.
" El valor real, se obtendra segun orden de prioridad:
"  > El valor definido por la variable de entorno 'OSC52_FORMAT'
"    Ejemplo : 'OSC52_FORMAT=0 vim'
"  > El valor definido por esta variable VIM 'g:clipboard_osc52_format'.
" Sus valores es un entero y puden ser:
"  > '0' Formato OSC-52 estandar que es enviado directmente una terminal que NO use como '$TERM' a
"        GNU screen.
"  > '1' Formato OSC-52 es dividio en pequeños trozos y enmascador en formato DSC, para enviarlo
"        directmente a una terminal basada en GNU ('$TERM' inicia con screen).
"  > '2' Formato OSC-52 se enmascara DSC enmascarado para TMUX (tmux requiere un formato determinado) y
"        sera este el que decida si este debera reenvíarse a la terminal donde corre tmux (en este caso
"        TMUX desenmacara y lo envia).
"  > Si la no se define una variable o si se define pero es cualquier otro valor, VIM/NeoVIM determinaran
"    automaticamente el valor en base a las variables de entorno asociada a la terminal usada.
" Con fines practicos, internamete se usara el valor '9' para representar que se desea que el mecanismo
" de determacion del clipboard de VIM/NeoVIM se realize automaticamente.
if $OSC52_FORMAT != ''

    if $OSC52_FORMAT == 0
        let g:clipboard_osc52_format = 0
    elseif $OSC52_FORMAT == 1
        let g:clipboard_osc52_format = 1
    elseif $OSC52_FORMAT == 2
        let g:clipboard_osc52_format = 2
    else
        let g:clipboard_osc52_format = 9
    endif

elseif exists("g:clipboard_osc52_format")

    if g:clipboard_osc52_format != 0 && g:clipboard_osc52_format != 1 && g:clipboard_osc52_format != 2
        let g:clipboard_osc52_format = 9
    endif

else
    let g:clipboard_osc52_format = 9
endif


" Permitir que cuando se realize un 'yank' se copie automaticamente al clipboard.
" El valor real, se obtendra segun orden de prioridad:
"  > El valor definido por la variable de entorno 'YANK_TO_CB'
"    > 0 ('true' ), si se cuando realiza un yank este se copiara automaticamente al clipboard.
"      Ejemplo : 'YANK_TO_CB=0 vim'
"    > 1 ('false'), si realiza un yank este NO se copiara al clipboard.
"      Ejemplo : 'YANK_TO_CB=1 vim'
"    > Cualquiere otro valor se considera no definido.
"  > El valor definido por esta variable VIM 'g:yank_to_clipboard'
"    > v:true (o diferente a '0') si realiza un yank este tambien se copia al clipboard
"    > v:false (o '0') si se realiza un yank este no se copiara al clipboard.
"    > Si no se especifica, se considera no definido
" Si no se define, su valor por defecto es 'v:false' (es decir '0').
if $YANK_TO_CB != ''

    if $YANK_TO_CB == 0
        let g:yank_to_clipboard = v:true
    elseif $YANK_TO_CB == 1
        let g:yank_to_clipboard = v:false
    else
        let g:yank_to_clipboard = v:false
    endif

elseif exists("g:yank_to_clipboard")

    if empty(g:yank_to_clipboard)
        let g:yank_to_clipboard = v:false
    else
        let g:yank_to_clipboard = v:true
    endif

else
    let g:yank_to_clipboard = v:false
endif


" El modo de VIM/NeoVIM siempre debe ser el modo Editor
let g:use_ide = v:false


" Variables globales no usuados
let g:use_coc = v:true
let g:use_typing_plugins = {}
let g:use_ai_plugins = v:false
let g:tools_path = ''
let g:use_lsp_adapters = {}
let g:use_dap_adapters = {}

"#########################################################################################################
" Basic Settings
"#########################################################################################################

" Establecer opciones VIM, variables de uso interno, keymapping basicos (clipboard, etc).
runtime setting/setting_core.vim


"#########################################################################################################
" Setup plugins basicos
"#########################################################################################################

" StatusLine, TabLine, TMUX, FZF, NERDTree.
runtime setting/basic/basic_core.vim

" Autocpmpletado de la linea de comandos, Highlighting Sintax (resaltado de sintaxis) nativo y el ofrecido
" por Treesitter.
runtime setting/basic/basic_extended.vim
