"--------------------------------------------------------------------------------
"1. Inicialización
"--------------------------------------------------------------------------------
if get(b:, 'py_ftplugin_loaded', 0) | finish | endif

"El 'workspace' de CoC es la carpeta mas cerca al archivo del buffer que tenga una de las siguiente subcarpetas:
let b:coc_root_patterns = ['.git', '.env']

"--------------------------------------------------------------------------------
"2. ¿?
"--------------------------------------------------------------------------------

"--------------------------------------------------------------------------------
"3. Finalización
"--------------------------------------------------------------------------------

"Flag de buffer cargado
let b:py_ftplugin_loaded = 1


