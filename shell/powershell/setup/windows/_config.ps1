
# Folder base, donde se almacena el programas, comando y afines usados por Windows.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es un valor valido, se asignara un sus posibles valores (segun orden de prioridad):
#     > "D:\CLI"
#     > "C:\CLI"
# - En este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_path_base_win}\Programs"     : subfolder donde se almacena los subfolder de los programas.
#     > "${g_path_base_win}\Commands\bin" : subfolder donde se almacena los comandos.
#     > "${g_path_base_win}\Commands\man" : subfolder donde se almacena los archivos de ayuda man1 del comando.
#     > "${g_path_base_win}\Commands\doc" : subfolder donde se almacena documentacion del comando.
#     > "${g_path_base_win}\Commands\etc" : subfolder donde se almacena archivos adicionales del comando.
#$g_path_base_win='D:\CLI\'

# Folder base donde se almacena data temporal que sera eliminado automaticamente despues completar la configuración.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es valido, la funcion "set_temp_path" asignara segun orden de prioridad a '$env:TEMP'.
#$g_path_temp='C:\Windows\Temp'

# Usado solo durante la instalación. Define si se instala solo la ultima version de un programa.
#Por defecto es 1 (considerado 'false'). Solo si su valor es '0', es considera 'true'.
#$g_setup_only_last_version=1


