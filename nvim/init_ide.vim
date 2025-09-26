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


" Determina si habilita el completado a nivel linea de comandos (modo editor o ide) incluyendo ':' y las
" busquedas '/' y '?'. Su valores pueden ser:
"  > '1' o 'v:true', si se habilita el completado en la linea de comandos.
"  > '0' o 'v:false', si se desabilita el completado en la linea de comandos.
"  >  Si no se define o es 'v:null', se considera que se habilita el completado.
if exists("g:cmdline_completion")

    if empty(g:cmdline_completion)
        let g:cmdline_completion = v:false
    else
        let g:cmdline_completion = v:true
    endif

else
    let g:cmdline_completion = v:true
endif



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


" Deshabilitación manual de las capacidades de modo IDE
"  > La deshabilitación automatica de las capacidades de modo IDE se realiza si no cumple requisitos
"    minimos de un IDE.
" El valor real, se obtendra segun orden de prioridad:
"  > El valor definido por la variable de entorno 'ONLY_BASIC'
"    > 0 ('true' ), si se desactiva las capacidades IDE.
"      Ejemplo : 'ONLY_BASIC=0 vim'
"    > 1 ('false'), si se preserva las capacidades IDE.
"      Ejemplo : 'ONLY_BASIC=1 vim'
"    > Cualquiere otro valor se considera no definido.
"  > El valor definido por esta variable VIM
"    > v:true (o diferente a '0') si es 'true'
"    > v:false (o '0') si es false.
"    > Si no se especifica, se considera no definido
" Si no se define, su valor por defecto es 'v:true' (valor diferente a 0).
if $ONLY_BASIC != ''

    if $ONLY_BASIC == 0
        let g:use_ide = v:false
    elseif $ONLY_BASIC == 1
        let g:use_ide = v:true
    else
        let g:use_ide = v:true
    endif

elseif exists("g:use_ide")

    if empty(g:use_ide)
        let g:use_ide = v:false
    else
        let g:use_ide = v:true
    endif

else
    let g:use_ide = v:true
endif


" Los plugins de typing a usar :
"  > 'surround'
"    > Plugin de typing 'vim-surround'
"    > Es usado para encerar/modificar texto con '()', '{}', '[]' un texto.
"  > 'html_emmet'
"    > Plugin de typing 'emmet-vim', el cual es usado para crear elementos html.
"  > 'visual_multi'
"     > Plugin de typing 'vim-visual-multi', el cual es usado para realizar seleccion multiple
"       de texto.
" Definir los valores por defecto si no han sido definidos.
if !exists("g:use_typing_plugins") || empty(g:use_typing_plugins)
    let g:use_typing_plugins = {
    \   'surround'     : v:false,
    \   'html_emmet'   : v:false,
    \   'visual_multi' : v:false,
    \}
endif
"echom 'Typing plugins: ' .. string(g:use_typing_plugins)


" Habilitar el plugin de AI.
" > Para 'AI Autocompletion' se usara la capacidade de autocompletado de 'GitHub Copilot' y estara por
"   defecto desabilitado.
"   > Para habilitarlo use ':Copilot enable'
"   > Para CoC (VIM/NeoVIM), se usara 'github/copilot.vim' y el plugin de CoC '@hexuhua/coc-copilot'.
"   > Para NeoVIM y no usas CoC, se usara 'zbirenbaum/copilot.lua'.
" > Para 'AI Agent' se usara Avente, usando la API ofrecido por 'GitHub Copilot'.
"   > Puede usar avante con el 'AI Autocompletion' desactivado.
" El valor real, se obtendra segun orden de prioridad:
"  > El valor definido por la variable de entorno 'USE_AI=0'
"    > 0 si es 'true'
"    > 1 si es false.
"    > Cualquiere otro valor se considera no definido.
"  > El valor definido por esta variable VIM.
"    > v:true (o diferente a '0 ') si es 'true'
"    > v:false (o '0') si es false.
"    > Si no se especifica, se considera no definido
" Si no se define, su valor por defecto es 'v:false' (valor 0).
if $USE_AI != ''

    if $USE_AI == 0
        let g:use_ai_plugins = v:true
    elseif $USE_AI == 1
        let g:use_ai_plugins = v:false
    else
        let g:use_ai_plugins = v:false
    endif

elseif exists("g:use_ai_plugins")

    if empty(g:use_ai_plugins)
        let g:use_ai_plugins = v:false
    else
        let g:use_ai_plugins = v:true
    endif

else
    let g:use_ai_plugins = v:false
endif


" Si esta habilitado el 'AI Autocompletion', a que archivos se habiltara el autocompletado por AI,
" Definir los valores por defecto si no han sido definidos.
if !exists("g:completion_filetypes") || empty(g:completion_filetypes)
    let g:completion_filetypes = {
    \   '*'           : v:false,
    \   'c'           : v:true,
    \   'cpp'         : v:true,
    \   'go'          : v:true,
    \   'rust'        : v:true,
    \   'java'        : v:true,
    \   'cs'          : v:true,
    \   'python'      : v:true,
    \   'sh'          : v:false,
    \   'ps1'         : v:false,
    \   'lua'         : v:false,
    \   'vim'         : v:false,
    \   'javascript'  : v:true,
    \   'typescript'  : v:true,
    \}
endif
"echom 'Completion Filetypes: ' .. string(g:completion_filetypes)


" Ruta base donde se encuentra los programas requeridos por VIM/NeoVIM.
" Su valor se calculara, segun prioridad, usando:
"  > Valor definido en la variable de entorno 'MY_TOOLS_PATH' (siempre que defina un valor).
"  > Si no define un valor, se usara la ruta indicada en esta variable global vim 'g:tools_path'.
"  > Si no se define una variable o es vacia, se usara el valor por defecto es : '/var/opt/tools'
" Su valor por defecto es : '/var/opt/tools'
" Dentro de esta ruta se debe encontrar (entre otros) los subfolderes:
"   > Ruta base donde estan los LSP Server            : './lsp_servers/'
"   > Ruta base donde estan los DAP Server            : './dap_servers/'
"   > Ruta base donde estan las extensiones de vscode : './vsc_extensions/'
" Estableciendo el valor por defecto si no se define antes.
if $MY_TOOLS_PATH != ''
    let g:tools_path = $MY_TOOLS_PATH
elseif !exists("g:tools_path")
    let g:tools_path = "/var/opt/tools"
endif


" Establecer los Linters por defecto que se usaran.
"  > Use las capacidades de linting y fixing del servidor LSP.
"  > Si su servidores tiene capacidades muy limitidas de linting/fixing use ALE.
"    > Para Typescript/Javascript debe usar linting/fixing para complementar a 'tsserver'.
"    > Para LSP asociados a archivos, como 'DockerFile' (Docker LS), use linting.
"  > Solo en caso que considere que el linting/fixing ofrecido de su servidor LSP es limitado,
"    configure ALE usando diferentes reglas para que no existe reglas duplicadas.
"  > Si usa CoC, algunas extensiones impelementan un LSP como linting/fixing adicional. Solo en
"    ese caso, desactve el linter/fixer de ALE para esos archivos.
"  > Si usa CoC, se ha configurado para que todo diagnostico generado por CoC, se envie a ALE para
"    que lo presente. ALE siemre mostrara el diagnostico ya sea generado por este o por un externo
"    como CoC.
if !exists("g:ale_linters") || empty(g:ale_linters)

    "Establecer valores por defecto
    let g:ale_linters = {
    "\   'cpp'        : ['clangtidy'],
    "\   'c'          : ['clangtidy'],
    "\   'rust'       : ['clippy'],
    "\   'go'         : ['golangci-lint'],
    "\   'python'     : ['pylint', 'flake8'],
    "\   'xml'        : ['xmllint'],
    \   'http'       : ['kulala_fmt'],
    \   'rest'       : ['kulala_fmt'],
    \   'dockerfile' : ['hadolint'],
    \   'javascript' : ['biome'],
    \   'typescript' : ['biome'],
    \}

endif
"echom 'Linters: ' .. string(g:ale_linters)


" Establecer los Fixers por defecto que se usaran.
"  > Use las capacidades de linting y fixing del servidor LSP.
"  > Si su servidores tiene capacidades muy limitidas de linting/fixing use ALE.
"    > Para Typescript/Javascript debe usar linting/fixing para complementar a 'tsserver'.
"  > Solo en caso que considere que el linting/fixing ofrecido de su servidor LSP es limitado,
"    configure ALE usando diferentes reglas para que no existe reglas duplicadas.
"  > Si usa CoC, algunas extensiones impelementan un LSP como linting/fixing adicional. Solo en
"    ese caso, desactve el linter/fixer de ALE para esos archivos.
"  > Si usa CoC, se ha configurado para que todo diagnostico generado por CoC, se envie a ALE para
"    que lo presente. ALE siemre mostrara el diagnostico ya sea generado por este o por un externo
"    como CoC.
if !exists("g:ale_fixers") || empty(g:ale_fixers)

    "Establecer valores por defecto
    let g:ale_fixers = {
    \   '*'          : ['remove_trailing_lines', 'trim_whitespace'],
    "\   'cpp'        : ['clang-format', 'clangtidy'],
    "\   'c'          : ['clang-format', 'clangtidy'],
    "\   'rust'       : ['rustfmt'],
    "\   'go'         : ['gofmt', 'goimports'],
    "\   'python'     : ['black', 'isort'],
    \   'http'       : ['kulala_fmt'],
    \   'rest'       : ['kulala_fmt'],
    \   'javascript' : ['biome'],
    \   'typescript' : ['biome'],
    \   'yaml'       : ['prettier'],
    \   'json'       : ['prettier'],
    \   'html'       : ['prettier'],
    \   'css'        : ['prettier'],
    \}

endif
"echom 'Fixers: ' .. string(g:ale_fixers)


" Adaptadores LSP en modo IDE Vim/NeoVim cuando se usa CoC :
"  > omnisharp_vim : Para C#. Usa el servidor 'Omnisharp LS' pero usando el plugin 'omnisharp_vim'.
"                    El plugin de omnisharp-vim requiere de un motor de autocompletado y uno de los
"                    motor de completado compatible es CoC.
"  >               : Los demas adaptadores son gestionados por CoC (como extension o configurando un
"                    servicio de tipo cliente LSP en el archivo de configuración).
" Adaptadores LSP (asociado a lenguajes de programación) en modo IDE NeoVim usando el cliente LSP nativo :
"  > cpp           : Para C++. Usa el servidor 'Clangd'.
"  > rust          : Para Rust. Usa el servidor 'Rust Analyzer'.
"  > golang        : Para GoLang. Usa el servidor 'GoPls'.
"  > csharp        : Para C#. Usa el servidor 'Roslyn LS'. Tiene mayor prioridad que 'omnisharp'.
"  > omnisharp     : Para C#. Usa el servidor 'Omnisharp LS'. Tiene mayor prioridad que 'omnisharp_vim'.
"  > java          : Para Java. Usa el servidor 'Eclipse JDT LS'.
"                    El mismo servidor tambien es un servidor DAP.
"  > swift         : Para Swift.
"  > kotlin        : Para Kotlin.
"  > python        : Para Python. Usa el servidor 'BasedPyRight'. Tiene mas prioridad que 'PyRight'.
"  > pyright       : Para Python. Usa el servidor 'PyRight'.
"  > typescript    : Para Javascript/Typescript. Usa 'Typescript LS' un adapador de 'TsServer'.
"                    Use linter como 'eslint' y 'biome' para mejorar el linting.
"  > lua           : Para Lua. Usa el LSP 'Lua LS'.
"  > viml          : Para VimScript. Usa el LSP 'Vim LS'.
"  > bash          : Para Bash. Usa de 'Bash LS'
"  > powershell    : Para Powershell. Usa de 'Powershell Editor Service'.
"  > ansible       : Para Ansible. Usa de 'Ansible LS' (requiere Python, Ansible y Ansible-Lint).
"  > markdown      : Para archivo Markdown.
" Adaptadores LSP, asociado a ciertos archivos, en modo IDE NeoVim usando el cliente LSP nativo (usualmente
" usados para autocompletado):
"  > ansible       : Para Ansible. Usa de 'Ansible LS' (requiere Python, Ansible y Ansible-Lint).
"  > gradle        : Para archivo de configuración de gradle.
"  > dockerfile    : Para archivo dockerfile. Use linter 'hadolint' para mejorar el linting.
"  > json          : Para archivo JSON.
"  > yaml          : Para archivo YAML.
"  > toml          : Para archivo TOML.
"  > xml           : Para archivo XML.
"  > markdown      : Para archivo Markdown.
"  > html          : Para archivo html.
"  > css           : Para archivo css.
"  > tailwindcss   : Para uso de tailwindcss asociado a css.
"  > kulula        : Para archivos .http y .rest usados por el client rest 'kulala'.
" Solo aplica si NO usa CoC. CoC estas configuracion se realiza usualmente por extensiones.
" Estableciendo el valor por defecto si no se define antes.
if !exists("g:use_lsp_adapters") || empty(g:use_lsp_adapters)

    let g:use_lsp_adapters = {
    "\   'cpp'           : v:true,
    "\   'rust'          : v:true,
    "\   'golang'        : v:true,
    "\   'csharp'        : v:true,
    "\   'omnisharp'     : v:true,
    "\   'omnisharp_vim' : v:true,
    "\   'java'          : v:true,
    "\   'swift'         : v:true,
    "\   'kotlin'        : v:true,
    "\   'python'        : v:true,
    "\   'pyright'       : v:true,
    "\   'typescript'    : v:true,
    "\   'lua_nvim'      : v:true,
    \   'lua'           : v:true,
    \   'viml'          : v:true,
    \   'bash'          : v:true,
    \   'powershell'    : v:true,
    "\   'ansible'       : v:true,
    "\   'gradle'        : v:true,
    \   'dockerfile'    : v:true,
    "\   'json'          : v:true,
    \   'yaml'          : v:true,
    \   'toml'          : v:true,
    \   'xml'           : v:true,
    "\   'markdown'      : v:true,
    \   'html'          : v:true,
    \   'css'           : v:true,
    "\   'tailwindcss'   : v:true,
    \   'kulala'        : v:true,
    \}

endif


" En VIM se usa Vimspector el cual tiene su propios forma ge gestionar sus adaptadores (gadgets).
" En NeoVim se usa 'nvim-dap' cuyos adaptadores pueden habilitarse/desahabiltarse y son :
" > cpp_vscode    : Para C/C++ y Rust. Adaptador de Microsoft para los debugger MSVC, LLDB y GDB.
"                   En windows, el adaptador para MSVC esta licenciado, por lo que debe usar LLDB.
"                   Mayor prioridad para C/C++ y Rust debido a que nvim-dapui se integra mejor.
" > cpp_lldb_dap  : Para C/C++ y Rust. Adaptador DAP 'lldb-dap' nativo de LLDB creado por LLVM.
"                   Menor prioridad que el anterior.
" > cpp_lldb_code : Para C/C++ y Rust. Adaptador 'codelldb' para el depurador LLDB.
"                   Menor prioridad que el anterior.
" > cpp_gdb       : Para C/C++ y Rust. Conexion directa al depurador DBG de GNU Linux que soporta DAP.
"                   Menor prioridad que el anterior.
" > go_vscode     : Para GoLang. Adaptador DAP 'vscode-go' para el depurador 'delve' de GoLang.
" > go_native     : Para GoLang. Usar directamente el depurador 'delve' de GoLang.
"                   Soporta a DAP nativo del depurador 'delve' aun es experimental.
" > csharp        : Depurador 'NetCoreDbg' con soporte a DAP para .NET de Samsumg.
" > swift         : Para Swift.
" > kotlin        : Para Kotlin.
" > python        : Para Python. Usa el adaptador DAP 'debugpy' para el debugger de Python.
" > typescript    : Para Typescript/Javascript. Actualmente solo soporte al uso como backend.
" Estableciendo el valor por defecto si no se define antes.
if !exists("g:use_dap_adapters") || empty(g:use_dap_adapters)
    let g:use_dap_adapters = {
    "\   'cpp_lldb_dap'  : v:true,
    "\   'cpp_lldb_code' : v:true,
    "\   'cpp_gdb'       : v:true,
    \   'cpp_vscode'    : v:true,
    \   'go_vscode'     : v:true,
    "\   'go_native'     : v:true,
    \   'csharp'        : v:true,
    "\   'swift'         : v:true,
    "\   'kotlin'        : v:true,
    \   'python'        : v:true,
    \   'typescript'    : v:true,
    \}
endif


" Ejecutar el fixers (si este esta configurado para el filetype actual) cuando se guarda el documento.
" > Si el fixer no tiene un regla configurada o no puede arreglar un error/warning, no lo hace.
" > Muchos fixer incluye en formato del documento como parte de su reglas predefinidas.
" El valor real, se obtendra segun orden de prioridad:
"  > El valor definido por la variable de entorno 'FIX_ON_SAVE'
"    > 0 ('true' ), si se desactiva las capacidades IDE.
"      Ejemplo : 'FIX_ON_SAVE=0 vim'
"    > 1 ('false'), si se preserva las capacidades IDE.
"      Ejemplo : 'FIX_ON_SAVE=1 vim'
"    > Cualquiere otro valor se considera no definido.
"  > El valor definido por esta variable VIM
"    > v:true (o diferente a '0') si es 'true'
"    > v:false (o '0') si es false.
"    > Si no se especifica, se considera no definido
" Si no se define, su valor por defecto es 'v:true' (valor diferente a 0).
if $FIX_ON_SAVE != ''

    if $FIX_ON_SAVE == 0
        let g:ale_fix_on_save = v:true
    elseif $FIX_ON_SAVE == 1
        let g:ale_fix_on_save = v:false
    else
        let g:ale_fix_on_save = v:true
    endif

elseif !exists("g:ale_fix_on_save")
    let g:ale_fix_on_save = v:true
endif


" Solo para NeoVIM. Habilitar el uso de COC.
" El valor real, se obtendra segun orden de prioridad:
"  > El valor definido por la variable de entorno 'USE_COC'
"    > 0 ('true'), se usa CoC
"      Ejemplo : 'USE_COC=0 vim'
"    > 1 ('false'), NO se usa CoC.
"      Ejemplo : 'USE_COC=1 vim'
"    > Cualquiere otro valor se considera no definido.
"  > El valor definido por esta variable VIM
"    > v:true (o diferente a '0 ') si es 'true'
"    > v:false (o '0') si es false.
"    > Si no se especifica, se considera no definido
" Si no se define, su valor por defecto es 'v:false' (valor 0).
if $USE_COC != ''

    if $USE_COC == 0
        let g:use_coc = v:true
    else
        let g:use_coc = v:false
    endif

elseif !exists("g:use_coc")
    let g:use_coc = v:false
endif

" Habilitar el soporte de 'Spring Boot' el el LSP 'Eclipse JDTLS'
" Por defecto es false
if !exists("g:java_springboot")
    let g:java_springboot = v:false
endif


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


"#########################################################################################################
" Setup plugins de IDE
"#########################################################################################################

if !g:use_ide
    finish
endif

" Librerias utiles del IDE:
" > Librerias para ejecuciones asincronas.
" > Plugin para mejorar el typing code.
runtime setting/ide/ide_utils.vim

" Setting IDE Core (LSP client, Completion, Diagnostic, etc.)
" > Solo en VIM, se define:
"   - Code Outline (esquema de codigo del buffer): 'vista.vim'.
"     Se integra con LSP cliente de CoC y con CTags.
" > En VIM o NeoVIM con CoC, se define:
"   - Cliente LSP, Completion, Otros: CoC.nvim
"   - Los servidores LSP y/o adaptadores LSP usualmente se realiza instalando una extension CoC.
"   - Diagnostico (Linting, Fixing) y Formatting code: ALE
"   - Snippets: La extension 'coc-Snippets' y la fuente de snippets 'vim-snippets'.
"   - Plugins con Clientes LSP personalizados.
"     Por ejemplo: adaptador LSP para C# (OmniSharp)
" > En NeoVIM sin CoC, se define:
"   - Cliente LSP : Se usara el API nativo 'vim.lsp' y 'nvim-lspconfig' para facilitar su configuración.
"   - Los servidores LSP y/o adaptadores LSP se desacargarn manualmente (usando un script bash).
"   - Completion : se usara 'nvim-cmp' y plugins para sus diversas fuentes de autocompletado.
"   - Diagnostico (Linting, Fixing) y Formatting code: ALE (el cual usa el API de diagnostico nativo).
"   - Snippets: 'LuaSnippet' y la fuente de snippets 'friendly-snippets'.
"   - Plugins que configuran clientes LSP y/o su adapador y ofrecen mas capacidades:
"     Por ejemplo: nvim-jdtls para Java.
" > En NeoVIM (use o no use CoC), se define:
"   - Code Outline (esquema de codigo del buffer): 'aerial.nvim'.
"     Aunque no se podra integrar al cliente LSP creado por CoC, se integrara al arbol AST creado por treesitter.
"   - Treesitter como un analizador del arbol sinstanctico de codigo (AST) el cual permite:
"     - Resaltado de sintaxis de codigo (highlighting)
"     - Navegar y selecionar objetos del arbol AST.
"     - Indentación automática mejorada.
"     - Incremental selection (seleccionar nodos de sintaxis con combinaciones de teclas).
"     - Folding basado en estructura sintáctica.
"     - Text objects basados en sintaxis real.
runtime setting/ide/ide_development.vim

" Capacidades de testing (incluyendo debugging) del IDE
" > Para Debugging en VIM, se usan 'vimspector', el cual incluye:
"   - Cliente DAP y adaptadores de varios debugger con soporte parcial a DAP.
"   - UI para debugging
" > Para Debugging en NeoVIM, se usara 'nvim-dap' y 'nvim-dapui'
" > Para 'Unit testing' en VIM se usara 'vim-test' (facilita la ejecucion desde vim)
" > Para 'Unit testing' en NeoVIM se usara 'nvim-neotest' el cual permite:
"   - Facilita la ejecucion desde NeoVIM.
"   - Muestra reportes de la ejecucion e indicadores del estado en buffer de las pruebas ejecutadas.
runtime setting/ide/ide_testing.vim

" Capacidades adicionales de IDE
" > Client REST
" > Tools for GIT
" > IA Chat
" > AI Agent
runtime setting/ide/ide_extended.vim
