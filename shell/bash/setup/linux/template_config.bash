#!/bin/bash

# Nota: Esta variables no es usado para el script "04_setup_packages.bash"

##############################################################################################
# Usado por los script "00_setup_summary.bash", "01_setup_commands.bash", "02_setup_profile.bash", "03_update_all.bash"
##############################################################################################

# Folder base donde se almacena los subfolderes de los programas.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es un valor valido, la funcion "set_program_path" asignara un sus posibles valores (segun orden de prioridad):
#     > "/var/opt/tools"
#     > "~/tools"
#g_path_programs='/var/opt/tools'

# Folder base donde se almacena data temporal que sera eliminado automaticamente despues completar la configuración.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es valido, la funcion "set_temp_path" asignara segun orden de prioridad a '/var/tmp' o '/tmp'.
# - Tener en cuenta que en muchas distribuciones el folder '/tmp' esta en la memoria y esta limitado a su tamaño.
#g_path_temp='/var/tmp'


##############################################################################################
# Usado por los script "00_setup_summary.bash", "01_setup_commands.bash", "03_update_all.bash"
##############################################################################################

# Folder base donde se almacena el comando y sus archivos afines.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura), dentro
#   de este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_path_cmd_base}/bin"         : subfolder donde se almacena los comandos.
#     > "${g_path_cmd_base}/man/man1"    : subfolder donde se almacena archivos de ayuda man1.
#     > "${g_path_cmd_base}/share/fonts" : subfolder donde se almacena las fuentes.
# - Si no es un valor valido, la funcion "set_command_path" asignara un sus posibles valores (segun orden de prioridad):
#     > Si tiene permisos administrativos, usara los folderes predeterminado para todos los usuarios:
#        - "/usr/local/bin"      : subfolder donde se almacena los comandos.
#        - "/usr/local/man/man1" : subfolder donde se almacena archivos de ayuda man1.
#        - "/usr/share/fonts"    : subfolder donde se almacena las fuentes.
#     > Caso contrario, se usara los folderes predeterminado para el usuario:
#        - "~/.local/bin"         : subfolder donde se almacena los comandos.
#        - "~/.local/man/man1"    : subfolder donde se almacena archivos de ayuda man1.
#        - "~/.local/share/fonts" : subfolder donde se almacena las fuentes.
#g_path_cmd_base=''


##############################################################################################
# Usado por los script "01_setup_commands.bash"
##############################################################################################

# Folder base, generados solo para Linux WSL, donde se almacena el programas, comando y afines usados por Windows.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es un valor valido, se asignara un sus posibles valores (segun orden de prioridad):
#     > "/mnt/d/CLI" (es decir "D:\CLI")
#     > "/mnt/c/CLI" (es decir "C:\CLI")
# - En este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_path_base_win}/Programs"     : subfolder donde se almacena los subfolder de los programas.
#     > "${g_path_base_win}/Commands/bin" : subfolder donde se almacena los comandos.
#     > "${g_path_base_win}/Commands/man" : subfolder donde se almacena los archivos de ayuda man1 del comando.
#     > "${g_path_base_win}/Commands/doc" : subfolder donde se almacena documentacion del comando.
#     > "${g_path_base_win}/Commands/etc" : subfolder donde se almacena archivos adicionales del comando.
#g_path_base_win='/mnt/d/CLI'


##############################################################################################
# Usado por los script "01_setup_commands.bash", "03_update_all.bash"
##############################################################################################

# Folder base, generados solo para Linux WSL, donde se almacena el programas, comando y afines usados por Windows.
# Usado solo durante la instalación. Define si se instala solo la ultima version de un programa.
# Por defecto es 1 (considerado 'false'). Solo si su valor es '0', es considera 'true'.
#g_setup_only_last_version=0


