"#########################################################################################
" Variables globales para VIM/NeoVim
"#########################################################################################
"

" Determina si habilita el completado a nivel linea de comandos (modo editor o ide) incluyendo ':' y las
" busquedas '/' y '?'. Su valores pueden ser:
"  > '1' o 'v:true', si se habilita el completado en la linea de comandos.
"  > '0' o 'v:false', si se desabilita el completado en la linea de comandos.
"  >  Si no se define o es 'v:null', se considera que se habilita el completado.
"let g:cmdline_completion = v:false
"let g:cmdline_completion = v:true
"let g:cmdline_completion = v:null


" Establecer un mecanismo de escritura (copy) al clipboard para VIM/NeoVim, lo cual incluye:
"  > Acciones de escritura al clipboard usanbdo el valor de los registros VIM.
"  > EScritura automatica al clipboard despues de realizar el yank (si esta habilitado 'g:yank_to_clipboard').
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
"let g:clipboard_writer_mode = 1


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
"let g:clipboard_osc52_format = 0


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
"let g:yank_to_clipboard = v:true


" Por defecto el comando para escribir al clipboard siempre es calculado automaticamente cuando la variable
" 'g:clipboard_writer_mode' o 'CLIPBOARD' es 2
" > Este busca si existe comandos 'wl-copy', 'xclip' o 'xsel' en ese orden.
" > El comando a usarse se debera indicar las opciones/argumentos requeridos de usar el texto desde STDIN.
" En algunos casos, puede elegir otro comando o no usar el orden preestablecido, modifique esta variable.
" Si no se define, se calculara automaticamente.
"let g:clipboard_writer_cmd = 'wl-copy'
"let g:clipboard_writer_cmd = 'xclip -i -selection clipboard'
"let g:clipboard_writer_cmd = 'xsel -i -b'
"let g:clipboard_writer_cmd = '/mnt/c/windows/system32/clip.exe'
"let g:clipboard_writer_cmd = 'clip.exe'
"let g:clipboard_writer_cmd = 'pbcopy'
"let g:clipboard_writer_cmd = v:null


" Por defecto el comando para escribir al clipboard siempre es calculado automaticamente.
" En algunos casos, puede elegir otro comando o no usar el orden preestablecido, modifique esta variable.
" Si no se define, se calculara automaticamente.
"let g:clipboard_reader_cmd = 'wl-paste'
"let g:clipboard_reader_cmd = 'xclip -o -selection clipboard'
"let g:clipboard_reader_cmd = 'xsel --clipboard --output'
"let g:clipboard_reader_cmd = 'pwsh.exe -NoProfile -Command "Get-Clipboard"'
"let g:clipboard_reader_cmd = 'pbpaste'
"let g:clipboard_reader_cmd = v:null



"#########################################################################################
" IDE> Variables globales para VIM/NeoVim en modo developer
"#########################################################################################
"

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


" Ruta base donde se encuentra los programas requeridos por VIM/NeoVIM.
" Su valor se calculara, segun prioridad, usando:
"  > Valor definido en la variable de entorno 'MY_TOOLS_PATH' (siempre que defina un valor).
"  > Si no define un valor, se usara la ruta indicada en esta variable global vim 'g:tools_path'.
"  > Si no se define una variable o es vacia, se usara el valor por defecto es : '/var/opt/tools'.
" Dentro de esta ruta se debe encontrar (entre otros) los subfolderes:
"   > Ruta base donde estan los LSP Server            : './lsp_servers/'
"   > Ruta base donde estan los DAP Server            : './dap_servers/'
"   > Ruta base donde estan las extensiones de vscode : './vsc_extensions/'
" Modiquelo si desea cambiar ese valor el valor por defecto.
"let g:tools_path = 'C:/apps/tools'
"let g:tools_path = 'D:/apps/tools'
"let g:tools_path = $HOME .. '/tools'


" Adaptadores LSP en modo IDE Vim/NeoVim cuando se usa CoC :
"  > omnisharp_vim : Para C#. Usa el servidor 'Omnisharp LS' pero usando el plugin 'omnisharp_vim'.
"                    El plugin de omnisharp-vim requiere de un motor de autocompletado y uno de los
"                    motor de completado compatible es CoC.
"  >               : Los demas adaptadores son gestionados por CoC (como extension o en su
"                    archivo de configuración)
" Comente/descomente, establezca el valor de las lineas deseadas.
let g:use_lsp_adapters = {
\   'omnisharp_vim'     : v:false,
\}


" Activar los linter a usar
"  > Si establece 'v:null' o '{}', se activara los linter definido por defecto..
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
let g:ale_linters = {
\   'dockerfile'  : ['hadolint'],
"\   'cpp'         : ['clangtidy'],
"\   'c'           : ['clangtidy'],
"\   'rust'        : ['clippy'],
"\   'go'          : ['golangci-lint'],
"\   'cs'          : ['OmniSharp'],
"\   'python'      : ['pylint', 'flake8'],
"\   'xml'        : ['xmllint'],
"\   'javascript'  : ['eslint'],
"\   'typescript'  : ['eslint'],
\   'javascript'  : ['biome'],
\   'typescript'  : ['biome'],
\}


" Activar los fixer a usar
"  > Si establece 'v:null' o '{}', se activara los linter definido por defecto.
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
let g:ale_fixers = {
\   '*'          : ['remove_trailing_lines', 'trim_whitespace'],
"\   'cpp'        : ['clang-format', 'clangtidy'],
"\   'c'          : ['clang-format', 'clangtidy'],
"\   'rust'       : ['rustfmt'],
"\   'go'         : ['gofmt', 'goimports'],
"\   'python'     : ['black', 'isort'],
"\   'javascript' : ['prettier', 'eslint'],
"\   'typescript' : ['prettier', 'eslint'],
\   'javascript' : ['biome'],
\   'typescript' : ['biome'],
\   'yaml'       : ['prettier'],
\   'json'       : ['prettier'],
\   'html'       : ['prettier'],
\   'css'        : ['prettier'],
\}


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
"let g:ale_fix_on_save = v:true


" Ejecutar el linter (si este esta configurado para el filetype actual) cuando se guarda el documento.
" > Los errors/warning que detecta el linter dependera de las reglas configurada (por defecto incluye algunas).
"let g:ale_lint_on_save = v:true


" Por defecto NO activara el linter cuando se escribre.
" > Se recomienda usar las capacidade del linting y fixing basicas que ofrece su LSP.
"   - El LSP cuando se escribe realiza linting basico (analisis no tan profundo y enfocado en responder rapido).
"   - El LSP muestra 'Code Actions', el cual si el usario lo ejecuta, puede ejecutar fixing basico.
" > Solo usa el linting avanzado cuando se guarda el documento.
"let g:ale_lint_on_text_changed = 'never'


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
