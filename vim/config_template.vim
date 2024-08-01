"#########################################################################################
" Variables globales generales
"#########################################################################################

" Habilita el uso del TabLine (barra superior donde se muestran los buffer y los tabs).
" Valor por defecto es 1 ('true'). 
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
"let g:use_tabline = 1

" Habilitar el plugin de typing 'vim-surround', el cual es usado para encerar/modificar
" texto con '()', '{}', '[]' un texto. Valor por defecto es 0 ('false').
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
" Si cambia este valor, recargar/cerrar VIM para volver a cargar los plugin.
"let g:use_typing_surround = 0

" Habilitar el plugin de typing 'emmet-vim', el cual es usado para crear elementos
" HTML usando palabras claves. Valor por defecto es 0 ('false').
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
" Si cambia este valor, recargar/cerrar VIM para volver a cargar los plugin.
"let g:use_typing_html_emmet = 0

" Habilitar el plugin de typing 'vim-visual-multi', el cual es usado para realizar seleccion
" multiple de texto. Valor por defecto es 0 ('false').
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
" Si cambia este valor, recargar/cerrar VIM para volver a cargar los plugin.
"let g:use_typing_visual_multi = 0

"#########################################################################################
" Variables globales para VIM/NeoVim en modo IDE
"#########################################################################################

" Ruta base para los servidores LSP y DAP. Los valores por defecto son:
" En Linux :
"   > Path base del LSP Server : '/var/opt/tools/lsp_servers'
"   > Path base del DAP Server : '/var/opt/tools/dap_servers'
" En Windows :
"   > Path base del DAP Server : 'C:/cli/prgs/dap_servers'
"   > Path base del LSP Server : 'C:/cli/prgs/lsp_servers'
" Modiquelo si desea cambiar ese valor.
"let g:home_path_dap_server = 'D:/cli/prgs/dap_servers'
"let g:home_path_lsp_server = 'D:/cli/prgs/lsp_servers'
"let g:home_path_lsp_server = $HOME .. '/tools/lsp_servers'
"let g:home_path_dap_server = $HOME .. '/tools/dap_servers'

" Solo para Linux WSL donde Rosalyn tambien esta instalado en Windows.
" Si es 1 ('true'), se re-usara el LSP Server C# (Roslyn) instalado en Windows.
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
" Su valor por defecto es 0 ('false').
"let g:using_lsp_server_cs_win = 0

