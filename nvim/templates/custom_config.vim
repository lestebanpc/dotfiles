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

" Para NeoVIM, deshabilitar el treesitter (en caso de no tener un compilador C/C++) requirido por nvim-treesitter.
" Por defecto, si no se define su valor es 'v:true' (se habilita la compilacion de tree-sitter).
"let g:enable_compile_treesitter = v:true
"let g:enable_compile_treesitter = v:false
"let g:enable_compile_treesitter = v:null



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


" Habilitar el plugin de 'AI Autocompletion' (solo NeoVIM).
" > Para 'AI Autocompletion' se configurara como una fuente de completado de NeoVIM.
" > El valor real, se obtendra segun orden de prioridad:
"   > El valor definido por la variable de entorno 'AI_COMPLETION'
"     > 0 si usara el broker LLM de 'GitHub Copilot' usando el plugin 'zbirenbaum/copilot.lua'.
"     > 1 si usara un LLM (local o externo) o un broker LLM soportado por el plugin 'milanglacier/minuet-ai.nvim'.
"     > Cualquier otro valor se considera no definido.
"  > El valor definido por esta variable VIM 'g:use_ai_completion'.
"     > 0 si usara el broker LLM de 'GitHub Copilot' usando el plugin 'zbirenbaum/copilot.lua'.
"     > 1 si usara el LLM (local o externo) o ub broker LLM soportado por el plugin 'milanglacier/minuet-ai.nvim'.
"     > Cualquier otro valor se considera no definido.
" Si no esta definido, no se usara ningun plugin de 'AI autocompletion'.
"let g:use_ai_completion = 0
"let g:use_ai_completion = v:null


" Si esta habilitado el 'AI Autocompletion', a que archivos se habiltara el autocompletado por AI,
" Definir los valores por defecto si no han sido definidos.
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


" Habilitar el plugin de 'AI Agent' (solo NeoVIM).
" > Para 'AI Agent' se puede usar un agente integrado dentro del editor y integrarse a un agente externo usualmente
"   de tipo CLI.
" > El valor real, se obtendra segun orden de prioridad:
"   > El valor definido por la variable de entorno 'AI_AGENT'.
"     > 0 Si usara un 'AI agent' integrado con NeoVIM (usa el plugin 'yetone/avante.nvim').
"       > Siempre estara desactivado su capacidad de 'AI autocomplete' debido a que no se integra como fuente de autocompletado.
"     > 1 Si integra con 'AI agent' externo (de tipo 'CLI AI agent') conocido como 'OpenCode CLI' (usa el plugin 'NickvanDyke/opencode.nvim').
"     > 2 Si integra con 'AI agent' externo (de tipo 'CLI AI agent') conocido como 'Gemini CLI'.
"     > 3 Si integra con 'AI agent' externo (de tipo 'CLI AI agent') conocido como 'Qwen CLI'.
"     > Cualquier otro valor se considera no definido.
"  > El valor definido por esta variable VIM 'g:use_ai_agent'.
"     > 0 Si usara un 'AI agent' integrado con NeoVIM (usa el plugin 'yetone/avante.nvim').
"       > Siempre estara desactivado su capacidad de 'AI autocomplete' debido a que no se integra como fuente de autocompletado.
"     > 1 Si integra con 'AI agent' externo (de tipo 'CLI AI agent') conocido como 'OpenCode CLI' (usa el plugin 'NickvanDyke/opencode.nvim').
"     > 2 Si integra con 'AI agent' externo (de tipo 'CLI AI agent') conocido como 'Gemini CLI'.
"     > 3 Si integra con 'AI agent' externo (de tipo 'CLI AI agent') conocido como 'Qwen CLI'.
"     > Cualquier otro valor se considera no definido.
" Si no esta definido, no se usara ningun plugin de agente AI.
"let g:use_ai_agent = 1


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
"  > typescript    : Para Javascript/Typescript. Usa 'Typescript LS' un adapador de 'TsServer'
"                    Use linter como 'eslint' y 'biome' para mejorar el linting.
"  > lua_nvim      : Para Lua. Usa el LSP 'Lua LS' pero configurado para crear LUA en Neovim.
"                    Si se define tambien 'lua', 'lua_nvim' prevalece.
"  > lua           : Para Lua. Usa el LSP 'Lua LS'.
"  > viml          : Para VimScript. Usa el LSP 'Vim LS'.
"  > bash          : Para Bash. Usa de 'Bash LS'
"  > powershell    : Para Powershell. Usa de 'Powershell Editor Service'.
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
" Comente/descomente, establezca el valor de las lineas deseadas.
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
\   'json'          : v:true,
\   'yaml'          : v:true,
\   'toml'          : v:true,
\   'xml'           : v:true,
\   'markdown'      : v:true,
\   'html'          : v:true,
\   'css'           : v:true,
"\   'tailwindcss'   : v:true,
\   'kulala'        : v:true,
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
"\   'cpp'         : ['clangtidy'],
"\   'c'           : ['clangtidy'],
"\   'rust'        : ['clippy'],
"\   'go'          : ['golangci-lint'],
"\   'cs'          : ['OmniSharp'],
"\   'python'      : ['pylint', 'flake8'],
"\   'xml'        : ['xmllint'],
\   'http'        : ['kulala_fmt'],
\   'rest'        : ['kulala_fmt'],
\   'dockerfile'  : ['hadolint'],
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
\   'http'        : ['kulala_fmt'],
\   'rest'        : ['kulala_fmt'],
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
"    > v:false (o '0') si es false.:
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



"#########################################################################################
" IDE> Variables globales solo para NeoVim en modo developer
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

" Nombre del programa que creara el DAP server 'debugpy' de python.
" > El programa debera especificar su ruta absoluta o estar el PATH del usuario.
" > El inteprete python usado para ejecutar el servidor DAP 'debugpy' no requiere que sea el mismo del programa a depurar.
" > Valores posibles:
"   > 'python' y 'python3', para Windows/Mac y Linux respectivamente.
"     > Usar el inteprete python para crear el servidor 'debugpy'.
"   > 'debugpy-adapter'
"     > Comando creado cuando se instala 'debugpy' y permite crear el servidor 'debugpy'
"     > Identifica automaticamente el interprete python a usar, por lo que no se debe espeficar.
"   > 'uv'
"     > Comando que permite crear el servidor 'debugpy'.
"     > Identifica automaticamente el interprete python a usar, por lo que no se debe espeficar.
"   > Ruta absoluta de 'python', 'python3' o 'debugpy-adapter' cuando esta instalado en entorno virtual.
" > Valor por defecto: 'python3' en Linux y 'python' en cualquier otro sistema.
"let g:dap_launcher_python = 'python'

" Obtener el framework de testing de Python a usar
" > Los valores puede ser: 'unittest', 'pytest', 'django'
" > Para determinar el framework, se usara la siguiente prioridad:
"   > Usar el framework especificado por la variable global
"   > Si no se especifica se intentara obtener detectar el framework a usar.
"   > Si no logra determinar el framework usara 'unittest'
"let g:python_tester_type = 'pytest'

" Habilitar el soporte de 'Spring Boot' el el LSP 'Eclipse JDTLS'
" Por defecto es false
"let g:java_springboot = v:false
