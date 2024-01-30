"--------------------------------------------------------------------------------
"1. Inicialización
"--------------------------------------------------------------------------------
if !g:use_ide | finish | endif
if get(b:, 'js_ftplugin_loaded', 0) | finish | endif


"--------------------------------------------------------------------------------
"2. Linter y Fixer
"--------------------------------------------------------------------------------

"Estableciendo el Linter: ESLint
"let b:ale_linters = ['eslint']
let b:ale_linters = {'javascript': ['eslint']}

"Estableciendo el Fixer : Prettier y ESLint.
"let b:ale_fixers = ['prettier', 'eslint']
let b:ale_fixers = {'javascript': ['prettier', 'eslint']}


"--------------------------------------------------------------------------------
"3. Finalización
"--------------------------------------------------------------------------------

"Flag de buffer cargado
let b:js_ftplugin_loaded = 1


