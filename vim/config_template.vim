"#########################################################################################
" Variables globales generales
"#########################################################################################

" Habilita el uso del TabLine (barra superior donde se muestran los buffer y los tabs).
" Valor por defecto es 1 ('true'). 
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
"let g:use_tabline = 1


"#########################################################################################
" Variables globales para VIM/NeoVim en modo IDE
"#########################################################################################

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


" Habilitar el plugin de AI. Valor por defecto es 1 ('true').
" Valor '0' es considerado 'false', otro valor es considerado 'true'.
" Si cambia este valor, recargar/cerrar VIM para volver a cargar los plugin.
"let g:use_ai_plugins = 0


" Ruta base donde se encuentra los programas requeridos por VIM/NeoVIM.
" Sus valores por defecto son:
"   > En Linux   : '/var/opt/tools'
"   > En Windows : 'c:/cli/prgs'
" Dentro de esta ruta se debe encontrar (entre otros) los subfolderes:
"   > Ruta base donde estan los LSP Server            : './lsp_servers/'
"   > Ruta base donde estan los DAP Server            : './dap_servers/'
"   > Ruta base donde estan las extensiones de vscode : './vsc_extensions/'
" Modiquelo si desea cambiar ese valor el valor por defecto.
"let g:programs_base_path = 'D:/cli/prgs'
"let g:programs_base_path = $HOME .. '/tools'



