"#########################################################################################
" Variables globales para VIM/NeoVim
"#########################################################################################
"

" Estableciento manual del modo de escritura (copy) al clipboard a usar por VIM/NeoVim
" El valor real, se obtendra segun orden de prioridad:
"  > El valor definido por la variable de entorno 'CLIPBOARD'
"    Ejemplo : 'CLIPBOARD=1 vim'
"  > El valor definido por esta variable VIM 'g:clipboard_mode'.
" Sus valores es un entero y puden ser:
"  > '0', si se usa el mecanismo nativo de escritura al clipboard de NeoVIM
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
"let g:clipboard_mode = 1


" Solo se debe usar si 'clipboard_mode' es '1' (manual o automático).
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
"let g:clipboard_osc52_format = 0




"#########################################################################################
" IDE> Variables globales para VIM/NeoVim
"#########################################################################################
"

" Deshabilitación manual de las capacidades de modo IDE
"  > La deshabilitación automatica de las capacidades de modo IDE se realiza si no cumple requisitos
"    minimos de un IDE.
" El valor real, se obtendra segun orden de prioridad:
"  > El valor definido por la variable de entorno 'USE_EDITOR'
"    > 0 ('true' ), si se desactiva las capacidades IDE.
"      Ejemplo : 'USE_EDITOR=0 vim'
"    > 1 ('false'), si se preserva las capacidades IDE.
"      Ejemplo : 'USE_EDITOR=1 vim'
"    > Cualquiere otro valor se considera no definido.
"  > El valor definido por esta variable VIM
"    > v:true (o diferente a '0') si es 'true'
"    > v:false (o '0') si es false.
"    > Si no se especifica, se considera no definido
" Si no se define, su valor por defecto es 'v:true' (valor diferente a 0).
"let g:use_ide = v:false


" Los plugins de typing disponibles son :
"  > 'surround'
"    > Plugin de typing 'vim-surround'
"    > Es usado para encerar/modificar texto con '()', '{}', '[]' un texto.
"  > 'html_emmet'
"    > Plugin de typing 'emmet-vim', el cual es usado para crear elementos html.
"  > 'visual_multi'
"     > Plugin de typing 'vim-visual-multi', el cual es usado para realizar seleccion multiple
"       de texto.
" Si no se define se considera 'v:false' (o '0').
" Comente/descomente, establezca el valor de las lineas deseadas.
"let g:use_typing_plugins = {
"\   'surround'     : v:false,
"\   'html_emmet'   : v:false,
"\   'visual_multi' : v:false,
"\}


" Habilitar los plugin de AI.
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
"let g:use_ai_plugins = v:false


" Ruta base donde se encuentra los programas requeridos por VIM/NeoVIM.
" Su valor se calculara, segun prioridad, usando:
"  > Valor definido en la variable de entorno 'MY_PRGS_PATH' (siempre que defina un valor).
"  > Si no define un valor, se usara la ruta indicada en esta variable global vim 'g:programs_base_path'.
"  > Si no se define una variable o es vacia, se usara el valor por defecto es : '/var/opt/tools'.
" Dentro de esta ruta se debe encontrar (entre otros) los subfolderes:
"   > Ruta base donde estan los LSP Server            : './lsp_servers/'
"   > Ruta base donde estan los DAP Server            : './dap_servers/'
"   > Ruta base donde estan las extensiones de vscode : './vsc_extensions/'
" Modiquelo si desea cambiar ese valor el valor por defecto.
"let g:programs_base_path = 'C:/cli/prgs'
"let g:programs_base_path = 'D:/cli/prgs'
"let g:programs_base_path = $HOME .. '/tools'


" Adaptadores LSP en modo IDE Vim/NeoVim cuando se usa CoC :
"  > omnisharp_vim : Para C#. Usa el servidor 'Omnisharp LS' pero usando el plugin 'omnisharp_vim'.
"                    El plugin de omnisharp-vim requiere de un motor de autocompletado y uno de los
"                    motor de completado compatible es CoC.
"  >               : Los demas adaptadores son gestionados por CoC (como extension o en su
"                    archivo de configuración)
" Adaptadores LSP en modo IDE NeoVim cuando se usa el cliente LSP nativo :
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
"  > typescript    : Para Javascript/Typescript. Usa 'Typescript LS' un adapador de 'TsServer'
"  > lua           : Para Lua. Usa el LSP 'Lua LS'.
"  > viml          : Para VimScript. Usa el LSP 'Vim LS'.
"  > bash          : Para Bash. Usa de 'Bash LS'
"  > ansible       : Para Ansible. Usa de 'Ansible LS' (requiere Python, Ansible y Ansible-Lint).
"  > markdown      : Para archivo Markdown.
" Solo aplica si NO usa CoC. CoC estas configuracion se realiza usualmente por extensiones.
" Comente/descomente, establezca el valor de las lineas deseadas.
"let g:use_lsp_adapters = {
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
"\   'lua'           : v:true,
"\   'viml'          : v:true,
"\   'bash'          : v:true,
"\   'ansible'       : v:true,
"\   'markdown'      : v:true,
"\}



"#########################################################################################
" IDE> Variables globales solo para NeoVim
"#########################################################################################
"

" Habilitar el uso de COC.
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
"let g:use_coc = v:false


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
" Comente/descomente, establezca el valor de las lineas deseadas.
"let g:use_dap_adapters = {
"\   'cpp_lldb_dap'  : v:true,
"\   'cpp_lldb_code' : v:true,
"\   'cpp_gdb'       : v:true,
"\   'cpp_vscode'    : v:true,
"\   'go_vscode'     : v:true,
"\   'go_native'     : v:true,
"\   'csharp'        : v:true,
"\   'swift'         : v:true,
"\   'kotlin'        : v:true,
"\   'python'        : v:true,
"\   'typescript'    : v:true,
"\}



"#########################################################################################
" IDE> Variables para configurar el Linter/Fixer de ALE (VIM/NeoVim)
"#########################################################################################
"
" Activar los linter a usar
" > Si establece 'v:null' o '{}', se activara los linter definido por defecto..

"let g:ale_linters = {
"\   'cpp': ['clangtidy'],
"\   'c':   ['clangtidy'],
"\   'rust': ['clippy'],
"\   'go': ['golangci-lint'],
"\   'cs': ['OmniSharp'],
"\   'python': ['pylint', 'flake8'],
"\   'dockerfile': ['hadolint'],
"\   'javascript': ['eslint'],
"\   'typescript': ['eslint'],
"\}

"let g:ale_linters = v:null
"let g:ale_linters = {}


" Activar los fixer a usar
" > Si establece 'v:null' o '{}', se activara los linter definido por defecto.

"let g:ale_fixers = {
"\   '*': ['remove_trailing_lines', 'trim_whitespace'],
"\   'cpp': ['clang-format', 'clangtidy'],
"\   'c':   ['clang-format', 'clangtidy'],
"\   'rust': ['rustfmt'],
"\   'go': ['gofmt', 'goimports'],
"\   'python': ['black', 'isort'],
"\   'javascript': ['prettier', 'eslint'],
"\   'typescript': ['prettier', 'eslint'],
"\   'yaml': ['prettier'],
"\   'json': ['prettier'],
"\   'html': ['prettier'],
"\   'css':  ['prettier'],
"\}

"let g:ale_fixers = v:null
"let g:ale_fixers = {}


" ---------------------------------------------------------------------------------------
" Para C++ (Linter 'CLangTidy' y Fixer 'CLang-Format')
" ---------------------------------------------------------------------------------------
"
" Opciones del linter 'CLangTidy' (opcionalmente, puede usar un archivo '.clang-tidy')
"let g:ale_cpp_clangtidy_options = '--checks=modernize-*,readability-*'
"leg g:ale_cpp_clangtidy_options = '--checks=modernize-*,performance-*,bugprone-* --header-filter=.*'

" Opciones del fixer 'CLang-Format')
"let g:ale_cpp_clangformat_options = '--style=Google'


" ---------------------------------------------------------------------------------------
" Para Rust (Linter 'Clippy' y Format 'rustfmt')
" ---------------------------------------------------------------------------------------
"
" Opciones del linter 'Clippy'
"let g:ale_rust_clippy_options = '-- -W clippy::pedantic -W clippy::nursery'


" ---------------------------------------------------------------------------------------
" Para Go (Linter 'golangci-lint' y Format 'gofmt' o 'goimports')
" ---------------------------------------------------------------------------------------
"
" Opciones del linter 'golangci-lint'
"let g:ale_go_golangci_lint_options = '--enable=all --fast --exclude-use-default=false'
"let g:ale_go_golangci_lint_options = '--enable=govet,staticcheck,typecheck,errcheck'
"let g:ale_go_golangci_lint_options = '--disable-all --enable=staticcheck --enable=errcheck'


" ---------------------------------------------------------------------------------------
" Para Python (Linters 'pylint' o 'flake8' y Formats 'black' o 'isort')
" ---------------------------------------------------------------------------------------
"


" ---------------------------------------------------------------------------------------
" Para Go (Linter 'eslint' y Format 'prettier')
" ---------------------------------------------------------------------------------------
"
