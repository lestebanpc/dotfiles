"--------------------------------------------------------------------------------
"1. Inicialización
"--------------------------------------------------------------------------------
if !g:use_ide | finish | endif
if get(b:, 'json_ftplugin_loaded', 0) | finish | endif


"--------------------------------------------------------------------------------
"2. Linter y Fixer
"--------------------------------------------------------------------------------

"Estableciendo el Linter: ESLint.
"let b:ale_linters = ['eslint']
"let b:ale_linters = {'json': ['eslint']}

"Estableciendo el Fixer : Prettier y ESLint.
"let b:ale_fixers = ['prettier']
let b:ale_fixers = {'json': ['prettier']}


"--------------------------------------------------------------------------------
"3. Finalización
"--------------------------------------------------------------------------------

"Flag de buffer cargado
let b:json_ftplugin_loaded = 1



