#
# Para habilitar su uso genere el arcivo '${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1':
#  cp ~/.files/shell/powershell/bin/windowssetup/lib/setup_config_template.ps1 "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1"
#  vim "${env:USERPROFILE}/.files/shell/powershell/bin/windowssetup/.setup_config.ps1"
#

# Folder base, donde se almacena el programas, comando y afines usados por Windows.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es un valor valido, se asignara su valor por defecto "/mnt/c/tools" (es decir "c:\apps").
# - En este folder se creara/usara la siguiente estructura de folderes:
#     > "${g_win_base_path}/tools"     : subfolder donde se almacena los subfolder de los programas.
#     > "${g_win_base_path}/cmds/bin" : subfolder donde se almacena los comandos.
#     > "${g_win_base_path}/cmds/doc" : subfolder donde se almacena documentacion del comando.
#     > "${g_win_base_path}/cmds/etc" : subfolder donde se almacena archivos adicionales del comando.
#     > "${g_win_base_path}/fonts" : subfolder donde se almacena los archivos de fuentes tipograficas.
#$g_win_base_path='D:\apps'

# Folder base donde se almacena data temporal que sera eliminado automaticamente despues completar la configuración.
# - El valor solo se tomara en cuenta si es un valor valido (el folder existe y debe tener permisos e escritura).
# - Si no es valido, la funcion "set_temp_path" asignara segun orden de prioridad a '$env:TEMP'.
#$g_temp_path='C:\Windows\Temp'

# Usado solo durante la instalación. Define si se instala solo la ultima version de un programa.
# Por defecto es 1 (considerado 'false'). Solo si su valor es '0', es considera 'true'.
#$g_setup_only_last_version=1

# Definir si se descarga y configuracion plugins de AI (AI Completion, AI Chatbot, AI Agent, etc.).
# Sus valores puede ser:
# > 0 No instala ningun plugin de AI.
# > Puede ser la suma de los siguientes valores:
#   > 1 Instala plugin de AI Completion.
#   > 2 Instala plugin de AI Chatbot y AI Agent interno (por ejemplo Avante)
#   > 4 Instala plugin de integracion de AI Chatbot y AI Agent externo (por ejemplo integracion con OpenCode-CLI o Gemini-CLI)
# Si no se define el valor por defecto es '0' (no se instala ningun plugin de AI).
#$g_setup_vim_ai_plugins=7

# Modo de instalacion segun los acceso que se tiene para crear enlaces simbolicos
# Sus valores pueden ser:
# > 0 Si no se tiene acceso para crear a enlaces simbolicos (debe tener un usuario que puede ejecutar en en modo privilegiado
#     o poder ejecutar 'sudo').
#     > Usualmente se realiza una copia (y/o elimina versiones anteriores) de los archivos no-modificables por el usuario.
#     > Existe algunos archivos que usuario puede modificarlos. Estos archivos solo se puede reescribir si se flag de reescritura
#       para evitar perdidas de configuraciones de usuario.
# > 1 Se puede crear enlaces simbolicos pero desde una instancia de una pseudo-terminal con acceso privilegiado.
# > 2 Se puede crear enlaces simbolicos en la misma pseudo-terminal usando el comando 'sudo' (Solo en Windows que no son Core
#     y cuya version >= 24H2)
# > Si no se especifica su valor por defecto es 1.
#$g_setup_access_type=1
