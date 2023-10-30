"----------------------------- Variables Iniciales    -----------------------------

"Habilita el uso del TabLine (barra superior donde se muestran los buffer y los tabs)
let g:use_tabline = 1

"Habilita el uso de IDE (En VIM, puede ser desabilitado si se cumple los requisitos minimos)
let g:use_ide = 1

"----------------------------- Variables usados x IDE  -----------------------------

"Habilitar Typing
let g:use_typing_html_emmet = 1
let g:use_typing_surround = 1
let g:use_typing_visual_multi = 1

"Ruta base para los servidores LSP y DAP
let g:home_path_dap_server = 'D:/Tools/CLI/DAP_Servers'
let g:home_path_lsp_server = 'D:/Tools/CLI/LSP_Servers'

"----------------------------- Basic Settings          -----------------------------
source C:/Users/LucianoWin/.files/vim/setting/core_setting.vim
source C:/Users/LucianoWin/.files/vim/setting/core_mapping.vim

"----------------------------- Load plugins            -----------------------------
"Registro de los plugin en los gestores de plugins (si se usa)
"Carga automatica de algunos plugins por el gestor de paquetes
"Carga manual de plugin
"Configuracion de basica de plugins basicos:
"  - Configuracion basica requeridos antes de la carga de un plugin
"  - Establecer el 'Color Schema' del tema (requerido antes de cualquier plugin UI)
source C:/Users/LucianoWin/.files/vim/setting/plugin_load.vim

"----------------------------- Setup plugins (UI)       ----------------------------
"StatusLine, TabLine, TMUX, ...
source C:/Users/LucianoWin/.files/vim/setting/plugin/ui_core.vim

"Utilitarios basicos: FZF, NERDTree, ...
source C:/Users/LucianoWin/.files/vim/setting/plugin/ui_extended.vim

"----------------------------- Setup plugins (IDE)     -----------------------------
if !g:use_ide
    finish
endif

"Setting Typing del IDE:
source C:/Users/LucianoWin/.files/vim/setting/plugin/ui_ide_typing.vim

"Setting IDE Core : Diagnostic (Linting y Fixing), LSP client, Completition, ...
"En VIM se define:
"   - Diagnostico : ALE
"   - Interprese Lenguage Server (incluye LSP server) y Completition : CoC.nvim
"   - Snippets : UltiSnippets
source C:/Users/LucianoWin/.files/vim/setting/plugin/ui_ide_core.vim

"Adaptadores de Lenguajes personalizados: C# (OmniSharp)
"Implementa :
"   - LSO cliente para LSP server Roslyn
"   - Source para ALE linting (Linter para C#)
"   - Source de autocompletado para Coc (y otros motores de autocompletado
"   - Source para UltiSnippets
source C:/Users/LucianoWin/.files/vim/setting/plugin/ui_ide_lsp_cs.vim

