"
" Se recomienda ejecutar ('~/.files/shell/powershell/bin/windowssetup/02_setup_profile.ps1') el script de 
" configuración del profile y escoger uno de los modos Editor o IDE, el cual creara los enlaces simbolicos
" requeridos para la inicialización de NeoVIM en dicho modo. El runtime path donde se encuentra el archivo 
" de inicialización de NeoVIM ('${env:USERPROFILE}\vimfiles\') tiene la siguiente estructura:
"  ./init.vim          -> Archivo de inicialización de NeoVIM como IDE
"                         En modo IDE, es un enlace simbolico a '~/.files/nvim/init_ide_windows.vim' 
"                         En modo editor, es un enlace simbolico a '~/.files/nvim/init_basic_windows.vim' 
"  ./coc-settings.json -> Archivo de configurarion de CoC (solo es usado cuando esta en modo IDE y se usan
"                         la variable de entorno 'USE_COC=1'. 
"                         Es un enlace a '~/.files/nvim/coc-settings_linux.json'
"  ./setting/         -> Carpeta de script VimScript de configuracion de VIM/NeoVIM invocados desde el 
"                         archivo de inicialización. Es un enlace simbolico a '~/.files/vim/setting/'.
"  ./lua/              -> Carpeta de script LUA de configuracion de NeoVIM invocados por los script
"                         ubicados en './setting/plugin/' ('ui_core.vim', 'ui_extended.vim' y 
"                         'ui_ide_core.vim'). Es un enlace simbolico a '~/.files/nvim/lua/'.
"  ./ftplugin/         -> Carpeta de plugin de filetypes usado por cualquier IDE.
"                         En modo IDE, es un enlace simbolico a '~/.files/nvim/ftplugin/cocide/'.
"                         En modo Editor, es un enlace simbolico a '~/.files/nvim/ftplugin/editor/'.
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

" Ruta base para los servidores LSP y DAP. Los valores por defecto son:
" En Linux :
"   > Path base del LSP Server : '/var/opt/tools/lsp_servers'
"   > Path base del DAP Server : '/var/opt/tools/dap_servers'
" En Windows :
"   > Path base del LSP Server : 'C:/cli/prgs/lsp_servers'
"   > Path base del DAP Server : 'C:/cli/prgs/dap_servers'
" Modiquelo si desea cambiar ese valor.
let g:home_path_lsp_server = get(g:, 'home_path_lsp_server', 'C:/cli/prgs/lsp_servers')
let g:home_path_dap_server = get(g:, 'home_path_dap_server', 'C:/cli/prgs/dap_servers')

" Solo para Linux WSL donde Rosalyn tambien esta instalado en Windows.
" Si es 1 ('true'), se re-usara el LSP Server C# (Roslyn) instalado en Windows.
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
" Su valor por defecto es 0 ('false').
let g:using_lsp_server_cs_win = get(g:, 'using_lsp_server_cs_win', 0)


"#########################################################################################################
" Basic Settings
"#########################################################################################################

runtime setting/core_setting.vim
runtime setting/core_mapping.vim


"#########################################################################################################
" Load plugins
"#########################################################################################################

"Registro de los plugin en los gestores de plugins (si se usa)
"Carga automatica de algunos plugins por el gestor de paquetes
"Carga manual de plugin
"Configuracion de basica de plugins basicos:
"  - Configuracion basica requeridos antes de la carga de un plugin
"  - Establecer el 'Color Schema' del tema (requerido antes de cualquier plugin UI)
runtime setting/plugin_load.vim


"#########################################################################################################
" Setup plugins (UI)
"#########################################################################################################

"StatusLine, TabLine, TMUX, ...
runtime setting/plugin/ui_core.vim

"Utilitarios basicos: FZF, NERDTree, ...
runtime setting/plugin/ui_extended.vim


"#########################################################################################################
" Setup plugins (IDE)
"#########################################################################################################

if !g:use_ide
    finish
endif

"Setting Typing del IDE:
runtime setting/plugin/ui_ide_typing.vim

"Setting IDE Core : Diagnostic (Linting y Fixing), LSP client, Completition, ...
"En VIM se define:
"   - Diagnostico : ALE
"   - Interprese Lenguage Server (incluye LSP server) y Completition : CoC.nvim
"   - Snippets : UltiSnippets
runtime setting/plugin/ui_ide_core.vim

"Adaptadores de Lenguajes personalizados: C# (OmniSharp)
"Implementa :
"   - LSO cliente para LSP server Roslyn
"   - Source para ALE linting (Linter para C#)
"   - Source de autocompletado para Coc (y otros motores de autocompletado
"   - Source para UltiSnippets
runtime setting/plugin/ui_ide_lsp_cs.vim


