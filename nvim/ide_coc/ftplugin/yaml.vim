"--------------------------------------------------------------------------------
"1. Inicialización
"--------------------------------------------------------------------------------
if !g:use_ide | finish | endif
if get(b:, 'yaml_ftplugin_loaded', 0) | finish | endif


"--------------------------------------------------------------------------------
"2. Linter y Fixer
"--------------------------------------------------------------------------------

"Estableciendo el Linter: Usando como linter a ESLint.
"A nivel buffer no requiere especifcar el 'file type' (este se obtendra del 'file type' del buffer)
"let b:ale_linters = ['eslint']
"let b:ale_linters = {'yaml': ['eslint']}

"Estableciendo el Fixer : Usando como fixer a prettier y ESLint.
"A nivel buffer no requiere especifcar el 'file type' (este se obtendra del 'file type' del buffer)
"let b:ale_fixers = ['prettier']
let b:ale_fixers = {'yaml': ['prettier']}


"--------------------------------------------------------------------------------
"3. Finalización
"--------------------------------------------------------------------------------

"Flag de buffer cargado
let b:yaml_ftplugin_loaded = 1



