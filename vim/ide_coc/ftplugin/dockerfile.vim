"--------------------------------------------------------------------------------
"1. Inicialización
"--------------------------------------------------------------------------------
if !g:use_ide | finish | endif
if get(b:, 'dockerfile_ftplugin_loaded', 0) | finish | endif


"--------------------------------------------------------------------------------
"2. Linter y Fixer
"--------------------------------------------------------------------------------

"Estableciendo el Linter: HadoLint
"let b:ale_linters = ['hadolint']
let b:ale_linters = {'dockerfile': ['hadolint']}

"Estableciendo el Fixer: HadoLint
"let b:ale_fixers = ['hadolint']
"let b:ale_fixers = {'dockerfile': ['hadolint']}


"--------------------------------------------------------------------------------
"3. Finalización
"--------------------------------------------------------------------------------

"Flag de buffer cargado
let b:dockerfile_ftplugin_loaded = 1





